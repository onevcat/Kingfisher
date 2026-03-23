//
//  UIButtonExtensionTests.swift
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

#if canImport(UIKit)
import UIKit
import XCTest
@testable import Kingfisher

class UIButtonExtensionTests: XCTestCase, @unchecked Sendable {

    var button: UIButton!
    
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
        button = UIButton()
        KingfisherManager.shared.downloader = ImageDownloader(name: "testDownloader")
        KingfisherManager.shared.defaultOptions = [.waitForCache]
        
        cleanDefaultCache()
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        button = nil
        cleanDefaultCache()
        KingfisherManager.shared.defaultOptions = .empty
        super.tearDown()
    }

    @MainActor func testDownloadAndSetImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        var progressBlockIsCalled = false

        KF.url(url)
            .onProgress { _, _ in
                progressBlockIsCalled = true
            }
            .onSuccess { result in
                XCTAssertTrue(progressBlockIsCalled)

                XCTAssertTrue(result.image.renderEqual(to: testImage))
                XCTAssertTrue(self.button.image(for: .normal)!.renderEqual(to: testImage))

                XCTAssertEqual(result.cacheType, .none)

                exp.fulfill()
            }
            .set(to: button, for: .normal)

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    @MainActor func testDownloadAndSetBackgroundImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)
        
        var progressBlockIsCalled = false
        KF.url(url)
            .onProgress { _, _ in
                progressBlockIsCalled = true
            }
            .onSuccess { result in
                XCTAssertTrue(progressBlockIsCalled)

                XCTAssertTrue(result.image.renderEqual(to: testImage))
                XCTAssertTrue(self.button.backgroundImage(for: .normal)!.renderEqual(to: testImage))

                XCTAssertEqual(result.cacheType, .none)

                exp.fulfill()
            }
            .setBackground(to: button, for: .normal)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    @MainActor func testCancelImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        KF.url(url)
            .onFailure { error in
                XCTAssertTrue(error.isTaskCancelled)
                delay(0.1) { exp.fulfill() }
            }
            .set(to: button, for: .highlighted)
        
        self.button.kf.cancelImageDownloadTask()
        _ = stub.go()

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    @MainActor func testCancelBackgroundImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        KF.url(url)
            .onFailure { error in
                XCTAssertTrue(error.isTaskCancelled)
                delay(0.1) { exp.fulfill() }
            }
            .setBackground(to: button, for: .highlighted)
        
        self.button.kf.cancelBackgroundImageDownloadTask()
        _ = stub.go()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    @MainActor func testSettingNilURL() {
        let exp = expectation(description: #function)
        
        let url: URL? = nil
        button.kf.setBackgroundImage(with: url, for: .normal, completionHandler:  { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            guard case .imageSettingError(reason: .emptySource) = result.error! else {
                XCTFail()
                return
            }
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    @MainActor func testSettingNonWorkingImageWithFailureImage() {
        let expectation = self.expectation(description: "wait for downloading image")
        let url = testURLs[0]
        stub(url, errorCode: 404)
        let state = UIControl.State()

        KF.url(url)
            .onFailureImage(testImage)
            .onFailure { error in
                XCTAssertEqual(testImage, self.button.image(for: state))
                expectation.fulfill()
            }
            .set(to: button, for: state)
        XCTAssertNil(button.image(for: state))
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    @MainActor func testSettingNonWorkingBackgroundImageWithFailureImage() {
        let expectation = self.expectation(description: "wait for downloading image")
        let url = testURLs[0]
        stub(url, errorCode: 404)
        let state = UIControl.State()

        KF.url(url)
            .onFailureImage(testImage)
            .onFailure { error in
                XCTAssertEqual(testImage, self.button.backgroundImage(for: state))
                expectation.fulfill()
            }
            .setBackground(to: button, for: state)

        XCTAssertNil(button.backgroundImage(for: state))
        waitForExpectations(timeout: 5, handler: nil)

    }

    @MainActor func testSupersededDiskCachedImageDoesNotPromoteToMemory() {
        let exp = expectation(description: #function)
        let url1 = testURLs[0]
        let url2 = testURLs[1]
        let coordinator = CoordinatingCacheSerializer()
        let cache = KingfisherManager.shared.cache
        let group = DispatchGroup()

        group.enter()
        cache.store(testImage, original: testImageData, forKey: url1.cacheKey, toDisk: true) { _ in
            group.leave()
        }
        group.enter()
        cache.store(testImage, original: testImageData, forKey: url2.cacheKey, toDisk: true) { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            cache.clearMemoryCache()

            let completionGroup = DispatchGroup()

            completionGroup.enter()
            self.button.kf.setImage(
                with: url1,
                for: .normal,
                options: [.cacheSerializer(coordinator)],
                completionHandler: { result in
                XCTAssertNotNil(result.error)
                if case .imageSettingError(reason: .notCurrentSourceTask) = result.error! {
                } else {
                    XCTFail("First setImage should receive .notCurrentSourceTask, got: \(result.error!)")
                }
                completionGroup.leave()
            })

            DispatchQueue.global().async {
                coordinator.waitUntilFirstCallEntered()

                DispatchQueue.main.async {
                    completionGroup.enter()
                    self.button.kf.setImage(
                        with: url2,
                        for: .normal,
                        options: [.cacheSerializer(coordinator)],
                        completionHandler: { result in
                        XCTAssertNotNil(result.value?.image)
                        completionGroup.leave()
                    })

                    coordinator.allowFirstCallToProceed()
                }
            }

            completionGroup.notify(queue: .main) {
                XCTAssertNil(
                    cache.retrieveImageInMemoryCache(forKey: url1.cacheKey),
                    "Superseded button image task must not promote to memory cache"
                )
                XCTAssertNotNil(
                    cache.retrieveImageInMemoryCache(forKey: url2.cacheKey),
                    "Current button image task should promote to memory cache"
                )
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    @MainActor func testCancelBackgroundImageTaskCancelsDiskCacheRetrieval() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let coordinator = CoordinatingCacheSerializer()
        let cache = KingfisherManager.shared.cache

        let storeExp = expectation(description: "store")
        cache.store(testImage, original: testImageData, forKey: url.cacheKey, toDisk: true) { _ in
            storeExp.fulfill()
        }
        wait(for: [storeExp], timeout: 3)
        cache.clearMemoryCache()

        button.kf.setBackgroundImage(
            with: url,
            for: .normal,
            options: [.cacheSerializer(coordinator)],
            completionHandler: { _ in
            exp.fulfill()
        })

        DispatchQueue.global().async {
            coordinator.waitUntilFirstCallEntered()

            DispatchQueue.main.async {
                self.button.kf.cancelBackgroundImageDownloadTask()
                coordinator.allowFirstCallToProceed()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNil(
            cache.retrieveImageInMemoryCache(forKey: url.cacheKey),
            "cancelBackgroundImageDownloadTask() must prevent disk cache result from being promoted to memory"
        )
    }
}
#endif
