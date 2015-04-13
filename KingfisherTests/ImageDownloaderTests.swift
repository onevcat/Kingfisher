//
//  ImageDownloaderTests.swift
//  Kingfisher-Demo
//
//  Created by WANG WEI on 2015/04/10.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

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
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)

        let URL = NSURL(string: URLString)!
        downloader.downloadImageWithURL(URL, options: KingfisherManager.OptionsNone, progressBlock: { (receivedSize, totalSize) -> () in
            return
        }) { (image, error, imageURL) -> () in
            expectation.fulfill()
            XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL)")
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testDownloadMultipleImages() {
        let expectation = expectationWithDescription("wait for all downloading finish")
        
        let group = dispatch_group_create()
        
        for URLString in testKeys {
            if let URL = NSURL(string: URLString) {
                dispatch_group_enter(group)
                stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
                downloader.downloadImageWithURL(URL, options: KingfisherManager.OptionsNone, progressBlock: { (receivedSize, totalSize) -> () in
                    
                }, completionHandler: { (image, error, imageURL) -> () in
                    XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL).")
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
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)

        for _ in 0...5 {
            dispatch_group_enter(group)
            downloader.downloadImageWithURL(NSURL(string: URLString)!, options: KingfisherManager.OptionsNone, progressBlock: { (receivedSize, totalSize) -> () in
                
                }) { (image, error, imageURL) -> () in
                    XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL).")
                    dispatch_group_leave(group)
                    
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
}
