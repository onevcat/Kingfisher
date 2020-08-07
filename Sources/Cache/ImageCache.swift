//
//  ImageCache.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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
    public static let KingfisherDidCleanDiskCache =
        Notification.Name("com.onevcat.Kingfisher.KingfisherDidCleanDiskCache")
}

/// Key for array of cleaned hashes in `userInfo` of `KingfisherDidCleanDiskCacheNotification`.
public let KingfisherDiskCacheCleanedHashKey = "com.onevcat.Kingfisher.cleanedHash"

/// Cache type of a cached image.
/// - none: The image is not cached yet when retrieving it.
/// - memory: The image is cached in memory.
/// - disk: The image is cached in disk.
public enum CacheType {
    /// The image is not cached yet when retrieving it.
    case none
    /// The image is cached in memory.
    case memory
    /// The image is cached in disk.
    case disk
    
    /// Whether the cache type represents the image is already cached or not.
    public var cached: Bool {
        switch self {
        case .memory, .disk: return true
        case .none: return false
        }
    }
}

/// Represents the caching operation result.
public struct CacheStoreResult {
    
    /// The cache result for memory cache. Caching an image to memory will never fail.
    public let memoryCacheResult: Result<(), Never>
    
    /// The cache result for disk cache. If an error happens during caching operation,
    /// you can get it from `.failure` case of this `diskCacheResult`.
    public let diskCacheResult: Result<(), KingfisherError>
}

extension KFCrossPlatformImage: CacheCostCalculable {
    /// Cost of an image
    public var cacheCost: Int { return kf.cost }
}

extension Data: DataTransformable {
    public func toData() throws -> Data {
        return self
    }

    public static func fromData(_ data: Data) throws -> Data {
        return data
    }

    public static let empty = Data()
}


/// Represents the getting image operation from the cache.
///
/// - disk: The image can be retrieved from disk cache.
/// - memory: The image can be retrieved memory cache.
/// - none: The image does not exist in the cache.
public enum ImageCacheResult {
    
    /// The image can be retrieved from disk cache.
    case disk(KFCrossPlatformImage)
    
    /// The image can be retrieved memory cache.
    case memory(KFCrossPlatformImage)
    
    /// The image does not exist in the cache.
    case none
    
    /// Extracts the image from cache result. It returns the associated `Image` value for
    /// `.disk` and `.memory` case. For `.none` case, `nil` is returned.
    public var image: KFCrossPlatformImage? {
        switch self {
        case .disk(let image): return image
        case .memory(let image): return image
        case .none: return nil
        }
    }
    
    /// Returns the corresponding `CacheType` value based on the result type of `self`.
    public var cacheType: CacheType {
        switch self {
        case .disk: return .disk
        case .memory: return .memory
        case .none: return .none
        }
    }
}

/// Represents a hybrid caching system which is composed by a `MemoryStorage.Backend` and a `DiskStorage.Backend`.
/// `ImageCache` is a high level abstract for storing an image as well as its data to disk memory and disk, and
/// retrieving them back.
///
/// While a default image cache object will be used if you prefer the extension methods of Kingfisher, you can create
/// your own cache object and configure its storages as your need. This class also provide an interface for you to set
/// the memory and disk storage config.
open class ImageCache {

    // MARK: Singleton
    /// The default `ImageCache` object. Kingfisher will use this cache for its related methods if there is no
    /// other cache specified. The `name` of this default cache is "default", and you should not use this name
    /// for any of your customize cache.
    public static let `default` = ImageCache(name: "default")

    // MARK: Public Properties
    /// The `MemoryStorage.Backend` object used in this cache. This storage holds loaded images in memory with a
    /// reasonable expire duration and a maximum memory usage. To modify the configuration of a storage, just set
    /// the storage `config` and its properties.
    public let memoryStorage: MemoryStorage.Backend<KFCrossPlatformImage>
    
    /// The `DiskStorage.Backend` object used in this cache. This storage stores loaded images in disk with a
    /// reasonable expire duration and a maximum disk usage. To modify the configuration of a storage, just set
    /// the storage `config` and its properties.
    public let diskStorage: DiskStorage.Backend<Data>
    
    private let ioQueue: DispatchQueue
    
    /// Closure that defines the disk cache path from a given path and cacheName.
    public typealias DiskCachePathClosure = (URL, String) -> URL

    // MARK: Initializers

    /// Creates an `ImageCache` from a customized `MemoryStorage` and `DiskStorage`.
    ///
    /// - Parameters:
    ///   - memoryStorage: The `MemoryStorage.Backend` object to use in the image cache.
    ///   - diskStorage: The `DiskStorage.Backend` object to use in the image cache.
    public init(
        memoryStorage: MemoryStorage.Backend<KFCrossPlatformImage>,
        diskStorage: DiskStorage.Backend<Data>)
    {
        self.memoryStorage = memoryStorage
        self.diskStorage = diskStorage
        let ioQueueName = "com.onevcat.Kingfisher.ImageCache.ioQueue.\(UUID().uuidString)"
        ioQueue = DispatchQueue(label: ioQueueName)

        let notifications: [(Notification.Name, Selector)]
        #if !os(macOS) && !os(watchOS)
        #if swift(>=4.2)
        notifications = [
            (UIApplication.didReceiveMemoryWarningNotification, #selector(clearMemoryCache)),
            (UIApplication.willTerminateNotification, #selector(cleanExpiredDiskCache)),
            (UIApplication.didEnterBackgroundNotification, #selector(backgroundCleanExpiredDiskCache))
        ]
        #else
        notifications = [
            (NSNotification.Name.UIApplicationDidReceiveMemoryWarning, #selector(clearMemoryCache)),
            (NSNotification.Name.UIApplicationWillTerminate, #selector(cleanExpiredDiskCache)),
            (NSNotification.Name.UIApplicationDidEnterBackground, #selector(backgroundCleanExpiredDiskCache))
        ]
        #endif
        #elseif os(macOS)
        notifications = [
            (NSApplication.willResignActiveNotification, #selector(cleanExpiredDiskCache)),
        ]
        #else
        notifications = []
        #endif
        notifications.forEach {
            NotificationCenter.default.addObserver(self, selector: $0.1, name: $0.0, object: nil)
        }
    }
    
    /// Creates an `ImageCache` with a given `name`. Both `MemoryStorage` and `DiskStorage` will be created
    /// with a default config based on the `name`.
    ///
    /// - Parameter name: The name of cache object. It is used to setup disk cache directories and IO queue.
    ///                   You should not use the same `name` for different caches, otherwise, the disk storage would
    ///                   be conflicting to each other. The `name` should not be an empty string.
    public convenience init(name: String) {
        try! self.init(name: name, cacheDirectoryURL: nil, diskCachePathClosure: nil)
    }

    /// Creates an `ImageCache` with a given `name`, cache directory `path`
    /// and a closure to modify the cache directory.
    ///
    /// - Parameters:
    ///   - name: The name of cache object. It is used to setup disk cache directories and IO queue.
    ///           You should not use the same `name` for different caches, otherwise, the disk storage would
    ///           be conflicting to each other.
    ///   - cacheDirectoryURL: Location of cache directory URL on disk. It will be internally pass to the
    ///                        initializer of `DiskStorage` as the disk cache directory. If `nil`, the cache
    ///                        directory under user domain mask will be used.
    ///   - diskCachePathClosure: Closure that takes in an optional initial path string and generates
    ///                           the final disk cache path. You could use it to fully customize your cache path.
    /// - Throws: An error that happens during image cache creating, such as unable to create a directory at the given
    ///           path.
    public convenience init(
        name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure? = nil) throws
    {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }

        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let costLimit = totalMemory / 4
        let memoryStorage = MemoryStorage.Backend<KFCrossPlatformImage>(config:
            .init(totalCostLimit: (costLimit > Int.max) ? Int.max : Int(costLimit)))

        var diskConfig = DiskStorage.Config(
            name: name,
            sizeLimit: 0,
            directory: cacheDirectoryURL
        )
        if let closure = diskCachePathClosure {
            diskConfig.cachePathBlock = closure
        }
        let diskStorage = try DiskStorage.Backend<Data>(config: diskConfig)
        diskConfig.cachePathBlock = nil

        self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Storing Images

    open func store(_ image: KFCrossPlatformImage,
                    original: Data? = nil,
                    forKey key: String,
                    options: KingfisherParsedOptionsInfo,
                    toDisk: Bool = true,
                    completionHandler: ((CacheStoreResult) -> Void)? = nil)
    {
        let identifier = options.processor.identifier
        let callbackQueue = options.callbackQueue
        
        let computedKey = key.computedKey(with: identifier)
        // Memory storage should not throw.
        memoryStorage.storeNoThrow(value: image, forKey: computedKey, expiration: options.memoryCacheExpiration)
        
        guard toDisk else {
            if let completionHandler = completionHandler {
                let result = CacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
                callbackQueue.execute { completionHandler(result) }
            }
            return
        }
        
        ioQueue.async {
            let serializer = options.cacheSerializer
            if let data = serializer.data(with: image, original: original) {
                self.syncStoreToDisk(
                    data,
                    forKey: key,
                    processorIdentifier: identifier,
                    callbackQueue: callbackQueue,
                    expiration: options.diskCacheExpiration,
                    completionHandler: completionHandler)
            } else {
                guard let completionHandler = completionHandler else { return }
                
                let diskError = KingfisherError.cacheError(
                    reason: .cannotSerializeImage(image: image, original: original, serializer: serializer))
                let result = CacheStoreResult(
                    memoryCacheResult: .success(()),
                    diskCacheResult: .failure(diskError))
                callbackQueue.execute { completionHandler(result) }
            }
        }
    }

    /// Stores an image to the cache.
    ///
    /// - Parameters:
    ///   - image: The image to be stored.
    ///   - original: The original data of the image. This value will be forwarded to the provided `serializer` for
    ///               further use. By default, Kingfisher uses a `DefaultCacheSerializer` to serialize the image to
    ///               data for caching in disk, it checks the image format based on `original` data to determine in
    ///               which image format should be used. For other types of `serializer`, it depends on their
    ///               implementation detail on how to use this original data.
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of processor being used for caching. If you are using a processor for the
    ///                 image, pass the identifier of processor to this parameter.
    ///   - serializer: The `CacheSerializer`
    ///   - toDisk: Whether this image should be cached to disk or not. If `false`, the image is only cached in memory.
    ///             Otherwise, it is cached in both memory storage and disk storage. Default is `true`.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.untouch`. For case
    ///                    that `toDisk` is `false`, a `.untouch` queue means `callbackQueue` will be invoked from the
    ///                    caller queue of this method. If `toDisk` is `true`, the `completionHandler` will be called
    ///                    from an internal file IO queue. To change this behavior, specify another `CallbackQueue`
    ///                    value.
    ///   - completionHandler: A closure which is invoked when the cache operation finishes.
    open func store(_ image: KFCrossPlatformImage,
                      original: Data? = nil,
                      forKey key: String,
                      processorIdentifier identifier: String = "",
                      cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
                      toDisk: Bool = true,
                      callbackQueue: CallbackQueue = .untouch,
                      completionHandler: ((CacheStoreResult) -> Void)? = nil)
    {
        struct TempProcessor: ImageProcessor {
            let identifier: String
            func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
                return nil
            }
        }
        
        let options = KingfisherParsedOptionsInfo([
            .processor(TempProcessor(identifier: identifier)),
            .cacheSerializer(serializer),
            .callbackQueue(callbackQueue)
        ])
        store(image, original: original, forKey: key, options: options,
              toDisk: toDisk, completionHandler: completionHandler)
    }
    
    open func storeToDisk(
        _ data: Data,
        forKey key: String,
        processorIdentifier identifier: String = "",
        expiration: StorageExpiration? = nil,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: ((CacheStoreResult) -> Void)? = nil)
    {
        ioQueue.async {
            self.syncStoreToDisk(
                data,
                forKey: key,
                processorIdentifier: identifier,
                callbackQueue: callbackQueue,
                expiration: expiration,
                completionHandler: completionHandler)
        }
    }
    
    private func syncStoreToDisk(
        _ data: Data,
        forKey key: String,
        processorIdentifier identifier: String = "",
        callbackQueue: CallbackQueue = .untouch,
        expiration: StorageExpiration? = nil,
        completionHandler: ((CacheStoreResult) -> Void)? = nil)
    {
        let computedKey = key.computedKey(with: identifier)
        let result: CacheStoreResult
        do {
            try self.diskStorage.store(value: data, forKey: computedKey, expiration: expiration)
            result = CacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
        } catch {
            let diskError: KingfisherError
            if let error = error as? KingfisherError {
                diskError = error
            } else {
                diskError = .cacheError(reason: .cannotConvertToData(object: data, error: error))
            }
            
            result = CacheStoreResult(
                memoryCacheResult: .success(()),
                diskCacheResult: .failure(diskError)
            )
        }
        if let completionHandler = completionHandler {
            callbackQueue.execute { completionHandler(result) }
        }
    }

    // MARK: Removing Images

    /// Removes the image for the given key from the cache.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of processor being used for caching. If you are using a processor for the
    ///                 image, pass the identifier of processor to this parameter.
    ///   - fromMemory: Whether this image should be removed from memory storage or not.
    ///                 If `false`, the image won't be removed from the memory storage. Default is `true`.
    ///   - fromDisk: Whether this image should be removed from disk storage or not.
    ///               If `false`, the image won't be removed from the disk storage. Default is `true`.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.untouch`.
    ///   - completionHandler: A closure which is invoked when the cache removing operation finishes.
    open func removeImage(forKey key: String,
                          processorIdentifier identifier: String = "",
                          fromMemory: Bool = true,
                          fromDisk: Bool = true,
                          callbackQueue: CallbackQueue = .untouch,
                          completionHandler: (() -> Void)? = nil)
    {
        let computedKey = key.computedKey(with: identifier)

        if fromMemory {
            try? memoryStorage.remove(forKey: computedKey)
        }
        
        if fromDisk {
            ioQueue.async{
                try? self.diskStorage.remove(forKey: computedKey)
                if let completionHandler = completionHandler {
                    callbackQueue.execute { completionHandler() }
                }
            }
        } else {
            if let completionHandler = completionHandler {
                callbackQueue.execute { completionHandler() }
            }
        }
    }

    func retrieveImage(forKey key: String,
                       options: KingfisherParsedOptionsInfo,
                       callbackQueue: CallbackQueue = .mainCurrentOrAsync,
                       completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?)
    {
        // No completion handler. No need to start working and early return.
        guard let completionHandler = completionHandler else { return }

        // Try to check the image from memory cache first.
        if let image = retrieveImageInMemoryCache(forKey: key, options: options) {
            let image = options.imageModifier?.modify(image) ?? image
            callbackQueue.execute { completionHandler(.success(.memory(image))) }
        } else if options.fromMemoryCacheOrRefresh {
            callbackQueue.execute { completionHandler(.success(.none)) }
        } else {

            // Begin to disk search.
            self.retrieveImageInDiskCache(forKey: key, options: options, callbackQueue: callbackQueue) {
                result in
                switch result {
                case .success(let image):

                    guard let image = image else {
                        // No image found in disk storage.
                        callbackQueue.execute { completionHandler(.success(.none)) }
                        return
                    }

                    let finalImage = options.imageModifier?.modify(image) ?? image
                    // Cache the disk image to memory.
                    // We are passing `false` to `toDisk`, the memory cache does not change
                    // callback queue, we can call `completionHandler` without another dispatch.
                    var cacheOptions = options
                    cacheOptions.callbackQueue = .untouch
                    self.store(
                        finalImage,
                        forKey: key,
                        options: cacheOptions,
                        toDisk: false)
                    {
                        _ in
                        callbackQueue.execute { completionHandler(.success(.disk(finalImage))) }
                    }
                case .failure(let error):
                    callbackQueue.execute { completionHandler(.failure(error)) }
                }
            }
        }
    }

    // MARK: Getting Images

    /// Gets an image for a given key from the cache, either from memory storage or disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `KingfisherOptionsInfo` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.mainCurrentOrAsync`.
    ///   - completionHandler: A closure which is invoked when the image getting operation finishes. If the
    ///                        image retrieving operation finishes without problem, an `ImageCacheResult` value
    ///                        will be sent to this closure as result. Otherwise, a `KingfisherError` result
    ///                        with detail failing reason will be sent.
    open func retrieveImage(forKey key: String,
                               options: KingfisherOptionsInfo? = nil,
                        callbackQueue: CallbackQueue = .mainCurrentOrAsync,
                     completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?)
    {
        retrieveImage(
            forKey: key,
            options: KingfisherParsedOptionsInfo(options),
            callbackQueue: callbackQueue,
            completionHandler: completionHandler)
    }

    func retrieveImageInMemoryCache(
        forKey key: String,
        options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
    {
        let computedKey = key.computedKey(with: options.processor.identifier)
        return memoryStorage.value(forKey: computedKey, extendingExpiration: options.memoryCacheAccessExtendingExpiration)
    }

    /// Gets an image for a given key from the memory storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `KingfisherOptionsInfo` options setting used for retrieving the image.
    /// - Returns: The image stored in memory cache, if exists and valid. Otherwise, if the image does not exist or
    ///            has already expired, `nil` is returned.
    open func retrieveImageInMemoryCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil) -> KFCrossPlatformImage?
    {
        return retrieveImageInMemoryCache(forKey: key, options: KingfisherParsedOptionsInfo(options))
    }

    func retrieveImageInDiskCache(
        forKey key: String,
        options: KingfisherParsedOptionsInfo,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: @escaping (Result<KFCrossPlatformImage?, KingfisherError>) -> Void)
    {
        let computedKey = key.computedKey(with: options.processor.identifier)
        let loadingQueue: CallbackQueue = options.loadDiskFileSynchronously ? .untouch : .dispatch(ioQueue)
        loadingQueue.execute {
            do {
                var image: KFCrossPlatformImage? = nil
                if let data = try self.diskStorage.value(forKey: computedKey, extendingExpiration: options.diskCacheAccessExtendingExpiration) {
                    image = options.cacheSerializer.image(with: data, options: options)
                }
                callbackQueue.execute { completionHandler(.success(image)) }
            } catch {
                if let error = error as? KingfisherError {
                    callbackQueue.execute { completionHandler(.failure(error)) }
                } else {
                    assertionFailure("The internal thrown error should be a `KingfisherError`.")
                }
            }
        }
    }
    
    /// Gets an image for a given key from the disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `KingfisherOptionsInfo` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.untouch`.
    ///   - completionHandler: A closure which is invoked when the operation finishes.
    open func retrieveImageInDiskCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: @escaping (Result<KFCrossPlatformImage?, KingfisherError>) -> Void)
    {
        retrieveImageInDiskCache(
            forKey: key,
            options: KingfisherParsedOptionsInfo(options),
            callbackQueue: callbackQueue,
            completionHandler: completionHandler)
    }

    // MARK: Cleaning
    /// Clears the memory & disk storage of this cache. This is an async operation.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    public func clearCache(completion handler: (() -> Void)? = nil) {
        clearMemoryCache()
        clearDiskCache(completion: handler)
    }
    
    /// Clears the memory storage of this cache.
    @objc public func clearMemoryCache() {
        try? memoryStorage.removeAll()
    }
    
    /// Clears the disk storage of this cache. This is an async operation.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    open func clearDiskCache(completion handler: (() -> Void)? = nil) {
        ioQueue.async {
            do {
                try self.diskStorage.removeAll()
            } catch _ { }
            if let handler = handler {
                DispatchQueue.main.async { handler() }
            }
        }
    }
    
    /// Clears the expired images from memory & disk storage. This is an async operation.
    open func cleanExpiredCache(completion handler: (() -> Void)? = nil) {
        cleanExpiredMemoryCache()
        cleanExpiredDiskCache(completion: handler)
    }

    /// Clears the expired images from disk storage.
    open func cleanExpiredMemoryCache() {
        memoryStorage.removeExpired()
    }
    
    /// Clears the expired images from disk storage. This is an async operation.
    @objc func cleanExpiredDiskCache() {
        cleanExpiredDiskCache(completion: nil)
    }

    /// Clears the expired images from disk storage. This is an async operation.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    open func cleanExpiredDiskCache(completion handler: (() -> Void)? = nil) {
        ioQueue.async {
            do {
                var removed: [URL] = []
                let removedExpired = try self.diskStorage.removeExpiredValues()
                removed.append(contentsOf: removedExpired)

                let removedSizeExceeded = try self.diskStorage.removeSizeExceededValues()
                removed.append(contentsOf: removedSizeExceeded)

                if !removed.isEmpty {
                    DispatchQueue.main.async {
                        let cleanedHashes = removed.map { $0.lastPathComponent }
                        NotificationCenter.default.post(
                            name: .KingfisherDidCleanDiskCache,
                            object: self,
                            userInfo: [KingfisherDiskCacheCleanedHashKey: cleanedHashes])
                    }
                }

                if let handler = handler {
                    DispatchQueue.main.async { handler() }
                }
            } catch {}
        }
    }

#if !os(macOS) && !os(watchOS)
    /// Clears the expired images from disk storage when app is in background. This is an async operation.
    /// In most cases, you should not call this method explicitly.
    /// It will be called automatically when `UIApplicationDidEnterBackgroundNotification` received.
    @objc public func backgroundCleanExpiredDiskCache() {
        // if 'sharedApplication()' is unavailable, then return
        guard let sharedApplication = KingfisherWrapper<UIApplication>.shared else { return }

        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            #if swift(>=4.2)
            task = UIBackgroundTaskIdentifier.invalid
            #else
            task = UIBackgroundTaskInvalid
            #endif
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

    // MARK: Image Cache State

    /// Returns the cache type for a given `key` and `identifier` combination.
    /// This method is used for checking whether an image is cached in current cache.
    /// It also provides information on which kind of cache can it be found in the return value.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DefaultImageProcessor.default`.
    /// - Returns: A `CacheType` instance which indicates the cache status.
    ///            `.none` means the image is not in cache or it is already expired.
    open func imageCachedType(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> CacheType
    {
        let computedKey = key.computedKey(with: identifier)
        if memoryStorage.isCached(forKey: computedKey) { return .memory }
        if diskStorage.isCached(forKey: computedKey) { return .disk }
        return .none
    }
    
    /// Returns whether the file exists in cache for a given `key` and `identifier` combination.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DefaultImageProcessor.default`.
    /// - Returns: A `Bool` which indicates whether a cache could match the given `key` and `identifier` combination.
    ///
    /// - Note:
    /// The return value does not contain information about from which kind of storage the cache matches.
    /// To get the information about cache type according `CacheType`,
    /// use `imageCachedType(forKey:processorIdentifier:)` instead.
    public func isCached(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> Bool
    {
        return imageCachedType(forKey: key, processorIdentifier: identifier).cached
    }
    
    /// Gets the hash used as cache file name for the key.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DefaultImageProcessor.default`.
    /// - Returns: The hash which is used as the cache file name.
    ///
    /// - Note:
    /// By default, for a given combination of `key` and `identifier`, `ImageCache` will use the value
    /// returned by this method as the cache file name. You can use this value to check and match cache file
    /// if you need.
    open func hash(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> String
    {
        let computedKey = key.computedKey(with: identifier)
        return diskStorage.cacheFileName(forKey: computedKey)
    }
    
    /// Calculates the size taken by the disk storage.
    /// It is the total file size of all cached files in the `diskStorage` on disk in bytes.
    ///
    /// - Parameter handler: Called with the size calculating finishes. This closure is invoked from the main queue.
    open func calculateDiskStorageSize(completion handler: @escaping ((Result<UInt, KingfisherError>) -> Void)) {
        ioQueue.async {
            do {
                let size = try self.diskStorage.totalSize()
                DispatchQueue.main.async { handler(.success(size)) }
            } catch {
                if let error = error as? KingfisherError {
                    DispatchQueue.main.async { handler(.failure(error)) }
                } else {
                    assertionFailure("The internal thrown error should be a `KingfisherError`.")
                }
                
            }
        }
    }
    
    /// Gets the cache path for the key.
    /// It is useful for projects with web view or anyone that needs access to the local file path.
    ///
    /// i.e. Replacing the `<img src='path_for_key'>` tag in your HTML.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DefaultImageProcessor.default`.
    /// - Returns: The disk path of cached image under the given `key` and `identifier`.
    ///
    /// - Note:
    /// This method does not guarantee there is an image already cached in the returned path. It just gives your
    /// the path that the image should be, if it exists in disk storage.
    ///
    /// You could use `isCached(forKey:)` method to check whether the image is cached under that key in disk.
    open func cachePath(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> String
    {
        let computedKey = key.computedKey(with: identifier)
        return diskStorage.cacheFileURL(forKey: computedKey).path
    }
}

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

#if !os(macOS) && !os(watchOS)
// MARK: - For App Extensions
extension UIApplication: KingfisherCompatible { }
extension KingfisherWrapper where Base: UIApplication {
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

extension ImageCache {

    /// Creates an `ImageCache` with a given `name`, cache directory `path`
    /// and a closure to modify the cache directory.
    ///
    /// - Parameters:
    ///   - name: The name of cache object. It is used to setup disk cache directories and IO queue.
    ///           You should not use the same `name` for different caches, otherwise, the disk storage would
    ///           be conflicting to each other.
    ///   - path: Location of cache URL on disk. It will be internally pass to the initializer of `DiskStorage` as the
    ///           disk cache directory.
    ///   - diskCachePathClosure: Closure that takes in an optional initial path string and generates
    ///                           the final disk cache path. You could use it to fully customize your cache path.
    /// - Throws: An error that happens during image cache creating, such as unable to create a directory at the given
    ///           path.
    @available(*, deprecated, message: "Use `init(name:cacheDirectoryURL:diskCachePathClosure:)` instead",
    renamed: "init(name:cacheDirectoryURL:diskCachePathClosure:)")
    public convenience init(
        name: String,
        path: String?,
        diskCachePathClosure: DiskCachePathClosure? = nil) throws
    {
        let directoryURL = path.flatMap { URL(string: $0) }
        try self.init(name: name, cacheDirectoryURL: directoryURL, diskCachePathClosure: diskCachePathClosure)
    }
}
