//
//  NetworkStub.swift
//  Kingfisher
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
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
import XCTest

/// The error that `StubURLProtocol` reports for a request that matches no registered stub.
struct UnexpectedRequestError: Error, CustomStringConvertible {
    let url: URL?
    var description: String { "No network stub for \(url?.absoluteString ?? "<nil>")" }
}

/// A canned response for one URL.
///
/// A stub can hold its response. A held stub keeps every matching request open until `release()` is called. While a
/// request is held, no thread is blocked: the loader is parked and resumed later. A request that is cancelled while
/// held is stopped by `URLSession` and never receives the response.
///
/// A stub also records what happens to its requests, so a test can wait for a real event (the request reached the
/// network layer, the request was stopped) instead of a fixed interval.
final class NetworkStub: @unchecked Sendable {

    enum Response {
        case success(statusCode: Int, headers: [String: String], body: Data)
        case failure(any Error)
    }

    let url: URL
    let response: Response
    /// When not `nil`, a request must have these header values to match this stub.
    let requiredHeaders: [String: String]?

    private let lock = NSLock()
    private var isHeld: Bool
    private var parked: [StubURLProtocol.Loader] = []
    private var startedCount = 0
    private var stoppedCount = 0
    private var waiters: [Waiter] = []

    private struct Waiter {
        let condition: (_ started: Int, _ stopped: Int) -> Bool
        let resume: () -> Void
    }

    init(url: URL, response: Response, requiredHeaders: [String: String]?, held: Bool) {
        self.url = url
        self.response = response
        self.requiredHeaders = requiredHeaders
        self.isHeld = held
    }

    /// The number of requests that reached this stub.
    var requestCount: Int { lock.withLock { startedCount } }

    /// The number of requests that `URLSession` stopped before they completed (for example, by a cancellation).
    var stoppedRequestCount: Int { lock.withLock { stoppedCount } }

    /// Sends the response to all held requests, and to all later requests.
    func release() {
        let loaders: [StubURLProtocol.Loader] = lock.withLock {
            isHeld = false
            defer { parked.removeAll() }
            return parked
        }
        loaders.forEach { $0.respond(with: response) }
    }

    // MARK: Waiting for events

    /// Waits until `count` requests reached this stub.
    func waitForRequest(count: Int = 1, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) async {
        await wait(timeout: timeout, file: file, line: line, "\(count) request(s) for \(url)") { started, _ in
            started >= count
        }
    }

    /// Waits until `URLSession` stopped `count` requests of this stub before they completed.
    func waitForStoppedRequest(count: Int = 1, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) async {
        await wait(timeout: timeout, file: file, line: line, "\(count) stopped request(s) for \(url)") { _, stopped in
            stopped >= count
        }
    }

    /// Returns an expectation that is fulfilled when `count` requests reached this stub.
    func requestExpectation(count: Int = 1) -> XCTestExpectation {
        expectation(description: "\(count) request(s) for \(url)") { started, _ in started >= count }
    }

    /// Returns an expectation that is fulfilled when `URLSession` stopped `count` requests of this stub.
    func stoppedRequestExpectation(count: Int = 1) -> XCTestExpectation {
        expectation(description: "\(count) stopped request(s) for \(url)") { _, stopped in stopped >= count }
    }

    private func expectation(
        description: String,
        _ condition: @escaping (Int, Int) -> Bool
    ) -> XCTestExpectation {
        let exp = XCTestExpectation(description: description)
        addWaiter(condition) { exp.fulfill() }
        return exp
    }

    private func wait(
        timeout: TimeInterval,
        file: StaticString,
        line: UInt,
        _ description: String,
        _ condition: @escaping (Int, Int) -> Bool
    ) async {
        let exp = expectation(description: description, condition)
        let result = await XCTWaiter.fulfillment(of: [exp], timeout: timeout)
        if result != .completed {
            XCTFail("Timed out waiting for \(description)", file: file, line: line)
        }
    }

    private func addWaiter(_ condition: @escaping (Int, Int) -> Bool, resume: @escaping () -> Void) {
        let satisfied: Bool = lock.withLock {
            if condition(startedCount, stoppedCount) { return true }
            waiters.append(Waiter(condition: condition, resume: resume))
            return false
        }
        if satisfied { resume() }
    }

    // MARK: Called by StubURLProtocol

    func matches(_ request: URLRequest) -> Bool {
        guard request.url == url else { return false }
        guard let requiredHeaders else { return true }
        return requiredHeaders.allSatisfy { request.value(forHTTPHeaderField: $0.key) == $0.value }
    }

    fileprivate func start(_ loader: StubURLProtocol.Loader) {
        let shouldPark: Bool = lock.withLock {
            startedCount += 1
            if isHeld { parked.append(loader) }
            return isHeld
        }
        notifyWaiters()
        if !shouldPark {
            loader.respond(with: response)
        }
    }

    fileprivate func stop(_ loader: StubURLProtocol.Loader) {
        lock.withLock {
            stoppedCount += 1
            parked.removeAll { $0 === loader }
        }
        notifyWaiters()
    }

    private func notifyWaiters() {
        let ready: [Waiter] = lock.withLock {
            let (ready, rest) = waiters.reduce(into: ([Waiter](), [Waiter]())) { result, waiter in
                if waiter.condition(startedCount, stoppedCount) {
                    result.0.append(waiter)
                } else {
                    result.1.append(waiter)
                }
            }
            waiters = rest
            return ready
        }
        ready.forEach { $0.resume() }
    }
}

/// The registry of active network stubs.
///
/// `StubURLProtocol` cannot get a reference to the test that created its session, so the registry is global. Tests
/// run one at a time in a process. Call `reset()` in `tearDown` so stubs of one test do not leak into the next one.
enum NetworkStubRegistry {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var stubs: [NetworkStub] = []

    static func add(_ stub: NetworkStub) {
        lock.withLock {
            // A new stub for the same URL replaces the earlier one.
            stubs.removeAll { $0.url == stub.url && $0.requiredHeaders == stub.requiredHeaders }
            stubs.append(stub)
        }
    }

    static func stub(for request: URLRequest) -> NetworkStub? {
        lock.withLock { stubs.last { $0.matches(request) } }
    }

    /// Removes all stubs. Requests that are still held stay open until `URLSession` stops them.
    static func reset() {
        lock.withLock { stubs.removeAll() }
    }
}

/// A `URLProtocol` that answers requests from `NetworkStubRegistry`.
///
/// A session uses it when its configuration contains it, see `URLSessionConfiguration.stubbed`. For
/// `URLSession.shared`, `KingfisherTestObserver` registers it globally.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {

    /// Delivers the response of one request to its `URLProtocolClient`.
    ///
    /// `URLProtocol` expects calls to its client on the thread (and run loop mode) that called `startLoading`. A held
    /// response is released from another thread, so the loader keeps that run loop and schedules the delivery on it.
    final class Loader: @unchecked Sendable {
        private weak var urlProtocol: StubURLProtocol?
        private let runLoop: CFRunLoop
        private let mode: CFRunLoopMode
        private let lock = NSLock()
        private var isFinished = false

        init(urlProtocol: StubURLProtocol) {
            self.urlProtocol = urlProtocol
            self.runLoop = CFRunLoopGetCurrent()
            let currentMode = RunLoop.current.currentMode ?? .default
            self.mode = CFRunLoopMode(currentMode.rawValue as CFString)
        }

        func respond(with response: NetworkStub.Response) {
            if CFRunLoopGetCurrent() === runLoop {
                deliver(response)
            } else {
                CFRunLoopPerformBlock(runLoop, mode.rawValue) { self.deliver(response) }
                CFRunLoopWakeUp(runLoop)
            }
        }

        /// Marks the request as stopped. Returns `false` if the response was already delivered.
        func markStopped() -> Bool {
            lock.withLock {
                defer { isFinished = true }
                return !isFinished
            }
        }

        private func deliver(_ response: NetworkStub.Response) {
            let canDeliver: Bool = lock.withLock {
                defer { isFinished = true }
                return !isFinished
            }
            guard canDeliver, let urlProtocol, let client = urlProtocol.client else { return }

            switch response {
            case .failure(let error):
                client.urlProtocol(urlProtocol, didFailWithError: error)
            case .success(let statusCode, let headers, let body):
                let httpResponse = HTTPURLResponse(
                    url: urlProtocol.request.url!,
                    statusCode: statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )!
                client.urlProtocol(urlProtocol, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(urlProtocol, didLoad: body)
                client.urlProtocolDidFinishLoading(urlProtocol)
            }
        }
    }

    private var loader: Loader?
    private var stub: NetworkStub?

    override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool { false }

    override func startLoading() {
        let loader = Loader(urlProtocol: self)
        self.loader = loader
        guard let stub = NetworkStubRegistry.stub(for: request) else {
            loader.respond(with: .failure(UnexpectedRequestError(url: request.url)))
            return
        }
        self.stub = stub
        stub.start(loader)
    }

    override func stopLoading() {
        guard let loader, loader.markStopped() else { return }
        stub?.stop(loader)
    }
}

extension URLSessionConfiguration {
    /// An ephemeral configuration that sends all HTTP requests to `StubURLProtocol`.
    static var stubbed: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }
}
