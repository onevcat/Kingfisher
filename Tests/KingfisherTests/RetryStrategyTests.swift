//
//  RetryStrategyTests.swift
//  Kingfisher
//
//  Created by onevcat on 2020/05/06.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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

class RetryStrategyTests: XCTestCase {

    var manager: KingfisherManager!

    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let uuid = UUID()
        let downloader = ImageDownloader(name: "test.manager.\(uuid.uuidString)")
        let cache = ImageCache(name: "test.cache.\(uuid.uuidString)")

        manager = KingfisherManager(downloader: downloader, cache: cache)
        manager.defaultOptions = [.waitForCache]
    }

    override func tearDownWithError() throws {
        LSNocilla.sharedInstance().clearStubs()
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        try super.tearDownWithError()
    }

    func testCanCreateRetryStrategy() {
        let strategy = DelayRetryStrategy(maxRetryCount: 10, retryInterval: .seconds(5))
        XCTAssertEqual(strategy.maxRetryCount, 10)
        XCTAssertEqual(strategy.retryInterval.timeInterval(for: 0), 5)
    }


    func testDelayRetryIntervalCalculating() {
        let secondInternal = DelayRetryStrategy.Interval.seconds(10)
        XCTAssertEqual(secondInternal.timeInterval(for: 0), 10)

        let accumulatedInternal = DelayRetryStrategy.Interval.accumulated(3)
        XCTAssertEqual(accumulatedInternal.timeInterval(for: 0), 3)
        XCTAssertEqual(accumulatedInternal.timeInterval(for: 1), 6)
        XCTAssertEqual(accumulatedInternal.timeInterval(for: 2), 9)
        XCTAssertEqual(accumulatedInternal.timeInterval(for: 3), 12)

        let customInternal = DelayRetryStrategy.Interval.custom { TimeInterval($0 * 2) }
        XCTAssertEqual(customInternal.timeInterval(for: 0), 0)
        XCTAssertEqual(customInternal.timeInterval(for: 1), 2)
        XCTAssertEqual(customInternal.timeInterval(for: 2), 4)
        XCTAssertEqual(customInternal.timeInterval(for: 3), 6)
    }

    func testKingfisherManagerCanRetry() {
        let exp = expectation(description: #function)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let retry = StubRetryStrategy()

        _ = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.retryStrategy(retry)],
            completionHandler: { result in
                XCTAssertEqual(retry.count, 3)
                exp.fulfill()
            }
        )
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDelayRetryStrategyExceededCount() {

        var blockCalled: [Bool] = []

        let source = Source.network(URL(string: "url")!)
        let retry = DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(0))

        let context1 = RetryContext(
            source: source,
            error: .responseError(reason: .URLSessionError(error: E()))
        )
        retry.retry(context: context1) { decision in
            guard case RetryDecision.retry(let userInfo) = decision else {
                XCTFail("The deicision should be `retry`")
                return
            }
            XCTAssertNil(userInfo)
            blockCalled.append(true)
        }

        let context2 = RetryContext(
            source: source,
            error: .responseError(reason: .URLSessionError(error: E()))
        )
        context2.increaseRetryCount() // 1
        context2.increaseRetryCount() // 2
        context2.increaseRetryCount() // 3
        retry.retry(context: context2) { decision in
            guard case RetryDecision.stop = decision else {
                XCTFail("The deicision should be `stop`")
                return
            }
            blockCalled.append(true)
        }

        XCTAssertEqual(blockCalled.count, 2)
        XCTAssertTrue(blockCalled.allSatisfy { $0 })
    }

    func testDelayRetryStrategyNotRetryForErrorReason() {
        // Only non-user cancel error && response error should be retied.
        var blockCalled: [Bool] = []
        let source = Source.network(URL(string: "url")!)
        let retry = DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(0))

        let task = URLSession.shared.dataTask(with: URL(string: "url")!)

        let context1 = RetryContext(
            source: source,
            error: .requestError(reason: .taskCancelled(task: .init(task: task), token: .init()))
        )
        retry.retry(context: context1) { decision in
            guard case RetryDecision.stop = decision else {
                XCTFail("The decision should be `stop` if user cancelled the task.")
                return
            }
            blockCalled.append(true)
        }

        let context2 = RetryContext(
            source: source,
            error: .cacheError(reason: .imageNotExisting(key: "any_key"))
        )
        retry.retry(context: context2) { decision in
            guard case RetryDecision.stop = decision else {
                XCTFail("The decision should be `stop` if the error type is not response error.")
                return
            }
            blockCalled.append(true)
        }

        XCTAssertEqual(blockCalled.count, 2)
        XCTAssertTrue(blockCalled.allSatisfy { $0 })
    }

    func testDelayRetryStrategyDidRetried() {
        var called = false
        let source = Source.network(URL(string: "url")!)
        let retry = DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(0))
        let context = RetryContext(
            source: source,
            error: .responseError(reason: .URLSessionError(error: E()))
        )
        retry.retry(context: context) { decision in
            guard case RetryDecision.retry = decision else {
                XCTFail("The decision should be `retry`.")
                return
            }
            called = true
        }

        XCTAssertTrue(called)
    }
}

private struct E: Error {}

class StubRetryStrategy: RetryStrategy {

    var count = 0

    func retry(context: RetryContext, retryHandler: @escaping (RetryDecision) -> Void) {

        if count == 0 {
            XCTAssertNil(context.userInfo)
        } else {
            XCTAssertEqual(context.userInfo as! Int, count)
        }

        XCTAssertEqual(context.retriedCount, count)

        count += 1
        if count == 3 {
            retryHandler(.stop)
        } else {
            retryHandler(.retry(userInfo: count))
        }
    }
}
