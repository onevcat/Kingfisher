//
//  UIButtonExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/17.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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
        super.tearDown()
        LSNocilla.sharedInstance().stop()
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        button = UIButton()
        KingfisherManager.sharedManager.downloader = ImageDownloader(name: "testDownloader")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        LSNocilla.sharedInstance().clearStubs()
        button = nil
        
        cleanDefaultCache()
        
        super.tearDown()
    }

    func testDownloadAndSetImage() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        var progressBlockIsCalled = false
        button.kf_setImageWithURL(URL, forState: UIControlState.Highlighted, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
        }) { (image, error, cacheType, imageURL) -> () in
            expectation.fulfill()
            
            XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
            XCTAssert(image != nil, "Downloaded image should exist.")
            XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
            XCTAssert(self.button.imageForState(UIControlState.Highlighted)! == testImage, "Downloaded image should be already set to the image for state")
            XCTAssert(self.button.kf_webURLForState(UIControlState.Highlighted) == imageURL, "Web URL should equal to the downloaded url.")
            XCTAssert(cacheType == .None, "cacheType should be .None since the image was just downloaded.")
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadAndSetBackgroundImage() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        var progressBlockIsCalled = false
        button.kf_setBackgroundImageWithURL(URL, forState: UIControlState.Normal, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
            }) { (image, error, cacheType, imageURL) -> () in
                expectation.fulfill()
                
                XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
                XCTAssert(image != nil, "Downloaded image should exist.")
                XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
                XCTAssert(self.button.backgroundImageForState(UIControlState.Normal)! == testImage, "Downloaded image should be already set to the image for state")
                XCTAssert(self.button.kf_backgroundWebURLForState(UIControlState.Normal) == imageURL, "Web URL should equal to the downloaded url.")
                XCTAssert(cacheType == .None, "cacheType should be .None since the image was just downloaded.")

        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
