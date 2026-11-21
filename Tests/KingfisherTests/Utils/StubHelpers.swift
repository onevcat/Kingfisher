//
//  StubHelpers.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/12.
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

import Foundation
@testable import Kingfisher

/// Stubs `url` with a successful HTTP response.
///
/// - Parameters:
///   - length: The value of the `Content-Length` header, if it should differ from the body size.
///   - requiredHeaders: Header values a request must have to match this stub.
@discardableResult
func stub(_ url: URL,
          data: Data,
          statusCode: Int = 200,
          length: Int? = nil,
          headers: [String: String] = [:],
          requiredHeaders: [String: String]? = nil
) -> NetworkStub {
    makeStub(url, data: data, statusCode: statusCode, length: length, headers: headers,
             requiredHeaders: requiredHeaders, held: false)
}

/// Stubs `url` with a successful HTTP response that is held until `release()` is called on the returned stub.
func heldStub(_ url: URL,
              data: Data,
              statusCode: Int = 200,
              length: Int? = nil,
              headers: [String: String] = [:]
) -> NetworkStub {
    makeStub(url, data: data, statusCode: statusCode, length: length, headers: headers,
             requiredHeaders: nil, held: true)
}

func stub(_ url: URL, errorCode: Int) {
    let error = NSError(domain: "stubError", code: errorCode, userInfo: nil)
    stub(url, error: error)
}

@discardableResult
func stub(_ url: URL, error: any Error) -> NetworkStub {
    let stub = NetworkStub(url: url, response: .failure(error), requiredHeaders: nil, held: false)
    NetworkStubRegistry.add(stub)
    return stub
}

private func makeStub(
    _ url: URL,
    data: Data,
    statusCode: Int,
    length: Int?,
    headers: [String: String],
    requiredHeaders: [String: String]?,
    held: Bool
) -> NetworkStub {
    var headers = headers
    if let length {
        headers["Content-Length"] = "\(length)"
    }
    let stub = NetworkStub(
        url: url,
        response: .success(statusCode: statusCode, headers: headers, body: data),
        requiredHeaders: requiredHeaders,
        held: held
    )
    NetworkStubRegistry.add(stub)
    return stub
}

func clearStubs(afterCancelling downloader: ImageDownloader?) {
    downloader?.cancelAll()
    NetworkStubRegistry.reset()
}

func clearStubs(afterCancelling manager: KingfisherManager?) {
    clearStubs(afterCancelling: manager?.downloader)
}

extension ImageDownloader {
    /// Creates a downloader whose session sends all requests to `StubURLProtocol`.
    static func stubbed(name: String) -> ImageDownloader {
        let downloader = ImageDownloader(name: name)
        downloader.sessionConfiguration = .stubbed
        return downloader
    }
}

struct DownloadStartObserver: ImageDownloadRequestModifier {
    let onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)?

    func modified(for request: URLRequest) -> URLRequest? { request }
}
