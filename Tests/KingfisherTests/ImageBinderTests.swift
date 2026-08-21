//
//  ImageBinderTests.swift
//  Kingfisher
//
//  Created by kjy on 7/16/26.
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
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

#if canImport(SwiftUI) && canImport(UIKit) && (os(iOS) || os(tvOS))

import SwiftUI
import UIKit
import XCTest
@testable import Kingfisher

private enum DelayedImageDataProviderError: Error, Sendable {
    case expected
}

private final class DelayedImageDataProvider: ImageDataProvider, @unchecked Sendable {
    let cacheKey = "com.onevcat.KingfisherTests.ImageBinder.\(UUID().uuidString)"
    private let result: Result<Data, DelayedImageDataProviderError>
    private let onResultProvided: @Sendable () -> Void

    init(
        result: Result<Data, DelayedImageDataProviderError>,
        onResultProvided: @escaping @Sendable () -> Void
    ) {
        self.result = result
        self.onResultProvided = onResultProvided
    }

    func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        let result = result
        let onResultProvided = onResultProvided
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onResultProvided()
            switch result {
            case .success(let data):
                handler(.success(data))
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}

@available(iOS 14.0, tvOS 14.0, *)
class ImageBinderTests: XCTestCase {
    private func makeSharedDownloadTasks(priorities: [Float]) -> [DownloadTask] {
        let url = URL(string: "https://example.com/shared-priority.png")!
        let sessionTask = SessionDataTask(task: URLSession.shared.dataTask(with: url))
        return priorities.map { priority in
            let options = KingfisherParsedOptionsInfo([.downloadPriority(priority)])
            let callback = SessionDataTask.TaskCallback(onCompleted: nil, options: options)
            let token = sessionTask.addCallback(callback)!
            let actualTask = DownloadTask(sessionTask: sessionTask, cancelToken: token)
            let linkedTask = DownloadTask()
            linkedTask.linkToTask(actualTask)
            return linkedTask
        }
    }

    @MainActor
    func testFadeCallsSuccessAfterMarkingLoadedOnCustomCallbackQueue() async {
        let callbackQueue = DispatchQueue(
            label: "com.onevcat.KingfisherTests.ImageBinder.callback"
        )
        let provider = RawImageDataProvider(
            data: testImagePNGData,
            cacheKey: "com.onevcat.KingfisherTests.ImageBinder.\(UUID().uuidString)"
        )
        let context = KFImage.Context<Image>(source: .provider(provider))
        var options = context.options
        options.callbackQueue = .dispatch(callbackQueue)
        options.transition = .fade(0.2)
        context.options = options

        let binder = KFImage.ImageBinder()
        let success = expectation(description: "Success is called after loading")

        context.onSuccessDelegate.delegate(on: self) { _, _ in
            XCTAssertTrue(binder.loaded)
            XCTAssertNotNil(binder.loadedImage)
            success.fulfill()
        }

        binder.start(context: context)

        await fulfillment(of: [success], timeout: 1)
    }

    @MainActor
    func testLoadTransitionCallsSuccessAfterMarkingLoadedOnCustomCallbackQueue() async {
        let callbackQueue = DispatchQueue(
            label: "com.onevcat.KingfisherTests.ImageBinder.callback"
        )
        let provider = RawImageDataProvider(
            data: testImagePNGData,
            cacheKey: "com.onevcat.KingfisherTests.ImageBinder.\(UUID().uuidString)"
        )
        let context = KFImage.Context<Image>(source: .provider(provider))
        var options = context.options
        options.callbackQueue = .dispatch(callbackQueue)
        context.options = options
        context.swiftUITransition = .opacity

        let binder = KFImage.ImageBinder()
        let success = expectation(description: "Success is called after loading")

        context.onSuccessDelegate.delegate(on: self) { _, _ in
            XCTAssertTrue(binder.loaded)
            XCTAssertNotNil(binder.loadedImage)
            success.fulfill()
        }

        binder.start(context: context)

        await fulfillment(of: [success], timeout: 1)
    }

    @MainActor
    func testBinderNotRetainedByInFlightDataProvider() async {
        let dataProvided = expectation(description: "Data provider finishes")
        let provider = DelayedImageDataProvider(
            result: .success(testImagePNGData),
            onResultProvided: { dataProvided.fulfill() }
        )
        let context = KFImage.Context<Image>(source: .provider(provider))

        weak var weakBinder: KFImage.ImageBinder?
        autoreleasepool {
            let binder = KFImage.ImageBinder()
            weakBinder = binder
            binder.start(context: context)
        }

        XCTAssertNil(weakBinder, "A binder should be released while its image retrieval is still in flight.")

        await fulfillment(of: [dataProvided], timeout: 1)
    }

    @MainActor
    func testReleasedBinderForwardsSuccess() async {
        let resultReceived = expectation(description: "Success is forwarded")
        let provider = DelayedImageDataProvider(
            result: .success(testImagePNGData),
            onResultProvided: {}
        )
        let context = KFImage.Context<Image>(source: .provider(provider))
        context.onSuccessDelegate.delegate(on: self) { _, result in
            XCTAssertNotNil(result.image)
            resultReceived.fulfill()
        }

        weak var weakBinder: KFImage.ImageBinder?
        autoreleasepool {
            let binder = KFImage.ImageBinder()
            weakBinder = binder
            binder.start(context: context)
        }

        XCTAssertNil(weakBinder, "A binder should be released while its image retrieval is still in flight.")

        await fulfillment(of: [resultReceived], timeout: 1)
    }

    @MainActor
    func testReleasedBinderForwardsFailure() async {
        let resultReceived = expectation(description: "Failure is forwarded")
        let provider = DelayedImageDataProvider(
            result: .failure(.expected),
            onResultProvided: {}
        )
        let context = KFImage.Context<Image>(source: .provider(provider))
        context.onFailureDelegate.delegate(on: self) { _, _ in
            resultReceived.fulfill()
        }

        weak var weakBinder: KFImage.ImageBinder?
        autoreleasepool {
            let binder = KFImage.ImageBinder()
            weakBinder = binder
            binder.start(context: context)
        }

        XCTAssertNil(weakBinder, "A binder should be released while its image retrieval is still in flight.")

        await fulfillment(of: [resultReceived], timeout: 1)
    }

    @MainActor
    func testReducingPriorityDoesNotAffectHigherPriorityConsumer() {
        let tasks = makeSharedDownloadTasks(
            priorities: [URLSessionTask.highPriority, URLSessionTask.defaultPriority]
        )
        let visibleTask = tasks[0]
        let disappearingTask = tasks[1]
        let binder = KFImage.ImageBinder()
        binder.downloadTask = disappearingTask
        binder.markLoading()

        binder.reducePriorityOnDisappear()

        XCTAssertTrue(visibleTask.sessionTask === disappearingTask.sessionTask)
        XCTAssertEqual(visibleTask.sessionTask?.task.priority, URLSessionTask.highPriority)
    }

    @MainActor
    func testRestoringPriorityUsesOriginalRequestPriority() {
        let task = makeSharedDownloadTasks(priorities: [URLSessionTask.highPriority])[0]
        let binder = KFImage.ImageBinder()
        binder.downloadTask = task
        binder.markLoading()

        binder.reducePriorityOnDisappear()
        XCTAssertEqual(task.sessionTask?.task.priority, URLSessionTask.lowPriority)

        binder.restorePriorityOnAppear()
        XCTAssertEqual(task.sessionTask?.task.priority, URLSessionTask.highPriority)
    }
}

#endif
