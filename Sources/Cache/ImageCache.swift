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
    
    /// This notification is sent when the disk cache is cleared, either due to expired cached files or the total size
    /// exceeding the maximum allowed size.
    ///
    /// The `object` of this notification is the ``ImageCache`` object that sends the notification. You can retrieve a
    /// list of removed hashes (files) by accessing the array under the ``KingfisherDiskCacheCleanedHashKey`` key in
    /// the `userInfo` of the received notification object. By checking the array, you can determine the hash codes
    /// of the removed files.
    /// 
    /// > Invoking the `clearDiskCache` method manually will not trigger this notification.
    public static let KingfisherDidCleanDiskCache =
        Notification.Name("com.onevcat.Kingfisher.KingfisherDidCleanDiskCache")
}

/// Key for array of cleaned hashes in `userInfo` of `KingfisherDidCleanDiskCache` notification.
public let KingfisherDiskCacheCleanedHashKey = "com.onevcat.Kingfisher.cleanedHash"

/// The type of cache for a cached image.
public enum CacheType: Sendable {
    /// The image is not yet cached when retrieving it.
    ///
    /// This indicates that the image was recently downloaded or generated rather than being retrieved from either
    /// memory or disk cache.
    case none
    
    /// The image is cached in memory and retrieved from there.
    case memory
    
    /// The image is cached in disk and retrieved from there.
    case disk
    
    /// Indicates whether the cache type represents the image is already cached or not.
    public var cached: Bool {
        switch self {
        case .memory, .disk: return true
        case .none: return false
        }
    }
}

/// Represents the result of the caching operation.
public struct CacheStoreResult: Sendable {
    
    /// The caching result for memory cache.
    ///
    /// Caching an image to memory will never fail.
    public let memoryCacheResult: Result<(), Never>
    
    /// The caching result for disk cache.
    ///
    /// If an error occurs during the caching operation, you can retrieve it from the `.failure` case of this value.
    /// Usually, the error contains a ``KingfisherError/CacheErrorReason``.
    public let diskCacheResult: Result<(), KingfisherError>
}

extension KFCrossPlatformImage: CacheCostCalculable {
    /// The cost of an image.
    ///
    /// It is an estimated size represented as a bitmap, measured in bytes of all pixels. A larger cost indicates that
    /// when cached in memory, it occupies more memory space. This cost contributes to the
    /// ``MemoryStorage/Config/countLimit``.
    public var cacheCost: Int { return kf.cost }
}

extension Data: DataTransformable {
    public func toData() throws -> Data {
        self
    }

    public static func fromData(_ data: Data) throws -> Data {
        data
    }

    public static let empty = Data()
}


/// Represents the result of the operation to retrieve an image from the cache.
public enum ImageCacheResult: Sendable {
    
    /// The image can be retrieved from the disk cache.
    case disk(KFCrossPlatformImage)
    
    /// The image can be retrieved from the memory cache.
    case memory(KFCrossPlatformImage)
    
    /// The image does not exist in the cache.
    case none
    
    /// Extracts the image from cache result. 
    ///
    /// It returns the associated `Image` value for ``ImageCacheResult/disk(_:)`` and ``ImageCacheResult/memory(_:)``
    /// case. For ``ImageCacheResult/none`` case, returns `nil`.
    public var image: KFCrossPlatformImage? {
        switch self {
        case .disk(let image): return image
        case .memory(let image): return image
        case .none: return nil
        }
    }
    
    /// Returns the corresponding ``CacheType`` value based on the result type of `self`.
    public var cacheType: CacheType {
        switch self {
        case .disk: return .disk
        case .memory: return .memory
        case .none: return .none
        }
    }
}

/// Represents a hybrid caching system composed of a ``MemoryStorage`` and a ``DiskStorage``.
///
/// ``ImageCache`` serves as a high-level abstraction for storing an image and its data in memory and on disk, as well
/// as retrieving them. You can define configurations for the memory cache backend and disk cache backend, and the the
/// unified methods to store images to the cache or retrieve images from either the memory cache or the disk cache.
///
/// > While a default image cache object will be used if you prefer the extension methods of Kingfisher, you can create
/// your own cache object and configure its storages according to your needs. This class also provides an interface for
/// configuring the memory and disk storage.
open class ImageCache: @unchecked Sendable {

    // MARK: Singleton
    /// The default ``ImageCache`` object.
    ///
    /// Kingfisher uses this value for its related methods if no other cache is specified. 
    ///
    /// > Warning: The `name` of this default cache is reserved as "default", and you should not use this name for any
    /// of your custom caches. Otherwise, different caches might become mixed up and corrupted.
    public static let `default` = ImageCache(name: "default")

    // MARK: Public Properties
    /// The ``MemoryStorage/Backend`` object for the memory cache used in this cache.
    ///
    /// This storage stores loaded images in memory with a reasonable expire duration and a maximum memory usage.
    ///
    /// > To modify the configuration of a storage, just set the storage ``MemoryStorage/Config`` and its properties.
    public let memoryStorage: MemoryStorage.Backend<KFCrossPlatformImage>
    
    /// The ``DiskStorage/Backend`` object for the disk cache used in this cache.
    ///
    /// This storage stores loaded images on disk with a reasonable expire duration and a maximum disk usage.
    ///
    /// > To modify the configuration of a storage, just set the storage ``DiskStorage/Config`` and its properties.
    public let diskStorage: DiskStorage.Backend<Data>
    
    private let ioQueue: DispatchQueue
    
    /// A closure that specifies the disk cache path based on a given path and the cache name.
    public typealias DiskCachePathClosure = @Sendable (URL, String) -> URL

    // MARK: Initializers

    /// Creates an ``ImageCache`` with a customized ``MemoryStorage`` and ``DiskStorage``.
    ///
    /// - Parameters:
    ///   - memoryStorage: The ``MemoryStorage/Backend`` object to be used in the image memory cache.
    ///   - diskStorage: The ``DiskStorage/Backend`` object to be used in the image disk cache.
    public init(
        memoryStorage: MemoryStorage.Backend<KFCrossPlatformImage>,
        diskStorage: DiskStorage.Backend<Data>)
    {
        self.memoryStorage = memoryStorage
        self.diskStorage = diskStorage
        let ioQueueName = "com.onevcat.Kingfisher.ImageCache.ioQueue.\(UUID().uuidString)"
        ioQueue = DispatchQueue(label: ioQueueName)

        Task { @MainActor in
            let notifications: [(Notification.Name, Selector)]
            #if !os(macOS) && !os(watchOS)
            notifications = [
                (UIApplication.didReceiveMemoryWarningNotification, #selector(clearMemoryCache)),
                (UIApplication.willTerminateNotification, #selector(cleanExpiredDiskCache)),
                (UIApplication.didEnterBackgroundNotification, #selector(backgroundCleanExpiredDiskCache))
            ]
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
    }
    
    /// Creates an ``ImageCache`` with a given `name`.
    ///
    /// Both the ``MemoryStorage`` and the ``DiskStorage`` will be created with a default configuration based on the `name`.
    ///
    /// - Parameter name: The name of the cache object. It is used to set up disk cache directories and IO queues. 
    /// You should not use the same `name` for different caches; otherwise, the disk storages would conflict with each
    /// other. The `name` should not be an empty string.
    ///
    /// > Warning: The `name` "default" is reserved to be used as the name of ``ImageCache/default`` in Kingfisher,
    /// and you should not use this name for any of your custom caches. Otherwise, different caches might become mixed
    /// up and corrupted.
    public convenience init(name: String) {
        self.init(noThrowName: name, cacheDirectoryURL: nil, diskCachePathClosure: nil)
    }

    /// Creates an ``ImageCache`` with a given `name`, the cache directory `path`, and a closure to modify the cache
    /// directory.
    ///
    /// - Parameters:
    ///   - name: The name of the cache object. It is used to set up disk cache directories and IO queues.
    /// You should not use the same `name` for different caches; otherwise, the disk storages would conflict with each
    /// other. The `name` should not be an empty string.
    ///   - cacheDirectoryURL: The location of the cache directory URL on disk. It will be passed internally to the 
    ///   initializer of the ``DiskStorage`` as the disk cache directory. If `nil`, the cache directory under the user
    ///   domain mask will be used.
    ///   - diskCachePathClosure: A closure that takes in an optional initial path string and generates the final disk 
    ///   cache path. You can use it to fully customize your cache path.
    /// - Throws: An error that occurs during the creation of the image cache, such as being unable to create a 
    /// directory at the given path.
    ///
    /// > Warning: The `name` "default" is reserved to be used as the name of ``ImageCache/default`` in Kingfisher,
    /// and you should not use this name for any of your custom caches. Otherwise, different caches might become mixed
    /// up and corrupted.
    public convenience init(
        name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure? = nil
    ) throws
    {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }

        let memoryStorage = ImageCache.createMemoryStorage()

        let config = ImageCache.createConfig(
            name: name, cacheDirectoryURL: cacheDirectoryURL, diskCachePathClosure: diskCachePathClosure
        )
        let diskStorage = try DiskStorage.Backend<Data>(config: config)
        self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
    }

    convenience init(
        noThrowName name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure?
    )
    {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }

        let memoryStorage = ImageCache.createMemoryStorage()

        let config = ImageCache.createConfig(
            name: name, cacheDirectoryURL: cacheDirectoryURL, diskCachePathClosure: diskCachePathClosure
        )
        let diskStorage = DiskStorage.Backend<Data>(noThrowConfig: config, creatingDirectory: true)
        self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
    }

    private static func createMemoryStorage() -> MemoryStorage.Backend<KFCrossPlatformImage> {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let costLimit = totalMemory / 4
        let memoryStorage = MemoryStorage.Backend<KFCrossPlatformImage>(config:
            .init(totalCostLimit: (costLimit > Int.max) ? Int.max : Int(costLimit)))
        return memoryStorage
    }

    private static func createConfig(
        name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure? = nil
    ) -> DiskStorage.Config
    {
        var diskConfig = DiskStorage.Config(
            name: name,
            sizeLimit: 0,
            directory: cacheDirectoryURL
        )
        if let closure = diskCachePathClosure {
            diskConfig.cachePathBlock = closure
        }
        return diskConfig
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Storing Images
    
    /// Stores an image to the cache.
    ///
    /// - Parameters:
    ///   - image: The image that to be stored.
    ///   - original: The original data of the image. This value will be forwarded to the provided `serializer` for
    ///   further use. By default, Kingfisher uses a ``DefaultCacheSerializer`` to serialize the image to data for
    ///   caching in disk. It checks the image format based on the `original` data to determine the appropriate image
    ///   format to use. For other types of `serializer`, it depends on their implementation details on how to use this
    ///   original data.
    ///   - key: The key used for caching the image.
    ///   - options: The options which contains configurations for caching the image.
    ///   - toDisk: Whether this image should be cached to disk or not. If `false`, the image is only cached in memory.
    ///   Otherwise, it is cached in both memory storage and disk storage. The default is `true`.
    ///   - completionHandler: A closure which is invoked when the cache operation finishes.
    open func store(
        _ image: KFCrossPlatformImage,
        original: Data? = nil,
        forKey key: String,
        options: KingfisherParsedOptionsInfo,
        toDisk: Bool = true,
        completionHandler: (@Sendable (CacheStoreResult) -> Void)? = nil
    )
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
                    writeOptions: options.diskStoreWriteOptions,
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

    /// Stores an image in the cache.
    ///
    /// - Parameters:
    ///   - image: The image to be stored.
    ///   - original: The original data of the image. This value will be forwarded to the provided `serializer` for 
    ///   further use. By default, Kingfisher uses a ``DefaultCacheSerializer`` to serialize the image to data for
    ///   caching in disk. It checks the image format based on the `original` data to determine the appropriate image
    ///   format to use. For other types of `serializer`, it depends on their implementation details on how to use this
    ///   original data.
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of the processor being used for caching. If you are using a processor for the 
    ///   image, pass the identifier of the processor to this parameter.
    ///   - serializer: The ``CacheSerializer`` used to convert the `image` and `original` to the data that will be
    ///   stored to disk. By default, the ``DefaultCacheSerializer/default`` will be used.
    ///   - toDisk: Whether this image should be cached to disk or not. If `false`, the image is only cached in memory.
    ///   Otherwise, it is cached in both memory storage and disk storage. The default is `true`.
    ///   - callbackQueue: The callback queue on which the `completionHandler` is invoked. The default is
    ///   ``CallbackQueue/untouch``. Under this default ``CallbackQueue/untouch`` queue, if `toDisk` is `false`, it
    ///   means the `completionHandler` will be invoked from the caller queue of this method; if `toDisk` is `true`,
    ///   the `completionHandler` will be called from an internal file IO queue. To change this behavior, specify
    ///   another ``CallbackQueue`` value.
    ///   - completionHandler: A closure that is invoked when the cache operation finishes.
    open func store(
        _ image: KFCrossPlatformImage,
        original: Data? = nil,
        forKey key: String,
        processorIdentifier identifier: String = "",
        cacheSerializer serializer: any CacheSerializer = DefaultCacheSerializer.default,
        toDisk: Bool = true,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: (@Sendable (CacheStoreResult) -> Void)? = nil
    )
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
        completionHandler: (@Sendable (CacheStoreResult) -> Void)? = nil)
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
        writeOptions: Data.WritingOptions = [],
        completionHandler: (@Sendable (CacheStoreResult) -> Void)? = nil)
    {
        let computedKey = key.computedKey(with: identifier)
        let result: CacheStoreResult
        do {
            try self.diskStorage.store(value: data, forKey: computedKey, expiration: expiration, writeOptions: writeOptions)
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
    ///   - identifier: The identifier of the processor being used for caching. If you are using a processor for the 
    ///   image, pass the identifier of the processor to this parameter.
    ///   - fromMemory: Whether this image should be removed from memory storage or not. If `false`, the image won't be 
    ///   removed from the memory storage. The default is `true`.
    ///   - fromDisk: Whether this image should be removed from the disk storage or not. If `false`, the image won't be
    ///    removed from the disk storage. The default is `true`.
    ///   - callbackQueue: The callback queue on which the `completionHandler` is invoked. The default is
    ///   ``CallbackQueue/untouch``.
    ///   - completionHandler: A closure that is invoked when the cache removal operation finishes.
    open func removeImage(
        forKey key: String,
        processorIdentifier identifier: String = "",
        fromMemory: Bool = true,
        fromDisk: Bool = true,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: (@Sendable () -> Void)? = nil
    )
    {
        removeImage(
            forKey: key,
            processorIdentifier: identifier,
            fromMemory: fromMemory,
            fromDisk: fromDisk,
            callbackQueue: callbackQueue,
            completionHandler: { _ in completionHandler?() } // This is a version which ignores error.
        )
    }
    
    func removeImage(forKey key: String,
                          processorIdentifier identifier: String = "",
                          fromMemory: Bool = true,
                          fromDisk: Bool = true,
                          callbackQueue: CallbackQueue = .untouch,
                          completionHandler: (@Sendable ((any Error)?) -> Void)? = nil)
    {
        let computedKey = key.computedKey(with: identifier)

        if fromMemory {
            memoryStorage.remove(forKey: computedKey)
        }
        
        @Sendable func callHandler(_ error: (any Error)?) {
            if let completionHandler = completionHandler {
                callbackQueue.execute { completionHandler(error) }
            }
        }
        
        if fromDisk {
            ioQueue.async{
                do {
                    try self.diskStorage.remove(forKey: computedKey)
                    callHandler(nil)
                } catch {
                    callHandler(error)
                }
            }
        } else {
            callHandler(nil)
        }
    }

    // MARK: Getting Images

    /// Retrieves an image for a given key from the cache, either from memory storage or disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherParsedOptionsInfo`` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which the `completionHandler` is invoked.
    ///   The default is ``CallbackQueue/mainCurrentOrAsync``.
    ///   - completionHandler: A closure that is invoked when the image retrieval operation finishes. If the image 
    ///   retrieval operation finishes without any problems, an ``ImageCacheResult`` value will be sent to this closure
    ///   as a result. Otherwise, a ``KingfisherError`` result with detailed failure reason will be sent.
    open func retrieveImage(
        forKey key: String,
        options: KingfisherParsedOptionsInfo,
        callbackQueue: CallbackQueue = .mainCurrentOrAsync,
        completionHandler: (@Sendable (Result<ImageCacheResult, KingfisherError>) -> Void)?)
    {
        // No completion handler. No need to start working and early return.
        guard let completionHandler = completionHandler else { return }

        // Try to check the image from memory cache first.
        if let image = retrieveImageInMemoryCache(forKey: key, options: options) {
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

                    // Cache the disk image to memory.
                    // We are passing `false` to `toDisk`, the memory cache does not change
                    // callback queue, we can call `completionHandler` without another dispatch.
                    var cacheOptions = options
                    cacheOptions.callbackQueue = .untouch
                    self.store(
                        image,
                        forKey: key,
                        options: cacheOptions,
                        toDisk: false)
                    {
                        _ in
                        callbackQueue.execute { completionHandler(.success(.disk(image))) }
                    }
                case .failure(let error):
                    callbackQueue.execute { completionHandler(.failure(error)) }
                }
            }
        }
    }

    /// Retrieves an image for a given key from the cache, either from memory storage or disk storage.
    ///
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherOptionsInfo`` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which the `completionHandler` is invoked.
    ///   The default is ``CallbackQueue/mainCurrentOrAsync``.
    ///   - completionHandler: A closure that is invoked when the image retrieval operation finishes. If the image
    ///   retrieval operation finishes without any problems, an ``ImageCacheResult`` value will be sent to this closure
    ///   as a result. Otherwise, a ``KingfisherError`` result with detailed failure reason will be sent.
    ///
    /// > This method is marked as `open` for compatibility purposes only. Do not override this method. Instead,
    /// override the version ``ImageCache/retrieveImage(forKey:options:callbackQueue:completionHandler:)-1m1bb`` that 
    /// accepts a ``KingfisherParsedOptionsInfo`` value.
    open func retrieveImage(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil,
        callbackQueue: CallbackQueue = .mainCurrentOrAsync,
        completionHandler: (@Sendable (Result<ImageCacheResult, KingfisherError>) -> Void)?
    )
    {
        retrieveImage(
            forKey: key,
            options: KingfisherParsedOptionsInfo(options),
            callbackQueue: callbackQueue,
            completionHandler: completionHandler)
    }

    /// Retrieves an image associated with a given key from the memory storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherParsedOptionsInfo`` options setting used to fetch the image.
    /// - Returns: The image stored in the memory cache if it exists and is valid. If the image does not exist or has
    ///  already expired, `nil` is returned.
    open func retrieveImageInMemoryCache(
        forKey key: String,
        options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
    {
        let computedKey = key.computedKey(with: options.processor.identifier)
        return memoryStorage.value(
            forKey: computedKey,
            extendingExpiration: options.memoryCacheAccessExtendingExpiration
        )
    }

    /// Retrieves an image associated with a given key from the memory storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherOptionsInfo`` options setting used to fetch the image.
    /// - Returns: The image stored in the memory cache if it exists and is valid. If the image does not exist or has
    ///  already expired, `nil` is returned.
    ///
    /// > This method is marked as `open` for compatibility purposes only. Do not override this method. Instead,
    /// override the version ``ImageCache/retrieveImageInMemoryCache(forKey:options:)-2xj0`` that accepts a
    ///  ``KingfisherParsedOptionsInfo`` value.
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
        completionHandler: @escaping @Sendable (Result<KFCrossPlatformImage?, KingfisherError>) -> Void)
    {
        let computedKey = key.computedKey(with: options.processor.identifier)
        let loadingQueue: CallbackQueue = options.loadDiskFileSynchronously ? .untouch : .dispatch(ioQueue)
        loadingQueue.execute {
            do {
                var image: KFCrossPlatformImage? = nil
                if let data = try self.diskStorage.value(forKey: computedKey, extendingExpiration: options.diskCacheAccessExtendingExpiration) {
                    image = options.cacheSerializer.image(with: data, options: options)
                }
                if options.backgroundDecode {
                    image = image?.kf.decoded(scale: options.scaleFactor)
                }
                callbackQueue.execute { [image] in completionHandler(.success(image)) }
            } catch let error as KingfisherError {
                callbackQueue.execute { completionHandler(.failure(error)) }
            } catch {
                assertionFailure("The internal thrown error should be a `KingfisherError`.")
            }
        }
    }
    
    /// Retrieves an image associated with a given key from the disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherOptionsInfo`` options setting used to fetch the image.
    ///   - callbackQueue: The callback queue on which the `completionHandler` is invoked.
    ///   The default is ``CallbackQueue/untouch``.
    ///   - completionHandler: A closure that is invoked when the operation is finished.
    open func retrieveImageInDiskCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: @escaping @Sendable (Result<KFCrossPlatformImage?, KingfisherError>) -> Void)
    {
        retrieveImageInDiskCache(
            forKey: key,
            options: KingfisherParsedOptionsInfo(options),
            callbackQueue: callbackQueue,
            completionHandler: completionHandler)
    }

    // MARK: Cleaning
    /// Clears the memory and disk storage of this cache. 
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the `handler` will be invoked.
    ///
    /// - Parameter handler: A closure that is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    public func clearCache(completion handler: (@Sendable () -> Void)? = nil) {
        clearMemoryCache()
        clearDiskCache(completion: handler)
    }
    
    /// Clears the memory storage of this cache.
    @objc public func clearMemoryCache() {
        memoryStorage.removeAll()
    }
    
    /// Clears the disk storage of this cache. 
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the `handler` will be invoked.
    ///
    /// - Parameter handler: A closure that is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    open func clearDiskCache(completion handler: (@Sendable () -> Void)? = nil) {
        ioQueue.async {
            do {
                try self.diskStorage.removeAll()
            } catch _ { }
            if let handler = handler {
                DispatchQueue.main.async { handler() }
            }
        }
    }
    
    /// Clears the expired images from the memory and disk storage.
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the `handler` will be invoked.
    open func cleanExpiredCache(completion handler: (@Sendable () -> Void)? = nil) {
        cleanExpiredMemoryCache()
        cleanExpiredDiskCache(completion: handler)
    }

    /// Clears the expired images from the memory storage.
    open func cleanExpiredMemoryCache() {
        memoryStorage.removeExpired()
    }
    
    /// Clears the expired images from disk storage. 
    ///
    /// This is an async operation.
    @objc func cleanExpiredDiskCache() {
        cleanExpiredDiskCache(completion: nil)
    }

    /// Clears the expired images from disk storage.
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the `handler` will be invoked.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    open func cleanExpiredDiskCache(completion handler: (@Sendable () -> Void)? = nil) {
        ioQueue.async {
            do {
                var removed: [URL] = []
                let removedExpired = try self.diskStorage.removeExpiredValues()
                removed.append(contentsOf: removedExpired)

                let removedSizeExceeded = try self.diskStorage.removeSizeExceededValues()
                removed.append(contentsOf: removedSizeExceeded)

                if !removed.isEmpty {
                    DispatchQueue.main.async { [removed] in
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
    /// Clears the expired images from disk storage when the app is in the background. 
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the `handler` will be invoked.
    ///
    /// In most cases, you should not call this method explicitly. It will be called automatically when a
    ///  `UIApplicationDidEnterBackgroundNotification` is received.
    @MainActor
    @objc public func backgroundCleanExpiredDiskCache() {
        // if 'sharedApplication()' is unavailable, then return
        guard let sharedApplication = KingfisherWrapper<UIApplication>.shared else { return }
        
        let taskActor = ActorBox<UIBackgroundTaskIdentifier?>(nil)
        
        let createdTask = sharedApplication.beginBackgroundTask(withName: "Kingfisher:backgroundCleanExpiredDiskCache") {
            Task {
                guard let bgTask = await taskActor.value, bgTask != .invalid else { return }
                sharedApplication.endBackgroundTask(bgTask)
                await taskActor.setValue(.invalid)
            }
        }
        
        cleanExpiredDiskCache {
            Task {
                guard let bgTask = await taskActor.value, bgTask != .invalid else { return }
                #if compiler(>=6)
                sharedApplication.endBackgroundTask(bgTask)
                #else
                await sharedApplication.endBackgroundTask(bgTask)
                #endif
                await taskActor.setValue(.invalid)
            }
        }
        
        Task {
            await taskActor.setValue(createdTask)
        }
    }
#endif

    // MARK: Image Cache State

    /// Returns the cache type for a given `key` and `identifier` combination.
    ///
    /// This method is used to check whether an image is cached in the current cache. It also provides information on
    ///  which kind of cache the image can be found in the return value.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The processor identifier used for this image. The default value is the
    ///    ``DefaultImageProcessor/identifier`` of the ``DefaultImageProcessor/default`` image processor.
    /// - Returns: A ``CacheType`` instance that indicates the cache status. ``CacheType/none`` indicates that the
    /// image is not in the cache or that it has already expired.
    open func imageCachedType(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> CacheType
    {
        let computedKey = key.computedKey(with: identifier)
        if memoryStorage.isCached(forKey: computedKey) { return .memory }
        if diskStorage.isCached(forKey: computedKey) { return .disk }
        return .none
    }
    
    /// Returns whether the file exists in the cache for a given `key` and `identifier` combination.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The processor identifier used for this image. The default value is the
    ///    ``DefaultImageProcessor/identifier`` of the ``DefaultImageProcessor/default`` image processor.
    /// - Returns: A `Bool` value indicating whether a cache matches the given `key` and `identifier` combination.
    ///
    /// > The return value does not contain information about the kind of storage the cache matches from.
    /// > To obtain information about the cache type according to ``CacheType``, use
    ///  ``ImageCache/imageCachedType(forKey:processorIdentifier:)`` instead.
    public func isCached(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> Bool
    {
        return imageCachedType(forKey: key, processorIdentifier: identifier).cached
    }
    
    /// Retrieves the hash used as the cache file name for the key.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The processor identifier used for this image. The default value is the
    ///    ``DefaultImageProcessor/identifier`` of the ``DefaultImageProcessor/default`` image processor.
    /// - Returns: The hash used as the cache file name.
    ///
    /// > By default, for a given combination of `key` and `identifier`, the ``ImageCache`` instance uses the value
    /// returned by this method as the cache file name. You can use this value to check and match the cache file if 
    /// needed.
    open func hash(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> String
    {
        let computedKey = key.computedKey(with: identifier)
        return diskStorage.cacheFileName(forKey: computedKey)
    }
    
    /// Calculates the size taken by the disk storage.
    ///
    /// It represents the total file size of all cached files in the ``ImageCache/diskStorage`` on disk in bytes.
    ///
    /// - Parameter handler: Called when the size calculation is complete. This closure is invoked from the main queue.
    open func calculateDiskStorageSize(
        completion handler: @escaping (@Sendable (Result<UInt, KingfisherError>) -> Void)
    ) {
        ioQueue.async {
            do {
                let size = try self.diskStorage.totalSize()
                DispatchQueue.main.async { handler(.success(size)) }
            } catch let error as KingfisherError {
                DispatchQueue.main.async { handler(.failure(error)) }
            } catch {
                assertionFailure("The internal thrown error should be a `KingfisherError`.")
            }
        }
    }
    
    /// Retrieves the cache path for the key.
    ///
    /// It is useful for projects with a web view or for anyone who needs access to the local file path.
    /// For instance, replacing the `<img src='path_for_key'>` tag in your HTML.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The processor identifier used for this image. The default value is the
    ///    ``DefaultImageProcessor/identifier`` of the ``DefaultImageProcessor/default`` image processor.
    /// - Returns: The disk path of the cached image under the given `key` and `identifier`.
    ///
    /// > This method does not guarantee that there is an image already cached in the returned path. It simply provides
    /// > the path where the image should be if it exists in the disk storage.
    /// >
    /// > You could use the ``ImageCache/isCached(forKey:processorIdentifier:)`` method to check whether the image is
    /// cached under that key on disk if necessary.
    open func cachePath(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier) -> String
    {
        let computedKey = key.computedKey(with: identifier)
        return diskStorage.cacheFileURL(forKey: computedKey).path
    }
    
    // MARK: - Concurrency
    
    /// Stores an image to the cache.
    ///
    /// - Parameters:
    ///   - image: The image that to be stored.
    ///   - original: The original data of the image. This value will be forwarded to the provided `serializer` for
    ///   further use. By default, Kingfisher uses a ``DefaultCacheSerializer`` to serialize the image to data for
    ///   caching in disk. It checks the image format based on the `original` data to determine the appropriate image
    ///   format to use. For other types of `serializer`, it depends on their implementation details on how to use this
    ///   original data.
    ///   - key: The key used for caching the image.
    ///   - options: The options which contains configurations for caching the image.
    ///   - toDisk: Whether this image should be cached to disk or not. If `false`, the image is only cached in memory.
    ///   Otherwise, it is cached in both memory storage and disk storage. The default is `true`.
    open func store(
        _ image: KFCrossPlatformImage,
        original: Data? = nil,
        forKey key: String,
        options: KingfisherParsedOptionsInfo,
        toDisk: Bool = true
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            store(image, original: original, forKey: key, options: options, toDisk: toDisk) {
                continuation.resume(with: $0.diskCacheResult)
            }
        }
    }
    
    /// Stores an image in the cache.
    ///
    /// - Parameters:
    ///   - image: The image to be stored.
    ///   - original: The original data of the image. This value will be forwarded to the provided `serializer` for
    ///   further use. By default, Kingfisher uses a ``DefaultCacheSerializer`` to serialize the image to data for
    ///   caching in disk. It checks the image format based on the `original` data to determine the appropriate image
    ///   format to use. For other types of `serializer`, it depends on their implementation details on how to use this
    ///   original data.
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of the processor being used for caching. If you are using a processor for the
    ///   image, pass the identifier of the processor to this parameter.
    ///   - serializer: The ``CacheSerializer`` used to convert the `image` and `original` to the data that will be
    ///   stored to disk. By default, the ``DefaultCacheSerializer/default`` will be used.
    ///   - toDisk: Whether this image should be cached to disk or not. If `false`, the image is only cached in memory.
    ///   Otherwise, it is cached in both memory storage and disk storage. The default is `true`.
    open func store(
        _ image: KFCrossPlatformImage,
        original: Data? = nil,
        forKey key: String,
        processorIdentifier identifier: String = "",
        cacheSerializer serializer: any CacheSerializer = DefaultCacheSerializer.default,
        toDisk: Bool = true
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            store(
                image,
                original: original,
                forKey: key,
                processorIdentifier: identifier,
                cacheSerializer: serializer,
                toDisk: toDisk) {
                    // Only `diskCacheResult` can fail
                    continuation.resume(with: $0.diskCacheResult)
                }
        }
    }
    
    open func storeToDisk(
        _ data: Data,
        forKey key: String,
        processorIdentifier identifier: String = "",
        expiration: StorageExpiration? = nil
    ) async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            storeToDisk(
                data,
                forKey: key,
                processorIdentifier: identifier,
                expiration: expiration) {
                    // Only `diskCacheResult` can fail
                    continuation.resume(with: $0.diskCacheResult)
                }
        }
    }
    
    /// Removes the image for the given key from the cache.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of the processor being used for caching. If you are using a processor for the
    ///   image, pass the identifier of the processor to this parameter.
    ///   - fromMemory: Whether this image should be removed from memory storage or not. If `false`, the image won't be
    ///   removed from the memory storage. The default is `true`.
    ///   - fromDisk: Whether this image should be removed from the disk storage or not. If `false`, the image won't be
    ///    removed from the disk storage. The default is `true`.
    open func removeImage(
        forKey key: String,
        processorIdentifier identifier: String = "",
        fromMemory: Bool = true,
        fromDisk: Bool = true
    ) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            removeImage(
                forKey: key,
                processorIdentifier: identifier,
                fromMemory: fromMemory,
                fromDisk: fromDisk,
                completionHandler: { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            )
        }
    }
    
    /// Retrieves an image for a given key from the cache, either from memory storage or disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherParsedOptionsInfo`` options setting used for retrieving the image.
    /// - Returns:
    /// If the image retrieving operation finishes without problem, an ``ImageCacheResult`` value.
    ///
    /// - Throws: An error of type ``KingfisherError``, if any error happens inside Kingfisher framework.
    open func retrieveImage(
        forKey key: String,
        options: KingfisherParsedOptionsInfo
    ) async throws -> ImageCacheResult {
        try await withCheckedThrowingContinuation { continuation in
            retrieveImage(forKey: key, options: options) { continuation.resume(with: $0) }
        }
    }
    
    /// Retrieves an image for a given key from the cache, either from memory storage or disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherOptionsInfo`` options setting used for retrieving the image.
    ///
    /// - Returns: If the image retrieving operation finishes without problem, an ``ImageCacheResult`` value.
    ///
    /// - Throws: An error of type ``KingfisherError``, if any error happens inside Kingfisher framework.
    ///
    /// > This method is marked as `open` for compatibility purposes only. Do not override this method. Instead,
    /// override the version ``ImageCache/retrieveImage(forKey:options:callbackQueue:completionHandler:)-1m1bb`` that
    /// accepts a ``KingfisherParsedOptionsInfo`` value.
    open func retrieveImage(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil
    ) async throws -> ImageCacheResult {
        try await withCheckedThrowingContinuation { continuation in
            retrieveImage(forKey: key, options: options) { continuation.resume(with: $0) }
        }
    }
    
    /// Retrieves an image associated with a given key from the disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The ``KingfisherOptionsInfo`` options setting used to fetch the image.
    ///
    /// - Returns: The image stored in the disk cache if it exists and is valid. If the image does not exist or has
    ///  already expired, `nil` is returned.
    ///
    /// - Returns: If the image retrieving operation finishes without problem, an ``ImageCacheResult`` value.
    ///
    /// - Throws: An error of type ``KingfisherError``, if any error happens inside Kingfisher framework.
    ///  ``KingfisherParsedOptionsInfo`` value.
    open func retrieveImageInDiskCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil
    ) async throws -> KFCrossPlatformImage? {
        try await withCheckedThrowingContinuation { continuation in
            retrieveImageInDiskCache(forKey: key, options: options) {
                continuation.resume(with: $0)
            }
        }
    }
    
    /// Clears the memory and disk storage of this cache.
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the whole method returns.
    open func clearCache() async {
        await withCheckedContinuation { continuation in
            clearCache { continuation.resume() }
        }
    }
    
    /// Clears the disk storage of this cache.
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the whole method returns.
    open func clearDiskCache() async {
        await withCheckedContinuation { continuation in
            clearDiskCache { continuation.resume() }
        }
    }
    
    /// Clears the expired images from the memory and disk storage.
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the whole method returns.
    open func cleanExpiredCache() async {
        await withCheckedContinuation { continuation in
            cleanExpiredCache { continuation.resume() }
        }
    }
    
    /// Clears the expired images from disk storage.
    ///
    /// This is an asynchronous operation. When the cache clearing operation finishes, the whole method returns.
    open func cleanExpiredDiskCache() async {
        await withCheckedContinuation { continuation in
            cleanExpiredDiskCache { continuation.resume() }
        }
    }
    
    /// Calculates the size taken by the disk storage.
    ///
    /// It represents the total file size of all cached files in the ``ImageCache/diskStorage`` on disk in bytes.
    open var diskStorageSize: UInt {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                calculateDiskStorageSize { continuation.resume(with: $0) }
            }
        }
    }
    
}

// Concurrency


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
