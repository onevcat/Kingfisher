//
//  KingfisherManagerTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/22.
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

actor CallingChecker {
    var called = false
    func mark() {
        called = true
    }
    
    func checkCancelBehavior(
        stub: LSStubResponseDSL,
        block: @escaping () async throws -> Void
    ) async throws {
        let task = Task {
            do {
                _ = try await block()
                XCTFail()
            } catch {
                mark()
                XCTAssertTrue((error as! KingfisherError).isTaskCancelled)
            }
        }
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
        task.cancel()
        _ = stub.go()
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
        XCTAssertTrue(called)
    }
}

class KingfisherManagerTests: XCTestCase {
    
    var manager: KingfisherManager!
    
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
        manager.defaultOptions = [.waitForCache]
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }
    
    func testRetrieveImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let manager = self.manager!
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)

        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .memory)

        manager.cache.clearMemoryCache()
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .disk)

        manager.cache.clearMemoryCache()
        manager.cache.clearDiskCache {
            manager.retrieveImage(with: url) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                exp.fulfill()
        }}}}}
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveImageAsync() async throws {
        let url = testURLs[0]
        stub(url, data: testImageData)

        let manager = self.manager!
        
        var result = try await manager.retrieveImage(with: url)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .none)
        
        result = try await manager.retrieveImage(with: url)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .memory)
        
        manager.cache.clearMemoryCache()
        result = try await manager.retrieveImage(with: url)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .disk)
        
        manager.cache.clearMemoryCache()
        await manager.cache.clearDiskCache()
        result = try await manager.retrieveImage(with: url)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .none)
    }
    
    func testRetrieveImageWithProcessor() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        let p = RoundCornerImageProcessor(cornerRadius: 20)
        let manager = self.manager!

        manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none,
                           "Need a processor to get correct image. Cannot get from cache, need download again.")

        manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .memory)
                    
        self.manager.cache.clearMemoryCache()
        manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .disk)
                        
        self.manager.cache.clearMemoryCache()
        self.manager.cache.clearDiskCache {
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)

                exp.fulfill()
        }}}}}}
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveImageForceRefresh() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: DefaultCacheSerializer.default,
            toDisk: true)
        {
            _ in
            XCTAssertTrue(self.manager.cache.imageCachedType(forKey: url.cacheKey).cached)
            self.manager.retrieveImage(with: url, options: [.forceRefresh]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveImageCancel() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)

        let task = manager.retrieveImage(with: url) {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            exp.fulfill()
        }

        XCTAssertNotNil(task)
        task?.cancel()
        _ = stub.go()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveImageCancelAsync() async throws {
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)

        let checker = CallingChecker()
        try await checker.checkCancelBehavior(stub: stub) {
            _ = try await self.manager.retrieveImage(with: url)
        }
    }
    
    /// Test to reproduce the Swift Task Continuation Misuse issue
    /// This test verifies that continuations are properly resumed even under rapid cancellation scenarios
    /// 
    /// NOTE: Single test run may not reproduce the issue, but running this test repeatedly 
    /// (e.g., 100 times in Xcode) will almost certainly trigger the SWIFT TASK CONTINUATION MISUSE warning.
    /// This confirms the existence of a race condition in the async retrieveImage implementation.
    func testRetrieveImageContinuationMisuseReproduction() async throws {
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)
        
        // Create multiple concurrent tasks that are cancelled quickly
        // This should reproduce the continuation leak scenario
        let taskCount = 50 // Increased to make race condition more likely
        var tasks: [Task<Void, Never>] = []
        
        for i in 0..<taskCount {
            let task = Task {
                do {
                    _ = try await self.manager.retrieveImage(with: url)
                    // If we reach here without cancellation, something is wrong
                    print("Task \(i) completed without cancellation - unexpected")
                } catch {
                    // This should be a cancellation error
                    if let kfError = error as? KingfisherError, kfError.isTaskCancelled {
                        // Expected cancellation
                    } else if error is CancellationError {
                        // Expected cancellation
                    } else {
                        print("Task \(i) failed with unexpected error: \(error)")
                    }
                }
            }
            tasks.append(task)
            
            // Cancel immediately after creation to create race conditions
            task.cancel()
            
            // Add a tiny delay to create more variation in timing
            if i % 5 == 0 {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 1000) // 1ms
            }
        }
        
        // Wait a bit to ensure all tasks have had a chance to start and be cancelled
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10) // 100ms
        
        // Complete the stub to allow any pending operations to finish
        _ = stub.go()
        
        // Wait for all tasks to complete
        for task in tasks {
            await task.value
        }
        
        // If we get here without hanging, the continuation handling is working correctly
        // The test passes if no SWIFT TASK CONTINUATION MISUSE warning is printed to console
    }
    
    /// Another test that creates a more specific race condition scenario
    /// This test checks the exact timing described in the issue
    /// 
    /// NOTE: Like the previous test, run this repeatedly to increase chances of reproducing the issue.
    func testRetrieveImageRaceConditionSpecific() async throws {
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 5000) // Longer delay
        
        // This creates the specific race condition:
        // 1. Task starts
        // 2. Gets to the withCheckedThrowingContinuation
        // 3. Cancel happens before the inner retrieveImage call completes setup
        let task = Task {
            do {
                _ = try await self.manager.retrieveImage(with: url)
                XCTFail("Task should have been cancelled")
            } catch {
                // Should be cancelled
                if let kfError = error as? KingfisherError {
                    XCTAssertTrue(kfError.isTaskCancelled)
                } else if error is CancellationError {
                    XCTAssertTrue(true)
                } else {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        
        // Very short delay to let the task start but not complete
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 1000) // 1ms
        
        // Cancel before the network stub is triggered
        task.cancel()
        
        // Now trigger the network response
        _ = stub.go()
        
        // Wait for the task to complete
        await task.value
    }
    
    func testSuccessCompletionHandlerRunningOnMainQueueByDefault() {
        let progressExpectation = expectation(description: "progressBlock running on main queue")
        let completionExpectation = expectation(description: "completionHandler running on main queue")

        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)
        
        manager.retrieveImage(with: url, options: nil, progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            progressExpectation.fulfill()})
        {
            result in
            XCTAssertNil(result.error)
            XCTAssertTrue(Thread.isMainThread)
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testShouldNotDownloadImageIfCacheOnlyAndNotInCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url, options: [.onlyFromCache]) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            if case .cacheError(reason: .imageNotExisting(let key)) = result.error! {
                XCTAssertEqual(key, url.cacheKey)
            } else {
                XCTFail()
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testErrorCompletionHandlerRunningOnMainQueueByDefault() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, statusCode: 404)

        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertTrue(result.error!.isInvalidResponseStatusCode(404))
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testSuccessCompletionHandlerRunningOnCustomQueue() {
        let progressExpectation = expectation(description: "progressBlock running on custom queue")
        let completionExpectation = expectation(description: "completionHandler running on custom queue")

        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        let options: KingfisherOptionsInfo = [.callbackQueue(.dispatch(customQueue))]
        manager.retrieveImage(with: url, options: options, progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            progressExpectation.fulfill()
        })
        {
            result in
            XCTAssertNil(result.error)
            dispatchPrecondition(condition: .onQueue(customQueue))
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testLoadCacheCompletionHandlerRunningOnCustomQueue() {
        let completionExpectation = expectation(description: "completionHandler running on custom queue")

        let url = testURLs[0]
        manager.cache.store(testImage, forKey: url.cacheKey)

        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        manager.retrieveImage(with: url, options: [.callbackQueue(.dispatch(customQueue))]) {
            result in
            XCTAssertNil(result.error)
            dispatchPrecondition(condition: .onQueue(customQueue))
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDefaultOptionCouldApply() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        manager.defaultOptions = [.scaleFactor(2)]
        manager.retrieveImage(with: url, completionHandler: { result in
            #if !os(macOS)
            XCTAssertEqual(result.value!.image.scale, 2.0)
            #endif
            exp.fulfill()
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testOriginalImageCouldBeStored() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let manager = self.manager!
        let p = SimpleProcessor()
        let options = KingfisherParsedOptionsInfo([.processor(p), .cacheOriginalImage])
        let source = Source.network(url)
        let context = RetrievingContext(options: options, originalSource: source)
        manager.loadAndCacheImage(source: .network(url), context: context) { result in
            
            var imageCached = manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            var originalCached = manager.cache.imageCachedType(forKey: url.cacheKey)

            XCTAssertEqual(imageCached, .memory)

            delay(0.3) {
                manager.cache.clearMemoryCache()
                
                imageCached = manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                originalCached = manager.cache.imageCachedType(forKey: url.cacheKey)
                XCTAssertEqual(imageCached, .disk)
                XCTAssertEqual(originalCached, .disk)
                
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testOriginalImageNotBeStoredWithoutOptionSet() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let p = SimpleProcessor()
        let options = KingfisherParsedOptionsInfo([.processor(p), .waitForCache])
        let source = Source.network(url)
        let context = RetrievingContext(options: options, originalSource: source)
        manager.loadAndCacheImage(source: .network(url), context: context) {
            result in
            var imageCached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            var originalCached = self.manager.cache.imageCachedType(forKey: url.cacheKey)
            
            XCTAssertEqual(imageCached, .memory)
            XCTAssertEqual(originalCached, .none)
            
            self.manager.cache.clearMemoryCache()
            
            imageCached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            originalCached = self.manager.cache.imageCachedType(forKey: url.cacheKey)
            XCTAssertEqual(imageCached, .disk)
            XCTAssertEqual(originalCached, .none)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCouldProcessOnOriginalImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: DefaultCacheSerializer.default,
            toDisk: true)
        {
            _ in
            let p = SimpleProcessor()
            
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            XCTAssertFalse(cached.cached)
            
            // No downloading will happen
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                XCTAssertTrue(p.processed)
                
                // The processed image should be cached
                let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                XCTAssertTrue(cached.cached)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFailingProcessOnOriginalImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: DefaultCacheSerializer.default,
            toDisk: true)
        {
            _ in
            let p = FailingProcessor()
            
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            XCTAssertFalse(cached.cached)
            
            // No downloading will happen
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.error)
                XCTAssertTrue(p.processed)
                if case .processorError(reason: .processingFailed(let processor, _)) = result.error! {
                    XCTAssertEqual(processor.identifier, p.identifier)
                } else {
                    XCTFail()
                }
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFailingProcessOnDataProviderImage() {
        let exp = expectation(description: #function)
        let provider = SimpleImageDataProvider(cacheKey: "key") { .success(testImageData) }
        let p = FailingProcessor()
        let options = [KingfisherOptionsInfoItem.processor(p), .processingQueue(.mainCurrentOrAsync)]
        _ = manager.retrieveImage(with: .provider(provider), options: options) { result in
            XCTAssertNotNil(result.error)
            if case .processorError(reason: .processingFailed(let processor, _)) = result.error! {
                XCTAssertEqual(processor.identifier, p.identifier)
            } else {
                XCTFail()
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCacheOriginalImageWithOriginalCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        let originalCache = ImageCache(name: "test-originalCache")
        
        // Clear original cache first.
        originalCache.clearMemoryCache()
        originalCache.clearDiskCache {
            
            XCTAssertEqual(originalCache.imageCachedType(forKey: url.cacheKey), .none)
            
            stub(url, data: testImageData)
            
            let p = RoundCornerImageProcessor(cornerRadius: 20)
            self.manager.retrieveImage(
                with: url,
                options: [.processor(p), .cacheOriginalImage, .originalCache(originalCache)])
            {
                result in
                let originalCached = originalCache.imageCachedType(forKey: url.cacheKey)
                XCTAssertEqual(originalCached, .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCouldProcessOnOriginalImageWithOriginalCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        let originalCache = ImageCache(name: "test-originalCache")
        
        // Clear original cache first.
        originalCache.clearMemoryCache()
        originalCache.clearDiskCache {
            originalCache.store(
                testImage,
                original: testImageData,
                forKey: url.cacheKey,
                processorIdentifier: DefaultImageProcessor.default.identifier,
                cacheSerializer: DefaultCacheSerializer.default,
                toDisk: true)
            {
                _ in
                let p = SimpleProcessor()
                
                let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                XCTAssertFalse(cached.cached)
                
                // No downloading will happen
                self.manager.retrieveImage(with: url, options: [.processor(p), .originalCache(originalCache)]) {
                    result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value!.cacheType, .none)
                    XCTAssertTrue(p.processed)
                    
                    // The processed image should be cached
                    let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                    XCTAssertTrue(cached.cached)
                    exp.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCouldProcessDoNotHappenWhenSerializerCachesTheProcessedData() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        stub(url, data: testImageData)
        
        let s = DefaultCacheSerializer()

        let p1 = SimpleProcessor()
        let options1: KingfisherOptionsInfo = [.processor(p1), .cacheSerializer(s), .waitForCache]
        let source = Source.network(url)
        
        manager.retrieveImage(with: source, options: options1) { result in
            XCTAssertTrue(p1.processed)
            
            let p2 = SimpleProcessor()
            let options2: KingfisherOptionsInfo = [.processor(p2), .cacheSerializer(s), .waitForCache]
            self.manager.cache.clearMemoryCache()
            
            self.manager.retrieveImage(with: source, options: options2) { result in
                XCTAssertEqual(result.value?.cacheType, .disk)
                XCTAssertFalse(p2.processed)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCouldProcessAgainWhenSerializerCachesOriginalData() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        stub(url, data: testImageData)
        
        var s = DefaultCacheSerializer()
        s.preferCacheOriginalData = true

        let p1 = SimpleProcessor()
        let options1: KingfisherOptionsInfo = [.processor(p1), .cacheSerializer(s), .waitForCache]
        let source = Source.network(url)
        
        manager.retrieveImage(with: source, options: options1) { [s] result in
            XCTAssertTrue(p1.processed)
            
            let p2 = SimpleProcessor()
            let options2: KingfisherOptionsInfo = [.processor(p2), .cacheSerializer(s), .waitForCache]
            self.manager.cache.clearMemoryCache()
            
            self.manager.retrieveImage(with: source, options: options2) { result in
                XCTAssertEqual(result.value?.cacheType, .disk)
                XCTAssertTrue(p2.processed)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testWaitForCacheOnRetrieveImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        self.manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            self.manager.cache.clearMemoryCache()
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey)
            XCTAssertEqual(cached, .disk)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNotWaitForCacheOnRetrieveImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        self.manager.defaultOptions = .empty
        self.manager.retrieveImage(with: url, options: [.callbackQueue(.untouch)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            // We are not waiting for cache finishing here. So only sync memory cache is done.
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .memory)
            
            // Clear the memory cache.
            self.manager.cache.clearMemoryCache()
            // After some time, the disk cache should be done.
            delay(0.5) {
                XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testWaitForCacheOnRetrieveImageWithProcessor() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        let p = RoundCornerImageProcessor(cornerRadius: 20)
        self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            // `waitForCache` is enabled by default in test setup, so the processed image should already be cached to disk
            // when the completion handler is called.
            self.manager.cache.clearMemoryCache()
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            XCTAssertEqual(cached, .disk)

            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testImageShouldOnlyFromMemoryCacheOrRefreshCanBeGotFromMemory() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
            // Can be downloaded and cached normally.
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            // Can still be got from memory even when disk cache cleared.
            self.manager.cache.clearDiskCache {
                self.manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value!.cacheType, .memory)
                    
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageShouldOnlyFromMemoryCacheOrRefreshCanRefreshIfNotInMemory() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .memory)

            self.manager.cache.clearMemoryCache()
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .disk)
            
            // Should skip disk cache and download again.
            self.manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .memory)

                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldDownloadAndCacheProcessedImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let size = CGSize(width: 1, height: 1)
        let processor = ResizingImageProcessor(referenceSize: size)

        manager.retrieveImage(with: url, options: [.processor(processor)]) { result in
            // Can download and cache normally
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.image.size, size)
            XCTAssertEqual(result.value!.cacheType, .none)

            self.manager.cache.clearMemoryCache()
            let cached = self.manager.cache.imageCachedType(
                forKey: url.cacheKey, processorIdentifier: processor.identifier)
            XCTAssertEqual(cached, .disk)

            self.manager.retrieveImage(with: url, options: [.processor(processor)]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.image.size, size)
                XCTAssertEqual(result.value!.cacheType, .disk)

                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    func testShouldApplyImageModifierWhenDownload() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let modifierCalled = LockIsolated(false)
        let modifier = AnyImageModifier { image in
            modifierCalled.setValue(true)
            return image.withRenderingMode(.alwaysTemplate)
        }
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)
            XCTAssertTrue(modifierCalled.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testShouldApplyImageModifierWhenLoadFromMemoryCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let modifierCalled = LockIsolated(false)
        let modifier = AnyImageModifier { image in
            modifierCalled.setValue(true)
            return image.withRenderingMode(.alwaysTemplate)
        }

        manager.cache.store(testImage, forKey: url.cacheKey)
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertEqual(result.value?.cacheType, .memory)
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)
            XCTAssertTrue(modifierCalled.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testShouldApplyImageModifierWhenLoadFromDiskCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let modifierCalled = LockIsolated(false)
        let modifier = AnyImageModifier { image in
            modifierCalled.setValue(true)
            return image.withRenderingMode(.alwaysTemplate)
        }

        manager.cache.store(testImage, forKey: url.cacheKey) { _ in
            self.manager.cache.clearMemoryCache()
            self.manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
                XCTAssertEqual(result.value!.cacheType, .disk)
                XCTAssertEqual(result.value!.image.renderingMode, .alwaysTemplate)
                XCTAssertTrue(modifierCalled.value)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageModifierResultShouldNotBeCached() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let modifierCalled = LockIsolated(false)
        let modifier = AnyImageModifier { image in
            modifierCalled.setValue(true)
            return image.withRenderingMode(.alwaysTemplate)
        }
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)

            let memoryCached = self.manager.cache.retrieveImageInMemoryCache(forKey: url.absoluteString)
            XCTAssertNotNil(memoryCached)
            XCTAssertEqual(memoryCached?.renderingMode, .automatic)

            self.manager.cache.retrieveImageInDiskCache(forKey: url.absoluteString) { result in
                XCTAssertNotNil(result.value!)
                XCTAssertEqual(result.value??.renderingMode, .automatic)
                XCTAssertTrue(modifierCalled.value)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

#endif
    
    func testRetrieveWithImageProvider() {
        let exp = expectation(description: #function)
        let provider = SimpleImageDataProvider(cacheKey: "key") { .success(testImageData) }
        manager.defaultOptions = .empty
        _ = manager.retrieveImage(with: .provider(provider), options: [.processingQueue(.mainCurrentOrAsync)]) {
            result in
            XCTAssertNotNil(result.value)
            XCTAssertTrue(result.value!.image.renderEqual(to: testImage))
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveWithImageProviderFail() {
        let exp = expectation(description: #function)
        let provider = SimpleImageDataProvider(cacheKey: "key") { .failure(SimpleImageDataProvider.E()) }
        _ = manager.retrieveImage(with: .provider(provider)) { result in
            XCTAssertNotNil(result.error)
            if case .imageSettingError(reason: .dataProviderError(_, let error)) = result.error! {
                XCTAssertTrue(error is SimpleImageDataProvider.E)
            } else {
                XCTFail()
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testContextRemovingAlternativeSource() {
        let allSources: [Source] = [
            .network(URL(string: "1")!),
            .network(URL(string: "2")!)
        ]
        let info = KingfisherParsedOptionsInfo([.alternativeSources(allSources)])
        let context = RetrievingContext<Source>(
            options: info, originalSource: .network(URL(string: "0")!))

        let source1 = context.popAlternativeSource()
        XCTAssertNotNil(source1)
        guard case .network(let r1) = source1! else {
            XCTFail("Should be a network source, but \(source1!)")
            return
        }
        XCTAssertEqual(r1.downloadURL.absoluteString, "1")

        let source2 = context.popAlternativeSource()
        XCTAssertNotNil(source2)
        guard case .network(let r2) = source2! else {
            XCTFail("Should be a network source, but \(source2!)")
            return
        }
        XCTAssertEqual(r2.downloadURL.absoluteString, "2")

        XCTAssertNil(context.popAlternativeSource())
    }

    func testRetrievingWithAlternativeSource() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        _ = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])])
        {
            result in

            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!.source.url, url)
            XCTAssertEqual(result.value!.originalSource.url, brokenURL)

            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRetrievingErrorsWithAlternativeSource() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: Data())

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let anotherBrokenURL = URL(string: "anotherBrokenURL")!
        stub(anotherBrokenURL, data: Data())

        _ = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(anotherBrokenURL), .network(url)])])
        {
            result in

            defer { exp.fulfill() }

            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)

            guard case .imageSettingError(reason: let reason) = result.error! else {
                XCTFail("The error should be image setting error")
                return
            }

            guard case .alternativeSourcesExhausted(let errorInfo) = reason else {
                XCTFail("The error reason should be alternativeSourcesFailed")
                return
            }

            XCTAssertEqual(errorInfo.count, 3)
            XCTAssertEqual(errorInfo[0].source.url, brokenURL)
            XCTAssertEqual(errorInfo[1].source.url, anotherBrokenURL)
            XCTAssertEqual(errorInfo[2].source.url, url)
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRetrievingAlternativeSourceTaskUpdateBlockCalled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let downloadTaskUpdatedCount = LockIsolated(0)
        let task = manager.retrieveImage(
          with: .network(brokenURL),
          options: [.alternativeSources([.network(url)])],
          downloadTaskUpdated: { newTask in
              downloadTaskUpdatedCount.withValue { $0 += 1 }
              XCTAssertEqual(newTask?.sessionTask?.task.currentRequest?.url, url)
          })
        {
            result in
            XCTAssertEqual(downloadTaskUpdatedCount.value, 1)
            exp.fulfill()
        }

        XCTAssertEqual(task?.sessionTask?.task.currentRequest?.url, brokenURL)

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRetrievingAlternativeSourceCancelled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let task = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])]
        )
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            exp.fulfill()
        }
        task?.cancel()

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRetrievingAlternativeSourceCanCancelUpdatedTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let dataStub = delayedStub(url, data: testImageData)
        
        let called = LockIsolated(false)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let task = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])],
            downloadTaskUpdated: { newTask in
                XCTAssertNotNil(newTask)
                newTask?.cancel()
                called.setValue(true)
            }
        )
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error?.isTaskCancelled ?? false)

            delay(0.3) {
                _ = dataStub.go()
                XCTAssertTrue(called.value)
                exp.fulfill()
            }
        }
        
        XCTAssertNotNil(task)
        XCTAssertTrue(task!.isInitialized)

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownsamplingHandleScale2x() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        _ = manager.retrieveImage(
            with: .network(url),
            options: [.processor(DownsamplingImageProcessor(size: .init(width: 4, height: 4))), .scaleFactor(2)])
        {
            result in

            let image = result.value?.image
            XCTAssertNotNil(image)
            
            #if os(macOS)
            XCTAssertEqual(image?.size, .init(width: 8, height: 8))
            XCTAssertEqual(image?.kf.scale, 1)
            #else
            XCTAssertEqual(image?.size, .init(width: 4, height: 4))
            XCTAssertEqual(image?.kf.scale, 2)
            #endif
            
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownsamplingHandleScale3x() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        _ = manager.retrieveImage(
            with: .network(url),
            options: [.processor(DownsamplingImageProcessor(size: .init(width: 4, height: 4))), .scaleFactor(3)])
        {
            result in

            let image = result.value?.image
            XCTAssertNotNil(image)
            #if os(macOS)
            XCTAssertEqual(image?.size, .init(width: 12, height: 12))
            XCTAssertEqual(image?.kf.scale, 1)
            #else
            XCTAssertEqual(image?.size, .init(width: 4, height: 4))
            XCTAssertEqual(image?.kf.scale, 3)
            #endif
            
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCacheCallbackCoordinatorStateChanging() {
        var coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: false, shouldCacheOriginal: false)
        var called = false
        coordinator.apply(.cacheInitiated) {
            called = true
        }
        XCTAssertTrue(called)
        XCTAssertEqual(coordinator.state, .done)
        coordinator.apply(.cachingImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: true, shouldCacheOriginal: false)
        called = false
        coordinator.apply(.cacheInitiated) { XCTFail() }
        XCTAssertEqual(coordinator.state, .idle)
        coordinator.apply(.cachingImage) {
            called = true
        }
        XCTAssertTrue(called)
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: false, shouldCacheOriginal: true)
        coordinator.apply(.cacheInitiated) {
            called = true
        }
        XCTAssertEqual(coordinator.state, .done)
        coordinator.apply(.cachingOriginalImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: true, shouldCacheOriginal: true)
        coordinator.apply(.cacheInitiated) { XCTFail() }
        XCTAssertEqual(coordinator.state, .idle)
        coordinator.apply(.cachingOriginalImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .originalImageCached)
        coordinator.apply(.cachingImage) { called = true }
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: true, shouldCacheOriginal: true)
        coordinator.apply(.cacheInitiated) { XCTFail() }
        XCTAssertEqual(coordinator.state, .idle)
        coordinator.apply(.cachingImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .imageCached)
        coordinator.apply(.cachingOriginalImage) { called = true }
        XCTAssertEqual(coordinator.state, .done)
    }
    
    func testCallbackClearAfterSuccess() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        stub(url, data: testImageData)
        
        let task = LockIsolated<DownloadTask?>(nil)
        let callbackCount = LockIsolated(0)
        
        let t: DownloadTask? = manager.retrieveImage(with: url) { result in
            let count = callbackCount.withValue { value in
                value += 1
                return value
            }

            XCTAssertEqual(count, 1, "Callback should not be invoked again.")
            XCTAssertNotNil(result.value?.image)

            task.value?.cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                exp.fulfill()
            }
        }

        task.setValue(t)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCanUseCustomizeDefaultCacheSerializer() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        var cacheSerializer = DefaultCacheSerializer()
        cacheSerializer.preferCacheOriginalData = true

        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: cacheSerializer, toDisk: true) {
                result in

                let computedKey = url.cacheKey.computedKey(with: DefaultImageProcessor.default.identifier)
                let fileURL = self.manager.cache.diskStorage.cacheFileURL(forKey: computedKey)
                let data = try! Data(contentsOf: fileURL)
                XCTAssertEqual(data, testImageData)

                exp.fulfill()
            }
        waitForExpectations(timeout: 3.0)
    }

    func testCanUseCustomizeDefaultCacheSerializerStoreEncoded() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        var cacheSerializer = DefaultCacheSerializer()
        cacheSerializer.compressionQuality = 0.8

        manager.cache.store(
            testImage,
            original: testImageJEPGData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: cacheSerializer, toDisk: true) {
                result in

                let computedKey = url.cacheKey.computedKey(with: DefaultImageProcessor.default.identifier)
                let fileURL = self.manager.cache.diskStorage.cacheFileURL(forKey: computedKey)
                let data = try! Data(contentsOf: fileURL)
                XCTAssertNotEqual(data, testImageJEPGData)
                XCTAssertEqual(data, testImage.kf.jpegRepresentation(compressionQuality: 0.8))

                exp.fulfill()
            }
        waitForExpectations(timeout: 3.0)
    }
    
    func testImageResultContainsDataWhenDownloaded() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.data())
            XCTAssertEqual(result.value!.data(), testImageData)
            XCTAssertEqual(result.value!.cacheType, .none)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageResultContainsDataWhenLoadFromMemoryCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url) { _ in
            self.manager.retrieveImage(with: url) { result in
                XCTAssertEqual(result.value!.cacheType, .memory)
                XCTAssertNotNil(result.value?.data())
                XCTAssertEqual(
                    result.value!.data(),
                    DefaultCacheSerializer.default.data(with: result.value!.image, original: nil)
                )
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageResultContainsDataWhenLoadFromDiskCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url) { _ in
            self.manager.cache.clearMemoryCache()
            self.manager.retrieveImage(with: url) { result in
                XCTAssertEqual(result.value!.cacheType, .disk)
                XCTAssertNotNil(result.value?.data())
                XCTAssertEqual(
                    result.value!.data(),
                    DefaultCacheSerializer.default.data(with: result.value!.image, original: nil)
                )
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // https://github.com/onevcat/Kingfisher/issues/1923
    func testAnimatedImageShouldRecreateFromCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let data = testImageGIFData
        stub(url, data: data)
        let p = SimpleProcessor()
        manager.retrieveImage(with: url, options: [.processor(p), .onlyLoadFirstFrame]) { result in
            XCTAssertTrue(p.processed)
            XCTAssertTrue(result.value!.image.creatingOptions!.onlyFirstFrame)
            p.processed = false
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertTrue(p.processed)
                XCTAssertFalse(result.value!.image.creatingOptions!.onlyFirstFrame)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testAnimatedImageShouldNotRecreateWithSameOptions() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let data = testImageGIFData
        stub(url, data: data)
        let p = SimpleProcessor()
        manager.retrieveImage(with: url, options: [.processor(p), .onlyLoadFirstFrame]) { result in
            XCTAssertTrue(p.processed)
            XCTAssertTrue(result.value!.image.creatingOptions!.onlyFirstFrame)
            p.processed = false
            self.manager.retrieveImage(with: url, options: [.processor(p), .onlyLoadFirstFrame]) { result in
                XCTAssertFalse(p.processed)
                XCTAssertTrue(result.value!.image.creatingOptions!.onlyFirstFrame)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testMissingResourceOfLivePhotoFound() {
        let resource = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        let source = LivePhotoSource(resources: [resource])
        
        let missing = manager.missingResources(source, options: .init(.empty))
        XCTAssertEqual(missing.count, 1)
    }
    
    func testMissingResourceOfLivePhotoNotFound() async throws {
        let resource = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        
        try await manager.cache.storeToDisk(
            testImageData,
            forKey: resource.cacheKey,
            forcedExtension: resource.downloadURL.pathExtension
        )
        
        let source = LivePhotoSource(resources: [resource])
        let missing = manager.missingResources(source, options: .init(.empty))
        XCTAssertEqual(missing.count, 0)
    }
    
    func testMissingResourceOfLivePhotoFoundOne() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        
        try await manager.cache.storeToDisk(
            testImageData,
            forKey: resource1.cacheKey,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        
        let source = LivePhotoSource(resources: [resource1, resource2])
        let missing = manager.missingResources(source, options: .init(.empty))
        XCTAssertEqual(missing.count, 1)
        XCTAssertEqual(missing[0].downloadURL, resource2.downloadURL)
    }
    
    func testMissingResourceOfLivePhotoForceRefresh() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        
        try await manager.cache.storeToDisk(
            testImageData,
            forKey: resource1.cacheKey,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        
        let source = LivePhotoSource(resources: [resource1, resource2])
        let missing = manager.missingResources(source, options: .init([.forceRefresh]))
        XCTAssertEqual(missing.count, 2)
        XCTAssertEqual(missing[0].downloadURL, resource1.downloadURL)
        XCTAssertEqual(missing[1].downloadURL, resource2.downloadURL)
    }
    
    func testDownloadAndCacheLivePhotoResourcesAll() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        
        stub(resource1.downloadURL, data: testImageData)
        stub(resource2.downloadURL, data: testImageData)
        
        let result = try await manager.downloadAndCache(
            resources: [resource1, resource2].map { LivePhotoResource.init(resource: $0)
            },
            options: .init(.empty))
        XCTAssertEqual(result.count, 2)
        
        let urls = result.compactMap(\.url)
        XCTAssertTrue(urls.contains(LivePhotoURL.mov))
        XCTAssertTrue(urls.contains(LivePhotoURL.heic))
        
        let resourceCached1 = manager.cache.imageCachedType(
            forKey: resource1.cacheKey,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        let resourceCached2 = manager.cache.imageCachedType(
            forKey: resource2.cacheKey,
            forcedExtension: resource2.downloadURL.pathExtension
        )
        XCTAssertEqual(resourceCached1, .disk)
        XCTAssertEqual(resourceCached2, .disk)
    }
    
    func testRetrieveLivePhotoFromNetwork() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        
        stub(resource1.downloadURL, data: testImageData)
        stub(resource2.downloadURL, data: testImageData)
        
        let resource1Cached = manager.cache.isCached(
            forKey: resource1.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier
        )
        let resource2Cached = manager.cache.isCached(
            forKey: resource2.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier
        )
        XCTAssertFalse(resource1Cached)
        XCTAssertFalse(resource2Cached)
        
        let source = LivePhotoSource(resources: [resource1, resource2])
        let result = try await manager.retrieveLivePhoto(with: source)
        XCTAssertEqual(result.fileURLs.count, 2)
        result.fileURLs.forEach { url in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        XCTAssertEqual(result.cacheType, .none)
        XCTAssertEqual(result.data(), [testImageData, testImageData])
        let urlsInSource = result.source.resources.map(\.downloadURL)
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.mov))
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.heic))
    }
    
    func testRetrieveLivePhotoFromLocal() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        
        try await manager.cache.storeToDisk(
            testImageData,
            forKey: resource1.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        try await manager.cache.storeToDisk(
            testImageData,
            forKey: resource2.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource2.downloadURL.pathExtension
        )
        
        let resource1Cached = manager.cache.isCached(
            forKey: resource1.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        let resource2Cached = manager.cache.isCached(
            forKey: resource2.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource2.downloadURL.pathExtension
        )
        XCTAssertTrue(resource1Cached)
        XCTAssertTrue(resource2Cached)
        
        let source = LivePhotoSource(resources: [resource1, resource2])
        let result = try await manager.retrieveLivePhoto(with: source)
        XCTAssertEqual(result.fileURLs.count, 2)
        result.fileURLs.forEach { url in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        XCTAssertEqual(result.cacheType, .disk)
        XCTAssertEqual(result.data(), [])
        let urlsInSource = result.source.resources.map(\.downloadURL)
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.mov))
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.heic))
    }
    
    func testRetrieveLivePhotoMixed() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        
        try await manager.cache.storeToDisk(
            testImageData,
            forKey: resource1.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        stub(resource2.downloadURL, data: testImageData)
        
        let resource1Cached = manager.cache.isCached(
            forKey: resource1.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        let resource2Cached = manager.cache.isCached(
            forKey: resource2.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource2.downloadURL.pathExtension
        )
        XCTAssertTrue(resource1Cached)
        XCTAssertFalse(resource2Cached)
        
        let source = LivePhotoSource(resources: [resource1, resource2])
        let result = try await manager.retrieveLivePhoto(with: source)
        XCTAssertEqual(result.fileURLs.count, 2)
        result.fileURLs.forEach { url in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        XCTAssertEqual(result.cacheType, .none)
        XCTAssertEqual(result.data(), [testImageData])
        let urlsInSource = result.source.resources.map(\.downloadURL)
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.mov))
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.heic))
    }
    
    func testRetrieveLivePhotoNetworkThenCache() async throws {
        let resource1 = KF.ImageResource(downloadURL: LivePhotoURL.mov)
        let resource2 = KF.ImageResource(downloadURL: LivePhotoURL.heic)
        
        stub(resource1.downloadURL, data: testImageData)
        stub(resource2.downloadURL, data: testImageData)
        
        let resource1Cached = manager.cache.isCached(
            forKey: resource1.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource1.downloadURL.pathExtension
        )
        let resource2Cached = manager.cache.isCached(
            forKey: resource2.cacheKey,
            processorIdentifier: LivePhotoImageProcessor.default.identifier,
            forcedExtension: resource2.downloadURL.pathExtension
        )
        XCTAssertFalse(resource1Cached)
        XCTAssertFalse(resource2Cached)
        
        let source = LivePhotoSource(resources: [resource1, resource2])
        let result = try await manager.retrieveLivePhoto(with: source)
        XCTAssertEqual(result.fileURLs.count, 2)
        result.fileURLs.forEach { url in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        XCTAssertEqual(result.cacheType, .none)
        XCTAssertEqual(result.data(), [testImageData, testImageData])
        let urlsInSource = result.source.resources.map(\.downloadURL)
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.mov))
        XCTAssertTrue(urlsInSource.contains(LivePhotoURL.heic))
        
        let localResult = try await manager.retrieveLivePhoto(with: source)
        XCTAssertEqual(localResult.fileURLs.count, 2)
        XCTAssertEqual(localResult.cacheType, .disk)
    }
    
    func testDownloadAndCacheLivePhotoWithEmptyResources() async throws {
        let result = try await manager.downloadAndCache(resources: [], options: .init([]))
        XCTAssertTrue(result.isEmpty)
    }
    
    func testDownloadAndCacheLivePhotoWithSingleResource() async throws {
        let resource = LivePhotoResource(downloadURL: LivePhotoURL.heic)
        stub(resource.downloadURL!, data: testImageData)
        
        let result = try await manager.downloadAndCache(resources: [resource], options: .init([]))
        XCTAssertEqual(result.count, 1)
        
        let t = manager.cache.imageCachedType(forKey: resource.cacheKey, forcedExtension: "heic")
        XCTAssertEqual(t, .disk)
    }
    
    func testDownloadAndCacheLivePhotoWithSingleResourceGuessingUnsupportedExtension() async throws {
        let resource = LivePhotoResource(downloadURL: URL(string: "https://example.com")!)
        stub(resource.downloadURL!, data: testImageData)
        
        XCTAssertEqual(resource.referenceFileType, .other(""))
        
        let result = try await manager.downloadAndCache(resources: [resource], options: .init([]))
        XCTAssertEqual(result.count, 1)
        
        var cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey, forcedExtension: "heic")
        XCTAssertEqual(cacheType, .none)
        
        cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey)
        XCTAssertEqual(cacheType, .disk)
    }
    
    func testDownloadAndCacheLivePhotoWithSingleResourceExplicitSetExtension() async throws {
        let resource = LivePhotoResource(downloadURL: URL(string: "https://example.com")!, fileType: .heic)
        stub(resource.downloadURL!, data: testImageData)
        
        XCTAssertEqual(resource.referenceFileType, .heic)
        
        let result = try await manager.downloadAndCache(resources: [resource], options: .init([]))
        XCTAssertEqual(result.count, 1)
        
        var cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey, forcedExtension: "heic")
        XCTAssertEqual(cacheType, .disk)
        
        cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey)
        XCTAssertEqual(cacheType, .none)
    }
    
    func testDownloadAndCacheLivePhotoWithSingleResourceGuessingHEICExtension() async throws {
        let resource = LivePhotoResource(downloadURL: URL(string: "https://example.com")!)
        stub(resource.downloadURL!, data: partitalHEICData)
        
        XCTAssertEqual(resource.referenceFileType, .other(""))
        
        let result = try await manager.downloadAndCache(resources: [resource], options: .init([]))
        XCTAssertEqual(result.count, 1)
        
        var cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey, forcedExtension: "heic")
        XCTAssertEqual(cacheType, .disk)
        
        cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey)
        XCTAssertEqual(cacheType, .none)
    }
    
    func testDownloadAndCacheLivePhotoWithSingleResourceGuessingMOVExtension() async throws {
        let resource = LivePhotoResource(downloadURL: URL(string: "https://example.com")!)
        stub(resource.downloadURL!, data: partitalMOVData)
        
        XCTAssertEqual(resource.referenceFileType, .other(""))
        
        let result = try await manager.downloadAndCache(resources: [resource], options: .init([]))
        XCTAssertEqual(result.count, 1)
        
        var cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey, forcedExtension: "mov")
        XCTAssertEqual(cacheType, .disk)
        
        cacheType = manager.cache.imageCachedType(forKey: resource.cacheKey)
        XCTAssertEqual(cacheType, .none)
    }
}

private var imageCreatingOptionsKey: Void?

extension KFCrossPlatformImage {
    var creatingOptions: ImageCreatingOptions? {
        get { return getAssociatedObject(self, &imageCreatingOptionsKey) }
        set { setRetainedAssociatedObject(self, &imageCreatingOptionsKey, newValue) }
    }
}

final class SimpleProcessor: ImageProcessor, @unchecked Sendable {
    public let identifier = "id"
    var processed = false
    /// Initialize a `DefaultImageProcessor`
    public init() {}
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        processed = true
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            let creatingOptions = options.imageCreatingOptions
            let image = KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: creatingOptions)
            image?.creatingOptions = creatingOptions
            return image
        }
    }
}

final class FailingProcessor: ImageProcessor, @unchecked Sendable {
    public let identifier = "FailingProcessor"
    var processed = false
    public init() {}
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        processed = true
        return nil
    }
}

struct SimpleImageDataProvider: ImageDataProvider, @unchecked Sendable {
    let cacheKey: String
    let provider: () -> (Result<Data, any Error>)
    
    func data(handler: @escaping (Result<Data, any Error>) -> Void) {
        handler(provider())
    }
    
    struct E: Error {}
}

actor ActorArray<Element> {
    var value: [Element]
    init(_ value: [Element]) {
        self.value = value
    }
    
    func append(_ newElement: Element) {
        value.append(newElement)
    }
}
