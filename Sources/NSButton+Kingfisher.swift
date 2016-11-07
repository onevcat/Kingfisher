//
//  NSButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Jie Zhang on 14/04/2016.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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


import AppKit

// MARK: - Set Images
/**
 *	Set image to use from web.
 */
extension Kingfisher where Base: NSButton {
    /**
     Set an image with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Image? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = options ?? KingfisherEmptyOptionsInfo
        if !options.keepCurrentImageWhileLoading {
            base.image = placeholder
        }
        
        setWebURL(resource.downloadURL)
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: {[weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.webURL else {
                        return
                    }
                    self.setImageTask(nil)
                    if image != nil {
                        strongBase.image = image
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
        imageTask?.downloadTask?.cancel()
    }
    
    /**
     Set an alternateImage with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    @discardableResult
    public func setAlternateImage(with resource: Resource?,
                                  placeholder: Image? = nil,
                                  options: KingfisherOptionsInfo? = nil,
                                  progressBlock: DownloadProgressBlock? = nil,
                                  completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = options ?? KingfisherEmptyOptionsInfo
        if !options.keepCurrentImageWhileLoading {
            base.alternateImage = placeholder
        }
        
        setAlternateWebURL(resource.downloadURL)
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: {[weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.alternateWebURL else {
                        return
                    }
                    self.setAlternateImageTask(nil)
                    
                    guard let image = image else {
                        completionHandler?(nil, error, cacheType, imageURL)
                        return
                    }
                    
                    strongBase.alternateImage = image
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        setAlternateImageTask(task)
        return task
    }
    
 
    /// Cancel the alternate image download task bounded to the image view if it is running. 
    /// Nothing will happen if the downloading has already finished.
    public func cancelAlternateImageDownloadTask() {
        alternateImageTask?.downloadTask?.cancel()
    }
}


// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

private var lastAlternateURLKey: Void?
private var alternateImageTaskKey: Void?

extension Kingfisher where Base: NSButton {
    /// Get the image URL binded to this image view.
    public var webURL: URL? {
        return objc_getAssociatedObject(base, &lastURLKey) as? URL
    }
    
    fileprivate func setWebURL(_ url: URL) {
        objc_setAssociatedObject(base, &lastURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Get the alternate image URL binded to this button.
    public var alternateWebURL: URL? {
        return objc_getAssociatedObject(base, &lastAlternateURLKey) as? URL
    }
    
    fileprivate func setAlternateWebURL(_ url: URL) {
        objc_setAssociatedObject(base, &lastAlternateURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var alternateImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &alternateImageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setAlternateImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &alternateImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


// MARK: - Deprecated. Only for back compatibility.
/**
 *	Set image to use from web. Deprecated. Use `kf` namespacing instead.
 */
extension NSButton {
    /**
     Set an image with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
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
    message: "Extensions directly on NSButton are deprecated. Use `button.kf.setImage` instead.",
    renamed: "kf.setImage")
    public func kf_setImage(with resource: Resource?,
                            placeholder: Image? = nil,
                            options: KingfisherOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                            completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return kf.setImage(with: resource, placeholder: placeholder, options: options,
                           progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    @available(*, deprecated,
    message: "Extensions directly on NSButton are deprecated. Use `button.kf.cancelImageDownloadTask` instead.",
    renamed: "kf.cancelImageDownloadTask")
    public func kf_cancelImageDownloadTask() { kf.cancelImageDownloadTask() }
    
    /**
     Set an alternateImage with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
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
    message: "Extensions directly on NSButton are deprecated. Use `button.kf.setAlternateImage` instead.",
    renamed: "kf.setAlternateImage")
    public func kf_setAlternateImage(with resource: Resource?,
                                     placeholder: Image? = nil,
                                     options: KingfisherOptionsInfo? = nil,
                                     progressBlock: DownloadProgressBlock? = nil,
                                     completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return kf.setAlternateImage(with: resource, placeholder: placeholder, options: options,
                                    progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /// Cancel the alternate image download task bounded to the image view if it is running.
    /// Nothing will happen if the downloading has already finished.
    @available(*, deprecated,
    message: "Extensions directly on NSButton are deprecated. Use `button.kf.cancelAlternateImageDownloadTask` instead.",
    renamed: "kf.cancelAlternateImageDownloadTask")
    public func kf_cancelAlternateImageDownloadTask() { kf.cancelAlternateImageDownloadTask() }
    
    
    /// Get the image URL binded to this image view.
    @available(*, deprecated,
    message: "Extensions directly on NSButton are deprecated. Use `button.kf.webURL` instead.",
    renamed: "kf.webURL")
    public var kf_webURL: URL? { return kf.webURL }
    
    @available(*, deprecated, message: "Extensions directly on NSButton are deprecated.",renamed: "kf.setWebURL")
    fileprivate func kf_setWebURL(_ url: URL) { kf.setWebURL(url) }
    
    @available(*, deprecated, message: "Extensions directly on NSButton are deprecated.",renamed: "kf.imageTask")
    fileprivate var kf_imageTask: RetrieveImageTask? { return kf.imageTask }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setImageTask")
    fileprivate func kf_setImageTask(_ task: RetrieveImageTask?) { kf.setImageTask(task)}
    
    /// Get the alternate image URL binded to this button.
    @available(*, deprecated,
    message: "Extensions directly on NSButton are deprecated. Use `button.kf.alternateWebURL` instead.",
    renamed: "kf.alternateWebURL")
    public var kf_alternateWebURL: URL? { return kf.alternateWebURL }
    
    @available(*, deprecated, message: "Extensions directly on NSButton are deprecated.",renamed: "kf.setAlternateWebURL")
    fileprivate func kf_setAlternateWebURL(_ url: URL) { kf.setAlternateWebURL(url) }
    
    @available(*, deprecated, message: "Extensions directly on NSButton are deprecated.",renamed: "kf.alternateImageTask")
    fileprivate var kf_alternateImageTask: RetrieveImageTask? { return kf.alternateImageTask }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "kf.setAlternateImageTask")
    fileprivate func kf_setAlternateImageTask(_ task: RetrieveImageTask?) { kf.setAlternateImageTask(task) }
}

