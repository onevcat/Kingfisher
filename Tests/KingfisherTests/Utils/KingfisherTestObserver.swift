//
//  KingfisherTestObserver.swift
//  Kingfisher
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

import Foundation
import XCTest
@testable import Kingfisher

/// The principal class of the test bundle (`NSPrincipalClass` in its Info.plist).
///
/// XCTest creates it once, before any test runs. It makes sure no test reaches the real network:
///
/// - The default downloader, which `KingfisherManager.shared` uses, sends its requests to `StubURLProtocol`.
/// - `URLSession.shared` uses `StubURLProtocol` too, because it is registered globally.
///
/// A session with its own configuration does not use globally registered protocols. Tests that create their own
/// downloader use `ImageDownloader.stubbed(name:)`, and tests that create their own session use
/// `URLSessionConfiguration.stubbed`.
final class KingfisherTestObserver: NSObject, XCTestObservation {

    override init() {
        super.init()
        URLProtocol.registerClass(StubURLProtocol.self)
        ImageDownloader.default.sessionConfiguration = .stubbed
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        // Stubs of one test must never affect the next one.
        NetworkStubRegistry.reset()
    }
}
