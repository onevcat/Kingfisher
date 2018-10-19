//
//  ImageView+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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


#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension KingfisherClass where Base: ImageView {

    /// Set an image with a resource, a placeholder image, options, progress handler and completion handler.
    ///
    /// Internally, this method will use KingfisherManager to get the requested resource, from either cache
    /// or network. Since this methos will perform UI changes, you must call this method from the UI thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the UI thread.
    ///
    /// - Parameters:
    ///   - resource: The Resource object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Placeholder? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: ((Result<RetrieveImageResult>) -> Void)? = nil) -> DownloadTask?
    {
        guard let resource = resource else {
            self.placeholder = placeholder
            webURL = nil
            completionHandler?(.failure(KingfisherError2.imageSettingError(reason: .emptyResource)))
            return nil
        }
        
        var options = KingfisherManager.shared.defaultOptions + (options ?? .empty)
        let noImageOrPlaceholderSet = base.image == nil && self.placeholder == nil
        
        if !options.keepCurrentImageWhileLoading || noImageOrPlaceholderSet {
            // Always set placeholder while there is no image/placehoer yet.
            self.placeholder = placeholder
        }

        let maybeIndicator = indicator
        maybeIndicator?.startAnimatingView()

        webURL = resource.downloadURL

        if base.shouldPreloadAllAnimation() {
            options.append(.preloadAllAnimationData)
        }
        
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL else { return }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    maybeIndicator?.stopAnimatingView()
                    guard resource.downloadURL == self.webURL else {
                        let error = KingfisherError2.imageSettingError(
                            reason: .notCurrentResource(result: result, resource: resource))
                        completionHandler?(.failure(error))
                        return
                    }

                    self.imageTask = nil

                    switch result {
                    case .success(let value):
                        guard self.needsTransition(options: options, cacheType: value.cacheType) else {
                            self.placeholder = nil
                            self.base.image = value.image
                            completionHandler?(result)
                            return
                        }

                        #if !os(macOS)
                        let transition = options.transition
                        UIView.transition(
                            with: self.base,
                            duration: 0.0,
                            options: [],
                            animations: { maybeIndicator?.stopAnimatingView() },
                            completion: { _ in
                                self.placeholder = nil
                                UIView.transition(
                                    with: self.base,
                                    duration: transition.duration,
                                    options: [transition.animationOptions, .allowUserInteraction],
                                    animations: { transition.animations?(self.base, value.image) },
                                    completion: { finished in
                                        transition.completion?(finished)
                                        completionHandler?(result)
                                    }
                                )
                            }
                        )
                        #endif
                    case .failure:
                        completionHandler?(result)
                    }
                }
        })
        
        imageTask = task
        return task
    }

    /// Cancel the image download task bounded to the image view if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }

    private func needsTransition(options: KingfisherOptionsInfo, cacheType: CacheType) -> Bool {
        guard let _ = options.lastMatchIgnoringAssociatedValue(.transition(.none)) else {
            return false
        }
        if options.forceTransition {
            return true
        }
        if cacheType == .none {
            return true
        }
        return false
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var indicatorKey: Void?
private var indicatorTypeKey: Void?
private var placeholderKey: Void?
private var imageTaskKey: Void?

extension KingfisherClass where Base: ImageView {
    /// Gets the image URL binded to this image view.
    public private(set) var webURL: URL? {
        get { return getAssociatedObject(base, &lastURLKey) }
        set { setRetainedAssociatedObject(base, &lastURLKey, newValue) }
    }

    /// Holds which indicator type is going to be used.
    /// Default is .none, means no indicator will be shown.
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


@objc extension ImageView {
    func shouldPreloadAllAnimation() -> Bool { return true }
}
