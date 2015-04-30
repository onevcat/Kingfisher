//
//  UIImageViewExtensionTests.swift
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
import Kingfisher

class UIImageViewExtensionTests: XCTestCase {

    var imageView: UIImageView!
    
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
        imageView = UIImageView()
        KingfisherManager.sharedManager.downloader = ImageDownloader(name: "testDownloader")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        LSNocilla.sharedInstance().clearStubs()
        imageView = nil
        
        cleanDefaultCache()
        
        super.tearDown()
    }

    func testImageDownloadForImageView() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        var progressBlockIsCalled = false
        
        imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
        }) { (image, error, cacheType, imageURL) -> () in
            expectation.fulfill()
            
            XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
            XCTAssert(image != nil, "Downloaded image should exist.")
            XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
            XCTAssert(self.imageView.image! == testImage, "Downloaded image should be already set to the image property.")
            XCTAssert(self.imageView.kf_webURL == imageURL, "Web URL should equal to the downloaded url.")
            
            XCTAssert(cacheType == .None, "The cache type should be none here. This image was just downloaded.")
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testImageDownloadCancelForImageView() {
        let expectation = expectationWithDescription("wait for downloading image")

        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        var progressBlockIsCalled = false
        var completionBlockIsCalled = false
        
        let task = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
        }) { (image, error, cacheType, imageURL) -> () in
            completionBlockIsCalled = true
        }
        task.cancel()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.09)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
            XCTAssert(completionBlockIsCalled == false, "CompletionBlock should not be called since it is canceled.")
        }
        
        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

    func testImageDownloadCacelPartialTask() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in

            }) { (image, error, cacheType, imageURL) -> () in
                task1Completion = true
        }
        
        let task2 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                task2Completion = true
        }
        
        let task3 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                task3Completion = true
        }
        
        task1.cancel()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.09)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == false, "Task 1 is canceled. The completion flag should be fasle.")
            XCTAssert(task2Completion == true, "Task 2 should be completed.")
            XCTAssert(task3Completion == true, "Task 3 should be completed.")
        }
        
        waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    func testImageDownalodMultipleCaches() {
        
        let cache1 = ImageCache(name: "cache1")
        let cache2 = ImageCache(name: "cache2")
        
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: [.TargetCache: cache1], progressBlock: { (receivedSize, totalSize) -> () in
            
        }) { (image, error, cacheType, imageURL) -> () in
            
            XCTAssertTrue(cache1.isImageCachedForKey(URLString).cached, "This image should be cached in cache1.")
            XCTAssertFalse(cache2.isImageCachedForKey(URLString).cached, "This image should not be cached in cache2.")
            XCTAssertFalse(KingfisherManager.sharedManager.cache.isImageCachedForKey(URLString).cached, "This image should not be cached in default cache.")
            
            self.imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: [.TargetCache: cache2], progressBlock: { (receivedSize, totalSize) -> () in
                
            }, completionHandler: { (image, error, cacheType, imageURL) -> () in
                XCTAssertTrue(cache1.isImageCachedForKey(URLString).cached, "This image should be cached in cache1.")
                XCTAssertTrue(cache2.isImageCachedForKey(URLString).cached, "This image should be cached in cache2.")
                XCTAssertFalse(KingfisherManager.sharedManager.cache.isImageCachedForKey(URLString).cached, "This image should not be cached in default cache.")
                
                clearCaches([cache1, cache2])
                
                expectation.fulfill()
            })
            
        }
        
        waitForExpectationsWithTimeout(0.1, handler: { (error) -> Void in
            clearCaches([cache1, cache2])
        })
    }
}
