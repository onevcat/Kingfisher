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
        var progressCalledCount = 0
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache],
            progressBlock: { _, _, _ in progressCalledCount += 1 }) {
                skippedResources, failedResources, completedResources in

                XCTAssertEqual(skippedResources.count, 0)
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, testURLs.count)
                XCTAssertEqual(progressCalledCount, testURLs.count)
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
            options: [.waitForCache])
        {
            skippedResources, failedResources, completedResources in
            
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, testURLs.count)
            XCTAssertEqual(completedResources.count, 0)
            delay(0.1) { exp.fulfill() }
        }
        
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
        KingfisherManager.shared.cache.store(Image(), forKey: testKeys[0])
        
        testURLs.forEach { stub($0, data: testImageData) }
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache])
        {
            skippedResources, failedResources, completedResources in
            XCTAssertEqual(skippedResources.count, 1)
            XCTAssertEqual(skippedResources[0].downloadURL, testURLs[0])
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, testURLs.count - 1)
            exp.fulfill()
        }
        
        prefetcher.start()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPrefetcherForceRefreshDownloadImages() {
        let exp = expectation(description: #function)
        KingfisherManager.shared.cache.store(Image(), forKey: testKeys[0])
        
        testURLs.forEach { stub($0, data: testImageData) }
        let prefetcher = ImagePrefetcher(urls: testURLs, options: [.forceRefresh, .waitForCache]) {
            skippedResources, failedResources, completedResources in
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, testURLs.count)
            exp.fulfill()
        }
        
        prefetcher.start()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPrefetchWithWrongInitParameters() {
        let exp = expectation(description: #function)
        let prefetcher = ImagePrefetcher(urls: [], options: [.waitForCache]) {
            skippedResources, failedResources, completedResources in
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, 0)
            exp.fulfill()
        }
        
        prefetcher.start()
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFetchWithProcessor() {
        let exp = expectation(description: #function)
        testURLs.forEach { stub($0, data: testImageData, length: 123) }
        
        let p = RoundCornerImageProcessor(cornerRadius: 20)
        
        func prefetchAgain() {
            var progressCalledCount = 0
            let prefetcher = ImagePrefetcher(
                urls: testURLs,
                options: [.processor(p), .waitForCache],
                progressBlock: { _, _, _ in progressCalledCount += 1 })
            {
                skippedResources, failedResources, completedResources in
                                                
                XCTAssertEqual(skippedResources.count, testURLs.count)
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, 0)
                XCTAssertEqual(progressCalledCount, testURLs.count)
                for url in testURLs {
                    let cached = KingfisherManager.shared.cache.imageCachedType(
                        forKey: url.absoluteString, processorIdentifier: p.identifier).cached
                    XCTAssertTrue(cached)
                }
                exp.fulfill()

            }
            prefetcher.start()
        }
        
        var progressCalledCount = 0
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.processor(p), .waitForCache],
            progressBlock: { _, _, _ in progressCalledCount += 1 })
        {
            skippedResources, failedResources, completedResources in
                                            
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, testURLs.count)
            XCTAssertEqual(progressCalledCount, testURLs.count)
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
        cache.store(Image(), forKey: key)
        cache.store(testImage, forKey: key) { result in
            try! cache.memoryStorage.remove(forKey: key)
            
            XCTAssertEqual(cache.imageCachedType(forKey: key), .disk)
            
            testURLs.forEach { stub($0, data: testImageData) }
            let prefetcher = ImagePrefetcher(
                urls: testURLs,
                options: [.waitForCache, .alsoPrefetchToMemory])
            {
                skippedResources, failedResources, completedResources in
                
                XCTAssertEqual(cache.imageCachedType(forKey: key), .memory)
                
                XCTAssertEqual(skippedResources.count, 1)
                XCTAssertEqual(skippedResources[0].downloadURL, testURLs[0])
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, testURLs.count - 1)
                exp.fulfill()
            }
            
            prefetcher.start()
            
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNotPrefetchToMemory() {
        let exp = expectation(description: #function)
        let cache = KingfisherManager.shared.cache
        let key = testKeys[0]

        cache.store(testImage, forKey: key) { result in
            try! cache.memoryStorage.remove(forKey: key)
            
            XCTAssertEqual(cache.imageCachedType(forKey: key), .disk)
            
            testURLs.forEach { stub($0, data: testImageData) }
            let prefetcher = ImagePrefetcher(
                urls: testURLs,
                options: [.waitForCache])
            {
                skippedResources, failedResources, completedResources in
                
                XCTAssertEqual(cache.imageCachedType(forKey: key), .disk)
                
                XCTAssertEqual(skippedResources.count, 1)
                XCTAssertEqual(skippedResources[0].downloadURL, testURLs[0])
                XCTAssertEqual(failedResources.count, 0)
                XCTAssertEqual(completedResources.count, testURLs.count - 1)
                exp.fulfill()
            }
            
            prefetcher.start()
            
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPrefetchMoreTaskThanMaxConcurrency() {
        let exp = expectation(description: #function)
        
        testURLs.forEach { stub($0, data: testImageData) }
        let prefetcher = ImagePrefetcher(
            urls: testURLs,
            options: [.waitForCache])
        {
            skippedResources, failedResources, completedResources in
            XCTAssertEqual(skippedResources.count, 0)
            XCTAssertEqual(failedResources.count, 0)
            XCTAssertEqual(completedResources.count, testURLs.count)
            exp.fulfill()
        }
        prefetcher.maxConcurrentDownloads = 1
        prefetcher.start()
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPrefetchMultiTimes() {
        let exp = expectation(description: #function)
        let group = DispatchGroup()
        testURLs.forEach { stub($0, data: testImageData) }
        for _ in 0..<10000 {
            group.enter()
            let prefetcher = ImagePrefetcher(
                resources: testURLs,
                options: [.cacheMemoryOnly])
            { _, _, _ in group.leave() }
            prefetcher.start()
        }
        group.notify(queue: .main) { exp.fulfill() }
        waitForExpectations(timeout: 5, handler: nil)
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
        var counter = 0
        let prefetcher = ImagePrefetcher(
            sources: sources,
            options: [.waitForCache],
            progressBlock: {
                skipped, failed, completed in
                counter += 1
                XCTAssertEqual(skipped.count, 0)
                XCTAssertEqual(failed.count, 0)
                XCTAssertEqual(completed.count, counter)
            },
            completionHandler: {
                skipped, failed, completed in
                XCTAssertEqual(skipped.count, 0)
                XCTAssertEqual(failed.count, 0)
                XCTAssertEqual(completed.count, sources.count)
                XCTAssertEqual(counter, sources.count)

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
