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
        
        let expectation = self.expectation(withDescription: "wait for downloading image")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = Foundation.URL(string: URLString)!

        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, CacheType.none)
            
            self.manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
                image, error, cacheType, imageURL in
                XCTAssertNotNil(image)
                XCTAssertEqual(cacheType, CacheType.memory)
                
                self.manager.cache.clearMemoryCache()
                self.manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
                    image, error, cacheType, imageURL in
                    XCTAssertNotNil(image)
                    XCTAssertEqual(cacheType, CacheType.disk)
                    
                    cleanDefaultCache()
                    self.manager.retrieveImageWithURL(URL, optionsInfo: [.forceRefresh], progressBlock: nil) {
                        image, error, cacheType, imageURL in
                        XCTAssertNotNil(image)
                        XCTAssertEqual(cacheType, CacheType.none)
                    
                        expectation.fulfill()
                    }
                }
            }
        }

        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testRetrieveImageNotModified() {
        let expectation = self.expectation(withDescription: "wait for downloading image")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = Foundation.URL(string: URLString)!
        
        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) {
            image, error, cacheType, imageURL in
            XCTAssertNotNil(image)
            XCTAssertEqual(cacheType, CacheType.none)
            
            self.manager.cache.clearMemoryCache()
            
            LSNocilla.sharedInstance().stop()
            LSNocilla.sharedInstance().start()
            stubRequest("GET", URLString).andReturn(304).withBody("12345")
            
            var progressCalled = false
            
            self.manager.retrieveImageWithURL(URL, optionsInfo: [.forceRefresh], progressBlock: {
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
        
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testSuccessCompletionHandlerRunningOnMainQueueDefaultly() {
        let progressExpectation = expectation(withDescription: "progressBlock running on main queue")
        let completionExpectation = expectation(withDescription: "completionHandler running on main queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = Foundation.URL(string: URLString)!
        
        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread())
            progressExpectation.fulfill()
            }, completionHandler: { _, error, _, _ in
                XCTAssertNil(error)
                XCTAssertTrue(Thread.isMainThread())
                completionExpectation.fulfill()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testErrorCompletionHandlerRunningOnMainQueueDefaultly() {
        let expectation = self.expectation(withDescription: "running on main queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(404)
        
        let URL = Foundation.URL(string: URLString)!
        
        manager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: { _, _ in
            //won't be called
            }, completionHandler: { _, error, _, _ in
                XCTAssertNotNil(error)
                XCTAssertTrue(Thread.isMainThread())
                expectation.fulfill()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testSucessCompletionHandlerRunningOnCustomQueue() {
        let progressExpectation = expectation(withDescription: "progressBlock running on custom queue")
        let completionExpectation = expectation(withDescription: "completionHandler running on custom queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        let URL = Foundation.URL(string: URLString)!
        
        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue", attributes: DispatchQueueAttributes.serial)
        manager.retrieveImageWithURL(URL, optionsInfo: [.callbackDispatchQueue(customQueue)], progressBlock: { _, _ in
            XCTAssertTrue(Thread.isMainThread())
            progressExpectation.fulfill()
            }, completionHandler: { _, error, _, _ in
                XCTAssertNil(error)
                XCTAssertEqual(String(validatingUTF8: DISPATCH_CURRENT_QUEUE_LABEL.label)!, "com.kingfisher.testQueue")
                completionExpectation.fulfill()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func testErrorCompletionHandlerRunningOnCustomQueue() {
        let expectation = self.expectation(withDescription: "running on custom queue")
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(404)
        
        let URL = Foundation.URL(string: URLString)!
        
        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue", attributes: DispatchQueueAttributes.serial)
        manager.retrieveImageWithURL(URL, optionsInfo: [.callbackDispatchQueue(customQueue)], progressBlock: { _, _ in
            //won't be called
            }, completionHandler: { _, error, _, _ in
                XCTAssertNotNil(error)
                XCTAssertEqual(String(validatingUTF8: DISPATCH_CURRENT_QUEUE_LABEL.label)!, "com.kingfisher.testQueue")
                expectation.fulfill()
        })
        waitForExpectations(withTimeout: 5, handler: nil)
    }
}
