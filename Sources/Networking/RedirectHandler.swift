//
//  RedirectHandler.swift
//  Kingfisher
//
//  Created by Roman Maidanovych on 2018/12/10.
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

import Foundation

/// Represents and wraps a method for modifying request during an image download request redirection.
public protocol ImageDownloadRedirectHandler {
    
    /// The `ImageDownloadRedirectHandler` contained will be used to change the request before redirection.
    /// This is the posibility you can modify the image download request during redirection. You can modify the request for
    /// some customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url
    /// mapping.
    ///
    /// Usually, you pass an `ImageDownloadRedirectHandler` as the associated value of
    /// `KingfisherOptionsInfoItem.redirectHandler` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will redirect with it.
    ///
    /// - Parameter request: The input request contains necessary information like `url`. This request is generated
    ///                      according to your resource url as a GET request.
    /// - Returns: A modified version of request, which you wish to use for downloading an image. If `nil` returned,
    ///            a `KingfisherError.requestError` with `.emptyRequest` as its reason will occur.
    ///
    func handled(for request: URLRequest) -> URLRequest?
}

struct NoHandler: ImageDownloadRedirectHandler {
    static let `default` = NoHandler()
    private init() {}
    func handled(for request: URLRequest) -> URLRequest? {
        return request
    }
}

/// A wrapper for creating an `ImageDownloadRedirectHandler` easier.
/// This type conforms to `ImageDownloadRedirectHandler` and wraps an image modify block.
public struct AnyHandler: ImageDownloadRedirectHandler {
    
    let block: (URLRequest) -> URLRequest?
    
    /// For `ImageDownloadRedirectHandler` conformation.
    public func handled(for request: URLRequest) -> URLRequest? {
        return block(request)
    }
    
    /// Creates a value of `ImageDownloadRedirectHandler` which runs `modify` block.
    ///
    /// - Parameter modify: The request modifying block runs when a request modifying task comes.
    ///                     The return `URLRequest?` value of this block will be used as the image download
    ///                     request redirected.
    ///                     If `nil` returned, a `KingfisherError.requestError` with `.emptyRequest` as its
    ///                     reason will occur.
    public init(handle: @escaping (URLRequest) -> URLRequest?) {
        block = handle
    }
}
