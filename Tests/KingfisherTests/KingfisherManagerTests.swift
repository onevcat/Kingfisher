//
//  KingfisherManagerTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/22.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }
    
    func testRetrieveImage() {
        
        let expectation = expectationWithDescription("wait for downloading image")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = NSURL(string: URLString)!

        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, CacheType.None)
            
            self.manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
                image, error, cacheType, imageURL in
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, CacheType.Memory)
                
                self.manager.cache.clearMemoryCache()
                self.manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
                    image, error, cacheType, imageURL in
                    XCTAssertNotNil(image)
                    XCTAssertEqual(cacheType, CacheType.Disk)
                    
                    cleanDefaultCache()
                    self.manager.retrieveImageWithURL(URL, optionsInfo: [.ForceRefresh], progressBlock: nil) {
                        image, error, cacheType, imageURL in
                        XCTAssertNotNil(image)
                        XCTAssertEqual(cacheType, CacheType.None)
                    
                        expectation.fulfill()
                    }
                }
            }
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testRetrieveImageNotModified() {
        let expectation = expectationWithDescription("wait for downloading image")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = NSURL(string: URLString)!
        
        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, CacheType.None)
            
            self.manager.cache.clearMemoryCache()
            
            LSNocilla.sharedInstance().stop()
            LSNocilla.sharedInstance().start()
            stubRequest("GET", URLString).andReturn(304).withBody("12345")
            
            var progressCalled = false
            
            self.manager.retrieveImageWithURL(URL, optionsInfo: [.ForceRefresh], progressBlock: {
                _, _ in
                progressCalled = true
            }) {
                image, error, cacheType, imageURL in
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, CacheType.Disk)
                
                XCTAssertTrue(progressCalled, "The progress callback should be called at least once since network connecting happens.")
                
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testSuccessCompletionHandlerRunningOnMainQueueDefaultly() {
        let progressExpectation = expectationWithDescription("progressBlock running on main queue")
        let completionExpectation = expectationWithDescription("completionHandler running on main queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = NSURL(string: URLString)!
        
        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: { _, _ in
            XCTAssertTrue(NSThread.isMainThread())
            progressExpectation.fulfill()
            }, completionHandler: { _, error, _, _ in
                XCTAssertNil(error)
                XCTAssertTrue(NSThread.isMainThread())
                completionExpectation.fulfill()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testErrorCompletionHandlerRunningOnMainQueueDefaultly() {
        let expectation = expectationWithDescription("running on main queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(404)
        
        let URL = NSURL(string: URLString)!
        
        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: { _, _ in
            //won't be called
            }, completionHandler: { _, error, _, _ in
                XCTAssertNotNil(error)
                XCTAssertTrue(NSThread.isMainThread())
                expectation.fulfill()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testSucessCompletionHandlerRunningOnCustomQueue() {
        let progressExpectation = expectationWithDescription("progressBlock running on custom queue")
        let completionExpectation = expectationWithDescription("completionHandler running on custom queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = NSURL(string: URLString)!
        
        let customQueue = dispatch_queue_create("com.kingfisher.testQueue", DISPATCH_QUEUE_SERIAL)
        manager.retrieveImageWithURL(URL, optionsInfo: [.CallbackDispatchQueue(customQueue)], progressBlock: { _, _ in
            XCTAssertTrue(NSThread.isMainThread())
            progressExpectation.fulfill()
            }, completionHandler: { _, error, _, _ in
                XCTAssertNil(error)
                XCTAssertEqual(String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!, "com.kingfisher.testQueue")
                completionExpectation.fulfill()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testErrorCompletionHandlerRunningOnCustomQueue() {
        let expectation = expectationWithDescription("running on custom queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(404)
        
        let URL = NSURL(string: URLString)!
        
        let customQueue = dispatch_queue_create("com.kingfisher.testQueue", DISPATCH_QUEUE_SERIAL)
        manager.retrieveImageWithURL(URL, optionsInfo: [.CallbackDispatchQueue(customQueue)], progressBlock: { _, _ in
            //won't be called
            }, completionHandler: { _, error, _, _ in
                XCTAssertNotNil(error)
                XCTAssertEqual(String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!, "com.kingfisher.testQueue")
                expectation.fulfill()
        })
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
