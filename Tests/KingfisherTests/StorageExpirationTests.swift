//
//  StorageExpirationTests.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/12.
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

class StorageExpirationTests: XCTestCase {

    func testExpirationNever() {
        let e = StorageExpiration.never
        XCTAssertEqual(e.estimatedExpirationSinceNow, .distantFuture)
        XCTAssertEqual(e.timeInterval, .infinity)
        XCTAssertFalse(e.isExpired)
    }

    func testExpirationSeconds() {
        let e = StorageExpiration.seconds(100)
        XCTAssertEqual(
            e.estimatedExpirationSinceNow.timeIntervalSince1970,
            Date().timeIntervalSince1970 + 100,
            accuracy: 0.1)
        XCTAssertEqual(e.timeInterval, 100)
        XCTAssertFalse(e.isExpired)
    }
    
    func testExpirationDays() {
        let e = StorageExpiration.days(1)
        let oneDayInSecond: TimeInterval = 60 * 60 * 24
        XCTAssertEqual(
            e.estimatedExpirationSinceNow.timeIntervalSince1970,
            Date().timeIntervalSince1970 + oneDayInSecond,
            accuracy: 0.1)
        XCTAssertEqual(e.timeInterval, oneDayInSecond, accuracy: 0.1)
        XCTAssertFalse(e.isExpired)
    }
    
    func testExpirationDate() {
        let oneDayInSecond: TimeInterval = 60 * 60 * 24
        let targetDate = Date().addingTimeInterval(oneDayInSecond)
        let e = StorageExpiration.date(targetDate)
        XCTAssertEqual(
            e.estimatedExpirationSinceNow.timeIntervalSince1970,
            Date().timeIntervalSince1970 + oneDayInSecond,
            accuracy: 0.1)
        XCTAssertEqual(e.timeInterval, oneDayInSecond, accuracy: 0.1)
        XCTAssertFalse(e.isExpired)
    }
    
    func testAlreadyExpired() {
        let e = StorageExpiration.expired
        XCTAssertTrue(e.isExpired)
        XCTAssertEqual(e.estimatedExpirationSinceNow, .distantPast)
    }
}
