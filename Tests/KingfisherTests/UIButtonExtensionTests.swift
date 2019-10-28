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

class UIButtonExtensionTests: XCTestCase {

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

    func testDownloadAndSetImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)

        var progressBlockIsCalled = false
        
        button.kf.setImage(with: url, for: .normal, progressBlock: { _, _ in
            progressBlockIsCalled = true
        })
        {
            result in
            XCTAssertTrue(progressBlockIsCalled)
            let image = result.value?.image
            XCTAssertNotNil(image)
            
            XCTAssertTrue(image!.renderEqual(to: testImage))
            XCTAssertTrue(self.button.image(for: .normal)!.renderEqual(to: testImage))
            
            //XCTAssertEqual(self.button.kf.taskIdentifier(for: .normal), Source.Identifier.current)
            XCTAssertEqual(result.value!.cacheType, .none)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadAndSetBackgroundImage() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData, length: 123)
        
        var progressBlockIsCalled = false
        button.kf.setBackgroundImage(with: url, for: .normal, progressBlock: { _, _ in
            progressBlockIsCalled = true
        })
        {
            result in
    
            XCTAssertTrue(progressBlockIsCalled)
            
            let image = result.value?.image
            XCTAssertNotNil(image)
            XCTAssertTrue(image!.renderEqual(to: testImage))
            XCTAssertTrue(self.button.backgroundImage(for: .normal)!.renderEqual(to: testImage))
            XCTAssertEqual(result.value!.cacheType, .none)
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCacnelImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        button.kf.setImage(with: url, for: .highlighted) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            delay(0.1) { exp.fulfill() }
        }
        
        self.button.kf.cancelImageDownloadTask()
        _ = stub.go()

        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCacnelBackgroundImageTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)
        
        button.kf.setBackgroundImage(with: url, for: .highlighted) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            delay(0.1) { exp.fulfill() }
        }
        
        self.button.kf.cancelBackgroundImageDownloadTask()
        _ = stub.go()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingNilURL() {
        let exp = expectation(description: #function)
        
        let url: URL? = nil
        button.kf.setBackgroundImage(with: url, for: .normal) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            guard case .imageSettingError(reason: .emptySource) = result.error! else {
                XCTFail()
                return
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testSettingNonWorkingImageWithFailureImage() {
        let expectation = self.expectation(description: "wait for downloading image")
        let url = testURLs[0]
        stub(url, errorCode: 404)
        let state = UIControl.State()
        
        button.kf.setImage(with: url, for: state, options: [.onFailureImage(testImage)]) { (result) -> Void in
            XCTAssertNil(result.value)
            expectation.fulfill()
        }
        XCTAssertNil(button.image(for: state))
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(testImage, button.image(for: state))
    }
    
    func testSettingNonWorkingBackgroundImageWithFailureImage() {
        let expectation = self.expectation(description: "wait for downloading image")
        let url = testURLs[0]
        stub(url, errorCode: 404)
        let state = UIControl.State()
        
        button.kf.setBackgroundImage(with: url, for: state, options: [.onFailureImage(testImage)]) { (result) -> Void in
            XCTAssertNil(result.value)
            expectation.fulfill()
        }
        XCTAssertNil(button.backgroundImage(for: state))
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(testImage, button.backgroundImage(for: state))
    }
}
#endif
