//
//  UIImageViewExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/17.
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

class ImageViewExtensionTests: XCTestCase {

    var imageView: KFCrossPlatformImageView!
    
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

        imageView = KFCrossPlatformImageView()
        KingfisherManager.shared.downloader = ImageDownloader(name: "testDownloader")
        KingfisherManager.shared.defaultOptions = [.waitForCache]
        
        cleanDefaultCache()
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        imageView = nil
        cleanDefaultCache()
        KingfisherManager.shared.defaultOptions = .empty
        super.tearDown()
    }

    func testImageDownloadForImageView() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        var progressBlockIsCalled = false
        
        imageView.kf.setImage(
            with: url,
            progressBlock: { _, _ in
                progressBlockIsCalled = true
                XCTAssertTrue(Thread.isMainThread)
            })
        {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            XCTAssertNotNil(result.value)

            let value = result.value!
            XCTAssertTrue(value.image.renderEqual(to: testImage))
            XCTAssertTrue(self.imageView.image!.renderEqual(to: testImage))
            
            XCTAssertEqual(value.cacheType, .none)
            XCTAssertTrue(Thread.isMainThread)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageDownloadCompletionHandlerRunningOnMainQueue() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        imageView.kf.setImage(
            with: url,
            options: [.callbackQueue(.dispatch(customQueue))],
            progressBlock: { _, _ in XCTAssertTrue(Thread.isMainThread) })
        {
            result in
            XCTAssertTrue(Thread.isMainThread)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageDownloadWithResourceForImageView() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        var progressBlockIsCalled = false

        let resource = ImageResource(downloadURL: url)
        imageView.kf.setImage(
            with: resource,
            progressBlock: { _, _ in progressBlockIsCalled = true })
        {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            XCTAssertNotNil(result.value)

            let value = result.value!
            XCTAssertTrue(value.image.renderEqual(to: testImage))
            XCTAssertTrue(self.imageView.image!.renderEqual(to: testImage))

            XCTAssertEqual(value.cacheType, .none)
            XCTAssertTrue(Thread.isMainThread)

            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageDownloadCancelForImageView() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)

        let task = imageView.kf.setImage(
            with: url,
            progressBlock: { _, _ in XCTFail() })
        {
            result in
            XCTAssertNotNil(result.error)
            delay(0.1) { exp.fulfill() }
        }

        XCTAssertNotNil(task)
        task?.cancel()
        _ = stub.go()
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageDownloadCancelPartialTaskBeforeRequest() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        let group = DispatchGroup()
        
        group.enter()
        let task1 = KF.url(url)
            .onFailure { _ in group.leave() }
            .set(to: imageView)
        
        group.enter()
        KF.url(url)
            .onSuccess { _ in group.leave() }
            .set(to: imageView)
        
        group.enter()
        let anotherImageView = KFCrossPlatformImageView()
        KF.url(url)
            .onSuccess { _ in group.leave() }
            .set(to: anotherImageView)
        
        task1?.cancel()
        _ = stub.go()
        
        group.notify(queue: .main) {
            delay(0.1) { exp.fulfill() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageDownloadCancelAllTasksAfterRequestStarted() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        let group = DispatchGroup()
        
        group.enter()
        let task1 = imageView.kf.setImage(with: url) { result in
            XCTAssertNotNil(result.error)
            group.leave()
        }
        
        group.enter()
        let task2 = imageView.kf.setImage(with: url) { result in
            XCTAssertNotNil(result.error)
            group.leave()
        }
        
        group.enter()
        let task3 = imageView.kf.setImage(with: url) { result in
            XCTAssertNotNil(result.error)
            group.leave()
        }

        task1?.cancel()
        task2?.cancel()
        task3?.cancel()
        _ = stub.go()
        
        group.notify(queue: .main) {
            delay(0.1) { exp.fulfill() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testImageDownloadMultipleCaches() {
        
        let cache1 = ImageCache(name: "cache1")
        let cache2 = ImageCache(name: "cache2")
        
        cache1.clearDiskCache()
        cache2.clearDiskCache()
        cleanDefaultCache()
        
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let key = url.cacheKey

        imageView.kf.setImage(with: url, options: [.targetCache(cache1)]) { result in

            XCTAssertTrue(cache1.imageCachedType(forKey: key).cached)
            XCTAssertFalse(cache2.imageCachedType(forKey: key).cached)
            XCTAssertFalse(KingfisherManager.shared.cache.imageCachedType(forKey: key).cached)
            
            self.imageView.kf.setImage(with: url, options: [.targetCache(cache2), .waitForCache]) { result in
                XCTAssertTrue(cache1.imageCachedType(forKey: key).cached)
                XCTAssertTrue(cache2.imageCachedType(forKey: key).cached)
                XCTAssertFalse(KingfisherManager.shared.cache.imageCachedType(forKey: key).cached)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5) { error in
            clearCaches([cache1, cache2])
        }
    }
    
    func testIndicatorViewExisting() {
        imageView.kf.indicatorType = .activity
        XCTAssertNotNil(imageView.kf.indicator)
        XCTAssertTrue(imageView.kf.indicator is ActivityIndicator)

        imageView.kf.indicatorType = .none
        XCTAssertNil(imageView.kf.indicator)
    }
    
    func testCustomizeStructIndicatorExisting() {
        struct StructIndicator: Indicator {
            let view = KFCrossPlatformView()
            func startAnimatingView() {}
            func stopAnimatingView() {}
        }
        
        imageView.kf.indicatorType = .custom(indicator: StructIndicator())
        XCTAssertNotNil(imageView.kf.indicator)
        XCTAssertTrue(imageView.kf.indicator is StructIndicator)
        
        imageView.kf.indicatorType = .none
        XCTAssertNil(imageView.kf.indicator)
    }
    
    func testActivityIndicatorViewAnimating() {
        imageView.kf.indicatorType = .activity
        
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        imageView.kf.setImage(with: url, progressBlock: { receivedSize, totalSize in
            let indicator = self.imageView.kf.indicator
            XCTAssertNotNil(indicator)
            XCTAssertFalse(indicator!.view.isHidden)
        })
        {
            result in
            let indicator = self.imageView.kf.indicator
            XCTAssertTrue(indicator!.view.isHidden)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCanUseImageIndicatorViewAnimating() {
        
        imageView.kf.indicatorType = .image(imageData: testImageData)
        XCTAssertTrue(imageView.kf.indicator is ImageIndicator)
        let image = (imageView.kf.indicator?.view as? KFCrossPlatformImageView)?.image
        XCTAssertNotNil(image)
        XCTAssertTrue(image!.renderEqual(to: testImage))
        
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        imageView.kf.setImage(with: url, progressBlock: { receivedSize, totalSize in
            let indicator = self.imageView.kf.indicator
            XCTAssertNotNil(indicator)
            XCTAssertFalse(indicator!.view.isHidden)
        })
        {
            result in
            let indicator = self.imageView.kf.indicator
            XCTAssertTrue(indicator!.view.isHidden)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCancelImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        imageView.kf.setImage(with: url, progressBlock: { _, _ in XCTFail() }) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            delay(0.1) { exp.fulfill() }
        }

        self.imageView.kf.cancelDownloadTask()
        _ = stub.go()

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadForMutipleURLs() {
        let exp = expectation(description: #function)

        stub(testURLs[0], data: testImageData)
        stub(testURLs[1], data: testImageData)

        let group = DispatchGroup()
        
        group.enter()
        imageView.kf.setImage(with: testURLs[0]) { result in
            // The download successed, but not the resource we want.
            XCTAssertNotNil(result.error)
            if case .imageSettingError(
                reason: .notCurrentSourceTask(let result, _, let source)) = result.error!
            {
                XCTAssertEqual(source.url, testURLs[0])
                XCTAssertNotEqual(result!.image, self.imageView.image)
            } else {
                XCTFail()
            }
            group.leave()
        }
        
        group.enter()
        self.imageView.kf.setImage(with: testURLs[1]) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertEqual(result.value?.source.url, testURLs[1])
            XCTAssertEqual(result.value!.image, self.imageView.image)
            group.leave()
        }
        
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingNilURL() {
        let exp = expectation(description: #function)
        let url: URL? = nil
        imageView.kf.setImage(with: url, progressBlock: { _, _ in XCTFail() }) {
            result in
            XCTAssertNotNil(result.error)
            guard case .imageSettingError(reason: .emptySource) = result.error! else {
                XCTFail()
                fatalError()
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingImageWhileKeepingCurrentOne() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        imageView.image = testImage
        imageView.kf.setImage(with: url) { result in }
        XCTAssertNil(imageView.image)
        
        imageView.image = testImage
        imageView.kf.setImage(with: url, options: [.keepCurrentImageWhileLoading]) { result in
            XCTAssertEqual(self.imageView.image, result.value!.image)
            XCTAssertNotEqual(self.imageView.image, testImage)
            exp.fulfill()
        }
        XCTAssertEqual(testImage, imageView.image)

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingImageKeepingRespectingPlaceholder() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        // While current image is nil, set placeholder
        imageView.kf.setImage(with: url, placeholder: testImage, options: [.keepCurrentImageWhileLoading]) { result in }
        XCTAssertNotNil(imageView.image)
        XCTAssertEqual(testImage, imageView.image)
        
        // While current image is not nil, keep it
        let anotherImage = KFCrossPlatformImage(data: testImageJEPGData)
        imageView.image = anotherImage
        imageView.kf.setImage(with: url, placeholder: testImage, options: [.keepCurrentImageWhileLoading]) { result in
            XCTAssertNotEqual(self.imageView.image, anotherImage)
            exp.fulfill()
        }
        XCTAssertNotNil(imageView.image)
        XCTAssertEqual(anotherImage, imageView.image)

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSetGIFImageOnlyFirstFrameThenFullFrames() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageGIFData, length: 123)

        func loadFullGIFImage() {
            ImageCache.default.clearMemoryCache()
            
            imageView.kf.setImage(with: url, progressBlock: { _, _ in XCTFail() })
            {
                result in
                let image = result.value?.image
                XCTAssertNotNil(image)
                XCTAssertNotNil(image!.kf.images)
                XCTAssertEqual(image!.kf.images?.count, 8)
                
                XCTAssertEqual(result.value!.cacheType, .disk)
                XCTAssertTrue(Thread.isMainThread)
                
                exp.fulfill()
            }
        }

        var progressBlockIsCalled = false
        imageView.kf.setImage(with: url, options: [.onlyLoadFirstFrame, .waitForCache], progressBlock: { _, _ in
            progressBlockIsCalled = true
            XCTAssertTrue(Thread.isMainThread)
        })
        {
            result in

            XCTAssertTrue(progressBlockIsCalled)
            let image = result.value?.image
            XCTAssertNotNil(image)
            XCTAssertNil(image!.kf.images)

            XCTAssert(result.value!.cacheType == .none)

            let memory = KingfisherManager.shared.cache.memoryStorage.value(forKey: url.cacheKey)
            XCTAssertNotNil(memory)

            let disk = try! KingfisherManager.shared.cache.diskStorage.value(forKey: url.cacheKey)
            XCTAssertNotNil(disk)

            XCTAssertTrue(Thread.isMainThread)
            loadFullGIFImage()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // https://github.com/onevcat/Kingfisher/issues/1923
    func testLoadGIFImageWithDifferentOptions() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageGIFData)
        
        imageView.kf.setImage(with: url) { result in
            let fullImage = result.value?.image
            XCTAssertNotNil(fullImage)
            XCTAssertEqual(fullImage!.kf.images?.count, 8)
            
            self.imageView.kf.setImage(with: url, options: [.onlyLoadFirstFrame]) { result in
                let firstFrameImage = result.value?.image
                XCTAssertNotNil(firstFrameImage)
                XCTAssertNil(firstFrameImage!.kf.images)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3)
    }
    
    // https://github.com/onevcat/Kingfisher/issues/665
    // The completion handler should be called even when the image view loading url gets changed.
    func testIssue665() {
        let exp = expectation(description: #function)

        stub(testURLs[0], data: testImageData)
        stub(testURLs[1], data: testImageData)

        let group = DispatchGroup()
        
        group.enter()
        imageView.kf.setImage(with: testURLs[0]) { _ in
            group.leave()
        }
        
        group.enter()
        imageView.kf.setImage(with: testURLs[1]) { _ in
            group.leave()
        }
        
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageSettingWithPlaceholder() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        stub(url, data: testImageData, length: 123)

        let emptyImage = KFCrossPlatformImage()
        var processBlockCalled = false

        imageView.kf.setImage(
            with: url,
            placeholder: emptyImage,
            progressBlock: { _, _ in
                processBlockCalled = true
                XCTAssertEqual(self.imageView.image, emptyImage)
            })
        {
            result in
            XCTAssertTrue(processBlockCalled)
            XCTAssertTrue(self.imageView.image!.renderEqual(to: testImage))
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testImageSettingWithCustomizePlaceholder() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        stub(url, data: testImageData, length: 123)

        let view = KFCrossPlatformView()
        var processBlockCalled = false

        imageView.kf.setImage(
            with: url,
            placeholder: view,
            progressBlock: { _, _ in
                processBlockCalled = true
                XCTAssertNil(self.imageView.image)
                XCTAssertTrue(self.imageView.subviews.contains(view))
            })
        {
            result in
            XCTAssertTrue(processBlockCalled)
            XCTAssertTrue(self.imageView.image!.renderEqual(to: testImage))
            XCTAssertFalse(self.imageView.subviews.contains(view))
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testSettingNonWorkingImageWithCustomizePlaceholderAndFailureImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        stub(url, errorCode: 404)

        let view = KFCrossPlatformView()

        imageView.kf.setImage(
            with: url,
            placeholder: view,
            options: [.onFailureImage(testImage)])
        {
            result in
            XCTAssertEqual(self.imageView.image, testImage)
            XCTAssertFalse(self.imageView.subviews.contains(view))
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingNonWorkingImageWithFailureImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, errorCode: 404)

        imageView.kf.setImage(with: url, options: [.onFailureImage(testImage)]) {
            result in
            XCTAssertNil(result.value)

            if case KingfisherError.responseError(let reason) = result.error!,
               case .URLSessionError(error: let nsError) = reason
            {
                XCTAssertEqual((nsError as NSError).code, 404)
            } else {
                XCTFail()
            }
            XCTAssertEqual(self.imageView.image, testImage)
            exp.fulfill()
        }
        XCTAssertNil(imageView.image)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSettingNonWorkingImageWithEmptyFailureImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, errorCode: 404)
        
        imageView.kf.setImage(with: url, placeholder: testImage, options: [.onFailureImage(nil)]) {
            result in
            XCTAssertNil(result.value)
            XCTAssertNil(self.imageView.image)
            exp.fulfill()
        }
        XCTAssertEqual(testImage, imageView.image)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSettingNonWorkingImageWithoutFailureImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, errorCode: 404)
        
        imageView.kf.setImage(with: url, placeholder: testImage) {
            result in
            XCTAssertNil(result.value)
            XCTAssertEqual(testImage, self.imageView.image)
            exp.fulfill()
        }
        XCTAssertEqual(testImage, imageView.image)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // https://github.com/onevcat/Kingfisher/issues/1053
    func testSetSameURLWithDifferentProcessors() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        
        stub(url, data: testImageData)
        
        let size1 = CGSize(width: 10, height: 10)
        let p1 = ResizingImageProcessor(referenceSize: size1)
        
        let size2 = CGSize(width: 20, height: 20)
        let p2 = ResizingImageProcessor(referenceSize: size2)
        
        let group = DispatchGroup()
        
        group.enter()
        imageView.kf.setImage(with: url, options: [.processor(p1)]) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isNotCurrentTask)
            group.leave()
        }
        
        group.enter()
        imageView.kf.setImage(with: url, options: [.processor(p2)]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!.image.size, size2)
            group.leave()
        }
        
        group.notify(queue: .main) { exp.fulfill() }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testMemoryImageCacheExtendingExpirationTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let options: KingfisherOptionsInfo = [.cacheMemoryOnly, .memoryCacheExpiration(.seconds(1)), .memoryCacheAccessExtendingExpiration(.expirationTime(.seconds(100)))]
       
        imageView.kf.setImage(with: url, options: options) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertTrue(result.value!.cacheType == .none)
            
            let cacheKey = result.value!.source.cacheKey as NSString
            let expirationTime1 = ImageCache.default.memoryStorage.storage.object(forKey: cacheKey)?.estimatedExpiration
            XCTAssertNotNil(expirationTime1)
            
            delay(0.1, block: {
                self.imageView.kf.setImage(with: url, options: options) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertTrue(result.value!.cacheType == .memory)
                    
                    let expirationTime2 = ImageCache.default.memoryStorage.storage.object(forKey: cacheKey)?.estimatedExpiration
                    
                    XCTAssertNotNil(expirationTime2)
                    XCTAssertNotEqual(expirationTime1, expirationTime2)
                    XCTAssert(expirationTime1!.isPast(referenceDate: expirationTime2!))
                    XCTAssertGreaterThan(expirationTime2!.timeIntervalSince(expirationTime1!), 10)
                    
                    exp.fulfill()
                }
            })
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testMemoryImageCacheNotExtendingExpirationTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let options: KingfisherOptionsInfo = [.cacheMemoryOnly, .memoryCacheExpiration(.seconds(1)), .memoryCacheAccessExtendingExpiration(.none)]
  
        imageView.kf.setImage(with: url, options: options) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertTrue(result.value!.cacheType == .none)
            
            let cacheKey = result.value!.source.cacheKey as NSString
            let expirationTime1 = ImageCache.default.memoryStorage.storage.object(forKey: cacheKey)?.estimatedExpiration
            XCTAssertNotNil(expirationTime1)
            
            delay(0.1, block: {
                self.imageView.kf.setImage(with: url, options: options) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertTrue(result.value!.cacheType == .memory)
                    
                    let expirationTime2 = ImageCache.default.memoryStorage.storage.object(forKey: cacheKey)?.estimatedExpiration
                    
                    XCTAssertNotNil(expirationTime2)
                    XCTAssertEqual(expirationTime1, expirationTime2)
                    
                    exp.fulfill()
                }
            })
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDiskImageCacheExtendingExpirationTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let options: KingfisherOptionsInfo = [.memoryCacheExpiration(.expired),
                                              .diskCacheExpiration(.seconds(2)),
                                              .diskCacheAccessExtendingExpiration(.expirationTime(.seconds(100)))]

        imageView.kf.setImage(with: url, options: options) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertTrue(result.value!.cacheType == .none)

            delay(1, block: {
                self.imageView.kf.setImage(with: url, options: options) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertTrue(result.value!.cacheType == .disk)
                    delay(2, block: {
                        self.imageView.kf.setImage(with: url, options: options) { result in
                            XCTAssertNotNil(result.value?.image)
                            XCTAssertTrue(result.value!.cacheType == .disk)

                            exp.fulfill()
                        }
                    })
                }
            })
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDiskImageCacheNotExtendingExpirationTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let options: KingfisherOptionsInfo = [.memoryCacheExpiration(.expired),
                                              .diskCacheExpiration(.seconds(2)),
                                              .diskCacheAccessExtendingExpiration(.none)]

        imageView.kf.setImage(with: url, options: options) { result in
            XCTAssertNotNil(result.value?.image)
            XCTAssertTrue(result.value!.cacheType == .none)

            delay(1, block: {
                self.imageView.kf.setImage(with: url, options: options) { result in
                    XCTAssertNotNil(result.value?.image)
                    XCTAssertTrue(result.value!.cacheType == .disk)

                        delay(2, block: {
                            self.imageView.kf.setImage(with: url, options: options) { result in
                                XCTAssertNotNil(result.value?.image)
                                XCTAssertTrue(result.value!.cacheType == .none)

                                exp.fulfill()
                            }
                        })
                }
            })
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testImageSettingWithAlternativeSource() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData)

        let brokenURL = URL(string: "brokenurl")!
        stub(brokenURL, data: Data())

        imageView.kf.setImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])]
        ) { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!.source.url, url)
            XCTAssertEqual(result.value!.originalSource.url, brokenURL)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testImageSettingCanCancelAlternativeSource() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let dataStub = delayedStub(url, data: testImageData)

        let brokenURL = testURLs[1]
        let brokenStub = delayedStub(brokenURL, data: Data())

        var finishCalled = false

        delay(0.1) {
            _ = brokenStub.go()
        }
        delay(0.3) {
            self.imageView.kf.cancelDownloadTask()
        }
        delay(0.5) {
            _ = dataStub.go()
            XCTAssertTrue(finishCalled)
            exp.fulfill()
        }

        imageView.kf.setImage(
            with: .network(brokenURL),
            options: [.alternativeSources([.network(url)])]
        ) { result in
            finishCalled = true
            XCTAssertNotNil(result.error)
            guard case .requestError(reason: .taskCancelled(let task, _)) = result.error! else {
                XCTFail("The error should be a task cancelled.")
                return
            }
            XCTAssertEqual(task.task.originalRequest?.url, url, "Should be the alternatived url cancelled.")
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testLowDataModeSource() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData)

        // Stub a failure of `.constrained`. It is what happens when an image downloading fails when low data mode on.
        let brokenURL = testURLs[1]
        let error = URLError(
            .notConnectedToInternet,
            userInfo: [NSURLErrorNetworkUnavailableReasonKey: URLError.NetworkUnavailableReason.constrained.rawValue]
        )
        stub(brokenURL, error: error)

        imageView.kf.setImage(with: .network(brokenURL), options: [.lowDataMode(.network(url))]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.source.url, url)
            XCTAssertEqual(result.value?.originalSource.url, brokenURL)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

}

extension KFCrossPlatformView: Placeholder {}
