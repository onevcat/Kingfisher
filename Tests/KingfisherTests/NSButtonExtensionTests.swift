//
//  UIButtonExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/17.
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

import AppKit
import XCTest
@testable import Kingfisher

class NSButtonExtensionTests: XCTestCase {

    var button: NSButton!

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
        
        button = NSButton()
        KingfisherManager.shared.downloader = ImageDownloader(name: "testDownloader")
        KingfisherManager.shared.defaultOptions = [.waitForCache]
        
        cleanDefaultCache()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        LSNocilla.sharedInstance().clearStubs()
        button = nil
        cleanDefaultCache()
        KingfisherManager.shared.defaultOptions = .empty
        super.tearDown()
    }

    func testDownloadAndSetImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)
        
        var progressBlockIsCalled = false

        button.kf.setImage(with: url, progressBlock: { _, _ in progressBlockIsCalled = true }) {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            
            let image = result.value?.image
            XCTAssertNotNil(image)
            XCTAssertTrue(image!.renderEqual(to: testImage))
            XCTAssertTrue(self.button.image!.renderEqual(to: testImage))
            XCTAssertEqual(result.value?.imageURL, self.button.kf.webURL)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDownloadAndSetAlternateImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        var progressBlockIsCalled = false
        button.kf.setAlternateImage(with: url, progressBlock: { _, _ in progressBlockIsCalled = true }) {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            
            let image = result.value?.image
            XCTAssertNotNil(image)
            XCTAssertTrue(image!.renderEqual(to: testImage))
            XCTAssertTrue(self.button.alternateImage!.renderEqual(to: testImage))
            XCTAssertEqual(result.value?.imageURL, self.button.kf.alternateWebURL)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            exp.fulfill()

        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCacnelImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)
        
        button.kf.setImage(with: url) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue((result.error as! KingfisherError).isTaskCancelled)
        }
        
        self.button.kf.cancelImageDownloadTask()
        _ = stub.go()
        delay(0.1) {
            exp.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCacnelAlternateImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)
        
        button.kf.setAlternateImage(with: url) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue((result.error as! KingfisherError).isTaskCancelled)
        }
        
        self.button.kf.cancelAlternateImageDownloadTask()
        _ = stub.go()
        delay(0.1) {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSettingNilURL() {
        let exp = expectation(description: #function)
        let url: URL? = nil
        button.kf.setAlternateImage(with: url, progressBlock: { _, _ in XCTFail() }) {
            result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            
            guard case KingfisherError.imageSettingError(reason: .emptyResource) = result.error! else {
                XCTFail()
                fatalError()
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

}
