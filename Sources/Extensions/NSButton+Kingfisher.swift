//
//  NSButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Jie Zhang on 14/04/2016.
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


import AppKit

extension KingfisherClass where Base: NSButton {
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
     
     If `resource` is `nil`, the `placeholder` image will be set and
     `completionHandler` will be called with both `error` and `image` being `nil`.
     */
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Image? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil)
        -> DownloadTask?
    {
        guard let resource = resource else {
            base.image = placeholder
            webURL = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptyResource)))
            return nil
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? .empty)
        if !options.keepCurrentImageWhileLoading {
            base.image = placeholder
        }
        
        webURL = resource.downloadURL
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL else { return }
                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    guard resource.downloadURL == self.webURL else {
                        let error = KingfisherError.imageSettingError(
                            reason: .notCurrentResource(result: result.value, error: result.error, resource: resource))
                        completionHandler?(.failure(error))
                        return
                    }
                    
                    self.imageTask = nil
                    
                    switch result {
                    case .success(let value):
                        self.base.image = value.image
                        completionHandler?(result)
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.image = image
                        }
                        completionHandler?(result)
                    }
                }
            })
        
        imageTask = task
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
     Set an alternateImage with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
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
    public func setAlternateImage(with resource: Resource?,
                                  placeholder: Image? = nil,
                                  options: KingfisherOptionsInfo? = nil,
                                  progressBlock: DownloadProgressBlock? = nil,
                                  completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil)
        -> DownloadTask?
    {
        guard let resource = resource else {
            base.alternateImage = placeholder
            alternateWebURL = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptyResource)))
            return nil
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? .empty)
        if !options.keepCurrentImageWhileLoading {
            base.alternateImage = placeholder
        }
        
        alternateWebURL = resource.downloadURL
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.alternateWebURL else { return }
                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    guard resource.downloadURL == self.alternateWebURL else {
                        let error = KingfisherError.imageSettingError(
                            reason: .notCurrentResource(result: result.value, error: result.error, resource: resource))
                        completionHandler?(.failure(error))
                        return
                    }
                    
                    self.alternateImageTask = nil
                    
                    switch result {
                    case .success(let value):
                        self.base.alternateImage = value.image
                        completionHandler?(result)
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.alternateImage = image
                        }
                        completionHandler?(result)
                    }
                }
            })
        
        alternateImageTask = task
        return task
    }
    
 
    /// Cancel the alternate image download task bounded to the image view if it is running. 
    /// Nothing will happen if the downloading has already finished.
    public func cancelAlternateImageDownloadTask() {
        alternateImageTask?.cancel()
    }
}


// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

private var lastAlternateURLKey: Void?
private var alternateImageTaskKey: Void?

extension KingfisherClass where Base: NSButton {
    public private(set) var webURL: URL? {
        get { return getAssociatedObject(base, &lastURLKey) }
        set { setRetainedAssociatedObject(base, &lastURLKey, newValue) }
    }
    
    private var imageTask: DownloadTask? {
        get { return getAssociatedObject(base, &imageTaskKey) }
        set { setRetainedAssociatedObject(base, &imageTaskKey, newValue)}
    }
    
    public private(set) var alternateWebURL: URL? {
        get { return getAssociatedObject(base, &lastAlternateURLKey) }
        set { setRetainedAssociatedObject(base, &lastAlternateURLKey, newValue) }
    }
    
    private var alternateImageTask: DownloadTask? {
        get { return getAssociatedObject(base, &alternateImageTaskKey) }
        set { setRetainedAssociatedObject(base, &alternateImageTaskKey, newValue)}
    }
}
