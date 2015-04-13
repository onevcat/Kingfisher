//
//  ImageDownloaderTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
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
import Kingfisher

class ImageDownloaderTests: XCTestCase {
    
    var downloader: ImageDownloader!

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
        downloader = ImageDownloader()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        LSNocilla.sharedInstance().clearStubs()
        downloader = nil
    }
    
    func testDownloadAnImage() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let urlString = testKeys[0]
        stubRequest("GET", urlString).andReturn(200).withBody(testImageData)

        let url = NSURL(string: urlString)!
        downloader.downloadImageWithURL(url, options: KingfisherManager.OptionsNone, progressBlock: { (receivedSize, totalSize) -> () in
            return
        }) { (image, error, imageURL) -> () in
            expectation.fulfill()
            XCTAssert(image != nil, "Download should be able to finished for url: \(imageURL)")
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testDownloadMultipleImages() {
        let expectation = expectationWithDescription("wait for all downloading finish")
        
        let group = dispatch_group_create()
        
        for urlString in testKeys {
            if let url = NSURL(string: urlString) {
                dispatch_group_enter(group)
                stubRequest("GET", urlString).andReturn(200).withBody(testImageData)
                downloader.downloadImageWithURL(url, options: KingfisherManager.OptionsNone, progressBlock: { (receivedSize, totalSize) -> () in
                    
                }, completionHandler: { (image, error, imageURL) -> () in
                    XCTAssert(image != nil, "Download should be able to finished for url: \(imageURL).")
                    dispatch_group_leave(group)
                })
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testDownloadAnImageWithMultipleCallback() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let group = dispatch_group_create()
        let urlString = testKeys[0]
        stubRequest("GET", urlString).andReturn(200).withBody(testImageData)

        for _ in 0...5 {
            dispatch_group_enter(group)
            downloader.downloadImageWithURL(NSURL(string: urlString)!, options: KingfisherManager.OptionsNone, progressBlock: { (receivedSize, totalSize) -> () in
                
                }) { (image, error, imageURL) -> () in
                    XCTAssert(image != nil, "Download should be able to finished for url: \(imageURL).")
                    dispatch_group_leave(group)
                    
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
}
