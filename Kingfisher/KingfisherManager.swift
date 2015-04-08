//
//  KingfisherManager.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

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
                let diskTask = cache.retrieveImageForKey(key, completionHandler: { (image, cacheType) -> () in
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