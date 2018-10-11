//
//  ImageDownloaderDelegate.swift
//  Kingfisher
//
//  Created by jp20028 on 2018/10/11.
//
//  Copyright (c) 2018年 Wei Wang <onevcat@gmail.com>
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

/// Protocol of `ImageDownloader`.
public protocol ImageDownloaderDelegate: AnyObject {

    /// Called when the `ImageDownloader` object will start downloading an image from specified URL.
    ///
    /// - Parameters:
    ///   - downloader: The `ImageDownloader` object which is used for the downloading operation.
    ///   - url: URL of the original request URL.
    ///   - request: The request object for the download process.
    ///
    func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?)

    /// Called when the `ImageDownloader` completes a downloading request with success or failure.
    ///
    /// - Parameters:
    ///   - downloader: The `ImageDownloader` object which is used for the downloading operation.
    ///   - url: URL of the original request URL.
    ///   - response: The response object of the downloading process.
    ///   - error: The error in case of failure.
    ///
    func imageDownloader(
        _ downloader: ImageDownloader,
        didFinishDownloadingImageForURL url: URL,
        with response: URLResponse?, error: Error?)

    /// Called when the `ImageDownloader` object successfully downloaded and processed an image from specified URL.
    ///
    /// - Parameters:
    ///   - downloader: The `ImageDownloader` object which is used for the downloading operation.
    ///   - image: The downloaded and processed image.
    ///   - url: URL of the original request URL.
    ///   - response: The original response object of the downloading process.
    ///
    func imageDownloader(
        _ downloader: ImageDownloader,
        didDownload image: Image,
        for url: URL,
        with response: URLResponse?)

    /// Checks if a received HTTP status code is valid or not.
    /// By default, a status code between 200 to 400 (excluded) is considered as valid.
    /// If an invalid code is received, the downloader will raise an .invalidStatusCode error.
    ///
    /// - Parameters:
    ///   - code: The received HTTP status code.
    ///   - downloader: The `ImageDownloader` object asks for validate status code.
    /// - Returns: Returns a value to indicate whether this HTTP status code is valid or not.
    /// - Note: If the default 200 to 400 valid code does not suit your need,
    ///         you can implement this method to change that behavior.
    func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool

    /// Called when the `ImageDownloader` object successfully downloaded image data from specified URL. This is
    /// your last chance to modify the downloaded data before Kingfisher tries to perform addition processing on
    /// the image data.
    ///
    /// - Parameters:
    ///   - downloader: The `ImageDownloader` object which is used for the downloading operation.
    ///   - data: Original downloaded data.
    ///   - url: URL of the original request URL.
    /// - Returns: The data from which Kingfisher would use to create an image.
    /// - Note: This callback can be used to preprocess raw image data before creation of
    ///         Image instance (i.e. decrypting or verification).
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data?
}

extension ImageDownloaderDelegate {
    public func imageDownloader(
        _ downloader: ImageDownloader,
        willDownloadImageForURL url: URL,
        with request: URLRequest?) {}

    public func imageDownloader(
        _ downloader: ImageDownloader,
        didFinishDownloadingImageForURL url: URL,
        with response: URLResponse?,
        error: Error?) {}

    public func imageDownloader(
        _ downloader: ImageDownloader,
        didDownload image: Image,
        for url: URL,
        with response: URLResponse?) {}

    public func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool {
        return (200..<400).contains(code)
    }
    public func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data? {
        return data
    }
}
