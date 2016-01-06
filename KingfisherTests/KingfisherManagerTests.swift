//
//  KingfisherManagerTests.swift
//  Kingfisher
//
//  Created by WANG WEI on 2015/10/22.
//  Copyright © 2015年 Wei Wang. All rights reserved.
//

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
}
