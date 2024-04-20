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
    
    func testClearDiskCacheAsync() async throws {
        let key = testKeys[0]
        try await cache.store(testImage, original: testImageData, forKey: key, toDisk: true)
        cache.clearMemoryCache()
        var cacheResult = self.cache.imageCachedType(forKey: key)
        XCTAssertTrue(cacheResult.cached)
        XCTAssertEqual(cacheResult, .disk)
        
        await cache.clearDiskCache()
        cacheResult = cache.imageCachedType(forKey: key)
        XCTAssertFalse(cacheResult.cached)
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
    
    func testClearMemoryCacheAsync() async throws {
        let key = testKeys[0]
        try await cache.store(testImage, original: testImageData, forKey: key, toDisk: true)
        cache.clearMemoryCache()
        let result = try await cache.retrieveImage(forKey: key)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .disk)
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
    
    func testNoImageFoundAsync() async throws {
        let result = try await cache.retrieveImage(forKey: testKeys[0])
        XCTAssertNil(result.image)
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
    
    func testStoreImageInMemoryAsync() async throws {
        let key = testKeys[0]
        try await cache.store(testImage, forKey: key, toDisk: false)
        let result = try await cache.retrieveImage(forKey: key)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .memory)
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
    
    func testStoreMultipleImagesAsync() async throws {
        await storeMultipleImages()
    
        let diskCachePath = cache.diskStorage.directoryURL.path
        let files = try FileManager.default.contentsOfDirectory(atPath: diskCachePath)
        XCTAssertEqual(files.count, testKeys.count)
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
    
    func testCachedFileExistsAsync() async throws {
        let key = testKeys[0]
        let url = URL(string: key)!
        
        let exists = cache.imageCachedType(forKey: url.cacheKey).cached
        XCTAssertFalse(exists)
        
        var result = try await cache.retrieveImage(forKey: key)
        XCTAssertNil(result.image)
        XCTAssertEqual(result.cacheType, .none)
        
        try await cache.store(testImage, forKey: key, toDisk: true)
        
        result = try await cache.retrieveImage(forKey: key)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .memory)
        
        cache.clearMemoryCache()
        
        result = try await cache.retrieveImage(forKey: key)
        XCTAssertNotNil(result.image)
        XCTAssertEqual(result.cacheType, .disk)
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

    func testCachedFileWithCustomPathExtensionExistsAsync() async throws {
        cache.diskStorage.config.pathExtension = "jpg"
        let key = testKeys[0]
        let url = URL(string: key)!
        try await cache.store(testImage, forKey: key, toDisk: true)
        let cachePath = self.cache.cachePath(forKey: url.cacheKey)
        XCTAssertTrue(cachePath.hasSuffix(".jpg"))
    }
  
    func testCachedImageIsFetchedSynchronouslyFromTheMemoryCache() {
        cache.store(testImage, forKey: testKeys[0], toDisk: false)
        let foundImage = ActorBox<KFCrossPlatformImage?>(nil)
        cache.retrieveImage(forKey: testKeys[0]) { result in
            Task {
                await foundImage.setValue(result.value?.image)
            }
        }
        Task {
            let value = await foundImage.value
            XCTAssertEqual(testImage, value)
        }
    }
    
    func testCachedImageIsFetchedSynchronouslyFromTheMemoryCacheAsync() async throws {
        try await cache.store(testImage, forKey: testKeys[0], toDisk: false)
        let result = try await cache.retrieveImage(forKey: testKeys[0])
        XCTAssertEqual(testImage, result.image)
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
    
    func testIsImageCachedForKeyAsync() async throws {
        let key = testKeys[0]
        XCTAssertFalse(cache.imageCachedType(forKey: key).cached)
        try await cache.store(testImage, original: testImageData, forKey: key, toDisk: true)
        XCTAssertTrue(cache.imageCachedType(forKey: key).cached)
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
    
    func testCannotRetrieveCacheWithProcessorIdentifierAsync() async throws {
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        try await cache.store(testImage, original: testImageData, forKey: key, toDisk: true)
        let result = try await cache.retrieveImage(forKey: key, options: [.processor(p)])
        XCTAssertNotNil(result)
        XCTAssertNil(result.image)
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
    
    func testRetrieveCacheWithProcessorIdentifierAsync() async throws {
        let key = testKeys[0]
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        try await cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            processorIdentifier: p.identifier,
            toDisk: true
        )
        let result = try await cache.retrieveImage(forKey: key, options: [.processor(p)])
        XCTAssertNotNil(result.image)
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
    
    func testDefaultCacheAsync() async throws {
        let key = testKeys[0]
        let cache = ImageCache.default
        try await cache.store(testImage, forKey: key)
        XCTAssertTrue(cache.memoryStorage.isCached(forKey: key))
        XCTAssertTrue(cache.diskStorage.isCached(forKey: key))
        cleanDefaultCache()
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
            
            let dispatched = LockIsolated(false)
            self.cache.retrieveImageInDiskCache(forKey: key, options:  [.loadDiskFileSynchronously]) {
                result in
                XCTAssertFalse(dispatched.value)
                exp.fulfill()
            }
            // This should be called after the completion handler above.
            dispatched.setValue(true)
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
            
            let dispatched = LockIsolated(false)
            self.cache.retrieveImageInDiskCache(forKey: key, options: nil) {
                result in
                XCTAssertTrue(dispatched.value)
                exp.fulfill()
            }
            // This should be called before the completion handler above.
            dispatched.setValue(true)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    func testModifierShouldOnlyApplyForFinalResultWhenMemoryLoad() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        
        let modifierCalled = ActorBox(false)
        let modifier = AnyImageModifier { image in
            Task {
                await modifierCalled.setValue(true)
            }
            return image.withRenderingMode(.alwaysTemplate)
        }
        
        cache.store(testImage, original: testImageData, forKey: key) { _ in
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertEqual(result.value?.image?.renderingMode, .automatic)
                Task {
                    let called = await modifierCalled.value
                    XCTAssertFalse(called)
                    exp.fulfill()
                    
                }
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testModifierShouldOnlyApplyForFinalResultWhenMemoryLoadAsync() async throws {
        let key = testKeys[0]

        let modifierCalled = ActorBox(false)
        let modifier = AnyImageModifier { image in
            Task {
                await modifierCalled.setValue(true)
            }
            return image.withRenderingMode(.alwaysTemplate)
        }

        try await cache.store(testImage, original: testImageData, forKey: key)
        let result = try await cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)])
        let called = await modifierCalled.value
        XCTAssertFalse(called)
        XCTAssertEqual(result.image?.renderingMode, .automatic)
    }

    func testModifierShouldOnlyApplyForFinalResultWhenDiskLoad() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        let modifierCalled = ActorBox(false)
        let modifier = AnyImageModifier { image in
            Task {
                await modifierCalled.setValue(true)
            }
            return image.withRenderingMode(.alwaysTemplate)
        }

        cache.store(testImage, original: testImageData, forKey: key) { _ in
            self.cache.clearMemoryCache()
            self.cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)]) { result in
                XCTAssertEqual(result.value?.image?.renderingMode, .automatic)
                Task {
                    let called = await modifierCalled.value
                    XCTAssertFalse(called)
                    exp.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testModifierShouldOnlyApplyForFinalResultWhenDiskLoadAsync() async throws {
        let key = testKeys[0]
        let modifierCalled = ActorBox(false)
        let modifier = AnyImageModifier { image in
            Task {
                await modifierCalled.setValue(true)
            }
            return image.withRenderingMode(.alwaysTemplate)
        }
        
        try await cache.store(testImage, original: testImageData, forKey: key)
        cache.clearMemoryCache()
        let result = try await cache.retrieveImage(forKey: key, options: [.imageModifier(modifier)])
        let called = await modifierCalled.value
        XCTAssertFalse(called)
        // The renderingMode is expected to be the default value `.automatic`. The image modifier should only apply to
        // the image manager result.
        XCTAssertEqual(result.image?.renderingMode, .automatic)
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
    
    func testStoreToMemoryWithExpirationAsync() async throws {
        let key = testKeys[0]
        try await cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            options: KingfisherParsedOptionsInfo([.memoryCacheExpiration(.seconds(0.2))]),
            toDisk: true
        )
        XCTAssertEqual(self.cache.imageCachedType(forKey: key), .memory)
        // After 1 sec, the cache only remains on disk.
        try await Task.sleep(nanoseconds: NSEC_PER_SEC)
        XCTAssertEqual(self.cache.imageCachedType(forKey: key), .disk)
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
    
    func testStoreToDiskWithExpirationAsync() async throws {
        let key = testKeys[0]
        try await cache.store(
            testImage,
            original: testImageData,
            forKey: key,
            options: KingfisherParsedOptionsInfo([.diskCacheExpiration(.expired)]),
            toDisk: true
        )
        
        XCTAssertEqual(self.cache.imageCachedType(forKey: key), .memory)
        self.cache.clearMemoryCache()
        XCTAssertEqual(self.cache.imageCachedType(forKey: key), .none)
    }

    func testCalculateDiskStorageSize() {
        let exp = expectation(description: #function)
        cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                XCTAssertEqual(size, 0)
                self.storeMultipleImages {
                    self.cache.calculateDiskStorageSize { result in
                        switch result {
                        case .success(let size):
                            XCTAssertEqual(size, UInt(testImagePNGData.count * testKeys.count))
                        case .failure:
                            XCTAssert(false)
                        }
                        exp.fulfill()
                    }
                }
            case .failure:
                XCTAssert(false)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDiskCacheStillWorkWhenFolderDeletedExternally() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let url = URL(string: key)!
        
        let exists = cache.imageCachedType(forKey: url.cacheKey)
        XCTAssertEqual(exists, .none)
        
        cache.store(testImage, forKey: key, toDisk: true) { _ in
            self.cache.retrieveImage(forKey: key) { result in

                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value?.cacheType, .memory)

                self.cache.clearMemoryCache()
                self.cache.retrieveImage(forKey: key) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value?.cacheType, .disk)
                    self.cache.clearMemoryCache()
                    
                    try! FileManager.default.removeItem(at: self.cache.diskStorage.directoryURL)
                    
                    let exists = self.cache.imageCachedType(forKey: url.cacheKey)
                    XCTAssertEqual(exists, .none)
                    
                    self.cache.store(testImage, forKey: key, toDisk: true) { _ in
                        self.cache.clearMemoryCache()
                        let cacheType = self.cache.imageCachedType(forKey: url.cacheKey)
                        XCTAssertEqual(cacheType, .disk)
                        exp.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDiskCacheCalculateSizeWhenFolderDeletedExternally() {
        let exp = expectation(description: #function)
        
        let key = testKeys[0]
        
        cache.calculateDiskStorageSize { result in
            XCTAssertEqual(result.value, 0)
            
            self.cache.store(testImage, forKey: key, toDisk: true) { _ in
                self.cache.calculateDiskStorageSize { result in
                    XCTAssertEqual(result.value, UInt(testImagePNGData.count))
                    
                    try! FileManager.default.removeItem(at: self.cache.diskStorage.directoryURL)
                    self.cache.calculateDiskStorageSize { result in
                        XCTAssertEqual(result.value, 0)
                        exp.fulfill()
                    }
                    
                }
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCalculateDiskStorageSizeAsync() async throws {
        let size = try await cache.diskStorageSize
        XCTAssertEqual(size, 0)
        await storeMultipleImages()
        let newSize = try await cache.diskStorageSize
        XCTAssertEqual(newSize, UInt(testImagePNGData.count * testKeys.count))
    }
    
    // MARK: - Helper
    private func storeMultipleImages(_ completionHandler: @escaping () -> Void) {
        let group = DispatchGroup()
        testKeys.forEach {
            group.enter()
            cache.store(testImage, original: testImageData, forKey: $0, toDisk: true) { _ in
                group.leave()
            }
        }
        group.notify(queue: .main, execute: completionHandler)
    }
    
    private func storeMultipleImages() async {
        await withCheckedContinuation {
            storeMultipleImages($0.resume)
        }
    }
}

@dynamicMemberLookup
public final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSRecursiveLock()

  /// Initializes lock-isolated state around a value.
  ///
  /// - Parameter value: A value to isolate with a lock.
  public init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
    self._value = try value()
  }

  public subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.lock.sync {
      self._value[keyPath: keyPath]
    }
  }

  /// Perform an operation with isolated access to the underlying value.
  ///
  /// Useful for modifying a value in a single transaction.
  ///
  /// ```swift
  /// // Isolate an integer for concurrent read/write access:
  /// var count = LockIsolated(0)
  ///
  /// func increment() {
  ///   // Safely increment it:
  ///   self.count.withValue { $0 += 1 }
  /// }
  /// ```
  ///
  /// - Parameter operation: An operation to be performed on the the underlying value with a lock.
  /// - Returns: The result of the operation.
  public func withValue<T: Sendable>(
    _ operation: @Sendable (inout Value) throws -> T
  ) rethrows -> T {
    try self.lock.sync {
      var value = self._value
      defer { self._value = value }
      return try operation(&value)
    }
  }

  /// Overwrite the isolated value with a new value.
  ///
  /// ```swift
  /// // Isolate an integer for concurrent read/write access:
  /// var count = LockIsolated(0)
  ///
  /// func reset() {
  ///   // Reset it:
  ///   self.count.setValue(0)
  /// }
  /// ```
  ///
  /// > Tip: Use ``withValue(_:)`` instead of ``setValue(_:)`` if the value being set is derived
  /// > from the current value. That is, do this:
  /// >
  /// > ```swift
  /// > self.count.withValue { $0 += 1 }
  /// > ```
  /// >
  /// > ...and not this:
  /// >
  /// > ```swift
  /// > self.count.setValue(self.count + 1)
  /// > ```
  /// >
  /// > ``withValue(_:)`` isolates the entire transaction and avoids data races between reading and
  /// > writing the value.
  ///
  /// - Parameter newValue: The value to replace the current isolated value with.
  public func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
    try self.lock.sync {
      self._value = try newValue()
    }
  }
}

extension LockIsolated where Value: Sendable {
  /// The lock-isolated value.
  public var value: Value {
    self.lock.sync {
      self._value
    }
  }
}

extension NSRecursiveLock {
  @inlinable @discardableResult
  @_spi(Internals) public func sync<R>(work: () throws -> R) rethrows -> R {
    self.lock()
    defer { self.unlock() }
    return try work()
  }
}
