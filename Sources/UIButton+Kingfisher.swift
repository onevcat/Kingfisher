//
//  UIButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/13.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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

// MARK: - Set Images
/**
 *	Set image to use in button from web for a specified state.
 */
extension Kingfisher where Base: UIButton {
    /**
     Set an image to use for a specified state with a resource, a placeholder image, options, progress handler and
     completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter state:             The state that uses the specified image.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     
     If `resource` is `nil`, the `placeholder` image will be set and
     `completionHandler` will be called with both `error` and `image` being `nil`.
     */
    @discardableResult
    public func setImage(with resource: Resource?,
                         for state: UIControlState,
                         placeholder: UIImage? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            base.setImage(placeholder, for: state)
            setWebURL(nil, for: state)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo)
        if !options.keepCurrentImageWhileLoading {
            base.setImage(placeholder, for: state)
        }
        
        setWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL(for: state) else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: {[weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.webURL(for: state) else {
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }
                    self.setImageTask(nil)
                    if image != nil {
                        strongBase.setImage(image, for: state)
                    }

                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        setImageTask(task)
        return task
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelImageDownloadTask() {
        imageTask?.cancel()
    }
    
    /**
     Set the background image to use for a specified state with a resource,
     a placeholder image, options progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter state:             The state that uses the specified image.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     
     If `resource` is `nil`, the `placeholder` image will be set and
     `completionHandler` will be called with both `error` and `image` being `nil`.
     */
    @discardableResult
    public func setBackgroundImage(with resource: Resource?,
                                   for state: UIControlState,
                                   placeholder: UIImage? = nil,
                                   options: KingfisherOptionsInfo? = nil,
                                   progressBlock: DownloadProgressBlock? = nil,
                                   completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            base.setBackgroundImage(placeholder, for: state)
            setBackgroundWebURL(nil, for: state)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo)
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
            completionHandler: { [weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.backgroundWebURL(for: state) else {
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }
                    self.setBackgroundImageTask(nil)
                    if image != nil {
                        strongBase.setBackgroundImage(image, for: state)
                    }
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        setBackgroundImageTask(task)
        return task
    }
    
    /**
     Cancel the background image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelBackgroundImageDownloadTask() {
        backgroundImageTask?.cancel()
    }

}

// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension Kingfisher where Base: UIButton {
    /**
     Get the image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified image.
     
     - returns: Current URL for image.
     */
    public func webURL(for state: UIControlState) -> URL? {
        return webURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func setWebURL(_ url: URL?, for state: UIControlState) {
        webURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var webURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(base, &lastURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            setWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func setWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(base, &lastURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


private var lastBackgroundURLKey: Void?
private var backgroundImageTaskKey: Void?


extension Kingfisher where Base: UIButton {
    /**
     Get the background image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified background image.
     
     - returns: Current URL for background image.
     */
    public func backgroundWebURL(for state: UIControlState) -> URL? {
        return backgroundWebURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func setBackgroundWebURL(_ url: URL?, for state: UIControlState) {
        backgroundWebURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var backgroundWebURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(base, &lastBackgroundURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            setBackgroundWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func setBackgroundWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(base, &lastBackgroundURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var backgroundImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &backgroundImageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setBackgroundImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &backgroundImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Deprecated. Only for back compatibility.
/**
*	Set image to use from web for a specified state. Deprecated. Use `kf` namespacing instead.
*/
extension UIButton {
    /**
    Set an image to use for a specified state with a resource, a placeholder image, options, progress handler and 
     completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:             The state that uses the specified image.
    - parameter placeholder:       A placeholder image when retrieving the image at URL.
    - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    @discardableResult
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.kf.setImage` instead.",
    renamed: "kf.setImage")
    public func kf_setImage(with resource: Resource?,
                                for state: UIControlState,
                              placeholder: UIImage? = nil,
                                  options: KingfisherOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                        completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return kf.setImage(with: resource, for: state, placeholder: placeholder, options: options,
                              progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.kf.cancelImageDownloadTask` instead.",
    renamed: "kf.cancelImageDownloadTask")
    public func kf_cancelImageDownloadTask() { kf.cancelImageDownloadTask() }
    
    /**
     Set the background image to use for a specified state with a resource,
     a placeholder image, options progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter state:             The state that uses the specified image.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    @discardableResult
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.kf.setBackgroundImage` instead.",
    renamed: "kf.setBackgroundImage")
    public func kf_setBackgroundImage(with resource: Resource?,
                                      for state: UIControlState,
                                      placeholder: UIImage? = nil,
                                      options: KingfisherOptionsInfo? = nil,
                                      progressBlock: DownloadProgressBlock? = nil,
                                      completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return kf.setBackgroundImage(with: resource, for: state, placeholder: placeholder, options: options,
                                     progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Cancel the background image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.kf.cancelBackgroundImageDownloadTask` instead.",
    renamed: "kf.cancelBackgroundImageDownloadTask")
    public func kf_cancelBackgroundImageDownloadTask() { kf.cancelBackgroundImageDownloadTask() }
    
    /**
     Get the image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified image.
     
     - returns: Current URL for image.
     */
    @available(*, deprecated,
        message: "Extensions directly on UIButton are deprecated. Use `button.kf.webURL` instead.",
        renamed: "kf.webURL")
    public func kf_webURL(for state: UIControlState) -> URL? { return kf.webURL(for: state) }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setWebURL")
    fileprivate func kf_setWebURL(_ url: URL, for state: UIControlState) { kf.setWebURL(url, for: state) }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.webURLs")
    fileprivate var kf_webURLs: NSMutableDictionary { return kf.webURLs }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setWebURLs")
    fileprivate func kf_setWebURLs(_ URLs: NSMutableDictionary) { kf.setWebURLs(URLs) }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.imageTask")
    fileprivate var kf_imageTask: RetrieveImageTask? { return kf.imageTask }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setImageTask")
    fileprivate func kf_setImageTask(_ task: RetrieveImageTask?) { kf.setImageTask(task) }
    
    /**
     Get the background image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified background image.
     
     - returns: Current URL for background image.
     */
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.kf.backgroundWebURL` instead.",
    renamed: "kf.backgroundWebURL")
    public func kf_backgroundWebURL(for state: UIControlState) -> URL? { return kf.backgroundWebURL(for: state) }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setBackgroundWebURL")
    fileprivate func kf_setBackgroundWebURL(_ url: URL, for state: UIControlState) {
        kf.setBackgroundWebURL(url, for: state)
    }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "kf.backgroundWebURLs")
    fileprivate var kf_backgroundWebURLs: NSMutableDictionary { return kf.backgroundWebURLs }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setBackgroundWebURLs")
    fileprivate func kf_setBackgroundWebURLs(_ URLs: NSMutableDictionary) { kf.setBackgroundWebURLs(URLs) }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "kf.backgroundImageTask")
    fileprivate var kf_backgroundImageTask: RetrieveImageTask? { return kf.backgroundImageTask }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setBackgroundImageTask")
    fileprivate func kf_setBackgroundImageTask(_ task: RetrieveImageTask?) { return kf.setBackgroundImageTask(task) }
    
}
