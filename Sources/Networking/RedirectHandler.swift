//
//  RedirectHandler.swift
//  Kingfisher
//
//  Created by Roman Maidanovych on 2018/12/10.
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

/// The ``ImageDownloadRedirectHandler`` is used to modify the request before redirection.
///
/// This allows you to customize the image download request during redirection. You can make modifications for
/// purposes such as adding an authentication token to the header, performing basic HTTP authentication, or URL
/// mapping.
///
/// Typically, you pass an ``ImageDownloadRedirectHandler`` as the associated value of
/// ``KingfisherOptionsInfoItem/redirectHandler(_:)`` and use it as the `options` parameter in relevant methods.
///
/// If you do not make any changes to the input `request` and return it as is, the downloading process will redirect
/// using it.
///
public protocol ImageDownloadRedirectHandler: Sendable {

    /// Called when a redirect is received and the downloader waiting for the request to continue the download task.
    ///
    /// - Parameters:
    ///   - task: The current ``SessionDataTask`` that triggers this redirect.
    ///   - response: The response received during redirection.
    ///   - newRequest: The new request received from the URL session for redirection that can be modified.
    /// - Returns: The modified request.
    func handleHTTPRedirection(
        for task: SessionDataTask,
        response: HTTPURLResponse,
        newRequest: URLRequest
    ) async -> URLRequest?
}

/// A wrapper for creating an ``ImageDownloadRedirectHandler`` instance more easily.
///
/// This type conforms to ``ImageDownloadRedirectHandler`` and wraps an image modification block.
public struct AnyRedirectHandler: ImageDownloadRedirectHandler {
    
    let block: @Sendable (SessionDataTask, HTTPURLResponse, URLRequest, @escaping (URLRequest?) -> Void) -> Void
    
    public func handleHTTPRedirection(
        for task: SessionDataTask, response: HTTPURLResponse, newRequest: URLRequest
    ) async -> URLRequest? {
        return await withCheckedContinuation { continuation in
            block(task, response, newRequest, { urlRequest in
                continuation.resume(returning: urlRequest)
            })
        }
    }
    
    /// Creates a value of ``ImageDownloadRedirectHandler`` that executes the `modify` block.
    ///
    /// - Parameter handle: The block that modifies the request when a request modification task is triggered.
    public init(handle: @escaping @Sendable (SessionDataTask, HTTPURLResponse, URLRequest, @escaping (URLRequest?) -> Void) -> Void) {
        block = handle
    }
    
}
