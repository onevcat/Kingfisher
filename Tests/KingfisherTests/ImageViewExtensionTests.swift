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
        KingfisherManager.shared.downloader = ImageDownloader(name: "testDownloader")
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
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        var progressBlockIsCalled = false
        
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
            XCTAssertTrue(Thread.isMainThread)
        }) { (image, error, cacheType, imageURL) -> () in
            expectation.fulfill()
            
            XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
            XCTAssert(image != nil, "Downloaded image should exist.")
            XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
            XCTAssert(self.imageView.image! == testImage, "Downloaded image should be already set to the image property.")
            XCTAssert(self.imageView.kf.webURL == imageURL, "Web URL should equal to the downloaded url.")
            
            XCTAssert(cacheType == .none, "The cache type should be none here. This image was just downloaded.")
            XCTAssertTrue(Thread.isMainThread)
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadCompletionHandlerRunningOnMainQueue() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        let customQueue = DispatchQueue(label: "com.kingfisher.testQueue")
        imageView.kf.setImage(with: url, placeholder: nil, options: [.callbackDispatchQueue(customQueue)], progressBlock: { (receivedSize, totalSize) -> () in
            XCTAssertTrue(Thread.isMainThread)
        }) { (image, error, cacheType, imageURL) -> () in
            XCTAssertTrue(Thread.isMainThread, "The image extension callback should be always in main queue.")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadWithResourceForImageView() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        let resource = ImageResource(downloadURL: url)
        
        var progressBlockIsCalled = false
        
        cleanDefaultCache()
        
        _ = imageView.kf.setImage(with: resource, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
            }) { (image, error, cacheType, imageURL) -> () in
                expectation.fulfill()
                
                XCTAssert(progressBlockIsCalled, "progressBlock should be called at least once.")
                XCTAssert(image != nil, "Downloaded image should exist.")
                XCTAssert(image! == testImage, "Downloaded image should be the same as test image.")
                XCTAssert(self.imageView.image! == testImage, "Downloaded image should be already set to the image property.")
                XCTAssert(self.imageView.kf.webURL == imageURL, "Web URL should equal to the downloaded url.")
                
                XCTAssert(cacheType == .none, "The cache type should be none here. This image was just downloaded. But now is: \(cacheType)")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadCancelForImageView() {
        let expectation = self.expectation(description: "wait for downloading image")

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        var progressBlockIsCalled = false
        var completionBlockIsCalled = false
        
        let task = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
        }) { (image, error, cacheType, imageURL) -> () in
            completionBlockIsCalled = true
        }

        task.cancel()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.09)) / Double(NSEC_PER_SEC)) { () -> Void in
            expectation.fulfill()
            XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
            XCTAssert(completionBlockIsCalled == false, "CompletionBlock should not be called since it is canceled.")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadCancelForImageViewAfterRequestStarted() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        var progressBlockIsCalled = false
        var completionBlockIsCalled = false
        
        cleanDefaultCache()
        
        let task = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            progressBlockIsCalled = true
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                completionBlockIsCalled = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.1)) / Double(NSEC_PER_SEC)) { () -> Void in
            task.cancel()
            _ = stub!.go()
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.2)) / Double(NSEC_PER_SEC)) { () -> Void in
            expectation.fulfill()
            XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
            XCTAssert(completionBlockIsCalled == true, "CompletionBlock should be called with error.")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testImageDownloadCancelPartialTaskBeforeRequest() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in

            }) { (image, error, cacheType, imageURL) -> () in
                task1Completion = true
        }
        
        let _ = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task2Completion = true
        }
        
        let _ = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task3Completion = true
        }
        
        task1.cancel()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.1)) / Double(NSEC_PER_SEC)) { () -> Void in
            _ = stub!.go()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.2)) / Double(NSEC_PER_SEC)) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == false, "Task 1 should be not completed since it is cancelled before downloading started.")
            XCTAssert(task2Completion == true, "Task 2 should be completed.")
            XCTAssert(task3Completion == true, "Task 3 should be completed.")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadCancelPartialTaskAfterRequestStarted() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task1Completion = true
        }
        
        let _ = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task2Completion = true
        }
        
        let _ = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(image)
                task3Completion = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.1)) / Double(NSEC_PER_SEC)) { () -> Void in
            task1.cancel()
            _ = stub!.go()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.2)) / Double(NSEC_PER_SEC)) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == true, "Task 1 should be completed since task 2 and 3 are not cancelled and they are sharing the same downloading process.")
            XCTAssert(task2Completion == true, "Task 2 should be completed.")
            XCTAssert(task3Completion == true, "Task 3 should be completed.")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadCancelAllTasksAfterRequestStarted() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        var task1Completion = false
        var task2Completion = false
        var task3Completion = false
        
        let task1 = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                task1Completion = true
        }
        
        let task2 = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                task2Completion = true
        }
        
        let task3 = imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                task3Completion = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.1)) / Double(NSEC_PER_SEC)) { () -> Void in
            task1.cancel()
            task2.cancel()
            task3.cancel()
            _ = stub!.go()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.2)) / Double(NSEC_PER_SEC)) { () -> Void in
            expectation.fulfill()
            XCTAssert(task1Completion == true, "Task 1 should be completed with error.")
            XCTAssert(task2Completion == true, "Task 2 should be completed with error.")
            XCTAssert(task3Completion == true, "Task 3 should be completed with error.")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testImageDownloadMultipleCaches() {
        
        let cache1 = ImageCache(name: "cache1")
        let cache2 = ImageCache(name: "cache2")
        
        cache1.clearDiskCache()
        cache2.clearDiskCache()
        
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        imageView.kf.setImage(with: url, placeholder: nil, options: [.targetCache(cache1)], progressBlock: { (receivedSize, totalSize) -> () in
            
        }) { (image, error, cacheType, imageURL) -> () in
            
            XCTAssertTrue(cache1.isImageCached(forKey: URLString).cached, "This image should be cached in cache1.")
            XCTAssertFalse(cache2.isImageCached(forKey: URLString).cached, "This image should not be cached in cache2.")
            XCTAssertFalse(KingfisherManager.shared.cache.isImageCached(forKey: URLString).cached, "This image should not be cached in default cache.")
            
            self.imageView.kf.setImage(with: url, placeholder: nil, options: [.targetCache(cache2)], progressBlock: { (receivedSize, totalSize) -> () in
                
            }, completionHandler: { (image, error, cacheType, imageURL) -> () in
                
                XCTAssertTrue(cache1.isImageCached(forKey: URLString).cached, "This image should be cached in cache1.")
                XCTAssertTrue(cache2.isImageCached(forKey: URLString).cached, "This image should be cached in cache2.")
                XCTAssertFalse(KingfisherManager.shared.cache.isImageCached(forKey: URLString).cached, "This image should not be cached in default cache.")
                
                clearCaches([cache1, cache2])
                
                expectation.fulfill()
            })
            
        }
        
        waitForExpectations(timeout: 5, handler: { (error) -> Void in
            clearCaches([cache1, cache2])
        })
    }
    
    func testIndicatorViewExisting() {
        imageView.kf.indicatorType = .activity
        XCTAssertNotNil(imageView.kf.indicator, "The indicator should exist when indicatorType is different than .none")
        XCTAssertTrue(imageView.kf.indicator is ActivityIndicator)


        imageView.kf.indicatorType = .none
        XCTAssertNil(imageView.kf.indicator, "The indicator should be removed when indicatorType is .none")
    }
    
    func testActivityIndicatorViewAnimating() {
        imageView.kf.indicatorType = .activity
        
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            let indicator = self.imageView.kf.indicator
            XCTAssertNotNil(indicator, "The indicator view should exist when showIndicatorWhenLoading is true")
            XCTAssertFalse(indicator!.view.isHidden, "The indicator should be shown and animating when loading")

        }) { (image, error, cacheType, imageURL) -> () in
            let indicator = self.imageView.kf.indicator
            XCTAssertTrue(indicator!.view.isHidden, "The indicator should stop and hidden after loading")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanUseImageIndicatorViewAnimating() {
        
        imageView.kf.indicatorType = .image(imageData: testImageData as! Data)
        XCTAssertTrue(imageView.kf.indicator is ImageIndicator)
        let image = (imageView.kf.indicator?.view as? ImageView)?.image
        XCTAssertNotNil(image)
        XCTAssertTrue(image!.renderEqual(to: testImage))
        
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            let indicator = self.imageView.kf.indicator
            XCTAssertNotNil(indicator, "The indicator view should exist when showIndicatorWhenLoading is true")
            XCTAssertFalse(indicator!.view.isHidden, "The indicator should be shown and animating when loading")
            
        }) { (image, error, cacheType, imageURL) -> () in
            let indicator = self.imageView.kf.indicator
            XCTAssertTrue(indicator!.view.isHidden, "The indicator should stop and hidden after loading")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCacnelImageTask() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
                XCTFail("Progress block should not be called.")
            }) { (image, error, cacheType, imageURL) -> () in
                XCTAssertNotNil(error)
                XCTAssertEqual(error?.code, NSURLErrorCancelled)
                
                expectation.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.1)) / Double(NSEC_PER_SEC)) { () -> Void in
            self.imageView.kf.cancelDownloadTask()
            _ = stub!.go()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadForMutipleURLs() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLStrings = [testKeys[0], testKeys[1]]
        _ = stubRequest("GET", URLStrings[0]).andReturn(200)?.withBody(testImageData)
        _ = stubRequest("GET", URLStrings[1]).andReturn(200)?.withBody(testImageData)
        let URLs = URLStrings.map{URL(string: $0)!}
        
        var task1Complete = false
        var task2Complete = false
        
        imageView.kf.setImage(with: URLs[0], placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                task1Complete = true
                XCTAssertNotNil(image)
                XCTAssertEqual(imageURL, URLs[0])
                XCTAssertNotEqual(self.imageView.image, image)
        }
        
        self.imageView.kf.setImage(with: URLs[1], placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageURL) -> () in
                task2Complete = true
                XCTAssertNotNil(image)
                XCTAssertEqual(imageURL, URLs[1])
                XCTAssertEqual(self.imageView.image, image)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * 0.1)) / Double(NSEC_PER_SEC)) { () -> Void in
            XCTAssertFalse(task1Complete, "Task 1 should not be completed since task 2 overrides it.")
            XCTAssertTrue(task2Complete, "Task 2 should be completed.")

            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSettingNilURL() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let url: URL? = nil
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { (receivedSize, totalSize) -> () in
            XCTFail("Progress block should not be called.")
        }) { (image, error, cacheType, imageURL) -> () in
            XCTAssertNil(image)
            XCTAssertNil(error)
            XCTAssertEqual(cacheType, CacheType.none)
            XCTAssertNil(imageURL)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSettingImageWhileKeepingCurrentOne() {

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        let url = URL(string: URLString)!
        
        imageView.image = testImage
        imageView.kf.setImage(with: url, placeholder: nil, options: nil)
        XCTAssertNil(imageView.image)
        
        imageView.image = testImage
        imageView.kf.setImage(with: url, placeholder: nil, options: [.keepCurrentImageWhileLoading])
        XCTAssertEqual(testImage, imageView.image)
    }
}
