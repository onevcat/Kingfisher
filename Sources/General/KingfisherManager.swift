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


import Foundation

/// The downloading progress block type.
/// The parameter value is the `receivedSize` of current response.
/// The second parameter is the total expected data length from response's "Content-Length" header.
/// If the expected length is not available, this block will not be called.
public typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

/// Represents the result of a Kingfisher retrieving image task.
public struct RetrieveImageResult {

    /// Gets the image object of this result.
    public let image: Image

    /// Gets the cache source of the image. It indicates from which layer of cache this image is retrieved.
    /// If the image is just downloaded from network, `.none` will be returned.
    public let cacheType: CacheType

    /// The resource URL of image.
    public let imageURL: URL
}

/// Main manager class of Kingfisher. It connects Kingfisher downloader and cache,
/// to provide a set of connivence methods to use Kingfisher for tasks.
/// You can use this class to retrieve an image via a specified URL from web or cache.
public class KingfisherManager {
    
    /// Represents a shared manager used across Kingfisher.
    /// Use this instance for getting or storing images with Kingfisher.
    public static let shared = KingfisherManager()
    
    /// The `ImageCache` used by this manager. It is `ImageCache.default` by default.
    /// If a cache is specified in `KingfisherManager.defaultOptions`, the value in `defaultOptions` will be
    /// used instead.
    public var cache: ImageCache
    
    /// The `ImageDownloader` used by this manager. It is `ImageDownloader.default` by default.
    /// If a downloader is specified in `KingfisherManager.defaultOptions`, the value in `defaultOptions` will be
    /// used instead.
    public var downloader: ImageDownloader
    
    /// Default options used by the manager. This option will be used in
    /// Kingfisher manager related methods, as well as all view extension methods.
    /// You can also passing other options for each image task by sending an `options` parameter
    /// to Kingfisher's APIs. The per image options will overwrite the default ones,
    /// if the option exists in both.
    public var defaultOptions = KingfisherOptionsInfo.empty
    
    // Use `defaultOptions` to overwrite the `downloader` and `cache`.
    private var currentDefaultOptions: KingfisherOptionsInfo {
        return [.downloader(downloader), .targetCache(cache)] + defaultOptions
    }

    private let processQueue: DispatchQueue
    
    private convenience init() {
        self.init(downloader: .default, cache: .default)
    }
    
    init(downloader: ImageDownloader, cache: ImageCache) {
        self.downloader = downloader
        self.cache = cache

        let processQueueName = "com.onevcat.Kingfisher.KingfisherManager.processQueue.\(UUID().uuidString)"
        processQueue = DispatchQueue(label: processQueueName)
    }

    /// Gets an image from a given resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object defines data information like key or URL.
    ///   - options: Options to use when creating the animated image.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. `progressBlock` is always called in
    ///                    main queue.
    ///   - completionHandler: Called when the image retrieved and set finished. This completion handler will be invoked
    ///                        from the `options.callbackQueue`. If not specified, the main queue will be used.
    /// - Returns: A task represents the image downloading. If there is no downloading starts, `nil` is returned.
    ///
    /// - Note:
    ///    This method will first check whether the requested `resource` is already in cache or not. If cached,
    ///    it returns `nil` and invoke the `completionHandler` after the cached image retrieved. Otherwise, it
    ///    will download the `resource`, store it in cache, then call `completionHandler`.
    ///
    @discardableResult
    public func retrieveImage(
        with resource: Resource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult>) -> Void)?) -> DownloadTask?
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
            let loadedFromCache = retrieveImageFromCache(
                forKey: resource.cacheKey,
                with: resource.downloadURL,
                options: options,
                completionHandler: completionHandler)

            if loadedFromCache {
                return nil
            }

            if options.onlyFromCache {
                let error = KingfisherError.cacheError(reason: .imageNotExisting(key: resource.cacheKey))
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

    /// Download and cache the image with given parameters.
    ///
    /// - Parameters:
    ///   - url: The target URL from where the image data could be downloaded.
    ///   - key: The key to use when caching the image.
    ///   - options: Options on how to process or serialize the image data.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. `progressBlock` is always called in
    ///                    main queue.
    ///   - completionHandler: Called when the process finishes, either with succeeded
    ///                        `RetrieveImageResult` or an error.
    /// - Returns: A task represents the image downloading. If there is no downloading starts, `nil` is returned.
    @discardableResult
    func downloadAndCacheImage(
        with url: URL,
        forKey key: String,
        options: KingfisherOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult>) -> Void)?) -> DownloadTask?
    {
        let downloader = options.downloader ?? self.downloader

        return downloader.downloadImage(
            with: url,
            options: options,
            progressBlock: progressBlock)
        {
            result in
            switch result {
            case .success(let value):
                // Add image to cache.
                let targetCache = options.targetCache ?? self.cache
                targetCache.store(
                    value.image,
                    original: value.originalData,
                    forKey: key,
                    processorIdentifier: options.processor.identifier,
                    cacheSerializer: options.cacheSerializer,
                    toDisk: !options.cacheMemoryOnly,
                    callbackQueue: options.callbackQueue)
                {
                    _ in
                    if options.waitForCache {
                        let result = RetrieveImageResult(image: value.image, cacheType: .none, imageURL: url)
                        completionHandler?(.success(result))
                    }
                }

                // Add original image to cache if necessary.
                let needToCacheOriginalImage = options.cacheOriginalImage &&
                                               options.processor != DefaultImageProcessor.default
                if needToCacheOriginalImage {
                    let defaultProcessor = DefaultImageProcessor.default
                    self.processQueue.async {
                        guard let originalImage =
                            defaultProcessor.process(item: .data(value.originalData), options: options)
                        else { return }

                        let originalCache = options.originalCache ?? targetCache
                        originalCache.store(
                            originalImage,
                            original: value.originalData,
                            forKey: key,
                            processorIdentifier: defaultProcessor.identifier,
                            cacheSerializer: options.cacheSerializer,
                            toDisk: !options.cacheMemoryOnly)
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
    
    /// Retrieves image from memory or disk cache.
    ///
    /// - Parameters:
    ///   - key: The key to use when caching the image.
    ///   - url: Image request URL. This is not used when retrieving image from cache. It is just used for
    ///          `RetrieveImageResult` callback compatibility.
    ///   - options: Options on how to get the image from image cache.
    ///   - completionHandler: Called when the image retrieving finishes, either with succeeded
    ///                        `RetrieveImageResult` or an error.
    /// - Returns: `true` if the requested image or the original image before being processed is existing in cache.
    ///            Otherwise, this method returns `false`.
    ///
    /// - Note:
    ///    The image retrieving could happen in either memory cache or disk cache. The `.processor` option in
    ///    `options` will be considered when searching in the cache. If no processed image is found, Kingfisher
    ///    will try to check whether an original version of that image is existing or not. If there is already an
    ///    original, Kingfisher retrieves it from cache and processes it. Then, the processed image will be store
    ///    back to cache for later use.
    func retrieveImageFromCache(
        forKey key: String,
        with url: URL,
        options: KingfisherOptionsInfo,
        completionHandler: ((Result<RetrieveImageResult>) -> Void)?) -> Bool
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
                    completionHandler?(.failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key))))
                }
            }
            return true
        }

        // 2. Check whether the original image exists. If so, get it, process it, save to storage and return.
        let originalCache = options.originalCache ?? targetCache
        // No need to store the same file in the same cache again.
        if originalCache === targetCache && options.processor == DefaultImageProcessor.default {
            return false
        }

        // Check whether the unprocessed image existing or not.
        let originalImageCached = originalCache.imageCachedType(
            forKey: key, processorIdentifier: DefaultImageProcessor.default.identifier).cached
        if originalImageCached {
            // Now we are ready to get found the original image from cache. We need the unprocessed image, so remove
            // any processor from options first.
            let optionsWithoutProcessor = options.removeAllMatchesIgnoringAssociatedValue(.processor(options.processor))
            originalCache.retrieveImage(forKey: key, options: optionsWithoutProcessor) { result in
                if let image = result.value?.image {
                    let processor = options.processor
                    let processQueue = self.processQueue
                    processQueue.async {
                        let item = ImageProcessItem.image(image)
                        guard let processedImage = processor.process(item: item, options: options) else {
                            let error = KingfisherError.processorError(
                                            reason: .processingFailed(processor: processor, item: item))
                            completionHandler?(.failure(error))
                            return
                        }

                        targetCache.store(
                            processedImage,
                            forKey: key,
                            processorIdentifier: processor.identifier,
                            cacheSerializer: options.cacheSerializer,
                            toDisk: !options.cacheMemoryOnly)
                        {
                            _ in
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
                    // This should not happen actually, since we already confirmed `originalImageCached` is `true`.
                    // Just in case...
                    completionHandler?(.failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key))))
                }
            }
            return true
        }

        return false

    }
}
