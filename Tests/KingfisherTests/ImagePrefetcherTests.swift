//
//  ImagePrefetcherTests.swift
//  Kingfisher
//
//  Created by Claire Knight <claire.knight@moggytech.co.uk> on 24/02/2016
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

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

class ImagePrefetcherTests: XCTestCase {
    
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
        cleanDefaultCache()
    }
    
    override func tearDown() {
        cleanDefaultCache()
        super.tearDown()
    }

    func testPrefetchingImages() {
        let exp = expectation(description: #function)

        testURLs.forEach { stub($0, data: testImageData) }
        let progressCalledCount = LockIsolated(0)
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache],
            progressBlock: { _, _, _ in progressCalledCount.withValue { $0 += 1 } }) {
                skippedResources, failedResources, completedResources in

                XCTAssertEqual(skippedResources.count, 0)
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, testURLs.count)
                XCTAssertEqual(progressCalledCount.value, testURLs.count)
                for url in testURLs {
                    XCTAssertTrue(KingfisherManager.shared.cache.imageCachedType(forKey: url.absoluteString).cached)
                }
                exp.fulfill()
            }
        prefetcher.start()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCancelPrefetching() {
        let exp = expectation(description: #function)
        let stubs = testURLs.map { delayedStub($0, data: testImageData) }
        
        let maxConcurrentCount = 2
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache],
            completionHandler: { skippedResources, failedResources, completedResources in
                XCTAssertEqual(skippedResources.count, 0)
                XCTAssertEqual(failedResources.count, testURLs.count)
                XCTAssertEqual(completedResources.count, 0)
                delay(0.1) { exp.fulfill() }
            }
        )
        
        prefetcher.maxConcurrentDownloads = maxConcurrentCount
        
        prefetcher.start()
        
        DispatchQueue.main.async {
            prefetcher.stop()
            stubs.forEach { _ = $0.go() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    

    func testPrefetcherCouldSkipCachedImages() {
        let exp = expectation(description: #function)
        KingfisherManager.shared.cache.store(KFCrossPlatformImage(), forKey: testKeys[0])
        
        testURLs.forEach { stub($0, data: testImageData) }
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache],
            completionHandler: { skippedResources, failedResources, completedResources in
                XCTAssertEqual(skippedResources.count, 1)
                XCTAssertEqual(skippedResources[0].downloadURL, testURLs[0])
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, testURLs.count - 1)
                exp.fulfill()
            }
        )
        
        prefetcher.start()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPrefetcherForceRefreshDownloadImages() {
        let exp = expectation(description: #function)
        KingfisherManager.shared.cache.store(KFCrossPlatformImage(), forKey: testKeys[0])
        
        testURLs.forEach { stub($0, data: testImageData) }
        let prefetcher = ImagePrefetcher(urls: testURLs, options: [.forceRefresh, .waitForCache], completionHandler:  {
            skippedResources, failedResources, completedResources in
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, testURLs.count)
            exp.fulfill()
        })
        
        prefetcher.start()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPrefetchWithWrongInitParameters() {
        let exp = expectation(description: #function)
        let prefetcher = ImagePrefetcher(urls: [], options: [.waitForCache], completionHandler:  {
            skippedResources, failedResources, completedResources in
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, 0)
            exp.fulfill()
        })
        
        prefetcher.start()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFetchWithProcessor() {
        let exp = expectation(description: #function)
        testURLs.forEach { stub($0, data: testImageData, length: 123) }

        let p = RoundCornerImageProcessor(cornerRadius: 20)

        @Sendable func prefetchAgain() {
            let progressCalledCount = LockIsolated(0)
            let prefetcher = ImagePrefetcher(
                urls: testURLs,
                options: [.processor(p), .waitForCache],
                progressBlock: { _, _, _ in progressCalledCount.withValue { $0 += 1 } })
            {
                skippedResources, failedResources, completedResources in

                XCTAssertEqual(skippedResources.count, testURLs.count)
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, 0)
                XCTAssertEqual(progressCalledCount.value, testURLs.count)
                for url in testURLs {
                    let cached = KingfisherManager.shared.cache.imageCachedType(
                        forKey: url.absoluteString, processorIdentifier: p.identifier).cached
                    XCTAssertTrue(cached)
                }
                exp.fulfill()

            }
            prefetcher.start()
        }

        let progressCalledCount = LockIsolated(0)
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.processor(p), .waitForCache],
            progressBlock: { _, _, _ in progressCalledCount.withValue { $0 += 1 } })
        {
            skippedResources, failedResources, completedResources in

            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, testURLs.count)
            XCTAssertEqual(progressCalledCount.value, testURLs.count)
            for url in testURLs {
                let cached = KingfisherManager.shared.cache.imageCachedType(
                    forKey: url.absoluteString, processorIdentifier: p.identifier).cached
                XCTAssertTrue(cached)
            }

            prefetchAgain()
        }
        prefetcher.start()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testAlsoPrefetchToMemory() {
        let exp = expectation(description: #function)
        let cache = KingfisherManager.shared.cache
        let key = testKeys[0]
        cache.store(KFCrossPlatformImage(), forKey: key)
        cache.store(testImage, forKey: key) { result in
            cache.memoryStorage.remove(forKey: key)
            
            XCTAssertEqual(cache.imageCachedType(forKey: key), .disk)
            
            testURLs.forEach { stub($0, data: testImageData) }
            let prefetcher = ImagePrefetcher(
                urls: testURLs,
                options: [.waitForCache, .alsoPrefetchToMemory], 
                completionHandler: { skippedResources, failedResources, completedResources in
                        
                    XCTAssertEqual(cache.imageCachedType(forKey: key), .memory)
                    XCTAssertEqual(skippedResources.count, 1)
                    XCTAssertEqual(skippedResources[0].downloadURL, testURLs[0])
                    XCTAssertEqual(failedResources.count, 0)
                    XCTAssertEqual(completedResources.count, testURLs.count - 1)
                    exp.fulfill()
                }
            )
            
            prefetcher.start()
            
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNotPrefetchToMemory() {
        let exp = expectation(description: #function)
        let cache = KingfisherManager.shared.cache
        let key = testKeys[0]

        cache.store(testImage, forKey: key) { result in
            cache.memoryStorage.remove(forKey: key)
            
            XCTAssertEqual(cache.imageCachedType(forKey: key), .disk)
            
            testURLs.forEach { stub($0, data: testImageData) }
            let prefetcher = ImagePrefetcher(
                urls: testURLs,
                options: [.waitForCache],
                completionHandler: { skippedResources, failedResources, completedResources in
                        
                    XCTAssertEqual(cache.imageCachedType(forKey: key), .disk)
                    
                    XCTAssertEqual(skippedResources.count, 1)
                    XCTAssertEqual(skippedResources[0].downloadURL, testURLs[0])
                    XCTAssertEqual(failedResources.count, 0)
                    XCTAssertEqual(completedResources.count, testURLs.count - 1)
                    exp.fulfill()
                }
            )
            
            prefetcher.start()
            
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPrefetchMoreTaskThanMaxConcurrency() {
        let exp = expectation(description: #function)
        
        testURLs.forEach { stub($0, data: testImageData) }
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache], 
            completionHandler: { skippedResources, failedResources, completedResources in
                XCTAssertEqual(skippedResources.count, 0)
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, testURLs.count)
                exp.fulfill()
            }
        )
        prefetcher.maxConcurrentDownloads = 1
        prefetcher.start()
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPrefetchStopWaitsForPendingRetryDecisions() {
        let entered = expectation(description: "Both retry decisions pending")
        entered.expectedFulfillmentCount = 2
        let firstFailed = expectation(description: "First source failed")
        let completed = expectation(description: "Both sources accounted for")
        let retry = PrefetchGatedRetryStrategy(entered: entered)
        let sources = (0..<2).map { _ in
            Source.provider(RawImageDataProvider(data: Data(), cacheKey: UUID().uuidString))
        }
        let prefetcher = ImagePrefetcher(
            sources: sources, options: [.retryStrategy(retry)],
            progressBlock: { _, failed, _ in
                if failed.count == 1 { firstFailed.fulfill() }
            },
            completionHandler: { skipped, failed, successful in
                XCTAssertTrue(skipped.isEmpty)
                XCTAssertEqual(failed.count, 2)
                XCTAssertTrue(successful.isEmpty)
                completed.fulfill()
            }
        )
        prefetcher.start()
        wait(for: [entered], timeout: 3)
        prefetcher.stop()
        retry.resolveNext()
        wait(for: [firstFailed], timeout: 3)
        retry.resolveNext()
        wait(for: [completed], timeout: 3)
    }

    func testPrefetchStopWhileRequestModifierIsPending() {
        let entered = expectation(description: "Modifier entered")
        let completed = expectation(description: "Prefetch completed")
        let modifier = PrefetchGatedRequestModifier(entered: entered)
        stub(testURLs[0], data: testImageData)
        let prefetcher = ImagePrefetcher(
            urls: [testURLs[0]], options: [.requestModifier(modifier)],
            completionHandler: { skipped, failed, successful in
                XCTAssertTrue(skipped.isEmpty)
                XCTAssertEqual(failed.count, 1)
                XCTAssertTrue(successful.isEmpty)
                completed.fulfill()
            }
        )
        prefetcher.start()
        wait(for: [entered], timeout: 3)
        prefetcher.stop()
        modifier.resume()
        wait(for: [completed], timeout: 3)
    }

    func testPrefetchFallsBackWhenDiskCacheDisappears() {
        let cache = EvictingPrefetchCache(name: UUID().uuidString)
        defer { clearCaches([cache]) }
        let url = testURLs[0]
        let stored = expectation(description: "Stored on disk")
        cache.store(testImage, forKey: url.cacheKey) { _ in stored.fulfill() }
        wait(for: [stored], timeout: 3)
        cache.clearMemoryCache()
        stub(url, data: testImageData)
        let completed = expectation(description: "Fallback completed")
        let prefetcher = ImagePrefetcher(
            urls: [url], options: [.targetCache(cache), .alsoPrefetchToMemory],
            completionHandler: { skipped, failed, successful in
                XCTAssertTrue(skipped.isEmpty)
                XCTAssertTrue(failed.isEmpty)
                XCTAssertEqual(successful.count, 1)
                completed.fulfill()
            }
        )
        prefetcher.start()
        wait(for: [completed], timeout: 2)
    }

    func testPrefetchOnlyFromCacheDoesNotLoadMissingSource() {
        let cache = ImageCache(name: UUID().uuidString)
        defer { clearCaches([cache]) }
        let loads = LockIsolated(0)
        let provider = SimpleImageDataProvider(cacheKey: UUID().uuidString) {
            loads.withValue { $0 += 1 }
            return .success(testImageData)
        }
        let completed = expectation(description: "Only-from-cache prefetch completed")
        let prefetcher = ImagePrefetcher(
            sources: [.provider(provider)], options: [.targetCache(cache), .onlyFromCache],
            completionHandler: { skipped, failed, successful in
                XCTAssertTrue(skipped.isEmpty)
                XCTAssertEqual(failed.count, 1)
                XCTAssertTrue(successful.isEmpty)
                XCTAssertEqual(loads.value, 0)
                completed.fulfill()
            }
        )

        prefetcher.start()
        wait(for: [completed], timeout: 2)
    }

    func testPrefetchOnlyFromCacheDoesNotFallBackWhenDiskCacheDisappears() {
        let cache = EvictingPrefetchCache(name: UUID().uuidString)
        defer { clearCaches([cache]) }
        let key = UUID().uuidString
        let stored = expectation(description: "Stored on disk")
        cache.store(testImage, forKey: key) { _ in stored.fulfill() }
        wait(for: [stored], timeout: 3)
        cache.clearMemoryCache()

        let loads = LockIsolated(0)
        let provider = SimpleImageDataProvider(cacheKey: key) {
            loads.withValue { $0 += 1 }
            return .success(testImageData)
        }
        let completed = expectation(description: "Only-from-cache prefetch completed")
        let prefetcher = ImagePrefetcher(
            sources: [.provider(provider)], options: [.targetCache(cache), .alsoPrefetchToMemory, .onlyFromCache],
            completionHandler: { skipped, failed, successful in
                XCTAssertTrue(skipped.isEmpty)
                XCTAssertEqual(failed.count, 1)
                XCTAssertTrue(successful.isEmpty)
                XCTAssertEqual(loads.value, 0)
                completed.fulfill()
            }
        )

        prefetcher.start()
        wait(for: [completed], timeout: 2)
    }

    func testPrefetchStopCancelsEverySourceWithDuplicateCacheKeys() {
        let started = expectation(description: "Both providers started")
        started.expectedFulfillmentCount = 2
        let exited = expectation(description: "Both providers exited")
        exited.expectedFulfillmentCount = 2
        let completed = expectation(description: "Prefetch completed")
        completed.assertForOverFulfill = true
        let cancellations = LockIsolated(0)
        let callbacks = LockIsolated(0)
        let provider = PrefetchCancellationProbe(
            cacheKey: UUID().uuidString, started: started, exited: exited, cancellations: cancellations
        )
        let prefetcher = ImagePrefetcher(sources: [.provider(provider), .provider(provider)], completionHandler: {
            skipped, failed, successful in
            callbacks.withValue { $0 += 1 }
            XCTAssertEqual(skipped.count, 0)
            XCTAssertEqual(failed.count, 2)
            XCTAssertEqual(successful.count, 0)
            XCTAssertEqual(cancellations.value, 2)
            completed.fulfill()
        })
        prefetcher.start()
        wait(for: [started], timeout: 3)
        prefetcher.stop()
        wait(for: [completed, exited], timeout: 3)
        XCTAssertEqual(cancellations.value, 2)
        let settled = expectation(description: "Queued callbacks drained")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        wait(for: [settled], timeout: 1)
        XCTAssertEqual(callbacks.value, 1)
    }

    func testPrefetchMultiTimes() {
        let exp = expectation(description: #function)
        let group = DispatchGroup()
        testURLs.forEach { stub($0, data: testImageData) }
        for _ in 0..<10000 {
            group.enter()
            let prefetcher = ImagePrefetcher(
                resources: testURLs,
                options: [.cacheMemoryOnly], 
                completionHandler: {
                    _, _, _ in group.leave()
                }
            )
            prefetcher.start()
        }
        group.notify(queue: .main) { exp.fulfill() }
        waitForExpectations(timeout: 15, handler: nil)
    }

    func testPrefetchSources() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData)

        let sources: [Source] = [
            .provider(SimpleImageDataProvider(cacheKey: "1") { .success(testImageData) }),
            .provider(SimpleImageDataProvider(cacheKey: "2") { .success(testImageData) }),
            .network(url)
        ]
        let counter = LockIsolated(0)
        let prefetcher = ImagePrefetcher(
            sources: sources,
            options: [.waitForCache],
            progressBlock: {
                skipped, failed, completed in
                counter.withValue { $0 += 1 }
                XCTAssertEqual(skipped.count, 0)
                XCTAssertEqual(failed.count, 0)
                XCTAssertEqual(completed.count, counter.value)
            },
            completionHandler: {
                skipped, failed, completed in
                XCTAssertEqual(skipped.count, 0)
                XCTAssertEqual(failed.count, 0)
                XCTAssertEqual(completed.count, sources.count)
                XCTAssertEqual(counter.value, sources.count)

                let allCached = [ImageCache.default.isCached(forKey: "1"),
                                 ImageCache.default.isCached(forKey: "2"),
                                 ImageCache.default.isCached(forKey: url.absoluteString)
                ].allSatisfy { $0 == true }
                XCTAssertTrue(allCached)

                exp.fulfill()
            })
        prefetcher.start()

        waitForExpectations(timeout: 3, handler: nil)
    }
}

private struct PrefetchCancellationProbe: ImageDataProvider {
    let cacheKey: String
    let started: XCTestExpectation
    let exited: XCTestExpectation
    let cancellations: LockIsolated<Int>

    func data() async throws -> Data {
        started.fulfill()
        defer { exited.fulfill() }
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            return testImageData
        } catch {
            cancellations.withValue { $0 += 1 }
            throw error
        }
    }
}

private final class EvictingPrefetchCache: ImageCache, @unchecked Sendable {
    override func imageCachedType(
        forKey key: String,
        processorIdentifier identifier: String = DefaultImageProcessor.default.identifier,
        forcedExtension: String? = nil
    ) -> CacheType {
        let type = super.imageCachedType(forKey: key, processorIdentifier: identifier, forcedExtension: forcedExtension)
        if type == .disk { try? diskStorage.removeAll() }
        return type
    }
}

private final class PrefetchGatedRequestModifier: AsyncImageDownloadRequestModifier, @unchecked Sendable {
    let entered: XCTestExpectation
    let pending = LockIsolated<(@Sendable () -> Void)?>(nil)
    var onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)? { nil }

    init(entered: XCTestExpectation) { self.entered = entered }

    func modified(for request: URLRequest) async -> URLRequest? {
        await withCheckedContinuation { continuation in
            pending.withValue { $0 = { continuation.resume(returning: request) } }
            entered.fulfill()
        }
    }

    func resume() {
        let callback = pending.withValue { value in
            defer { value = nil }
            return value
        }
        callback?()
    }
}

private final class PrefetchGatedRetryStrategy: RetryStrategy, @unchecked Sendable {
    let entered: XCTestExpectation
    let pending = LockIsolated<[@Sendable (RetryDecision) -> Void]>([])

    init(entered: XCTestExpectation) { self.entered = entered }

    func retry(context: RetryContext, retryHandler: @escaping @Sendable (RetryDecision) -> Void) {
        pending.withValue { $0.append(retryHandler) }
        entered.fulfill()
    }

    func resolveNext() {
        let handler = pending.withValue { $0.removeFirst() }
        handler(.stop)
    }
}
