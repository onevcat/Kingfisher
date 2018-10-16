//
//  KingfisherManager.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

public struct RetrieveImageResult {
    public let image: Image
    public let cacheType: CacheType
    public let imageURL: URL
}

/// Main manager class of Kingfisher. It connects Kingfisher downloader and cache.
/// You can use this class to retrieve an image via a specified URL from web or cache.
public class KingfisherManager {
    
    /// Shared manager used by the extensions across Kingfisher.
    public static let shared = KingfisherManager()
    
    /// Cache used by this manager
    public var cache: ImageCache
    
    /// Downloader used by this manager
    public var downloader: ImageDownloader
    
    /// Default options used by the manager. This option will be used in 
    /// Kingfisher manager related methods, and all image view and
    /// button extension methods. You can also passing other options for each image task by
    /// sending an `options` parameter to Kingfisher's APIs, the per image options
    /// will overwrite the default ones, if exist in both.
    ///
    /// - Note: This option will not be applied to independent using of `ImageDownloader` or `ImageCache`.
    public var defaultOptions = KingfisherOptionsInfo.empty
    
    // Use `defaultOptions` to overwrite the `downloader` and `cache`.
    var currentDefaultOptions: KingfisherOptionsInfo {
        return [.downloader(downloader), .targetCache(cache)] + defaultOptions
    }

    private let processQueue: DispatchQueue
    
    convenience init() {
        self.init(downloader: .default, cache: .default)
    }
    
    init(downloader: ImageDownloader, cache: ImageCache) {
        self.downloader = downloader
        self.cache = cache

        let processQueueName = "com.onevcat.Kingfisher.KingfisherManager.processQueue.\(UUID().uuidString)"
        processQueue = DispatchQueue(label: processQueueName, attributes: .concurrent)
    }
    
    @discardableResult
    public func retrieveImage(with resource: Resource,
                              options: KingfisherOptionsInfo? = nil,
                              progressBlock: DownloadProgressBlock? = nil,
                              completionHandler: ((Result<RetrieveImageResult>) -> Void)?) -> SessionDataTask?
    {
        let options = currentDefaultOptions + (options ?? .empty)
        if options.forceRefresh {
            return downloadAndCacheImage(
                with: resource.downloadURL,
                forKey: resource.cacheKey,
                options: options,
                progressBlock: progressBlock,
                completionHandler: completionHandler)
        } else {
            let loadFromCache = tryToRetrieveImageFromCache(
                forKey: resource.cacheKey,
                with: resource.downloadURL,
                progressBlock: progressBlock,
                completionHandler: completionHandler,
                options: options)

            if loadFromCache {
                return nil
            }

            if options.onlyFromCache {
                let error = KingfisherError2.cacheError(reason: .imageNotExisting(key: resource.cacheKey))
                completionHandler?(.failure(error))
                return nil
            }

            return downloadAndCacheImage(
                with: resource.downloadURL,
                forKey: resource.cacheKey,
                options: options,
                progressBlock: progressBlock,
                completionHandler: completionHandler)
        }
    }

    @discardableResult
    func downloadAndCacheImage(with url: URL,
                             forKey key: String,
                             options: KingfisherOptionsInfo,
                          progressBlock: DownloadProgressBlock? = nil,
                      completionHandler: ((Result<RetrieveImageResult>) -> Void)?) -> SessionDataTask?
    {
        let downloader = options.downloader ?? self.downloader
        let processQueue = self.processQueue

        return downloader.downloadImage(
            with: url,
            options: options,
            progressBlock: { receivedSize, totalSize in progressBlock?(receivedSize, totalSize)})
        {
            result in
            switch result {
            case .success(let value):
                let targetCache = options.targetCache ?? self.cache
                targetCache.store(
                    value.image,
                    original: value.originalData,
                    forKey: key,
                    processorIdentifier: options.processor.identifier,
                    cacheSerializer: options.cacheSerializer,
                    toDisk: !options.cacheMemoryOnly)
                {
                    guard options.waitForCache else { return }
                    let result = RetrieveImageResult(image: value.image, cacheType: .none, imageURL: url)
                    options.callbackDispatchQueue.async { completionHandler?(.success(result)) }
                }

                if options.cacheOriginalImage && options.processor != DefaultImageProcessor.default {
                    let originalCache = options.originalCache ?? targetCache
                    let defaultProcessor = DefaultImageProcessor.default
                    processQueue.async {
                        if let originalImage = defaultProcessor.process(item: .data(value.originalData), options: options) {
                            originalCache.store(originalImage,
                                                original: value.originalData,
                                                forKey: key,
                                                processorIdentifier: defaultProcessor.identifier,
                                                cacheSerializer: options.cacheSerializer,
                                                toDisk: !options.cacheMemoryOnly,
                                                completionHandler: nil)
                        }
                    }
                }
                if !options.waitForCache {
                    let result = RetrieveImageResult(image: value.image, cacheType: .none, imageURL: url)
                    completionHandler?(.success(result))
                }
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        }
    }
    
    func tryToRetrieveImageFromCache(forKey key: String,
                                       with url: URL,
                                  progressBlock: DownloadProgressBlock?,
                              completionHandler: ((Result<RetrieveImageResult>) -> Void)?,
                                        options: KingfisherOptionsInfo) -> Bool
    {
        // 1. Check whether the image was already in target cache. If so, just get it.
        let targetCache = options.targetCache ?? cache
        let targetImageCached = targetCache.imageCachedType(
            forKey: key, processorIdentifier: options.processor.identifier)
        
        let validCache = targetImageCached.cached &&
            (options.fromMemoryCacheOrRefresh == false || targetImageCached == .memory)
        if validCache {
            targetCache.retrieveImage(forKey: key, options: options) { result in
                if let image = result.value?.image {
                    let value = result.map {
                        RetrieveImageResult(image: image, cacheType: $0.cacheType, imageURL: url)
                    }
                    completionHandler?(value)
                } else {
                    completionHandler?(.failure(KingfisherError2.cacheError(reason: .imageNotExisting(key: key))))
                }
            }
            return true
        }

        // 2. Check whether the original image exists. If so, get it, process it, save to storage and return.
        let originalCache = options.originalCache ?? targetCache
        // No need to search the same file in the same cache again.
        if originalCache === targetCache && options.processor == DefaultImageProcessor.default {
            return false
        }

        let originalImageCached = originalCache.imageCachedType(
            forKey: key, processorIdentifier: DefaultImageProcessor.default.identifier).cached
        if originalImageCached {
            let optionsWithoutProcessor = options.removeAllMatchesIgnoringAssociatedValue(.processor(options.processor))
            originalCache.retrieveImage(forKey: key, options: optionsWithoutProcessor) { result in
                if let image = result.value?.image {
                    let processor = options.processor
                    let processQueue = self.processQueue
                    processQueue.async {
                        let item = ImageProcessItem.image(image)
                        guard let processedImage = processor.process(item: item, options: options) else {
                            let error = KingfisherError2.processorError(
                                            reason: .processingFailed(processor: processor, item: item))
                            completionHandler?(.failure(error))
                            return
                        }

                        targetCache.store(
                            processedImage,
                            forKey: key,
                            processorIdentifier: processor.identifier,
                            cacheSerializer: options.cacheSerializer,
                            toDisk: !options.onlyFromCache)
                        {
                            if options.waitForCache {
                                let value = RetrieveImageResult(image: processedImage, cacheType: .none, imageURL: url)
                                completionHandler?(.success(value))
                            }
                        }

                        if !options.waitForCache {
                            let value = RetrieveImageResult(image: processedImage, cacheType: .none, imageURL: url)
                            completionHandler?(.success(value))
                        }
                    }
                } else {
                    completionHandler?(.failure(KingfisherError2.cacheError(reason: .imageNotExisting(key: key))))
                }
            }
            return true
        }

        return false

    }
}
