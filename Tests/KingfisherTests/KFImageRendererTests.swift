//
//  KFImageRendererTests.swift
//  Kingfisher
//
//  Created by kjy on 7/9/26.
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
class KFImageRendererTests: XCTestCase {
    @MainActor
    func testPlaceholderDefinesLayoutWhenLoadedImageIsNil() async {
        let maxHeight: CGFloat = 200

        let view = KFImage.dataProvider(nil)
            .resizable()
            .placeholder {
                Color.gray
                    .frame(maxHeight: maxHeight)
            }
            .aspectRatio(contentMode: .fit)

        let measuredSize = await measureLayout(view)

        XCTAssertLessThanOrEqual(
            measuredSize.height,
            maxHeight + 0.5,
            "The placeholder should define the KFImage layout while loadedImage is nil. Before the fix, the empty image branch still participated in layout and made KFImage taller than the placeholder."
        )
        XCTAssertGreaterThan(measuredSize.height, 0)
    }

    @MainActor
    func testFailureViewDefinesLayoutWhenLoadedImageIsNil() async {
        let maxHeight: CGFloat = 200
        let failureExpectation = expectation(description: "Image loading fails")

        let view = KFImage.dataProvider(FailingImageDataProvider())
            .resizable()
            .onFailureView {
                Color.red
                    .frame(maxHeight: maxHeight)
            }
            .onFailure { _ in
                failureExpectation.fulfill()
            }
            .aspectRatio(contentMode: .fit)

        let measuredSize = await measureLayout(view, after: failureExpectation)

        XCTAssertLessThanOrEqual(
            measuredSize.height,
            maxHeight + 0.5,
            "The failure view should define the KFImage layout while loadedImage is nil. Before the fix, the empty image branch still participated in layout and made KFImage taller than the failure view."
        )
        XCTAssertGreaterThan(measuredSize.height, 0)
    }

    @MainActor
    private func measureLayout<V: View>(
        _ view: V,
        after expectation: XCTestExpectation? = nil
    ) async -> CGSize {
        let width: CGFloat = 390
        let height: CGFloat = 800

        var measuredSize = CGSize.zero

        let rootView = VStack(spacing: 0) {
            view
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                measuredSize = proxy.size
                            }
                            .onChange(of: proxy.size) { newSize in
                                measuredSize = newSize
                            }
                    }
                )

            Spacer()
        }
        .frame(width: width, height: height)

        let controller = UIHostingController(rootView: rootView)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        if let expectation {
            await fulfillment(of: [expectation], timeout: 1)
        }

        for _ in 0..<5 {
            await Task.yield()
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
        }

        window.isHidden = true
        return measuredSize
    }
}

private struct FailingImageDataProvider: ImageDataProvider {
    let cacheKey = "com.onevcat.KingfisherTests.FailingImageDataProvider"

    func data() async throws -> Data {
        throw Error()
    }

    struct Error: Swift.Error {}
}

#endif
