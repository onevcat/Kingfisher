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

public class MemoryStorage<T: CacheCostCalculatable>: Storage {

    public struct Config {
        public var totalCostLimit: Int
        public var countLimit: Int = .max
        public var expiration: StorageExpiration = .seconds(300)
        public var cleanInterval: TimeInterval = 120

        public init(totalCostLimit: Int) {
            self.totalCostLimit = totalCostLimit
        }
    }

    let storage = NSCache<NSString, StorageObject<T>>()
    var keys = Set<String>()

    var cleanTimer: Timer? = nil
    let lock = NSLock()

    public var config: Config {
        didSet {
            storage.totalCostLimit = config.totalCostLimit
            storage.countLimit = config.countLimit
        }
    }

    init(config: Config) {
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

    func store(
        value: T,
        forKey key: String,
        expiration: StorageExpiration? = nil) throws
    {
        lock.lock()
        defer { lock.unlock() }
        let object = StorageObject(value, expiration: expiration ?? config.expiration)
        storage.setObject(object, forKey: key as NSString, cost: value.cost)
        keys.insert(key)
    }

    func value(forKey key: String) throws -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard let object = storage.object(forKey: key as NSString) else {
            return nil
        }
        guard object.estimatedExpiration.isFuture else {
            return nil
        }

        object.extendExpiration()
        return object.value
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
