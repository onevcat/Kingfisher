//
//  UIButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/13.
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

import UIKit

extension KingfisherClass where Base: UIButton {
    
    /// Sets an image to the button for a specified state with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the resource.
    ///   - state: The button state to which the image should be set.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `KingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(with resource: Resource?,
                         for state: UIControl.State,
                         placeholder: UIImage? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil)
        -> DownloadTask?
    {
        guard let resource = resource else {
            base.setImage(placeholder, for: state)
            setWebURL(nil, for: state)
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptyResource)))
            return nil
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? .empty)
        if !options.keepCurrentImageWhileLoading {
            base.setImage(placeholder, for: state)
        }
        
        setWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL(for: state) else { return }
                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    guard resource.downloadURL == self.webURL(for: state) else {
                        let error = KingfisherError.imageSettingError(
                            reason: .notCurrentSource(result: result.value, error: result.error, source: .network(resource)))
                        completionHandler?(.failure(error))
                        return
                    }
                    
                    self.imageTask = nil

                    switch result {
                    case .success(let value):
                        self.base.setImage(value.image, for: state)
                        completionHandler?(result)
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.setImage(image, for: state)
                        }
                        completionHandler?(result)
                    }
                }
            })
        
        imageTask = task
        return task
    }
    
    /// Cancels the image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelImageDownloadTask() {
        imageTask?.cancel()
    }
    
    /// Sets a background image to the button for a specified state with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the resource.
    ///   - state: The button state to which the image should be set.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `KingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setBackgroundImage(with resource: Resource?,
                                   for state: UIControl.State,
                                   placeholder: UIImage? = nil,
                                   options: KingfisherOptionsInfo? = nil,
                                   progressBlock: DownloadProgressBlock? = nil,
                                   completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil)
        -> DownloadTask?
    {
        guard let resource = resource else {
            base.setBackgroundImage(placeholder, for: state)
            setBackgroundWebURL(nil, for: state)
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptyResource)))
            return nil
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? .empty)
        if !options.keepCurrentImageWhileLoading {
            base.setBackgroundImage(placeholder, for: state)
        }
        
        setBackgroundWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.backgroundWebURL(for: state) else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    guard resource.downloadURL == self.backgroundWebURL(for: state) else {
                        let error = KingfisherError.imageSettingError(
                            reason: .notCurrentSource(result: result.value, error: result.error, source: .network(resource)))
                        completionHandler?(.failure(error))
                        return
                    }
                    self.backgroundImageTask = nil
                    
                    switch result {
                    case .success(let value):
                        self.base.setBackgroundImage(value.image, for: state)
                        completionHandler?(result)
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.setBackgroundImage(image, for: state)
                        }
                        completionHandler?(result)
                    }
                }
            })
        
        backgroundImageTask = task
        return task
    }
    
    /// Cancels the background image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelBackgroundImageDownloadTask() {
        backgroundImageTask?.cancel()
    }

}

// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension KingfisherClass where Base: UIButton {

    /// Gets the image URL of this button for a specified state.
    ///
    /// - Parameter state: The state that uses the specified image.
    /// - Returns: Current URL for image.
    public func webURL(for state: UIControl.State) -> URL? {
        return webURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    private func setWebURL(_ url: URL?, for state: UIControl.State) {
        webURLs[NSNumber(value:state.rawValue)] = url
    }
    
    private var webURLs: NSMutableDictionary {
        get {
            guard let dictionary: NSMutableDictionary = getAssociatedObject(base, &lastURLKey) else {
                let dic = NSMutableDictionary()
                self.webURLs = dic
                return dic
            }
            return dictionary
        }
        set {
            setRetainedAssociatedObject(base, &lastURLKey, newValue)
        }
    }
    
    private var imageTask: DownloadTask? {
        get { return getAssociatedObject(base, &imageTaskKey) }
        set { setRetainedAssociatedObject(base, &imageTaskKey, newValue)}
    }
}


private var lastBackgroundURLKey: Void?
private var backgroundImageTaskKey: Void?


extension KingfisherClass where Base: UIButton {
    
    /// Gets the background image URL of this button for a specified state.
    ///
    /// - Parameter state: The state that uses the specified background image.
    /// - Returns: Current URL for image.
    public func backgroundWebURL(for state: UIControl.State) -> URL? {
        return backgroundWebURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    private func setBackgroundWebURL(_ url: URL?, for state: UIControl.State) {
        backgroundWebURLs[NSNumber(value:state.rawValue)] = url
    }
    
    private var backgroundWebURLs: NSMutableDictionary {
        get {
            guard let dictionary: NSMutableDictionary = getAssociatedObject(base, &lastBackgroundURLKey) else {
                let dic = NSMutableDictionary()
                self.backgroundWebURLs = dic
                return dic
            }
            return dictionary
        }
        set {
            setRetainedAssociatedObject(base, &lastBackgroundURLKey, newValue)
        }
    }
    
    private var backgroundImageTask: DownloadTask? {
        get { return getAssociatedObject(base, &backgroundImageTaskKey) }
        set { setRetainedAssociatedObject(base, &backgroundImageTaskKey, newValue) }
    }
}
