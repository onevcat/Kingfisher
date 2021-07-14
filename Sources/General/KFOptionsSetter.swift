//
//  KFOptionsSetter.swift
//  Kingfisher
//
//  Created by onevcat on 2020/12/22.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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
import CoreGraphics

public protocol KFOptionSetter {
    var options: KingfisherParsedOptionsInfo { get nonmutating set }

    var onFailureDelegate: Delegate<KingfisherError, Void> { get }
    var onSuccessDelegate: Delegate<RetrieveImageResult, Void> { get }
    var onProgressDelegate: Delegate<(Int64, Int64), Void> { get }

    var delegateObserver: AnyObject { get }
}

extension KF.Builder: KFOptionSetter {
    public var delegateObserver: AnyObject { self }
}

// MARK: - Life cycles
extension KFOptionSetter {
    /// Sets the progress block to current builder.
    /// - Parameter block: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. If `block` is `nil`, the callback
    ///                    will be reset.
    /// - Returns: A `Self` value with changes applied.
    public func onProgress(_ block: DownloadProgressBlock?) -> Self {
        onProgressDelegate.delegate(on: delegateObserver) { (observer, result) in
            block?(result.0, result.1)
        }
        return self
    }

    /// Sets the the done block to current builder.
    /// - Parameter block: Called when the image task successfully completes and the the image set is done. If `block`
    ///                    is `nil`, the callback will be reset.
    /// - Returns: A `KF.Builder` with changes applied.
    public func onSuccess(_ block: ((RetrieveImageResult) -> Void)?) -> Self {
        onSuccessDelegate.delegate(on: delegateObserver) { (observer, result) in
            block?(result)
        }
        return self
    }

    /// Sets the catch block to current builder.
    /// - Parameter block: Called when an error happens during the image task. If `block`
    ///                    is `nil`, the callback will be reset.
    /// - Returns: A `KF.Builder` with changes applied.
    public func onFailure(_ block: ((KingfisherError) -> Void)?) -> Self {
        onFailureDelegate.delegate(on: delegateObserver) { (observer, error) in
            block?(error)
        }
        return self
    }
}

// MARK: - Basic options settings.
extension KFOptionSetter {
    /// Sets the target image cache for this task.
    /// - Parameter cache: The target cache is about to be used for the task.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// Kingfisher will use the associated `ImageCache` object when handling related operations,
    /// including trying to retrieve the cached images and store the downloaded image to it.
    ///
    public func targetCache(_ cache: ImageCache) -> Self {
        options.targetCache = cache
        return self
    }

    /// Sets the target image cache to store the original downloaded image for this task.
    /// - Parameter cache: The target cache is about to be used for storing the original downloaded image from the task.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// The `ImageCache` for storing and retrieving original images. If `originalCache` is
    /// contained in the options, it will be preferred for storing and retrieving original images.
    /// If there is no `.originalCache` in the options, `.targetCache` will be used to store original images.
    ///
    /// When using KingfisherManager to download and store an image, if `cacheOriginalImage` is
    /// applied in the option, the original image will be stored to this `originalCache`. At the
    /// same time, if a requested final image (with processor applied) cannot be found in `targetCache`,
    /// Kingfisher will try to search the original image to check whether it is already there. If found,
    /// it will be used and applied with the given processor. It is an optimization for not downloading
    /// the same image for multiple times.
    ///
    public func originalCache(_ cache: ImageCache) -> Self {
        options.originalCache = cache
        return self
    }

    /// Sets the downloader used to perform the image download task.
    /// - Parameter downloader: The downloader which is about to be used for downloading.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// Kingfisher will use the set `ImageDownloader` object to download the requested images.
    public func downloader(_ downloader: ImageDownloader) -> Self {
        options.downloader = downloader
        return self
    }

    /// Sets the download priority for the image task.
    /// - Parameter priority: The download priority of image download task.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// The `priority` value will be set as the priority of the image download task. The value for it should be
    /// between 0.0~1.0. You can choose a value between `URLSessionTask.defaultPriority`, `URLSessionTask.lowPriority`
    /// or `URLSessionTask.highPriority`. If this option not set, the default value (`URLSessionTask.defaultPriority`)
    /// will be used.
    public func downloadPriority(_ priority: Float) -> Self {
        options.downloadPriority = priority
        return self
    }

    /// Sets whether Kingfisher should ignore the cache and try to start a download task for the image source.
    /// - Parameter enabled: Enable the force refresh or not.
    /// - Returns: A `Self` value with changes applied.
    public func forceRefresh(_ enabled: Bool = true) -> Self {
        options.forceRefresh = enabled
        return self
    }

    /// Sets whether Kingfisher should try to retrieve the image from memory cache first. If not found, it ignores the
    /// disk cache and starts a download task for the image source.
    /// - Parameter enabled: Enable the memory-only cache searching or not.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// This is useful when you want to display a changeable image behind the same url at the same app session, while
    /// avoiding download it for multiple times.
    public func fromMemoryCacheOrRefresh(_ enabled: Bool = true) -> Self {
        options.fromMemoryCacheOrRefresh = enabled
        return self
    }

    /// Sets whether the image should only be cached in memory but not in disk.
    /// - Parameter enabled: Whether the image should be only cache in memory or not.
    /// - Returns: A `Self` value with changes applied.
    public func cacheMemoryOnly(_ enabled: Bool = true) -> Self {
        options.cacheMemoryOnly = enabled
        return self
    }

    /// Sets whether Kingfisher should wait for caching operation to be completed before calling the
    /// `onSuccess` or `onFailure` block.
    /// - Parameter enabled: Whether Kingfisher should wait for caching operation.
    /// - Returns: A `Self` value with changes applied.
    public func waitForCache(_ enabled: Bool = true) -> Self {
        options.waitForCache = enabled
        return self
    }

    /// Sets whether Kingfisher should only try to retrieve the image from cache, but not from network.
    /// - Parameter enabled: Whether Kingfisher should only try to retrieve the image from cache.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// If the image is not in cache, the image retrieving will fail with the
    /// `KingfisherError.cacheError` with `.imageNotExisting` as its reason.
    public func onlyFromCache(_ enabled: Bool = true) -> Self {
        options.onlyFromCache = enabled
        return self
    }

    /// Sets whether the image should be decoded in a background thread before using.
    /// - Parameter enabled: Whether the image should be decoded in a background thread before using.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// Setting to `true` will decode the downloaded image data and do a off-screen rendering to extract pixel
    /// information in background. This can speed up display, but will cost more time and memory to prepare the image
    /// for using.
    public func backgroundDecode(_ enabled: Bool = true) -> Self {
        options.backgroundDecode = enabled
        return self
    }

    /// Sets the callback queue which is used as the target queue of dispatch callbacks when retrieving images from
    ///  cache. If not set, Kingfisher will use main queue for callbacks.
    /// - Parameter queue: The target queue which the cache retrieving callback will be invoked on.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// - Note:
    /// This option does not affect the callbacks for UI related extension methods or `KFImage` result handlers.
    /// You will always get the callbacks called from main queue.
    public func callbackQueue(_ queue: CallbackQueue) -> Self {
        options.callbackQueue = queue
        return self
    }

    /// Sets the scale factor value when converting retrieved data to an image.
    /// - Parameter factor: The scale factor value.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// Specify the image scale, instead of your screen scale. You may need to set the correct scale when you dealing
    /// with 2x or 3x retina images. Otherwise, Kingfisher will convert the data to image object at `scale` 1.0.
    ///
    public func scaleFactor(_ factor: CGFloat) -> Self {
        options.scaleFactor = factor
        return self
    }

    /// Sets whether the original image should be cached even when the original image has been processed by any other
    /// `ImageProcessor`s.
    /// - Parameter enabled: Whether the original image should be cached.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// If set and an `ImageProcessor` is used, Kingfisher will try to cache both the final result and original
    /// image. Kingfisher will have a chance to use the original image when another processor is applied to the same
    /// resource, instead of downloading it again. You can use `.originalCache` to specify a cache or the original
    /// images if necessary.
    ///
    /// The original image will be only cached to disk storage.
    ///
    public func cacheOriginalImage(_ enabled: Bool = true) -> Self {
        options.cacheOriginalImage = enabled
        return self
    }

    /// Sets whether the disk storage loading should happen in the same calling queue.
    /// - Parameter enabled: Whether the disk storage loading should happen in the same calling queue.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// By default, disk storage file loading
    /// happens in its own queue with an asynchronous dispatch behavior. Although it provides better non-blocking disk
    /// loading performance, it also causes a flickering when you reload an image from disk, if the image view already
    /// has an image set.
    ///
    /// Set this options will stop that flickering by keeping all loading in the same queue (typically the UI queue
    /// if you are using Kingfisher's extension methods to set an image), with a tradeoff of loading performance.
    ///
    public func loadDiskFileSynchronously(_ enabled: Bool = true) -> Self {
        options.loadDiskFileSynchronously = enabled
        return self
    }

    /// Sets a queue on which the image processing should happen.
    /// - Parameter queue: The queue on which the image processing should happen.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// By default, Kingfisher uses a pre-defined serial
    /// queue to process images. Use this option to change this behavior. For example, specify a `.mainCurrentOrAsync`
    /// to let the image be processed in main queue to prevent a possible flickering (but with a possibility of
    /// blocking the UI, especially if the processor needs a lot of time to run).
    public func processingQueue(_ queue: CallbackQueue?) -> Self {
        options.processingQueue = queue
        return self
    }

    /// Sets the alternative sources that will be used when loading of the original input `Source` fails.
    /// - Parameter sources: The alternative sources will be used.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// Values of the `sources` array will be used to start a new image loading task if the previous task
    /// fails due to an error. The image source loading process will stop as soon as a source is loaded successfully.
    /// If all `sources` are used but the loading is still failing, an `imageSettingError` with
    /// `alternativeSourcesExhausted` as its reason will be given out in the `catch` block.
    ///
    /// This is useful if you want to implement a fallback solution for setting image.
    ///
    /// User cancellation will not trigger the alternative source loading.
    public func alternativeSources(_ sources: [Source]?) -> Self {
        options.alternativeSources = sources
        return self
    }

    /// Sets a retry strategy that will be used when something gets wrong during the image retrieving.
    /// - Parameter strategy: The provided strategy to define how the retrying should happen.
    /// - Returns: A `Self` value with changes applied.
    public func retry(_ strategy: RetryStrategy?) -> Self {
        options.retryStrategy = strategy
        return self
    }

    /// Sets a retry strategy with a max retry count and retrying interval.
    /// - Parameters:
    ///   - maxCount: The maximum count before the retry stops.
    ///   - interval: The time interval between each retry attempt.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// This defines the simplest retry strategy, which retry a failing request for several times, with some certain
    /// interval between each time. For example, `.retry(maxCount: 3, interval: .second(3))` means attempt for at most
    /// three times, and wait for 3 seconds if a previous retry attempt fails, then start a new attempt.
    public func retry(maxCount: Int, interval: DelayRetryStrategy.Interval = .seconds(3)) -> Self {
        let strategy = DelayRetryStrategy(maxRetryCount: maxCount, retryInterval: interval)
        options.retryStrategy = strategy
        return self
    }

    /// Sets the `Source` should be loaded when user enables Low Data Mode and the original source fails with an
    /// `NSURLErrorNetworkUnavailableReason.constrained` error.
    /// - Parameter source: The `Source` will be loaded under low data mode.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// When this option is set, the
    /// `allowsConstrainedNetworkAccess` property of the request for the original source will be set to `false` and the
    /// `Source` in associated value will be used to retrieve the image for low data mode. Usually, you can provide a
    /// low-resolution version of your image or a local image provider to display a placeholder.
    ///
    /// If not set or the `source` is `nil`, the device Low Data Mode will be ignored and the original source will
    /// be loaded following the system default behavior, in a normal way.
    public func lowDataModeSource(_ source: Source?) -> Self {
        options.lowDataModeSource = source
        return self
    }

    /// Sets whether the image setting for an image view should happen with transition even when retrieved from cache.
    /// - Parameter enabled: Enable the force transition or not.
    /// - Returns: A `KF.Builder` with changes applied.
    public func forceTransition(_ enabled: Bool = true) -> Self {
        options.forceTransition = enabled
        return self
    }

}

// MARK: - Request Modifier
extension KFOptionSetter {
    /// Sets an `ImageDownloadRequestModifier` to change the image download request before it being sent.
    /// - Parameter modifier: The modifier will be used to change the request before it being sent.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    ///
    public func requestModifier(_ modifier: ImageDownloadRequestModifier) -> Self {
        options.requestModifier = modifier
        return self
    }

    /// Sets a block to change the image download request before it being sent.
    /// - Parameter modifyBlock: The modifying block will be called to change the request before it being sent.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    ///
    public func requestModifier(_ modifyBlock: @escaping (inout URLRequest) -> Void) -> Self {
        options.requestModifier = AnyModifier { r -> URLRequest? in
            var request = r
            modifyBlock(&request)
            return request
        }
        return self
    }
}

// MARK: - Redirect Handler
extension KFOptionSetter {
    /// The `ImageDownloadRedirectHandler` argument will be used to change the request before redirection.
    /// This is the possibility you can modify the image download request during redirect. You can modify the request for
    /// some customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url
    /// mapping.
    /// The original redirection request will be sent without any modification by default.
    /// - Parameter handler: The handler will be used for redirection.
    /// - Returns: A `Self` value with changes applied.
    public func redirectHandler(_ handler: ImageDownloadRedirectHandler) -> Self {
        options.redirectHandler = handler
        return self
    }

    /// The `block` will be used to change the request before redirection.
    /// This is the possibility you can modify the image download request during redirect. You can modify the request for
    /// some customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url
    /// mapping.
    /// The original redirection request will be sent without any modification by default.
    /// - Parameter block: The block will be used for redirection.
    /// - Returns: A `Self` value with changes applied.
    public func redirectHandler(_ block: @escaping (KF.RedirectPayload) -> Void) -> Self {
        let redirectHandler = AnyRedirectHandler { (task, response, request, handler) in
            let payload = KF.RedirectPayload(
                task: task, response: response, newRequest: request, completionHandler: handler
            )
            block(payload)
        }
        options.redirectHandler = redirectHandler
        return self
    }
}

// MARK: - Processor
extension KFOptionSetter {

    /// Sets an image processor for the image task. It replaces the current image processor settings.
    ///
    /// - Parameter processor: The processor you want to use to process the image after it is downloaded.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// - Note:
    /// To append a processor to current ones instead of replacing them all, use `appendProcessor(_:)`.
    public func setProcessor(_ processor: ImageProcessor) -> Self {
        options.processor = processor
        return self
    }

    /// Sets an array of image processors for the image task. It replaces the current image processor settings.
    /// - Parameter processors: An array of processors. The processors inside this array will be concatenated one by one
    ///                         to form a processor pipeline.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// - Note:
    /// To append processors to current ones instead of replacing them all, concatenate them by `|>`, then use
    /// `appendProcessor(_:)`.
    public func setProcessors(_ processors: [ImageProcessor]) -> Self {
        switch processors.count {
        case 0:
            options.processor = DefaultImageProcessor.default
        case 1...:
            options.processor = processors.dropFirst().reduce(processors[0]) { $0 |> $1 }
        default:
            assertionFailure("Never happen")
        }
        return self
    }

    /// Appends a processor to the current set processors.
    /// - Parameter processor: The processor which will be appended to current processor settings.
    /// - Returns: A `Self` value with changes applied.
    public func appendProcessor(_ processor: ImageProcessor) -> Self {
        options.processor = options.processor |> processor
        return self
    }

    /// Appends a `RoundCornerImageProcessor` to current processors.
    /// - Parameters:
    ///   - radius: The radius will be applied in processing. Specify a certain point value with `.point`, or a fraction
    ///             of the target image with `.widthFraction`. or `.heightFraction`. For example, given a square image
    ///             with width and height equals,  `.widthFraction(0.5)` means use half of the length of size and makes
    ///             the final image a round one.
    ///   - targetSize: Target size of output image should be. If `nil`, the image will keep its original size after processing.
    ///   - corners: The target corners which will be applied rounding.
    ///   - backgroundColor: Background color of the output image. If `nil`, it will use a transparent background.
    /// - Returns: A `Self` value with changes applied.
    public func roundCorner(
        radius: RoundCornerImageProcessor.Radius,
        targetSize: CGSize? = nil,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> Self
    {
        let processor = RoundCornerImageProcessor(
            radius: radius,
            targetSize: targetSize,
            roundingCorners: corners,
            backgroundColor: backgroundColor
        )
        return appendProcessor(processor)
    }

    /// Appends a `BlurImageProcessor` to current processors.
    /// - Parameter radius: Blur radius for the simulated Gaussian blur.
    /// - Returns: A `Self` value with changes applied.
    public func blur(radius: CGFloat) -> Self {
        appendProcessor(
            BlurImageProcessor(blurRadius: radius)
        )
    }

    /// Appends a `OverlayImageProcessor` to current processors.
    /// - Parameters:
    ///   - color: Overlay color will be used to overlay the input image.
    ///   - fraction: Fraction will be used when overlay the color to image.
    /// - Returns: A `Self` value with changes applied.
    public func overlay(color: KFCrossPlatformColor, fraction: CGFloat = 0.5) -> Self {
        appendProcessor(
            OverlayImageProcessor(overlay: color, fraction: fraction)
        )
    }

    /// Appends a `TintImageProcessor` to current processors.
    /// - Parameter color: Tint color will be used to tint the input image.
    /// - Returns: A `Self` value with changes applied.
    public func tint(color: KFCrossPlatformColor) -> Self {
        appendProcessor(
            TintImageProcessor(tint: color)
        )
    }

    /// Appends a `BlackWhiteProcessor` to current processors.
    /// - Returns: A `Self` value with changes applied.
    public func blackWhite() -> Self {
        appendProcessor(
            BlackWhiteProcessor()
        )
    }

    /// Appends a `CroppingImageProcessor` to current processors.
    /// - Parameters:
    ///   - size: Target size of output image should be.
    ///   - anchor: Anchor point from which the output size should be calculate. The anchor point is consisted by two
    ///             values between 0.0 and 1.0. It indicates a related point in current image.
    ///             See `CroppingImageProcessor.init(size:anchor:)` for more.
    /// - Returns: A `Self` value with changes applied.
    public func cropping(size: CGSize, anchor: CGPoint = .init(x: 0.5, y: 0.5)) -> Self {
        appendProcessor(
            CroppingImageProcessor(size: size, anchor: anchor)
        )
    }

    /// Appends a `DownsamplingImageProcessor` to current processors.
    ///
    /// Compared to `ResizingImageProcessor`, the `DownsamplingImageProcessor` does not render the original images and
    /// then resize it. Instead, it downsamples the input data directly to a thumbnail image. So it is a more efficient
    /// than `ResizingImageProcessor`. Prefer to use `DownsamplingImageProcessor` as possible
    /// as you can than the `ResizingImageProcessor`.
    ///
    /// Only CG-based images are supported. Animated images (like GIF) is not supported.
    ///
    /// - Parameter size: Target size of output image should be. It should be smaller than the size of input image.
    ///                   If it is larger, the result image will be the same size of input data without downsampling.
    /// - Returns: A `Self` value with changes applied.
    public func downsampling(size: CGSize) -> Self {
        let processor = DownsamplingImageProcessor(size: size)
        if options.processor == DefaultImageProcessor.default {
            return setProcessor(processor)
        } else {
            return appendProcessor(processor)
        }
    }


    /// Appends a `ResizingImageProcessor` to current processors.
    ///
    /// If you need to resize a data represented image to a smaller size, use `DownsamplingImageProcessor`
    /// instead, which is more efficient and uses less memory.
    ///
    /// - Parameters:
    ///   - referenceSize: The reference size for resizing operation in point.
    ///   - mode: Target content mode of output image should be. Default is `.none`.
    /// - Returns: A `Self` value with changes applied.
    public func resizing(referenceSize: CGSize, mode: ContentMode = .none) -> Self {
        appendProcessor(
            ResizingImageProcessor(referenceSize: referenceSize, mode: mode)
        )
    }
}

// MARK: - Cache Serializer
extension KFOptionSetter {

    /// Uses a given `CacheSerializer` to convert some data to an image object for retrieving from disk cache or vice
    /// versa for storing to disk cache.
    /// - Parameter cacheSerializer: The `CacheSerializer` which will be used.
    /// - Returns: A `Self` value with changes applied.
    public func serialize(by cacheSerializer: CacheSerializer) -> Self {
        options.cacheSerializer = cacheSerializer
        return self
    }

    /// Uses a given format to serializer the image data to disk. It converts the image object to the give data format.
    /// - Parameters:
    ///   - format: The desired data encoding format when store the image on disk.
    ///   - jpegCompressionQuality: If the format is `.JPEG`, it specify the compression quality when converting the
    ///                             image to a JPEG data. Otherwise, it is ignored.
    /// - Returns: A `Self` value with changes applied.
    public func serialize(as format: ImageFormat, jpegCompressionQuality: CGFloat? = nil) -> Self {
        let cacheSerializer: FormatIndicatedCacheSerializer
        switch format {
        case .JPEG:
            cacheSerializer = .jpeg(compressionQuality: jpegCompressionQuality ?? 1.0)
        case .PNG:
            cacheSerializer = .png
        case .GIF:
            cacheSerializer = .gif
        case .unknown:
            cacheSerializer = .png
        }
        options.cacheSerializer = cacheSerializer
        return self
    }
}

// MARK: - Image Modifier
extension KFOptionSetter {

    /// Sets an `ImageModifier` to the image task. Use this to modify the fetched image object properties if needed.
    ///
    /// If the image was fetched directly from the downloader, the modifier will run directly after the
    /// `ImageProcessor`. If the image is being fetched from a cache, the modifier will run after the `CacheSerializer`.
    /// - Parameter modifier: The `ImageModifier` which will be used to modify the image object.
    /// - Returns: A `Self` value with changes applied.
    public func imageModifier(_ modifier: ImageModifier?) -> Self {
        options.imageModifier = modifier
        return self
    }

    /// Sets a block to modify the image object. Use this to modify the fetched image object properties if needed.
    ///
    /// If the image was fetched directly from the downloader, the modifier block will run directly after the
    /// `ImageProcessor`. If the image is being fetched from a cache, the modifier will run after the `CacheSerializer`.
    ///
    /// - Parameter block: The block which is used to modify the image object.
    /// - Returns: A `Self` value with changes applied.
    public func imageModifier(_ block: @escaping (inout KFCrossPlatformImage) throws -> Void) -> Self {
        let modifier = AnyImageModifier { image -> KFCrossPlatformImage in
            var image = image
            try block(&image)
            return image
        }
        options.imageModifier = modifier
        return self
    }
}


// MARK: - Cache Expiration
extension KFOptionSetter {

    /// Sets the expiration setting for memory cache of this image task.
    ///
    /// By default, the underlying `MemoryStorage.Backend` uses the
    /// expiration in its config for all items. If set, the `MemoryStorage.Backend` will use this value to overwrite
    /// the config setting for this caching item.
    ///
    /// - Parameter expiration: The expiration setting used in cache storage.
    /// - Returns: A `Self` value with changes applied.
    public func memoryCacheExpiration(_ expiration: StorageExpiration?) -> Self {
        options.memoryCacheExpiration = expiration
        return self
    }

    /// Sets the expiration extending setting for memory cache. The item expiration time will be incremented by this
    /// value after access.
    ///
    /// By default, the underlying `MemoryStorage.Backend` uses the initial cache expiration as extending
    /// value: .cacheTime.
    ///
    /// To disable extending option at all, sets `.none` to it.
    ///
    /// - Parameter extending: The expiration extending setting used in cache storage.
    /// - Returns: A `Self` value with changes applied.
    public func memoryCacheAccessExtending(_ extending: ExpirationExtending) -> Self {
        options.memoryCacheAccessExtendingExpiration = extending
        return self
    }

    /// Sets the expiration setting for disk cache of this image task.
    ///
    /// By default, the underlying `DiskStorage.Backend` uses the expiration in its config for all items. If set,
    /// the `DiskStorage.Backend` will use this value to overwrite the config setting for this caching item.
    ///
    /// - Parameter expiration: The expiration setting used in cache storage.
    /// - Returns: A `Self` value with changes applied.
    public func diskCacheExpiration(_ expiration: StorageExpiration?) -> Self {
        options.diskCacheExpiration = expiration
        return self
    }

    /// Sets the expiration extending setting for disk cache. The item expiration time will be incremented by this
    /// value after access.
    ///
    /// By default, the underlying `DiskStorage.Backend` uses the initial cache expiration as extending
    /// value: .cacheTime.
    ///
    /// To disable extending option at all, sets `.none` to it.
    ///
    /// - Parameter extending: The expiration extending setting used in cache storage.
    /// - Returns: A `Self` value with changes applied.
    public func diskCacheAccessExtending(_ extending: ExpirationExtending) -> Self {
        options.diskCacheAccessExtendingExpiration = extending
        return self
    }
}
