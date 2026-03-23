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
