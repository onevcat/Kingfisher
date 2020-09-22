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

public class KF {
    public static func source(_ source: Source) -> KF.Builder {
        Builder(source: source)
    }

    public static func resource(_ resource: Resource) -> KF.Builder {
        Builder(source: .network(resource))
    }

    public static func url(_ url: URL, cacheKey: String? = nil) -> KF.Builder {
        Builder(source: .network(ImageResource(downloadURL: url, cacheKey: cacheKey)))
    }

    public static func dataProvider(_ provider: ImageDataProvider) -> KF.Builder {
        Builder(source: .provider(provider))
    }

    public static func data(_ data: Data, cacheKey: String) -> KF.Builder {
        Builder(source: .provider(RawImageDataProvider(data: data, cacheKey: cacheKey)))
    }
}


extension KF {
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
    public func progress(_ block: DownloadProgressBlock?) -> Self {
        self.progressBlock = block
        return self
    }

    public func done(_ block: ((RetrieveImageResult) -> Void)?) -> Self {
        self.doneBlock = block
        return self
    }

    public func `catch`(_ block: ((KingfisherError) -> Void)?) -> Self {
        self.errorBlock = block
        return self
    }
}

#if !os(watchOS)
extension KF.Builder {
    #if os(iOS) || os(tvOS)
    public func placeholder(_ placeholder: Placeholder?) -> Self {
        self.placeholder = placeholder
        return self
    }
    #endif

    public func placeholder(_ image: KFCrossPlatformImage?) -> Self {
        self.placeholder = image
        return self
    }
}
#endif

extension KF.Builder {
    public func targetCache(_ cache: ImageCache) -> Self {
        options.targetCache = cache
        return self
    }

    public func originalCache(_ cache: ImageCache) -> Self {
        options.originalCache = cache
        return self
    }

    public func downloader(_ downloader: ImageDownloader) -> Self {
        options.downloader = downloader
        return self
    }

    #if os(iOS) || os(tvOS)
    public func transition(_ transition: ImageTransition) -> Self {
        options.transition = transition
        return self
    }

    public func fade(duration: TimeInterval) -> Self {
        options.transition = .fade(duration)
        return self
    }
    #endif

    public func downloadPriority(_ priority: Float) -> Self {
        options.downloadPriority = priority
        return self
    }

    public func forceRefresh(_ enabled: Bool = true) -> Self {
        options.forceRefresh = enabled
        return self
    }

    public func fromMemoryCacheOrRefresh(_ enabled: Bool = true) -> Self {
        options.fromMemoryCacheOrRefresh = enabled
        return self
    }

    public func forceTransition(_ enabled: Bool = true) -> Self {
        options.forceTransition = enabled
        return self
    }

    public func cacheMemoryOnly(_ enabled: Bool = true) -> Self {
        options.cacheMemoryOnly = enabled
        return self
    }

    public func waitForCache(_ enabled: Bool = true) -> Self {
        options.waitForCache = enabled
        return self
    }

    public func onlyFromCache(_ enabled: Bool = true) -> Self {
        options.onlyFromCache = enabled
        return self
    }

    public func backgroundDecode(_ enabled: Bool = true) -> Self {
        options.backgroundDecode = enabled
        return self
    }

    public func preloadAllAnimationData(enabled: Bool = true) -> Self {
        options.preloadAllAnimationData = enabled
        return self
    }

    public func callbackQueue(_ queue: CallbackQueue) -> Self {
        options.callbackQueue = queue
        return self
    }

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

