//
//  Deprecated.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/28.
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

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - Deprecated
extension KingfisherWrapper where Base: Image {
    @available(*, deprecated, message:
    "Will be removed soon. Pass parameters with `ImageCreatingOptions`, use `image(with:options:)` instead.")
    public static func image(
        data: Data,
        scale: CGFloat,
        preloadAllAnimationData: Bool,
        onlyFirstFrame: Bool) -> Image?
    {
        let options = ImageCreatingOptions(
            scale: scale,
            duration: 0.0,
            preloadAll: preloadAllAnimationData,
            onlyFirstFrame: onlyFirstFrame)
        return KingfisherWrapper.image(data: data, options: options)
    }
    
    @available(*, deprecated, message:
    "Will be removed soon. Pass parameters with `ImageCreatingOptions`, use `animatedImage(with:options:)` instead.")
    public static func animated(
        with data: Data,
        scale: CGFloat = 1.0,
        duration: TimeInterval = 0.0,
        preloadAll: Bool,
        onlyFirstFrame: Bool = false) -> Image?
    {
        let options = ImageCreatingOptions(
            scale: scale, duration: duration, preloadAll: preloadAll, onlyFirstFrame: onlyFirstFrame)
        return animatedImage(data: data, options: options)
    }
}

@available(*, deprecated, message: "Will be removed soon. Use `Result<RetrieveImageResult>` based callback instead")
public typealias CompletionHandler =
    ((_ image: Image?, _ error: NSError?, _ cacheType: CacheType, _ imageURL: URL?) -> Void)

@available(*, deprecated, message: "Will be removed soon. Use `Result<ImageLoadingResult>` based callback instead")
public typealias ImageDownloaderCompletionHandler =
    ((_ image: Image?, _ error: NSError?, _ url: URL?, _ originalData: Data?) -> Void)

// MARK: - Deprecated
@available(*, deprecated, message: "Will be removed soon. Use `DownloadTask` to cancel a task.")
extension RetrieveImageTask {
    @available(*, deprecated, message: "RetrieveImageTask.empty will be removed soon. Use `nil` to represent a no task.")
    public static let empty = RetrieveImageTask()
}

// MARK: - Deprecated
extension KingfisherManager {
    /// Get an image with resource.
    /// If `.empty` is used as `options`, Kingfisher will seek the image in memory and disk first.
    /// If not found, it will download the image at `resource.downloadURL` and cache it with `resource.cacheKey`.
    /// These default behaviors could be adjusted by passing different options. See `KingfisherOptions` for more.
    ///
    /// - Parameters:
    ///   - resource: Resource object contains information such as `cacheKey` and `downloadURL`.
    ///   - options: A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time downloaded data changed. This could be used as a progress UI.
    ///   - completionHandler: Called when the whole retrieving process finished.
    /// - Returns: A `RetrieveImageTask` task object. You can use this object to cancel the task.
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    public func retrieveImage(with resource: Resource,
                              options: KingfisherOptionsInfo?,
                              progressBlock: DownloadProgressBlock?,
                              completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return retrieveImage(with: resource, options: options, progressBlock: progressBlock) {
            result in
            switch result {
            case .success(let value): completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error): completionHandler?(nil, error as NSError, .none, resource.downloadURL)
            }
        }
    }
}

// MARK: - Deprecated
extension ImageDownloader {
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    open func downloadImage(with url: URL,
                            retrieveImageTask: RetrieveImageTask? = nil,
                            options: KingfisherOptionsInfo? = nil,
                            progressBlock: ImageDownloaderProgressBlock? = nil,
                            completionHandler: ImageDownloaderCompletionHandler?) -> DownloadTask?
    {
        return downloadImage(with: url, options: options, progressBlock: progressBlock) {
            result in
            switch result {
            case .success(let value): completionHandler?(value.image, nil, value.url, value.originalData)
            case .failure(let error): completionHandler?(nil, error as NSError, nil, nil)
            }
        }
    }
}

@available(*, deprecated, message: "RetrieveImageDownloadTask is removed. Use `DownloadTask` to cancel a task.")
public struct RetrieveImageDownloadTask {
}

@available(*, deprecated, message: "RetrieveImageTask is removed. Use `DownloadTask` to cancel a task.")
public final class RetrieveImageTask {
}

@available(*, deprecated, message: "Use `DownloadProgressBlock` instead.", renamed: "DownloadProgressBlock")
public typealias ImageDownloaderProgressBlock = DownloadProgressBlock

#if !os(watchOS)
// MARK: - Deprecated
extension KingfisherWrapper where Base: ImageView {
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Placeholder? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return setImage(with: resource, placeholder: placeholder, options: options, progressBlock: progressBlock) {
            result in
            switch result {
            case .success(let value):
                completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

#if canImport(UIKit) && !os(watchOS)
// MARK: - Deprecated
extension KingfisherWrapper where Base: UIButton {
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    public func setImage(
        with resource: Resource?,
        for state: UIControl.State,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return setImage(
            with: resource,
            for: state,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock)
        {
            result in
            switch result {
            case .success(let value):
                completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
    
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    public func setBackgroundImage(
        with resource: Resource?,
        for state: UIControl.State,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return setBackgroundImage(
            with: resource,
            for: state,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock)
        {
            result in
            switch result {
            case .success(let value):
                completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

#if os(watchOS)
import WatchKit
// MARK: - Deprecated
extension KingfisherWrapper where Base: WKInterfaceImage {
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    public func setImage(_ resource: Resource?,
                         placeholder: Image? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return setImage(
            with: resource,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock)
        {
            result in
            switch result {
            case .success(let value):
                completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

#if os(macOS)
// MARK: - Deprecated
extension KingfisherWrapper where Base: NSButton {
    @discardableResult
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    public func setImage(with resource: Resource?,
                         placeholder: Image? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return setImage(
            with: resource,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock)
        {
            result in
            switch result {
            case .success(let value):
                completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
    
    @discardableResult
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    public func setAlternateImage(with resource: Resource?,
                                  placeholder: Image? = nil,
                                  options: KingfisherOptionsInfo? = nil,
                                  progressBlock: DownloadProgressBlock? = nil,
                                  completionHandler: CompletionHandler?) -> DownloadTask?
    {
        return setAlternateImage(
            with: resource,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock)
        {
            result in
            switch result {
            case .success(let value):
                completionHandler?(value.image, nil, value.cacheType, value.source.url)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

// MARK: - Deprecated
extension ImageCache {
    /// The largest cache cost of memory cache. The total cost is pixel count of
    /// all cached images in memory.
    /// Default is unlimited. Memory cache will be purged automatically when a
    /// memory warning notification is received.
    @available(*, deprecated, message: "Use `memoryStorage.config.totalCostLimit` instead.",
    renamed: "memoryStorage.config.totalCostLimit")
    open var maxMemoryCost: Int {
        get { return memoryStorage.config.totalCostLimit }
        set { memoryStorage.config.totalCostLimit = newValue }
    }

    /// The default DiskCachePathClosure
    @available(*, deprecated, message: "Not needed anymore.")
    public final class func defaultDiskCachePathClosure(path: String?, cacheName: String) -> String {
        let dstPath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return (dstPath as NSString).appendingPathComponent(cacheName)
    }

    /// The default file extension appended to cached files.
    @available(*, deprecated, message: "Use `diskStorage.config.pathExtension` instead.",
    renamed: "diskStorage.config.pathExtension")
    open var pathExtension: String? {
        get { return diskStorage.config.pathExtension }
        set { diskStorage.config.pathExtension = newValue }
    }
    
    ///The disk cache location.
    @available(*, deprecated, message: "Use `diskStorage.directoryURL.absoluteString` instead.",
    renamed: "diskStorage.directoryURL.absoluteString")
    public var diskCachePath: String {
        return diskStorage.directoryURL.absoluteString
    }
    
    /// The largest disk size can be taken for the cache. It is the total
    /// allocated size of cached files in bytes.
    /// Default is no limit.
    @available(*, deprecated, message: "Use `diskStorage.config.sizeLimit` instead.",
    renamed: "diskStorage.config.sizeLimit")
    open var maxDiskCacheSize: UInt {
        get { return UInt(diskStorage.config.sizeLimit) }
        set { diskStorage.config.sizeLimit = newValue }
    }
    
    @available(*, deprecated, message: "Use `diskStorage.cacheFileURL(forKey:).path` instead.",
    renamed: "diskStorage.cacheFileURL(forKey:)")
    open func cachePath(forComputedKey key: String) -> String {
        return diskStorage.cacheFileURL(forKey: key).path
    }
    
    /**
     Get an image for a key from disk.
     
     - parameter key:     Key for the image.
     - parameter options: Options of retrieving image. If you need to retrieve an image which was
     stored with a specified `ImageProcessor`, pass the processor in the option too.
     
     - returns: The image object if it is cached, or `nil` if there is no such key in the cache.
     */
    @available(*, deprecated,
    message: "Use `Result` based `retrieveImageInDiskCache(forKey:options:callbackQueue:completionHandler:)` instead.",
    renamed: "retrieveImageInDiskCache(forKey:options:callbackQueue:completionHandler:)")
    open func retrieveImageInDiskCache(forKey key: String, options: KingfisherOptionsInfo? = nil) -> Image? {
        let options = options ?? .empty
        let computedKey = key.computedKey(with: options.processor.identifier)
        do {
            if let data = try diskStorage.value(forKey: computedKey) {
                return options.cacheSerializer.image(with: data, options: options)
            }
        } catch {}
        return nil
    }

    @available(*, deprecated,
    message: "Use `Result` based `retrieveImage(forKey:options:callbackQueue:completionHandler:)` instead.",
    renamed: "retrieveImage(forKey:options:callbackQueue:completionHandler:)")
    open func retrieveImage(forKey key: String,
                            options: KingfisherOptionsInfo?,
                            completionHandler: ((Image?, CacheType) -> Void)?)
    {
        retrieveImage(
            forKey: key,
            options: options,
            callbackQueue: .dispatch((options ?? .empty).callbackDispatchQueue))
        {
            result in
            completionHandler?(result.value?.image, result.value?.cacheType ?? .none)
        }
    }

    /// The longest time duration in second of the cache being stored in disk.
    /// Default is 1 week (60 * 60 * 24 * 7 seconds).
    /// Setting this to a negative value will make the disk cache never expiring.
    @available(*, deprecated, message: "Deprecated. Use `diskStorage.config.expiration` instead")
    open var maxCachePeriodInSecond: TimeInterval {
        get { return diskStorage.config.expiration.timeInterval }
        set { diskStorage.config.expiration = .seconds(newValue) }
    }

    @available(*, deprecated, message: "Use `Result` based callback instead.")
    open func store(_ image: Image,
                    original: Data? = nil,
                    forKey key: String,
                    processorIdentifier identifier: String = "",
                    cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
                    toDisk: Bool = true,
                    completionHandler: (() -> Void)?)
    {
        store(
            image,
            original: original,
            forKey: key,
            processorIdentifier: identifier,
            cacheSerializer: serializer,
            toDisk: toDisk)
        {
            _ in
            completionHandler?()
        }
    }

    @available(*, deprecated, message: "Use the `Result`-based `calculateDiskStorageSize` instead.")
    open func calculateDiskCacheSize(completion handler: @escaping ((_ size: UInt) -> Void)) {
        calculateDiskStorageSize { result in
            handler(result.value ?? 0)
        }
    }
}

// MARK: - Deprecated
public extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    /// The queue of callbacks should happen from Kingfisher.
    @available(*, deprecated, message: "Use `callbackQueue` instead.", renamed: "callbackQueue")
    public var callbackDispatchQueue: DispatchQueue {
        return KingfisherParsedOptionsInfo(Array(self)).callbackQueue.queue
    }
}

/// Error domain of Kingfisher
@available(*, deprecated, message: "Use `KingfisherError.domain` instead.", renamed: "KingfisherError.domain")
public let KingfisherErrorDomain = "com.onevcat.Kingfisher.Error"

/// Key will be used in the `userInfo` of `.invalidStatusCode`
@available(*, unavailable,
message: "Use `.invalidHTTPStatusCode` or `isInvalidResponseStatusCode` of `KingfisherError` instead for the status code.")
public let KingfisherErrorStatusCodeKey = "statusCode"

// MARK: - Deprecated
public extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    /// The target `ImageCache` which is used.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `targetCache` instead.")
    public var targetCache: ImageCache? {
        return KingfisherParsedOptionsInfo(Array(self)).targetCache
    }

    /// The original `ImageCache` which is used.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `originalCache` instead.")
    public var originalCache: ImageCache? {
        return KingfisherParsedOptionsInfo(Array(self)).originalCache
    }

    /// The `ImageDownloader` which is specified.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `downloader` instead.")
    public var downloader: ImageDownloader? {
        return KingfisherParsedOptionsInfo(Array(self)).downloader
    }

    /// Member for animation transition when using UIImageView.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `transition` instead.")
    public var transition: ImageTransition {
        return KingfisherParsedOptionsInfo(Array(self)).transition
    }

    /// A `Float` value set as the priority of image download task. The value for it should be
    /// between 0.0~1.0.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `downloadPriority` instead.")
    public var downloadPriority: Float {
        return KingfisherParsedOptionsInfo(Array(self)).downloadPriority
    }

    /// Whether an image will be always downloaded again or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `forceRefresh` instead.")
    public var forceRefresh: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).forceRefresh
    }

    /// Whether an image should be got only from memory cache or download.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `fromMemoryCacheOrRefresh` instead.")
    public var fromMemoryCacheOrRefresh: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).fromMemoryCacheOrRefresh
    }

    /// Whether the transition should always happen or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `forceTransition` instead.")
    public var forceTransition: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).forceTransition
    }

    /// Whether cache the image only in memory or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `cacheMemoryOnly` instead.")
    public var cacheMemoryOnly: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).cacheMemoryOnly
    }

    /// Whether the caching operation will be waited or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `waitForCache` instead.")
    public var waitForCache: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).waitForCache
    }

    /// Whether only load the images from cache or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `onlyFromCache` instead.")
    public var onlyFromCache: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).onlyFromCache
    }

    /// Whether the image should be decoded in background or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `backgroundDecode` instead.")
    public var backgroundDecode: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).backgroundDecode
    }

    /// Whether the image data should be all loaded at once if it is an animated image.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `preloadAllAnimationData` instead.")
    public var preloadAllAnimationData: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).preloadAllAnimationData
    }

    /// The `CallbackQueue` on which completion handler should be invoked.
    /// If not set in the options, `.mainCurrentOrAsync` will be used.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `callbackQueue` instead.")
    public var callbackQueue: CallbackQueue {
        return KingfisherParsedOptionsInfo(Array(self)).callbackQueue
    }

    /// The scale factor which should be used for the image.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `scaleFactor` instead.")
    public var scaleFactor: CGFloat {
        return KingfisherParsedOptionsInfo(Array(self)).scaleFactor
    }

    /// The `ImageDownloadRequestModifier` will be used before sending a download request.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `requestModifier` instead.")
    public var modifier: ImageDownloadRequestModifier {
        return KingfisherParsedOptionsInfo(Array(self)).requestModifier
    }

    /// `ImageProcessor` for processing when the downloading finishes.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `processor` instead.")
    public var processor: ImageProcessor {
        return KingfisherParsedOptionsInfo(Array(self)).processor
    }

    /// `ImageModifier` for modifying right before the image is displayed.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `imageModifier` instead.")
    public var imageModifier: ImageModifier {
        return KingfisherParsedOptionsInfo(Array(self)).imageModifier
    }

    /// `CacheSerializer` to convert image to data for storing in cache.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `cacheSerializer` instead.")
    public var cacheSerializer: CacheSerializer {
        return KingfisherParsedOptionsInfo(Array(self)).cacheSerializer
    }

    /// Keep the existing image while setting another image to an image view.
    /// Or the placeholder will be used while downloading.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `keepCurrentImageWhileLoading` instead.")
    public var keepCurrentImageWhileLoading: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).keepCurrentImageWhileLoading
    }

    /// Whether the options contains `.onlyLoadFirstFrame`.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `onlyLoadFirstFrame` instead.")
    public var onlyLoadFirstFrame: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).onlyLoadFirstFrame
    }

    /// Whether the options contains `.cacheOriginalImage`.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `cacheOriginalImage` instead.")
    public var cacheOriginalImage: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).cacheOriginalImage
    }

    /// The image which should be used when download image request fails.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `onFailureImage` instead.")
    public var onFailureImage: Optional<Image?> {
        return KingfisherParsedOptionsInfo(Array(self)).onFailureImage
    }

    /// Whether the `ImagePrefetcher` should load images to memory in an aggressive way or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `alsoPrefetchToMemory` instead.")
    public var alsoPrefetchToMemory: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).alsoPrefetchToMemory
    }

    /// Whether the disk storage file loading should happen in a synchronous behavior or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `KingfisherOptionsInfo` and use `loadDiskFileSynchronously` instead.")
    public var loadDiskFileSynchronously: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).loadDiskFileSynchronously
    }
}
