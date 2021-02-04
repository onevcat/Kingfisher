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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

#if canImport(TVUIKit)
import TVUIKit
#endif

/// A helper type to create image setting tasks in a builder pattern.
/// Use methods in this type to create a `KF.Builder` instance and configure image tasks there.
public enum KF {

    /// Creates a builder for a given `Source`.
    /// - Parameter source: The `Source` object defines data information from network or a data provider.
    /// - Returns: A `KF.Builder` for future configuration. After configuring the builder, call `set(to:)`
    ///            to start the image loading.
    public static func source(_ source: Source?) -> KF.Builder {
        Builder(source: source)
    }

    /// Creates a builder for a given `Resource`.
    /// - Parameter resource: The `Resource` object defines data information like key or URL.
    /// - Returns: A `KF.Builder` for future configuration. After configuring the builder, call `set(to:)`
    ///            to start the image loading.
    public static func resource(_ resource: Resource?) -> KF.Builder {
        source(resource?.convertToSource())
    }

    /// Creates a builder for a given `URL` and an optional cache key.
    /// - Parameters:
    ///   - url: The URL where the image should be downloaded.
    ///   - cacheKey: The key used to store the downloaded image in cache.
    ///               If `nil`, the `absoluteString` of `url` is used as the cache key.
    /// - Returns: A `KF.Builder` for future configuration. After configuring the builder, call `set(to:)`
    ///            to start the image loading.
    public static func url(_ url: URL?, cacheKey: String? = nil) -> KF.Builder {
        source(url?.convertToSource(overrideCacheKey: cacheKey))
    }

    /// Creates a builder for a given `ImageDataProvider`.
    /// - Parameter provider: The `ImageDataProvider` object contains information about the data.
    /// - Returns: A `KF.Builder` for future configuration. After configuring the builder, call `set(to:)`
    ///            to start the image loading.
    public static func dataProvider(_ provider: ImageDataProvider?) -> KF.Builder {
        source(provider?.convertToSource())
    }

    /// Creates a builder for some given raw data and a cache key.
    /// - Parameters:
    ///   - data: The data object from which the image should be created.
    ///   - cacheKey: The key used to store the downloaded image in cache.
    /// - Returns: A `KF.Builder` for future configuration. After configuring the builder, call `set(to:)`
    ///            to start the image loading.
    public static func data(_ data: Data?, cacheKey: String) -> KF.Builder {
        if let data = data {
            return dataProvider(RawImageDataProvider(data: data, cacheKey: cacheKey))
        } else {
            return dataProvider(nil)
        }
    }
}


extension KF {

    /// A builder class to configure an image retrieving task and set it to a holder view or component.
    public class Builder {
        private let source: Source?

        #if os(watchOS)
        private var placeholder: KFCrossPlatformImage?
        #else
        private var placeholder: Placeholder?
        #endif

        public var options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions)

        public let onFailureDelegate = Delegate<KingfisherError, Void>()
        public let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        public let onProgressDelegate = Delegate<(Int64, Int64), Void>()

        init(source: Source?) {
            self.source = source
        }

        private var resultHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? {
            {
                switch $0 {
                case .success(let result):
                    self.onSuccessDelegate(result)
                case .failure(let error):
                    self.onFailureDelegate(error)
                }
            }
        }

        private var progressBlock: DownloadProgressBlock {
            { self.onProgressDelegate(($0, $1)) }
        }
    }
}

extension KF.Builder {
    #if !os(watchOS)

    /// Builds the image task request and sets it to an image view.
    /// - Parameter imageView: The image view which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    ///            This value is `nil` if the image is being loaded from cache.
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
    ///            This value is `nil` if the image is being loaded from cache.
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
    ///            This value is `nil` if the image is being loaded from cache.
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
    ///            This value is `nil` if the image is being loaded from cache.
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

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Builds the image task request and sets it to a button.
    /// - Parameter button: The button which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    ///            This value is `nil` if the image is being loaded from cache.
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
    ///            This value is `nil` if the image is being loaded from cache.
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
    ///            This value is `nil` if the image is being loaded from cache.
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

    #if canImport(TVUIKit)
    /// Builds the image task request and sets it to a TV monogram view.
    /// - Parameter monogramView: The monogram view which loads the task and should be set with the image.
    /// - Returns: A task represents the image downloading, if initialized.
    ///            This value is `nil` if the image is being loaded from cache.
    @available(tvOS 12.0, *)
    @discardableResult
    public func set(to monogramView: TVMonogramView) -> DownloadTask? {
        let placeholderImage = placeholder as? KFCrossPlatformImage ?? nil
        return monogramView.kf.setImage(
            with: source,
            placeholder: placeholderImage,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: resultHandler
        )
    }
    #endif // end of canImport(TVUIKit)
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

    /// Sets whether keeping the existing image of image view while setting another image to it.
    /// - Parameter enabled: Whether the existing image should be kept.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// By setting this option, the placeholder image parameter of image view extension method
    /// will be ignored and the current image will be kept while loading or downloading the new image.
    ///
    public func keepCurrentImageWhileLoading(_ enabled: Bool = true) -> Self {
        options.keepCurrentImageWhileLoading = enabled
        return self
    }

    /// Sets whether only the first frame from an animated image file should be loaded as a single image.
    /// - Parameter enabled: Whether the only the first frame should be loaded.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// Loading an animated images may take too much memory. It will be useful when you want to display a
    /// static preview of the first frame from an animated image.
    ///
    /// This option will be ignored if the target image is not animated image data.
    ///
    public func onlyLoadFirstFrame(_ enabled: Bool = true) -> Self {
        options.onlyLoadFirstFrame = enabled
        return self
    }

    /// Sets the image that will be used if an image retrieving task fails.
    /// - Parameter image: The image that will be used when something goes wrong.
    /// - Returns: A `KF.Builder` with changes applied.
    ///
    /// If set and an image retrieving error occurred Kingfisher will set provided image (or empty)
    /// in place of requested one. It's useful when you don't want to show placeholder
    /// during loading time but wants to use some default image when requests will be failed.
    ///
    public func onFailureImage(_ image: KFCrossPlatformImage?) -> Self {
        options.onFailureImage = .some(image)
        return self
    }

    /// Enables progressive image loading with a specified `ImageProgressive` setting to process the
    /// progressive JPEG data and display it in a progressive way.
    /// - Parameter progressive: The progressive settings which is used while loading.
    /// - Returns: A `KF.Builder` with changes applied.
    public func progressiveJPEG(_ progressive: ImageProgressive? = .default) -> Self {
        options.progressiveJPEG = progressive
        return self
    }
}

// MARK: - Redirect Handler
extension KF {

    /// Represents the detail information when a task redirect happens. It is wrapping necessary information for a
    /// `ImageDownloadRedirectHandler`. See that protocol for more information.
    public struct RedirectPayload {

        /// The related session data task when the redirect happens. It is
        /// the current `SessionDataTask` which triggers this redirect.
        public let task: SessionDataTask

        /// The response received during redirection.
        public let response: HTTPURLResponse

        /// The request for redirection which can be modified.
        public let newRequest: URLRequest

        /// A closure for being called with modified request.
        public let completionHandler: (URLRequest?) -> Void
    }
}
