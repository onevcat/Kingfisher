//
//  StaleCacheTestHelpers.swift
//  Kingfisher
//
//  Created for issue #2495 - Disk cache stale task detection.
//

import XCTest
@testable import Kingfisher

// MARK: - SpyCacheSerializer

/// A cache serializer that records whether `image(with:options:)` was called,
/// and delegates actual work to `DefaultCacheSerializer`.
final class SpyCacheSerializer: CacheSerializer, @unchecked Sendable {

    private let lock = NSLock()

    private var _imageCallCount = 0
    var imageCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _imageCallCount
    }

    private var _lastData: Data?
    var lastData: Data? {
        lock.lock()
        defer { lock.unlock() }
        return _lastData
    }

    func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        DefaultCacheSerializer.default.data(with: image, original: original)
    }

    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        lock.lock()
        _imageCallCount += 1
        _lastData = data
        lock.unlock()
        return DefaultCacheSerializer.default.image(with: data, options: options)
    }
}

// MARK: - BlockingCacheSerializer

/// A cache serializer that blocks deserialization until `unblock()` is called.
/// Useful for testing timing windows between disk read and deserialization.
final class BlockingCacheSerializer: CacheSerializer, @unchecked Sendable {

    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()

    private var _imageCallCount = 0
    var imageCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _imageCallCount
    }

    /// Call this to allow the blocked `image(with:)` to proceed.
    func unblock() {
        semaphore.signal()
    }

    func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        DefaultCacheSerializer.default.data(with: image, original: original)
    }

    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        // Wait until unblocked. This simulates a slow deserializer and allows
        // tests to flip the checker between disk read and deserialization.
        semaphore.wait()
        lock.lock()
        _imageCallCount += 1
        lock.unlock()
        return DefaultCacheSerializer.default.image(with: data, options: options)
    }
}

// MARK: - CountingRetryStrategy

/// A retry strategy that counts how many times `retry` is called and always stops.
/// Useful for verifying that stale cache results do not enter the retry loop.
final class CountingRetryStrategy: RetryStrategy, @unchecked Sendable {

    private let lock = NSLock()

    private var _retryCount = 0
    var retryCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _retryCount
    }

    func retry(context: RetryContext, retryHandler: @escaping (RetryDecision) -> Void) {
        lock.lock()
        _retryCount += 1
        lock.unlock()
        retryHandler(.stop)
    }
}

// MARK: - CoordinatingCacheSerializer

/// A serializer that blocks on its first invocation, allowing tests to
/// synchronize between the ioQueue and the main thread deterministically.
///
/// Usage:
///   1. Call `setImage(url1)` with this serializer.
///   2. On a background thread, call `waitUntilFirstCallEntered()` —
///      this blocks until the ioQueue block for url1 reaches the serializer.
///   3. On the main thread, call `setImage(url2)` to cancel url1's token.
///   4. Call `allowFirstCallToProceed()` — the serializer returns for url1,
///      then CHECK 3 detects the stale token and discards the result.
final class CoordinatingCacheSerializer: CacheSerializer, @unchecked Sendable {

    private static let proceedTimeout: DispatchTimeInterval = .seconds(5)

    private let lock = NSLock()
    private var _callCount = 0
    private let enteredSemaphore = DispatchSemaphore(value: 0)
    private let proceedSemaphore = DispatchSemaphore(value: 0)

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _callCount
    }

    /// Blocks the caller until the first serializer invocation begins on the ioQueue.
    func waitUntilFirstCallEntered() { enteredSemaphore.wait() }

    /// Allows the blocked first serializer invocation to proceed.
    func allowFirstCallToProceed() { proceedSemaphore.signal() }

    func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        DefaultCacheSerializer.default.data(with: image, original: original)
    }

    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        lock.lock()
        _callCount += 1
        let isFirstCall = _callCount == 1
        lock.unlock()

        if isFirstCall {
            enteredSemaphore.signal()   // Tell the test "I'm in the serializer"
            let waitResult = proceedSemaphore.wait(timeout: .now() + Self.proceedTimeout)
            if waitResult == .timedOut {
                XCTFail("Timed out waiting for CoordinatingCacheSerializer to proceed")
            }
        }

        return DefaultCacheSerializer.default.image(with: data, options: options)
    }
}

// MARK: - RequestRecorder

/// A request modifier that records all URLs that pass through the downloader.
/// Use this to assert that certain URLs were NOT requested at the network level.
final class RequestRecorder: AsyncImageDownloadRequestModifier, @unchecked Sendable {
    private let requestedURLsStorage = LockIsolated([URL]())

    var requestedURLs: [URL] {
        requestedURLsStorage.value
    }

    var onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)? { nil }

    func modified(for request: URLRequest) async -> URLRequest? {
        if let url = request.url {
            requestedURLsStorage.withValue { $0.append(url) }
        }
        return request
    }
}
