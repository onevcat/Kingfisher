//
//  UIButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/13.
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

#if os(iOS) || os(tvOS)

import UIKit

/**
*	Set image to use from web for a specified state.
*/
extension UIButton {

    /**
    Set an image to use for a specified state with a resource.
    It will ask for Kingfisher's manager to get the image for the `cacheKey` property in `resource` and then set it for a button state.
    The memory and disk will be searched first. If the manager does not find it, it will try to download the image at the `resource.downloadURL` and store it with `resource.cacheKey` for next use.
    
    - parameter resource: Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:    The state that uses the specified image.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                  forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, forState: state, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image to use for a specified state with a URL.
    It will ask for Kingfisher's manager to get the image for the URL and then set it for a button state.
    The memory and disk will be searched first with `URL.absoluteString` as the cache key. If the manager does not find it, it will try to download the image at this URL and store the image with `URL.absoluteString` as cache key for next use.
    
    If you need to specify the key other than `URL.absoluteString`, please use resource version of these APIs with `resource.cacheKey` set to what you want.
    
    - parameter URL:   The URL of image for specified state.
    - parameter state: The state that uses the specified image.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set an image to use for a specified state with a resource and a placeholder image.
    
    - parameter resource:         Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, forState: state, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image to use for a specified state with a URL and a placeholder image.
    
    - parameter URL:              The URL of image for specified state.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set an image to use for a specified state with a resource, a placeholder image and options.
    
    - parameter resource:         Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image to use for a specified state with a URL, a placeholder image and options.
    
    - parameter URL:              The URL of image for specified state.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set an image to use for a specified state with a resource, a placeholder image, options and completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setImageWithResource(resource: Resource,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set an image to use for a specified state with a URL, a placeholder image, options and completion handler.
    
    - parameter URL:               The URL of image for specified state.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }

    
    /**
    Set an image to use for a specified state with a resource, a placeholder image, options, progress handler and completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setImageWithResource(resource: Resource,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                                   progressBlock: DownloadProgressBlock?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        setImage(placeholderImage, forState: state)
        kf_setWebURL(resource.downloadURL, forState: state)
        let task = KingfisherManager.sharedManager.retrieveImageWithResource(resource, optionsInfo: optionsInfo,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                }
            },
            completionHandler: {[weak self] image, error, cacheType, imageURL in
                dispatch_async_safely_to_main_queue {
                    if let sSelf = self {
                        
                        sSelf.kf_setImageTask(nil)
                        
                        if imageURL == sSelf.kf_webURLForState(state) && image != nil {
                            sSelf.setImage(image, forState: state)
                        }
                        completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
                    }
                }
            })
        
        kf_setImageTask(task)
        return task
    }
    
    /**
    Set an image to use for a specified state with a URL, a placeholder image, options, progress handler and completion handler.
    
    - parameter URL:               The URL of image for specified state.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(Resource(downloadURL: URL),
                                forState: state,
                        placeholderImage: placeholderImage,
                             optionsInfo: optionsInfo,
                           progressBlock: progressBlock,
                       completionHandler: completionHandler)
    }
}

private var lastURLKey: Void?
private var imageTaskKey: Void?

// MARK: - Runtime for UIButton image
extension UIButton {
    /**
    Get the image URL binded to this button for a specified state. 
    
    - parameter state: The state that uses the specified image.
    
    - returns: Current URL for image.
    */
    public func kf_webURLForState(state: UIControlState) -> NSURL? {
        return kf_webURLs[NSNumber(unsignedLong:state.rawValue)] as? NSURL
    }
    
    private func kf_setWebURL(URL: NSURL, forState state: UIControlState) {
        kf_webURLs[NSNumber(unsignedLong:state.rawValue)] = URL
    }
    
    private var kf_webURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(self, &lastURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            kf_setWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    private func kf_setWebURLs(URLs: NSMutableDictionary) {
        objc_setAssociatedObject(self, &lastURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private var kf_imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? RetrieveImageTask
    }
    
    private func kf_setImageTask(task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/**
*	Set background image to use from web for a specified state.
*/
extension UIButton {
    /**
    Set the background image to use for a specified state with a resource.
    It will ask for Kingfisher's manager to get the image for the `cacheKey` property in `resource` and then set it for a button state.
    The memory and disk will be searched first. If the manager does not find it, it will try to download the image at the `resource.downloadURL` and store it with `resource.cacheKey` for next use.
    
    - parameter resource: Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:    The state that uses the specified image.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setBackgroundImageWithResource(resource: Resource,
                                            forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithResource(resource, forState: state, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set the background image to use for a specified state with a URL.
    It will ask for Kingfisher's manager to get the image for the URL and then set it for a button state.
    The memory and disk will be searched first with `URL.absoluteString` as the cache key. If the manager does not find it, it will try to download the image at this URL and store the image with `URL.absoluteString` as cache key for next use.
    
    If you need to specify the key other than `URL.absoluteString`, please use resource version of these APIs with `resource.cacheKey` set to what you want.
    
    - parameter URL:   The URL of image for specified state.
    - parameter state: The state that uses the specified image.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set the background image to use for a specified state with a resource and a placeholder image.
    
    - parameter resource:         Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setBackgroundImageWithResource(resource: Resource,
                                            forState state: UIControlState,
                                          placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithResource(resource, forState: state, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set the background image to use for a specified state with a URL and a placeholder image.
    
    - parameter URL:              The URL of image for specified state.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set the background image to use for a specified state with a resource, a placeholder image and options.
    
    - parameter resource:         Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setBackgroundImageWithResource(resource: Resource,
                                            forState state: UIControlState,
                                          placeholderImage: UIImage?,
                                               optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithResource(resource, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set the background image to use for a specified state with a URL, a placeholder image and options.
    
    - parameter URL:              The URL of image for specified state.
    - parameter state:            The state that uses the specified image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set the background image to use for a specified state with a resource, a placeholder image, options and completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setBackgroundImageWithResource(resource: Resource,
                                            forState state: UIControlState,
                                          placeholderImage: UIImage?,
                                               optionsInfo: KingfisherOptionsInfo?,
                                         completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithResource(resource, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set the background image to use for a specified state with a URL, a placeholder image, options and completion handler.
    
    - parameter URL:               The URL of image for specified state.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }

    /**
    Set the background image to use for a specified state with a resource,
    a placeholder image, options progress handler and completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setBackgroundImageWithResource(resource: Resource,
                                            forState state: UIControlState,
                                          placeholderImage: UIImage?,
                                               optionsInfo: KingfisherOptionsInfo?,
                                             progressBlock: DownloadProgressBlock?,
                                         completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        setBackgroundImage(placeholderImage, forState: state)
        kf_setBackgroundWebURL(resource.downloadURL, forState: state)
        let task = KingfisherManager.sharedManager.retrieveImageWithResource(resource, optionsInfo: optionsInfo,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                }
            },
            completionHandler: { [weak self] image, error, cacheType, imageURL in
                dispatch_async_safely_to_main_queue {
                    if let sSelf = self {
                        
                        sSelf.kf_setBackgroundImageTask(nil)
                        
                        if imageURL == sSelf.kf_backgroundWebURLForState(state) && image != nil {
                            sSelf.setBackgroundImage(image, forState: state)
                        }
                        completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
                    }
                }
            })
        
        kf_setBackgroundImageTask(task)
        return task
    }
    
    /**
    Set the background image to use for a specified state with a URL,
    a placeholder image, options progress handler and completion handler.
    
    - parameter URL:               The URL of image for specified state.
    - parameter state:             The state that uses the specified image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                                   progressBlock: DownloadProgressBlock?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithResource(Resource(downloadURL: URL),
                                        forState: state,
                                placeholderImage: placeholderImage,
                                     optionsInfo: optionsInfo,
                                   progressBlock: progressBlock,
                               completionHandler: completionHandler)
    }
}

private var lastBackgroundURLKey: Void?
private var backgroundImageTaskKey: Void?
    
// MARK: - Runtime for UIButton background image
extension UIButton {
    /**
    Get the background image URL binded to this button for a specified state.
    
    - parameter state: The state that uses the specified background image.
    
    - returns: Current URL for background image.
    */
    public func kf_backgroundWebURLForState(state: UIControlState) -> NSURL? {
        return kf_backgroundWebURLs[NSNumber(unsignedLong:state.rawValue)] as? NSURL
    }
    
    private func kf_setBackgroundWebURL(URL: NSURL, forState state: UIControlState) {
        kf_backgroundWebURLs[NSNumber(unsignedLong:state.rawValue)] = URL
    }
    
    private var kf_backgroundWebURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(self, &lastBackgroundURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            kf_setBackgroundWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    private func kf_setBackgroundWebURLs(URLs: NSMutableDictionary) {
        objc_setAssociatedObject(self, &lastBackgroundURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private var kf_backgroundImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &backgroundImageTaskKey) as? RetrieveImageTask
    }
    
    private func kf_setBackgroundImageTask(task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &backgroundImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Cancel image download tasks.
extension UIButton {
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func kf_cancelImageDownloadTask() {
        kf_imageTask?.downloadTask?.cancel()
    }
    
    /**
     Cancel the background image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func kf_cancelBackgroundImageDownloadTask() {
        kf_backgroundImageTask?.downloadTask?.cancel()
    }
}
    
#elseif os(OSX)

import AppKit
extension NSButton {
    // Not Implemented yet.
}
    
#endif
