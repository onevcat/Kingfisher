//
//  KingfisherManager.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Represents the type for a downloading progress block.
///
/// This block type is used to monitor the progress of data being downloaded. It takes two parameters:
///
/// 1. `receivedSize`: The size of the data received in the current response.
/// 2. `expectedSize`: The total expected data length from the response's "Content-Length" header. If the expected 
/// length is not available, this block will not be called.
///
/// You can use this progress block to track the download progress and update user interfaces or perform additional 
/// actions based on the progress.
///
/// - Parameters:
///   - receivedSize: The size of the data received.
///   - expectedSize: The expected total data length from the "Content-Length" header.
public typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

/// Represents the result of a Kingfisher image retrieval task.
///
/// This type encapsulates the outcome of an image retrieval operation performed by Kingfisher.
/// It holds a successful result with the retrieved image.
public struct RetrieveImageResult: Sendable {
    /// Retrieves the image object from this result.
    public let image: KFCrossPlatformImage

    /// Retrieves the cache source of the image, indicating from which cache layer it was retrieved.
    ///
    /// If the image was freshly downloaded from the network and not retrieved from any cache, `.none` will be returned.
    /// Otherwise, either ``CacheType/memory`` or ``CacheType/disk`` will be returned, allowing you to determine whether
    /// the image was retrieved from memory or disk cache.
    public let cacheType: CacheType

    /// The ``Source`` to which this result is related. This indicates where the `image` referenced by `self` is located.
    public let source: Source

    /// The original ``Source`` from which the retrieval task begins. It may differ from the ``source`` property.
    /// When an alternative source loading occurs, the ``source`` will represent the replacement loading target, while the
    /// ``originalSource`` will retain the initial ``source`` that initiated the image loading process.
    public let originalSource: Source
    
    /// Retrieves the data associated with this result.
    ///
    /// When this result is obtained from a network download (when `cacheType == .none`), calling this method returns 
    /// the downloaded data. If the result is from the cache, it serializes the image using the specified cache
    /// serializer from the loading options and returns the result.
    ///
    /// - Note: Retrieving this data can be a time-consuming operation, so it is advisable to store it if you need to 
    /// use it multiple times and avoid frequent calls to this method.
    public let data: @Sendable () -> Data?
}

/// A structure that stores related information about a ``KingfisherError``. It provides contextual information
/// to facilitate the identification of the error.
public struct PropagationError: Sendable {

    /// The ``Source`` to which current `error` is bound.
    public let source: Source

    /// The actual error happens in framework.
    public let error: KingfisherError
}

/// The block type used for handling updates during the downloading task. 
///
/// The `newTask` parameter represents the updated task for the image loading process. It is `nil` if the image loading
/// doesn't involve a downloading process. When an image download is initiated, this value will contain the actual
/// ``DownloadTask`` instance, allowing you to retain it or cancel it later if necessary.
public typealias DownloadTaskUpdatedBlock = (@Sendable (_ newTask: DownloadTask?) -> Void)

/// The main manager class of Kingfisher. It connects the Kingfisher downloader and cache to offer a set of convenient 
/// methods for working with Kingfisher tasks.
///
/// You can utilize this class to retrieve an image via a specified URL from the web or cache.
public class KingfisherManager: @unchecked Sendable {

    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.KingfisherManagerPropertyQueue")
    
    /// Represents a shared manager used across Kingfisher.
    /// Use this instance for getting or storing images with Kingfisher.
    public static let shared = KingfisherManager()

    // Mark: Public Properties
    
    private var _cache: ImageCache
    
    /// The ``ImageCache`` utilized by this manager, which defaults to ``ImageCache/default``.
    ///
    /// If a cache is specified in ``KingfisherManager/defaultOptions`` or ``KingfisherOptionsInfoItem/targetCache(_:)``,
    /// those specified values will take precedence when Kingfisher attempts to retrieve or store images in the cache.
    public var cache: ImageCache {
        get { propertyQueue.sync { _cache } }
        set { propertyQueue.sync { _cache = newValue } }
    }
    
    private var _downloader: ImageDownloader
    
    /// The ``ImageDownloader`` utilized by this manager, which defaults to ``ImageDownloader/default``.
    ///
    /// If a downloader is specified in ``KingfisherManager/defaultOptions`` or ``KingfisherOptionsInfoItem/downloader(_:)``,
    /// those specified values will take precedence when Kingfisher attempts to download the image data from a remote
    /// server.
    public var downloader: ImageDownloader {
        get { propertyQueue.sync { _downloader } }
        set { propertyQueue.sync { _downloader = newValue } }
    }
    
    /// The default options used by the ``KingfisherManager`` instance.
    ///
    /// These options are utilized in Kingfisher manager-related methods, as well as all view extension methods.
    /// You can also pass additional options for each image task by providing an `options` parameter to Kingfisher's APIs.
    ///
    /// Per-image options will override the default ones if there is a conflict.
    public var defaultOptions = KingfisherOptionsInfo.empty
    
    // Use `defaultOptions` to overwrite the `downloader` and `cache`.
    private var currentDefaultOptions: KingfisherOptionsInfo {
        return [.downloader(downloader), .targetCache(cache)] + defaultOptions
    }

    private let processingQueue: CallbackQueue
    
    private convenience init() {
        self.init(downloader: .default, cache: .default)
    }

    /// Creates an image setting manager with the specified downloader and cache.
    ///
    /// - Parameters:
    ///   - downloader: The image downloader used for image downloads.
    ///   - cache: The image cache that stores images in memory and on disk.
    ///
    public init(downloader: ImageDownloader, cache: ImageCache) {
        _downloader = downloader
        _cache = cache

        let processQueueName = "com.onevcat.Kingfisher.KingfisherManager.processQueue.\(UUID().uuidString)"
        processingQueue = .dispatch(DispatchQueue(label: processQueueName))
    }

    // MARK: - Getting Images

    /// Retrieves an image from a specified resource.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object defining data information, such as a key or URL.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image download progress is updated. This block is invoked only if the response 
    ///   contains an `expectedContentLength` and always runs on the main queue.
    ///   - downloadTaskUpdated: Called when a new image download task is created for the current image retrieval. This
    ///   typically occurs when an alternative source is used to replace the original (failed) task. You can update your
    ///   reference to the ``DownloadTask`` if you want to manually invoke ``DownloadTask/cancel()`` on the new task.
    ///   - completionHandler: Called when the image retrieval and setting are completed. This completion handler is 
    ///   invoked from the `options.callbackQueue`. If not specified, the main queue is used.
    ///
    /// - Returns: A task representing the image download. If a download task is initiated for a ``Source/network(_:)`` resource,
    ///            the started ``DownloadTask`` is returned; otherwise, `nil` is returned.
    ///
    /// - Note: This method first checks whether the requested `resource` is already in the cache. If it is cached,
    /// it returns `nil` and invokes the `completionHandler` after retrieving the cached image. Otherwise, it downloads
    /// the `resource`, stores it in the cache, and then calls the `completionHandler`.
    ///
    @discardableResult
    public func retrieveImage(
        with resource: any Resource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        return retrieveImage(
            with: resource.convertToSource(),
            options: options,
            progressBlock: progressBlock,
            downloadTaskUpdated: downloadTaskUpdated,
            completionHandler: completionHandler
        )
    }

    /// Retrieves an image from a specified source.
    ///
    /// - Parameters:
    ///   - source: The ``Source`` object defining data information, such as a key or URL.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image download progress is updated. This block is invoked only if the response
    ///   contains an `expectedContentLength` and always runs on the main queue.
    ///   - downloadTaskUpdated: Called when a new image download task is created for the current image retrieval. This
    ///   typically occurs when an alternative source is used to replace the original (failed) task. You can update your
    ///   reference to the ``DownloadTask`` if you want to manually invoke ``DownloadTask/cancel()`` on the new task.
    ///   - completionHandler: Called when the image retrieval and setting are completed. This completion handler is
    ///   invoked from the `options.callbackQueue`. If not specified, the main queue is used.
    ///
    /// - Returns: A task representing the image download. If a download task is initiated for a ``Source/network(_:)`` resource,
    ///            the started ``DownloadTask`` is returned; otherwise, `nil` is returned.
    ///
    /// - Note: This method first checks whether the requested `source` is already in the cache. If it is cached,
    /// it returns `nil` and invokes the `completionHandler` after retrieving the cached image. Otherwise, it downloads
    /// the `source`, stores it in the cache, and then calls the `completionHandler`.
    ///
    @discardableResult
    public func retrieveImage(
        with source: Source,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        let options = currentDefaultOptions + (options ?? .empty)
        let info = KingfisherParsedOptionsInfo(options)
        return retrieveImage(
            with: source,
            options: info,
            progressBlock: progressBlock,
            downloadTaskUpdated: downloadTaskUpdated,
            completionHandler: completionHandler)
    }

    func retrieveImage(
        with source: Source,
        options: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        var info = options
        if let block = progressBlock {
            info.onDataReceived = (info.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }
        return retrieveImage(
            with: source,
            options: info,
            downloadTaskUpdated: downloadTaskUpdated,
            progressiveImageSetter: nil,
            completionHandler: completionHandler)
    }

    func retrieveImage(
        with source: Source,
        options: KingfisherParsedOptionsInfo,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        progressiveImageSetter: ((KFCrossPlatformImage?) -> Void)? = nil,
        referenceTaskIdentifierChecker: (() -> Bool)? = nil,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        var options = options
        let retryStrategy = options.retryStrategy
        
        if let provider = ImageProgressiveProvider(options: options, refresh: { image in
            guard let setter = progressiveImageSetter else {
                return
            }
            guard let strategy = options.progressiveJPEG?.onImageUpdated(image) else {
                setter(image)
                return
            }
            switch strategy {
            case .default: setter(image)
            case .keepCurrent: break
            case .replace(let newImage): setter(newImage)
            }
        }) {
            options.onDataReceived = (options.onDataReceived ?? []) + [provider]
        }
        if let checker = referenceTaskIdentifierChecker {
            options.onDataReceived?.forEach {
                $0.onShouldApply = checker
            }
        }
        
        let retrievingContext = RetrievingContext(options: options, originalSource: source)

        @Sendable func startNewRetrieveTask(
            with source: Source,
            retryContext: RetryContext?,
            downloadTaskUpdated: DownloadTaskUpdatedBlock?
        ) {
            let newTask = self.retrieveImage(with: source, context: retrievingContext) { result in
                handler(currentSource: source, retryContext: retryContext, result: result)
            }
            downloadTaskUpdated?(newTask)
        }

        @Sendable func failCurrentSource(_ source: Source, retryContext: RetryContext?, with error: KingfisherError) {
            // Skip alternative sources if the user cancelled it.
            guard !error.isTaskCancelled else {
                completionHandler?(.failure(error))
                return
            }
            // When low data mode constrained error, retry with the low data mode source instead of use alternative on fly.
            guard !error.isLowDataModeConstrained else {
                if let source = retrievingContext.options.lowDataModeSource {
                    retrievingContext.options.lowDataModeSource = nil
                    startNewRetrieveTask(with: source, retryContext: retryContext, downloadTaskUpdated: downloadTaskUpdated)
                } else {
                    // This should not happen.
                    completionHandler?(.failure(error))
                }
                return
            }
            if let nextSource = retrievingContext.popAlternativeSource() {
                retrievingContext.appendError(error, to: source)
                startNewRetrieveTask(with: nextSource, retryContext: retryContext, downloadTaskUpdated: downloadTaskUpdated)
            } else {
                // No other alternative source. Finish with error.
                if retrievingContext.propagationErrors.isEmpty {
                    completionHandler?(.failure(error))
                } else {
                    retrievingContext.appendError(error, to: source)
                    let finalError = KingfisherError.imageSettingError(
                        reason: .alternativeSourcesExhausted(retrievingContext.propagationErrors)
                    )
                    completionHandler?(.failure(finalError))
                }
            }
        }

        @Sendable func handler(
            currentSource: Source,
            retryContext: RetryContext?,
            result: (Result<RetrieveImageResult, KingfisherError>)
        ) -> Void {
            switch result {
            case .success:
                completionHandler?(result)
            case .failure(let error):
                if let retryStrategy = retryStrategy {
                    let context = retryContext?.increaseRetryCount() ?? RetryContext(source: source, error: error)
                    retryStrategy.retry(context: context) { decision in
                        switch decision {
                        case .retry(let userInfo):
                            context.userInfo = userInfo
                            startNewRetrieveTask(with: source, retryContext: context, downloadTaskUpdated: downloadTaskUpdated)
                        case .stop:
                            failCurrentSource(currentSource, retryContext: context, with: error)
                        }
                    }
                } else {
                    failCurrentSource(currentSource, retryContext: retryContext, with: error)
                }
            }
        }

        return retrieveImage(
            with: source,
            context: retrievingContext)
        {
            result in
            handler(currentSource: source, retryContext: nil, result: result)
        }

    }
    
    private func retrieveImage(
        with source: Source,
        context: RetrievingContext,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask?
    {
        let options = context.options
        if options.forceRefresh {
            return loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: completionHandler)?.value
            
        } else {
            let loadedFromCache = retrieveImageFromCache(
                source: source,
                context: context,
                completionHandler: completionHandler)
            
            if loadedFromCache {
                return nil
            }
            
            if options.onlyFromCache {
                let error = KingfisherError.cacheError(reason: .imageNotExisting(key: source.cacheKey))
                completionHandler?(.failure(error))
                return nil
            }
            
            return loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: completionHandler)?.value
        }
    }

    func provideImage(
        provider: any ImageDataProvider,
        options: KingfisherParsedOptionsInfo,
        completionHandler: (@Sendable (Result<ImageLoadingResult, KingfisherError>) -> Void)?)
    {
        guard let  completionHandler = completionHandler else { return }
        provider.data { result in
            switch result {
            case .success(let data):
                (options.processingQueue ?? self.processingQueue).execute {
                    let processor = options.processor
                    let processingItem = ImageProcessItem.data(data)
                    guard let image = processor.process(item: processingItem, options: options) else {
                        options.callbackQueue.execute {
                            let error = KingfisherError.processorError(
                                reason: .processingFailed(processor: processor, item: processingItem))
                            completionHandler(.failure(error))
                        }
                        return
                    }

                    options.callbackQueue.execute {
                        let result = ImageLoadingResult(image: image, url: nil, originalData: data)
                        completionHandler(.success(result))
                    }
                }
            case .failure(let error):
                options.callbackQueue.execute {
                    let error = KingfisherError.imageSettingError(
                        reason: .dataProviderError(provider: provider, error: error))
                    completionHandler(.failure(error))
                }

            }
        }
    }

    private func cacheImage(
        source: Source,
        options: KingfisherParsedOptionsInfo,
        context: RetrievingContext,
        result: Result<ImageLoadingResult, KingfisherError>,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?
    )
    {
        switch result {
        case .success(let value):
            let needToCacheOriginalImage = options.cacheOriginalImage &&
                                           options.processor != DefaultImageProcessor.default
            let coordinator = CacheCallbackCoordinator(
                shouldWaitForCache: options.waitForCache, shouldCacheOriginal: needToCacheOriginalImage)
            let result = RetrieveImageResult(
                image: options.imageModifier?.modify(value.image) ?? value.image,
                cacheType: .none,
                source: source,
                originalSource: context.originalSource,
                data: {  value.originalData }
            )
            // Add image to cache.
            let targetCache = options.targetCache ?? self.cache
            targetCache.store(
                value.image,
                original: value.originalData,
                forKey: source.cacheKey,
                options: options,
                toDisk: !options.cacheMemoryOnly)
            {
                _ in
                coordinator.apply(.cachingImage) {
                    completionHandler?(.success(result))
                }
            }

            // Add original image to cache if necessary.

            if needToCacheOriginalImage {
                let originalCache = options.originalCache ?? targetCache
                originalCache.storeToDisk(
                    value.originalData,
                    forKey: source.cacheKey,
                    processorIdentifier: DefaultImageProcessor.default.identifier,
                    expiration: options.diskCacheExpiration)
                {
                    _ in
                    coordinator.apply(.cachingOriginalImage) {
                        completionHandler?(.success(result))
                    }
                }
            }

            coordinator.apply(.cacheInitiated) {
                completionHandler?(.success(result))
            }

        case .failure(let error):
            completionHandler?(.failure(error))
        }
    }

    @discardableResult
    func loadAndCacheImage(
        source: Source,
        context: RetrievingContext,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> DownloadTask.WrappedTask?
    {
        let options = context.options
        @Sendable func _cacheImage(_ result: Result<ImageLoadingResult, KingfisherError>) {
            cacheImage(
                source: source,
                options: options,
                context: context,
                result: result,
                completionHandler: completionHandler
            )
        }

        switch source {
        case .network(let resource):
            let downloader = options.downloader ?? self.downloader
            let task = downloader.downloadImage(
                with: resource.downloadURL, options: options, completionHandler: _cacheImage
            )


            // The code below is neat, but it fails the Swift 5.2 compiler with a runtime crash when 
            // `BUILD_LIBRARY_FOR_DISTRIBUTION` is turned on. I believe it is a bug in the compiler. 
            // Let's fallback to a traditional style before it can be fixed in Swift.
            //
            // https://github.com/onevcat/Kingfisher/issues/1436
            //
            // return task.map(DownloadTask.WrappedTask.download)

            if task.isInitialized {
                return .download(task)
            } else {
                return nil
            }

        case .provider(let provider):
            provideImage(provider: provider, options: options, completionHandler: _cacheImage)
            return .dataProviding
        }
    }
    
    /// Retrieves an image from either memory or disk cache.
    ///
    /// - Parameters:
    ///   - source: The target source from which to retrieve the image.
    ///   - key: The key to use for caching the image.
    ///   - url: The image request URL. This is not used when retrieving an image from the cache; it is solely used for 
    ///   compatibility with ``RetrieveImageResult`` callbacks.
    ///   - options: Options on how to retrieve the image from the image cache.
    ///   - completionHandler: Called when the image retrieval is complete, either with a successful
    ///   ``RetrieveImageResult`` or an error.
    ///
    /// - Returns: `true` if the requested image or the original image before processing exists in the cache. Otherwise, this method returns `false`.
    ///
    /// - Note: Image retrieval can occur in either the memory cache or the disk cache. The
    /// ``KingfisherOptionsInfoItem/processor(_:)`` option in `options` is considered when searching the cache. If no
    /// processed image is found, Kingfisher attempts to determine whether an original version of the image exists. If
    /// an original exists, Kingfisher retrieves it from the cache and processes it. Subsequently, the processed image
    /// is stored back in the cache for future use.
    ///
    func retrieveImageFromCache(
        source: Source,
        context: RetrievingContext,
        completionHandler: (@Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)?) -> Bool
    {
        let options = context.options
        // 1. Check whether the image was already in target cache. If so, just get it.
        let targetCache = options.targetCache ?? cache
        let key = source.cacheKey
        let targetImageCached = targetCache.imageCachedType(
            forKey: key, processorIdentifier: options.processor.identifier)
        
        let validCache = targetImageCached.cached &&
            (options.fromMemoryCacheOrRefresh == false || targetImageCached == .memory)
        if validCache {
            targetCache.retrieveImage(forKey: key, options: options) { result in
                guard let completionHandler = completionHandler else { return }
                
                // TODO: Optimize it when we can use async across all the project.
                @Sendable func checkResultImageAndCallback(_ inputImage: KFCrossPlatformImage) {
                    var image = inputImage
                    if image.kf.imageFrameCount != nil && image.kf.imageFrameCount != 1, let data = image.kf.animatedImageData {
                        // Always recreate animated image representation since it is possible to be loaded in different options.
                        // https://github.com/onevcat/Kingfisher/issues/1923
                        image = options.processor.process(item: .data(data), options: options) ?? .init()
                    }
                    if let modifier = options.imageModifier {
                        image = modifier.modify(image)
                    }
                    let value = result.map {
                        RetrieveImageResult(
                            image: image,
                            cacheType: $0.cacheType,
                            source: source,
                            originalSource: context.originalSource,
                            data: { [image] in options.cacheSerializer.data(with: image, original: nil) }
                        )
                    }
                    completionHandler(value)
                }
                
                result.match { cacheResult in
                    options.callbackQueue.execute {
                        guard let image = cacheResult.image else {
                            completionHandler(.failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key))))
                            return
                        }
                        
                        if options.cacheSerializer.originalDataUsed {
                            let processor = options.processor
                            (options.processingQueue ?? self.processingQueue).execute {
                                let item = ImageProcessItem.image(image)
                                guard let processedImage = processor.process(item: item, options: options) else {
                                    let error = KingfisherError.processorError(
                                        reason: .processingFailed(processor: processor, item: item))
                                    options.callbackQueue.execute { completionHandler(.failure(error)) }
                                    return
                                }
                                options.callbackQueue.execute {
                                    checkResultImageAndCallback(processedImage)
                                }
                            }
                        } else {
                            checkResultImageAndCallback(image)
                        }
                    }
                } onFailure: { error in
                    options.callbackQueue.execute {
                        completionHandler(.failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key))))
                    }
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
        let originalImageCacheType = originalCache.imageCachedType(
            forKey: key, processorIdentifier: DefaultImageProcessor.default.identifier)
        let canAcceptDiskCache = !options.fromMemoryCacheOrRefresh
        
        let canUseOriginalImageCache =
            (canAcceptDiskCache && originalImageCacheType.cached) ||
            (!canAcceptDiskCache && originalImageCacheType == .memory)
        
        if canUseOriginalImageCache {
            // Now we are ready to get found the original image from cache. We need the unprocessed image, so remove
            // any processor from options first.
            var optionsWithoutProcessor = options
            optionsWithoutProcessor.processor = DefaultImageProcessor.default
            originalCache.retrieveImage(forKey: key, options: optionsWithoutProcessor) { result in

                result.match(
                    onSuccess: { cacheResult in
                        guard let image = cacheResult.image else {
                            assertionFailure("The image (under key: \(key) should be existing in the original cache.")
                            return
                        }

                        let processor = options.processor
                        (options.processingQueue ?? self.processingQueue).execute {
                            let item = ImageProcessItem.image(image)
                            guard let processedImage = processor.process(item: item, options: options) else {
                                let error = KingfisherError.processorError(
                                    reason: .processingFailed(processor: processor, item: item))
                                options.callbackQueue.execute { completionHandler?(.failure(error)) }
                                return
                            }

                            var cacheOptions = options
                            cacheOptions.callbackQueue = .untouch

                            let coordinator = CacheCallbackCoordinator(
                                shouldWaitForCache: options.waitForCache, shouldCacheOriginal: false)

                            let image = options.imageModifier?.modify(processedImage) ?? processedImage
                            let result = RetrieveImageResult(
                                image: image,
                                cacheType: .none,
                                source: source,
                                originalSource: context.originalSource,
                                data: { options.cacheSerializer.data(with: processedImage, original: nil) }
                            )

                            targetCache.store(
                                processedImage,
                                forKey: key,
                                options: cacheOptions,
                                toDisk: !options.cacheMemoryOnly)
                            {
                                _ in
                                coordinator.apply(.cachingImage) {
                                    options.callbackQueue.execute { completionHandler?(.success(result)) }
                                }
                            }

                            coordinator.apply(.cacheInitiated) {
                                options.callbackQueue.execute { completionHandler?(.success(result)) }
                            }
                        }
                    },
                    onFailure: { _ in
                        // This should not happen actually, since we already confirmed `originalImageCached` is `true`.
                        // Just in case...
                        options.callbackQueue.execute {
                            completionHandler?(
                                .failure(KingfisherError.cacheError(reason: .imageNotExisting(key: key)))
                            )
                        }
                    }
                )
            }
            return true
        }

        return false
    }
}

// Concurrency
extension KingfisherManager {
    
    /// Retrieves an image from a specified resource.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object defining data information, such as a key or URL.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image download progress is updated. This block is invoked only if the response
    ///   contains an `expectedContentLength` and always runs on the main queue.
    ///
    /// - Returns: The ``RetrieveImageResult`` containing the retrieved image object and cache type.
    /// - Throws: A ``KingfisherError`` if any issue occurred during the image retrieving progress.
    ///
    /// - Note: This method first checks whether the requested `resource` is already in the cache. If it is cached,
    /// it returns `nil` and invokes the `completionHandler` after retrieving the cached image. Otherwise, it downloads
    /// the `resource`, stores it in the cache, and then calls the `completionHandler`.
    ///
    public func retrieveImage(
        with resource: any Resource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil
    ) async throws -> RetrieveImageResult
    {
        try await retrieveImage(
            with: resource.convertToSource(),
            options: options,
            progressBlock: progressBlock
        )
    }
    
    /// Retrieves an image from a specified source.
    ///
    /// - Parameters:
    ///   - source: The ``Source`` object defining data information, such as a key or URL.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image download progress is updated. This block is invoked only if the response
    ///   contains an `expectedContentLength` and always runs on the main queue.
    ///
    /// - Returns: The ``RetrieveImageResult`` containing the retrieved image object and cache type.
    /// - Throws: A ``KingfisherError`` if any issue occurred during the image retrieving progress.
    ///
    /// - Note: This method first checks whether the requested `source` is already in the cache. If it is cached,
    /// it returns `nil` and invokes the `completionHandler` after retrieving the cached image. Otherwise, it downloads
    /// the `source`, stores it in the cache, and then calls the `completionHandler`.
    ///
    public func retrieveImage(
        with source: Source,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil
    ) async throws -> RetrieveImageResult
    {
        let options = currentDefaultOptions + (options ?? .empty)
        let info = KingfisherParsedOptionsInfo(options)
        return try await retrieveImage(
            with: source,
            options: info,
            progressBlock: progressBlock
        )
    }
    
    func retrieveImage(
        with source: Source,
        options: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil
    ) async throws -> RetrieveImageResult
    {
        var info = options
        if let block = progressBlock {
            info.onDataReceived = (info.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }
        return try await retrieveImage(
            with: source,
            options: info,
            progressiveImageSetter: nil
        )
    }
    
    func retrieveImage(
        with source: Source,
        options: KingfisherParsedOptionsInfo,
        progressiveImageSetter: ((KFCrossPlatformImage?) -> Void)? = nil,
        referenceTaskIdentifierChecker: (() -> Bool)? = nil
    ) async throws -> RetrieveImageResult
    {
        let task = CancellationDownloadTask()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let downloadTask = retrieveImage(
                    with: source,
                    options: options,
                    downloadTaskUpdated: { newTask in
                        Task {
                            await task.setTask(newTask)
                        }
                    },
                    progressiveImageSetter: progressiveImageSetter,
                    referenceTaskIdentifierChecker: referenceTaskIdentifierChecker,
                    completionHandler: { result in
                        continuation.resume(with: result)
                    }
                )
                if Task.isCancelled {
                    downloadTask?.cancel()
                } else {
                    Task {
                        await task.setTask(downloadTask)
                    }
                }
            }
        } onCancel: {
            Task {
                await task.task?.cancel()
            }
        }
    }
}

class RetrievingContext: @unchecked Sendable {

    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.RetrievingContextPropertyQueue")
    
    private var _options: KingfisherParsedOptionsInfo
    var options: KingfisherParsedOptionsInfo {
        get { propertyQueue.sync { _options } }
        set { propertyQueue.sync { _options = newValue } }
    }

    let originalSource: Source
    var propagationErrors: [PropagationError] = []

    init(options: KingfisherParsedOptionsInfo, originalSource: Source) {
        self.originalSource = originalSource
        _options = options
    }

    func popAlternativeSource() -> Source? {
        var localOptions = options
        guard var alternativeSources = localOptions.alternativeSources, !alternativeSources.isEmpty else {
            return nil
        }
        let nextSource = alternativeSources.removeFirst()
        
        localOptions.alternativeSources = alternativeSources
        options = localOptions
        
        return nextSource
    }

    @discardableResult
    func appendError(_ error: KingfisherError, to source: Source) -> [PropagationError] {
        let item = PropagationError(source: source, error: error)
        propagationErrors.append(item)
        return propagationErrors
    }
}

class CacheCallbackCoordinator: @unchecked Sendable {

    enum State {
        case idle
        case imageCached
        case originalImageCached
        case done
    }

    enum Action {
        case cacheInitiated
        case cachingImage
        case cachingOriginalImage
    }

    private let shouldWaitForCache: Bool
    private let shouldCacheOriginal: Bool
    private let stateQueue: DispatchQueue
    private var threadSafeState: State = .idle

    private(set) var state: State {
        set { stateQueue.sync { threadSafeState = newValue } }
        get { stateQueue.sync { threadSafeState } }
    }

    init(shouldWaitForCache: Bool, shouldCacheOriginal: Bool) {
        self.shouldWaitForCache = shouldWaitForCache
        self.shouldCacheOriginal = shouldCacheOriginal
        let stateQueueName = "com.onevcat.Kingfisher.CacheCallbackCoordinator.stateQueue.\(UUID().uuidString)"
        self.stateQueue = DispatchQueue(label: stateQueueName)
    }

    func apply(_ action: Action, trigger: () -> Void) {
        switch (state, action) {
        case (.done, _):
            break

        // From .idle
        case (.idle, .cacheInitiated):
            if !shouldWaitForCache {
                state = .done
                trigger()
            }
        case (.idle, .cachingImage):
            if shouldCacheOriginal {
                state = .imageCached
            } else {
                state = .done
                trigger()
            }
        case (.idle, .cachingOriginalImage):
            state = .originalImageCached

        // From .imageCached
        case (.imageCached, .cachingOriginalImage):
            state = .done
            trigger()

        // From .originalImageCached
        case (.originalImageCached, .cachingImage):
            state = .done
            trigger()

        default:
            assertionFailure("This case should not happen in CacheCallbackCoordinator: \(state) - \(action)")
        }
    }
}
