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

    func testSessionDataTaskMutableDataSnapshotIsIndependentOfLaterMutations() {
        let url = URL(string: "https://example.com/image.png")!
        let urlTask = URLSession(configuration: .ephemeral).dataTask(with: url)
        let task = SessionDataTask(task: urlTask)
        let received = Data(repeating: 0x11, count: 1024 * 1024)
        task.didReceiveData(received)

        var snapshot = task.mutableData
        let secondSnapshot = task.mutableData
        snapshot[0] = 0x22

        XCTAssertEqual(secondSnapshot, received)
        XCTAssertEqual(task.mutableData, received)

        task.didReceiveData(Data([0x33]))
        XCTAssertEqual(snapshot.count, received.count)
        XCTAssertEqual(snapshot[0], 0x22)
        XCTAssertEqual(secondSnapshot, received)
        XCTAssertEqual(task.mutableData, received + Data([0x33]))
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

    func testDataReceivingSideEffectBlockCanBeCalled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingStub()

        let options: KingfisherOptionsInfo = [.onDataReceived([receiver]), .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) {
            result in
            XCTAssertTrue(receiver.called.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDataReceivingSideEffectBlockCanBeCalledButNotApply() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingNotApplyStub()

        let options: KingfisherOptionsInfo = [.onDataReceived([receiver]), .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) {
            result in
            XCTAssertTrue(receiver.called.value)
            XCTAssertFalse(receiver.applied.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testAnyDataReceivingSideEffectClosureInvocation() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let invoked = LockIsolated(false)
        let receivedData = LockIsolated(Data())

        let effect = AnyDataReceivingSideEffect { session, task, data in
            invoked.setValue(true)
            receivedData.withValue { $0.append(data) }
        }

        let options: KingfisherOptionsInfo = [.onDataReceived([effect]), .waitForCache]
        KingfisherManager.shared.retrieveImage(with: url, options: options) { result in
            XCTAssertTrue(invoked.value)
            XCTAssertEqual(receivedData.value.count, testImageData.count)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testMultipleDataReceivingSideEffectsConcatenate() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver1 = DataReceivingStub()
        let receiver2 = DataReceivingStub()

        let options: KingfisherOptionsInfo = [
            .onDataReceived([receiver1]),
            .onDataReceived([receiver2]),
            .waitForCache
        ]
        KingfisherManager.shared.retrieveImage(with: url, options: options) { result in
            XCTAssertTrue(receiver1.called.value)
            XCTAssertTrue(receiver2.called.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    @MainActor
    func testKFOptionSetterOnDataReceivedFluentBuilders() {
        let url = testURLs[0]
        let receiver1 = DataReceivingStub()
        let receiver2 = DataReceivingStub()

        // Setting array
        let builder1 = KF.url(url).onDataReceived([receiver1])
        XCTAssertEqual(builder1.options.onDataReceived?.count, 1)

        // Appending single side effect
        let builder2 = builder1.onDataReceived(receiver2)
        XCTAssertEqual(builder2.options.onDataReceived?.count, 2)

        // Appending closure
        let builder3 = builder2.onDataReceived { session, task, data in }
        XCTAssertEqual(builder3.options.onDataReceived?.count, 3)

        // Resetting to nil
        let builder4 = builder3.onDataReceived(nil)
        XCTAssertNil(builder4.options.onDataReceived)
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
