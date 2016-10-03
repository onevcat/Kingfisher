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
        let uuid = UUID().uuidString
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
        
        let expectation = self.expectation(description: "wait for clearing disk cache")
        let key = testKeys[0]
        
        cache.store(testImage, original: testImageData as? Data, forKey: key, toDisk: true) { () -> () in
            self.cache.clearMemoryCache()
            let cacheResult = self.cache.isImageCached(forKey: key)
            XCTAssertTrue(cacheResult.cached, "Should be cached")
            XCTAssert(cacheResult.cacheType == .disk, "Should be cached in disk")
        
            self.cache.clearDiskCache {
                let cacheResult = self.cache.isImageCached(forKey: key)
                XCTAssertFalse(cacheResult.cached, "Should be not cached")
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler:nil)
    }
    
    func testClearMemoryCache() {
        let expectation = self.expectation(description: "wait for retrieving image")
        
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], toDisk: true) { () -> () in
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: testKeys[0], options: nil, completionHandler: { (image, type) -> () in
                XCTAssert(image != nil && type == .disk, "Should be cached in disk. But \(type)")

                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNoImageFound() {
        let expectation = self.expectation(description: "wait for retrieving image")
        
        cache.clearDiskCache {
            self.cache.retrieveImage(forKey: testKeys[0], options: nil, completionHandler: { (image, type) -> () in
                XCTAssert(image == nil, "Should not be cached in memory yet")
                expectation.fulfill()
            })
            return
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreImageInMemory() {
        let expectation = self.expectation(description: "wait for retrieving image")
        
        cache.store(testImage, forKey: testKeys[0], toDisk: false) { () -> () in
            self.cache.retrieveImage(forKey: testKeys[0], options: nil, completionHandler: { (image, type) -> () in
                XCTAssert(image != nil && type == .memory, "Should be cached in memory.")
                expectation.fulfill()
            })
            return
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreMultipleImages() {
        let expectation = self.expectation(description: "wait for writing image")
        
        storeMultipleImages { () -> () in
            let diskCachePath = self.cache.diskCachePath
            let files: [String]?
            do {
                files = try FileManager.default.contentsOfDirectory(atPath: diskCachePath)
            } catch _ {
                files = nil
            }
            XCTAssert(files?.count == 4, "All test images should be at locaitons. Expected 4, actually \(files?.count)")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCachedFileExists() {
        let expectation = self.expectation(description: "cache does contain image")
        
        let URLString = testKeys[0]
        let url = URL(string: URLString)!
        
        let exists = cache.isImageCached(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
        
        cache.retrieveImage(forKey: URLString, options: nil, completionHandler: { (image, type) -> () in
            XCTAssertNil(image, "Should not be cached yet")
            
            XCTAssertEqual(type, .none)

            self.cache.store(testImage, forKey: URLString, toDisk: true) { () -> () in
                self.cache.retrieveImage(forKey: URLString, options: nil, completionHandler: { (image, type) -> () in
                    XCTAssertNotNil(image, "Should be cached (memory or disk)")
                    XCTAssertEqual(type, .memory)

                    let exists = self.cache.isImageCached(forKey: url.cacheKey).cached
                    XCTAssertTrue(exists, "Image should exist in the cache (memory or disk)")

                    self.cache.clearMemoryCache()
                    self.cache.retrieveImage(forKey: URLString, options: nil, completionHandler: { (image, type) -> () in
                        XCTAssertNotNil(image, "Should be cached (disk)")
                        XCTAssertEqual(type, CacheType.disk)
                        
                        let exists = self.cache.isImageCached(forKey: url.cacheKey).cached
                        XCTAssertTrue(exists, "Image should exist in the cache (disk)")
                        
                        expectation.fulfill()
                    })
                })
            }
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCachedFileDoesNotExist() {
        let URLString = testKeys[0]
        let url = URL(string: URLString)!
        
        let exists = cache.isImageCached(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
    }

    func testCachedFileWithCustomPathExtensionExists() {
        cache.pathExtension = "jpg"
        let expectation = self.expectation(description: "cache with custom path extension does contain image")
        
        let URLString = testKeys[0]
        let url = URL(string: URLString)!
        
        let exists = cache.isImageCached(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
        
        cache.retrieveImage(forKey: URLString, options: nil, completionHandler: { (image, type) -> () in
            XCTAssertNil(image, "Should not be cached yet")
            
            XCTAssertEqual(type, .none)
            
            self.cache.store(testImage, forKey: URLString, toDisk: true) { () -> () in
                self.cache.retrieveImage(forKey: URLString, options: nil, completionHandler: { (image, type) -> () in
                    XCTAssertNotNil(image, "Should be cached (memory or disk)")
                    XCTAssertEqual(type, .memory)
                    
                    let exists = self.cache.isImageCached(forKey: url.cacheKey).cached
                    XCTAssertTrue(exists, "Image should exist in the cache (memory or disk)")
                    
                    self.cache.clearMemoryCache()
                    self.cache.retrieveImage(forKey: URLString, options: nil, completionHandler: { (image, type) -> () in
                        XCTAssertNotNil(image, "Should be cached (disk)")
                        XCTAssertEqual(type, CacheType.disk)
                        
                        let exists = self.cache.isImageCached(forKey: url.cacheKey).cached
                        XCTAssertTrue(exists, "Image should exist in the cache (disk)")
                        
                        let cachePath = self.cache.cachePath(forKey: url.cacheKey)
                        let hasExtension = cachePath.hasSuffix(".jpg")
                        XCTAssert(hasExtension, "Should have .jpg file extension")
                        
                        expectation.fulfill()
                    })
                })
            }
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }

  
    func testCachedImageIsFetchedSyncronouslyFromTheMemoryCache() {
        cache.store(testImage, forKey: testKeys[0], toDisk: false) { () -> () in
            // do nothing
        }

        var foundImage: Image?

        cache.retrieveImage(forKey: testKeys[0], options: [.backgroundDecode]) { (image, type) -> () in
            foundImage = image
        }

        XCTAssertEqual(testImage, foundImage, "should have found the image immediately")
    }

    func testIsImageCachedForKey() {
        let expectation = self.expectation(description: "wait for caching image")
        
        XCTAssert(self.cache.isImageCached(forKey: testKeys[0]).cached == false, "This image should not be cached yet.")
        self.cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], toDisk: true) { () -> () in
            XCTAssert(self.cache.isImageCached(forKey: testKeys[0]).cached == true, "This image should be already cached.")
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRetrievingImagePerformance() {

        let expectation = self.expectation(description: "wait for retrieving image")
        self.cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], toDisk: true) { () -> () in
            self.measure({ () -> Void in
                for _ in 1 ..< 200 {
                    _ = self.cache.retrieveImageInDiskCache(forKey: testKeys[0])
                }
            })
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testCleanDiskCacheNotification() {
        let expectation = self.expectation(description: "wait for retrieving image")
        
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], toDisk: true) { () -> () in

            self.observer = NotificationCenter.default.addObserver(forName: .KingfisherDidCleanDiskCache, object: self.cache, queue: OperationQueue.main, using: { (noti) -> Void in

                let receivedCache = noti.object as? ImageCache
                XCTAssertNotNil(receivedCache)
                XCTAssert(receivedCache === self.cache, "The object of notification should be the cache object.")
                
                guard let hashes = (noti as NSNotification).userInfo?[KingfisherDiskCacheCleanedHashKey] as? [String] else {
                    XCTFail("The clean disk cache notification should contains Strings in key 'KingfisherDiskCacheCleanedHashKey'")
                    expectation.fulfill()
                    return
                }
                
                XCTAssertEqual(1, hashes.count, "There should be one and only one file cleaned")
                XCTAssertEqual(hashes.first!, self.cache.hash(forKey: testKeys[0]), "The cleaned file should be the stored one.")
                
                NotificationCenter.default.removeObserver(self.observer)
                expectation.fulfill()
            })
            
            self.cache.maxCachePeriodInSecond = 0
            self.cache.cleanExpiredDiskCache()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCannotRetrieveCacheWithProcessorIdentifier() {
        let expectation = self.expectation(description: "wait for retrieving image")
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], toDisk: true) { () -> () in
            
            self.cache.retrieveImage(forKey: testKeys[0], options: [.processor(p)], completionHandler: { (image, type) -> () in
                
                XCTAssert(image == nil, "The image with prosossor should not be cached yet.")
                
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRetrieveCacheWithProcessorIdentifier() {
        let expectation = self.expectation(description: "wait for retrieving image")
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], processorIdentifier: p.identifier,toDisk: true) { () -> () in
            
            self.cache.retrieveImage(forKey: testKeys[0], options: [.processor(p)], completionHandler: { (image, type) -> () in
                
                XCTAssert(image != nil, "The image with prosossor should already be cached.")
                
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // MARK: - Helper
    func storeMultipleImages(_ completionHandler:@escaping ()->()) {
        
        let group = DispatchGroup()
        
        group.enter()
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[0], toDisk: true) { () -> () in
            group.leave()
        }
        group.enter()
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[1], toDisk: true) { () -> () in
            group.leave()
        }
        group.enter()
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[2], toDisk: true) { () -> () in
            group.leave()
        }
        group.enter()
        cache.store(testImage, original: testImageData as? Data, forKey: testKeys[3], toDisk: true) { () -> () in
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            completionHandler()
        }
    }
}
