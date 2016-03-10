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
import Kingfisher

#if os(OSX)
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
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cleanDefaultCache()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cleanDefaultCache()
        super.tearDown()
    }

    func testPrefetchingImages() {
        let expectation = expectationWithDescription("wait for prefetching images")
        
        var urls = [NSURL]()
        for URLString in testKeys {
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            urls.append(NSURL(string: URLString)!)
        }
        
        var progressCalledCount = 0
        let prefetcher = ImagePrefetcher(urls: urls, optionsInfo: nil, progressBlock: { (skippedResources, failedResources, completedResources) -> () in
            progressCalledCount += 1
            }) { (skippedResources, failedResources, completedResources) -> () in
                expectation.fulfill()
                XCTAssertEqual(skippedResources.count, 0, "There should be no items skipped.")
                XCTAssertEqual(failedResources.count, 0, "There should be no failed downloading.")
                XCTAssertEqual(completedResources.count, urls.count, "All resources prefetching should be completed.")
                XCTAssertEqual(progressCalledCount, urls.count, "Progress should be called the same time of download count.")
                for url in urls {
                    XCTAssertTrue(KingfisherManager.sharedManager.cache.isImageCachedForKey(url.absoluteString).cached)
                }
        }
        
        prefetcher.start()
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testCancelPrefetching() {
        let expectation = expectationWithDescription("wait for prefetching images")
        
        var urls = [NSURL]()
        var responses = [LSStubResponseDSL!]()
        for URLString in testKeys {
            let response = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
            responses.append(response)
            urls.append(NSURL(string: URLString)!)
        }
        
        let maxConcurrentCount = 2
        let prefetcher = ImagePrefetcher(urls: urls, optionsInfo: nil, progressBlock: { (skippedResources, failedResources, completedResources) -> () in
            
            }) { (skippedResources, failedResources, completedResources) -> () in
                expectation.fulfill()
                XCTAssertEqual(skippedResources.count, 0, "There should be no items skipped.")
                XCTAssertEqual(failedResources.count, urls.count, "The failed count should be the same with started downloads due to cancellation.")
                XCTAssertEqual(completedResources.count, 0, "None resources prefetching should complete.")
        }
        
        prefetcher.maxConcurrentDownloads = maxConcurrentCount
        
        prefetcher.start()
        prefetcher.stop()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            for response in responses {
                response.go()
            }
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }
    

    func testPrefetcherCouldSkipCachedImages() {
        let expectation = expectationWithDescription("wait for prefetching images")
        KingfisherManager.sharedManager.cache.storeImage(Image(), forKey: testKeys[0])
        
        var urls = [NSURL]()
        for URLString in testKeys {
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            urls.append(NSURL(string: URLString)!)
        }
        
        let prefetcher = ImagePrefetcher(urls: urls, optionsInfo: nil, progressBlock: { (skippedResources, failedResources, completedResources) -> () in

            }) { (skippedResources, failedResources, completedResources) -> () in
                expectation.fulfill()
                XCTAssertEqual(skippedResources.count, 1, "There should be 1 item skipped.")
                XCTAssertEqual(skippedResources[0].downloadURL.absoluteString, testKeys[0], "The correct image key should be skipped.")

                XCTAssertEqual(failedResources.count, 0, "There should be no failed downloading.")
                XCTAssertEqual(completedResources.count, urls.count - 1, "All resources prefetching should be completed.")
        }
        
        prefetcher.start()
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testPrefetcherForceRefreshDownloadImages() {
        let expectation = expectationWithDescription("wait for prefetching images")
        
        // Store an image in cache.
        KingfisherManager.sharedManager.cache.storeImage(Image(), forKey: testKeys[0])
        
        var urls = [NSURL]()
        for URLString in testKeys {
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            urls.append(NSURL(string: URLString)!)
        }
        
        // Use `.ForceRefresh` to download it forcely.
        let prefetcher = ImagePrefetcher(urls: urls, optionsInfo: [.ForceRefresh], progressBlock: { (skippedResources, failedResources, completedResources) -> () in
            
            }) { (skippedResources, failedResources, completedResources) -> () in
                expectation.fulfill()
                
                XCTAssertEqual(skippedResources.count, 0, "There should be no item skipped.")
                XCTAssertEqual(failedResources.count, 0, "There should be no failed downloading.")
                XCTAssertEqual(completedResources.count, urls.count, "All resources prefetching should be completed.")
        }
        
        prefetcher.start()
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testPrefetchWithWrongInitParameters() {
        let expectation = expectationWithDescription("wait for prefetching images")
        let prefetcher = ImagePrefetcher(urls: [], optionsInfo: nil, progressBlock: nil) { (skippedResources, failedResources, completedResources) -> () in
            expectation.fulfill()
            
            XCTAssertEqual(skippedResources.count, 0, "There should be no item skipped.")
            XCTAssertEqual(failedResources.count, 0, "There should be no failed downloading.")
            XCTAssertEqual(completedResources.count, 0, "There should be no completed downloading.")
        }
        
        prefetcher.start()
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
