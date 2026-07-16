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

@available(iOS 14.0, tvOS 14.0, *)
class ImageBinderTests: XCTestCase {
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
}

#endif
