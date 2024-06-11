//
//  MemoryStorage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
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

import Foundation

/// Represents the concepts related to storage that stores a specific type of value in memory.
///
/// This serves as a namespace for memory storage types. A ``MemoryStorage/Backend`` with a particular
/// ``MemoryStorage/Config`` is used to define the storage.
/// 
/// Refer to these composite types for further details.
public enum MemoryStorage {

    /// Represents a storage that stores a specific type of value in memory.
    ///
    /// It provides fast access but has a limited storage size. The stored value type needs to conform to the
    /// ``CacheCostCalculable`` protocol, and its ``CacheCostCalculable/cacheCost`` will be used to determine the cost
    /// of the cache item's size in the memory.
    ///
    /// You can configure a ``MemoryStorage/Backend`` in its ``MemoryStorage/Backend/init(config:)`` method by passing
    /// a ``MemoryStorage/Config`` value or by modifying the ``MemoryStorage/Backend/config`` property after it's
    /// created.
    ///
    /// The ``MemoryStorage`` backend has an upper limit on the total cost size in memory and item count. All items in
    /// the storage have an expiration date. When retrieved, if the target item is already expired, it will be
    /// recognized as if it does not exist in the storage.
    ///
    /// The `MemoryStorage` also includes a scheduled self-cleaning task to evict expired items from memory.
    ///
    /// > This class is thready safe.
    public class Backend<T: CacheCostCalculable>: @unchecked Sendable {
        
        let storage = NSCache<NSString, StorageObject<T>>()

        // Keys track the objects once inside the storage.
        //
        // For object removing triggered by user, the corresponding key would be also removed. However, for the object
        // removing triggered by cache rule/policy of system, the key will be remained there until next `removeExpired`
        // happens.
        //
        // Breaking the strict tracking could save additional locking behaviors and improve the cache performance.
        // See https://github.com/onevcat/Kingfisher/issues/1233
        var keys = Set<String>()

        private var cleanTimer: Timer? = nil
        private let lock = NSLock()

        /// The configuration used in this storage.
        ///
        /// It is a value you can set and use to configure the storage as needed.
        public var config: Config {
            didSet {
                storage.totalCostLimit = config.totalCostLimit
                storage.countLimit = config.countLimit
            }
        }

        /// Creates a ``MemoryStorage/Backend`` with a given ``MemoryStorage/Config`` value.
        ///
        /// - Parameter config: The configuration used to create the storage. It determines the maximum size limitation,
        /// default expiration settings, and more.
        public init(config: Config) {
            self.config = config
            storage.totalCostLimit = config.totalCostLimit
            storage.countLimit = config.countLimit

            cleanTimer = .scheduledTimer(withTimeInterval: config.cleanInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.removeExpired()
            }
        }

        /// Removes the expired values from the storage.
        public func removeExpired() {
            lock.lock()
            defer { lock.unlock() }
            for key in keys {
                let nsKey = key as NSString
                guard let object = storage.object(forKey: nsKey) else {
                    // This could happen if the object is moved by cache `totalCostLimit` or `countLimit` rule.
                    // We didn't remove the key yet until now, since we do not want to introduce additional lock.
                    // See https://github.com/onevcat/Kingfisher/issues/1233
                    keys.remove(key)
                    continue
                }
                if object.isExpired {
                    storage.removeObject(forKey: nsKey)
                    keys.remove(key)
                }
            }
        }
        
        /// Stores a value in the storage under the specified key and expiration policy.
        ///
        /// - Parameters:
        ///   - value: The value to be stored.
        ///   - key: The key to which the `value` will be stored.
        ///   - expiration: The expiration policy used by this storage action.
        public func store(
            value: T,
            forKey key: String,
            expiration: StorageExpiration? = nil)
        {
            storeNoThrow(value: value, forKey: key, expiration: expiration)
        }

        // The no throw version for storing value in cache. Kingfisher knows the detail so it
        // could use this version to make syntax simpler internally.
        func storeNoThrow(
            value: T,
            forKey key: String,
            expiration: StorageExpiration? = nil)
        {
            lock.lock()
            defer { lock.unlock() }
            let expiration = expiration ?? config.expiration
            // The expiration indicates that already expired, no need to store.
            guard !expiration.isExpired else { return }
            
            let object: StorageObject<T>
            if config.keepWhenEnteringBackground {
                object = BackgroundKeepingStorageObject(value, expiration: expiration)
            } else {
                object = StorageObject(value, expiration: expiration)
            }
            storage.setObject(object, forKey: key as NSString, cost: value.cacheCost)
            keys.insert(key)
        }
        
        /// Gets a value from the storage.
        ///
        /// - Parameters:
        ///   - key: The cache key of the value.
        ///   - extendingExpiration: The expiration policy used by this retrieval action.
        /// - Returns: The value under `key` if it is valid and found in the storage. Otherwise, `nil`.
        public func value(forKey key: String, extendingExpiration: ExpirationExtending = .cacheTime) -> T? {
            guard let object = storage.object(forKey: key as NSString) else {
                return nil
            }
            if object.isExpired {
                return nil
            }
            object.extendExpiration(extendingExpiration)
            return object.value
        }

        /// Determines whether there is valid cached data under a given key.
        ///
        /// - Parameter key: The cache key of the value.
        /// - Returns: `true` if there is valid data under the key, otherwise `false`.
        public func isCached(forKey key: String) -> Bool {
            guard let _ = value(forKey: key, extendingExpiration: .none) else {
                return false
            }
            return true
        }

        /// Removes a value from a specified key.
        ///
        /// - Parameter key: The cache key of the value.
        public func remove(forKey key: String) {
            lock.lock()
            defer { lock.unlock() }
            storage.removeObject(forKey: key as NSString)
            keys.remove(key)
        }

        /// Removes all values in this storage.
        public func removeAll() {
            lock.lock()
            defer { lock.unlock() }
            storage.removeAllObjects()
            keys.removeAll()
        }
    }
}

extension MemoryStorage {
    /// Represents the configuration used in a ``MemoryStorage/Backend``.
    public struct Config {

        /// The total cost limit of the storage.
        ///
        /// This counts up the value of ``CacheCostCalculable/cacheCost``. If adding this object to the cache causes
        /// the cache’s total cost to rise above totalCostLimit, the cache may automatically evict objects until its
        /// total cost falls below this value.
        public var totalCostLimit: Int

        /// The item count limit of the memory storage.
        ///
        /// The default value is `Int.max`, which means no hard limitation of the item count.
        public var countLimit: Int = .max

        /// The ``StorageExpiration`` used in this memory storage.
        ///
        /// The default is `.seconds(300)`, which means that the memory cache will expire in 5 minutes if not accessed.
        public var expiration: StorageExpiration = .seconds(300)

        /// The time interval between the storage performing cleaning work for sweeping expired items.
        public var cleanInterval: TimeInterval
        
        /// Determine whether newly added items to memory cache should be purged when the app goes to the background.
        ///
        /// By default, cached items in memory will be purged as soon as the app goes to the background to ensure a
        /// minimal memory footprint. Enabling this prevents this behavior and keeps the items alive in the cache even
        /// when your app is not in the foreground.
        ///
        /// The default value is `false`. After setting it to `true`, only newly added cache objects are affected. 
        /// Existing objects that were already in the cache while this value was `false` will still be purged when the
        /// app enters the background.
        public var keepWhenEnteringBackground: Bool = false

        /// Creates a configuration from a given ``MemoryStorage/Config/totalCostLimit`` value and a
        ///  ``MemoryStorage/Config/cleanInterval``.
        ///
        /// - Parameters:
        ///   - totalCostLimit: The total cost limit of the storage in bytes.
        ///   - cleanInterval: The time interval between the storage performing cleaning work for sweeping expired items.
        ///   The default is 120, which means auto eviction happens once every two minutes.
        ///
        /// > Other properties of the ``MemoryStorage/Config`` will use their default values when created.
        public init(totalCostLimit: Int, cleanInterval: TimeInterval = 120) {
            self.totalCostLimit = totalCostLimit
            self.cleanInterval = cleanInterval
        }
    }
}

extension MemoryStorage {
    
    class BackgroundKeepingStorageObject<T>: StorageObject<T>, NSDiscardableContent {
        var accessing = true
        func beginContentAccess() -> Bool {
            if value != nil {
                accessing = true
            } else {
                accessing = false
            }
            return accessing
        }
        
        func endContentAccess() {
            accessing = false
        }
        
        func discardContentIfPossible() {
            value = nil
        }
        
        func isContentDiscarded() -> Bool {
            return value == nil
        }
    }
    
    class StorageObject<T> {
        var value: T?
        let expiration: StorageExpiration
        
        private(set) var estimatedExpiration: Date
        
        init(_ value: T, expiration: StorageExpiration) {
            self.value = value
            self.expiration = expiration
            
            self.estimatedExpiration = expiration.estimatedExpirationSinceNow
        }

        func extendExpiration(_ extendingExpiration: ExpirationExtending = .cacheTime) {
            switch extendingExpiration {
            case .none:
                return
            case .cacheTime:
                self.estimatedExpiration = expiration.estimatedExpirationSinceNow
            case .expirationTime(let expirationTime):
                self.estimatedExpiration = expirationTime.estimatedExpirationSinceNow
            }
        }
        
        var isExpired: Bool {
            return estimatedExpiration.isPast
        }
    }
}
