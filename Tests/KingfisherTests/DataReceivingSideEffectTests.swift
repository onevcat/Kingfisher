//
//  DataReceivingSideEffectTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 2019/05/15.
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

class DataReceivingSideEffectTests: XCTestCase {

    var manager: KingfisherManager!

    func testSessionDataTaskMutableDataGetterDoesNotShareStorage() {
        let url = URL(string: "https://example.com/image.png")!
        let urlTask = URLSession(configuration: .ephemeral).dataTask(with: url)
        let task = SessionDataTask(task: urlTask)

        // Use a large buffer to avoid inline Data storage, making COW storage sharing observable.
        task.didReceiveData(Data(repeating: 0x11, count: 1024 * 1024))

        let snapshot = task.mutableData
        let secondSnapshot = task.mutableData

        XCTAssertEqual(snapshot.count, secondSnapshot.count)
        XCTAssertNotEqual(
            storageAddress(of: snapshot),
            storageAddress(of: secondSnapshot),
            "mutableData should return an independent Data copy instead of sharing the internal COW storage."
        )
    }

    func testSessionDataTaskSharedDataIsZeroCopyAndUnaffectedByLaterAppends() {
        let url = URL(string: "https://example.com/image.png")!
        let urlTask = URLSession(configuration: .ephemeral).dataTask(with: url)
        let task = SessionDataTask(task: urlTask)

        let received = Data(repeating: 0x22, count: 1024 * 1024)
        task.didReceiveData(received)

        // Zero-copy: repeated reads share the internal COW storage instead of allocating copies.
        let first = task.sharedData
        let second = task.sharedData
        XCTAssertEqual(
            storageAddress(of: first),
            storageAddress(of: second),
            "sharedData should share the internal COW storage without allocating a copy."
        )

        // COW safety: a later append must not mutate a previously returned value.
        task.didReceiveData(Data([0x33]))
        XCTAssertEqual(first, received)
        XCTAssertEqual(task.sharedData.count, received.count + 1)
    }

    private func storageAddress(of data: Data) -> UInt {
        data.withUnsafeBytes { buffer in
            UInt(bitPattern: buffer.baseAddress!)
        }
    }

    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let uuid = UUID()
        let downloader = ImageDownloader(name: "test.manager.\(uuid.uuidString)")
        let cache = ImageCache(name: "test.cache.\(uuid.uuidString)")

        manager = KingfisherManager(downloader: downloader, cache: cache)
    }

    override func tearDown() {
        clearStubs(afterCancelling: manager)
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }

    func xtestDataReceivingSideEffectBlockCanBeCalled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingStub()

        let options: KingfisherOptionsInfo = [/*.onDataReceived([receiver]),*/ .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) {
            result in
            XCTAssertTrue(receiver.called.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func xtestDataReceivingSideEffectBlockCanBeCalledButNotApply() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingNotApplyStub()

        let options: KingfisherOptionsInfo = [/*.onDataReceived([receiver]),*/ .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) {
            result in
            XCTAssertTrue(receiver.called.value)
            XCTAssertFalse(receiver.applied.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}

class DataReceivingStub: DataReceivingSideEffect, @unchecked Sendable {
    var called = LockIsolated(false)
    var onShouldApply: () -> Bool = { return true }
    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {
        self.called.setValue(true)
    }
}

class DataReceivingNotApplyStub: DataReceivingSideEffect, @unchecked Sendable {

    var called = LockIsolated(false)
    var applied = LockIsolated(false)

    var onShouldApply: () -> Bool = { return false }

    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {
        called.setValue(true)
        if onShouldApply() {
            applied.setValue(true)
        }
    }
}
