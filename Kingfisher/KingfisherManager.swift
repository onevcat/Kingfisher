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


/**
*  RetrieveImageTask represents a task of image retrieving process.
*  It contains an async task of getting image from disk and from network.
*/
public class RetrieveImageTask {
    
    var diskRetrieveTask: RetrieveImageDiskTask?
    var downloadTask: RetrieveImageDownloadTask?
    
    /**
    Cancel current task. If this task does not begin or already done, do nothing.
    */
    public func cancel() {
        if let diskRetrieveTask = diskRetrieveTask {
            dispatch_block_cancel(diskRetrieveTask)
        }
        
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        }
    }
}

public let KingfisherErrorDomain = "com.onevcat.Kingfisher.Error"


private let instance = KingfisherManager()

/**
*  Main manager class of Kingfisher
*/
public class KingfisherManager {

    /**
    *	Options to control some downloader and cache behaviors.
    */
    public typealias Options = (forceRefresh: Bool, lowPriority: Bool, cacheMemoryOnly: Bool, shouldDecode: Bool)
    
    /// A preset option tuple with all value set to `false`.
    public static var OptionsNone: Options = {
        return (forceRefresh: false, lowPriority: false, cacheMemoryOnly: false, shouldDecode: false)
    }()
    
    /// Shared manager used by the extensions across Kingfisher.
    public class var sharedManager: KingfisherManager {
        return instance
    }
    
    /// Cache used by this manager
    public var cache: ImageCache
    
    /// Downloader used by this manager
    public var downloader: ImageDownloader
    
    /**
    Default init method
    
    :returns: A Kingfisher manager object with default cache and default downloader.
    */
    public init() {
        cache = ImageCache.defaultCache
        downloader = ImageDownloader.defaultDownloader
    }

    /**
    Get an image with URL as the key.
    If KingfisherOptions.None is used as `options`, Kingfisher will seek the image in memory and disk first.
    If not found, it will download the image at URL and cache it.
    These default behaviors could be adjusted by passing different options. See `KingfisherOptions` for more.
    
    :param: URL               The image URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: progressBlock     Called every time downloaded data changed. This could be used as a progress UI.
    :param: completionHandler Called when the whole retriving process finished.
    
    :returns: A `RetrieveImageTask` task object. You can use this object to cancel the task.
    */
    public func retrieveImageWithURL(URL: NSURL,
                             optionsInfo: KingfisherOptionsInfo?,
                           progressBlock: DownloadProgressBlock?,
                       completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        func parseOptionsInfo(optionsInfo: KingfisherOptionsInfo?) -> (Options, ImageCache, ImageDownloader) {
            let options: Options
            if let optionsInOptionsInfo = optionsInfo?[.Options] as? KingfisherOptions {
                options = (forceRefresh: (optionsInOptionsInfo & KingfisherOptions.ForceRefresh) != KingfisherOptions.None,
                    lowPriority: (optionsInOptionsInfo & KingfisherOptions.LowPriority) != KingfisherOptions.None,
                    cacheMemoryOnly: (optionsInOptionsInfo & KingfisherOptions.CacheMemoryOnly) != KingfisherOptions.None,
                    shouldDecode: (optionsInOptionsInfo & KingfisherOptions.BackgroundDecode) != KingfisherOptions.None)
            } else {
                options = (forceRefresh: false,
                    lowPriority: false,
                    cacheMemoryOnly: false,
                    shouldDecode: false)
            }
            
            let targetCache = optionsInfo?[.TargetCache] as? ImageCache ?? self.cache
            let usedDownloader = optionsInfo?[.Downloader] as? ImageDownloader ?? self.downloader
            
            return (options, targetCache, usedDownloader)
        }
        
        let task = RetrieveImageTask()
        
        // There is a bug in Swift compiler which prevents to write `let (options, targetCache) = parseOptionsInfo(optionsInfo)`
        // It will cause a compiler error.
        let parsedOptions = parseOptionsInfo(optionsInfo)
        let (options, targetCache, downloader) = (parsedOptions.0, parsedOptions.1, parsedOptions.2)
        
        if let key = URL.absoluteString {
            if options.forceRefresh {
                downloadAndCacheImageWithURL(URL,
                    forKey: key,
                    retrieveImageTask: task,
                    progressBlock: progressBlock,
                    completionHandler: completionHandler,
                    options: options,
                    targetCache: targetCache,
                    downloader: downloader)
            } else {
                let diskTask = targetCache.retrieveImageForKey(key, options: options, completionHandler: { (image, cacheType) -> () in
                    if image != nil {
                        completionHandler?(image: image, error: nil, cacheType:cacheType, imageURL: URL)
                    } else {
                        self.downloadAndCacheImageWithURL(URL,
                            forKey: key,
                            retrieveImageTask: task,
                            progressBlock: progressBlock,
                            completionHandler: completionHandler,
                            options: options,
                            targetCache: targetCache,
                            downloader: downloader)
                    }
                })
                task.diskRetrieveTask = diskTask
            }
        }
        
        return task
    }
    
    func downloadAndCacheImageWithURL(URL: NSURL,
                               forKey key: String,
                        retrieveImageTask: RetrieveImageTask,
                            progressBlock: DownloadProgressBlock?,
                        completionHandler: CompletionHandler?,
                                  options: Options,
                              targetCache: ImageCache,
                               downloader: ImageDownloader)
    {
        downloader.downloadImageWithURL(URL, retrieveImageTask: retrieveImageTask, options: options, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlock?(receivedSize: receivedSize, totalSize: totalSize)
            return
        }) { (image, error, imageURL) -> () in

            if let error = error where error.code == KingfisherError.NotModified.rawValue {
                // Not modified. Try to find the image from cache. 
                // (The image should be in cache. It should be ensured by the framework users.)
                targetCache.retrieveImageForKey(key, options: options, completionHandler: { (cacheImage, cacheType) -> () in
                    completionHandler?(image: cacheImage, error: nil, cacheType: cacheType, imageURL: URL)

                })
                return
            }
            
            if let image = image {
                targetCache.storeImage(image, forKey: key, toDisk: !options.cacheMemoryOnly, completionHandler: nil)
            }
            
            completionHandler?(image: image, error: error, cacheType: .None, imageURL: URL)
        }
    }
}

// MARK: - Deprecated
public extension KingfisherManager {
    @availability(*, deprecated=1.2, message="Use -retrieveImageWithURL:optionsInfo:progressBlock:completionHandler: instead.")
    public func retrieveImageWithURL(URL: NSURL,
                                 options: KingfisherOptions,
                           progressBlock: DownloadProgressBlock?,
                       completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return retrieveImageWithURL(URL, optionsInfo: [.Options : options], progressBlock: progressBlock, completionHandler: completionHandler)
    }
}
