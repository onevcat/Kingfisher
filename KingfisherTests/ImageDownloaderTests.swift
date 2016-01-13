//
//  ImageDownloaderTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
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
        downloader = ImageDownloader(name: "test")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        LSNocilla.sharedInstance().clearStubs()
        downloader = nil
        super.tearDown()
    }
    
    func testDownloadAnImage() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)

        let URL = NSURL(string: URLString)!
        downloader.downloadImageWithURL(URL, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            return
        }) { (image, error, imageURL, data) -> () in
            expectation.fulfill()
            XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL)")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadMultipleImages() {
        let expectation = expectationWithDescription("wait for all downloading finish")
        
        let group = dispatch_group_create()
        
        for URLString in testKeys {
            if let URL = NSURL(string: URLString) {
                dispatch_group_enter(group)
                stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
                downloader.downloadImageWithURL(URL, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
                    
                }, completionHandler: { (image, error, imageURL, data) -> () in
                    XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL).")
                    dispatch_group_leave(group)
                })
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadAnImageWithMultipleCallback() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let group = dispatch_group_create()
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)

        for _ in 0...5 {
            dispatch_group_enter(group)
            downloader.downloadImageWithURL(NSURL(string: URLString)!, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
                
                }) { (image, error, imageURL, data) -> () in
                    XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL).")
                    dispatch_group_leave(group)
                    
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadWithModifyingRequest() {
        let expectation = expectationWithDescription("wait for downloading image")

        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        
        downloader.requestModifier = {
            (request: NSMutableURLRequest) in
            request.URL = NSURL(string: URLString)
        }
        
        let someURL = NSURL(string: "some_strange_url")!
        downloader.downloadImageWithURL(someURL, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
        }) { (image, error, imageURL, data) -> () in
            XCTAssert(image != nil, "Download should be able to finished for URL: \(imageURL).")
            XCTAssertEqual(imageURL!, NSURL(string: URLString)!, "The returned imageURL should be the replaced one")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testServerNotModifiedResponse() {
        let expectation = expectationWithDescription("wait for server response 304")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(304)
        
        downloader.downloadImageWithURL(NSURL(string: URLString)!, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
        }) { (image, error, imageURL, data) -> () in
            XCTAssertNotNil(error, "There should be an error since server returning 304 and no image downloaded.")
            XCTAssertEqual(error!.code, KingfisherError.NotModified.rawValue, "The error should be NotModified.")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    // Since we could not receive one challage, no test for trusted hosts currently.
    // See http://stackoverflow.com/questions/27065372/why-is-a-https-nsurlsession-connection-only-challenged-once-per-domain for more.
    func testSSLCertificateValidation() {
        LSNocilla.sharedInstance().stop()
        
        let downloader = ImageDownloader(name: "ssl.test")
        
        let URL = NSURL(string: "https://testssl-expire.disig.sk/Expired.png")!
        
        let expectation = expectationWithDescription("wait for download from an invalid ssl site.")
        
        downloader.downloadImageWithURL(URL, progressBlock: nil, completionHandler: { (image, error, imageURL, data) -> () in
            XCTAssertNotNil(error, "Error should not be nil")
            XCTAssert(error?.code == NSURLErrorServerCertificateUntrusted || error?.code == NSURLErrorSecureConnectionFailed, "Error should be NSURLErrorServerCertificateUntrusted, but \(error)")
            expectation.fulfill()
            LSNocilla.sharedInstance().start()
        })
        
        waitForExpectationsWithTimeout(20) { (error) in
            XCTAssertNil(error, "\(error)")
            LSNocilla.sharedInstance().start()
        }
    }
    
    func testDownloadResultErrorAndRetry() {
        let expectation = expectationWithDescription("wait for downloading error")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andFailWithError(NSError(domain: "stubError", code: -1, userInfo: nil))
        let URL = NSURL(string: URLString)!
        
        downloader.downloadImageWithURL(URL, progressBlock: nil) { (image, error, imageURL, data) -> () in
            XCTAssertNotNil(error, "Should return with an error")
            
            LSNocilla.sharedInstance().clearStubs()
            stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
            
            // Retry the download
            self.downloader.downloadImageWithURL(URL, progressBlock: nil, completionHandler: { (image, error, imageURL, data) -> () in
                XCTAssertNil(error, "Download should be finished without error")
                expectation.fulfill()
            })
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadEmptyURL() {
        let expectation = expectationWithDescription("wait for downloading error")
        
        downloader.downloadImageWithURL(NSURL(string: "")!, progressBlock: { (receivedSize, totalSize) -> () in
            XCTFail("The progress block should not be called.")
            }) { (image, error, imageURL, originalData) -> () in
                XCTAssertNotNil(error, "An error should happen for empty URL")
                XCTAssertEqual(error!.code, KingfisherError.InvalidURL.rawValue)
                expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadTaskProperty() {
        let task = downloader.downloadImageWithURL(NSURL(string: "1234")!, progressBlock: { (receivedSize, totalSize) -> () in

            }) { (image, error, imageURL, originalData) -> () in
        }
        
        XCTAssertNotNil(task, "The task should exist.")
        XCTAssertEqual(task!.ownerDownloader, downloader, "The owner downloader should be correct")
        XCTAssertEqual(task!.URL, NSURL(string: "1234"), "The request URL should equal.")
    }
    
    func testCancelDownloadTask() {
        
        let expectation = expectationWithDescription("wait for downloading")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
        let URL = NSURL(string: URLString)!
        
        var progressBlockIsCalled = false
        var completionBlockIsCalled = false
        
        let downloadTask = downloader.downloadImageWithURL(URL, progressBlock: { (receivedSize, totalSize) -> () in
                progressBlockIsCalled = true
            }) { (image, error, imageURL, originalData) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error!.code, NSURLErrorCancelled)
                completionBlockIsCalled = true
        }
        
        XCTAssertNotNil(downloadTask)

        downloadTask!.cancel()
        stub.go()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.09)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
            XCTAssert(completionBlockIsCalled == true, "CompletionBlock should be called with error.")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadTaskNil() {
        let downloadTask = downloader.downloadImageWithURL(NSURL(string: "")!, progressBlock: nil, completionHandler: nil)
        XCTAssertNil(downloadTask)
    }
}
