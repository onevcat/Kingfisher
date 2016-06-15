//
//  ImageCache.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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

#if os(OSX)
import AppKit
#else
import UIKit
#endif

/**
This notification will be sent when the disk cache got cleaned either there are cached files expired or the total size exceeding the max allowed size. The manually invoking of `clearDiskCache` method will not trigger this notification.

The `object` of this notification is the `ImageCache` object which sends the notification.

A list of removed hashes (files) could be retrieved by accessing the array under `KingfisherDiskCacheCleanedHashKey` key in `userInfo` of the notification object you received. By checking the array, you could know the hash codes of files are removed.

The main purpose of this notification is supplying a chance to maintain some necessary information on the cached files. See [this wiki](https://github.com/onevcat/Kingfisher/wiki/How-to-implement-ETag-based-304-(Not-Modified)-handling-in-Kingfisher) for a use case on it.
*/
public let KingfisherDidCleanDiskCacheNotification = "com.onevcat.Kingfisher.KingfisherDidCleanDiskCacheNotification"

/**
Key for array of cleaned hashes in `userInfo` of `KingfisherDidCleanDiskCacheNotification`.
*/
public let KingfisherDiskCacheCleanedHashKey = "com.onevcat.Kingfisher.cleanedHash"

private let defaultCacheName = "default"
private let cacheReverseDNS = "com.onevcat.Kingfisher.ImageCache."
private let ioQueueName = "com.onevcat.Kingfisher.ImageCache.ioQueue."
private let processQueueName = "com.onevcat.Kingfisher.ImageCache.processQueue."

private let defaultCacheInstance = ImageCache(name: defaultCacheName)
private let defaultMaxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7 //Cache exists for 1 week

/// It represents a task of retrieving image. You can call `cancel` on it to stop the process.
public typealias RetrieveImageDiskTask = DispatchWorkItem

/**
Cache type of a cached image.

- None:   The image is not cached yet when retrieving it.
- Memory: The image is cached in memory.
- Disk:   The image is cached in disk.
*/
public enum CacheType {
    case none, memory, disk
}

/// `ImageCache` represents both the memory and disk cache system of Kingfisher. While a default image cache object will be used if you prefer the extension methods of Kingfisher, you can create your own cache object and configure it as your need. You should use an `ImageCache` object to manipulate memory and disk cache for Kingfisher.
public class ImageCache {

    //Memory
    private let memoryCache = Cache<NSString, AnyObject>()
    
    /// The largest cache cost of memory cache. The total cost is pixel count of all cached images in memory.
    public var maxMemoryCost: UInt = 0 {
        didSet {
            self.memoryCache.totalCostLimit = Int(maxMemoryCost)
        }
    }
    
    //Disk
    private let ioQueue: DispatchQueue
    private var fileManager: FileManager!
    
    ///The disk cache location.
    public let diskCachePath: String
    
    /// The longest time duration of the cache being stored in disk. Default is 1 week.
    public var maxCachePeriodInSecond = defaultMaxCachePeriodInSecond
    
    /// The largest disk size can be taken for the cache. It is the total allocated size of cached files in bytes. Default is 0, which means no limit.
    public var maxDiskCacheSize: UInt = 0
    
    private let processQueue: DispatchQueue
    
    /// The default cache.
    public class var defaultCache: ImageCache {
        return defaultCacheInstance
    }
    
    /**
    Init method. Passing a name for the cache. It represents a cache folder in the memory and disk.
    
    - parameter name: Name of the cache. It will be used as the memory cache name and the disk cache folder name appending to the cache path. This value should not be an empty string.
    - parameter path: Optional - Location of cache path on disk. If `nil` is passed (the default value), 
                      the cache folder in of your app will be used. If you want to cache some user generating images, you could pass the Documentation path here.
    
    - returns: The cache object.
    */
    public init(name: String, path: String? = nil) {
        
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }
        
        let cacheName = cacheReverseDNS + name
        memoryCache.name = cacheName
        
        let dstPath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        diskCachePath = (dstPath as NSString).appendingPathComponent(cacheName)
        
        ioQueue = DispatchQueue(label: ioQueueName + name, attributes: DispatchQueueAttributes.serial)
        processQueue = DispatchQueue(label: processQueueName + name, attributes: DispatchQueueAttributes.concurrent)
        
        ioQueue.sync(execute: { () -> Void in
            self.fileManager = FileManager()
        })
        
#if !os(OSX) && !os(watchOS)
        NotificationCenter.default().addObserver(self, selector: #selector(ImageCache.clearMemoryCache), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(ImageCache.cleanExpiredDiskCache), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(ImageCache.backgroundCleanExpiredDiskCache), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
#endif
    }
    
    deinit {
        NotificationCenter.default().removeObserver(self)
    }
}

// MARK: - Store & Remove
extension ImageCache {
    /**
    Store an image to cache. It will be saved to both memory and disk. It is an async operation.
    
    - parameter image:             The image to be stored.
    - parameter originalData:      The original data of the image.
                                   Kingfisher will use it to check the format of the image and optimize cache size on disk.
                                   If `nil` is supplied, the image data will be saved as a normalized PNG file. 
                                   It is strongly suggested to supply it whenever possible, to get a better performance and disk usage.
    - parameter key:               Key for the image.
    - parameter toDisk:            Whether this image should be cached to disk or not. If false, the image will be only cached in memory.
    - parameter completionHandler: Called when store operation completes.
    */
    public func storeImage(_ image: Image, originalData: Data? = nil, forKey key: String, toDisk: Bool = true, completionHandler: (() -> Void)? = nil) {
        memoryCache.setObject(image, forKey: key, cost: image.kf_imageCost)
        
        func callHandlerInMainQueue() {
            if let handler = completionHandler {
                DispatchQueue.main.async {
                    handler()
                }
            }
        }
        
        if toDisk {
            ioQueue.async(execute: {
                let imageFormat: ImageFormat
                if let originalData = originalData {
                    imageFormat = originalData.kf_imageFormat
                } else {
                    imageFormat = .unknown
                }
                
                let data: Data?
                switch imageFormat {
                case .png: data = originalData ?? ImagePNGRepresentation(image)
                case .jpeg: data = originalData ?? ImageJPEGRepresentation(image, 1.0)
                case .gif: data = originalData ?? ImageGIFRepresentation(image)
                case .unknown: data = originalData ?? ImagePNGRepresentation(image.kf_normalizedImage())
                }
                
                if let data = data {
                    if !self.fileManager.fileExists(atPath: self.diskCachePath) {
                        do {
                            try self.fileManager.createDirectory(atPath: self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
                        } catch _ {}
                    }
                    
                    self.fileManager.createFile(atPath: self.cachePathForKey(key), contents: data, attributes: nil)
                }
                callHandlerInMainQueue()
            })
        } else {
            callHandlerInMainQueue()
        }
    }
    
    /**
    Remove the image for key for the cache. It will be opted out from both memory and disk. 
    It is an async operation.
    
    - parameter key:               Key for the image.
    - parameter fromDisk:          Whether this image should be removed from disk or not. If false, the image will be only removed from memory.
    - parameter completionHandler: Called when removal operation completes.
    */
    public func removeImageForKey(_ key: String, fromDisk: Bool = true, completionHandler: (() -> Void)? = nil) {
        memoryCache.removeObject(forKey: key)
        
        func callHandlerInMainQueue() {
            if let handler = completionHandler {
                DispatchQueue.main.async {
                    handler()
                }
            }
        }
        
        if fromDisk {
            ioQueue.async(execute: { () -> Void in
                do {
                    try self.fileManager.removeItem(atPath: self.cachePathForKey(key))
                } catch _ {}
                callHandlerInMainQueue()
            })
        } else {
            callHandlerInMainQueue()
        }
    }
    
}

// MARK: - Get data from cache
extension ImageCache {
    /**
    Get an image for a key from memory or disk.
    
    - parameter key:               Key for the image.
    - parameter options:           Options of retrieving image.
    - parameter completionHandler: Called when getting operation completes with image result and cached type of this image. If there is no such key cached, the image will be `nil`.
    
    - returns: The retrieving task.
    */
    public func retrieveImageForKey(_ key: String, options: KingfisherOptionsInfo?, completionHandler: ((Image?, CacheType) -> ())?) -> RetrieveImageDiskTask? {
        // No completion handler. Not start working and early return.
        guard let completionHandler = completionHandler else {
            return nil
        }
        
        var block: RetrieveImageDiskTask?
        let options = options ?? KingfisherEmptyOptionsInfo
        
        if let image = self.retrieveImageInMemoryCacheForKey(key) {
            dispatch_async_safely_to_queue(options.callbackDispatchQueue) { () -> Void in
                completionHandler(image, .memory)
            }
        } else {
            var sSelf: ImageCache! = self
            block = DispatchWorkItem(block: {
                // Begin to load image from disk
                if let image = sSelf.retrieveImageInDiskCacheForKey(key, scale: options.scaleFactor, preloadAllGIFData: options.preloadAllGIFData) {
                    if options.backgroundDecode {
                        sSelf.processQueue.async(execute: { () -> Void in
                            let result = image.kf_decodedImage(options.scaleFactor)
                            sSelf.storeImage(result!, forKey: key, toDisk: false, completionHandler: nil)

                            dispatch_async_safely_to_queue(options.callbackDispatchQueue, { () -> Void in
                                completionHandler(result, .memory)
                                sSelf = nil
                            })
                        })
                    } else {
                        sSelf.storeImage(image, forKey: key, toDisk: false, completionHandler: nil)
                        dispatch_async_safely_to_queue(options.callbackDispatchQueue, { () -> Void in
                            completionHandler(image, .disk)
                            sSelf = nil
                        })
                    }
                } else {
                    // No image found from either memory or disk
                    dispatch_async_safely_to_queue(options.callbackDispatchQueue, { () -> Void in
                        completionHandler(nil, .none)
                        sSelf = nil
                    })
                }
            })
            
            sSelf.ioQueue.async(execute: block!)
        }
    
        return block
    }
    
    /**
    Get an image for a key from memory.
    
    - parameter key: Key for the image.
    
    - returns: The image object if it is cached, or `nil` if there is no such key in the cache.
    */
    public func retrieveImageInMemoryCacheForKey(_ key: String) -> Image? {
        return memoryCache.object(forKey: key) as? Image
    }
    
    /**
    Get an image for a key from disk.
    
    - parameter key: Key for the image.
    - parameter scale: The scale factor to assume when interpreting the image data.
    - parameter preloadAllGIFData: Whether all GIF data should be loaded. If true, you can set the loaded image to a regular UIImageView to play 
      the GIF animation. Otherwise, you should use `AnimatedImageView` to play it. Default is `false`

    - returns: The image object if it is cached, or `nil` if there is no such key in the cache.
    */
    public func retrieveImageInDiskCacheForKey(_ key: String, scale: CGFloat = 1.0, preloadAllGIFData: Bool = false) -> Image? {
        return diskImageForKey(key, scale: scale, preloadAllGIFData: preloadAllGIFData)
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
    Clear disk cache. This is could be an async or sync operation.
    Specify the way you want it by passing the `sync` parameter.
    */
    public func clearDiskCache() {
        clearDiskCacheWithCompletionHandler(nil)
    }
    
    /**
    Clear disk cache. This is an async operation.
    
    - parameter completionHander: Called after the operation completes.
    */
    public func clearDiskCacheWithCompletionHandler(_ completionHander: (()->())?) {
        ioQueue.async(execute: { () -> Void in
            do {
                try self.fileManager.removeItem(atPath: self.diskCachePath)
                try self.fileManager.createDirectory(atPath: self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
            } catch _ {
            }
            
            if let completionHander = completionHander {
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHander()
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
    
    - parameter completionHandler: Called after the operation completes.
    */
    public func cleanExpiredDiskCacheWithCompletionHander(_ completionHandler: (()->())?) {
        
        // Do things in cocurrent io queue
        ioQueue.async(execute: { () -> Void in
            
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles(onlyForCacheSize: false)
            
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItem(at: fileURL)
                } catch _ {
                }
            }
                
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                    
                // Sort files by last modify date. We want to clean from the oldest files.
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1[URLResourceKey.contentModificationDateKey] as? Date,
                           date2 = resourceValue2[URLResourceKey.contentModificationDateKey] as? Date {
                        return date1.compare(date2) == .orderedAscending
                    }
                    // Not valid date information. This should not happen. Just in case.
                    return true
                }
                
                for fileURL in sortedFiles {
                    
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                    } catch {
                        
                    }
                        
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        diskCacheSize -= fileSize.uintValue
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
                
            DispatchQueue.main.async(execute: { () -> Void in
                
                if URLsToDelete.count != 0 {
                    let cleanedHashes = URLsToDelete.map({ (url) -> String in
                        return url.lastPathComponent!
                    })
                    
                    NotificationCenter.default().post(name: Notification.Name(rawValue: KingfisherDidCleanDiskCacheNotification), object: self, userInfo: [KingfisherDiskCacheCleanedHashKey: cleanedHashes])
                }
                
                completionHandler?()
            })
        })
    }
    
    private func travelCachedFiles(onlyForCacheSize: Bool) -> (URLsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: [NSObject: AnyObject]]) {
        
        let diskCacheURL = URL(fileURLWithPath: diskCachePath)
        let resourceKeys = [URLResourceKey.isDirectoryKey, URLResourceKey.contentModificationDateKey, URLResourceKey.totalFileAllocatedSizeKey]
        let expiredDate = Date(timeIntervalSinceNow: -self.maxCachePeriodInSecond)
        
        var cachedFiles = [URL: [NSObject: AnyObject]]()
        var URLsToDelete = [URL]()
        var diskCacheSize: UInt = 0
        
        let resourceKeysString = resourceKeys.map { (key) -> String in
            return key.rawValue
        }
        if let fileEnumerator = self.fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: resourceKeysString, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, errorHandler: nil),
            urls = fileEnumerator.allObjects as? [URL] {
                for fileURL in urls {
                    
                    do {
                        let resourceValues = try (fileURL as NSURL).resourceValues(forKeys: resourceKeys)
                        // If it is a Directory. Continue to next file URL.
                        if let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? NSNumber {
                            if isDirectory.boolValue {
                                continue
                            }
                        }
                        
                        if !onlyForCacheSize {
                            // If this file is expired, add it to URLsToDelete
                            if let modificationDate = resourceValues[URLResourceKey.contentModificationDateKey] as? Date {
                                if (modificationDate as NSDate).laterDate(expiredDate) == expiredDate {
                                    URLsToDelete.append(fileURL)
                                    continue
                                }
                            }
                        }
                        
                        if let fileSize = resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                            diskCacheSize += fileSize.uintValue
                            if !onlyForCacheSize {
                                cachedFiles[fileURL] = resourceValues
                            }
                        }
                    } catch _ {
                    }
                }
        }
        
        return (URLsToDelete, diskCacheSize, cachedFiles)
    }
    
#if !os(OSX) && !os(watchOS)
    /**
    Clean expired disk cache when app in background. This is an async operation.
    In most cases, you should not call this method explicitly. 
    It will be called automatically when `UIApplicationDidEnterBackgroundNotification` received.
    */
    @objc public func backgroundCleanExpiredDiskCache() {
        // if 'sharedApplication()' is unavailable, then return
        guard let sharedApplication = UIApplication.kf_sharedApplication() else { return }

        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        
        backgroundTask = sharedApplication.beginBackgroundTask { () -> Void in
            endBackgroundTask(&backgroundTask!)
        }
        
        cleanExpiredDiskCacheWithCompletionHander { () -> () in
            endBackgroundTask(&backgroundTask!)
        }
    }
#endif
}


// MARK: - Check cache status
extension ImageCache {
    
    /**
    *  Cache result for checking whether an image is cached for a key.
    */
    public struct CacheCheckResult {
        public let cached: Bool
        public let cacheType: CacheType?
    }
    
    /**
     Determine if a cached image exists for the given image, as keyed by the URL. It will return true if the
     image is found either in memory or on disk. Essentially as long as there is a cache of the image somewhere
     true is returned. A convenience method that decodes `isImageCachedForKey`.
     
     - parameter url: The image URL.
     
     - returns: True if the image is cached, false otherwise.
     */
    public func cachedImageExistsforURL(_ url: URL) -> Bool {
        let resource = Resource(downloadURL: url)
        let result = isImageCachedForKey(resource.cacheKey)
        return result.cached
    }

    /**
    Check whether an image is cached for a key.
    
    - parameter key: Key for the image.
    
    - returns: The check result.
    */
    public func isImageCachedForKey(_ key: String) -> CacheCheckResult {
        
        if memoryCache.object(forKey: key) != nil {
            return CacheCheckResult(cached: true, cacheType: .memory)
        }
        
        let filePath = cachePathForKey(key)
        
        var diskCached = false
        ioQueue.sync { () -> Void in
            diskCached = self.fileManager.fileExists(atPath: filePath)
        }

        if diskCached {
            return CacheCheckResult(cached: true, cacheType: .disk)
        }
        
        return CacheCheckResult(cached: false, cacheType: nil)
    }
    
    /**
    Get the hash for the key. This could be used for matching files.
    
    - parameter key: The key which is used for caching.
    
    - returns: Corresponding hash.
    */
    public func hashForKey(_ key: String) -> String {
        return cacheFileNameForKey(key)
    }
    
    /**
    Calculate the disk size taken by cache. 
    It is the total allocated size of the cached files in bytes.
    
    - parameter completionHandler: Called with the calculated size when finishes.
    */
    public func calculateDiskCacheSizeWithCompletionHandler(_ completionHandler: ((size: UInt) -> ())) {
        ioQueue.async(execute: { () -> Void in
            let (_, diskCacheSize, _) = self.travelCachedFiles(onlyForCacheSize: true)
            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(size: diskCacheSize)
            })
        })
    }
    
    /**
    Get the cache path for the key.
    It is useful for projects with UIWebView or anyone that needs access to the local file path.
    
    i.e. `<img src='path_for_key'>`
     
    - Note: This method does not guarantee there is an image already cached in the path. 
      You could use `isImageCachedForKey` method to check whether the image is cached under that key.
    */
    public func cachePathForKey(_ key: String) -> String {
        let fileName = cacheFileNameForKey(key)
        return (diskCachePath as NSString).appendingPathComponent(fileName)
    }

}

// MARK: - Internal Helper
extension ImageCache {
    
    func diskImageForKey(_ key: String, scale: CGFloat, preloadAllGIFData: Bool) -> Image? {
        if let data = diskImageDataForKey(key) {
            return Image.kf_imageWithData(data, scale: scale, preloadAllGIFData: preloadAllGIFData)
        } else {
            return nil
        }
    }
    
    func diskImageDataForKey(_ key: String) -> Data? {
        let filePath = cachePathForKey(key)
        return (try? Data(contentsOf: URL(fileURLWithPath: filePath)))
    }
    
    func cacheFileNameForKey(_ key: String) -> String {
        return key.kf_MD5
    }
}

extension Image {
    var kf_imageCost: Int {
        return kf_images == nil ?
            Int(size.height * size.width * kf_scale * kf_scale) :
            Int(size.height * size.width * kf_scale * kf_scale) * kf_images!.count
    }
}

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

#if !os(OSX) && !os(watchOS)
// MARK: - For App Extensions
extension UIApplication {
    public static func kf_sharedApplication() -> UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard responds(to: selector) else { return nil }
        return perform(selector).takeUnretainedValue() as? UIApplication
    }
}
#endif
