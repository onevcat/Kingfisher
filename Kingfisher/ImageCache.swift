//
//  ImageCache.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

import Foundation

private let defaultCacheName = "default"
private let cacheReverseDNS = "com.onevcat.Kingfisher.ImageCache."
private let ioQueneName = "com.onevcat.Kingfisher.ImageCache.ioQueue"

private let defaultCacheInstance = ImageCache(name: defaultCacheName)
private let defaultMaxCachePeriodInSecond: NSTimeInterval = 60 * 60 * 24 * 7 //Cache exists for 1 week


public typealias RetrieveImageDiskTask = dispatch_block_t

public enum CacheType {
    case Memory, Disk
}

public class ImageCache {
    
    public var maxCachePeriodInSecond = defaultMaxCachePeriodInSecond
    public var maxMemoryCost: UInt = 0 {
        didSet {
            self.memoryCache.totalCostLimit = Int(maxMemoryCost)
        }
    }
    public var maxDiskCacheSize: UInt = 0
    
    //Memory
    private let memoryCache = NSCache()
    
    //Disk
    private let ioQueue = dispatch_queue_create(ioQueneName, DISPATCH_QUEUE_SERIAL)
    private let diskCachePath: String
    private var fileManager: NSFileManager!
    
    public class var defaultCache: ImageCache {
        return defaultCacheInstance
    }
    
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
    
    public func storeImage(image: UIImage, forKey key: String) {
        storeImage(image, forKey: key, toDisk: true, completionHandler: nil)
    }
    
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
    
    public func removeImageForKey(key: String) {
        removeImageForKey(key, fromDisk: true, completionHandler: nil)
    }
    
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
    public func retrieveImageForKey(key: String, completionHandler: ((UIImage?, CacheType!) -> ())?) -> RetrieveImageDiskTask? {
        // No completion handler. Not start working and early return.
        if (completionHandler == nil) {
            return dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {}
        }
        
        let block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
            if let image = self.retriveImageInMemoryCaheForKey(key) {
                //Found image in memory cache.
                completionHandler?(image, .Memory)
            } else {
                //Begin to load image from disk
                dispatch_async(self.ioQueue, { () -> Void in
                    
                    if let image = self.retriveImageInDiskCacheForKey(key) {
                        self.storeImage(image, forKey: key, toDisk: false, completionHandler: nil)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if let completionHandler = completionHandler {
                                completionHandler(image, .Disk)
                            }
                        })
                        
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
    
    public func retriveImageInMemoryCaheForKey(key: String) -> UIImage? {
        return memoryCache.objectForKey(key) as? UIImage
    }
    
    public func retriveImageInDiskCacheForKey(key: String) -> UIImage? {
        return diskImageForKey(key)
    }
}

// MARK: - Clear & Clean
extension ImageCache {
    @objc public func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    public func clearDiskCache() {
        clearDiskCacheWithCompletionHandler(nil)
    }
    
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
    
    @objc public func cleanExpiredDiskCache() {
        cleanExpiredDiskCacheWithCompletionHander(nil)
    }
    
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
                        
                    for fileURL in fileEnumerator.allObjects as [NSURL] {
                            
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
                                diskCacheSize += fileSize.unsignedIntegerValue
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
                                diskCacheSize -= fileSize.unsignedIntegerValue
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
    
    // For Objective-C compatibility, we can not use tuple
    public struct CacheCheckResult {
        public let cached: Bool
        public let cacheType: CacheType?
    }
    
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

