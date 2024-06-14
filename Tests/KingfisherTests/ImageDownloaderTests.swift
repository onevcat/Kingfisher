//
//  ImageDownloaderTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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
        stub(url, data: testImageData)

        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.value)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadAnImageAsync() async throws {
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let result = try await downloader.downloadImage(with: url, options: .empty)
        XCTAssertEqual(result.originalData, testImageData)
    }
    
    func testDownloadMultipleImages() {
        let exp = expectation(description: #function)
        let group = DispatchGroup()
        
        for url in testURLs {
            group.enter()
            stub(url, data: testImageData)
            downloader.downloadImage(with: url) { result in
                XCTAssertNotNil(result.value)
                group.leave()
            }
        }
        
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadMultipleImagesAsync() async throws {
        try await withThrowingTaskGroup(of: ImageLoadingResult.self) { group in
            for url in testURLs {
                stub(url, data: testImageData)
                group.addTask {
                    try await self.downloader.downloadImage(with: url)
                }
            }
            
            for try await result in group {
                XCTAssertEqual(result.originalData, testImageData)
            }
        }
    }
    
    func testDownloadAnImageWithMultipleCallback() {
        let exp = expectation(description: #function)
        
        let group = DispatchGroup()
        let url = testURLs[0]
        stub(url, data: testImageData)

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
        stub(url, data: testImageData)
        
        let modifier = URLModifier(url: url)
        
        let someURL = URL(string: "some_strange_url")!
        let task = downloader.downloadImage(with: someURL, options: [.requestModifier(modifier)]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.url, url)
            exp.fulfill()
        }
        XCTAssertTrue(task.isInitialized)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloadWithAsyncModifyingRequest() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData)

        let downloadTaskCalled = ActorBox(false)

        let asyncModifier = AsyncURLModifier(url: url, onDownloadTaskStarted: { task in
            XCTAssertNotNil(task)
            Task {
                await downloadTaskCalled.setValue(true)
            }
        })

        let someURL = URL(string: "some_strange_url")!
        let task = downloader.downloadImage(with: someURL, options: [.requestModifier(asyncModifier)]) { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.url, url)
            Task {
                let result = await downloadTaskCalled.value
                XCTAssertTrue(result)
                exp.fulfill()
            }
        }
        // The returned task is nil since the download is not starting immediately.
        XCTAssertFalse(task.isInitialized)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloadWithModifyingRequestToNil() {
        let nilModifier = AnyModifier { _ in
            return nil
        }

        let exp = expectation(description: #function)
        let someURL = URL(string: "some_strange_url")!
        downloader.downloadImage(with: someURL, options: [.requestModifier(nilModifier)]) { result in
            XCTAssertNotNil(result.error)
            guard case .requestError(reason: .emptyRequest) = result.error! else {
                XCTFail()
                fatalError()
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testServerInvalidStatusCode() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData, statusCode: 404)
        
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isInvalidResponseStatusCode(404))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadResultErrorAndRetry() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]

        stub(url, errorCode: -1)
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.error)
            
            LSNocilla.sharedInstance().clearStubs()

            stub(url, data: testImageData)
            // Retry the download
            self.downloader.downloadImage(with: url) { result in
                XCTAssertNil(result.error)
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadEmptyURL() {
        let exp = expectation(description: #function)
        
        let modifier = URLModifier(url: nil)
        
        let url = URL(string: "http://onevcat.com")!
        downloader.downloadImage(
            with: url,
            options: [.requestModifier(modifier)],
            progressBlock: { received, totalSize in XCTFail("The progress block should not be called.") })
        {
            result in
            XCTAssertNotNil(result.error)
            if case .requestError(reason: .invalidURL(let request)) = result.error! {
                XCTAssertNil(request.url)
            } else {
                XCTFail()
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadTaskProperty() {
        let task = downloader.downloadImage(with: URL(string: "1234")!)
        XCTAssertNotNil(task, "The task should exist.")
    }
    
    func testCancelDownloadTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)
        
        let task = downloader.downloadImage(
            with: url,
            progressBlock: { _, _ in XCTFail() })
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            delay(0.1) { exp.fulfill() }
        }
        
        XCTAssertTrue(task.isInitialized)
        task.cancel()

        _ = stub.go()
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCancelDownloadTaskAsync() async throws {
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)
        
        let checker = CallingChecker()
        try await checker.checkCancelBehavior(stub: stub) {
            _ = try await self.downloader.downloadImage(with: url)
        }
    }

    func testCancelOneDownloadTask() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

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

        task1.cancel()
        delay(0.1) { _ = stub.go() }
        group.notify(queue: .main) {
            delay(0.1) { exp.fulfill() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCancelAllDownloadTasks() {
        let exp = expectation(description: #function)

        let url1 = testURLs[0]
        let stub1 = delayedStub(url1, data: testImageData)

        let url2 = testURLs[1]
        let stub2 = delayedStub(url2, data: testImageData)

        let group = DispatchGroup()

        let urls = [url1, url1, url2]
        urls.forEach {
            group.enter()
            downloader.downloadImage(with: $0) { result in
                XCTAssertNotNil(result.error)
                XCTAssertTrue(result.error!.isTaskCancelled)
                group.leave()
            }
        }

        delay(0.1) {
            self.downloader.cancelAll()
            _ = stub1.go()
            _ = stub2.go()
        }
        group.notify(queue: .main) {
            delay(0.1) { exp.fulfill() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCancelDownloadTaskForURL() {
        let exp = expectation(description: #function)
        
        let url1 = testURLs[0]
        let stub1 = delayedStub(url1, data: testImageData)
        
        let url2 = testURLs[1]
        let stub2 = delayedStub(url2, data: testImageData)
        
        let group = DispatchGroup()
        
        group.enter()
        downloader.downloadImage(with: url1) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            group.leave()
        }
        
        group.enter()
        downloader.downloadImage(with: url1) { result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            group.leave()
        }
        
        group.enter()
        downloader.downloadImage(with: url2) { result in
            XCTAssertNotNil(result.value)
            group.leave()
        }
        
        delay(0.1) {
            self.downloader.cancel(url: url1)
            _ = stub1.go()
            _ = stub2.go()
        }
        
        group.notify(queue: .main) {
            delay(0.1) { exp.fulfill() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // Issue 532 https://github.com/onevcat/Kingfisher/issues/532#issuecomment-305644311
    func testCancelThenRestartSameDownload() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData, length: 123)

        let group = DispatchGroup()
        
        group.enter()
        let downloadTask = downloader.downloadImage(
            with: url,
            progressBlock: { _, _ in XCTFail()})
        {
            result in
            XCTAssertNotNil(result.error)
            XCTAssertTrue(result.error!.isTaskCancelled)
            group.leave()
        }
        
        XCTAssertTrue(downloadTask.isInitialized)
        downloadTask.cancel()
        _ = stub.go()
        
        group.enter()
        downloader.downloadImage(with: url) {
            result in
            XCTAssertNotNil(result.value)
            if let error = result.error {
                print(error)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            delay(0.1) { exp.fulfill() }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadTaskNilWithNilURL() {
        let modifier = URLModifier(url: nil)
        let downloadTask = downloader.downloadImage(with: URL(string: "url")!, options: [.requestModifier(modifier)])
        XCTAssertFalse(downloadTask.isInitialized)
    }
    
    func testDownloadWithProcessor() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData)

        let p = RoundCornerImageProcessor(cornerRadius: 40)
        let roundCornered = testImage.kf.image(withRoundRadius: 40, fit: testImage.kf.size)
        
        downloader.downloadImage(with: url, options: [.processor(p)]) { result in
            XCTAssertNotNil(result.value)
            let image = result.value!.image
            XCTAssertFalse(image.renderEqual(to: testImage))
            XCTAssertTrue(image.renderEqual(to: roundCornered))
            XCTAssertEqual(result.value!.originalData, testImageData)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadWithDifferentProcessors() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let stub = delayedStub(url, data: testImageData)

        let p1 = RoundCornerImageProcessor(cornerRadius: 40)
        let roundCornered = testImage.kf.image(withRoundRadius: 40, fit: testImage.kf.size)

        let p2 = BlurImageProcessor(blurRadius: 3.0)
        let blurred = testImage.kf.blurred(withRadius: 3.0)
        
        let group = DispatchGroup()

        group.enter()
        let task1 = downloader.downloadImage(with: url, options: [.processor(p1)]) { result in
            XCTAssertTrue(result.value!.image.renderEqual(to: roundCornered))
            group.leave()
        }

        group.enter()
        let task2 = downloader.downloadImage(with: url, options: [.processor(p2)]) { result in
            XCTAssertTrue(result.value!.image.renderEqual(to: blurred))
            group.leave()
        }

        XCTAssertNotNil(task1)
        XCTAssertEqual(task1.sessionTask?.task, task2.sessionTask?.task)

        _ = stub.go()
        
        group.notify(queue: .main, execute: exp.fulfill)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testDownloadedDataCouldBeModified() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let modifier = URLNilDataModifier()

        downloader.delegate = modifier
        downloader.downloadImage(with: url) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            if case .responseError(reason: .dataModifyingFailed) = result.error! {
            } else {
                XCTFail()
            }
            self.downloader.delegate = nil
            // hold delegate
            _ = modifier
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloadedDataCouldBeModifiedWithTask() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData)
        
        let modifier = TaskNilDataModifier()

        downloader.delegate = modifier
        downloader.downloadImage(with: url) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)
            if case .responseError(reason: .dataModifyingFailed) = result.error! {
            } else {
                XCTFail()
            }
            self.downloader.delegate = nil
            // hold delegate
            _ = modifier
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    func testModifierShouldOnlyApplyForFinalResultWhenDownload() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData)

        let modifierCalled = ActorBox(false)
        let modifier = AnyImageModifier { image in
            Task {
                await modifierCalled.setValue(true)
            }
            return image.withRenderingMode(.alwaysTemplate)
        }

        downloader.downloadImage(with: url, options: [.imageModifier(modifier)]) { result in
            XCTAssertEqual(result.value?.image.renderingMode, .automatic)
            Task {
                let called = await modifierCalled.value
                XCTAssertFalse(called)
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
#endif
    
    func testDownloadTaskTakePriorityOption() {
        let exp = expectation(description: #function)
        
        let url = testURLs[0]
        stub(url, data: testImageData)
        let task = downloader.downloadImage(with: url, options: [.downloadPriority(URLSessionTask.highPriority)])
        {
            _ in
            exp.fulfill()
        }
        XCTAssertEqual(task.sessionTask?.task.priority, URLSessionTask.highPriority)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    
    func testSessionDelegate() {
        class ExtensionDelegate: SessionDelegate, @unchecked Sendable {
            //'exp' only for test
            public let exp: XCTestExpectation
            init(_ expectation:XCTestExpectation) {
                exp = expectation
            }
            func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
                exp.fulfill()
            }
        }
        downloader.sessionDelegate = ExtensionDelegate(expectation(description: #function))
        
        let url = testURLs[0]
        stub(url, data: testImageData)
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.value)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloaderReceiveResponsePass() {

        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData, headers: ["someKey": "someValue"])

        let handler = TaskResponseCompletion()
        let obj = NSObject()
        handler.onReceiveResponse.delegate(on: obj) { (obj, response) in
            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("Should be an HTTP response.")
                return .cancel
            }
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertEqual(httpResponse.url, url)
            XCTAssertEqual(httpResponse.allHeaderFields["someKey"] as? String, "someValue")

            return .allow
        }

        downloader.delegate = handler
        downloader.downloadImage(with: url) { result in
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.error)

            self.downloader.delegate = nil
            // hold delegate
            _ = handler
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDownloaderReceiveResponseFailure() {
        let exp = expectation(description: #function)

        let url = testURLs[0]
        stub(url, data: testImageData, headers: ["someKey": "someValue"])

        let handler = TaskResponseCompletion()
        let obj = NSObject()
        handler.onReceiveResponse.delegate(on: obj) { (obj, response) in
            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("Should be an HTTP response.")
                return .cancel
            }
            XCTAssertEqual(httpResponse.statusCode, 200)
            XCTAssertEqual(httpResponse.url, url)
            XCTAssertEqual(httpResponse.allHeaderFields["someKey"] as? String, "someValue")

            return .cancel
        }

        downloader.delegate = handler
        downloader.downloadImage(with: url) { result in
            XCTAssertNil(result.value)
            XCTAssertNotNil(result.error)

            if case .responseError(reason: .cancelledByDelegate) = result.error! {
            } else {
                XCTFail()
            }

            self.downloader.delegate = nil
            // hold delegate
            _ = handler
            exp.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}

class URLNilDataModifier: ImageDownloaderDelegate {
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data? {
        return nil
    }
}

class TaskNilDataModifier: ImageDownloaderDelegate {
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, with dataTask: SessionDataTask) -> Data? {
        return nil
    }
}

class TaskResponseCompletion: ImageDownloaderDelegate {

    let onReceiveResponse = Delegate<URLResponse, URLSession.ResponseDisposition>()
    func imageDownloader(_ downloader: ImageDownloader, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
        return onReceiveResponse.call(response)!
    }
}

final class URLModifier: ImageDownloadRequestModifier {
    let url: URL?
    init(url: URL?) {
        self.url = url
    }
    func modified(for request: URLRequest) -> URLRequest? {
        var r = request
        r.url = url
        return r
    }
}

final class AsyncURLModifier: AsyncImageDownloadRequestModifier {
    let url: URL?
    let onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)?
    
    init(url: URL?, onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)?) {
        self.url = url
        self.onDownloadTaskStarted = onDownloadTaskStarted
    }

    func modified(for request: URLRequest) async -> URLRequest? {
        var r = request
        r.url = url
        // Simulate an async action
        try? await Task.sleep(nanoseconds: 1_000_000)
        return r
    }
}
