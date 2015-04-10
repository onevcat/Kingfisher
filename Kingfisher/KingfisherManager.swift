//
//  KingfisherManager.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

import Foundation

public class RetrieveImageTask {
    
    var diskRetriveTask: RetrieveImageDiskTask?
    var downloadTask: RetrieveImageDownloadTask?
    
    public func cancel() {
        if let diskRetriveTask = diskRetriveTask {
            dispatch_block_cancel(diskRetriveTask)
        }
        
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        }
    }
}

public let KingfisherErrorDomain = "com.onevcat.Kingfisher.Error"

public enum WebImageError: Int {
    case BadData = 10000
}

private let instance = KingfisherManager()

public class KingfisherManager {
    
    public typealias Options = (forceRefresh: Bool, lowPriority: Bool, cacheMemoryOnly: Bool, shouldDecode: Bool)
    
    public static var OptionsNone: Options = {
        return (forceRefresh: false, lowPriority: false, cacheMemoryOnly: false, shouldDecode: false)
    }()
    
    public class var sharedManager: KingfisherManager {
        return instance
    }
    
    public var cache: ImageCache
    public var downloader: ImageDownloader
    
    public init() {
        cache = ImageCache.defaultCache
        downloader = ImageDownloader.defaultDownloader
    }

    
    public func retriveImageWithURL(url: NSURL,
                                options: KingfisherOptions,
                          progressBlock:DownloadProgressBlock?,
                      completionHandler:CompletionHandler?) -> RetrieveImageTask
    {
        let task = RetrieveImageTask()
        
        let options = (forceRefresh: options & KingfisherOptions.ForceRefresh != KingfisherOptions.None,
                        lowPriority: options & KingfisherOptions.LowPriority != KingfisherOptions.None,
                    cacheMemoryOnly: options & KingfisherOptions.CacheMemoryOnly != KingfisherOptions.None,
                       shouldDecode: options & KingfisherOptions.BackgroundDecode != KingfisherOptions.None)

        if let key = url.absoluteString {
            if options.forceRefresh {
                downloadAndCacheImageWithURL(url,
                    forKey: key,
                    retrieveImageTask: task,
                    progressBlock: progressBlock,
                    completionHandler: completionHandler,
                    options: options)
            } else {
                let diskTask = cache.retrieveImageForKey(key, options: options, completionHandler: { (image, cacheType) -> () in
                    if image != nil {
                        completionHandler?(image: image, error: nil, imageURL: url)
                    } else {
                        self.downloadAndCacheImageWithURL(url,
                            forKey: key,
                            retrieveImageTask: task,
                            progressBlock: progressBlock,
                            completionHandler: completionHandler,
                            options: options)
                    }
                })
                task.diskRetriveTask = diskTask
            }
        }
        
        return task
    }
    
    func downloadAndCacheImageWithURL(url: NSURL,
                               forKey key: String,
                        retrieveImageTask: RetrieveImageTask,
                            progressBlock: DownloadProgressBlock?,
                        completionHandler: CompletionHandler?,
                                  options: Options)
    {
        downloader.downloadImageWithURL(url, retrieveImagetask: retrieveImageTask, options: options, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlock?(receivedSize: receivedSize, totalSize: totalSize)
            return
        }) { (image, error, imageURL) -> () in
            completionHandler?(image: image, error: error, imageURL: url)
            if let image = image {
                self.cache.storeImage(image, forKey: key, toDisk: !options.cacheMemoryOnly, completionHandler: nil)
            }
        }
    }
}