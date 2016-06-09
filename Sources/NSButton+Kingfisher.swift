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
     Set an image with a URL, a placeholder image, options, progress handler and completion handler.

     - parameter URL:               The URL of image.
     - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
     - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.

     - returns: A task represents the retrieving process.

     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */

    public func kf_setImageWithURL(URL: NSURL?,
                                   placeholderImage: Image? = nil,
                                   optionsInfo: KingfisherOptionsInfo? = nil,
                                   progressBlock: DownloadProgressBlock? = nil,
                                   completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        let resource = URL.map { Resource(downloadURL: $0) }
        return kf_setImageWithResource(resource,
                                       placeholderImage: placeholderImage,
                                       optionsInfo: optionsInfo,
                                       progressBlock: progressBlock,
                                       completionHandler: completionHandler)
    }


    /**
     Set an image with a URL, a placeholder image, options, progress handler and completion handler.

     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
     - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.

     - returns: A task represents the retrieving process.

     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    public func kf_setImageWithResource(resource: Resource?,
                                        placeholderImage: Image? = nil,
                                        optionsInfo: KingfisherOptionsInfo? = nil,
                                        progressBlock: DownloadProgressBlock? = nil,
                                        completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        image = placeholderImage
        
        guard let resource = resource else {
            completionHandler?(image: nil, error: nil, cacheType: .None, imageURL: nil)
            return RetrieveImageTask.emptyTask
        }
        
        kf_setWebURL(resource.downloadURL)
        let task = KingfisherManager.sharedManager.retrieveImageWithResource(resource, optionsInfo: optionsInfo,
             progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                }
            },
             completionHandler: {[weak self] image, error, cacheType, imageURL in
                dispatch_async_safely_to_main_queue {
                    guard let sSelf = self where imageURL == sSelf.kf_webURL else {
                        return
                    }

                    sSelf.kf_setImageTask(nil)

                    if image != nil {
                        sSelf.image = image
                    }
                    
                    completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
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
    public var kf_webURL: NSURL? {
        return objc_getAssociatedObject(self, &lastURLKey) as? NSURL
    }

    private func kf_setWebURL(URL: NSURL) {
        objc_setAssociatedObject(self, &lastURLKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private var kf_imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? RetrieveImageTask
    }
    
    private func kf_setImageTask(task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/**
 *	Set alternate image to use from web.
 */
extension NSButton {

    /**
     Set an alternateImage with a URL, a placeholder image, options, progress handler and completion handler.

     - parameter URL:               The URL of image.
     - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
     - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.

     - returns: A task represents the retrieving process.

     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */

    public func kf_setAlternateImageWithURL(URL: NSURL?,
                                            placeholderImage: Image? = nil,
                                            optionsInfo: KingfisherOptionsInfo? = nil,
                                            progressBlock: DownloadProgressBlock? = nil,
                                            completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        let resource = URL.map { Resource(downloadURL: $0) }
        return kf_setAlternateImageWithResource(resource,
                                                placeholderImage: placeholderImage,
                                                optionsInfo: optionsInfo,
                                                progressBlock: progressBlock,
                                                completionHandler: completionHandler)
    }


    /**
     Set an alternateImage with a URL, a placeholder image, options, progress handler and completion handler.

     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
     - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.

     - returns: A task represents the retrieving process.

     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    public func kf_setAlternateImageWithResource(resource: Resource?,
                                                 placeholderImage: Image? = nil,
                                                 optionsInfo: KingfisherOptionsInfo? = nil,
                                                 progressBlock: DownloadProgressBlock? = nil,
                                                 completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        alternateImage = placeholderImage
        
        guard let resource = resource else {
            completionHandler?(image: nil, error: nil, cacheType: .None, imageURL: nil)
            return RetrieveImageTask.emptyTask
        }
        
        kf_setAlternateWebURL(resource.downloadURL)
        let task = KingfisherManager.sharedManager.retrieveImageWithResource(resource, optionsInfo: optionsInfo,
             progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                }
            },
             completionHandler: {[weak self] image, error, cacheType, imageURL in
                dispatch_async_safely_to_main_queue {
                    guard let sSelf = self where imageURL == sSelf.kf_alternateWebURL else {
                        return
                    }
                    
                    sSelf.kf_setAlternateImageTask(nil)
                    
                    guard let image = image else {
                        completionHandler?(image: nil, error: error, cacheType: cacheType, imageURL: imageURL)
                        return
                    }
                    
                    sSelf.alternateImage = image
                    completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
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

    public var kf_alternateWebURL: NSURL? {
        return objc_getAssociatedObject(self, &lastAlternateURLKey) as? NSURL
    }

    private func kf_setAlternateWebURL(URL: NSURL) {
        objc_setAssociatedObject(self, &lastAlternateURLKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private var kf_alternateImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &alternateImageTaskKey) as? RetrieveImageTask
    }

    private func kf_setAlternateImageTask(task: RetrieveImageTask?) {
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
