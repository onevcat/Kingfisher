//
//  KingfisherError.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/26.
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

/// Error domain of Kingfisher
public let KingfisherErrorDomain = "com.onevcat.Kingfisher.Error"

struct KingfisherPlaceholderError: Error {
}


///The code of errors which `ImageDownloader` might encountered.
public enum KingfisherError: Int {

    /// badData: The downloaded data is not an image or the data is corrupted.
    case badData = 10000

    /// notModified: The remote server responded a 304 code. No image data downloaded.
    case notModified = 10001

    /// The HTTP status code in response is not valid. If an invalid
    /// code error received, you could check the value under `KingfisherErrorStatusCodeKey`
    /// in `userInfo` to see the code.
    case invalidStatusCode = 10002

    /// notCached: The image requested is not in cache but .onlyFromCache is activated.
    case notCached = 10003

    /// The URL is invalid.
    case invalidURL = 20000

    /// The downloading task is cancelled before started.
    case downloadCancelledBeforeStarting = 30000
}

/// Key will be used in the `userInfo` of `.invalidStatusCode`
public let KingfisherErrorStatusCodeKey = "statusCode"
