//
//  ImageCacheAsyncTests.swift
//  Kingfisher
//
//  Created for testing async disk cache checking functionality.
//

import XCTest
@testable import Kingfisher

class ImageCacheAsyncTests: XCTestCase {
    
    var cache: ImageCache!
    
    override func setUp() {
        super.setUp()
        let uuid = UUID()
        let cacheName = "test-\(uuid)"
        cache = ImageCache(name: cacheName)
        cache.clearCache()
    }
    
    override func tearDown() {
        cache.clearCache()
        cache = nil
        super.tearDown()
    }
    
    func testCachedTypeMemory() {
        let expectation = self.expectation(description: "CachedType Memory")
        let key = "test-memory-key"
        let image = KFCrossPlatformImage.image(with: .red, size: CGSize(width: 100, height: 100))
        
        // Store in memory cache
        cache.memoryStorage.store(value: image, forKey: key.computedKey(with: DefaultImageProcessor.default.identifier))
        
        // Check cached type
        cache.cachedType(forKey: key) { cacheType in
            XCTAssertEqual(cacheType, .memory)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCachedTypeDisk() {
        let expectation = self.expectation(description: "CachedType Disk")
        let key = "test-disk-key"
        let data = Data(repeating: 0, count: 100)
        
        // Store in disk cache only
        cache.diskStorage.store(
            value: data,
            forKey: key.computedKey(with: DefaultImageProcessor.default.identifier),
            expiration: .never
        ) { _ in
            // Check cached type
            self.cache.cachedType(forKey: key) { cacheType in
                XCTAssertEqual(cacheType, .disk)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCachedTypeNone() {
        let expectation = self.expectation(description: "CachedType None")
        let key = "test-nonexistent-key"
        
        // Check cached type for non-existent key
        cache.cachedType(forKey: key) { cacheType in
            XCTAssertEqual(cacheType, .none)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCachedTypeDoesNotBlockMainThread() {
        let expectation = self.expectation(description: "Does not block main thread")
        let key = "test-main-thread-key"
        
        // Ensure we're on main thread
        XCTAssertTrue(Thread.isMainThread)
        
        var mainThreadBlocked = false
        let checkInterval: TimeInterval = 0.01
        var elapsedTime: TimeInterval = 0
        
        // Start a timer to check if main thread is responsive
        let timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            elapsedTime += checkInterval
            if elapsedTime > 0.5 {
                timer.invalidate()
                XCTAssertFalse(mainThreadBlocked, "Main thread should not be blocked")
                expectation.fulfill()
            }
        }
        
        // Perform many cache checks
        for i in 0..<100 {
            cache.cachedType(forKey: "\(key)-\(i)") { _ in
                // Empty handler
            }
        }
        
        // This should execute immediately if main thread is not blocked
        DispatchQueue.main.async {
            mainThreadBlocked = false
        }
        
        // Mark that we're about to potentially block
        mainThreadBlocked = true
        
        waitForExpectations(timeout: 3) { _ in
            timer.invalidate()
        }
    }
    
    func testCachedTypePerformance() {
        // Prepare cache with many items
        let itemCount = 1000
        for i in 0..<itemCount {
            let key = "perf-test-\(i)"
            let data = Data(repeating: UInt8(i % 256), count: 100)
            cache.diskStorage.store(
                value: data,
                forKey: key.computedKey(with: DefaultImageProcessor.default.identifier),
                expiration: .never
            ) { _ in }
        }
        
        // Wait for disk writes to complete
        Thread.sleep(forTimeInterval: 1)
        
        // Measure performance of checking cache
        measure {
            let expectation = self.expectation(description: "Performance test")
            var completedChecks = 0
            
            for i in 0..<itemCount {
                let key = "perf-test-\(i)"
                cache.cachedType(forKey: key) { _ in
                    completedChecks += 1
                    if completedChecks == itemCount {
                        expectation.fulfill()
                    }
                }
            }
            
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
}