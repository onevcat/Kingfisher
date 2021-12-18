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

/// Represents a set of conception related to storage which stores a certain type of value in memory.
/// This is a namespace for the memory storage types. A `Backend` with a certain `Config` will be used to describe the
/// storage. See these composed types for more information.
public enum MemoryStorage {

    /// Represents a storage which stores a certain type of value in memory. It provides fast access,
    /// but limited storing size. The stored value type needs to conform to `CacheCostCalculable`,
    /// and its `cacheCost` will be used to determine the cost of size for the cache item.
    ///
    /// You can config a `MemoryStorage.Backend` in its initializer by passing a `MemoryStorage.Config` value.
    /// or modifying the `config` property after it being created. The backend of `MemoryStorage` has
    /// upper limitation on cost size in memory and item count. All items in the storage has an expiration
    /// date. When retrieved, if the target item is already expired, it will be recognized as it does not
    /// exist in the storage. The `MemoryStorage` also contains a scheduled self clean task, to evict expired
    /// items from memory.
    public class Backend<T: CacheCostCalculable> {
        let storage = NSCache<NSString, StorageObject<T>>()

        // Keys trackes the objects once inside the storage. For object removing triggered by user, the corresponding
        // key would be also removed. However, for the object removing triggered by cache rule/policy of system, the
        // key will be remained there until next `removeExpired` happens.
        //
        // Breaking the strict tracking could save additional locking behaviors.
        // See https://github.com/onevcat/Kingfisher/issues/1233
        var keys = Set<String>()

        private var cleanTimer: Timer? = nil
        private let lock = NSLock()

        /// The config used in this storage. It is a value you can set and
        /// use to config the storage in air.
        public var config: Config {
            didSet {
                storage.totalCostLimit = config.totalCostLimit
                storage.countLimit = config.countLimit
            }
        }

        /// Creates a `MemoryStorage` with a given `config`.
        ///
        /// - Parameter config: The config used to create the storage. It determines the max size limitation,
        ///                     default expiration setting and more.
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
                if object.estimatedExpiration.isPast {
                    storage.removeObject(forKey: nsKey)
                    keys.remove(key)
                }
            }
        }

        /// Stores a value to the storage under the specified key and expiration policy.
        /// - Parameters:
        ///   - value: The value to be stored.
        ///   - key: The key to which the `value` will be stored.
        ///   - expiration: The expiration policy used by this store action.
        /// - Throws: No error will
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
                object = BackgroundKeepingStorageObject(value, key: key, expiration: expiration)
            } else {
                object = StorageObject(value, key: key, expiration: expiration)
            }
            storage.setObject(object, forKey: key as NSString, cost: value.cacheCost)
            keys.insert(key)
        }
        
        /// Gets a value from the storage.
        ///
        /// - Parameters:
        ///   - key: The cache key of value.
        ///   - extendingExpiration: The expiration policy used by this getting action.
        /// - Returns: The value under `key` if it is valid and found in the storage. Otherwise, `nil`.
        public func value(forKey key: String, extendingExpiration: ExpirationExtending = .cacheTime) -> T? {
            guard let object = storage.object(forKey: key as NSString) else {
                return nil
            }
            if object.expired {
                return nil
            }
            object.extendExpiration(extendingExpiration)
            return object.value
        }

        /// Whether there is valid cached data under a given key.
        /// - Parameter key: The cache key of value.
        /// - Returns: If there is valid data under the key, `true`. Otherwise, `false`.
        public func isCached(forKey key: String) -> Bool {
            guard let _ = value(forKey: key, extendingExpiration: .none) else {
                return false
            }
            return true
        }

        /// Removes a value from a specified key.
        /// - Parameter key: The cache key of value.
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
    /// Represents the config used in a `MemoryStorage`.
    public struct Config {

        /// Total cost limit of the storage in bytes.
        public var totalCostLimit: Int

        /// The item count limit of the memory storage.
        public var countLimit: Int = .max

        /// The `StorageExpiration` used in this memory storage. Default is `.seconds(300)`,
        /// means that the memory cache would expire in 5 minutes.
        public var expiration: StorageExpiration = .seconds(300)

        /// The time interval between the storage do clean work for swiping expired items.
        public var cleanInterval: TimeInterval
        
        /// Whether the newly added items to memory cache should be purged when the app goes to background.
        ///
        /// By default, the cached items in memory will be purged as soon as the app goes to background to ensure
        /// least memory footprint. Enabling this would prevent this behavior and keep the items alive in cache even
        /// when your app is not in foreground anymore.
        ///
        /// Default is `false`. After setting `true`, only the newly added cache objects are affected. Existing
        /// objects which are already in the cache while this value was `false` will be still be purged when entering
        /// background.
        public var keepWhenEnteringBackground: Bool = false

        /// Creates a config from a given `totalCostLimit` value.
        ///
        /// - Parameters:
        ///   - totalCostLimit: Total cost limit of the storage in bytes.
        ///   - cleanInterval: The time interval between the storage do clean work for swiping expired items.
        ///                    Default is 120, means the auto eviction happens once per two minutes.
        ///
        /// - Note:
        /// Other members of `MemoryStorage.Config` will use their default values when created.
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
        let key: String
        
        private(set) var estimatedExpiration: Date
        
        init(_ value: T, key: String, expiration: StorageExpiration) {
            self.value = value
            self.key = key
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
        
        var expired: Bool {
            return estimatedExpiration.isPast
        }
    }
}
