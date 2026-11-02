//
//  ProgressiveJPEGDemoTests.swift
//  Kingfisher
//
//  Created by onevcat on 2026/11/02.
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
import UIKit
@testable import Kingfisher

@MainActor
private final class ProgressiveDemoImageView: UIImageView {
    var didSetImage: (() -> Void)?

    override var image: UIImage? {
        didSet {
            if image != nil { didSetImage?() }
        }
    }
}

class ProgressiveJPEGDemoTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    @MainActor func testBlurToggleDownloadsAgainAfterCompletedLoad() throws {
        try checkReload(actions: ["Disable Blur"])
    }

    @MainActor func testFastestScanToggleDownloadsAgainAfterCompletedLoad() throws {
        try checkReload(actions: ["Disable Fastest Scan"])
    }

    @MainActor private func checkReload(actions: [String]) throws {
        let manager = KingfisherManager.shared
        let originalCache = manager.cache
        let originalDownloader = manager.downloader
        let originalOptions = manager.defaultOptions
        let cache = ImageCache(name: UUID().uuidString)
        let downloader = ImageDownloader(name: UUID().uuidString)
        manager.cache = cache
        manager.downloader = downloader
        // Make completion an explicit barrier for both memory and disk writes.
        manager.defaultOptions = [.waitForCache]
        defer {
            clearStubs(afterCancelling: downloader)
            clearCaches([cache])
            manager.cache = originalCache
            manager.downloader = originalDownloader
            manager.defaultOptions = originalOptions
        }

        let data = try XCTUnwrap(testImage.jpegData(compressionQuality: 0.9))
        stub(ImageLoader.progressiveImageURL, data: data, length: data.count)
        let controller = ProgressiveJPEGViewController()
        let imageView = ProgressiveDemoImageView()
        let label = UILabel()
        // Retain the outlets without loading the storyboard or starting an extra request.
        controller.imageView = imageView
        controller.progressLabel = label
        let initialLoad = expectation(description: "Initial download completes")
        imageView.didSetImage = { initialLoad.fulfill() }
        controller.loadViewIfNeeded()
        wait(for: [initialLoad], timeout: 5)
        XCTAssertEqual(label.text, "\(data.count) / \(data.count)")

        for title in actions {
            let alert = controller.alertPopup(self)
            let action = try XCTUnwrap(alert.actions.first { $0.title == title })
            // UIKit has no public API for invoking an alert action without presenting UI.
            // Access only the test action's handler so the real toggle/removal/reload path runs.
            let block = try XCTUnwrap(action.value(forKey: "handler")) as AnyObject
            let handler = unsafeBitCast(block, to: (@convention(block) (UIAlertAction) -> Void).self)
            let reloaded = expectation(description: "Reload after \(title)")
            imageView.didSetImage = { reloaded.fulfill() }
            withExtendedLifetime(alert) { handler(action) }
            wait(for: [reloaded], timeout: 5)
            XCTAssertEqual(label.text, "\(data.count) / \(data.count)", "\(title) must download again")
        }
        imageView.didSetImage = nil
    }
}
