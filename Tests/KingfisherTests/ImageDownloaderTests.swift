//
//  ImageDownloaderTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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
    var modifier = URLModifier()
    
    
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
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        let url = URL(string: URLString)!
        downloader.downloadImage(with: url, options: nil, progressBlock: { (receivedSize, totalSize) -> Void in
            return
        }) { (image, error, imageURL, data) -> Void in
            expectation.fulfill()
            XCTAssert(image != nil, "Download should be able to finished for URL: \(String(describing: imageURL))")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadMultipleImages() {
        let expectation = self.expectation(description: "wait for all downloading finish")
        
        let group = DispatchGroup()
        
        for URLString in testKeys {
            if let url = URL(string: URLString) {
                group.enter()
                _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
                downloader.downloadImage(with: url, options: nil, progressBlock: { (receivedSize, totalSize) -> Void in
                    
                }, completionHandler: { (image, error, imageURL, data) -> Void in
                    XCTAssert(image != nil, "Download should be able to finished for URL: \(String(describing: imageURL)).")
                    group.leave()
                })
            }
        }
        
        group.notify(queue: .main, execute: expectation.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadAnImageWithMultipleCallback() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let group = DispatchGroup()
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        for _ in 0...5 {
            group.enter()
            downloader.downloadImage(with: URL(string: URLString)!, options: nil, progressBlock: { (receivedSize, totalSize) -> Void in
                
                }) { (image, error, imageURL, data) -> Void in
                    XCTAssert(image != nil, "Download should be able to finished for URL: \(String(describing: imageURL)).")
                    group.leave()
                    
            }
        }

        group.notify(queue: .main, execute: expectation.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadWithModifyingRequest() {
        let expectation = self.expectation(description: "wait for downloading image")

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        modifier.url = URL(string: URLString)
        
        let someURL = URL(string: "some_strange_url")!
        downloader.downloadImage(with: someURL, options: [.requestModifier(modifier)], progressBlock: { (receivedSize, totalSize) -> Void in
            
        }) { (image, error, imageURL, data) -> Void in
            XCTAssert(image != nil, "Download should be able to finished for URL: \(String(describing: imageURL)).")
            XCTAssertEqual(imageURL!, URL(string: URLString)!, "The returned imageURL should be the replaced one")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testServerNotModifiedResponse() {
        let expectation = self.expectation(description: "wait for server response 304")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(304)
        
        downloader.downloadImage(with: URL(string: URLString)!, options: nil, progressBlock: { (receivedSize, totalSize) -> Void in
            
        }) { (image, error, imageURL, data) -> Void in
            XCTAssertNotNil(error, "There should be an error since server returning 304 and no image downloaded.")
            XCTAssertEqual(error!.code, KingfisherError.notModified.rawValue, "The error should be NotModified.")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testServerInvalidStatusCode() {
        let expectation = self.expectation(description: "wait for response which has invalid status code")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(404)?.withBody(testImageData)
        
        downloader.downloadImage(with: URL(string: URLString)!, options: nil, progressBlock: { (receivedSize, totalSize) -> Void in
            
        }) { (image, error, imageURL, data) -> Void in
            XCTAssertNotNil(error, "There should be an error since server returning 404")
            XCTAssertEqual(error!.code, KingfisherError.invalidStatusCode.rawValue, "The error should be InvalidStatusCode.")
            XCTAssertEqual(error!.userInfo["statusCode"]! as? Int, 404, "The error should be InvalidStatusCode.")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Since we could not receive one challage, no test for trusted hosts currently.
    // See http://stackoverflow.com/questions/27065372/why-is-a-https-nsurlsession-connection-only-challenged-once-per-domain for more.
    func testSSLCertificateValidation() {
        LSNocilla.sharedInstance().stop()
        
        let downloader = ImageDownloader(name: "ssl.test")
        
        let url = URL(string: "https://testssl-expire.disig.sk/Expired.png")!
        
        let expectation = self.expectation(description: "wait for download from an invalid ssl site.")
        
        downloader.downloadImage(with: url, progressBlock: nil, completionHandler: { (image, error, imageURL, data) -> Void in
            XCTAssertNotNil(error, "Error should not be nil")
            XCTAssert(error?.code == NSURLErrorServerCertificateUntrusted || error?.code == NSURLErrorSecureConnectionFailed, "Error should be NSURLErrorServerCertificateUntrusted, but \(String(describing: error))")
            expectation.fulfill()
            LSNocilla.sharedInstance().start()
        })
        
        waitForExpectations(timeout: 20) { (error) in
            XCTAssertNil(error, "\(String(describing: error))")
            LSNocilla.sharedInstance().start()
        }
    }
 
    
    func testDownloadResultErrorAndRetry() {
        let expectation = self.expectation(description: "wait for downloading error")
        
        let URLString = testKeys[0]
        stubRequest("GET", URLString).andFailWithError(NSError(domain: "stubError", code: -1, userInfo: nil))
        let url = URL(string: URLString)!
        
        downloader.downloadImage(with: url, progressBlock: nil) { (image, error, imageURL, data) -> Void in
            XCTAssertNotNil(error, "Should return with an error")
            
            LSNocilla.sharedInstance().clearStubs()
            _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
            
            // Retry the download
            self.downloader.downloadImage(with: url, progressBlock: nil, completionHandler: { (image, error, imageURL, data) -> Void in
                XCTAssertNil(error, "Download should be finished without error")
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadEmptyURL() {
        let expectation = self.expectation(description: "wait for downloading error")
        
        modifier.url = nil
        
        let url = URL(string: "http://onevcat.com")
        downloader.downloadImage(with: url!, options: [.requestModifier(modifier)], progressBlock: { (receivedSize, totalSize) -> Void in
            XCTFail("The progress block should not be called.")
            }) { (image, error, imageURL, originalData) -> Void in
                XCTAssertNotNil(error, "An error should happen for empty URL")
                XCTAssertEqual(error!.code, KingfisherError.invalidURL.rawValue)
                self.downloader.delegate = nil
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadTaskProperty() {
        let task = downloader.downloadImage(with: URL(string: "1234")!, progressBlock: { (receivedSize, totalSize) -> Void in

            }) { (image, error, imageURL, originalData) -> Void in
        }
        
        XCTAssertNotNil(task, "The task should exist.")
        XCTAssertTrue(task!.ownerDownloader === downloader, "The owner downloader should be correct")
        XCTAssertEqual(task!.url, URL(string: "1234"), "The request URL should equal.")
    }
    
    func testCancelDownloadTask() {
        
        let expectation = self.expectation(description: "wait for downloading")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        var progressBlockIsCalled = false
        
        let downloadTask = downloader.downloadImage(with: url, progressBlock: { (receivedSize, totalSize) -> Void in
                progressBlockIsCalled = true
            }) { (image, error, imageURL, originalData) -> Void in
                XCTAssertNotNil(error)
                XCTAssertEqual(error!.code, NSURLErrorCancelled)
                XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
                
                expectation.fulfill()
        }
        
        XCTAssertNotNil(downloadTask)

        downloadTask!.cancel()
        _ = stub!.go()
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Issue 532 https://github.com/onevcat/Kingfisher/issues/532#issuecomment-305644311
    func testCancelThenRestartSameDownload() {
        let expectation = self.expectation(description: "wait for downloading")
        
        let URLString = testKeys[0]
        let stub = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)?.delay()
        let url = URL(string: URLString)!
        
        var progressBlockIsCalled = false
        
        let group = DispatchGroup()
        
        group.enter()
        let downloadTask = downloader.downloadImage(with: url, progressBlock: { (receivedSize, totalSize) -> Void in
            progressBlockIsCalled = true
        }) { (image, error, imageURL, originalData) -> Void in
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, NSURLErrorCancelled)
            XCTAssert(progressBlockIsCalled == false, "ProgressBlock should not be called since it is canceled.")
            group.leave()
        }
        
        XCTAssertNotNil(downloadTask)
        
        downloadTask!.cancel()
        _ = stub!.go()
        
        group.enter()
        downloader.downloadImage(with: url, progressBlock: { (receivedSize, totalSize) -> Void in
            progressBlockIsCalled = true
        }) { (image, error, imageURL, originalData) -> Void in
            XCTAssertNotNil(image)
            group.leave()
        }
        
        group.notify(queue: .main, execute: expectation.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadTaskNil() {
        modifier.url = nil
        let downloadTask = downloader.downloadImage(with: URL(string: "url")!, options: [.requestModifier(modifier)], progressBlock: nil, completionHandler: nil)
        XCTAssertNil(downloadTask)
        
        downloader.delegate = nil
    }
    
    func testDownloadWithProcessor() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        let roundcornered = testImage.kf.image(withRoundRadius: 40, fit: testImage.kf.size)
        
        downloader.downloadImage(with: url, options: [.processor(p)], progressBlock: { (receivedSize, totalSize) -> Void in
            
        }) { (image, error, imageURL, data) -> Void in
            expectation.fulfill()
            XCTAssert(image != nil, "Download should be able to finished for URL: \(String(describing: imageURL))")
            XCTAssertFalse(image!.renderEqual(to: testImage), "The processed image should not equal to the original one.")
            XCTAssertTrue(image!.renderEqual(to: roundcornered), "The processed image should equal to the one directly processed from original one.")
            XCTAssertEqual(NSData(data: data!), testImageData, "But the original data should equal each other.")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadWithDifferentProcessors() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        let p1 = RoundCornerImageProcessor(cornerRadius: 40)
        let roundcornered = testImage.kf.image(withRoundRadius: 40, fit: testImage.kf.size)

        let p2 = BlurImageProcessor(blurRadius: 3.0)
        let blurred = testImage.kf.blurred(withRadius: 3.0)
        
        var count = 0
        
        downloader.downloadImage(with: url, options: [.processor(p1)], progressBlock: { (receivedSize, totalSize) -> Void in

        }) { (image, error, imageURL, data) -> Void in
            XCTAssertTrue(image!.renderEqual(to: roundcornered), "The processed image should equal to the one directly processed from original one.")
            
            count += 1
            if count == 2 { expectation.fulfill() }
        }
        
        downloader.downloadImage(with: url, options: [.processor(p2)], progressBlock: { (receivedSize, totalSize) -> Void in
            
        }) { (image, error, imageURL, data) -> Void in
            XCTAssertTrue(image!.renderEqual(to: blurred), "The processed image should equal to the one directly processed from original one.")
            
            count += 1
            if count == 2 { expectation.fulfill() }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadedDataCouldBeModified() {
        let expectation = self.expectation(description: "wait for downloading image")
        
        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)
        
        let url = URL(string: URLString)!
        
        downloader.delegate = self
        downloader.downloadImage(with: url) { image, error, imageURL, data in
            XCTAssertNil(image)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, KingfisherError.badData.rawValue)
            self.downloader.delegate = nil
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS)
    func testDownloadedImageCouldBeModified() {
        let expectation = self.expectation(description: "wait for downloading image")

        let URLString = testKeys[0]
        _ = stubRequest("GET", URLString).andReturn(200)?.withBody(testImageData)

        let url = URL(string: URLString)!

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        downloader.downloadImage(with: url, options: [.imageModifier(modifier)]) {
            image, _, _, _ in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(image?.renderingMode, .alwaysTemplate)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
#endif
}

extension ImageDownloaderTests: ImageDownloaderDelegate {
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data? {
        return nil
    }
}

class URLModifier: ImageDownloadRequestModifier {
    var url: URL? = nil
    func modified(for request: URLRequest) -> URLRequest? {
        var r = request
        r.url = url
        return r
    }
}
