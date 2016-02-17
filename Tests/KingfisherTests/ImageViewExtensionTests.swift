//
//  UIImageViewExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/17.
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

class ImageViewExtensionTests: XCTestCase {

    var imageView: ImageView!
    
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
        imageView = ImageView()
        KingfisherManager.sharedManager.downloader = ImageDownloader(name: "testDownloader")
        cleanDefaultCache()
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
            XCTAssertTrue(NSThread.isMainThread())
        }) { (image, error, cacheType, imageURL) -> () in
            expectation.fulfill()
            
            XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
            XCTAssert(image != nil, "Downloaded image should exist.")
            XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
            XCTAssert(self.imageView.image! == testImage, "Downloaded image should be already set to the image property.")
            XCTAssert(self.imageView.kf_webURL == imageURL, "Web URL should equal to the downloaded url.")
            
            XCTAssert(cacheType == .None, "The cache type should be none here. This image was just downloaded.")
            XCTAssertTrue(NSThread.isMainThread())
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testImageDownloadCompletionHandlerRunningOnMainQueue() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        let customQueue = dispatch_queue_create("com.kingfisher.testQueue", DISPATCH_QUEUE_SERIAL)
        imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: [.CallbackDispatchQueue(customQueue)], progressBlock: { (receivedSize, totalSize) -> () in
            XCTAssertTrue(NSThread.isMainThread())
        }) { (image, error, cacheType, imageURL) -> () in
            XCTAssertTrue(NSThread.isMainThread(), "The image extension callback should be always in main queue.")
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testImageDownloadWithResourceForImageView() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        let resource = Resource(downloadURL: URL)
        
        var progressBlockIsCalled = false
        
        cleanDefaultCache()
        
        imageView.kf_setImageWithResource(resource, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
            }) { (image, error, cacheType, imageURL) -> () in
                expectation.fulfill()
                
                XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
                XCTAssert(image != nil, "Downloaded image should exist.")
                XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
                XCTAssert(self.imageView.image! == testImage, "Downloaded image should be already set to the image property.")
                XCTAssert(self.imageView.kf_webURL == imageURL, "Web URL should equal to the downloaded url.")
                
                XCTAssert(cacheType == .None, "The cache type should be none here. This image was just downloaded. But now is: \(cacheType)")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
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
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testImageDownloadCancelForImageViewAfterRequestStarted() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
        let URL = NSURL(string: URLString)!
        
        var progressBlockIsCalled = false
        var completionBlockIsCalled = false
        
        cleanDefaultCache()
        
        let task = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                completionBlockIsCalled = true
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            task.cancel()
            stub.go()
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
            XCTAssert(completionBlockIsCalled == true, "CompletionBlock should be called with error.")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testImageDownloadCancelPartialTaskBeforeRequest() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
        let URL = NSURL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in

            }) { (image, error, cacheType, imageURL) -> () in
                task1Completion = true
        }
        
        let _ = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task2Completion = true
        }
        
        let _ = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task3Completion = true
        }
        
        task1.cancel()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            stub.go()
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == false, "Task 1 should be not completed since it is cancelled before downloading started.")
            XCTAssert(task2Completion == true, "Task 2 should be completed.")
            XCTAssert(task3Completion == true, "Task 3 should be completed.")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testImageDownloadCancelPartialTaskAfterRequestStarted() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
        let URL = NSURL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task1Completion = true
        }
        
        let _ = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task2Completion = true
        }
        
        let _ = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task3Completion = true
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            task1.cancel()
            stub.go()
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == true, "Task 1 should be completed since task 2 and 3 are not cancelled and they are sharing the same downloading process.")
            XCTAssert(task2Completion == true, "Task 2 should be completed.")
            XCTAssert(task3Completion == true, "Task 3 should be completed.")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testImageDownloadCancelAllTasksAfterRequestStarted() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
        let URL = NSURL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                task1Completion = true
        }
        
        let task2 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                task2Completion = true
        }
        
        let task3 = imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                task3Completion = true
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            task1.cancel()
            task2.cancel()
            task3.cancel()
            stub.go()
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue()) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == true, "Task 1 should be completed with error.")
            XCTAssert(task2Completion == true, "Task 2 should be completed with error.")
            XCTAssert(task3Completion == true, "Task 3 should be completed with error.")
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testImageDownalodMultipleCaches() {
        
        let cache1 = ImageCache(name: "cache1")
        let cache2 = ImageCache(name: "cache2")
        
        cache1.clearDiskCache()
        cache2.clearDiskCache()
        
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: [.TargetCache(cache1)], progressBlock: { (receivedSize, totalSize) -> () in
            
        }) { (image, error, cacheType, imageURL) -> () in
            
            XCTAssertTrue(cache1.isImageCachedForKey(URLString).cached, "This image should be cached in cache1.")
            XCTAssertFalse(cache2.isImageCachedForKey(URLString).cached, "This image should not be cached in cache2.")
            XCTAssertFalse(KingfisherManager.sharedManager.cache.isImageCachedForKey(URLString).cached, "This image should not be cached in default cache.")
            
            self.imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: [.TargetCache(cache2)], progressBlock: { (receivedSize, totalSize) -> () in
                
            }, completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                XCTAssertTrue(cache1.isImageCachedForKey(URLString).cached, "This image should be cached in cache1.")
                XCTAssertTrue(cache2.isImageCachedForKey(URLString).cached, "This image should be cached in cache2.")
                XCTAssertFalse(KingfisherManager.sharedManager.cache.isImageCachedForKey(URLString).cached, "This image should not be cached in default cache.")
                
                clearCaches([cache1, cache2])
                
                expectation.fulfill()
            })
            
        }
        
        waitForExpectationsWithTimeout(5, handler: { (error) -> Void in
            clearCaches([cache1, cache2])
        })
    }
    
    func testIndicatorViewExisting() {
        imageView.kf_showIndicatorWhenLoading = true
        XCTAssertNotNil(imageView.kf_indicator, "The indicator view should exist when showIndicatorWhenLoading is true")
        
        imageView.kf_showIndicatorWhenLoading = false
        XCTAssertNil(imageView.kf_indicator, "The indicator view should be removed when showIndicatorWhenLoading set to false")
    }
    
    func testIndicatorViewAnimating() {
        imageView.kf_showIndicatorWhenLoading = true
        
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andReturn(200).withBody(testImageData)
        let URL = NSURL(string: URLString)!
        
        imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            let indicator = self.imageView.kf_indicator
            XCTAssertNotNil(indicator, "The indicator view should exist when showIndicatorWhenLoading is true")
            XCTAssertFalse(indicator!.hidden, "The indicator should be shown and animating when loading")

        }) { (image, error, cacheType, imageURL) -> () in
            let indicator = self.imageView.kf_indicator
            XCTAssertTrue(indicator!.hidden, "The indicator should stop and hidden after loading")
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testCacnelImageTask() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200).withBody(testImageData).delay()
        let URL = NSURL(string: URLString)!
        
        imageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
                XCTFail("Progress block should not be called.")
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                
                expectation.fulfill()
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            self.imageView.kf_cancelDownloadTask()
            stub.go()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testDownloadForMutipleURLs() {
        let expectation = expectationWithDescription("wait for downloading image")
        
        let URLStrings = [testKeys[0], testKeys[1]]
        stubRequest("GET", URLStrings[0]).andReturn(200).withBody(testImageData)
        stubRequest("GET", URLStrings[1]).andReturn(200).withBody(testImageData)
        let URLs = URLStrings.map{NSURL(string: $0)!}
        
        var task1Complete = false
        var task2Complete = false
        
        imageView.kf_setImageWithURL(URLs[0], placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                task1Complete = true
                XCTAssertNotNil(image)
                XCTAssertEqual(imageURL, URLs[0])
                XCTAssertNotEqual(self.imageView.image, image)
        }
        
        self.imageView.kf_setImageWithURL(URLs[1], placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                task2Complete = true
                XCTAssertNotNil(image)
                XCTAssertEqual(imageURL, URLs[1])
                XCTAssertEqual(self.imageView.image, image)
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1)), dispatch_get_main_queue()) { () -> Void in
            XCTAssertTrue(task1Complete, "Task 1 should be completed.")
            XCTAssertTrue(task2Complete, "Task 2 should be completed.")

            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5, handler: nil)
    }
}
