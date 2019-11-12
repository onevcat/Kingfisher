//
//  ImageView+Kingfisher.swift
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

#if !os(watchOS)

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension KingfisherWrapper where Base: KFCrossPlatformImageView {

    // MARK: Setting Image

    /// Sets an image to the image view with a `Source`.
    ///
    /// - Parameters:
    ///   - source: The `Source` object defines data information from network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```
    /// // Set image from a network source.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: .network(url))
    ///
    /// // Or set image from a data provider.
    /// let provider = LocalFileImageDataProvider(fileURL: fileURL)
    /// imageView.kf.setImage(with: .provider(provider))
    /// ```
    ///
    /// For both `.network` and `.provider` source, there are corresponding view extension methods. So the code
    /// above is equivalent to:
    ///
    /// ```
    /// imageView.kf.setImage(with: url)
    /// imageView.kf.setImage(with: provider)
    /// ```
    ///
    /// Internally, this method will use `KingfisherManager` to get the source.
    /// Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with source: Source?,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        var mutatingSelf = self
        guard let source = source else {
            mutatingSelf.placeholder = placeholder
            mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }

        var options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        let noImageOrPlaceholderSet = base.image == nil && self.placeholder == nil
        if !options.keepCurrentImageWhileLoading || noImageOrPlaceholderSet {
            // Always set placeholder while there is no image/placeholder yet.
            mutatingSelf.placeholder = placeholder
        }

        let maybeIndicator = indicator
        maybeIndicator?.startAnimatingView()

        let issuedIdentifier = Source.Identifier.next()
        mutatingSelf.taskIdentifier = issuedIdentifier

        if base.shouldPreloadAllAnimation() {
            options.preloadAllAnimationData = true
        }

        if let block = progressBlock {
            options.onDataReceived = (options.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }

        if let provider = ImageProgressiveProvider(options, refresh: { image in
            self.base.image = image
        }) {
            options.onDataReceived = (options.onDataReceived ?? []) + [provider]
        }
        
        options.onDataReceived?.forEach {
            $0.onShouldApply = { issuedIdentifier == self.taskIdentifier }
        }

        let task = KingfisherManager.shared.retrieveImage(
            with: source,
            options: options,
            downloadTaskUpdated: { mutatingSelf.imageTask = $0 },
            completionHandler: { result in
                CallbackQueue.mainCurrentOrAsync.execute {
                    maybeIndicator?.stopAnimatingView()
                    guard issuedIdentifier == self.taskIdentifier else {
                        let reason: KingfisherError.ImageSettingErrorReason
                        do {
                            let value = try result.get()
                            reason = .notCurrentSourceTask(result: value, error: nil, source: source)
                        } catch {
                            reason = .notCurrentSourceTask(result: nil, error: error, source: source)
                        }
                        let error = KingfisherError.imageSettingError(reason: reason)
                        completionHandler?(.failure(error))
                        return
                    }
                    
                    mutatingSelf.imageTask = nil
                    mutatingSelf.taskIdentifier = nil
                    
                    switch result {
                    case .success(let value):
                        guard self.needsTransition(options: options, cacheType: value.cacheType) else {
                            mutatingSelf.placeholder = nil
                            self.base.image = value.image
                            completionHandler?(result)
                            return
                        }
                        
                        self.makeTransition(image: value.image, transition: options.transition) {
                            completionHandler?(result)
                        }
                        
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.image = image
                        }
                        completionHandler?(result)
                    }
                }
            }
        )
        mutatingSelf.imageTask = task
        return task
    }

    /// Sets an image to the image view with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// This is the easiest way to use Kingfisher to boost the image setting process from network. Since all parameters
    /// have a default value except the `resource`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: url)
    /// ```
    ///
    /// Internally, this method will use `KingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with resource: Resource?,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        return setImage(
            with: resource.map { .network($0) },
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    /// Sets an image to the image view with a data provider.
    ///
    /// - Parameters:
    ///   - provider: The `ImageDataProvider` object contains information about the data.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// Internally, this method will use `KingfisherManager` to get the image data, from either cache
    /// or the data provider. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with provider: ImageDataProvider?,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        return setImage(
            with: provider.map { .provider($0) },
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    // MARK: Cancelling Downloading Task

    /// Cancels the image download task of the image view if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }

    private func needsTransition(options: KingfisherParsedOptionsInfo, cacheType: CacheType) -> Bool {
        switch options.transition {
        case .none:
            return false
        #if !os(macOS)
        default:
            if options.forceTransition { return true }
            if cacheType == .none { return true }
            return false
        #endif
        }
    }

    private func makeTransition(image: KFCrossPlatformImage, transition: ImageTransition, done: @escaping () -> Void) {
        #if !os(macOS)
        // Force hiding the indicator without transition first.
        UIView.transition(
            with: self.base,
            duration: 0.0,
            options: [],
            animations: { self.indicator?.stopAnimatingView() },
            completion: { _ in
                var mutatingSelf = self
                mutatingSelf.placeholder = nil
                UIView.transition(
                    with: self.base,
                    duration: transition.duration,
                    options: [transition.animationOptions, .allowUserInteraction],
                    animations: { transition.animations?(self.base, image) },
                    completion: { finished in
                        transition.completion?(finished)
                        done()
                    }
                )
            }
        )
        #else
        done()
        #endif
    }
}

// MARK: - Associated Object
private var taskIdentifierKey: Void?
private var indicatorKey: Void?
private var indicatorTypeKey: Void?
private var placeholderKey: Void?
private var imageTaskKey: Void?

extension KingfisherWrapper where Base: KFCrossPlatformImageView {

    // MARK: Properties
    public private(set) var taskIdentifier: Source.Identifier.Value? {
        get {
            let box: Box<Source.Identifier.Value>? = getAssociatedObject(base, &taskIdentifierKey)
            return box?.value
        }
        set {
            let box = newValue.map { Box($0) }
            setRetainedAssociatedObject(base, &taskIdentifierKey, box)
        }
    }

    /// Holds which indicator type is going to be used.
    /// Default is `.none`, means no indicator will be shown while downloading.
    public var indicatorType: IndicatorType {
        get {
            return getAssociatedObject(base, &indicatorTypeKey) ?? .none
        }
        
        set {
            switch newValue {
            case .none: indicator = nil
            case .activity: indicator = ActivityIndicator()
            case .image(let data): indicator = ImageIndicator(imageData: data)
            case .custom(let anIndicator): indicator = anIndicator
            }

            setRetainedAssociatedObject(base, &indicatorTypeKey, newValue)
        }
    }
    
    /// Holds any type that conforms to the protocol `Indicator`.
    /// The protocol `Indicator` has a `view` property that will be shown when loading an image.
    /// It will be `nil` if `indicatorType` is `.none`.
    public private(set) var indicator: Indicator? {
        get {
            let box: Box<Indicator>? = getAssociatedObject(base, &indicatorKey)
            return box?.value
        }
        
        set {
            // Remove previous
            if let previousIndicator = indicator {
                previousIndicator.view.removeFromSuperview()
            }
            
            // Add new
            if let newIndicator = newValue {
                // Set default indicator layout
                let view = newIndicator.view
                
                base.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false
                view.centerXAnchor.constraint(
                    equalTo: base.centerXAnchor, constant: newIndicator.centerOffset.x).isActive = true
                view.centerYAnchor.constraint(
                    equalTo: base.centerYAnchor, constant: newIndicator.centerOffset.y).isActive = true

                switch newIndicator.sizeStrategy(in: base) {
                case .intrinsicSize:
                    break
                case .full:
                    view.heightAnchor.constraint(equalTo: base.heightAnchor, constant: 0).isActive = true
                    view.widthAnchor.constraint(equalTo: base.widthAnchor, constant: 0).isActive = true
                case .size(let size):
                    view.heightAnchor.constraint(equalToConstant: size.height).isActive = true
                    view.widthAnchor.constraint(equalToConstant: size.width).isActive = true
                }
                
                newIndicator.view.isHidden = true
            }

            // Save in associated object
            // Wrap newValue with Box to workaround an issue that Swift does not recognize
            // and casting protocol for associate object correctly. https://github.com/onevcat/Kingfisher/issues/872
            setRetainedAssociatedObject(base, &indicatorKey, newValue.map(Box.init))
        }
    }
    
    private var imageTask: DownloadTask? {
        get { return getAssociatedObject(base, &imageTaskKey) }
        set { setRetainedAssociatedObject(base, &imageTaskKey, newValue)}
    }

    /// Represents the `Placeholder` used for this image view. A `Placeholder` will be shown in the view while
    /// it is downloading an image.
    public private(set) var placeholder: Placeholder? {
        get { return getAssociatedObject(base, &placeholderKey) }
        set {
            if let previousPlaceholder = placeholder {
                previousPlaceholder.remove(from: base)
            }
            
            if let newPlaceholder = newValue {
                newPlaceholder.add(to: base)
            } else {
                base.image = nil
            }
            setRetainedAssociatedObject(base, &placeholderKey, newValue)
        }
    }
}


@objc extension KFCrossPlatformImageView {
    func shouldPreloadAllAnimation() -> Bool { return true }
}

extension KingfisherWrapper where Base: KFCrossPlatformImageView {
    /// Gets the image URL bound to this image view.
    @available(*, deprecated, message: "Use `taskIdentifier` instead to identify a setting task.")
    public private(set) var webURL: URL? {
        get { return nil }
        set { }
    }
}

#endif
