//
//  ImageCacheTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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
        cache = try! ImageCache(name: cacheName)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        clearCaches([cache])
        cache = nil
        observer = nil
    }
    
    func testInvalidCustomCachePath() {
        let customPath = "/path/to/image/cache"
        XCTAssertThrowsError(try ImageCache(name: "test", path: customPath)) { error in
            guard case KingfisherError2.cacheError(reason: .cannotCreateDirectory(_, let path)) = error else {
                XCTFail("Should be KingfisherError with cacheError reason.")
                return
            }
            XCTAssertEqual(path, customPath + "/com.onevcat.Kingfisher.ImageCache.test")
        }
    }

    func testCustomCachePath() {
        let cacheURL = try! FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let subFolder = cacheURL.appendingPathComponent("temp")

        let customPath = subFolder.absoluteString
        let cache = try! ImageCache(name: "test", path: customPath)
        XCTAssertEqual(
            cache.diskStorage.directoryURL.absoluteString,
            customPath + "com.onevcat.Kingfisher.ImageCache.test/")
    }
    
    func testMaxCachePeriodInSecond() {
        cache.diskStorage.config.expiration = .seconds(1)
        XCTAssertEqual(cache.diskStorage.config.expiration.timeInterval, 1)
    }
    
    func testMaxMemorySize() {
        cache.memoryStorage.config.totalCostLimit = 1
        XCTAssert(cache.memoryStorage.config.totalCostLimit == 1, "maxMemoryCost should be able to be set.")
    }
    
    func testMaxDiskCacheSize() {
        cache.diskStorage.config.sizeLimit = 1
        XCTAssert(cache.diskStorage.config.sizeLimit == 1, "maxDiskCacheSize should be able to be set.")
    }
    
    func testClearDiskCache() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, original: testImageData2, forKey: key, toDisk: true) {
            self.cache.clearMemoryCache()
            let cacheResult = self.cache.imageCachedType(forKey: key)
            XCTAssertTrue(cacheResult.cached)
            XCTAssertEqual(cacheResult, .disk)
        
            self.cache.clearDiskCache {
                let cacheResult = self.cache.imageCachedType(forKey: key)
                XCTAssertFalse(cacheResult.cached)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler:nil)
    }
    
    func testClearMemoryCache() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, original: testImageData2, forKey: key, toDisk: true) {
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testNoImageFound() {
        let exp = expectation(description: #function)
        cache.retrieveImage(forKey: testKeys[0]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.value!.image)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCachedFileDoesNotExist() {
        let URLString = testKeys[0]
        let url = URL(string: URLString)!

        let exists = cache.imageCachedType(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
    }
    
    func testStoreImageInMemory() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, forKey: key, toDisk: false) {
            self.cache.retrieveImage(forKey: key) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .memory)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testStoreMultipleImages() {
        let exp = expectation(description: #function)
        storeMultipleImages {
            let diskCachePath = self.cache.diskStorage.directoryURL.path
            var files: [String] = []
            do {
                files = try FileManager.default.contentsOfDirectory(atPath: diskCachePath)
            } catch _ {
                XCTFail()
            }
            XCTAssertEqual(files.count, testKeys.count)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCachedFileExists() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let url = URL(string: key)!
        
        let exists = cache.imageCachedType(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
        
        cache.retrieveImage(forKey: key) { result in
            switch result {
            case .success(let value):
                XCTAssertNil(value.image)
                XCTAssertEqual(value.cacheType, .none)
            case .failure:
                XCTFail()
                return
            }

            self.cache.store(testImage, forKey: key, toDisk: true) {
                self.cache.retrieveImage(forKey: key) { result in

                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value?.cacheType, .memory)

                    self.cache.clearMemoryCache()
                    self.cache.retrieveImage(forKey: key) { result in
                        XCTAssertNotNil(result.value?.image)
                        XCTAssertEqual(result.value?.cacheType, .disk)

                        exp.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCachedFileWithCustomPathExtensionExists() {
        cache.diskStorage.config.pathExtension = "jpg"
        let exp = expectation(description: #function)
        
        let key = testKeys[0]
        let url = URL(string: key)!

        cache.store(testImage, forKey: key, toDisk: true) {
            let cachePath = self.cache.cachePath(forKey: url.cacheKey)
            XCTAssertTrue(cachePath.hasSuffix(".jpg"))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

  
    func testCachedImageIsFetchedSyncronouslyFromTheMemoryCache() {
        cache.store(testImage, forKey: testKeys[0], toDisk: false)
        var foundImage: Image?
        cache.retrieveImage(forKey: testKeys[0]) { result in
            foundImage = result.value?.image
        }
        XCTAssertEqual(testImage, foundImage)
    }

    func testIsImageCachedForKey() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        XCTAssertFalse(cache.imageCachedType(forKey: key).cached)
        cache.store(testImage, original: testImageData2, forKey: key, toDisk: true) {
            XCTAssertTrue(self.cache.imageCachedType(forKey: key).cached)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCleanDiskCacheNotification() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        cache.diskStorage.config.expiration = .seconds(0)

        cache.store(testImage, original: testImageData2, forKey: key, toDisk: true) {
            self.observer = NotificationCenter.default.addObserver(
                forName: .KingfisherDidCleanDiskCache,
                object: self.cache,
                queue: .main) {
                    noti in
                    let receivedCache = noti.object as? ImageCache
                    XCTAssertNotNil(receivedCache)
                    XCTAssertTrue(receivedCache === self.cache)
                
                    guard let hashes = noti.userInfo?[KingfisherDiskCacheCleanedHashKey] as? [String] else {
                        XCTFail("Notification should contains Strings in key 'KingfisherDiskCacheCleanedHashKey'")
                        exp.fulfill()
                        return
                    }
                
                    XCTAssertEqual(hashes.count, 1)
                    XCTAssertEqual(hashes.first!, self.cache.hash(forKey: key))
                
                    NotificationCenter.default.removeObserver(self.observer)
                    exp.fulfill()
                }

            self.cache.cleanExpiredDiskCache()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCannotRetrieveCacheWithProcessorIdentifier() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        cache.store(testImage, original: testImageData2, forKey: key, toDisk: true) {
            self.cache.retrieveImage(forKey: key, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value)
                XCTAssertNil(result.value!.image)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrieveCacheWithProcessorIdentifier() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        cache.store(testImage, original: testImageData2, forKey: key, processorIdentifier: p.identifier, toDisk: true) {
            self.cache.retrieveImage(forKey: key, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS)
    func testGettingMemoryCachedImageCouldBeModified() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData2, forKey: key) {
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertTrue(modifierCalled)
                XCTAssertEqual(result.value?.image?.renderingMode, .alwaysTemplate)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGettingDiskCachedImageCouldBeModified() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData2, forKey: key) {
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertTrue(modifierCalled)
                XCTAssertEqual(result.value?.image?.renderingMode, .alwaysTemplate)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
#endif

    // MARK: - Helper
    func storeMultipleImages(_ completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        testKeys.forEach {
            group.enter()
            cache.store(testImage, original: testImageData2, forKey: $0, toDisk: true) {
                group.leave()
            }
        }
        group.notify(queue: .main, execute: completionHandler)
    }
}
