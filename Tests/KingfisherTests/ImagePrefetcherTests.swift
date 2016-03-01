//
//  ImagePrefetcherTests.swift
//  Kingfisher
//
//  Created by Claire Knight <claire.knight@moggytech.co.uk> on 24/02/2016
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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

class ImagePrefetcherTests: XCTestCase {

    var prefetcher: ImagePrefetcher!
    
    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }
    
    override class func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        prefetcher = ImagePrefetcher()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cleanDefaultCache()
        prefetcher = nil
        super.tearDown()
    }

    func testPrefetchingImages() {
        let expectation = expectationWithDescription("wait for prefetching images")
        
        var urls = [NSURL]()
        for URLString in testKeys {
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            urls.append(NSURL(string: URLString)!)
        }

        let total = urls.count
        
        prefetcher.prefetchURLs(urls, progressBlock: { (completedURLs, allURLs) -> () in
            XCTAssertEqual(allURLs, total, "total urls should match all those the prefetcher knows about")
        }) { (cancelled, completedURLs, skippedURLs) -> () in
            expectation.fulfill()
            XCTAssertFalse(cancelled, "the prefetch should not have been cancelled")
            XCTAssertEqual(completedURLs, total, "all requests should have been completed, regardless of success")
            KingfisherManager.sharedManager.cache.clearMemoryCache()  // Remove from the Memory cache to ensure it is on disk!
            let cacheStatus = KingfisherManager.sharedManager.cache.isImageCachedForKey(Resource(downloadURL: urls[0]).cacheKey)
            XCTAssertEqual(CacheType.Disk, cacheStatus.cacheType ?? CacheType.None, "prefetched images should be cached to disk")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testCancelPrefetching() {
        let expectation = expectationWithDescription("wait for prefetching images")
        
        var urls = [NSURL]()
        for URLString in testKeys {
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            urls.append(NSURL(string: URLString)!)
        }
        
        prefetcher.maxConcurrentDownloads = 2
        
        prefetcher.prefetchURLs(urls, progressBlock: { (completedURLs, allURLs) -> () in
            }) { (cancelled, completedURLs, skippedURLs) -> () in
                XCTAssertTrue(cancelled, "the prefetch should have been cancelled")
                // The completed and skipped URLs will depend on how far through the process the prefetch got before the cancel was called
                expectation.fulfill()
        }
        prefetcher.cancelPrefetching()

        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testIsPrefetching() {
        let expectation = expectationWithDescription("wait for prefetching images")
        
        var urls = [NSURL]()
        for URLString in testKeys {
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            urls.append(NSURL(string: URLString)!)
        }
        
        prefetcher.prefetchURLs(urls, progressBlock: { (completedURLs, allURLs) -> () in
            XCTAssertTrue(self.prefetcher.isPrefetching(), "should be prefetching")
            }) { (cancelled, completedURLs, skippedURLs) -> () in
                XCTAssertFalse(cancelled, "the prefetch should not have been cancelled")
                XCTAssertFalse(self.prefetcher.isPrefetching(), "should not be prefetching")
                expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
