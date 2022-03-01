//
//  KingfisherManagerTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/22.
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

class KingfisherManagerTests: XCTestCase {
    
    var manager: KingfisherManager!
    
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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let uuid = UUID()
        let downloader = ImageDownloader(name: "test.manager.\(uuid.uuidString)")
        let cache = ImageCache(name: "test.cache.\(uuid.uuidString)")
        
        manager = KingfisherManager(downloader: downloader, cache: cache)
        manager.defaultOptions = [.waitForCache]
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }
    
    func testRetrieveImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let manager = self.manager!
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)

        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .memory)

        manager.cache.clearMemoryCache()
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .disk)

        manager.cache.clearMemoryCache()
        manager.cache.clearDiskCache {
            manager.retrieveImage(with: url) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                exp.fulfill()
        }}}}}
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveImageWithProcessor() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        let p = RoundCornerImageProcessor(cornerRadius: 20)
        let manager = self.manager!

        manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none,
                           "Need a processor to get correct image. Cannot get from cache, need download again.")

        manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .memory)
                    
        self.manager.cache.clearMemoryCache()
        manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .disk)
                        
        self.manager.cache.clearMemoryCache()
        self.manager.cache.clearDiskCache {
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)

                exp.fulfill()
        }}}}}}
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testRetrieveImageForceRefresh() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: DefaultCacheSerializer.default,
            toDisk: true)
        {
            _ in
            XCTAssertTrue(self.manager.cache.imageCachedType(forKey: url.cacheKey).cached)
            self.manager.retrieveImage(with: url, options: [.forceRefresh]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSuccessCompletionHandlerRunningOnMainQueueDefaultly() {
        let progressExpectation = expectation(description: "progressBlock running on main queue")
        let completionExpectation = expectation(description: "completionHandler running on main queue")

        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)
        
        manager.retrieveImage(with: url, options: nil, progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            progressExpectation.fulfill()})
        {
            result in
            XCTAssertNil(result.error)
            XCTAssertTrue(Thread.isMainThread)
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testShouldNotDownloadImageIfCacheOnlyAndNotInCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url, options: [.onlyFromCache]) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            if case .cacheError(reason: .imageNotExisting(let key)) = result.error! {
                XCTAssertEqual(key, url.cacheKey)
            } else {
                XCTFail()
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testErrorCompletionHandlerRunningOnMainQueueDefaultly() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, statusCode: 404)

        manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertTrue(result.error!.isInvalidResponseStatusCode(404))
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testSucessCompletionHandlerRunningOnCustomQueue() {
        let progressExpectation = expectation(description: "progressBlock running on custom queue")
        let completionExpectation = expectation(description: "completionHandler running on custom queue")

        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        let options: KingfisherOptionsInfo = [.callbackQueue(.dispatch(customQueue))]
        manager.retrieveImage(with: url, options: options, progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            progressExpectation.fulfill()
        })
        {
            result in
            XCTAssertNil(result.error)
            dispatchPrecondition(condition: .onQueue(customQueue))
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testLoadCacheCompletionHandlerRunningOnCustomQueue() {
        let completionExpectation = expectation(description: "completionHandler running on custom queue")

        let url = testURLs[0]
        manager.cache.store(testImage, forKey: url.cacheKey)

        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        manager.retrieveImage(with: url, options: [.callbackQueue(.dispatch(customQueue))]) {
            result in
            XCTAssertNil(result.error)
            dispatchPrecondition(condition: .onQueue(customQueue))
            completionExpectation.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDefaultOptionCouldApply() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        manager.defaultOptions = [.scaleFactor(2)]
        manager.retrieveImage(with: url, completionHandler: { result in
            #if !os(macOS)
            XCTAssertEqual(result.value!.image.scale, 2.0)
            #endif
            exp.fulfill()
        })
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testOriginalImageCouldBeStored() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let manager = self.manager!
        let p = SimpleProcessor()
        let options = KingfisherParsedOptionsInfo([.processor(p), .cacheOriginalImage])
        let source = Source.network(url)
        let context = RetrievingContext(options: options, originalSource: source)
        manager.loadAndCacheImage(source: .network(url), context: context) { result in
            
            var imageCached = manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            var originalCached = manager.cache.imageCachedType(forKey: url.cacheKey)

            XCTAssertEqual(imageCached, .memory)

            delay(0.1) {
                manager.cache.clearMemoryCache()
                
                imageCached = manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                originalCached = manager.cache.imageCachedType(forKey: url.cacheKey)
                XCTAssertEqual(imageCached, .disk)
                XCTAssertEqual(originalCached, .disk)
                
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testOriginalImageNotBeStoredWithoutOptionSet() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let p = SimpleProcessor()
        let options = KingfisherParsedOptionsInfo([.processor(p), .waitForCache])
        let source = Source.network(url)
        let context = RetrievingContext(options: options, originalSource: source)
        manager.loadAndCacheImage(source: .network(url), context: context) {
            result in
            var imageCached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            var originalCached = self.manager.cache.imageCachedType(forKey: url.cacheKey)
            
            XCTAssertEqual(imageCached, .memory)
            XCTAssertEqual(originalCached, .none)
            
            self.manager.cache.clearMemoryCache()
            
            imageCached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            originalCached = self.manager.cache.imageCachedType(forKey: url.cacheKey)
            XCTAssertEqual(imageCached, .disk)
            XCTAssertEqual(originalCached, .none)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCouldProcessOnOriginalImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: DefaultCacheSerializer.default,
            toDisk: true)
        {
            _ in
            let p = SimpleProcessor()
            
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            XCTAssertFalse(cached.cached)
            
            // No downloading will happen
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                XCTAssertTrue(p.processed)
                
                // The processed image should be cached
                let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                XCTAssertTrue(cached.cached)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFailingProcessOnOriginalImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: DefaultCacheSerializer.default,
            toDisk: true)
        {
            _ in
            let p = FailingProcessor()
            
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
            XCTAssertFalse(cached.cached)
            
            // No downloading will happen
            self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
                XCTAssertNotNil(result.error)
                XCTAssertTrue(p.processed)
                if case .processorError(reason: .processingFailed(let processor, _)) = result.error! {
                    XCTAssertEqual(processor.identifier, p.identifier)
                } else {
                    XCTFail()
                }
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testFailingProcessOnDataProviderImage() {
        let provider = SimpleImageDataProvider(cacheKey: "key") { .success(testImageData) }
        var called = false
        let p = FailingProcessor()
        let options = [KingfisherOptionsInfoItem.processor(p), .processingQueue(.mainCurrentOrAsync)]
        _ = manager.retrieveImage(with: .provider(provider), options: options) { result in
            called = true
            XCTAssertNotNil(result.error)
            if case .processorError(reason: .processingFailed(let processor, _)) = result.error! {
                XCTAssertEqual(processor.identifier, p.identifier)
            } else {
                XCTFail()
            }
        }
        XCTAssertTrue(called)
    }
    
    func testCacheOriginalImageWithOriginalCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        let originalCache = ImageCache(name: "test-originalCache")
        
        // Clear original cache first.
        originalCache.clearMemoryCache()
        originalCache.clearDiskCache {
            
            XCTAssertEqual(originalCache.imageCachedType(forKey: url.cacheKey), .none)
            
            stub(url, data: testImageData)
            
            let p = RoundCornerImageProcessor(cornerRadius: 20)
            self.manager.retrieveImage(
                with: url,
                options: [.processor(p), .cacheOriginalImage, .originalCache(originalCache)])
            {
                result in
                let originalCached = originalCache.imageCachedType(forKey: url.cacheKey)
                XCTAssertEqual(originalCached, .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCouldProcessOnOriginalImageWithOriginalCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        let originalCache = ImageCache(name: "test-originalCache")
        
        // Clear original cache first.
        originalCache.clearMemoryCache()
        originalCache.clearDiskCache {
            originalCache.store(
                testImage,
                original: testImageData,
                forKey: url.cacheKey,
                processorIdentifier: DefaultImageProcessor.default.identifier,
                cacheSerializer: DefaultCacheSerializer.default,
                toDisk: true)
            {
                _ in
                let p = SimpleProcessor()
                
                let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                XCTAssertFalse(cached.cached)
                
                // No downloading will happen
                self.manager.retrieveImage(with: url, options: [.processor(p), .originalCache(originalCache)]) {
                    result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value!.cacheType, .none)
                    XCTAssertTrue(p.processed)
                    
                    // The processed image should be cached
                    let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey, processorIdentifier: p.identifier)
                    XCTAssertTrue(cached.cached)
                    exp.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testWaitForCacheOnRetrieveImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        self.manager.retrieveImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            self.manager.cache.clearMemoryCache()
            let cached = self.manager.cache.imageCachedType(forKey: url.cacheKey)
            XCTAssertEqual(cached, .disk)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNotWaitForCacheOnRetrieveImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        self.manager.defaultOptions = .empty
        self.manager.retrieveImage(with: url, options: [.callbackQueue(.untouch)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            // We are not waiting for cache finishing here. So only sync memory cache is done.
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .memory)
            
            // Clear the memory cache.
            self.manager.cache.clearMemoryCache()
            // After some time, the disk cache should be done.
            delay(0.2) {
                XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .disk)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testWaitForCacheOnRetrieveImageWithProcessor() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        let p = RoundCornerImageProcessor(cornerRadius: 20)
        self.manager.retrieveImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageShouldOnlyFromMemoryCacheOrRefreshCanBeGotFromMemory() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
            // Can be downloaded and cached normally.
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            // Can still be got from memory even when disk cache cleared.
            self.manager.cache.clearDiskCache {
                self.manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertEqual(result.value!.cacheType, .memory)
                    
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageShouldOnlyFromMemoryCacheOrRefreshCanRefreshIfNotInMemory() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.cacheType, .none)
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .memory)

            self.manager.cache.clearMemoryCache()
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .disk)
            
            // Should skip disk cache and download again.
            self.manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.cacheType, .none)
                XCTAssertEqual(self.manager.cache.imageCachedType(forKey: url.cacheKey), .memory)

                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldDownloadAndCacheProcessedImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let size = CGSize(width: 1, height: 1)
        let processor = ResizingImageProcessor(referenceSize: size)

        manager.retrieveImage(with: url, options: [.processor(processor)]) { result in
            // Can download and cache normally
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value!.image.size, size)
            XCTAssertEqual(result.value!.cacheType, .none)

            self.manager.cache.clearMemoryCache()
            let cached = self.manager.cache.imageCachedType(
                forKey: url.cacheKey, processorIdentifier: processor.identifier)
            XCTAssertEqual(cached, .disk)

            self.manager.retrieveImage(with: url, options: [.processor(processor)]) { result in
                XCTAssertNotNil(result.value?.image)
                XCTAssertEqual(result.value!.image.size, size)
                XCTAssertEqual(result.value!.cacheType, .disk)

                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS)
    func testShouldApplyImageModifierWhenDownload() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testShouldApplyImageModifierWhenLoadFromMemoryCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        manager.cache.store(testImage, forKey: url.cacheKey)
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(result.value?.cacheType, .memory)
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testShouldApplyImageModifierWhenLoadFromDiskCache() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        manager.cache.store(testImage, forKey: url.cacheKey) { _ in
            self.manager.cache.clearMemoryCache()
            self.manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
                XCTAssertTrue(modifierCalled)
                XCTAssertEqual(result.value!.cacheType, .disk)
                XCTAssertEqual(result.value!.image.renderingMode, .alwaysTemplate)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageModifierResultShouldNotBeCached() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)

            let memoryCached = self.manager.cache.retrieveImageInMemoryCache(forKey: url.absoluteString)
            XCTAssertNotNil(memoryCached)
            XCTAssertEqual(memoryCached?.renderingMode, .automatic)

            self.manager.cache.retrieveImageInDiskCache(forKey: url.absoluteString) { result in
                XCTAssertNotNil(result.value!)
                XCTAssertEqual(result.value??.renderingMode, .automatic)

                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

#endif
    
    func testRetrieveWithImageProvider() {
        let provider = SimpleImageDataProvider(cacheKey: "key") { .success(testImageData) }
        var called = false
        manager.defaultOptions = .empty
        _ = manager.retrieveImage(with: .provider(provider), options: [.processingQueue(.mainCurrentOrAsync)]) {
            result in
            called = true
            XCTAssertNotNil(result.value)
            XCTAssertTrue(result.value!.image.renderEqual(to: testImage))
        }
        XCTAssertTrue(called)
    }
    
    func testRetrieveWithImageProviderFail() {
        let provider = SimpleImageDataProvider(cacheKey: "key") { .failure(SimpleImageDataProvider.E()) }
        var called = false
        _ = manager.retrieveImage(with: .provider(provider)) { result in
            called = true
            XCTAssertNotNil(result.error)
            if case .imageSettingError(reason: .dataProviderError(_, let error)) = result.error! {
                XCTAssertTrue(error is SimpleImageDataProvider.E)
            } else {
                XCTFail()
            }
        }
        XCTAssertTrue(called)
    }

    func testContextRemovingAlternativeSource() {
        let allSources: [Source] = [
            .network(URL(string: "1")!),
            .network(URL(string: "2")!)
        ]
        let info = KingfisherParsedOptionsInfo([.alternativeSources(allSources)])
        let context = RetrievingContext(
            options: info, originalSource: .network(URL(string: "0")!))

        let source1 = context.popAlternativeSource()
        XCTAssertNotNil(source1)
        guard case .network(let r1) = source1! else {
            XCTFail("Should be a network source, but \(source1!)")
            return
        }
        XCTAssertEqual(r1.downloadURL.absoluteString, "1")

        let source2 = context.popAlternativeSource()
        XCTAssertNotNil(source2)
        guard case .network(let r2) = source2! else {
            XCTFail("Should be a network source, but \(source2!)")
            return
        }
        XCTAssertEqual(r2.downloadURL.absoluteString, "2")

        XCTAssertNil(context.popAlternativeSource())
    }

    func testRetrievingWithAlternativeSource() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        _ = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])])
        {
            result in

            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!.source.url, url)
            XCTAssertEqual(result.value!.originalSource.url, brokenURL)

            exp.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrievingErrorsWithAlternativeSource() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: Data())

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let anotherBrokenURL = URL(string: "anotherBrokenURL")!
        stub(anotherBrokenURL, data: Data())

        _ = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(anotherBrokenURL), .network(url)])])
        {
            result in

            defer { exp.fulfill() }

            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)

            guard case .imageSettingError(reason: let reason) = result.error! else {
                XCTFail("The error should be image setting error")
                return
            }

            guard case .alternativeSourcesExhausted(let errorInfo) = reason else {
                XCTFail("The error reason should be alternativeSourcesFailed")
                return
            }

            XCTAssertEqual(errorInfo.count, 3)
            XCTAssertEqual(errorInfo[0].source.url, brokenURL)
            XCTAssertEqual(errorInfo[1].source.url, anotherBrokenURL)
            XCTAssertEqual(errorInfo[2].source.url, url)
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrievingAlternativeSourceTaskUpdateBlockCalled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        var downloadTaskUpdatedCount = 0
        let task = manager.retrieveImage(
          with: .network(brokenURL),
          options: [.alternativeSources([.network(url)])],
          downloadTaskUpdated: { newTask in
            downloadTaskUpdatedCount += 1
            XCTAssertEqual(newTask?.sessionTask.task.currentRequest?.url, url)
          })
          {
            result in
            XCTAssertEqual(downloadTaskUpdatedCount, 1)
            exp.fulfill()
        }

        XCTAssertEqual(task?.sessionTask.task.currentRequest?.url, brokenURL)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrievingAlternativeSourceCancelled() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        let task = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])]
        )
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            exp.fulfill()
        }
        task?.cancel()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRetrievingAlternativeSourceCanCancelUpdatedTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let dataStub = delayedStub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        var task: DownloadTask!
        task = manager.retrieveImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])],
            downloadTaskUpdated: { newTask in
                task = newTask
                task.cancel()
            }
        )
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error?.isTaskCancelled ?? false)

            delay(0.1) {
                _ = dataStub.go()
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDownsamplingHandleScale2x() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        _ = manager.retrieveImage(
            with: .network(url),
            options: [.processor(DownsamplingImageProcessor(size: .init(width: 4, height: 4))), .scaleFactor(2)])
        {
            result in

            let image = result.value?.image
            XCTAssertNotNil(image)
            
            #if os(macOS)
            XCTAssertEqual(image?.size, .init(width: 8, height: 8))
            XCTAssertEqual(image?.kf.scale, 1)
            #else
            XCTAssertEqual(image?.size, .init(width: 4, height: 4))
            XCTAssertEqual(image?.kf.scale, 2)
            #endif
            
            exp.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDownsamplingHandleScale3x() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        _ = manager.retrieveImage(
            with: .network(url),
            options: [.processor(DownsamplingImageProcessor(size: .init(width: 4, height: 4))), .scaleFactor(3)])
        {
            result in

            let image = result.value?.image
            XCTAssertNotNil(image)
            #if os(macOS)
            XCTAssertEqual(image?.size, .init(width: 12, height: 12))
            XCTAssertEqual(image?.kf.scale, 1)
            #else
            XCTAssertEqual(image?.size, .init(width: 4, height: 4))
            XCTAssertEqual(image?.kf.scale, 3)
            #endif
            
            exp.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCacheCallbackCoordinatorStateChanging() {
        var coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: false, shouldCacheOriginal: false)
        var called = false
        coordinator.apply(.cacheInitiated) {
            called = true
        }
        XCTAssertTrue(called)
        XCTAssertEqual(coordinator.state, .done)
        coordinator.apply(.cachingImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: true, shouldCacheOriginal: false)
        called = false
        coordinator.apply(.cacheInitiated) { XCTFail() }
        XCTAssertEqual(coordinator.state, .idle)
        coordinator.apply(.cachingImage) {
            called = true
        }
        XCTAssertTrue(called)
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: false, shouldCacheOriginal: true)
        coordinator.apply(.cacheInitiated) {
            called = true
        }
        XCTAssertEqual(coordinator.state, .done)
        coordinator.apply(.cachingOriginalImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: true, shouldCacheOriginal: true)
        coordinator.apply(.cacheInitiated) { XCTFail() }
        XCTAssertEqual(coordinator.state, .idle)
        coordinator.apply(.cachingOriginalImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .originalImageCached)
        coordinator.apply(.cachingImage) { called = true }
        XCTAssertEqual(coordinator.state, .done)

        coordinator = CacheCallbackCoordinator(
            shouldWaitForCache: true, shouldCacheOriginal: true)
        coordinator.apply(.cacheInitiated) { XCTFail() }
        XCTAssertEqual(coordinator.state, .idle)
        coordinator.apply(.cachingImage) { XCTFail() }
        XCTAssertEqual(coordinator.state, .imageCached)
        coordinator.apply(.cachingOriginalImage) { called = true }
        XCTAssertEqual(coordinator.state, .done)
    }
    
    func testCallbackClearAfterSuccess() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        stub(url, data: testImageData)
        
        var task: DownloadTask?
        var called = false
        task = manager.retrieveImage(with: url) { result in
            XCTAssertFalse(called)
            XCTAssertNotNil(result.value?.image)
            if !called {
                called = true
                task?.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    exp.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCanUseCustomizeDefaultCacheSerializer() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        var cacheSerializer = DefaultCacheSerializer()
        cacheSerializer.preferCacheOriginalData = true

        manager.cache.store(
            testImage,
            original: testImageData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: cacheSerializer, toDisk: true) {
                result in

                let computedKey = url.cacheKey.computedKey(with: DefaultImageProcessor.default.identifier)
                let fileURL = self.manager.cache.diskStorage.cacheFileURL(forKey: computedKey)
                let data = try! Data(contentsOf: fileURL)
                XCTAssertEqual(data, testImageData)

                exp.fulfill()
            }
        waitForExpectations(timeout: 1.0)
    }

    func testCanUseCustomizeDefaultCacheSerializerStoreEncoded() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        var cacheSerializer = DefaultCacheSerializer()
        cacheSerializer.compressionQuality = 0.8

        manager.cache.store(
            testImage,
            original: testImageJEPGData,
            forKey: url.cacheKey,
            processorIdentifier: DefaultImageProcessor.default.identifier,
            cacheSerializer: cacheSerializer, toDisk: true) {
                result in

                let computedKey = url.cacheKey.computedKey(with: DefaultImageProcessor.default.identifier)
                let fileURL = self.manager.cache.diskStorage.cacheFileURL(forKey: computedKey)
                let data = try! Data(contentsOf: fileURL)
                XCTAssertNotEqual(data, testImageJEPGData)
                XCTAssertEqual(data, testImage.kf.jpegRepresentation(compressionQuality: 0.8))

                exp.fulfill()
            }
        waitForExpectations(timeout: 1.0)
    }
}

class SimpleProcessor: ImageProcessor {
    public let identifier = "id"
    var processed = false
    /// Initialize a `DefaultImageProcessor`
    public init() {}
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        processed = true
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options.imageCreatingOptions)
        }
    }
}

class FailingProcessor: ImageProcessor {
    public let identifier = "FailingProcessor"
    var processed = false
    public init() {}
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        processed = true
        return nil
    }
}

struct SimpleImageDataProvider: ImageDataProvider {
    let cacheKey: String
    let provider: () -> (Result<Data, Error>)
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        handler(provider())
    }
    
    struct E: Error {}
}
