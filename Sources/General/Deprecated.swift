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

extension KingfisherClass where Base: Image {
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
        return KingfisherClass.image(data: data, options: options)
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

@available(*, deprecated, message: "Will be removed soon. Use `Result<ImageDownloadResult>` based callback instead")
public typealias ImageDownloaderCompletionHandler =
    ((_ image: Image?, _ error: NSError?, _ url: URL?, _ originalData: Data?) -> Void)

@available(*, deprecated, message: "Will be removed soon. Use `DownloadTask` to cancel a task.")
extension RetrieveImageTask {
    @available(*, deprecated, message: "RetrieveImageTask.empty will be removed soon. Use `nil` to represnt a no task.")
    public static let empty = RetrieveImageTask()
}

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
            case .success(let value): completionHandler?(value.image, nil, value.cacheType, value.imageURL)
            case .failure(let error): completionHandler?(nil, error as NSError, .none, resource.downloadURL)
            }
        }
    }
}

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
extension KingfisherClass where Base: ImageView {
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
                completionHandler?(value.image, nil, value.cacheType, value.imageURL)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

#if canImport(UIKit) && !os(watchOS)
extension KingfisherClass where Base: UIButton {
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
                completionHandler?(value.image, nil, value.cacheType, value.imageURL)
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
                completionHandler?(value.image, nil, value.cacheType, value.imageURL)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

#if os(watchOS)
import WatchKit
extension KingfisherClass where Base: WKInterfaceImage {
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
                completionHandler?(value.image, nil, value.cacheType, value.imageURL)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

#if os(macOS)
extension KingfisherClass where Base: NSButton {
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
                completionHandler?(value.image, nil, value.cacheType, value.imageURL)
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
                completionHandler?(value.image, nil, value.cacheType, value.imageURL)
            case .failure(let error):
                completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
#endif

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
        set { diskStorage.config.sizeLimit = Int(newValue) }
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
    @available(*, deprecated, message: "Use `Result` based `retrieveImageInDiskCache(forKey:options:callbackQueue:completionHandler:)` instead.",
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

    @available(*, deprecated, message: "Use `Result` based `retrieveImage(forKey:options:callbackQueue:completionHandler:)` instead.",
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
}

extension ImageCache {
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

    open func calculateDiskCacheSize(completion handler: @escaping ((_ size: UInt) -> Void)) {
        calculateDiskCacheSize { result in
            handler(result.value ?? 0)
        }
    }
}
