//
//  ImageDownloaderDelegate.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/11.
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
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Protocol for handling events for ``ImageDownloader``.
///
/// This delegate protocol provides a set of methods related to the stages and rules of the image downloader. You use
/// the provided methods to inspect the downloader working phases or respond to some events to make decisions.
public protocol ImageDownloaderDelegate: AnyObject {

    /// Called when the ``ImageDownloader`` object is about to start downloading an image from a specified URL.
    ///
    /// - Parameters:
    ///   - downloader: The ``ImageDownloader`` object used for the downloading operation.
    ///   - url: The URL of the starting request.
    ///   - request: The request object for the download process.
    func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?)

    /// Called when the ``ImageDownloader`` completes a downloading request with success or failure.
    ///
    /// - Parameters:
    ///   - downloader: The ``ImageDownloader`` object used for the downloading operation.
    ///   - url: The URL of the original request.
    ///   - response: The response object of the downloading process.
    ///   - error: The error in case of failure.
    func imageDownloader(
        _ downloader: ImageDownloader,
        didFinishDownloadingImageForURL url: URL,
        with response: URLResponse?,
        error: (any Error)?)
    
    /// Called when the ``ImageDownloader`` object successfully downloads image data with a specified task.
    ///
    /// This is your last chance to verify or modify the downloaded data before Kingfisher attempts to perform
    /// additional processing on the image data.
    ///
    /// - Parameters:
    ///   - downloader: The ``ImageDownloader`` object used for the downloading operation.
    ///   - data: The original downloaded data.
    ///   - task: The data task containing request and response information for the download.
    /// - Returns: The data that Kingfisher should use to create an image. You need to provide valid data that is in
    /// one of the supported image file formats. Kingfisher will process this data and attempt to convert it into an
    /// image object.
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, with task: SessionDataTask) -> Data?
  
    /// Called when the ``ImageDownloader`` object successfully downloads image data from a specified URL.
    ///
    /// This is your last chance to verify or modify the downloaded data before Kingfisher attempts to perform
    /// additional processing on the image data.
    ///
    /// - Parameters:
    ///   - downloader: The ``ImageDownloader`` object used for the downloading operation.
    ///   - data: The original downloaded data.
    ///   - url: The URL of the original request.
    ///
    /// - Returns: The data that Kingfisher should use to create an image. You need to provide valid data that is in
    /// one of the supported image file formats. Kingfisher will process this data and attempt to convert it into an
    /// image object.
    ///
    /// This method can be used to preprocess raw image data before the creation of the `Image` instance (e.g.,
    /// decrypting or verification). If `nil` is returned, the processing is interrupted and a
    /// ``KingfisherError/ResponseErrorReason/dataModifyingFailed(task:)`` error will be raised. You can use this fact
    /// to stop the image processing flow if you find that the data is corrupted or malformed.
    ///
    /// > If the ``SessionDataTask`` version of `imageDownloader(_:didDownload:with:)` is implemented, this method will
    /// > not be called anymore.
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data?

    /// Called when the ``ImageDownloader`` object successfully downloads and processes an image from a specified URL.
    ///
    /// - Parameters:
    ///   - downloader: The ``ImageDownloader`` object used for the downloading operation.
    ///   - image: The downloaded and processed image.
    ///   - url: The URL of the original request.
    ///   - response: The original response object of the downloading process.
    func imageDownloader(
        _ downloader: ImageDownloader,
        didDownload image: KFCrossPlatformImage,
        for url: URL,
        with response: URLResponse?)

    /// Checks if a received HTTP status code is valid or not.
    ///
    /// By default, a status code in the range `200..<400` is considered as valid. If an invalid code is received,
    /// the downloader will raise a ``KingfisherError/ResponseErrorReason/invalidHTTPStatusCode(response:)`` error.
    ///
    /// - Parameters:
    ///   - code: The received HTTP status code.
    ///   - downloader: The ``ImageDownloader`` object requesting validation of the status code.
    /// - Returns: A value indicating whether this HTTP status code is valid or not.
    ///
    /// > If the default range of `200..<400` as valid codes does not suit your needs, you can implement this method to
    /// change that behavior.
    func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool

    /// Called when the task has received a valid HTTP response after passing other checks such as the status code. 
    /// You can perform additional checks or verifications on the response to determine if the download should be
    /// allowed or cancelled.
    ///
    /// For example, this is useful if you want to verify some header values in the response before actually starting 
    /// the download.
    ///
    /// If implemented, you have to return a proper response disposition, such as `.allow` to start the actual
    /// downloading or `.cancel` to cancel the task. If `.cancel` is used as the disposition, the downloader will raise 
    /// a ``KingfisherError/ResponseErrorReason/cancelledByDelegate(response:)`` error. If not implemented, any response
    /// that passes other checks will be allowed, and the download will start.
    ///
    /// - Parameters:
    ///   - downloader: The `ImageDownloader` object used for the downloading operation.
    ///   - response: The original response object of the downloading process.
    ///
    /// - Returns: The disposition for the download task. You have to return either `.allow` or `.cancel`.
    func imageDownloader(
        _ downloader: ImageDownloader,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition
}

// Default implementation for `ImageDownloaderDelegate`.
extension ImageDownloaderDelegate {
    public func imageDownloader(
        _ downloader: ImageDownloader,
        willDownloadImageForURL url: URL,
        with request: URLRequest?) {}

    public func imageDownloader(
        _ downloader: ImageDownloader,
        didFinishDownloadingImageForURL url: URL,
        with response: URLResponse?,
        error: (any Error)?) {}

    public func imageDownloader(
        _ downloader: ImageDownloader,
        didDownload image: KFCrossPlatformImage,
        for url: URL,
        with response: URLResponse?) {}

    public func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool {
        return (200..<400).contains(code)
    }
  
    public func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, with task: SessionDataTask) -> Data? {
        guard let url = task.originalURL else {
            return data
        }
        return imageDownloader(downloader, didDownload: data, for: url)
    }
  
    public func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data? {
        return data
    }

    public func imageDownloader(
        _ downloader: ImageDownloader,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        .allow
    }
}
