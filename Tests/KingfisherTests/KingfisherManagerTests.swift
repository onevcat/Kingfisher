//
//  KingfisherManagerTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/22.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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
        LSNocilla.sharedInstance().clearStubs()
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }
    
    func testRetrieveImage() {
        
        let expectation = self.expectation(description: "wait for downloading image")
        let URLString = testKeys[0]
        
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!

        manager.retrieveImage(with: url, options: nil, progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, .none)
            
            self.manager.retrieveImage(with: url, options: nil, progressBlock: nil) {
                image, error, cacheType, imageURL in
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, .memory)
                
                self.manager.cache.clearMemoryCache()
                self.manager.retrieveImage(with: url, options: nil, progressBlock: nil) {
                    image, error, cacheType, imageURL in
                    XCTAssertNotNil(image)
                    XCTAssertEqual(cacheType, .disk)
                    
                    cleanDefaultCache()
                    self.manager.retrieveImage(with: url, options: [.forceRefresh], progressBlock: nil) {
                        image, error, cacheType, imageURL in
                        XCTAssertNotNil(image)
                        XCTAssertEqual(cacheType, CacheType.none)
                    
                        expectation.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRetrieveImageWithProcessor() {
        cleanDefaultCache()
        let expectation = self.expectation(description: "wait for downloading image")
        let URLString = testKeys[0]
        
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        let p = RoundCornerImageProcessor(cornerRadius: 20)
        manager.retrieveImage(with: url, options: [.processor(p)], progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, .none)
            
            self.manager.retrieveImage(with: url, options: nil, progressBlock: nil) {
                image, error, cacheType, imageURL in
                
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, .none, "Need a processor to get correct image. Cannot get from cache, need download again.")
                
                self.manager.retrieveImage(with: url, options: [.processor(p)], progressBlock: nil) {
                    image, error, cacheType, imageURL in
                
                    XCTAssertNotNil(image)
                    XCTAssertEqual(cacheType, .memory)
                    
                    self.manager.cache.clearMemoryCache()
                    self.manager.retrieveImage(with: url, options: [.processor(p)], progressBlock: nil) {
                        image, error, cacheType, imageURL in
                        XCTAssertNotNil(image)
                        XCTAssertEqual(cacheType, .disk)
                        
                        cleanDefaultCache()
                        self.manager.retrieveImage(with: url, options: [.processor(p), .forceRefresh], progressBlock: nil) {
                            image, error, cacheType, imageURL in
                            XCTAssertNotNil(image)
                            XCTAssertEqual(cacheType, CacheType.none)
                            
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRetrieveImageNotModified() {
        let expectation = self.expectation(description: "wait for downloading image")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        manager.retrieveImage(with: url, options: nil, progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, CacheType.none)
            
            self.manager.cache.clearMemoryCache()
            
            _ = stubRequest("GET", URLString).andReturn(304)?.withBody("12345" as NSString)
            
            var progressCalled = false
            
            self.manager.retrieveImage(with: url, options: [.forceRefresh], progressBlock: {
                _, _ in
                progressCalled = true
            }) {
                image, error, cacheType, imageURL in
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, CacheType.disk)
                
                XCTAssertTrue(progressCalled, "The progress callback should be called at least once since network connecting happens.")
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSuccessCompletionHandlerRunningOnMainQueueDefaultly() {
        let progressExpectation = expectation(description: "progressBlock running on main queue")
        let completionExpectation = expectation(description: "completionHandler running on main queue")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        manager.retrieveImage(with: url, options: nil, progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            progressExpectation.fulfill()
            }, completionHandler: { _, error, _, _ in
                XCTAssertNil(error)
                XCTAssertTrue(Thread.isMainThread)
                completionExpectation.fulfill()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldNotDownloadImageIfCacheOnlyAndNotInCache() {
        cleanDefaultCache()
        let expectation = self.expectation(description: "wait for retrieving image cache")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        let url = URL(string: URLString)!

        manager.retrieveImage(with: url, options: [.onlyFromCache], progressBlock: nil, completionHandler: { image, error, _, _ in
                XCTAssertNil(image)
                XCTAssertNotNil(error)
                XCTAssertEqual(error!.code, KingfisherError.notCached.rawValue)
                expectation.fulfill()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testErrorCompletionHandlerRunningOnMainQueueDefaultly() {
        let expectation = self.expectation(description: "running on main queue")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(404)

        let url = URL(string: URLString)!

        manager.retrieveImage(with: url, options: nil, progressBlock: { _, _ in
            //won't be called
            }, completionHandler: { _, error, _, _ in
                XCTAssertNotNil(error)
                XCTAssertTrue(Thread.isMainThread)
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
        })
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSucessCompletionHandlerRunningOnCustomQueue() {
        let progressExpectation = expectation(description: "progressBlock running on custom queue")
        let completionExpectation = expectation(description: "completionHandler running on custom queue")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        manager.retrieveImage(with: url, options: [.callbackDispatchQueue(customQueue)], progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            DispatchQueue.main.async { progressExpectation.fulfill() }
            }, completionHandler: { _, error, _, _ in
                XCTAssertNil(error)
                
                if #available(iOS 10.0, tvOS 10.0, macOS 10.12, *) {
                    dispatchPrecondition(condition: .onQueue(customQueue))
                }

                DispatchQueue.main.async {
                    completionExpectation.fulfill()
                }
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testErrorCompletionHandlerRunningOnCustomQueue() {
        let expectation = self.expectation(description: "running on custom queue")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(404)
        
        let url = URL(string: URLString)!
        
        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        manager.retrieveImage(with: url, options: [.callbackDispatchQueue(customQueue)], progressBlock: { _, _ in
            //won't be called
            }, completionHandler: { _, error, _, _ in
                XCTAssertNotNil(error)
                if #available(iOS 10.0, tvOS 10.0, macOS 10.12, *) {
                    dispatchPrecondition(condition: .onQueue(customQueue))
                }
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDefaultOptionCouldApply() {
        let expectation = self.expectation(description: "Default options")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        manager.defaultOptions = [.scaleFactor(2)]
        manager.retrieveImage(with: url, options: nil, progressBlock: nil, completionHandler: { image, _, _, _ in
            #if !os(macOS)
            XCTAssertEqual(image!.scale, 2.0)
            #endif
            expectation.fulfill()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testOriginalImageCouldBeStored() {
        let expectation = self.expectation(description: "waiting for cache finished")

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!

        let p = SimpleProcessor()
        let options: KingfisherOptionsInfo = [.processor(p), .cacheOriginalImage]
        self.manager.downloadAndCacheImage(with: url, forKey: URLString, retrieveImageTask: RetrieveImageTask(), progressBlock: nil, completionHandler: {
            (image, error, cacheType, url) in
            delay(0.1) {
                var imageCached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                var originalCached = self.manager.cache.imageCachedType(forKey: URLString)

                XCTAssertEqual(imageCached, .memory)
                XCTAssertEqual(originalCached, .memory)

                self.manager.cache.clearMemoryCache()

                imageCached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                originalCached = self.manager.cache.imageCachedType(forKey: URLString)
                XCTAssertEqual(imageCached, .disk)
                XCTAssertEqual(originalCached, .disk)

                expectation.fulfill()
            }
        }, options: options)

        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testOriginalImageNotBeStoredWithoutOptionSet() {
        let expectation = self.expectation(description: "waiting for cache finished")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        let p = SimpleProcessor()
        let options: KingfisherOptionsInfo = [.processor(p)]
        manager.downloadAndCacheImage(with: url, forKey: URLString, retrieveImageTask: RetrieveImageTask(), progressBlock: nil, completionHandler: {
            (image, error, cacheType, url) in
            delay(0.1) {
                var imageCached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                var originalCached = self.manager.cache.imageCachedType(forKey: URLString)
                
                XCTAssertEqual(imageCached, .memory)
                XCTAssertEqual(originalCached, .none)
                
                self.manager.cache.clearMemoryCache()
                
                imageCached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                originalCached = self.manager.cache.imageCachedType(forKey: URLString)
                XCTAssertEqual(imageCached, .disk)
                XCTAssertEqual(originalCached, .none)
                
                expectation.fulfill()
            }
        }, options: options)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCouldProcessOnOriginalImage() {
        let expectation = self.expectation(description: "waiting for downloading finished")
        
        let URLString = testKeys[0]
        manager.cache.store(testImage, original: testImageData as Data,
                            forKey: URLString, processorIdentifier: DefaultImageProcessor.default.identifier,
                            cacheSerializer: DefaultCacheSerializer.default, toDisk: true)
        {
            let p = SimpleProcessor()
            
            let cached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
            XCTAssertFalse(cached.cached)
            
            // No downloading will happen
            self.manager.retrieveImage(with: URL(string: URLString)!, options: [.processor(p)], progressBlock: nil) {
                image, error, cacheType, url in
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, .none)
                XCTAssertTrue(p.processed)
                
                // The processed image should be cached
                delay(0.1) {
                    let cached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                    XCTAssertTrue(cached.cached)
                    expectation.fulfill()
                }
                
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCacheOriginalImageWithOriginalCache() {
        cleanDefaultCache()
        let expectation = self.expectation(description: "wait for downloading image")
        let URLString = testKeys[0]
        let originalCache = ImageCache(name: "test-originalCache")
        
        // Clear original cache first.
        originalCache.clearMemoryCache()
        originalCache.clearDiskCache {
            _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
            
            let url = URL(string: URLString)!
            
            let p = RoundCornerImageProcessor(cornerRadius: 20)
            self.manager.retrieveImage(with: url, options: [.processor(p), .cacheOriginalImage, .originalCache(originalCache)], progressBlock: nil) {
                image, error, cacheType, imageURL in
                delay(0.1) {
                    let originalCached = originalCache.imageCachedType(forKey: URLString)
                    XCTAssertEqual(originalCached, .memory)
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCouldProcessOnOriginalImageWithOriginalCache() {
        cleanDefaultCache()
        let expectation = self.expectation(description: "waiting for downloading finished")
        
        let URLString = testKeys[0]
        let originalCache = ImageCache(name: "test-originalCache")
        
        // Clear original cache first.
        originalCache.clearMemoryCache()
        originalCache.clearDiskCache {
            originalCache.store(testImage, original: testImageData as Data,
                                forKey: URLString, processorIdentifier: DefaultImageProcessor.default.identifier,
                                cacheSerializer: DefaultCacheSerializer.default, toDisk: true)
            {
                let p = SimpleProcessor()
                
                let cached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                XCTAssertFalse(cached.cached)
                
                // No downloading will happen
                self.manager.retrieveImage(with: URL(string: URLString)!, options: [.processor(p), .originalCache(originalCache)], progressBlock: nil) {
                    image, error, cacheType, url in
                    XCTAssertNotNil(image)
                    XCTAssertEqual(cacheType, .none)
                    XCTAssertTrue(p.processed)
                    
                    // The processed image should be cached
                    delay(0.1) {
                        let cached = self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: p.identifier)
                        XCTAssertTrue(cached.cached)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testImageShouldOnlyFromMemoryCacheOrRefreshCanBeGotFromMemory() {
        let expectation = self.expectation(description: "only from memory cache or refresh")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        let url = URL(string: URLString)!

        manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh], progressBlock: nil) {
            image, _, type, _ in
            // Can download and cache normally
            XCTAssertNotNil(image)
            XCTAssertEqual(type, .none)

            // Can still be got from memory even when disk cache cleared.
            self.manager.cache.clearDiskCache {
                self.manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh], progressBlock: nil) {
                    image, _, type, _ in
                    XCTAssertNotNil(image)
                    XCTAssertEqual(type, .memory)

                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testImageShouldOnlyFromMemoryCacheOrRefreshCanRefreshIfNotInMemory() {
        let expectation = self.expectation(description: "only from memory cache or refresh")
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        let url = URL(string: URLString)!

        manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh], progressBlock: nil) {
            image, _, type, _ in
            // Can download and cache normally
            XCTAssertNotNil(image)
            XCTAssertEqual(type, .none)
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: URLString), .memory)

            self.manager.cache.clearMemoryCache()
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: URLString), .disk)
            
            self.manager.retrieveImage(with: url, options: [.fromMemoryCacheOrRefresh], progressBlock: nil) {
                image, _, type, _ in
                XCTAssertNotNil(image)
                XCTAssertEqual(type, .none)
                XCTAssertEqual(self.manager.cache.imageCachedType(forKey: URLString), .memory)

                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldDownloadAndCacheProcessedImage() {
        let expectation = self.expectation(description: "waiting for downloading and cache")

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        let url = URL(string: URLString)!

        let size = CGSize(width: 1, height: 1)
        let processor = ResizingImageProcessor(referenceSize: size)

        manager.retrieveImage(with: url, options: [.processor(processor)], progressBlock: nil) {
            image, _, type, _ in
            // Can download and cache normally
            XCTAssertNotNil(image)
            XCTAssertEqual(image!.size, size)
            XCTAssertEqual(type, .none)

            self.manager.cache.clearMemoryCache()
            XCTAssertEqual(self.manager.cache.imageCachedType(forKey: URLString, processorIdentifier: processor.identifier), .disk)

            self.manager.retrieveImage(with: url, options: [.processor(processor)], progressBlock: nil) {
                image, _, type, _ in
                XCTAssertNotNil(image)
                XCTAssertEqual(image!.size, size)
                XCTAssertEqual(type, .disk)

                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS)
    func testShouldApplyImageModifierWhenDownload() {
        let expectation = self.expectation(description: "waiting for downloading and cache")

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)], progressBlock: nil) {
            image, _, _, _ in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(image?.renderingMode, .alwaysTemplate)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldApplyImageModifierWhenLoadFromMemoryCache() {
        let expectation = self.expectation(description: "waiting for downloading and cache")
        let URLString = testKeys[0]
        let url = URL(string: URLString)!

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        manager.cache.store(testImage, forKey: URLString)
        manager.retrieveImage(with: url, options: [.imageModifier(modifier)], progressBlock: nil) {
            image, _, type, _ in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(type, .memory)
            XCTAssertEqual(image?.renderingMode, .alwaysTemplate)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testShouldApplyImageModifierWhenLoadFromDiskCache() {
        let expectation = self.expectation(description: "waiting for downloading and cache")
        let URLString = testKeys[0]
        let url = URL(string: URLString)!

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        manager.cache.store(testImage, forKey: URLString) {
            self.manager.cache.clearMemoryCache()
            self.manager.retrieveImage(with: url, options: [.imageModifier(modifier)], progressBlock: nil) {
                image, _, type, _ in
                XCTAssertTrue(modifierCalled)
                XCTAssertEqual(type, .disk)
                XCTAssertEqual(image?.renderingMode, .alwaysTemplate)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
#endif
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
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        processed = true
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return Kingfisher<Image>.image(
                data: data,
                scale: options.scaleFactor,
                preloadAllAnimationData: options.preloadAllAnimationData,
                onlyFirstFrame: options.onlyLoadFirstFrame)
        }
    }
}

