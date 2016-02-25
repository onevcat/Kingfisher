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

    var manager: KingfisherManager!
    
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
        manager = KingfisherManager()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cleanDefaultCache()
        manager = nil
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
        
        manager.prefetcher.prefetchURLs(urls, progressBlock: { (completedURLs, allURLs) -> () in
            XCTAssertEqual(allURLs, total, "total urls should match all those the prefetcher knows about")
        }) { (completedURLs, skippedURLs) -> () in
            expectation.fulfill()
            XCTAssertEqual(completedURLs, total, "all requests should have been completed, regardless of success")
            KingfisherManager.sharedManager.cache.clearMemoryCache()  // Remove from the Memory cache to ensure it is on disk!
            let cacheStatus = KingfisherManager.sharedManager.cache.isImageCachedForKey(Resource(downloadURL: urls[0]).cacheKey)
            XCTAssertEqual(CacheType.Disk, cacheStatus.cacheType ?? CacheType.None, "prefetched images should be cached to disk")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
