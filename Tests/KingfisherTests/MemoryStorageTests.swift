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

extension Int: CacheCostCalculable {
    public var cacheCost: Int {
        return 1
    }
}

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

    func testStoreValueOverwritting() {
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

    func testStoreWithExpiration() {
        let exp = expectation(description: #function)

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(0.1))
        XCTAssertTrue(storage.isCached(forKey: "1"))

        XCTAssertFalse(storage.isCached(forKey: "2"))
        storage.store(value: 2, forKey: "2")
        XCTAssertTrue(storage.isCached(forKey: "2"))

        delay(0.2) {
            XCTAssertFalse(self.storage.isCached(forKey: "1"))
            XCTAssertTrue(self.storage.isCached(forKey: "2"))

            // But the object is still in underlying cache.
            let obj = self.storage.storage.object(forKey: "1")
            XCTAssertNotNil(obj)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStoreWithConfigExpiration() {
        let exp = expectation(description: #function)

        storage.config.expiration = .seconds(0.1)

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1")
        XCTAssertTrue(storage.isCached(forKey: "1"))

        delay(0.2) {
            XCTAssertFalse(self.storage.isCached(forKey: "1"))
            // But the object is still in underlying cache.
            let obj = self.storage.storage.object(forKey: "1")
            XCTAssertNotNil(obj)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStoreWithExpirationExtending() {
        let exp = expectation(description: #function)
        
        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))
        
        delay(0.1) {
            let expirationDate1 = self.storage.storage.object(forKey: "1")?.estimatedExpiration
            XCTAssertNotNil(expirationDate1)
            
            // Request for the object to extend it's expiration date
            let obj = self.storage.value(forKey: "1", extendingExpiration: .expirationTime(.seconds(5)))
            XCTAssertNotNil(obj)
            
            let expirationDate2 = self.storage.storage.object(forKey: "1")?.estimatedExpiration
            XCTAssertNotNil(expirationDate2)
            
            XCTAssertNotEqual(expirationDate1!, expirationDate2!)
            XCTAssert(expirationDate1!.isPast(referenceDate: expirationDate2!))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testStoreWithExpirationNotExtending() {
        let exp = expectation(description: #function)
        
        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(1))
        XCTAssertTrue(storage.isCached(forKey: "1"))
        
        delay(0.1) {
            let expirationDate1 = self.storage.storage.object(forKey: "1")?.estimatedExpiration
            XCTAssertNotNil(expirationDate1)
            
            // Request for the object to extend it's expiration date
            let obj = self.storage.value(forKey: "1", extendingExpiration: .none)
            XCTAssertNotNil(obj)
            
            let expirationDate2 = self.storage.storage.object(forKey: "1")?.estimatedExpiration
            XCTAssertNotNil(expirationDate2)
            
            XCTAssertEqual(expirationDate1, expirationDate2)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRemoveExpired() {
        let exp = expectation(description: #function)

        XCTAssertFalse(storage.isCached(forKey: "1"))
        storage.store(value: 1, forKey: "1", expiration: .seconds(0.1))
        XCTAssertTrue(storage.isCached(forKey: "1"))

        delay(0.2) {
            XCTAssertFalse(self.storage.isCached(forKey: "1"))

            // But the object is still in underlying cache.
            XCTAssertNotNil(self.storage.storage.object(forKey: "1"))
            self.storage.removeExpired()

            // It should be removed now.
            XCTAssertNil(self.storage.storage.object(forKey: "1"))
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testExtendExpirationByAccessing() {
        let exp = expectation(description: #function)

        let expiration = StorageExpiration.seconds(0.5)
        storage.store(value: 1, forKey: "1", expiration: expiration)

        delay(0.3) {
            // This should extend the expiration to (0.3 + 0.5) from initially created.
            let v = self.storage.value(forKey: "1")
            XCTAssertEqual(v, 1)
        }

        delay(0.6) {
            // Accessing `isCached` does not extend expiration
            XCTAssertTrue(self.storage.isCached(forKey: "1"))
        }
        
        delay(1) {
            XCTAssertFalse(self.storage.isCached(forKey: "1"))
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testAutoCleanExpiredMemory() {
        let exp = expectation(description: #function)
        let config = MemoryStorage.Config(totalCostLimit: 3, cleanInterval: 0.1)
        storage = MemoryStorage.Backend(config: config)

        storage.store(value: 1, forKey: "1", expiration: .seconds(0.1))
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertEqual(self.storage.keys.count, 1)
        
        delay(0.2) {
            XCTAssertFalse(self.storage.isCached(forKey: "1"))
            XCTAssertNil(self.storage.storage.object(forKey: "1"))
            XCTAssertEqual(self.storage.keys.count, 0)
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStorageObject() {
        let now = Date()
        let obj = MemoryStorage.StorageObject(1, expiration: .seconds(1))
        XCTAssertEqual(obj.value, 1)

        XCTAssertEqual(
            obj.estimatedExpiration.timeIntervalSince1970,
            now.addingTimeInterval(1).timeIntervalSince1970,
            accuracy: 0.3)

        let exp = expectation(description: #function)
        delay(0.5) {
            obj.extendExpiration()
            XCTAssertEqual(
                obj.estimatedExpiration.timeIntervalSince1970,
                now.addingTimeInterval(1.5).timeIntervalSince1970,
                accuracy: 0.3)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
