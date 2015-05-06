//
//  ImageCacheTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

import UIKit
import XCTest
import Kingfisher

private let cacheName = "com.onevcat.Kingfisher.ImageCache.test"


class ImageCacheTests: XCTestCase {

    var cache: ImageCache!
    var observer: NSObjectProtocol!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cache = ImageCache(name: "test")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        cache.clearMemoryCache()
        cache.clearDiskCache()
        cache = nil
        observer = nil
    }
    
    func testMaxCachePeriodInSecond() {
        cache.maxCachePeriodInSecond = 1
        XCTAssert(cache.maxCachePeriodInSecond == 1, "maxCachePeriodInSecond should be able to be set.")
    }
    
    func testMaxMemorySize() {
        cache.maxMemoryCost = 1
        XCTAssert(cache.maxMemoryCost == 1, "maxMemoryCost should be able to be set.")
    }
    
    func testMaxDiskCacheSize() {
        cache.maxDiskCacheSize = 1
        XCTAssert(cache.maxDiskCacheSize == 1, "maxDiskCacheSize should be able to be set.")
    }
    
    func testClearDiskCache() {
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let diskCachePath = paths.first!.stringByAppendingPathComponent(cacheName)
        
        let expectation = expectationWithDescription("wait for clearing disk cache")
        let key = testKeys[0]
        
        cache.storeImage(testImage, forKey: key, toDisk: true) { () -> () in
            self.cache.clearMemoryCache()
            let cacheResult = self.cache.isImageCachedForKey(key)
            XCTAssertTrue(cacheResult.cached, "Should be cached")
            XCTAssert(cacheResult.cacheType == .Disk, "Should be cached in disk")
        
            self.cache.clearDiskCacheWithCompletionHandler { () -> () in
                let cacheResult = self.cache.isImageCachedForKey(key)
                XCTAssertFalse(cacheResult.cached, "Should be not cached")
                expectation.fulfill()
            }
        }
        waitForExpectationsWithTimeout(10, handler:nil)
    }
    
    func testClearMemoryCache() {
        let expectation = expectationWithDescription("wait for retriving image")
        
        cache.storeImage(testImage, forKey: testKeys[0], toDisk: true) { () -> () in
            self.cache.clearMemoryCache()
            self.cache.retrieveImageForKey(testKeys[0], options: KingfisherManager.OptionsNone, completionHandler: { (image, type) -> () in
                XCTAssert(image != nil && type == .Disk, "Should be cached in disk.")
                expectation.fulfill()
            })
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testNoImageFound() {
        let expectation = expectationWithDescription("wait for retriving image")
        
        cache.clearDiskCacheWithCompletionHandler { () -> () in
            self.cache.retrieveImageForKey(testKeys[0], options: KingfisherManager.OptionsNone, completionHandler: { (image, type) -> () in
                XCTAssert(image == nil, "Should not be cached in memory yet")
                expectation.fulfill()
            })
            return
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testStoreImageInMemory() {
        let expectation = expectationWithDescription("wait for retriving image")
        
        cache.storeImage(testImage, forKey: testKeys[0], toDisk: false) { () -> () in
            self.cache.retrieveImageForKey(testKeys[0], options: KingfisherManager.OptionsNone, completionHandler: { (image, type) -> () in
                XCTAssert(image != nil && type == .Memory, "Should be cached in memory.")
                expectation.fulfill()
            })
            return
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testStoreMultipleImages() {
        let expectation = expectationWithDescription("wait for writing image")
        
        storeMultipleImages { () -> () in
            let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let diskCachePath = paths.first!.stringByAppendingPathComponent(cacheName)
            
            let files = NSFileManager.defaultManager().contentsOfDirectoryAtPath(diskCachePath, error:nil)
            XCTAssert(files?.count == 4, "All test images should be at locaitons. Expected 4, actually \(files?.count)")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testIsImageCachedForKey() {
        let expectation = self.expectationWithDescription("wait for caching image")
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            XCTAssert(self.cache.isImageCachedForKey(testKeys[0]).cached == false, "This image should not be cached yet.")
            self.cache.storeImage(testImage, forKey: testKeys[0], toDisk: true) { () -> () in
                XCTAssert(self.cache.isImageCachedForKey(testKeys[0]).cached == true, "This image should be already cached.")
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRetrivingImagePerformance() {

        let expectation = self.expectationWithDescription("wait for retriving image")
        self.cache.storeImage(testImage, forKey: testKeys[0], toDisk: true) { () -> () in
            self.measureBlock({ () -> Void in
                for _ in 1 ..< 1000 {
                    self.cache.retrieveImageInDiskCacheForKey(testKeys[0])
                }
            })
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testCleanDiskCacheNotification() {
        let expectation = expectationWithDescription("wait for retriving image")
        
        cache.storeImage(testImage, forKey: testKeys[0], toDisk: true) { () -> () in

            self.observer = NSNotificationCenter.defaultCenter().addObserverForName(KingfisherDidCleanDiskCacheNotification, object: self.cache, queue: NSOperationQueue.mainQueue(), usingBlock: { (noti) -> Void in

                XCTAssert(noti.object === self.cache, "The object of notification should be the cache object.")
                
                let hashes = noti.userInfo?[KingfisherDiskCacheCleanedHashKey] as! [String]
                
                XCTAssertEqual(1, hashes.count, "There should be one and only one file cleaned")
                XCTAssertEqual(hashes.first!, self.cache.hashForKey(testKeys[0]), "The cleaned file should be the stored one.")
                
                NSNotificationCenter.defaultCenter().removeObserver(self.observer)
                expectation.fulfill()
            })
            
            self.cache.maxCachePeriodInSecond = 0
            self.cache.cleanExpiredDiskCache()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    // MARK: - Helper
    func storeMultipleImages(completionHandler:()->()) {
        
        let group = dispatch_group_create()
        
        dispatch_group_enter(group)
        cache.storeImage(testImage, forKey: testKeys[0], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        cache.storeImage(testImage, forKey: testKeys[1], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        cache.storeImage(testImage, forKey: testKeys[2], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        cache.storeImage(testImage, forKey: testKeys[3], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completionHandler()
        }
    }
}
