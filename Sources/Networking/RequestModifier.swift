//
//  RequestModifier.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/09/05.
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

/// Represents and wraps a method for modifying a request before an image download request starts asynchronously.
///
/// Usually, you pass an ``AsyncImageDownloadRequestModifier`` instance as the associated value of
/// ``KingfisherOptionsInfoItem/requestModifier`` and use it as the `options` parameter in related methods.
///
/// For example, the code below defines a modifier to add a header field and its value to the request.
///
/// ```swift
/// class HeaderFieldModifier: AsyncImageDownloadRequestModifier {
///   var onDownloadTaskStarted: ((DownloadTask?) -> Void)? = nil
///   func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void) {
///     var r = request
///     r.setValue("value", forHTTPHeaderField: "key")
///     reportModified(r)
///   }
/// }
///
/// imageView.kf.setImage(with: url, options: [.requestModifier(HeaderFieldModifier())])
/// ```
///
public protocol AsyncImageDownloadRequestModifier {

    /// This method will be called just before the `request` is sent.
    ///
    /// This is the last chance to modify the image download request. You can modify the request for some customizing
    /// purposes, such as adding an auth token to the header, performing basic HTTP auth, or something like URL mapping.
    /// 
    /// After making the modification, call the `reportModified` block with the modified request, and the data
    /// will be downloaded with this modified request.
    ///
    /// > If you do nothing with the input `request` and return it as-is, the download process will start with it as the
    /// modifier doesn't exist.
    ///
    /// - Parameters:
    ///     - request: The input request contains necessary information like `url`. This request is generated
    ///                according to your resource URL as a GET request.
    ///     - reportModified: The callback block you need to call after the asynchronous modification is done.
    func modified(for request: URLRequest) async -> URLRequest?

    /// A block that will be called when the download task starts.
    ///
    /// If an ``AsyncImageDownloadRequestModifier`` and asynchronous modification occur before the download, the
    /// related download method will not return a valid ``DownloadTask`` value. Instead, you can get one from this
    /// method.
    ///
    /// User the ``DownloadTask`` value to track the task, or cancel it when you need to.
    var onDownloadTaskStarted: ((DownloadTask?) -> Void)? { get }
}

/// Represents and wraps a method for modifying request before an image download request starts.
public protocol ImageDownloadRequestModifier: AsyncImageDownloadRequestModifier {

    /// This method will be called just before the `request` being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    ///
    /// Usually, you pass an `ImageDownloadRequestModifier` as the associated value of
    /// `KingfisherOptionsInfoItem.requestModifier` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will start with it.
    ///
    /// - Parameter request: The input request contains necessary information like `url`. This request is generated
    ///                      according to your resource url as a GET request.
    /// - Returns: A modified version of request, which you wish to use for downloading an image. If `nil` returned,
    ///            a `KingfisherError.requestError` with `.emptyRequest` as its reason will occur.
    ///
    func modified(for request: URLRequest) -> URLRequest?
}

extension ImageDownloadRequestModifier {
    public func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void) {
        let request = modified(for: request)
        reportModified(request)
    }

    /// This is `nil` for a sync `ImageDownloadRequestModifier` by default. You can get the `DownloadTask` from the
    /// return value of downloader method.
    public var onDownloadTaskStarted: ((DownloadTask?) -> Void)? { return nil }
}

/// A wrapper for creating an `ImageDownloadRequestModifier` easier.
/// This type conforms to `ImageDownloadRequestModifier` and wraps an image modify block.
public struct AnyModifier: ImageDownloadRequestModifier {
    
    let block: (URLRequest) -> URLRequest?

    /// For `ImageDownloadRequestModifier` conformation.
    public func modified(for request: URLRequest) -> URLRequest? {
        return block(request)
    }
    
    /// Creates a value of `ImageDownloadRequestModifier` which runs `modify` block.
    ///
    /// - Parameter modify: The request modifying block runs when a request modifying task comes.
    ///                     The return `URLRequest?` value of this block will be used as the image download request.
    ///                     If `nil` returned, a `KingfisherError.requestError` with `.emptyRequest` as its
    ///                     reason will occur.
    public init(modify: @escaping (URLRequest) -> URLRequest?) {
        block = modify
    }
}
