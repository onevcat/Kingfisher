//
//  ImageCacheTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
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

class ImageCacheTests: XCTestCase {

    var cache: ImageCache!
    var observer: NSObjectProtocol!
    
    override func setUp() {
        super.setUp()

        let uuid = UUID().uuidString
        let cacheName = "test-\(uuid)"
        cache = ImageCache(name: cacheName)
    }
    
    override func tearDown() {
        clearCaches([cache])
        cache = nil
        observer = nil

        super.tearDown()
    }
    
    func testInvalidCustomCachePath() {
        let customPath = "/path/to/image/cache"
        let url = URL(fileURLWithPath: customPath)
        XCTAssertThrowsError(try ImageCache(name: "test", cacheDirectoryURL: url)) { error in
            guard case KingfisherError.cacheError(reason: .cannotCreateDirectory(let path, _)) = error else {
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

        let customPath = subFolder.path
        let cache = try! ImageCache(name: "test", cacheDirectoryURL: subFolder)
        XCTAssertEqual(
            cache.diskStorage.directoryURL.path,
            (customPath as NSString).appendingPathComponent("com.onevcat.Kingfisher.ImageCache.test"))
        clearCaches([cache])
    }
    
    func testCustomCachePathByBlock() {
        let cache = try! ImageCache(name: "test", cacheDirectoryURL: nil, diskCachePathClosure: { (url, path) -> URL in
            let modifiedPath = path + "-modified"
            return url.appendingPathComponent(modifiedPath, isDirectory: true)
        })
        let cacheURL = try! FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        XCTAssertEqual(
            cache.diskStorage.directoryURL.path,
            (cacheURL.path as NSString).appendingPathComponent("com.onevcat.Kingfisher.ImageCache.test-modified"))
        clearCaches([cache])
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
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
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
        waitForExpectations(timeout: 3, handler:nil)
    }
    
    func testClearMemoryCache() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNoImageFound() {
        let exp = expectation(description: #function)
        cache.retrieveImage(forKey: testKeys[0]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.value!.image)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
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
        cache.store(testImage, forKey: key, toDisk: false) { _ in
            self.cache.retrieveImage(forKey: key) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .memory)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
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
        waitForExpectations(timeout: 3, handler: nil)
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

            self.cache.store(testImage, forKey: key, toDisk: true) { _ in
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
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCachedFileWithCustomPathExtensionExists() {
        cache.diskStorage.config.pathExtension = "jpg"
        let exp = expectation(description: #function)
        
        let key = testKeys[0]
        let url = URL(string: key)!

        cache.store(testImage, forKey: key, toDisk: true) { _ in
            let cachePath = self.cache.cachePath(forKey: url.cacheKey)
            XCTAssertTrue(cachePath.hasSuffix(".jpg"))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

  
    func testCachedImageIsFetchedSyncronouslyFromTheMemoryCache() {
        cache.store(testImage, forKey: testKeys[0], toDisk: false)
        var foundImage: KFCrossPlatformImage?
        cache.retrieveImage(forKey: testKeys[0]) { result in
            foundImage = result.value?.image
        }
        XCTAssertEqual(testImage, foundImage)
    }

    func testIsImageCachedForKey() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        XCTAssertFalse(cache.imageCachedType(forKey: key).cached)
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            XCTAssertTrue(self.cache.imageCachedType(forKey: key).cached)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCleanDiskCacheNotification() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        cache.diskStorage.config.expiration = .seconds(0.01)

        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
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
                    guard let o = self.observer else { return }
                    NotificationCenter.default.removeObserver(o)
                    exp.fulfill()
                }

            delay(1) {
                self.cache.cleanExpiredDiskCache()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCannotRetrieveCacheWithProcessorIdentifier() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        cache.store(testImage, original: testImageData, forKey: key, toDisk: true) { _ in
            self.cache.retrieveImage(forKey: key, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value)
                XCTAssertNil(result.value!.image)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testRetrieveCacheWithProcessorIdentifier() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            processorIdentifier: p.identifier,
            toDisk: true)
        {
            _ in
            self.cache.retrieveImage(forKey: key, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDefaultCache() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let cache = ImageCache.default
        cache.store(testImage, forKey: key) { _ in
            XCTAssertTrue(cache.memoryStorage.isCached(forKey: key))
            XCTAssertTrue(cache.diskStorage.isCached(forKey: key))
            cleanDefaultCache()
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveDiskCacheSynchronously() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, forKey: key, toDisk: true) { _ in
            var cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .memory)
            
            self.cache.memoryStorage.remove(forKey: key)
            cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .disk)
            
            var dispatched = false
            self.cache.retrieveImageInDiskCache(forKey: key, options:  [.loadDiskFileSynchronously]) {
                result in
                XCTAssertFalse(dispatched)
                exp.fulfill()
            }
            // This should be called after the completion handler above.
            dispatched = true
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveDiskCacheAsynchronously() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(testImage, forKey: key, toDisk: true) { _ in
            var cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .memory)
            
            self.cache.memoryStorage.remove(forKey: key)
            cacheType = self.cache.imageCachedType(forKey: key)
            XCTAssertEqual(cacheType, .disk)
            
            var dispatched = false
            self.cache.retrieveImageInDiskCache(forKey: key, options:  nil) {
                result in
                XCTAssertTrue(dispatched)
                exp.fulfill()
            }
            // This should be called before the completion handler above.
            dispatched = true
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS)
    func testModifierShouldOnlyApplyForFinalResultWhenMemoryLoad() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData, forKey: key) { _ in
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertFalse(modifierCalled)
                XCTAssertEqual(result.value?.image?.renderingMode, .automatic)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testModifierShouldOnlyApplyForFinalResultWhenDiskLoad() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData, forKey: key) { _ in
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertFalse(modifierCalled)
                XCTAssertEqual(result.value?.image?.renderingMode, .automatic)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
#endif
    
    func testStoreToMemoryWithExpiration() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            options: KingfisherParsedOptionsInfo([.memoryCacheExpiration(.seconds(0.2))]),
            toDisk: true)
        {
            _ in
            XCTAssertEqual(self.cache.imageCachedType(forKey: key), .memory)
            delay(1) {
                XCTAssertEqual(self.cache.imageCachedType(forKey: key), .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStoreToDiskWithExpiration() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            options: KingfisherParsedOptionsInfo([.diskCacheExpiration(.expired)]),
            toDisk: true)
        {
            _ in
            XCTAssertEqual(self.cache.imageCachedType(forKey: key), .memory)
            self.cache.clearMemoryCache()
            XCTAssertEqual(self.cache.imageCachedType(forKey: key), .none)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Helper
    func storeMultipleImages(_ completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        testKeys.forEach {
            group.enter()
            cache.store(testImage, original: testImageData, forKey: $0, toDisk: true) { _ in
                group.leave()
            }
        }
        group.notify(queue: .main, execute: completionHandler)
    }
}
