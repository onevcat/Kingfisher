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
    public func kf_setImage(with resource: Resource?,
                              placeholder: Image? = nil,
                                  options: KingfisherOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                        completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        image = placeholder
        
        guard let resource = resource else {
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        kf_setWebURL(resource.downloadURL)
        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options,
             progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
             completionHandler: {[weak self] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let sSelf = self, imageURL == sSelf.kf_webURL else {
                        return
                    }

                    sSelf.kf_setImageTask(nil)

                    if image != nil {
                        sSelf.image = image
                    }
                    
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })

        kf_setImageTask(task)
        return task
    }

}


// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension NSButton {
    /// Get the image URL binded to this image view.
    public var kf_webURL: URL? {
        return objc_getAssociatedObject(self, &lastURLKey) as? URL
    }

    fileprivate func kf_setWebURL(_ url: URL) {
        objc_setAssociatedObject(self, &lastURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    fileprivate var kf_imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func kf_setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/**
 *	Set alternate image to use from web.
 */
extension NSButton {

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
    public func kf_setAlternateImage(with resource: Resource?,
                                       placeholder: Image? = nil,
                                           options: KingfisherOptionsInfo? = nil,
                                     progressBlock: DownloadProgressBlock? = nil,
                                 completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        alternateImage = placeholder
        
        guard let resource = resource else {
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        kf_setAlternateWebURL(resource.downloadURL)
        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options,
             progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
             completionHandler: {[weak self] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let sSelf = self, imageURL == sSelf.kf_alternateWebURL else {
                        return
                    }
                    
                    sSelf.kf_setAlternateImageTask(nil)
                    
                    guard let image = image else {
                        completionHandler?(nil, error, cacheType, imageURL)
                        return
                    }
                    
                    sSelf.alternateImage = image
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        kf_setImageTask(task)
        return task
    }
}

private var lastAlternateURLKey: Void?
private var alternateImageTaskKey: Void?

// MARK: - Runtime for NSButton alternateImage
extension NSButton {
    /**
     Get the alternate image URL binded to this button.
     */

    public var kf_alternateWebURL: URL? {
        return objc_getAssociatedObject(self, &lastAlternateURLKey) as? URL
    }

    fileprivate func kf_setAlternateWebURL(_ url: URL) {
        objc_setAssociatedObject(self, &lastAlternateURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    fileprivate var kf_alternateImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &alternateImageTaskKey) as? RetrieveImageTask
    }

    fileprivate func kf_setAlternateImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &alternateImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


// MARK: - Cancel image download tasks.
extension NSButton {
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func kf_cancelImageDownloadTask() {
        kf_imageTask?.downloadTask?.cancel()
    }

    public func kf_cancelAlternateImageDownloadTask() {
        kf_imageTask?.downloadTask?.cancel()
    }
}
