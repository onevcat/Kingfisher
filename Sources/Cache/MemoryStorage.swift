//
//  MemoryStorage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
//
//  Copyright (c) 2018年 Wei Wang <onevcat@gmail.com>
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

/// Represents a storage which stores a certain type of value in memory. It provides fast access,
/// but limited storing size. The stored value type needs to conform to `CacheCostCalculatable`,
/// and its `cacheCost` will be used to determine the cost of size for the cache item.
///
/// You can config a `MemoryStorage` in its initializer by passing a `MemoryStorage.Config` value.
/// or modifying the `config` property after it being created. The backend of `MemoryStorage` has
/// upper limitaion on cost size in memory and item count. All items in the storage has an expiration
/// date. When retrieved, if the target item is already expired, it will be recognized as it does not
/// exist in the storage. The `MemoryStorage` also contains a scheduled self clean task, to evict expired
/// items from memory.
public class MemoryStorage<T: CacheCostCalculatable>: Storage {

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
        /// Default is 120, means the auto eviction happens once per two minutes.
        public var cleanInterval: TimeInterval = 120

        /// Creates a config from a given `totalCostLimit` value.
        ///
        /// - Parameter totalCostLimit: Total cost limit of the storage in bytes.
        ///
        /// - Note:
        /// Other members of `MemoryStorage.Config` will use their default values when created.
        public init(totalCostLimit: Int) {
            self.totalCostLimit = totalCostLimit
        }
    }

    let storage = NSCache<NSString, StorageObject<T>>()
    var keys = Set<String>()

    var cleanTimer: Timer? = nil
    let lock = NSLock()

    /// The config used in this storage. It is a setable value and you can
    /// use it to config the storage in air.
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

    func removeExpired() {
        lock.lock()
        defer { lock.unlock() }
        for key in keys {
            let nsKey = key as NSString
            guard let object = storage.object(forKey: nsKey) else {
                keys.remove(key)
                continue
            }
            if object.estimatedExpiration.isPast {
                storage.removeObject(forKey: nsKey)
                keys.remove(key)
            }
        }
    }

    // Storing in memory will not throw. It is just for meeting protocol requirement and
    // forwarding to no throwing method.
    func store(
        value: T,
        forKey key: String,
        expiration: StorageExpiration? = nil) throws
    {
        storeNoThrow(value: value, forKey: key, expiration: expiration)
    }

    func storeNoThrow(
        value: T,
        forKey key: String,
        expiration: StorageExpiration? = nil)
    {
        lock.lock()
        defer { lock.unlock() }
        let object = StorageObject(value, expiration: expiration ?? config.expiration)
        storage.setObject(object, forKey: key as NSString, cost: value.cacheCost)
        keys.insert(key)
    }

    func value(forKey key: String) throws -> T? {
        return try value(forKey: key, extendingExpiration: true)
    }
    
    func value(forKey key: String, extendingExpiration: Bool) throws -> T? {
        guard let object = storage.object(forKey: key as NSString) else {
            return nil
        }
        guard object.estimatedExpiration.isFuture else {
            return nil
        }
        
        if extendingExpiration { object.extendExpiration() }
        return object.value
    }

    func isCached(forKey key: String) -> Bool {
        do {
            guard let _ = try value(forKey: key, extendingExpiration: false) else {
                return false
            }
            return true
        } catch {
            return false
        }
    }

    func remove(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeObject(forKey: key as NSString)
        keys.remove(key)
    }

    func removeAll() throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAllObjects()
        keys.removeAll()
    }
}
