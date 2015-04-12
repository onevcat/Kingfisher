//
//  ImageCache.swift
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

private let defaultCacheName = "default"
private let cacheReverseDNS = "com.onevcat.Kingfisher.ImageCache."
private let ioQueueName = "com.onevcat.Kingfisher.ImageCache.ioQueue"
private let processQueueName = "com.onevcat.Kingfisher.ImageCache.processQueue"

private let defaultCacheInstance = ImageCache(name: defaultCacheName)
private let defaultMaxCachePeriodInSecond: NSTimeInterval = 60 * 60 * 24 * 7 //Cache exists for 1 week

public typealias RetrieveImageDiskTask = dispatch_block_t

/**
Cache type of a cached image.

- Memory: The image is cached in memory.
- Disk:   The image is cached in disk.
*/
public enum CacheType {
    case Memory, Disk
}

public class ImageCache {

    //Memory
    private let memoryCache = NSCache()
    
    /// The largest cache cost of memory cache. The total cost is pixel count of all cached images in memory.
    public var maxMemoryCost: UInt = 0 {
        didSet {
            self.memoryCache.totalCostLimit = Int(maxMemoryCost)
        }
    }
    
    //Disk
    private let ioQueue = dispatch_queue_create(ioQueueName, DISPATCH_QUEUE_SERIAL)
    private let diskCachePath: String
    private var fileManager: NSFileManager!
    
    /// The longest time duration of the cache being stored in disk. Default is 1 week.
    public var maxCachePeriodInSecond = defaultMaxCachePeriodInSecond
    
    /// The largest disk size can be taken for the cache. It is the total allocated size of the file in bytes. Default is 0, which means no limit.
    public var maxDiskCacheSize: UInt = 0
    
    private let processQueue = dispatch_queue_create(processQueueName, DISPATCH_QUEUE_CONCURRENT)
    
    /// The default cache.
    public class var defaultCache: ImageCache {
        return defaultCacheInstance
    }
    
    /**
    Init method. Passing a name for the cache. It represents a cache folder in the memory and disk.
    
    :param: name Name of the cache.
    
    :returns: The cache object.
    */
    public init(name: String) {
        let cacheName = cacheReverseDNS + name
        memoryCache.name = cacheName
        
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        diskCachePath = paths.first!.stringByAppendingPathComponent(cacheName)
        
        dispatch_sync(ioQueue, { () -> Void in
            self.fileManager = NSFileManager()
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearMemoryCache", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanExpiredDiskCache", name: UIApplicationWillTerminateNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgroundCleanExpiredDiskCache", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

// MARK: - Store & Remove
public extension ImageCache {
    /**
    Store an image to cache. It will be saved to both memory and disk. 
    It is an async operation, if you need to do something about the stored image, use `-storeImage:forKey:toDisk:completionHandler:` 
    instead.
    
    :param: image The image will be stored.
    :param: key   Key for the image.
    */
    public func storeImage(image: UIImage, forKey key: String) {
        storeImage(image, forKey: key, toDisk: true, completionHandler: nil)
    }
    
    /**
    Store an image to cache. It is an async operation.
    
    :param: image             The image will be stored.
    :param: key               Key for the image.
    :param: toDisk            Whether this image should be cached to disk or not. If false, the image will be only cached in memory.
    :param: completionHandler Called when stroe operation completes.
    */
    public func storeImage(image: UIImage, forKey key: String, toDisk: Bool, completionHandler: (() -> ())?) {
        memoryCache.setObject(image, forKey: key, cost: image.kf_imageCost)
        
        if toDisk {
            dispatch_async(ioQueue, { () -> Void in
                if let data = UIImagePNGRepresentation(image) {
                    if !self.fileManager.fileExistsAtPath(self.diskCachePath) {
                        self.fileManager.createDirectoryAtPath(self.diskCachePath, withIntermediateDirectories: true, attributes: nil, error: nil)
                    }
                    
                    self.fileManager.createFileAtPath(self.cachePathForKey(key), contents: data, attributes: nil)
                    
                    if let handler = completionHandler {
                        dispatch_async(dispatch_get_main_queue()) {
                            handler()
                        }
                    }
                    
                } else {
                    if let handler = completionHandler {
                        dispatch_async(dispatch_get_main_queue()) {
                            handler()
                        }
                    }
                }
            })
        } else {
            if let handler = completionHandler {
                handler()
            }
        }
    }
    
    /**
    Remove the image for key for the cache. It will be opted out from both memory and disk.
    It is an async operation, if you need to do something about the stored image, use `-removeImageForKey:fromDisk:completionHandler:` 
    instead.
    
    :param: key Key for the image.
    */
    public func removeImageForKey(key: String) {
        removeImageForKey(key, fromDisk: true, completionHandler: nil)
    }
    
    /**
    Remove the image for key for the cache. It is an async operation.
    
    :param: key               Key for the image.
    :param: fromDisk          Whether this image should be removed from disk or not. If false, the image will be only removed from memory.
    :param: completionHandler Called when removal operation completes.
    */
    public func removeImageForKey(key: String, fromDisk: Bool, completionHandler: (() -> ())?) {
        memoryCache.removeObjectForKey(key)
        
        if fromDisk {
            dispatch_async(ioQueue, { () -> Void in
                self.fileManager.removeItemAtPath(self.cachePathForKey(key), error: nil)
                if let handler = completionHandler {
                    dispatch_async(dispatch_get_main_queue()) {
                        handler()
                    }
                }
            })
        } else {
            if let handler = completionHandler {
                handler()
            }
        }
    }
    
}

// MARK: - Get data from cache
extension ImageCache {
    /**
    Get an image for a key from memory or disk.
    
    :param: key               Key for the image.
    :param: options           Options of retriving image.
    :param: completionHandler Called when getting operation completes with image result and cached type of this image. If there is no such key cached, the image will be `nil`.
    
    :returns: The retriving task.
    */
    public func retrieveImageForKey(key: String, options:KingfisherManager.Options, completionHandler: ((UIImage?, CacheType!) -> ())?) -> RetrieveImageDiskTask? {
        // No completion handler. Not start working and early return.
        if (completionHandler == nil) {
            return dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {}
        }
        
        let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
            if let image = self.retriveImageInMemoryCaheForKey(key) {
                
                //Found image in memory cache.
                if options.shouldDecode {
                    dispatch_async(self.processQueue, { () -> Void in
                        let result = image.kf_decodedImage()
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completionHandler?(result, .Memory)
                            return
                        })
                    })
                } else {
                    completionHandler?(image, .Memory)
                }
            } else {
                //Begin to load image from disk
                dispatch_async(self.ioQueue, { () -> Void in
                    
                    if let image = self.retriveImageInDiskCacheForKey(key) {
                        
                        if options.shouldDecode {
                            dispatch_async(self.processQueue, { () -> Void in
                                let result = image.kf_decodedImage()
                                self.storeImage(result!, forKey: key, toDisk: false, completionHandler: nil)
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    completionHandler?(result, .Memory)
                                    return
                                })
                            })
                        } else {
                            self.storeImage(image, forKey: key, toDisk: false, completionHandler: nil)
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if let completionHandler = completionHandler {
                                    completionHandler(image, .Disk)
                                }
                            })
                        }
                    } else {
                        // No image found from either memory or disk
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if let completionHandler = completionHandler {
                                completionHandler(nil, nil)
                            }
                        })
                    }
                })
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), block)
        return block
    }
    
    /**
    Get an image for a key from memory.
    
    :param: key Key for the image.
    
    :returns: The image object if it is cached, or `nil` if there is no such key in the cache.
    */
    public func retriveImageInMemoryCaheForKey(key: String) -> UIImage? {
        return memoryCache.objectForKey(key) as? UIImage
    }
    
    /**
    Get an image for a key from disk.
    
    :param: key Key for the image.
    
    :returns: The image object if it is cached, or `nil` if there is no such key in the cache.
    */
    public func retriveImageInDiskCacheForKey(key: String) -> UIImage? {
        return diskImageForKey(key)
    }
}

// MARK: - Clear & Clean
extension ImageCache {
    /**
    Clear memory cache.
    */
    @objc public func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /**
    Clear disk cache. This is an async operation.
    */
    public func clearDiskCache() {
        clearDiskCacheWithCompletionHandler(nil)
    }
    
    /**
    Clear disk cache. This is an async operation.
    
    :param: completionHander Called after the operation completes.
    */
    public func clearDiskCacheWithCompletionHandler(completionHander: (()->())?) {
        dispatch_async(ioQueue, { () -> Void in
            self.fileManager.removeItemAtPath(self.diskCachePath, error: nil)
            self.fileManager.createDirectoryAtPath(self.diskCachePath, withIntermediateDirectories: true, attributes: nil, error: nil)
            
            if let handler = completionHander {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler()
                })
            }
        })
    }
    
    /**
    Clean expired disk cache. This is an async operation.
    */
    @objc public func cleanExpiredDiskCache() {
        cleanExpiredDiskCacheWithCompletionHander(nil)
    }
    
    /**
    Clean expired disk cache. This is an async operation.
    
    :param: completionHandler Called after the operation completes.
    */
    public func cleanExpiredDiskCacheWithCompletionHander(completionHandler: (()->())?) {
        // Do things in cocurrent io queue
        dispatch_async(ioQueue, { () -> Void in
            if let diskCacheURL = NSURL(fileURLWithPath: self.diskCachePath) {
                
                let resourceKeys = [NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
                let expiredDate = NSDate(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
                var cachedFiles = [NSURL: [NSObject: AnyObject]]()
                var urlsToDelete = [NSURL]()
                
                var diskCacheSize: UInt = 0
                
                if let fileEnumerator = self.fileManager.enumeratorAtURL(diskCacheURL,
                    includingPropertiesForKeys: resourceKeys,
                    options: NSDirectoryEnumerationOptions.SkipsHiddenFiles,
                    errorHandler: nil) {
                        
                    for fileURL in fileEnumerator.allObjects as! [NSURL] {
                            
                        if let resourceValues = fileURL.resourceValuesForKeys(resourceKeys, error: nil) {
                            // If it is a Directory. Continue to next file URL.
                            if let isDirectory = resourceValues[NSURLIsDirectoryKey]?.boolValue {
                                if isDirectory {
                                    continue
                                }
                            }
                            
                            // If this file is expired, add it to urlsToDelete
                            if let modificationDate = resourceValues[NSURLContentModificationDateKey] as? NSDate {
                                if modificationDate.laterDate(expiredDate) == expiredDate {
                                    urlsToDelete.append(fileURL)
                                    continue
                                }
                            }
                            
                            if let fileSize = resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                                diskCacheSize += fileSize.unsignedLongValue
                                cachedFiles[fileURL] = resourceValues
                            }
                        }
                        
                    }
                }
                
                for fileURL in urlsToDelete {
                    self.fileManager.removeItemAtURL(fileURL, error: nil)
                }
                
                if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                    let targetSize = self.maxDiskCacheSize / 2
                    
                    // Sort files by last modify date. We want to clean from the oldest files.
                    let sortedFiles = cachedFiles.keysSortedByValue({ (resourceValue1, resourceValue2) -> Bool in

                        if let date1 = resourceValue1[NSURLContentModificationDateKey] as? NSDate {
                            if let date2 = resourceValue2[NSURLContentModificationDateKey] as? NSDate {
                                return date1.compare(date2) == .OrderedAscending
                            }
                        }
                        // Not valid date information. This should not happen. Just in case.
                        return true
                    })
                    
                    for fileURL in sortedFiles {
                        if (self.fileManager.removeItemAtURL(fileURL, error: nil)) {
                            if let fileSize = cachedFiles[fileURL]?[NSURLTotalFileAllocatedSizeKey] as? NSNumber {
                                diskCacheSize -= fileSize.unsignedLongValue
                            }
                            
                            if diskCacheSize < targetSize {
                                break
                            }
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let completionHandler = completionHandler {
                        completionHandler()
                    }
                })

            } else {
                println("Bad disk cache path. \(self.diskCachePath) is not a valid local directory path.")
            }
        })
    }
    
    /**
    Clean expired disk cache when app in background. This is an async operation.
    In most cases, you should not call this method explicitly. 
    It will be called automatically when `UIApplicationDidEnterBackgroundNotification` received.
    */
    @objc public func backgroundCleanExpiredDiskCache() {
        
        func endBackgroundTask(inout task: UIBackgroundTaskIdentifier) {
            UIApplication.sharedApplication().endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            endBackgroundTask(&backgroundTask!)
        }
        
        cleanExpiredDiskCacheWithCompletionHander { () -> () in
            endBackgroundTask(&backgroundTask!)
        }
    }
}


// MARK: - Check cache statue
public extension ImageCache {
    
    /**
    *  Cache result for checking whether an image is cached for a key.
    */
    public struct CacheCheckResult {
        public let cached: Bool
        public let cacheType: CacheType?
    }
    
    /**
    Check whether an image is cached for a key.
    
    :param: key Key for the image.
    
    :returns: The check result.
    */
    public func isImageCachedForKey(key: String) -> CacheCheckResult {
        if memoryCache.objectForKey(key) != nil {
            return CacheCheckResult(cached: true, cacheType: .Memory)
        }
        
        let filePath = cachePathForKey(key)
        if fileManager.fileExistsAtPath(filePath) {
            return CacheCheckResult(cached: true, cacheType: .Disk)
        }
        
        return CacheCheckResult(cached: false, cacheType: nil)
    }
}

// MARK: - Internal Helper
extension ImageCache {
    
    func diskImageForKey(key: String) -> UIImage? {
        if let data = diskImageDataForKey(key) {
            if let image = UIImage(data: data) {
                return image
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func diskImageDataForKey(key: String) -> NSData? {
        let filePath = cachePathForKey(key)
        return NSData(contentsOfFile: filePath)
    }
    
    func cachePathForKey(key: String) -> String {
        let fileName = cacheFileNameForKey(key)
        return diskCachePath.stringByAppendingPathComponent(fileName)
    }
    
    func cacheFileNameForKey(key: String) -> String {
        return key.kf_MD5()
    }
}

extension UIImage {
    var kf_imageCost: Int {
        return Int(size.height * size.width * scale * scale)
    }
}

extension Dictionary {
    func keysSortedByValue(isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        var array = Array(self)
        sort(&array) {
            let (lk, lv) = $0
            let (rk, rv) = $1
            return isOrderedBefore(lv, rv)
        }
        return array.map {
            let (k, v) = $0
            return k
        }
    }
}

