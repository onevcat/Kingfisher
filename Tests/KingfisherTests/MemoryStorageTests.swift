//
//  MemoryStorageTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/11/12.
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

import XCTest
@testable import Kingfisher

extension Int {
    public var cacheCost: Int {
        return 1
    }
}

extension Int: @retroactive CacheCostCalculable { }

class MemoryStorageTests: XCTestCase {

    var storage: MemoryStorage.Backend<Int>!

    override func setUp() {
        super.setUp()
        let config = MemoryStorage.Config(totalCostLimit: 3)
        storage = MemoryStorage.Backend(config: config)
    }

    override func tearDown() {
        storage = nil
        super.tearDown()
    }

    func testConfigSettingStorage() {
        XCTAssertEqual(storage.config.totalCostLimit, 3)
        XCTAssertEqual(storage.storage.totalCostLimit, 3)
        storage.config = MemoryStorage.Config(totalCostLimit: 10)
        XCTAssertEqual(storage.config.totalCostLimit, 10)
        XCTAssertEqual(storage.storage.totalCostLimit, 10)

        storage.config.countLimit = 100
        XCTAssertEqual(storage.config.countLimit, 100)
        XCTAssertEqual(storage.storage.countLimit, 100)
    }

    func testStoreAndGetValue() {
        XCTAssertFalse(storage.isCached(forKey: "1"))

        storage.store(value: 1, forKey: "1")

        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertEqual(storage.value(forKey: "1"), 1)
    }

    func testStoreValueOverwriting() {
        storage.store(value: 1, forKey: "1")
        XCTAssertEqual(storage.value(forKey: "1"), 1)

        storage.store(value: 100, forKey: "1")
        XCTAssertEqual(storage.value(forKey: "1"), 100)
    }

    func testRemoveValue() {
        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1")
        XCTAssertTrue(storage.isCached(forKey: "1"))

        storage.remove(forKey: "1")
        XCTAssertFalse(storage.isCached(forKey: "1"))
    }

    func testRemoveAllValues() {
        storage.store(value: 1, forKey: "1")
        storage.store(value: 2, forKey: "2")
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertTrue(storage.isCached(forKey: "2"))

        storage.removeAll()
        XCTAssertFalse(storage.isCached(forKey: "1"))
        XCTAssertFalse(storage.isCached(forKey: "2"))
    }

    func testTotalCacheCost() {
        XCTAssertEqual(storage.totalCacheCost(), 0)

        storage.store(value: 1, forKey: "1")
        storage.store(value: 2, forKey: "2")
        storage.store(value: 3, forKey: "3")
        XCTAssertEqual(storage.totalCacheCost(), 3)

        storage.remove(forKey: "2")
        XCTAssertEqual(storage.totalCacheCost(), 2)

        storage.removeAll()
        XCTAssertEqual(storage.totalCacheCost(), 0)
    }

    func testStoreWithExpiration() {
        let clock = TestClock().install()

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))

        XCTAssertFalse(storage.isCached(forKey: "2"))
        storage.store(value: 2, forKey: "2")
        XCTAssertTrue(storage.isCached(forKey: "2"))

        clock.advance(by: 2)
        XCTAssertFalse(storage.isCached(forKey: "1"))
        XCTAssertTrue(storage.isCached(forKey: "2"))

        // But the object is still in underlying cache.
        XCTAssertNotNil(storage.storage.object(forKey: "1"))
    }

    func testStoreWithConfigExpiration() {
        let clock = TestClock().install()
        storage.config.expiration = .seconds(1)

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1")
        XCTAssertTrue(storage.isCached(forKey: "1"))

        clock.advance(by: 2)
        XCTAssertFalse(storage.isCached(forKey: "1"))
        // But the object is still in underlying cache.
        XCTAssertNotNil(storage.storage.object(forKey: "1"))
    }
    
    func testStoreWithExpirationExtending() {
        let clock = TestClock().install()

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))

        clock.advance(by: 0.5)
        let expirationDate1 = storage.storage.object(forKey: "1")?.estimatedExpiration
        XCTAssertNotNil(expirationDate1)

        // Request for the object to extend it's expiration date
        let obj = storage.value(forKey: "1", extendingExpiration: .expirationTime(.seconds(5)))
        XCTAssertNotNil(obj)

        let expirationDate2 = storage.storage.object(forKey: "1")?.estimatedExpiration
        XCTAssertEqual(expirationDate1, clock.now.addingTimeInterval(0.5))
        XCTAssertEqual(expirationDate2, clock.now.addingTimeInterval(5))
    }
    
    func testStoreWithExpirationNotExtending() {
        let clock = TestClock().install()

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))

        clock.advance(by: 0.5)
        let expirationDate1 = storage.storage.object(forKey: "1")?.estimatedExpiration
        XCTAssertNotNil(expirationDate1)

        // Request for the object without extending it's expiration date
        let obj = storage.value(forKey: "1", extendingExpiration: .none)
        XCTAssertNotNil(obj)

        let expirationDate2 = storage.storage.object(forKey: "1")?.estimatedExpiration
        XCTAssertEqual(expirationDate1, expirationDate2)
    }

    func testRemoveExpired() {
        let clock = TestClock().install()

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))

        clock.advance(by: 2)
        XCTAssertFalse(storage.isCached(forKey: "1"))

        // But the object is still in underlying cache.
        XCTAssertNotNil(storage.storage.object(forKey: "1"))
        storage.removeExpired()

        // It should be removed now.
        XCTAssertNil(storage.storage.object(forKey: "1"))
    }

    func testTotalCacheCostIncludesExpiredValues() {
        let clock = TestClock().install()

        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        storage.store(value: 2, forKey: "2")

        clock.advance(by: 2)
        XCTAssertEqual(storage.totalCacheCost(), 2)
        XCTAssertNotNil(storage.storage.object(forKey: "1"))
    }

    func testExtendExpirationByAccessing() {
        let clock = TestClock().install()

        storage.store(value: 1, forKey: "1", expiration: .seconds(5))

        clock.advance(by: 3)
        // This extends the expiration to (3 + 5) from initially created.
        XCTAssertEqual(storage.value(forKey: "1"), 1)

        clock.advance(by: 3)
        // Accessing `isCached` does not extend expiration
        XCTAssertTrue(storage.isCached(forKey: "1"))

        clock.advance(by: 3)
        XCTAssertFalse(storage.isCached(forKey: "1"))
    }

    func testTotalCacheCostExcludesEvictedValues() {
        storage.store(value: 1, forKey: "1")
        storage.store(value: 2, forKey: "2")
        XCTAssertEqual(storage.totalCacheCost(), 2)

        // Simulate a system eviction: `NSCache` may drop an object on its own (its cost/count limits are
        // advisory), and the tracking `keys` set is not updated until the next `removeExpired()` runs. An evicted
        // object no longer occupies memory, so its still-present key must contribute nothing to the total.
        storage.storage.removeObject(forKey: "1")
        XCTAssertEqual(storage.totalCacheCost(), 1)
    }

    func testAutoCleanExpiredMemory() {
        let exp = expectation(description: #function)
        let clock = TestClock().install()
        let config = MemoryStorage.Config(totalCostLimit: 3, cleanInterval: 0.05)
        storage = MemoryStorage.Backend(config: config)

        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertEqual(self.storage.keys.count, 1)

        clock.advance(by: 2)
        // The clean timer runs on real time. Wait for it to remove the expired value.
        poll(until: { self.storage.keys.isEmpty }) {
            XCTAssertFalse(self.storage.isCached(forKey: "1"))
            XCTAssertNil(self.storage.storage.object(forKey: "1"))
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStorageObject() {
        let clock = TestClock().install()
        let start = clock.now
        let obj = MemoryStorage.StorageObject(1, expiration: .seconds(1))
        XCTAssertEqual(obj.value, 1)
        XCTAssertEqual(obj.estimatedExpiration, start.addingTimeInterval(1))

        clock.advance(by: 0.5)
        obj.extendExpiration()
        XCTAssertEqual(obj.estimatedExpiration, start.addingTimeInterval(1.5))
    }
}
