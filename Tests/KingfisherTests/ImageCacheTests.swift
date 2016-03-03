//
//  ImageCacheTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
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

class ImageCacheTests: XCTestCase {

    var cache: ImageCache!
    var observer: NSObjectProtocol!
    private var cacheName = "com.onevcat.Kingfisher.ImageCache.test"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let uuid = NSUUID().UUIDString
        cacheName = "test-\(uuid)"
        cache = ImageCache(name: cacheName)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        clearCaches([cache])
        cache = nil
        observer = nil
    }
    
    func testCustomCachePath() {
        let customPath = "/path/to/image/cache"
        let cache = ImageCache(name: "test", path: customPath)
        XCTAssertEqual(cache.diskCachePath, customPath + "/com.onevcat.Kingfisher.ImageCache.test", "Custom disk cache path set correctly")
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
        
        let expectation = expectationWithDescription("wait for clearing disk cache")
        let key = testKeys[0]
        
        cache.storeImage(testImage, originalData: testImageData, forKey: key, toDisk: true) { () -> () in
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
        let expectation = expectationWithDescription("wait for retrieving image")
        
        cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[0], toDisk: true) { () -> () in
            self.cache.clearMemoryCache()
            self.cache.retrieveImageForKey(testKeys[0], options: nil, completionHandler: { (image, type) -> () in
                XCTAssert(image != nil && type == .Disk, "Should be cached in disk. But \(type)")

                expectation.fulfill()
            })
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testNoImageFound() {
        let expectation = expectationWithDescription("wait for retrieving image")
        
        cache.clearDiskCacheWithCompletionHandler { () -> () in
            self.cache.retrieveImageForKey(testKeys[0], options: nil, completionHandler: { (image, type) -> () in
                XCTAssert(image == nil, "Should not be cached in memory yet")
                expectation.fulfill()
            })
            return
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testStoreImageInMemory() {
        let expectation = expectationWithDescription("wait for retrieving image")
        
        cache.storeImage(testImage, forKey: testKeys[0], toDisk: false) { () -> () in
            self.cache.retrieveImageForKey(testKeys[0], options: nil, completionHandler: { (image, type) -> () in
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
            let diskCachePath = self.cache.diskCachePath
            let files: [AnyObject]?
            do {
                files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(diskCachePath)
            } catch _ {
                files = nil
            }
            XCTAssert(files?.count == 4, "All test images should be at locaitons. Expected 4, actually \(files?.count)")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testCachedFileExists() {
        let expectation = expectationWithDescription("cache does contain image")
        
        let URLString = testKeys[0]
        let URL = NSURL(string: URLString)!
        
        let exists = cache.cachedImageExistsforURL(URL)
        XCTAssertFalse(exists)
        
        cache.retrieveImageForKey(URLString, options: nil, completionHandler: { (image, type) -> () in
            XCTAssertNil(image, "Should not be cached yet")
            XCTAssertEqual(type, nil)

            self.cache.storeImage(testImage, forKey: URLString, toDisk: true) { () -> () in
                self.cache.retrieveImageForKey(URLString, options: nil, completionHandler: { (image, type) -> () in
                    XCTAssertNotNil(image, "Should be cached (memory or disk)")
                    XCTAssertEqual(type, CacheType.Memory)

                    let exists = self.cache.cachedImageExistsforURL(URL)
                    XCTAssertTrue(exists, "Image should exist in the cache (memory or disk)")

                    self.cache.clearMemoryCache()
                    self.cache.retrieveImageForKey(URLString, options: nil, completionHandler: { (image, type) -> () in
                        XCTAssertNotNil(image, "Should be cached (disk)")
                        XCTAssertEqual(type, CacheType.Disk)
                        
                        let exists = self.cache.cachedImageExistsforURL(URL)
                        XCTAssertTrue(exists, "Image should exist in the cache (disk)")
                        
                        expectation.fulfill()
                    })
                })
            }
        })
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testCachedFileDoesNotExist() {
        let URLString = testKeys[0]
        let URL = NSURL(string: URLString)!
        
        let exists = cache.cachedImageExistsforURL(URL)
        XCTAssertFalse(exists)
    }

    func testCachedImageIsFetchedSyncronouslyFromTheMemoryCache() {
        cache.storeImage(testImage, forKey: testKeys[0], toDisk: false) { () -> () in
            // do nothing
        }

        var foundImage: Image?

        cache.retrieveImageForKey(testKeys[0], options: [.BackgroundDecode]) { (image, type) -> () in
            foundImage = image
        }

        XCTAssertEqual(testImage, foundImage, "should have found the image immediately")
    }

    func testIsImageCachedForKey() {
        let expectation = self.expectationWithDescription("wait for caching image")
        
        XCTAssert(self.cache.isImageCachedForKey(testKeys[0]).cached == false, "This image should not be cached yet.")
        self.cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[0], toDisk: true) { () -> () in
            XCTAssert(self.cache.isImageCachedForKey(testKeys[0]).cached == true, "This image should be already cached.")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRetrievingImagePerformance() {

        let expectation = self.expectationWithDescription("wait for retrieving image")
        self.cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[0], toDisk: true) { () -> () in
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
        let expectation = expectationWithDescription("wait for retrieving image")
        
        cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[0], toDisk: true) { () -> () in

            self.observer = NSNotificationCenter.defaultCenter().addObserverForName(KingfisherDidCleanDiskCacheNotification, object: self.cache, queue: NSOperationQueue.mainQueue(), usingBlock: { (noti) -> Void in

                XCTAssert(noti.object === self.cache, "The object of notification should be the cache object.")
                
                guard let hashes = noti.userInfo?[KingfisherDiskCacheCleanedHashKey] as? [String] else {
                    XCTFail("The clean disk cache notification should contains Strings in key 'KingfisherDiskCacheCleanedHashKey'")
                    expectation.fulfill()
                    return
                }
                
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
        cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[0], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[1], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[2], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        dispatch_group_enter(group)
        cache.storeImage(testImage, originalData: testImageData, forKey: testKeys[3], toDisk: true) { () -> () in
            dispatch_group_leave(group)
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            completionHandler()
        }
    }
}
