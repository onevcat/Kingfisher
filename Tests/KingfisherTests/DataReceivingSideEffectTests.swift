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

        let invoked = LockIsolated(false)
        let receivedData = LockIsolated(Data())

        let options: KingfisherOptionsInfo = [
            .onDataReceived { task, data in
                invoked.setValue(true)
                receivedData.withValue { $0.append(data) }
            },
            .waitForCache
        ]
        manager.retrieveImage(with: url, options: options) { result in
            XCTAssertTrue(invoked.value)
            XCTAssertEqual(receivedData.value.count, testImageData.count)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDataReceivingSideEffectNotAppliedWhenStale() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let invoked = LockIsolated(false)

        let options: KingfisherOptionsInfo = [
            .onDataReceived { task, data in
                invoked.setValue(true)
            },
            .waitForCache
        ]
        manager.retrieveImage(
            with: .network(url),
            options: KingfisherParsedOptionsInfo(options),
            referenceTaskIdentifierChecker: { false }
        ) { result in
            XCTAssertFalse(invoked.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTwoRequestsSharingOneClosureWhenOneRequestBecomesStale() {
        let exp1 = expectation(description: "request 1 completed")
        let exp2 = expectation(description: "request 2 completed")
        let url = testURLs[0]
        let delayedResponse = delayedStub(url, data: testImageData, length: 123)

        let received = LockIsolated(Data())
        let sharedHandler: @Sendable (SessionDataTask, Data) -> Void = { _, data in
            received.withValue { $0.append(data) }
        }
        let options = KingfisherParsedOptionsInfo([.onDataReceived(sharedHandler), .forceRefresh])

        // Both requests use the same options and handler, and join one download.
        manager.retrieveImage(
            with: .network(url),
            options: options,
            referenceTaskIdentifierChecker: { true }
        ) { _ in exp1.fulfill() }
        manager.retrieveImage(
            with: .network(url),
            options: options,
            referenceTaskIdentifierChecker: { false }
        ) { _ in exp2.fulfill() }

        XCTAssertEqual(manager.downloader.sessionDelegate.task(for: url)?.callbacks.count, 2)
        _ = delayedResponse.go()
        waitForExpectations(timeout: 3, handler: nil)

        // Only the live request gets the data, exactly once. If the stale check were ignored, the data would be
        // received twice. If the two requests shared one stale check, it would not be received at all.
        XCTAssertEqual(received.value, testImageData)
    }

    func testLivePhotoDataReceivingSkipsStaleRequest() async throws {
        let url = LivePhotoURL.mov
        stub(url, data: testImageData)

        let called = LockIsolated(false)
        _ = try await manager.retrieveLivePhoto(
            with: LivePhotoSource(urls: [url]),
            options: [.onDataReceived { _, _ in called.setValue(true) }, .forceRefresh],
            referenceTaskIdentifierChecker: { false }
        )
        XCTAssertFalse(called.value)
    }

    func testLivePhotoDataReceivingCallsLiveRequest() async throws {
        let url = LivePhotoURL.mov
        stub(url, data: testImageData)

        let received = LockIsolated(Data())
        _ = try await manager.retrieveLivePhoto(
            with: LivePhotoSource(urls: [url]),
            options: [.onDataReceived { _, data in received.withValue { $0.append(data) } }, .forceRefresh],
            referenceTaskIdentifierChecker: { true }
        )
        XCTAssertEqual(received.value, testImageData)
    }

    func testDefaultOptionsHandlerIsAddedToRequestHandler() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let defaultCalled = LockIsolated(false)
        let requestCalled = LockIsolated(false)
        manager.defaultOptions = [.onDataReceived { _, _ in defaultCalled.setValue(true) }]
        manager.retrieveImage(
            with: url,
            options: [.onDataReceived { _, _ in requestCalled.setValue(true) }, .waitForCache]
        ) { _ in
            XCTAssertTrue(defaultCalled.value)
            XCTAssertTrue(requestCalled.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testMultipleOnDataReceivedHandlersConcatenate() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let invoked1 = LockIsolated(false)
        let invoked2 = LockIsolated(false)

        let options: KingfisherOptionsInfo = [
            .onDataReceived { _, _ in invoked1.setValue(true) },
            .onDataReceived { _, _ in invoked2.setValue(true) },
            .waitForCache
        ]
        manager.retrieveImage(with: url, options: options) { result in
            XCTAssertTrue(invoked1.value)
            XCTAssertTrue(invoked2.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCallbackDataReceivingSideEffectDirectInvocation() {
        let called = LockIsolated(false)
        let effect = CallbackDataReceivingSideEffect(onShouldApply: { true }) { task, data in
            called.setValue(true)
        }
        let url = URL(string: "https://example.com/image.png")!
        let urlTask = URLSession(configuration: .ephemeral).dataTask(with: url)
        let task = SessionDataTask(task: urlTask)
        effect.onDataReceived(URLSession.shared, task: task, data: Data([0x01]))
        XCTAssertTrue(called.value)
    }

    func testCallbackDataReceivingSideEffectSkipsWhenStale() {
        let called = LockIsolated(false)
        let effect = CallbackDataReceivingSideEffect(onShouldApply: { false }) { task, data in
            called.setValue(true)
        }
        let url = URL(string: "https://example.com/image.png")!
        let urlTask = URLSession(configuration: .ephemeral).dataTask(with: url)
        let task = SessionDataTask(task: urlTask)
        effect.onDataReceived(URLSession.shared, task: task, data: Data([0x01]))
        XCTAssertFalse(called.value)
    }

    @MainActor
    func testKFOptionSetterOnDataReceivedFluentBuilders() {
        let url = testURLs[0]

        let builder1 = KF.url(url).onDataReceived { task, data in }
        XCTAssertEqual(builder1.options.onDataReceivedHandlers.count, 1)

        let builder2 = builder1.onDataReceived { task, data in }
        XCTAssertEqual(builder2.options.onDataReceivedHandlers.count, 2)
    }

    func testInternalDataReceivingSideEffectStubCanBeCalled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let receiver = DataReceivingStub()

        var options = KingfisherParsedOptionsInfo([.waitForCache])
        options.onDataReceived = [receiver]
        manager.downloader.downloadImage(with: url, options: options) { result in
            XCTAssertTrue(receiver.called.value)
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
