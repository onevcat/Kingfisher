//
//  KingfisherOptionsInfo.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/23.
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
    

/// `KingfisherOptionsInfo` is a typealias for `[KingfisherOptionsInfoItem]`.
/// You can utilize the enum of option items with values to control certain behaviors of Kingfisher.
public typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]

extension Array where Element == KingfisherOptionsInfoItem {
    static let empty: KingfisherOptionsInfo = []
}

/// Represents the available option items that can be used in ``KingfisherOptionsInfo``.
public enum KingfisherOptionsInfoItem: Sendable {
    
    /// Kingfisher will utilize the associated ``ImageCache`` object when performing related operations, such as
    /// attempting to retrieve cached images and storing downloaded images in it.
    case targetCache(ImageCache)
    
    /// The ``ImageCache`` used for storing and retrieving original images.
    ///
    /// If ``originalCache(_:)`` is specified in the options, it will be given preference for storing and retrieving
    /// original images. If there is no ``originalCache(_:)`` option, ``targetCache(_:)`` will be used to
    /// store original images as well.
    ///
    /// When using ``KingfisherManager`` to download and store an image, if ``cacheOriginalImage`` is applied in the
    /// options, the original image will be stored in the associated ``ImageCache`` of this option. 
    ///
    /// Simultaneously, if a requested final image (with a processor applied) cannot be found in the ``targetCache(_:)``,
    /// Kingfisher will attempt to search for the original image to see if it already exists. If found, it will be
    /// utilized and processed with the given processor. This optimization prevents downloading the same image multiple
    /// times.
    case originalCache(ImageCache)
    
    /// Kingfisher will utilize the associated ``ImageDownloader`` object to download the requested images.
    case downloader(ImageDownloader)

    /// This enum defines the transition effect to be applied when setting an image to an image view.
    ///
    /// Kingfisher uses the ``ImageTransition`` specified by this enum to animate the image in if it's downloaded from
    /// the web. 
    ///
    /// By default, the transition does not occur when the image is retrieved from either memory or disk cache. To
    /// force the transition even when the image is retrieved from the cache, also set
    /// ``KingfisherOptionsInfoItem/forceTransition``.
    case transition(ImageTransition)
    
    /// The associated `Float` value to be set as the priority of the image download task.
    ///
    /// This value should fall within the range of 0.0 to 1.0. If this option is not set, the default value
    ///  (`URLSessionTask.defaultPriority`) will be used.
    case downloadPriority(Float)
    
    /// When set, Kingfisher will disregard the cache and attempt to initiate a download task for the image source.
    case forceRefresh

    /// Sets whether Kingfisher should try to load from memory cache first, and then perform a refresh from network.
    ///
    /// When set, Kingfisher will attempt to retrieve the image from memory cache first. If the image is not found in 
    /// the memory cache, it will skip the disk cache and download the image again from the network. This is useful
    /// when you want to display a changeable image with the same URL within the same app session, while avoiding
    /// multiple downloads.
    case fromMemoryCacheOrRefresh
    
    /// When set, applying a transition to set the image in an image view will occur even when the image is retrieved 
    /// from the cache. Refer to the ``transition(_:)`` option for more details.
    case forceTransition
    
    /// When set, Kingfisher will cache the value only in memory and not on disk.
    case cacheMemoryOnly
    
    /// When set, Kingfisher will wait for the caching operation to be completed before invoking the completion block.
    case waitForCache
    
    /// When set, Kingfisher will attempt to retrieve the image solely from the cache and not from the network.
    ///
    /// If the image is not found in the cache, the image retrieval will fail with a
    /// ``KingfisherError/CacheErrorReason/imageNotExisting(key:)`` error.
    case onlyFromCache
    
    /// Decode the image on a background thread before usage.
    ///
    /// This process involves decoding the downloaded image data and performing off-screen rendering to extract pixel
    ///  information in the background. While this can accelerate display performance, it may require additional time
    ///  to prepare the image for use.
    case backgroundDecode

    /// The associated value will be used as the target queue of dispatch callbacks when retrieving images from
    /// cache. If not set, Kingfisher will use `.mainCurrentOrAsync` for callbacks.
    ///
    /// - Note: This option does not affect the callbacks for UI related extension methods. You will always get the
    /// callbacks called from main queue.
    
    /// The associated value will serve as the target queue for dispatch callbacks when retrieving images from the cache.
    ///
    /// If not set, Kingfisher will use ``CallbackQueue/mainCurrentOrAsync`` for callbacks.
    ///
    /// - Note: This option does not impact the callbacks for UI-related extension methods. Those callbacks will always 
    /// occur on the main queue.
    case callbackQueue(CallbackQueue)
    
    /// The associated value will be used as the scale factor when converting retrieved image data to an image object.
    ///
    /// Specify the image scale rather than your screen scale. You should set the correct scale when dealing with 2x or 
    /// 3x retina images. Otherwise, Kingfisher will convert the data to an image object with a scale of 1.0.
    case scaleFactor(CGFloat)

    /// Determines whether all the animated image data should be preloaded.
    ///
    /// The default value is `false`, which means only the following frames will be loaded on demand. If set to `true`, 
    /// all the animated image data will be loaded and decoded into memory.
    ///
    /// This option is primarily used for internal backward compatibility. It should not be set directly. Instead, you 
    /// should choose the appropriate image view class to control the GIF data loading. Kingfisher offers two classes
    /// for displaying GIF images: ``AnimatedImageView``, which does not preload all data, consumes less memory, but uses
    /// more CPU during display; and a regular image view (`UIImageView` or `NSImageView`), which loads all data at
    /// once, consumes more memory, but decodes image frames only once.
    case preloadAllAnimationData
    
    /// The contained ``ImageDownloadRequestModifier`` will be used to alter the request before it is sent.
    ///
    /// This is the final opportunity to modify the image download request. You can customize the request for various 
    /// purposes, such as adding an authentication token to the header, performing basic HTTP authentication, or URL
    /// mapping.
    ///
    /// By default, the original request is sent without any modifications.
    case requestModifier(any AsyncImageDownloadRequestModifier)

    /// The contained ``ImageDownloadRedirectHandler`` will be used to alter the request during redirection.
    ///
    /// This provides an opportunity to customize the image download request during redirection. You can modify the 
    /// request for various purposes, such as adding an authentication token to the header, performing basic HTTP
    /// authentication, or URL mapping.
    ///
    /// By default, the original redirection request is sent without any modifications.
    case redirectHandler(any ImageDownloadRedirectHandler)

    /// The processor used in the image retrieval task.
    ///
    /// After downloading is complete, a processor will convert the downloaded data into an image and/or apply various 
    /// filters or transformations to it.
    ///
    /// If a cache is linked to the downloader (which occurs when you use ``KingfisherManager`` or any of the view
    /// extension methods), the converted image will also be stored in the cache. If not set, the
    /// ``DefaultImageProcessor/default`` will be used.
    case processor(any ImageProcessor)

    /// Offers a ``CacheSerializer`` to convert data into an image object for retrieval from disk cache, or vice versa
    /// for storage in the disk cache.
    ///
    /// If not set, the ``DefaultCacheSerializer/default`` will be used.
    case cacheSerializer(any CacheSerializer)

    /// An ``ImageModifier`` for making adjustments to an image right before it is used.
    ///
    /// If the image was directly fetched from the downloader, the modifier will be applied immediately after the 
    /// ``ImageProcessor``. If the image is retrieved from a cache, the modifier will be applied after the
    /// ``CacheSerializer``.
    ///
    /// Use the ``ImageModifier`` when you need to set properties that do not persist when caching the image with a 
    /// specific image type. Examples include setting the `renderingMode` or `alignmentInsets` of a `UIImage`.
    case imageModifier(any ImageModifier)

    /// Keep the existing image of image view while setting another image to it.
    /// By setting this option, the placeholder image parameter of image view extension method
    /// will be ignored and the current image will be kept while loading or downloading the new image.
    case keepCurrentImageWhileLoading
    
    /// When set, Kingfisher will load only the first frame from an animated image file as a single image.
    ///
    /// Loading animated images can consume a significant amount of memory. This option is useful when you want to 
    /// display a static preview of the first frame from an animated image. It will be ignored if the target image is
    /// not animated image data.
    case onlyLoadFirstFrame
    
    /// When set and an non-default ``ImageProcessor`` is used, Kingfisher will attempt to cache both the final result
    /// and the original image.
    ///
    /// Kingfisher will have the opportunity to use the original image when another processor is applied to the same 
    /// resource, instead of downloading it anew. You can use ``KingfisherOptionsInfoItem/originalCache(_:)`` to
    /// specify a cache for the original images if necessary.
    ///
    /// The original image will only be cached to disk storage.
    case cacheOriginalImage
    
    /// When set and an image retrieval error occurs, Kingfisher will replace the requested image with the provided 
    /// image (or an empty image).
    ///
    /// This is useful when you prefer not to display a placeholder during loading but want to use a default image when
    /// requests fail.
    case onFailureImage(KFCrossPlatformImage?)
    
    /// When set and used in methods of ``ImagePrefetcher``, the prefetching operation will aggressively load the images 
    /// into memory storage.
    ///
    /// By default, this option is not included in the options. This means that if the requested image is already in 
    /// the disk cache, Kingfisher will not attempt to load it into memory.
    case alsoPrefetchToMemory
    
    /// When set, disk storage loading will occur in the same calling queue.
    ///
    /// By default, disk storage file loading operates on its own queue with asynchronous dispatch behavior. While this 
    /// provides improved non-blocking disk loading performance, it can lead to flickering when you reload an image from
    /// disk if the image view already has an image set.
    ///
    /// Setting this option will eliminate that flickering by keeping all loading in the same queue (typically the UI 
    /// queue if you are using Kingfisher's extension methods to set an image). However, this comes with a tradeoff in
    /// loading performance.
    case loadDiskFileSynchronously

    /// Options for controlling the data writing process to disk storage.
    ///
    /// When set, these options will be passed to the store operation for new files.
    case diskStoreWriteOptions(Data.WritingOptions)

    /// When set, use the associated ``StorageExpiration`` value for the memory cache to determine the expiration date.
    ///
    /// By default, the underlying ``MemoryStorage/Backend`` uses the expiration defined in its ``MemoryStorage/Config``
    /// for all items. If this option is set, the ``MemoryStorage/Backend`` will utilize the associated value to 
    /// override the configuration setting for this caching item.
    case memoryCacheExpiration(StorageExpiration)
    
    /// When set, use the associated ``ExpirationExtending`` value for the memory cache to determine the extending policy
    /// when setting the next expiration date.
    ///
    /// The item's expiration date will be extended after access to keep the "most recently accessed" items alive for a 
    /// longer duration in the cache.
    ///
    /// By default, the underlying ``MemoryStorage/Backend`` uses the initial cache expiration as the extending value,
    /// which is ``ExpirationExtending/cacheTime``.
    ///
    /// - Note: To disable expiration extending entirely, use ``ExpirationExtending/none``.
    case memoryCacheAccessExtendingExpiration(ExpirationExtending)
    
    /// When set, use the associated ``StorageExpiration`` value for the disk cache to determine the expiration date.
    ///
    /// By default, the underlying ``DiskStorage/Backend`` uses the expiration defined in its ``DiskStorage/Config``
    /// for all items. If this option is set, the ``DiskStorage/Backend`` will utilize the associated value to override
    /// the configuration setting for this caching item.
    case diskCacheExpiration(StorageExpiration)

    /// When set, use the associated ``ExpirationExtending`` value for the disk cache to determine the extending policy
    /// when setting the next expiration date.
    ///
    /// The item's expiration date will be extended after access to keep the "most recently accessed" items alive for a
    /// longer duration in the cache.
    ///
    /// By default, the underlying ``DiskStorage/Backend`` uses the initial cache expiration as the extending value,
    /// which is ``ExpirationExtending/cacheTime``.
    ///
    /// - Note: To disable expiration extending entirely, use ``ExpirationExtending/none``.
    case diskCacheAccessExtendingExpiration(ExpirationExtending)
    
    /// Determines the queue on which image processing should occur.
    ///
    /// By default, Kingfisher uses an internal pre-defined serial queue to process images. Use this option to modify
    /// this behavior. For instance, you can specify ``CallbackQueue/mainCurrentOrAsync`` to process the image on the
    /// main queue, preventing potential flickering (but with the risk of blocking the UI, especially if the processor
    /// is time-consuming).
    case processingQueue(CallbackQueue)
    
    /// Enables progressive image loading.
    ///
    /// Kingfisher will use the associated ``ImageProgressive`` value to process progressive JPEG data and display 
    /// it progressively, if the image supports it.
    case progressiveJPEG(ImageProgressive)

    /// Sets a set of alternative sources when the original input `Source` fails to load.
    ///
    ///  The `Source`s in the associated
    /// array will be used to start a new image loading task if the previous task fails due to an error. The image
    /// source loading process will stop as soon as a source is loaded successfully. If all `[Source]`s are used but
    /// the loading is still failing, an `imageSettingError` with `alternativeSourcesExhausted` as its reason will be
    /// thrown out.
    ///
    /// This option is useful if you want to implement a fallback solution for setting image.
    ///
    /// User cancellation will not trigger the alternative source loading.
    ///
    
    /// Specifies a set of alternative sources to use when the original input ``Source`` fails to load.
    ///
    /// The ``Source``s in the associated array will be used to start a new image loading task if the previous task
    /// fails due to an error. The image source loading process will halt as soon as a source is loaded successfully.
    /// If all ``Source``s are used, but loading still fails, a
    /// ``KingfisherError/ImageSettingErrorReason/alternativeSourcesExhausted(_:)``will be used as the error in the
    /// result.
    ///
    /// This option is useful for implementing a fallback solution for image setting.
    ///
    /// - Note: User cancellation will not trigger the loading of alternative sources.
    case alternativeSources([Source])

    /// Provides a retry strategy to use when something goes wrong during the image retrieval process from
    /// ``KingfisherManager``.
    ///
    /// You can define a strategy by creating a type that conforms to the ``RetryStrategy`` protocol. When Kingfisher
    /// encounters a loading failure, it follows the defined retry strategy and retries until a ``RetryDecision/stop``
    /// is received.
    ///
    /// - Note: All extension methods of Kingfisher (the `kf` extensions on `UIImageView` or `UIButton`, for example)
    /// retrieve images through ``KingfisherManager``, so the retry strategy also applies when using them. However,
    /// this option does not apply when passed to an ``ImageDownloader`` or an ``ImageCache`` directly.
    case retryStrategy(any RetryStrategy)

    /// Specifies the `Source` to load when the user enables Low Data Mode and the original source fails due to the data
    /// constraint.
    ///
    /// When the user enables Low Data Mode in the system settings, and the original source fails with an
    /// `NSURLErrorNetworkUnavailableReason.constrained` error, Kingfisher uses this source instead to load an image
    ///  for Low Data Mode.
    ///
    /// When this option is set, the `allowsConstrainedNetworkAccess` property of the request for the original source 
    /// will be set to `false`, and the ``Source`` in the associated value will be used to retrieve the image for Low
    /// Data Mode. Typically, you can provide a low-resolution version of your image or a local image provider to
    /// display a placeholder to save data usage.
    ///
    /// If not set or if the associated optional ``Source`` value is `nil`, the device's Low Data Mode will be ignored,
    /// and the original source will be loaded following the system default behavior.
    case lowDataMode(Source?)
}

// MARK: - KingfisherParsedOptionsInfo

// Improve performance by parsing the input `KingfisherOptionsInfo` (self) first.
// So we can prevent the iterating over the options array again and again.

/// Represents the parsed options info used throughout Kingfisher methods.
///
/// Each property in this type corresponds to a case member in ``KingfisherOptionsInfoItem``. When a
///  ``KingfisherOptionsInfo`` is sent to Kingfisher-related methods, it will be parsed and converted to a
///  ``KingfisherParsedOptionsInfo`` first before passing through the internal methods.
public struct KingfisherParsedOptionsInfo: Sendable {

    public var targetCache: ImageCache? = nil
    public var originalCache: ImageCache? = nil
    public var downloader: ImageDownloader? = nil
    public var transition: ImageTransition = .none
    public var downloadPriority: Float = URLSessionTask.defaultPriority
    public var forceRefresh = false
    public var fromMemoryCacheOrRefresh = false
    public var forceTransition = false
    public var cacheMemoryOnly = false
    public var waitForCache = false
    public var onlyFromCache = false
    public var backgroundDecode = false
    public var preloadAllAnimationData = false
    public var callbackQueue: CallbackQueue = .mainCurrentOrAsync
    public var scaleFactor: CGFloat = 1.0
    public var requestModifier: (any AsyncImageDownloadRequestModifier)? = nil
    public var redirectHandler: (any ImageDownloadRedirectHandler)? = nil
    public var processor: any ImageProcessor = DefaultImageProcessor.default
    public var imageModifier: (any ImageModifier)? = nil
    public var cacheSerializer: any CacheSerializer = DefaultCacheSerializer.default
    public var keepCurrentImageWhileLoading = false
    public var onlyLoadFirstFrame = false
    public var cacheOriginalImage = false
    public var onFailureImage: Optional<KFCrossPlatformImage?> = .none
    public var alsoPrefetchToMemory = false
    public var loadDiskFileSynchronously = false
    public var diskStoreWriteOptions: Data.WritingOptions = []
    public var memoryCacheExpiration: StorageExpiration? = nil
    public var memoryCacheAccessExtendingExpiration: ExpirationExtending = .cacheTime
    public var diskCacheExpiration: StorageExpiration? = nil
    public var diskCacheAccessExtendingExpiration: ExpirationExtending = .cacheTime
    public var processingQueue: CallbackQueue? = nil
    public var progressiveJPEG: ImageProgressive? = nil
    public var alternativeSources: [Source]? = nil
    public var retryStrategy: (any RetryStrategy)? = nil
    public var lowDataModeSource: Source? = nil

    var onDataReceived: [any DataReceivingSideEffect]? = nil
    
    public init(_ info: KingfisherOptionsInfo?) {
        guard let info = info else { return }
        for option in info {
            switch option {
            case .targetCache(let value): targetCache = value
            case .originalCache(let value): originalCache = value
            case .downloader(let value): downloader = value
            case .transition(let value): transition = value
            case .downloadPriority(let value): downloadPriority = value
            case .forceRefresh: forceRefresh = true
            case .fromMemoryCacheOrRefresh: fromMemoryCacheOrRefresh = true
            case .forceTransition: forceTransition = true
            case .cacheMemoryOnly: cacheMemoryOnly = true
            case .waitForCache: waitForCache = true
            case .onlyFromCache: onlyFromCache = true
            case .backgroundDecode: backgroundDecode = true
            case .preloadAllAnimationData: preloadAllAnimationData = true
            case .callbackQueue(let value): callbackQueue = value
            case .scaleFactor(let value): scaleFactor = value
            case .requestModifier(let value): requestModifier = value
            case .redirectHandler(let value): redirectHandler = value
            case .processor(let value): processor = value
            case .imageModifier(let value): imageModifier = value
            case .cacheSerializer(let value): cacheSerializer = value
            case .keepCurrentImageWhileLoading: keepCurrentImageWhileLoading = true
            case .onlyLoadFirstFrame: onlyLoadFirstFrame = true
            case .cacheOriginalImage: cacheOriginalImage = true
            case .onFailureImage(let value): onFailureImage = .some(value)
            case .alsoPrefetchToMemory: alsoPrefetchToMemory = true
            case .loadDiskFileSynchronously: loadDiskFileSynchronously = true
            case .diskStoreWriteOptions(let options): diskStoreWriteOptions = options
            case .memoryCacheExpiration(let expiration): memoryCacheExpiration = expiration
            case .memoryCacheAccessExtendingExpiration(let expirationExtending): memoryCacheAccessExtendingExpiration = expirationExtending
            case .diskCacheExpiration(let expiration): diskCacheExpiration = expiration
            case .diskCacheAccessExtendingExpiration(let expirationExtending): diskCacheAccessExtendingExpiration = expirationExtending
            case .processingQueue(let queue): processingQueue = queue
            case .progressiveJPEG(let value): progressiveJPEG = value
            case .alternativeSources(let sources): alternativeSources = sources
            case .retryStrategy(let strategy): retryStrategy = strategy
            case .lowDataMode(let source): lowDataModeSource = source
            }
        }

        if originalCache == nil {
            originalCache = targetCache
        }
    }
}

extension KingfisherParsedOptionsInfo {
    var imageCreatingOptions: ImageCreatingOptions {
        return ImageCreatingOptions(
            scale: scaleFactor,
            duration: 0.0,
            preloadAll: preloadAllAnimationData,
            onlyFirstFrame: onlyLoadFirstFrame)
    }
}

protocol DataReceivingSideEffect: AnyObject, Sendable {
    var onShouldApply: () -> Bool { get set }
    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data)
}

class ImageLoadingProgressSideEffect: DataReceivingSideEffect, @unchecked Sendable {

    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageLoadingProgressSideEffectPropertyQueue")
    
    private var _onShouldApply: () -> Bool = { return true }
    
    var onShouldApply: () -> Bool {
        get { propertyQueue.sync { _onShouldApply } }
        set { propertyQueue.sync { _onShouldApply = newValue } }
    }
    
    let block: DownloadProgressBlock

    init(_ block: @escaping DownloadProgressBlock) {
        self.block = block
    }

    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {
        DispatchQueue.main.async {
            guard self.onShouldApply() else { return }
            guard let expectedContentLength = task.task.response?.expectedContentLength,
                      expectedContentLength != -1 else
            {
                return
            }

            let dataLength = Int64(task.mutableData.count)
            self.block(dataLength, expectedContentLength)
        }
    }
}
