//
//  KF.swift
//  Kingfisher
//
//  Created by onevcat on 2020/09/21.
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

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

/// A helper type to create image setting tasks in a builder pattern.
/// Use methods in this type to create a `KF.Builder` instance and configure image tasks there.
public enum KF {

    /// Creates a builder for a given `Source`.
    /// - Parameter source: The `Source` object defines data information from network or a data provider.
    /// - Returns: A `KF.Builder` for future configuration or image setting.
    public static func source(_ source: Source) -> KF.Builder {
        Builder(source: source)
    }

    /// Creates a builder for a given `Resource`.
    /// - Parameter resource: The `Resource` object defines data information like key or URL.
    /// - Returns: A `KF.Builder` for future configuration or image setting.
    public static func resource(_ resource: Resource) -> KF.Builder {
        Builder(source: .network(resource))
    }

    /// Creates a builder for a given `URL` and an optional cache key.
    /// - Parameters:
    ///   - url: The URL where the image should be downloaded.
    ///   - cacheKey: The key used to store the downloaded image in cache.
    ///               If `nil`, the `absoluteString` of `url` is used as the cache key.
    /// - Returns: A `KF.Builder` for future configuration or image setting.
    public static func url(_ url: URL, cacheKey: String? = nil) -> KF.Builder {
        Builder(source: .network(ImageResource(downloadURL: url, cacheKey: cacheKey)))
    }

    /// Creates a builder for a given `ImageDataProvider`.
    /// - Parameter provider: The `ImageDataProvider` object contains information about the data.
    /// - Returns: A `KF.Builder` for future configuration or image setting.
    public static func dataProvider(_ provider: ImageDataProvider) -> KF.Builder {
        Builder(source: .provider(provider))
    }

    /// Creates a builder for some given raw data and a cache key.
    /// - Parameters:
    ///   - data: The data object from which the image should be created.
    ///   - cacheKey: The key used to store the downloaded image in cache.
    /// - Returns: A `KF.Builder` for future configuration or image setting.
    public static func data(_ data: Data, cacheKey: String) -> KF.Builder {
        Builder(source: .provider(RawImageDataProvider(data: data, cacheKey: cacheKey)))
    }
}


extension KF {

    /// A builder class to configure an image retrieving task and set it to a holder view or component.
    public class Builder {
        private let source: Source

        #if os(watchOS)
        private var placeholder: KFCrossPlatformImage?
        #else
        private var placeholder: Placeholder?
        #endif

        private var options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions)

        private var progressBlock: DownloadProgressBlock?
        private var doneBlock: ((RetrieveImageResult) -> Void)?
        private var errorBlock: ((KingfisherError) -> Void)?

        init(source: Source) {
            self.source = source
        }

        private var resultHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? {
            if doneBlock == nil && errorBlock == nil {
                return nil
            }
            return { result in
                switch result {
                case .success(let result):
                    self.doneBlock?(result)
                case .failure(let error):
                    self.errorBlock?(error)
                }
            }
        }
    }
}

extension KF.Builder {
    #if !os(watchOS)

    /// Builds the image task request and sets it to an image view.
    /// - Parameter imageView: The image view which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func set(to imageView: KFCrossPlatformImageView) -> DownloadTask? {
        imageView.kf.setImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }

    /// Builds the image task request and sets it to an `NSTextAttachment` object.
    /// - Parameters:
    ///   - attachment: The text attachment object which loads the task and should be set with the image.
    ///   - attributedView: The owner of the attributed string which this `NSTextAttachment` is added.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func set(to attachment: NSTextAttachment, attributedView: KFCrossPlatformView) -> DownloadTask? {
        let placeholderImage = placeholder as? KFCrossPlatformImage ?? nil
        return attachment.kf.setImage(
            with: source,
            attributedView: attributedView,
            placeholder: placeholderImage,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }

    #if canImport(UIKit)

    /// Builds the image task request and sets it to a button.
    /// - Parameters:
    ///   - button: The button which loads the task and should be set with the image.
    ///   - state: The button state to which the image should be set.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func set(to button: UIButton, for state: UIControl.State) -> DownloadTask? {
        let placeholderImage = placeholder as? KFCrossPlatformImage ?? nil
        return button.kf.setImage(
            with: source,
            for: state,
            placeholder: placeholderImage,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }

    /// Builds the image task request and sets it to the background image for a button.
    /// - Parameters:
    ///   - button: The button which loads the task and should be set with the image.
    ///   - state: The button state to which the image should be set.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func setBackground(to button: UIButton, for state: UIControl.State) -> DownloadTask? {
        let placeholderImage = placeholder as? KFCrossPlatformImage ?? nil
        return button.kf.setBackgroundImage(
            with: source,
            for: state,
            placeholder: placeholderImage,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }
    #endif // end of canImport(UIKit)

    #if canImport(AppKit)
    /// Builds the image task request and sets it to a button.
    /// - Parameter button: The button which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func set(to button: NSButton) -> DownloadTask? {
        let placeholderImage = placeholder as? KFCrossPlatformImage ?? nil
        return button.kf.setImage(
            with: source,
            placeholder: placeholderImage,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }

    /// Builds the image task request and sets it to the alternative image for a button.
    /// - Parameter button: The button which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func setAlternative(to button: NSButton) -> DownloadTask? {
        let placeholderImage = placeholder as? KFCrossPlatformImage ?? nil
        return button.kf.setAlternateImage(
            with: source,
            placeholder: placeholderImage,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }
    #endif // end of canImport(AppKit)
    #endif // end of !os(watchOS)

    #if canImport(WatchKit)
    /// Builds the image task request and sets it to a `WKInterfaceImage` object.
    /// - Parameter interfaceImage: The watch interface image which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    @discardableResult
    public func set(to interfaceImage: WKInterfaceImage) -> DownloadTask? {
        return interfaceImage.kf.setImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }
    #endif // end of canImport(WatchKit)
}

extension KF.Builder {

    /// Sets the progress block to current builder.
    /// - Parameter block: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    /// - Returns: A `KF.Builder` with changes applied.
    public func progress(_ block: DownloadProgressBlock?) -> Self {
        self.progressBlock = block
        return self
    }

    /// Sets the the done block to current builder.
    /// - Parameter block: Called when the image task successfully completes and the the image set is done.
    /// - Returns: A `KF.Builder` with changes applied.
    public func done(_ block: ((RetrieveImageResult) -> Void)?) -> Self {
        self.doneBlock = block
        return self
    }

    /// Sets the catch block to current builder.
    /// - Parameter block: Called when an error happens during the image task.
    /// - Returns: A `KF.Builder` with changes applied.
    public func `catch`(_ block: ((KingfisherError) -> Void)?) -> Self {
        self.errorBlock = block
        return self
    }
}

#if !os(watchOS)
extension KF.Builder {
    #if os(iOS) || os(tvOS)

    /// Sets a placeholder which is used while retrieving the image.
    /// - Parameter placeholder: A placeholder to show while retrieving the image from its source.
    /// - Returns: A `KF.Builder` with changes applied.
    public func placeholder(_ placeholder: Placeholder?) -> Self {
        self.placeholder = placeholder
        return self
    }
    #endif

    /// Sets a placeholder image which is used while retrieving the image.
    /// - Parameter placeholder: An image to show while retrieving the image from its source.
    /// - Returns: A `KF.Builder` with changes applied.
    public func placeholder(_ image: KFCrossPlatformImage?) -> Self {
        self.placeholder = image
        return self
    }
}
#endif

extension KF.Builder {

    /// Sets the target image cache for this task.
    /// - Parameter cache: The target cache is about to be used for the task.
    /// - Returns: A `KF.Builder` with changes applied.
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
    /// - Returns: A `KF.Builder` with changes applied.
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
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// Kingfisher will use the set `ImageDownloader` object to download the requested images.
    public func downloader(_ downloader: ImageDownloader) -> Self {
        options.downloader = downloader
        return self
    }

    #if os(iOS) || os(tvOS)
    /// Sets the transition for the image task.
    /// - Parameter transition: The desired transition effect when setting the image to image view.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// Kingfisher will use the `transition` to animate the image in if it is downloaded from web.
    /// The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, also call `forceRefresh()` on the returned `KF.Builder`.
    public func transition(_ transition: ImageTransition) -> Self {
        options.transition = transition
        return self
    }

    /// Sets a fade transition for the image task.
    /// - Parameter duration: The duration of the fade transition.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// Kingfisher will use the fade transition to animate the image in if it is downloaded from web.
    /// The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, also call `forceRefresh()` on the returned `KF.Builder`.
    public func fade(duration: TimeInterval) -> Self {
        options.transition = .fade(duration)
        return self
    }
    #endif

    /// Sets the download priority for the image task.
    /// - Parameter priority: The download priority of image download task.
    /// - Returns: A `KF.Builder` with changes applied.
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
    /// - Returns: A `KF.Builder` with changes applied.
    public func forceRefresh(_ enabled: Bool = true) -> Self {
        options.forceRefresh = enabled
        return self
    }

    /// Sets whether Kingfisher should try to retrieve the image from memory cache first. If not found, it ignores the
    /// disk cache and starts a download task for the image source.
    /// - Parameter enabled: Enable the memory-only cache searching or not.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// This is useful when
    /// you want to display a changeable image behind the same url at the same app session, while avoiding download
    /// it for multiple times.
    public func fromMemoryCacheOrRefresh(_ enabled: Bool = true) -> Self {
        options.fromMemoryCacheOrRefresh = enabled
        return self
    }

    /// Sets whether the image setting for an image view should happen with transition even when retrieved from cache.
    /// - Parameter enabled: Enable the force transition or not.
    /// - Returns: A `KF.Builder` with changes applied.
    public func forceTransition(_ enabled: Bool = true) -> Self {
        options.forceTransition = enabled
        return self
    }

    /// Sets whether the image should only be cached in memory but not in disk.
    /// - Parameter enabled: Whether the image should be only cache in memory or not.
    /// - Returns: A `KF.Builder` with changes applied.
    public func cacheMemoryOnly(_ enabled: Bool = true) -> Self {
        options.cacheMemoryOnly = enabled
        return self
    }

    /// Sets whether Kingfisher should wait for caching operation to be completed before calling the
    /// `done` or `catch` block.
    /// - Parameter enabled: Whether Kingfisher should wait for caching operation.
    /// - Returns: A `KF.Builder` with changes applied.
    public func waitForCache(_ enabled: Bool = true) -> Self {
        options.waitForCache = enabled
        return self
    }

    /// Sets whether Kingfisher should only try to retrieve the image from cache, but not from network.
    /// - Parameter enabled: Whether Kingfisher should only try to retrieve the image from cache.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// If the image is not in cache, the image retrieving will fail with the
    /// `KingfisherError.cacheError` with `.imageNotExisting` as its reason.
    public func onlyFromCache(_ enabled: Bool = true) -> Self {
        options.onlyFromCache = enabled
        return self
    }

    /// Sets whether the image should be decoded in a background thread before using.
    /// - Parameter enabled: Whether the image should be decoded in a background thread before using.
    /// - Returns: A `KF.Builder` with changes applied.
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
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// - Note:
    /// This option does not affect the callbacks for UI related extension methods. You will always get the
    /// callbacks called from main queue.
    public func callbackQueue(_ queue: CallbackQueue) -> Self {
        options.callbackQueue = queue
        return self
    }

    /// Sets the scale factor value when converting retrieved data to an image.
    /// - Parameter factor: The scale factor value.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// Specify the image scale, instead of your screen scale. You may need to set the correct scale when you dealing
    /// with 2x or 3x retina images. Otherwise, Kingfisher will convert the data to image object at `scale` 1.0.
    ///
    public func scaleFactor(_ factor: CGFloat) -> Self {
        options.scaleFactor = factor
        return self
    }

    public func keepCurrentImageWhileLoading(_ enabled: Bool = true) -> Self {
        options.keepCurrentImageWhileLoading = enabled
        return self
    }

    public func onlyLoadFirstFrame(_ enabled: Bool = true) -> Self {
        options.onlyLoadFirstFrame = enabled
        return self
    }

    public func cacheOriginalImage(_ enabled: Bool = true) -> Self {
        options.cacheOriginalImage = enabled
        return self
    }

    public func onFailureImage(_ image: KFCrossPlatformImage?) -> Self {
        options.onFailureImage = .some(image)
        return self
    }

    public func loadDiskFileSynchronously(_ enabled: Bool = true) -> Self {
        options.loadDiskFileSynchronously = enabled
        return self
    }

    public func processingQueue(_ queue: CallbackQueue?) -> Self {
        options.processingQueue = queue
        return self
    }

    public func progressiveJPEG(_ progressive: ImageProgressive? = .default) -> Self {
        options.progressiveJPEG = progressive
        return self
    }

    public func alternativeSources(_ sources: [Source]?) -> Self {
        options.alternativeSources = sources
        return self
    }

    public func retry(_ strategy: RetryStrategy) -> Self {
        options.retryStrategy = strategy
        return self
    }

    public func retry(maxCount: Int, interval: DelayRetryStrategy.Interval = .seconds(3)) -> Self {
        let strategy = DelayRetryStrategy(maxRetryCount: maxCount, retryInterval: interval)
        options.retryStrategy = strategy
        return self
    }
}

// MARK: - Request Modifier
extension KF.Builder {
    public func requestModifier(_ modifier: ImageDownloadRequestModifier) -> Self {
        options.requestModifier = modifier
        return self
    }

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
extension KF {
    public struct RedirectPayload {
        public let task: SessionDataTask
        public let response: HTTPURLResponse
        public let newRequest: URLRequest
        public let completionHandler: (URLRequest?) -> Void
    }
}

extension KF.Builder {

    public func redirectHandler(_ handler: ImageDownloadRedirectHandler) -> Self {
        options.redirectHandler = handler
        return self
    }

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
extension KF.Builder {
    public func setProcessor(_ processor: ImageProcessor) -> Self {
        options.processor = processor
        return self
    }

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

    public func appendProcessor(_ processor: ImageProcessor) -> Self {
        options.processor = options.processor |> processor
        return self
    }

    public func roundCorner(
        point: CGFloat,
        targetSize: CGSize? = nil,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> Self
    {
        let processor = RoundCornerImageProcessor(
            radius: .point(point),
            targetSize: targetSize,
            roundingCorners: corners,
            backgroundColor: backgroundColor
        )
        return appendProcessor(processor)
    }

    public func roundCorner(
        widthFraction: CGFloat,
        targetSize: CGSize? = nil,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> Self {
        let processor = RoundCornerImageProcessor(
            radius: .widthFraction(widthFraction),
            targetSize: targetSize,
            roundingCorners: corners,
            backgroundColor: backgroundColor
        )
        return appendProcessor(processor)
    }

    public func roundCorner(
        heightFraction: CGFloat,
        targetSize: CGSize? = nil,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> Self {
        let processor = RoundCornerImageProcessor(
            radius: .heightFraction(heightFraction),
            targetSize: targetSize,
            roundingCorners: corners,
            backgroundColor: backgroundColor
        )
        return appendProcessor(processor)
    }

    public func blur(radius: CGFloat) -> Self {
        appendProcessor(
            BlurImageProcessor(blurRadius: radius)
        )
    }

    public func overlay(color: KFCrossPlatformColor, fraction: CGFloat = 0.5) -> Self {
        appendProcessor(
            OverlayImageProcessor(overlay: color, fraction: fraction)
        )
    }

    public func tint(color: KFCrossPlatformColor) -> Self {
        appendProcessor(
            TintImageProcessor(tint: color)
        )
    }

    public func blackWhite() -> Self {
        appendProcessor(
            BlackWhiteProcessor()
        )
    }

    public func cropping(size: CGSize, anchor: CGPoint = .init(x: 0.5, y: 0.5)) -> Self {
        appendProcessor(
            CroppingImageProcessor(size: size, anchor: anchor)
        )
    }

    public func downsampling(size: CGSize) -> Self {
        let processor = DownsamplingImageProcessor(size: size)
        if options.processor == DefaultImageProcessor.default {
            return setProcessor(processor)
        } else {
            return appendProcessor(processor)
        }
    }

    public func resizing(referenceSize: CGSize, mode: ContentMode = .none) -> Self {
        appendProcessor(
            ResizingImageProcessor(referenceSize: referenceSize, mode: mode)
        )
    }
}

// MARK: - Cache Serializer
extension KF.Builder {
    public func serialize(by cacheSerializer: CacheSerializer) -> Self {
        options.cacheSerializer = cacheSerializer
        return self
    }

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
extension KF.Builder {
    public func imageModifier(_ modifier: ImageModifier?) -> Self {
        options.imageModifier = modifier
        return self
    }

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
extension KF.Builder {
    public func memoryCacheExpiration(_ expiration: StorageExpiration?) -> Self {
        options.memoryCacheExpiration = expiration
        return self
    }

    public func memoryCacheAccessExtending(_ extending: ExpirationExtending) -> Self {
        options.memoryCacheAccessExtendingExpiration = extending
        return self
    }

    public func diskCacheExpiration(_ expiration: StorageExpiration?) -> Self {
        options.diskCacheExpiration = expiration
        return self
    }

    public func diskCacheAccessExtending(_ extending: ExpirationExtending) -> Self {
        options.diskCacheAccessExtendingExpiration = extending
        return self
    }
}

