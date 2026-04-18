//
//  ImageDataProviderCancellationTests.swift
//  Kingfisher
//
//  Created by onevcat on 2026/04/18.
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

import XCTest
@testable import Kingfisher

// MARK: - Test Providers

/// A callback-based provider that delivers after a delay, without honoring cancellation.
/// Exercises the default `data() async throws` bridge path: when Kingfisher cancels the
/// owning Task, the underlying `data(handler:)` still completes in the background, but
/// the caller sees `.dataProviderCancelled` because the post-await `Task.isCancelled`
/// check intercepts the result.
private final class DelayedCallbackProvider: ImageDataProvider, @unchecked Sendable {
    let cacheKey: String
    let delay: TimeInterval
    let payload: Data
    private let handlerInvoked: UnfairLockBox<Bool> = .init(false)

    var didInvokeHandler: Bool { handlerInvoked.value }

    init(
        cacheKey: String = "delayed-callback-\(UUID().uuidString)",
        delay: TimeInterval,
        payload: Data
    ) {
        self.cacheKey = cacheKey
        self.delay = delay
        self.payload = payload
    }

    func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        let payload = self.payload
        let handlerInvoked = self.handlerInvoked
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            handlerInvoked.value = true
            handler(.success(payload))
        }
    }
}

/// A cooperative async provider that polls `Task.isCancelled` between short sleeps.
/// Used to verify that Kingfisher's internal Task actually propagates cancellation into
/// the provider's own `data()` implementation — i.e. the work stops, not just the callback.
private final class CooperativeAsyncProvider: ImageDataProvider, @unchecked Sendable {
    let cacheKey: String
    let iterations: Int
    let iterationDelay: TimeInterval
    let payload: Data
    private let completedIterations: UnfairLockBox<Int> = .init(0)
    private let observedCancellation: UnfairLockBox<Bool> = .init(false)

    var completedIterationCount: Int { completedIterations.value }
    var didObserveCancellation: Bool { observedCancellation.value }

    init(
        cacheKey: String = "cooperative-async-\(UUID().uuidString)",
        iterations: Int,
        iterationDelay: TimeInterval,
        payload: Data
    ) {
        self.cacheKey = cacheKey
        self.iterations = iterations
        self.iterationDelay = iterationDelay
        self.payload = payload
    }

    func data() async throws -> Data {
        do {
            for _ in 0..<iterations {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: UInt64(iterationDelay * 1_000_000_000))
                completedIterations.value += 1
            }
        } catch is CancellationError {
            observedCancellation.value = true
            throw CancellationError()
        }
        return payload
    }
}

/// Minimal thread-safe box for counters/flags used from multiple queues in tests.
private final class UnfairLockBox<T>: @unchecked Sendable {
    private var storage: T
    private let lock = NSLock()

    init(_ value: T) { self.storage = value }

    var value: T {
        get { lock.lock(); defer { lock.unlock() }; return storage }
        set { lock.lock(); defer { lock.unlock() }; storage = newValue }
    }
}

extension UnfairLockBox where T == Int {
    static func += (lhs: UnfairLockBox<Int>, rhs: Int) {
        lhs.value += rhs
    }
}

// MARK: - Tests

final class ImageDataProviderCancellationTests: XCTestCase {

    private func makeManager() -> KingfisherManager {
        KingfisherManager(
            downloader: .default,
            cache: ImageCache(name: "provider-cancel-\(UUID().uuidString.prefix(8))")
        )
    }

    // Baseline: without cancellation the completion fires with `.success` and the
    // underlying provider handler runs to completion.
    func testProviderDeliversWhenNotCancelled() {
        let manager = makeManager()
        let provider = DelayedCallbackProvider(delay: 0.1, payload: testImageData)
        let done = expectation(description: "manager completion")

        _ = manager.retrieveImage(with: .provider(provider), options: nil) { result in
            if case .failure(let error) = result {
                XCTFail("unexpected failure: \(error)")
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 2.0)
        XCTAssertTrue(provider.didInvokeHandler)
    }

    // The `DownloadTask` returned for a provider source must now be non-nil and its
    // `cancel()` must deliver `.dataProviderCancelled` instead of letting the delayed
    // `.success` leak through to the caller.
    func testCancellingProviderTaskDeliversCancelledError() {
        let manager = makeManager()
        let provider = DelayedCallbackProvider(delay: 0.3, payload: testImageData)
        let done = expectation(description: "manager completion")

        let task = manager.retrieveImage(with: .provider(provider), options: nil) { result in
            switch result {
            case .success:
                XCTFail("provider load should have been cancelled, but got .success")
            case .failure(let error):
                guard case .requestError(reason: .dataProviderCancelled) = error else {
                    XCTFail("expected .dataProviderCancelled, got: \(error)")
                    done.fulfill()
                    return
                }
            }
            done.fulfill()
        }

        XCTAssertNotNil(task, "retrieveImage should return a cancellable task for provider sources (#2511)")
        task?.cancel()

        wait(for: [done], timeout: 2.0)
    }

    // End-to-end through the UIImageView/NSImageView extension path.
    @MainActor
    func testImageViewCancelDownloadTaskCancelsProvider() {
        let imageView = KFCrossPlatformImageView()
        let provider = DelayedCallbackProvider(delay: 0.3, payload: testImageData)
        let done = expectation(description: "setImage completion")

        imageView.kf.setImage(with: .provider(provider)) { result in
            switch result {
            case .success:
                XCTFail("setImage should have been cancelled, but got .success")
            case .failure(let error):
                guard case .requestError(reason: .dataProviderCancelled) = error else {
                    XCTFail("expected .dataProviderCancelled, got: \(error)")
                    done.fulfill()
                    return
                }
            }
            done.fulfill()
        }

        imageView.kf.cancelDownloadTask()
        wait(for: [done], timeout: 2.0)
    }

    // A cooperative provider overriding `data() async throws` must observe the cancel
    // signal: the provider's own iteration loop breaks early, proving the cancellation
    // propagates into the implementation (not just the caller-facing callback).
    func testCancelPropagatesIntoCooperativeAsyncProvider() {
        let manager = makeManager()
        // Long loop: without cancellation it would take ~20s to finish. If cooperative
        // cancellation works, the provider's loop exits within a few iterations.
        let provider = CooperativeAsyncProvider(
            iterations: 1_000,
            iterationDelay: 0.02,
            payload: testImageData
        )
        let done = expectation(description: "manager completion")

        let task = manager.retrieveImage(with: .provider(provider), options: nil) { result in
            switch result {
            case .success:
                XCTFail("cooperative provider should have been cancelled")
            case .failure(let error):
                guard case .requestError(reason: .dataProviderCancelled) = error else {
                    XCTFail("expected .dataProviderCancelled, got: \(error)")
                    done.fulfill()
                    return
                }
            }
            done.fulfill()
        }

        XCTAssertNotNil(task, "provider source must vend a cancellable DownloadTask")

        // Let a few iterations run, then cancel.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.08) {
            task?.cancel()
        }

        // With cooperative cancel this completes well before 2s; without it the loop
        // would run for ~20s and this test would time out.
        wait(for: [done], timeout: 2.0)

        XCTAssertTrue(
            provider.didObserveCancellation,
            "CooperativeAsyncProvider should see Task.checkCancellation() throw after cancel"
        )
        XCTAssertGreaterThanOrEqual(
            provider.completedIterationCount,
            1,
            "provider loop must make progress before cancel; otherwise the test doesn't prove mid-flight interruption"
        )
        XCTAssertLessThan(
            provider.completedIterationCount,
            provider.iterations,
            "provider loop should have exited early due to cancellation"
        )
    }

    // Non-cooperative callback providers: the background work still runs, but the
    // caller sees `.dataProviderCancelled` — matches the suppression semantics we
    // document, so callers don't get a late `.success` after `cancel()`.
    func testCancelSuppressesLateSuccessFromNonCooperativeProvider() {
        let manager = makeManager()
        let provider = DelayedCallbackProvider(delay: 0.4, payload: testImageData)
        let done = expectation(description: "manager completion")
        let handlerRan = expectation(description: "provider handler still runs")
        handlerRan.assertForOverFulfill = false

        let task = manager.retrieveImage(with: .provider(provider), options: nil) { result in
            switch result {
            case .success:
                XCTFail("non-cooperative provider cancel should deliver .dataProviderCancelled")
            case .failure(let error):
                guard case .requestError(reason: .dataProviderCancelled) = error else {
                    XCTFail("expected .dataProviderCancelled, got: \(error)")
                    done.fulfill()
                    return
                }
            }
            done.fulfill()
        }
        task?.cancel()

        // Poll the provider flag to confirm the handler eventually ran in the background.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            if provider.didInvokeHandler { handlerRan.fulfill() }
        }

        wait(for: [done, handlerRan], timeout: 2.0)
    }
}
