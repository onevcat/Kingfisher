//
//  WKInterfaceImage+Kingfisher.swift
//  Kingfisher
//
//  Created by Rodrigo Borges Soares on 04/05/18.
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

import WatchKit

// MARK: - Extension methods.
/**
 *    Set image to use from web.
 */
extension Kingfisher where Base: WKInterfaceImage {
    /**
     Set an image with a resource.

     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.

     - returns: A task represents the retrieving process.
     */
    @discardableResult
    public func setImage(_ resource: Resource?,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask {
        guard let resource = resource else {
            setWebURL(nil)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }

        setWebURL(resource.downloadURL)

        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo),
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL else {
                    return
                }

                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { [weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.webURL else {
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }

                    self.setImageTask(nil)
                    guard let image = image else {
                        completionHandler?(nil, error, cacheType, imageURL)
                        return
                    }
                
                    strongBase.setImage(image)
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
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension Kingfisher where Base: WKInterfaceImage {
    /// Get the image URL binded to this image view.
    public var webURL: URL? {
        return objc_getAssociatedObject(base, &lastURLKey) as? URL
    }

    fileprivate func setWebURL(_ url: URL?) {
        objc_setAssociatedObject(base, &lastURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }

    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

