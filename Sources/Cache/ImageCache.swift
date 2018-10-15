//
//  ImageCache.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Notification.Name {
    /// This notification will be sent when the disk cache got cleaned either there are cached files expired or the
    /// total size exceeding the max allowed size. The manually invoking of `clearDiskCache` method will not trigger
    /// this notification.
    ///
    /// The `object` of this notification is the `ImageCache` object which sends the notification.
    /// A list of removed hashes (files) could be retrieved by accessing the array under
    /// `KingfisherDiskCacheCleanedHashKey` key in `userInfo` of the notification object you received.
    /// By checking the array, you could know the hash codes of files are removed.
    public static let KingfisherDidCleanDiskCache = Notification.Name("com.onevcat.Kingfisher.KingfisherDidCleanDiskCache")
}

/// Key for array of cleaned hashes in `userInfo` of `KingfisherDidCleanDiskCacheNotification`.
public let KingfisherDiskCacheCleanedHashKey = "com.onevcat.Kingfisher.cleanedHash"

/// Cache type of a cached image.
/// - none: The image is not cached yet when retrieving it.
/// - memory: The image is cached in memory.
/// - disk: The image is cached in disk.
public enum CacheType {
    case none, memory, disk
    
    public var cached: Bool {
        switch self {
        case .memory, .disk: return true
        case .none: return false
        }
    }
}

extension Image: CacheCostCalculatable {
    #warning("Update image cost")
    public var cost: Int { return 1 }
}

extension Data: DataTransformable {
    public func toData() throws -> Data {
        return self
    }

    public static func fromData(_ data: Data) throws -> Data {
        return data
    }
}

public enum ImageCacheResult {
    case disk(Image)
    case memory(Image)
    case none
    
    public var image: Image? {
        switch self {
        case .disk(let image): return image
        case .memory(let image): return image
        case .none: return nil
        }
    }
    
    public var cacheType: CacheType {
        switch self {
        case .disk: return .disk
        case .memory: return .memory
        case .none: return .none
        }
    }
}

/// `ImageCache` represents both the memory and disk cache system of Kingfisher. 
/// While a default image cache object will be used if you prefer the extension methods of Kingfisher, 
/// you can create your own cache object and configure it as your need. You could use an `ImageCache`
/// object to manipulate memory and disk cache for Kingfisher.
open class ImageCache {

    public let memoryStorage: MemoryStorage<Image>
    public let diskStorage: DiskStorage<Data>
    
    //Disk
    fileprivate let ioQueue: DispatchQueue
    
    /// The longest time duration in second of the cache being stored in disk. 
    /// Default is 1 week (60 * 60 * 24 * 7 seconds).
    /// Setting this to a negative value will make the disk cache never expiring.
    open var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7 //Cache exists for 1 week
    
    /// The default cache.
    public static let `default` = ImageCache(name: "default")
    
    /// Closure that defines the disk cache path from a given path and cacheName.
    public typealias DiskCachePathClosure = (URL, String) -> URL

    /**
    Init method. Passing a name for the cache. It represents a cache folder in the memory and disk.
    
    - parameter name: Name of the cache. It will be used as the memory cache name and the disk cache folder name 
                      appending to the cache path. This value should not be an empty string.
    - parameter path: Optional - Location of cache path on disk. If `nil` is passed in (the default value),
                      the `.cachesDirectory` in of your app will be used.
    - parameter diskCachePathClosure: Closure that takes in an optional initial path string and generates
                      the final disk cache path. You could use it to fully customize your cache path.
    */
    public init(name: String,
                path: String? = nil,
                diskCachePathClosure: DiskCachePathClosure? = nil)
    {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }
        
        let cacheName = "com.onevcat.Kingfisher.ImageCache.\(name)"

        #warning("Choose a proper init cost limit.")
        memoryStorage = MemoryStorage(config: .init(totalCostLimit: 0))
        #warning("Choose a proper init cost limit.")

        var diskConfig = DiskStorage<Data>.Config(name: name, sizeLimit: 0)
        if let closure = diskCachePathClosure {
            diskConfig.cachePathBlock = diskCachePathClosure
            defer { diskConfig.cachePathBlock = nil }
        }

        diskStorage = try! DiskStorage(config: diskConfig)
        
        let ioQueueName = "com.onevcat.Kingfisher.ImageCache.ioQueue.\(name)"
        ioQueue = DispatchQueue(label: ioQueueName)

#if !os(macOS) && !os(watchOS)
        NotificationCenter.default.addObserver(
            self, selector: #selector(clearMemoryCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(cleanExpiredDiskCache), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(backgroundCleanExpiredDiskCache), name: UIApplication.didEnterBackgroundNotification, object: nil)
#endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    // MARK: - Store & Remove

    /**
    Store an image to cache. It will be saved to both memory and disk. It is an async operation.
    
    - parameter image:             The image to be stored.
    - parameter original:          The original data of the image.
                                   Kingfisher will use it to check the format of the image and optimize cache size on disk.
                                   If `nil` is supplied, the image data will be saved as a normalized PNG file.
                                   It is strongly suggested to supply it whenever possible, to get a better performance and disk usage.
    - parameter key:               Key for the image.
    - parameter identifier:        The identifier of processor used. If you are using a processor for the image, pass the identifier of
                                   processor to it.
                                   This identifier will be used to generate a corresponding key for the combination of `key` and processor.
    - parameter toDisk:            Whether this image should be cached to disk or not. If false, the image will be only cached in memory.
    - parameter completionHandler: Called when store operation completes.
    */
    open func store(_ image: Image,
                      original: Data? = nil,
                      forKey key: String,
                      processorIdentifier identifier: String = "",
                      cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
                      toDisk: Bool = true,
                      completionHandler: (() -> Void)? = nil)
    {
        let computedKey = key.computedKey(with: identifier)
        try? memoryStorage.store(value: image, forKey: computedKey)

        if toDisk {
            ioQueue.async {
                if let data = serializer.data(with: image, original: original) {
                    do {
                        try self.diskStorage.store(value: data, forKey: computedKey)
                    } catch {
                        #warning("TODO: handle error")
                    }
                }
                completionHandler?()
            }
        } else {
            completionHandler?()
        }
    }
    
    /**
    Remove the image for key for the cache. It will be opted out from both memory and disk. 
    It is an async operation.
    
    - parameter key:               Key for the image.
    - parameter identifier:        The identifier of processor used. If you are using a processor for the image, pass the identifier of processor to it.
                                   This identifier will be used to generate a corresponding key for the combination of `key` and processor.
    - parameter fromMemory:        Whether this image should be removed from memory or not. If false, the image won't be removed from memory.
    - parameter fromDisk:          Whether this image should be removed from disk or not. If false, the image won't be removed from disk.
    - parameter completionHandler: Called when removal operation completes.
    */
    open func removeImage(forKey key: String,
                          processorIdentifier identifier: String = "",
                          fromMemory: Bool = true,
                          fromDisk: Bool = true,
                          completionHandler: (() -> Void)? = nil)
    {
        let computedKey = key.computedKey(with: identifier)

        if fromMemory {
            try? memoryStorage.remove(forKey: computedKey)
        }
        
        if fromDisk {
            ioQueue.async{
                try? self.diskStorage.remove(forKey: computedKey)
                completionHandler?()
            }
        } else {
            completionHandler?()
        }
    }

    // MARK: - Get data from cache

    /**
    Get an image for a key from memory or disk.
    
    - parameter key:               Key for the image.
    - parameter options:           Options of retrieving image. If you need to retrieve an image which was 
                                   stored with a specified `ImageProcessor`, pass the processor in the option too.
    - parameter completionHandler: Called when getting operation completes with image result and cached type of 
                                   this image. If there is no such key cached, the image will be `nil`.
    
    - returns: The retrieving task.
    */
    open func retrieveImage(forKey key: String,
                               options: KingfisherOptionsInfo?,
                        callbackQueue: CallbackQueue = .current,
                     completionHandler: ((Result<(ImageCacheResult)>) -> Void)?)
    {
        // No completion handler. Not start working and early return.
        guard let completionHandler = completionHandler else { return }
        
        let options = options ?? .empty
        let imageModifier = options.imageModifier
        
        if let image = retrieveImageInMemoryCache(forKey: key, options: options) {
            let image = imageModifier.modify(image)
            callbackQueue.execute { completionHandler(.success(.memory(image))) }
        } else if options.fromMemoryCacheOrRefresh {
            callbackQueue.execute { completionHandler(.success(.none)) }
        } else {
            ioQueue.async {
                self.retrieveImageInDiskCache(forKey: key, options: options, callbackQueue: callbackQueue) {
                    result in
                    // The callback queue is already correct in this closure.
                    switch result {
                    case .success(let image):
                        guard let image = imageModifier.modify(image) else {
                            // No image found in disk storage.
                            completionHandler(.success(.none))
                            return
                        }
                    
                        // Cache the disk image to memory.
                        self.store(
                            image,
                            forKey: key,
                            processorIdentifier: options.processor.identifier,
                            cacheSerializer: options.cacheSerializer,
                            toDisk: false)
                        {
                            completionHandler(.success(.disk(image)))
                        }
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            }
        }
    }
    
    /**
    Get an image for a key from memory.
    
    - parameter key:     Key for the image.
    - parameter options: Options of retrieving image. If you need to retrieve an image which was 
                         stored with a specified `ImageProcessor`, pass the processor in the option too.
    - returns: The image object if it is cached, or `nil` if there is no such key in the cache.
    */
    open func retrieveImageInMemoryCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil) -> Image?
    {
        let options = options ?? .empty
        let computedKey = key.computedKey(with: options.processor.identifier)
        do {
            return try memoryStorage.value(forKey: computedKey)
        } catch {
            return nil
        }
    }
    
    open func retrieveImageInDiskCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil,
        callbackQueue: CallbackQueue = .current,
        completionHandler: @escaping (Result<Image?>) -> Void)
    {
        let options = options ?? .empty
        let computedKey = key.computedKey(with: options.processor.identifier)
        ioQueue.async {
            do {
                var image: Image? = nil
                if let data = try self.diskStorage.value(forKey: computedKey) {
                    image = options.cacheSerializer.image(with: data, options: options)
                }
                callbackQueue.execute { completionHandler(.success(image)) }
            } catch {
                callbackQueue.execute { completionHandler(.failure(error)) }
            }
        }
    }

    // MARK: - Clear & Clean

    /**
    Clear memory cache.
    */
    @objc public func clearMemoryCache() {
        try? memoryStorage.removeAll()
    }
    
    /**
    Clear disk cache. This is an async operation.
    
    - parameter completionHander: Called after the operation completes.
    */
    open func clearDiskCache(completion handler: (()->())? = nil) {
        ioQueue.async {
            do {
                try self.diskStorage.removeAll()
            } catch _ { }
            handler?()
        }
    }
    
    /**
    Clean expired disk cache. This is an async operation.
    */
    @objc fileprivate func cleanExpiredDiskCache() {
        cleanExpiredDiskCache(completion: nil)
    }
    
    /**
    Clean expired disk cache. This is an async operation.
    
    - parameter completionHandler: Called after the operation completes.
    */
    open func cleanExpiredDiskCache(completion handler: (() -> Void)? = nil) {
        
        // Do things in concurrent io queue
        ioQueue.async {
            do {
                try self.diskStorage.removeExpiredValues()
                try self.diskStorage.removeSizeExceededValues()
                handler?()
            } catch {}

//            DispatchQueue.main.async {
//
//                if URLsToDelete.count != 0 {
//                    let cleanedHashes = URLsToDelete.map { $0.lastPathComponent }
//                    NotificationCenter.default.post(name: .KingfisherDidCleanDiskCache, object: self, userInfo: [KingfisherDiskCacheCleanedHashKey: cleanedHashes])
//                }
//
//                handler?()
//            }
        }
    }

#if !os(macOS) && !os(watchOS)
    /**
    Clean expired disk cache when app in background. This is an async operation.
    In most cases, you should not call this method explicitly. 
    It will be called automatically when `UIApplicationDidEnterBackgroundNotification` received.
    */
    @objc public func backgroundCleanExpiredDiskCache() {
        // if 'sharedApplication()' is unavailable, then return
        guard let sharedApplication = KingfisherClass<UIApplication>.shared else { return }

        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskIdentifier.invalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = sharedApplication.beginBackgroundTask {
            endBackgroundTask(&backgroundTask!)
        }
        
        cleanExpiredDiskCache {
            endBackgroundTask(&backgroundTask!)
        }
    }
#endif


    // MARK: - Check cache status
    /// Cache type for checking whether an image is cached for a key in current cache.
    ///
    /// - Parameters:
    ///   - key: Key for the image.
    ///   - identifier: Processor identifier which used for this image. Default is empty string.
    /// - Returns: A `CacheType` instance which indicates the cache status. `.none` means the image is not in cache yet.
    open func imageCachedType(forKey key: String, processorIdentifier identifier: String = "") -> CacheType {
        let computedKey = key.computedKey(with: identifier)
        do {
            if let _ = try memoryStorage.value(forKey: computedKey) {
                return .memory
            }
            if let _ = try diskStorage.value(forKey: computedKey) {
                return .disk
            }
        } catch {}
        return .none
    }
    
    /**
    Get the hash for the key. This could be used for matching files.
    
    - parameter key:        The key which is used for caching.
    - parameter identifier: The identifier of processor used. If you are using a processor for the image, pass the identifier of processor to it.
    
     - returns: Corresponding hash.
    */
    open func hash(forKey key: String, processorIdentifier identifier: String = "") -> String {
        let computedKey = key.computedKey(with: identifier)
        return diskStorage.cacheFileName(forKey: computedKey)
    }
    
    /**
    Calculate the disk size taken by cache. 
    It is the total allocated size of the cached files in bytes.
    
    - parameter completionHandler: Called with the calculated size when finishes.
    */
    open func calculateDiskCacheSize(completion handler: @escaping ((_ size: UInt) -> Void)) {
        ioQueue.async {
            do {
                let size = try self.diskStorage.totalSize()
                DispatchQueue.main.async {
                    handler(UInt(size))
                }
            } catch {
                #warning("TODO: Call handler with an error.")
                handler(0)
            }
        }
    }
    
    /**
    Get the cache path for the key.
    It is useful for projects with UIWebView or anyone that needs access to the local file path.
    
    i.e. Replace the `<img src='path_for_key'>` tag in your HTML.
     
    - Note: This method does not guarantee there is an image already cached in the path. It just returns the path
      that the image should be.
      You could use `isImageCached(forKey:)` method to check whether the image is cached under that key.
    */
    open func cachePath(forKey key: String, processorIdentifier identifier: String = "") -> String {
        let computedKey = key.computedKey(with: identifier)
        return diskStorage.cacheFileURL(forKey: computedKey).absoluteString
    }
}

extension KingfisherClass where Base: Image {
    var imageCost: Int {
        return images == nil ?
            Int(size.height * size.width * scale * scale) :
            Int(size.height * size.width * scale * scale) * images!.count
    }
}

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

#if !os(macOS) && !os(watchOS)
// MARK: - For App Extensions
extension UIApplication: KingfisherClassCompatible { }
extension KingfisherClass where Base: UIApplication {
    public static var shared: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard Base.responds(to: selector) else { return nil }
        return Base.perform(selector).takeUnretainedValue() as? UIApplication
    }
}
#endif

extension String {
    func computedKey(with identifier: String) -> String {
        if identifier.isEmpty {
            return self
        } else {
            return appending("@\(identifier)")
        }
    }
}
