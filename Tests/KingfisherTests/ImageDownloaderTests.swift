//
//  ImageDownloaderTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }
    
    override func setUp() {
        super.setUp()
        downloader = ImageDownloader(name: "test")
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        downloader = nil
        super.tearDown()
    }
    
    func testDownloadAnImage() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData2)

        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadMultipleImages() {
        let exp = expectation(description: #function)
        let group = DispatchGroup()
        
        for url in testURLs {
            group.enter()
            stub(url, data: testImageData2)
            downloader.downloadImage(with: url) { result in
                XCTAssertNotNil(result.value)
                group.leave()
            }
        }
        
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadAnImageWithMultipleCallback() {
        let exp = expectation(description: #function)
        
        let group = DispatchGroup()
        let url = testURLs[0]
        stub(url, data: testImageData2)

        for _ in 0...5 {
            group.enter()
            downloader.downloadImage(with: url) { result in
                XCTAssertNotNil(result.value)
                group.leave()
            }
        }

        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadWithModifyingRequest() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData2)
        
        modifier.url = url
        
        let someURL = URL(string: "some_strange_url")!
        downloader.downloadImage(with: someURL, options: [.requestModifier(modifier)]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.url, url)
            exp.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testServerInvalidStatusCode() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData2, statusCode: 404)
        
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue((result.error as! KingfisherError2).isInvalidResponseStatusCode(404))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Since we could not receive one challage, no test for trusted hosts currently.
    // See http://stackoverflow.com/questions/27065372/ for more.
    func testSSLCertificateValidation() {
        LSNocilla.sharedInstance().stop()

        let exp = expectation(description: #function)

        let downloader = ImageDownloader(name: "ssl.test")
        let url = URL(string: "https://testssl-expire.disig.sk/Expired.png")!
        
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.error)
            if case KingfisherError2.responseError(reason: .URLSessionError(let error)) = result.error! {
                let nsError = error as NSError
                XCTAssert(nsError.code == NSURLErrorServerCertificateUntrusted ||
                          nsError.code == NSURLErrorSecureConnectionFailed,
                          "Error should be NSURLErrorServerCertificateUntrusted, but \(String(describing: error))")
            } else {
                XCTFail()
            }
            exp.fulfill()
            LSNocilla.sharedInstance().start()
        }
        
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error, "\(String(describing: error))")
            LSNocilla.sharedInstance().start()
        }
    }
 
    
    func testDownloadResultErrorAndRetry() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]

        stub(url, errorCode: -1)
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.error)
            
            LSNocilla.sharedInstance().clearStubs()

            stub(url, data: testImageData2)
            // Retry the download
            self.downloader.downloadImage(with: url) { result in
                XCTAssertNil(result.error)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadEmptyURL() {
        let exp = expectation(description: #function)
        
        modifier.url = nil
        
        let url = URL(string: "http://onevcat.com")!
        downloader.downloadImage(
            with: url,
            options: [.requestModifier(modifier)],
            progressBlock: { received, totalSize in XCTFail("The progress block should not be called.") })
        {
            result in
            XCTAssertNotNil(result.error)
            if case KingfisherError2.requestError(reason: .invalidURL(let request)) = result.error! {
                XCTAssertNil(request.url)
            } else {
                XCTFail()
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadTaskProperty() {
        let task = downloader.downloadImage(with: URL(string: "1234")!)
        XCTAssertNotNil(task, "The task should exist.")
    }
    
    func testCancelDownloadTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData2, length: 123)
        
        let task = downloader.downloadImage(
            with: url,
            progressBlock: { _, _ in XCTFail() })
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue((result.error as! KingfisherError2).isTaskCancelled)
            
            exp.fulfill()
        }
        
        XCTAssertNotNil(task)
        task!.cancel()

        _ = stub.go()
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCancelOneDownloadTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData2)

        let group = DispatchGroup()

        group.enter()
        let task1 = downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.error)
            group.leave()
        }

        group.enter()
        _ = downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.value?.image)
            group.leave()
        }

        task1?.cancel()
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancelAllDownloadTasks() {
        let exp = expectation(description: #function)

        let url1 = testURLs[0]
        let stub1 = delayedStub(url1, data: testImageData2)

        let url2 = testURLs[1]
        let stub2 = delayedStub(url2, data: testImageData2)

        let group = DispatchGroup()

        let urls = [url1, url1, url2]
        urls.forEach {
            group.enter()
            downloader.downloadImage(with: $0) { result in
                XCTAssertNotNil(result.error)
                XCTAssertTrue((result.error as! KingfisherError2).isTaskCancelled)
                group.leave()
            }
        }

        delay(0.1) {
            self.downloader.cancelAll()
            _ = stub1.go()
            _ = stub2.go()
        }
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    // Issue 532 https://github.com/onevcat/Kingfisher/issues/532#issuecomment-305644311
    func testCancelThenRestartSameDownload() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData2, length: 123)

        let group = DispatchGroup()
        
        group.enter()
        let downloadTask = downloader.downloadImage(
            with: url,
            progressBlock: { _, _ in XCTFail()})
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue((result.error as! KingfisherError2).isTaskCancelled)
            group.leave()
        }
        
        XCTAssertNotNil(downloadTask)
        
        downloadTask!.cancel()
        _ = stub.go()
        
        group.enter()
        downloader.downloadImage(with: url) {
            result in
            XCTAssertNotNil(result.value)
            group.leave()
        }
        
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadTaskNil() {
        modifier.url = nil
        let downloadTask = downloader.downloadImage(with: URL(string: "url")!, options: [.requestModifier(modifier)])
        XCTAssertNil(downloadTask)
    }
    
    func testDownloadWithProcessor() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData2)

        let p = RoundCornerImageProcessor(cornerRadius: 40)
        let roundcornered = testImage.kf.image(withRoundRadius: 40, fit: testImage.kf.size)
        
        downloader.downloadImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value)
            let image = result.value!.image
            XCTAssertFalse(image.renderEqual(to: testImage))
            XCTAssertTrue(image.renderEqual(to: roundcornered))
            XCTAssertEqual(result.value!.originalData, testImageData2)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadWithDifferentProcessors() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        stub(url, data: testImageData2)

        let p1 = RoundCornerImageProcessor(cornerRadius: 40)
        let roundcornered = testImage.kf.image(withRoundRadius: 40, fit: testImage.kf.size)

        let p2 = BlurImageProcessor(blurRadius: 3.0)
        let blurred = testImage.kf.blurred(withRadius: 3.0)
        
        let group = DispatchGroup()

        group.enter()
        let task1 = downloader.downloadImage(with: url, options: [.processor(p1)]) { result in
            XCTAssertTrue(result.value!.image.renderEqual(to: roundcornered))
            group.leave()
        }

        group.enter()
        let task2 = downloader.downloadImage(with: url, options: [.processor(p2)]) { result in
            XCTAssertTrue(result.value!.image.renderEqual(to: blurred))
            group.leave()
        }

        XCTAssertNotNil(task1)
        XCTAssertEqual(task1?.sessionTask.task, task2?.sessionTask.task)

        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDownloadedDataCouldBeModified() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData2)

        downloader.delegate = self
        downloader.downloadImage(with: url) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            if case KingfisherError2.responseError(reason: .dataModifyingFailed) = result.error! {
            } else {
                XCTFail()
            }
            self.downloader.delegate = nil
            exp.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

#if os(iOS) || os(tvOS) || os(watchOS)
    func testDownloadedImageCouldBeModified() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData2)

        var modifierCalled = false
        let modifier = AnyImageModifier { image in
            modifierCalled = true
            return image.withRenderingMode(.alwaysTemplate)
        }

        downloader.downloadImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertTrue(modifierCalled)
            XCTAssertEqual(result.value?.image.renderingMode, .alwaysTemplate)
            exp.fulfill()
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
