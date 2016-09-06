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

import UIKit

/**
*	Set image to use from web for a specified state.
*/
extension UIButton {
    /**
    Set an image to use for a specified state with a resource, a placeholder image, options, progress handler and completion handler.
    
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
    public func kf_setImage(with resource: Resource?,
                                for state: UIControlState,
                              placeholder: UIImage? = nil,
                                  options: KingfisherOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                        completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        setImage(placeholder, for: state)
        
        guard let resource = resource else {
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        kf_setWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: {[weak self] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let sSelf = self, imageURL == sSelf.kf_webURL(for: state) else {
                        return
                    }
                    
                    sSelf.kf_setImageTask(nil)
                    
                    if image != nil {
                        sSelf.setImage(image, for: state)
                    }
                    
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        kf_setImageTask(task)
        return task
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
    public func kf_webURL(for state: UIControlState) -> URL? {
        return kf_webURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func kf_setWebURL(_ url: URL, for state: UIControlState) {
        kf_webURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var kf_webURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(self, &lastURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            kf_setWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func kf_setWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(self, &lastURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var kf_imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func kf_setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/**
*	Set background image to use from web for a specified state.
*/
extension UIButton {
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
    public func kf_setBackgroundImage(with resource: Resource?,
                                          for state: UIControlState,
                                        placeholder: UIImage? = nil,
                                            options: KingfisherOptionsInfo? = nil,
                                      progressBlock: DownloadProgressBlock? = nil,
                                  completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        setBackgroundImage(placeholder, for: state)
        
        guard let resource = resource else {
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        kf_setBackgroundWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: { [weak self] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let sSelf = self, imageURL == sSelf.kf_backgroundWebURL(for: state) else {
                        return
                    }
                    
                    sSelf.kf_setBackgroundImageTask(nil)
                        
                    if image != nil {
                        sSelf.setBackgroundImage(image, for: state)
                    }
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        kf_setBackgroundImageTask(task)
        return task
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
    public func kf_backgroundWebURL(for state: UIControlState) -> URL? {
        return kf_backgroundWebURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func kf_setBackgroundWebURL(_ url: URL, for state: UIControlState) {
        kf_backgroundWebURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var kf_backgroundWebURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(self, &lastBackgroundURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            kf_setBackgroundWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func kf_setBackgroundWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(self, &lastBackgroundURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var kf_backgroundImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(self, &backgroundImageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func kf_setBackgroundImageTask(_ task: RetrieveImageTask?) {
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
