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
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A protocol that Kingfisher can use to perform chained setting in builder pattern.
@MainActor
public protocol KFOptionSetter {
    var options: KingfisherParsedOptionsInfo { get nonmutating set }

    var onFailureDelegate: Delegate<KingfisherError, Void> { get }
    var onSuccessDelegate: Delegate<RetrieveImageResult, Void> { get }
    var onProgressDelegate: Delegate<(Int64, Int64), Void> { get }
}

extension KF.Builder: KFOptionSetter { }

final actor KFDelegateObserver {
    static let `default` = KFDelegateObserver()
}

// MARK: - Life cycles
extension KFOptionSetter {
    /// Sets the progress block to current builder.
    ///
    /// - Parameter block:
    /// Called when the image downloading progress gets updated. If the response does not contain an
    /// [`expectedContentLength`](https://developer.apple.com/documentation/foundation/urlresponse/1413507-expectedcontentlength)
    /// in the received `URLResponse`, this block will not be called. If `block` is `nil`, the callback will be reset.
    ///
    /// - Returns: A `Self` value with changes applied.
    ///
    public func onProgress(_ block: DownloadProgressBlock?) -> Self {
        onProgressDelegate.delegate(on: KFDelegateObserver.default) { (_, result) in
            block?(result.0, result.1)
        }
        return self
    }

    /// Sets the done block to current builder.
    /// - Parameter block: Called when the image task successfully completes and the image set is done. If `block`
    ///                    is `nil`, the callback will be reset.
    /// - Returns: A `Self` with changes applied.
    ///
    public func onSuccess(_ block: ((RetrieveImageResult) -> Void)?) -> Self {
        onSuccessDelegate.delegate(on: KFDelegateObserver.default) { (_, result) in
            block?(result)
        }
        return self
    }

    /// Sets the catch block to current builder.
    /// - Parameter block: Called when an error happens during the image task. If `block`
    ///                    is `nil`, the callback will be reset.
    /// - Returns: A `Self` with changes applied.
    ///
    public func onFailure(_ block: ((KingfisherError) -> Void)?) -> Self {
        onFailureDelegate.delegate(on: KFDelegateObserver.default) { (_, error) in
            block?(error)
        }
        return self
    }
}

// MARK: - Basic options settings.
extension KFOptionSetter {

    /// Sets the target image cache for this task.
    ///
    /// - Parameter cache: The target cache to be used for the task.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// Kingfisher will utilize the associated ``ImageCache`` object when performing related operations,
    /// such as attempting to retrieve cached images and storing downloaded images within it.
    ///
    public func targetCache(_ cache: ImageCache) -> Self {
        options.targetCache = cache
        return self
    }
    
    /// Sets the target image cache to store the original downloaded image for this task.
    ///
    /// - Parameter cache: The target cache is about to be used for storing the original downloaded image from the task.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// The ``ImageCache`` for storing and retrieving original images. If ``KingfisherOptionsInfoItem/originalCache(_:)``
    /// is contained in the options, it will be preferred for storing and retrieving original images.
    /// If there is no ``KingfisherOptionsInfoItem/originalCache(_:)`` in the options,
    /// ``KingfisherOptionsInfoItem/targetCache(_:)`` will be used to store original images.
    ///
    /// When using ``KingfisherManager`` to download and store an image, if
    /// ``KingfisherOptionsInfoItem/cacheOriginalImage`` is applied in the option, the original image will be stored to
    /// the `cache` you pass as parameter in this method. At the same time, if a requested final image (with processor
    /// applied) cannot be found in the cache defined by ``KingfisherOptionsInfoItem/targetCache(_:)``, Kingfisher
    /// will try to search the original image to check whether it is already there. If found, it will be used and
    /// applied with the given processor. It is an optimization for not downloading the same image for multiple times.
    ///
    public func originalCache(_ cache: ImageCache) -> Self {
        options.originalCache = cache
        return self
    }

    /// Sets the downloader to be used for the image download task.
    ///
    /// - Parameter downloader: The `ImageDownloader` instance to use for downloading.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// Kingfisher will utilize the specified ``ImageDownloader`` instance to download requested images.
    ///
    public func downloader(_ downloader: ImageDownloader) -> Self {
        options.downloader = downloader
        return self
    }

    /// Sets the download priority for the image task.
    ///
    /// - Parameter priority: The download priority of the image download task.
    /// - Returns: A `Self` value with changes applied.
    ///
    /// The `priority` value will be configured as the priority of the image download task. Valid values range between 
    /// 0.0 and 1.0. You can select a value from `URLSessionTask.defaultPriority`, `URLSessionTask.lowPriority`,
    /// or `URLSessionTask.highPriority`. If this option is not set, the default value
    /// (`URLSessionTask.defaultPriority`) will be used.
    ///
    public func downloadPriority(_ priority: Float) -> Self {
        options.downloadPriority = priority
        return self
    }

    /// Sets whether Kingfisher should ignore the cache and attempt to initiate a download task for the image source.
    ///
    /// - Parameter enabled: Enable force refresh or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func forceRefresh(_ enabled: Bool = true) -> Self {
        options.forceRefresh = enabled
        return self
    }

    /// Sets whether Kingfisher should attempt to retrieve the image from the memory cache first. If the image is not 
    /// found in the memory cache, it bypasses the disk cache and initiates a download task for the image source.
    ///
    /// - Parameter enabled: Enable memory-only cache searching or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// This option is useful when you want to display a changeable image with the same URL during the same app session 
    /// while avoiding multiple downloads of the same image.
    ///
    public func fromMemoryCacheOrRefresh(_ enabled: Bool = true) -> Self {
        options.fromMemoryCacheOrRefresh = enabled
        return self
    }

    /// Sets whether the image should be cached only in memory and not on disk.
    ///
    /// - Parameter enabled: Enable memory-only caching for the image or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func cacheMemoryOnly(_ enabled: Bool = true) -> Self {
        options.cacheMemoryOnly = enabled
        return self
    }

    /// Sets whether Kingfisher should wait for caching operations to be completed before invoking the `onSuccess` 
    /// or `onFailure` block.
    ///
    /// - Parameter enabled: Enable waiting for caching operations or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func waitForCache(_ enabled: Bool = true) -> Self {
        options.waitForCache = enabled
        return self
    }

    /// Sets whether Kingfisher should exclusively attempt to retrieve the image from the cache and not from the network.
    ///
    /// - Parameter enabled: Enable cache-only image retrieval or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// If the image is not found in the cache, the image retrieval will fail with a
    /// ``KingfisherError/CacheErrorReason/imageNotExisting(key:)`` error.
    ///
    public func onlyFromCache(_ enabled: Bool = true) -> Self {
        options.onlyFromCache = enabled
        return self
    }

    /// Sets whether the image should be decoded on a background thread before usage.
    ///
    /// - Parameter enabled: Enable background image decoding or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// When set to `true`, the downloaded image data will be decoded and undergo off-screen rendering to extract pixel 
    /// information in the background. This can enhance display speed but may consume additional time and memory for
    /// image preparation before usage.
    ///
    public func backgroundDecode(_ enabled: Bool = true) -> Self {
        options.backgroundDecode = enabled
        return self
    }

    /// Sets the callback queue used as the target queue for dispatching callbacks when retrieving images from the 
    /// cache. If not set, Kingfisher will use the main queue for callbacks.
    ///
    /// - Parameter queue: The target queue on which cache retrieval callbacks will be invoked.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// - Note: This option does not impact callbacks for UI-related extension methods or ``KFImage`` result handlers. 
    /// Callbacks for those methods will always be executed on the main queue.
    ///
    public func callbackQueue(_ queue: CallbackQueue) -> Self {
        options.callbackQueue = queue
        return self
    }

    /// Sets the scale factor value used when converting retrieved data to an image.
    ///
    /// - Parameter factor: The scale factor value to use.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// Specify the image scale factor, which may differ from your screen's scale. This is particularly important when 
    /// working with 2x or 3x retina images. Failure to set the correct scale factor may result in Kingfisher
    /// converting the data to an image object with a `scale` of 1.0.
    ///
    public func scaleFactor(_ factor: CGFloat) -> Self {
        options.scaleFactor = factor
        return self
    }

    /// Sets whether the original image should be cached, even when the original image has been processed by other ``ImageProcessor``s.
    ///
    /// - Parameter enabled: Whether to cache the original image.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// When this option is set, and an ``ImageProcessor`` is used, Kingfisher will attempt to cache both the final 
    /// processed image and the original image. This ensures that the original image can be reused when another
    /// processor is applied to the same resource, without the need for redownloading. You can use
    ///  ``KingfisherOptionsInfoItem/originalCache(_:)`` to specify a cache for the original images.
    ///
    /// - Note: The original image will be cached only in disk storage.
    ///
    public func cacheOriginalImage(_ enabled: Bool = true) -> Self {
        options.cacheOriginalImage = enabled
        return self
    }

    /// Sets writing options for an original image on its initial write to disk storage.
    ///
    /// - Parameter writingOptions: Options that control the data writing operation to disk storage.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// If these options are set, they will be applied to the storage operation for new files. This can be useful if 
    /// you want to implement features such as file encryption on the initial write, for example,
    /// using `[.completeFileProtection]`.
    ///
    public func diskStoreWriteOptions(_ writingOptions: Data.WritingOptions) -> Self {
        options.diskStoreWriteOptions = writingOptions
        return self
    }

    /// Sets whether disk storage loading should occur in the same calling queue.
    ///
    /// - Parameter enabled: Whether disk storage loading should happen in the same calling queue.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// By default, disk storage file loading operates in its own queue with asynchronous dispatch behavior. While this 
    /// provides better non-blocking disk loading performance, it can result in flickering when reloading an image
    /// from disk if the image view already has an image set.
    ///
    /// Enabling this option prevents flickering by performing all loading in the same queue (typically the UI queue if 
    /// you are using Kingfisher's extension methods to set an image). However, this may come at the cost of loading
    /// performance.
    ///
    /// - Note: When using SwiftUI components (e.g., `KFImage`), this option is enabled by default to prevent 
    /// flickering during view updates. This is essential for maintaining visual consistency in SwiftUI's declarative
    /// environment. For UIKit/AppKit usage, the default remains `false` for optimal performance.
    ///
    public func loadDiskFileSynchronously(_ enabled: Bool = true) -> Self {
        options.loadDiskFileSynchronously = enabled
        return self
    }

    /// Sets the queue on which image processing should occur.
    ///
    /// - Parameter queue: The queue on which image processing should take place.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// By default, Kingfisher employs a pre-defined serial queue for image processing. Use this option to modify this
    ///  behavior. For example, specify `.mainCurrentOrAsync` to process the image on the main queue, which can prevent
    ///  potential flickering but may lead to UI blocking if the processor requires substantial time to execute.
    ///
    public func processingQueue(_ queue: CallbackQueue?) -> Self {
        options.processingQueue = queue
        return self
    }

    /// Sets the alternative sources to be used when loading the original input `Source` fails.
    ///
    /// - Parameter sources: The alternative sources to be used.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// The values in the `sources` array will be employed to initiate a new image loading task if the previous task 
    /// fails due to an error. The image source loading process will terminate as soon as one of the alternative
    /// sources is successfully loaded. If all `sources` are used but loading still fails,
    /// a ``KingfisherError/ImageSettingErrorReason/alternativeSourcesExhausted(_:)`` error will be thrown in the
    ///  `catch` block.
    ///
    /// This feature is valuable when implementing a fallback solution for setting images. 
    ///
    /// - Note: User cancellation or calling on ``DownloadTask/cancel()`` on ``DownloadTask`` will not trigger the
    /// loading of alternative sources.
    ///
    public func alternativeSources(_ sources: [Source]?) -> Self {
        options.alternativeSources = sources
        return self
    }

    /// Sets a retry strategy to be used when issues arise during image retrieval.
    ///
    /// - Parameter strategy: The provided strategy that defines how retry attempts should occur.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func retry(_ strategy: (any RetryStrategy)?) -> Self {
        options.retryStrategy = strategy
        return self
    }

    /// Sets a retry strategy with a maximum retry count and retry interval.
    ///
    /// - Parameters:
    ///   - maxCount: The maximum number of retry attempts before the retry stops.
    ///   - interval: The time interval between each retry attempt.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// This defines a straightforward retry strategy that retries a failing request for a specified number of times 
    /// with a designated time interval between each attempt. For example, `.retry(maxCount: 3, interval: .second(3))`
    /// indicates a maximum of three retry attempts, with a 3-second pause between each retry if the previous attempt
    /// fails.
    ///
    public func retry(maxCount: Int, interval: DelayRetryStrategy.Interval = .seconds(3)) -> Self {
        let strategy = DelayRetryStrategy(maxRetryCount: maxCount, retryInterval: interval)
        options.retryStrategy = strategy
        return self
    }

    /// Sets the `Source` to be loaded when the user enables Low Data Mode and the original source fails with an
    ///  `NSURLErrorNetworkUnavailableReason.constrained` error.
    ///
    /// - Parameter source: The `Source` to be loaded under low data mode.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// When this option is set, the `allowsConstrainedNetworkAccess` property of the request for the original source 
    /// will be set to `false`, and the specified ``Source`` will be used to retrieve the image in low data mode.
    /// Typically, you can provide a low-resolution version of your image or a local image provider to display a
    /// placeholder.
    ///
    /// If this option is not set or the `source` is `nil`, the device's Low Data Mode setting will be disregarded, 
    /// and the original source will be loaded following the system's default behavior in a regular manner.
    ///
    public func lowDataModeSource(_ source: Source?) -> Self {
        options.lowDataModeSource = source
        return self
    }

    /// Sets whether the image setting for an image view should include a transition even when the image is retrieved 
    /// from the cache.
    ///
    /// - Parameter enabled: Enable the use of a transition or not.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func forceTransition(_ enabled: Bool = true) -> Self {
        options.forceTransition = enabled
        return self
    }

    /// Sets the image to be used in the event of a failure during image retrieval.
    ///
    /// - Parameter image: The image to be used when an error occurs.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// If this option is set and an image retrieval error occurs, Kingfisher will use the provided image (or an empty 
    /// image) in place of the requested one. This is useful when you do not want to display a placeholder during the
    ///  loading process but prefer to use a default image when requests fail.
    ///
    public func onFailureImage(_ image: KFCrossPlatformImage?) -> Self {
        options.onFailureImage = .some(image)
        return self
    }
}

// MARK: - Request Modifier
extension KFOptionSetter {
    
    /// Sets an ``ImageDownloadRequestModifier`` to alter the image download request before it is sent.
    ///
    /// - Parameter modifier: The modifier to be used for changing the request before it is sent.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// This is your last opportunity to modify the image download request. You can use this for customization
    /// purposes, such as adding an authentication token to the header, implementing basic HTTP authentication,
    /// or URL mapping.
    public func requestModifier(_ modifier: any AsyncImageDownloadRequestModifier) -> Self {
        options.requestModifier = modifier
        return self
    }

    /// Sets a block to modify the image download request before it is sent.
    ///
    /// - Parameter modifyBlock: The modifying block that will be called to change the request before it is sent.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// This is your last opportunity to modify the image download request. You can use this for customization purposes,
    /// such as adding an authentication token to the header, implementing basic HTTP authentication, or URL mapping.
    ///
    public func requestModifier(_ modifyBlock: @escaping @Sendable (inout URLRequest) -> Void) -> Self {
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
    
    /// Sets an `ImageDownloadRedirectHandler` to modify the image download request during redirection.
    ///
    /// - Parameter handler: The handler to be used for redirection.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// This provides an opportunity to modify the image download request during redirection. You can use this for 
    /// customization purposes, such as adding an authentication token to the header, implementing basic HTTP
    /// authentication, or URL mapping. By default, the original redirection request will be sent without any
    /// modification.
    ///
    public func redirectHandler(_ handler: any ImageDownloadRedirectHandler) -> Self {
        options.redirectHandler = handler
        return self
    }

    /// Sets a block to modify the image download request during redirection.
    ///
    /// - Parameter block: The block to be used for redirection.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// This provides an opportunity to modify the image download request during redirection. You can use this for 
    /// customization purposes, such as adding an authentication token to the header, implementing basic HTTP
    /// authentication, or URL mapping. By default, the original redirection request will be sent without any
    /// modification.
    ///
    public func redirectHandler(_ block: @escaping @Sendable (KF.RedirectPayload) -> Void) -> Self {
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

    /// Sets an image processor for the image task, replacing the current image processor settings.
    ///
    /// - Parameter processor: The processor to use for processing the image after it is downloaded.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// - Note: To append a processor to the current ones instead of replacing them all, use ``appendProcessor(_:)``.
    ///
    public func setProcessor(_ processor: any ImageProcessor) -> Self {
        options.processor = processor
        return self
    }
    
    /// Enables progressive image loading with a specified `ImageProgressive` setting to process the
    /// progressive JPEG data and display it in a progressive way.
    /// - Parameter progressive: The progressive settings which is used while loading.
    /// - Returns: A ``KF/Builder`` with changes applied.
    public func progressiveJPEG(_ progressive: ImageProgressive? = .init()) -> Self {
        options.progressiveJPEG = progressive
        return self
    }

    /// Sets an array of image processors for the image task, replacing the current image processor settings.
    ///
    /// - Parameter processors: An array of processors. The processors in this array will be concatenated one by one to 
    /// form a processor pipeline.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// - Note: To append processors to the current ones instead of replacing them all, concatenate them using the
    /// `|>` operator, and then use ``KFOptionSetter/appendProcessor(_:)``.
    ///
    public func setProcessors(_ processors: [any ImageProcessor]) -> Self {
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

    /// Appends a processor to the current set of processors.
    ///
    /// - Parameter processor: The processor to append to the current processor settings.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func appendProcessor(_ processor: any ImageProcessor) -> Self {
        options.processor = options.processor |> processor
        return self
    }

    /// Appends a ``RoundCornerImageProcessor`` to the current set of processors.
    ///
    /// - Parameters:
    ///   - radius: The radius to apply during processing. Specify a certain point value with `.point`, or a fraction 
    ///   of the target image with `.widthFraction` or `.heightFraction`. For example, with a square image where width
    ///   and height are equal, `.widthFraction(0.5)` means using half of the length of the size to make the final
    ///   image round.
    ///   - targetSize: The target size for the output image. If `nil`, the image will retain its original size after 
    ///   processing.
    ///   - corners: The target corners to round.
    ///   - backgroundColor: The background color of the output image. If `nil`, a transparent background will be used.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func roundCorner(
        radius: Radius,
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

    /// Appends a ``BlurImageProcessor`` to the current set of processors.
    ///
    /// - Parameter radius: The blur radius for simulating Gaussian blur.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func blur(radius: CGFloat) -> Self {
        appendProcessor(
            BlurImageProcessor(blurRadius: radius)
        )
    }

    /// Appends an ``OverlayImageProcessor`` to the current set of processors.
    ///
    /// - Parameters:
    ///   - color: The overlay color to be used when overlaying the input image.
    ///   - fraction: The fraction to be used when overlaying the color onto the image.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func overlay(color: KFCrossPlatformColor, fraction: CGFloat = 0.5) -> Self {
        appendProcessor(
            OverlayImageProcessor(overlay: color, fraction: fraction)
        )
    }

    /// Appends a ``TintImageProcessor`` to the current set of processors.
    ///
    /// - Parameter color: The tint color to be used for tinting the input image.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func tint(color: KFCrossPlatformColor) -> Self {
        appendProcessor(
            TintImageProcessor(tint: color)
        )
    }

    /// Appends a ``BlackWhiteProcessor`` to the current set of processors.
    ///
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func blackWhite() -> Self {
        appendProcessor(
            BlackWhiteProcessor()
        )
    }

    /// Appends a ``CroppingImageProcessor`` to the current set of processors.
    ///
    /// - Parameters:
    ///   - size: The target size for the output image.
    ///   - anchor: The anchor point from which the output size should be calculated. The anchor point is represented 
    ///   by two values between 0.0 and 1.0, indicating a relative point in the current image. See
    ///    ``CroppingImageProcessor/init(size:anchor:)`` for more details.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func cropping(size: CGSize, anchor: CGPoint = .init(x: 0.5, y: 0.5)) -> Self {
        appendProcessor(
            CroppingImageProcessor(size: size, anchor: anchor)
        )
    }

    /// Appends a ``DownsamplingImageProcessor`` to the current set of processors.
    ///
    /// Compared to the ``ResizingImageProcessor``, the ``DownsamplingImageProcessor`` doesn't render the original 
    /// images and then resize them. Instead, it directly downsamples the input data to a thumbnail image, making it
    /// more efficient than the ``ResizingImageProcessor``. It is recommended to use the ``DownsamplingImageProcessor``
    /// whenever possible instead of the ``ResizingImageProcessor``.
    ///
    /// - Parameter size: The target size for the output image. It should be smaller than the size of the input image. If it is larger, the resulting image will be the same size as the input data without downsampling.
    /// - Returns: A `Self` value with the changes applied.
    ///
    /// - Note: Only CG-based images are supported, and animated images (e.g., GIF) are not supported.
    ///
    public func downsampling(size: CGSize) -> Self {
        let processor = DownsamplingImageProcessor(size: size)
        if options.processor == DefaultImageProcessor.default {
            return setProcessor(processor)
        } else {
            return appendProcessor(processor)
        }
    }

    /// Appends a ``ResizingImageProcessor`` to the current set of processors.
    ///
    /// If you need to resize a data-represented image to a smaller size, it is recommended to use the
    /// ``DownsamplingImageProcessor`` instead, which is more efficient and uses less memory.
    ///
    /// - Parameters:
    ///   - referenceSize: The reference size for the resizing operation in points.
    ///   - mode: The target content mode for the output image. The default is `.none`.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func resizing(referenceSize: CGSize, mode: ContentMode = .none) -> Self {
        appendProcessor(
            ResizingImageProcessor(referenceSize: referenceSize, mode: mode)
        )
    }
}

// MARK: - Cache Serializer
extension KFOptionSetter {

    /// Uses a specified ``CacheSerializer`` to convert data to an image object for retrieval from the disk cache or
    ///  vice versa for storage to the disk cache.
    ///
    /// - Parameter cacheSerializer: The ``CacheSerializer`` to be used.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func serialize(by cacheSerializer: any CacheSerializer) -> Self {
        options.cacheSerializer = cacheSerializer
        return self
    }

    /// Uses a specified format to serialize the image data to disk. It converts the image object to the given data 
    /// format.
    ///
    /// - Parameters:
    ///   - format: The desired data encoding format when storing the image on disk.
    ///   - jpegCompressionQuality: If the format is ``ImageFormat/JPEG``, it specifies the compression quality when 
    ///   converting the image to JPEG data. Otherwise, it is ignored.
    /// - Returns: A `Self` value with the changes applied.
    ///
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

    /// Sets an ``ImageModifier`` for the image task. Use this to modify the fetched image object's properties if needed.
    ///
    /// If the image was fetched directly from the downloader, the modifier will run directly after the 
    /// ``ImageProcessor``. If the image is being fetched from a cache, the modifier will run after the 
    /// ``CacheSerializer``.
    ///
    /// - Parameter modifier: The ``ImageModifier`` to be used for modifying the image object.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func imageModifier(_ modifier: (any ImageModifier)?) -> Self {
        options.imageModifier = modifier
        return self
    }

    /// Sets a block to modify the image object. Use this to modify the fetched image object's properties if needed.
    ///
    /// If the image was fetched directly from the downloader, the modifier block will run directly after the 
    /// ``ImageProcessor``. If the image is being fetched from a cache, the modifier will run after the
    /// ``CacheSerializer``.
    ///
    /// - Parameter block: The block used to modify the image object.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func imageModifier(_ block: @escaping @Sendable (inout KFCrossPlatformImage) throws -> Void) -> Self {
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

    /// Sets the expiration setting for the memory cache of this image task.
    ///
    /// By default, the underlying ``MemoryStorage/Backend`` uses the expiration in its configuration for all items. 
    /// If set, the ``MemoryStorage/Backend`` will use this value to overwrite the configuration setting for this
    /// caching item.
    ///
    /// - Parameter expiration: The expiration setting used in cache storage.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func memoryCacheExpiration(_ expiration: StorageExpiration?) -> Self {
        options.memoryCacheExpiration = expiration
        return self
    }

    /// Sets the expiration extending setting for the memory cache. The item expiration time will be incremented by this 
    /// value after access.
    ///
    /// By default, the underlying ``MemoryStorage/Backend`` uses the initial cache expiration as the extending value: 
    /// ``ExpirationExtending/cacheTime``.
    ///
    /// To disable the extending option entirely, set `.none` to it.
    ///
    /// - Parameter extending: The expiration extending setting used in cache storage.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func memoryCacheAccessExtending(_ extending: ExpirationExtending) -> Self {
        options.memoryCacheAccessExtendingExpiration = extending
        return self
    }

    /// Sets the expiration setting for the disk cache of this image task.
    ///
    /// By default, the underlying ``DiskStorage/Backend`` uses the expiration in its configuration for all items. 
    /// If set, the ``DiskStorage/Backend`` will use this value to overwrite the configuration setting for this caching
    /// item.
    ///
    /// - Parameter expiration: The expiration setting used in cache storage.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func diskCacheExpiration(_ expiration: StorageExpiration?) -> Self {
        options.diskCacheExpiration = expiration
        return self
    }

    /// Sets the expiration extending setting for the disk cache. The item expiration time will be incremented by this 
    /// value after access.
    ///
    /// By default, the underlying ``DiskStorage/Backend`` uses the initial cache expiration as the extending
    ///  value: ``ExpirationExtending/cacheTime``.
    ///
    /// To disable the extending option entirely, set `.none` to it.
    ///
    /// - Parameter extending: The expiration extending setting used in cache storage.
    /// - Returns: A `Self` value with the changes applied.
    ///
    public func diskCacheAccessExtending(_ extending: ExpirationExtending) -> Self {
        options.diskCacheAccessExtendingExpiration = extending
        return self
    }
}
