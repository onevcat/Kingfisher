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
public typealias ResultCompletionHandler = ((Result<RetrieveImageResult>) -> Void)

public struct RetrieveImageResult {
    public let image: Image
    public let cacheType: CacheType
    public let imageURL: URL
}

/// RetrieveImageTask represents a task of image retrieving process.
/// It contains an async task of getting image from disk and from network.
public final class RetrieveImageTask {
    
    // If task is canceled before the download task started (which means the `downloadTask` is nil),
    // the download task should not begin.
    var cancelledBeforeDownloadStarting: Bool = false
    
    /// The network retrieve task in this image task if exist. If the task does not need download (since the requested
    /// image is found in cache), or the download is already finished, it is `nil`,
    public var downloadTask: RetrieveImageDownloadTask?
    
    /**
    Cancel current task. If this task is already done, do nothing.
    */
    public func cancel() {
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        } else {
            cancelledBeforeDownloadStarting = true
        }
    }
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
                              options: KingfisherOptionsInfo?,
                              progressBlock: DownloadProgressBlock?,
                              completionHandler: ResultCompletionHandler?) -> RetrieveImageTask
    {
        let task = RetrieveImageTask()
        let options = currentDefaultOptions + (options ?? .empty)
        if options.forceRefresh {
            downloadAndCacheImage(
                with: resource.downloadURL,
                forKey: resource.cacheKey,
                retrieveImageTask: task,
                progressBlock: progressBlock,
                completionHandler: completionHandler,
                options: options)
        } else {
            tryToRetrieveImageFromCache(
                forKey: resource.cacheKey,
                with: resource.downloadURL,
                retrieveImageTask: task,
                progressBlock: progressBlock,
                completionHandler: completionHandler,
                options: options)
        }
        
        return task
    }

    @discardableResult
    func downloadAndCacheImage(with url: URL,
                             forKey key: String,
                      retrieveImageTask: RetrieveImageTask,
                          progressBlock: DownloadProgressBlock?,
                      completionHandler: ResultCompletionHandler?,
                                options: KingfisherOptionsInfo) -> RetrieveImageDownloadTask?
    {
        let downloader = options.downloader ?? self.downloader
        let processQueue = self.processQueue
        return downloader.downloadImage(with: url, retrieveImageTask: retrieveImageTask, options: options,
            progressBlock: { receivedSize, totalSize in
                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { image, error, imageURL, originalData in
                let targetCache = options.targetCache ?? self.cache
                if let image = image, let originalData = originalData {
                    targetCache.store(image,
                                      original: originalData,
                                      forKey: key,
                                      processorIdentifier:options.processor.identifier,
                                      cacheSerializer: options.cacheSerializer,
                                      toDisk: !options.cacheMemoryOnly) {
                                        
                                        guard options.waitForCache else { return }
                                        
                                        let cacheType = targetCache.imageCachedType(forKey: key, processorIdentifier: options.processor.identifier)
                                        let result = RetrieveImageResult(image: image, cacheType: cacheType, imageURL: url)
                                        completionHandler?(.success(result))
                    }
                    
                    if options.cacheOriginalImage && options.processor != DefaultImageProcessor.default {
                        let originalCache = options.originalCache ?? targetCache
                        let defaultProcessor = DefaultImageProcessor.default
                        processQueue.async {
                            if let originalImage = defaultProcessor.process(item: .data(originalData), options: options) {
                                originalCache.store(originalImage,
                                                    original: originalData,
                                                    forKey: key,
                                                    processorIdentifier: defaultProcessor.identifier,
                                                    cacheSerializer: options.cacheSerializer,
                                                    toDisk: !options.cacheMemoryOnly,
                                                    completionHandler: nil)
                            }
                        }
                    }
                }

                if options.waitForCache == false {
                    if let error = error {
                        completionHandler?(.failure(error))
                    } else {
                        let result = RetrieveImageResult(image: image!, cacheType: .none, imageURL: url)
                        completionHandler?(.success(result))
                    }
                }
            })
    }
    
    func tryToRetrieveImageFromCache(forKey key: String,
                                       with url: URL,
                              retrieveImageTask: RetrieveImageTask,
                                  progressBlock: DownloadProgressBlock?,
                              completionHandler: ResultCompletionHandler?,
                                        options: KingfisherOptionsInfo)
    {
        func handleNoCache() {
            if options.onlyFromCache {
                let error = NSError(domain: KingfisherErrorDomain, code: KingfisherError.notCached.rawValue, userInfo: nil)
                completionHandler?(.failure(error))
                return
            }
            downloadAndCacheImage(
                with: url,
                forKey: key,
                retrieveImageTask: retrieveImageTask,
                progressBlock: progressBlock,
                completionHandler: completionHandler,
                options: options)
            
        }
        
        let targetCache = options.targetCache ?? self.cache
        let processQueue = self.processQueue
        // First, try to get the exactly image from cache
        targetCache.retrieveImage(forKey: key, options: options) { image, cacheType in
            // If found, we could finish now.
            if image != nil {
                let result = RetrieveImageResult(image: image!, cacheType: cacheType, imageURL: url)
                completionHandler?(.success(result))
                return
            }
            
            // If not found, and we are using a default processor, download it!
            let processor = options.processor
            guard processor != DefaultImageProcessor.default else {
                handleNoCache()
                return
            }
            
            // If processor is not the default one, we have a chance to check whether
            // the original image is already in cache.
            let originalCache = options.originalCache ?? targetCache
            let optionsWithoutProcessor = options.removeAllMatchesIgnoringAssociatedValue(.processor(processor))
            originalCache.retrieveImage(forKey: key, options: optionsWithoutProcessor) { image, cacheType in
                // If we found the original image, there is no need to download it again.
                // We could just apply processor to it now.
                guard let image = image else {
                    handleNoCache()
                    return
                }

                processQueue.async {
                    guard let processedImage = processor.process(item: .image(image), options: options) else {
                        options.callbackDispatchQueue.safeAsync {
                            #warning("handle processor error")
//                            diskTaskCompletionHandler(nil, nil, .none, url)
                        }
                        return
                    }
                    targetCache.store(processedImage,
                                      original: nil,
                                      forKey: key,
                                      processorIdentifier:options.processor.identifier,
                                      cacheSerializer: options.cacheSerializer,
                                      toDisk: !options.cacheMemoryOnly) {
                                        
                                        guard options.waitForCache else { return }

                                        let cacheType = targetCache.imageCachedType(forKey: key, processorIdentifier: options.processor.identifier)
                                        options.callbackDispatchQueue.safeAsync {
                                            let result = RetrieveImageResult(image: processedImage, cacheType: cacheType, imageURL: url)
                                            completionHandler?(.success(result))
                                        }
                    }

                    if options.waitForCache == false {
                        options.callbackDispatchQueue.safeAsync {
                            let result = RetrieveImageResult(image: processedImage, cacheType: .none, imageURL: url)
                            completionHandler?(.success(result))
                        }
                    }
                }
            }
        }
    }
}
