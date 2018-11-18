//
//  ImageDataProvider.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/13.
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

/// Represents a data provider to provide image data to Kingfisher when setting with
/// `Source.provider` source. Compared to `Source.network` memeber, it gives a chance
/// to load some image data in your own way, as long as you can provide the data
/// representation for the image.
public protocol ImageDataProvider {
    
    /// The key used in cache.
    var cacheKey: String { get }
    
    /// The image identifier of this provider instance. For different image loading, you
    /// should provide a different `identifier` value. For example, when you want to load
    /// an image from a certain URL, use the `absoluteString` property of that URL is
    /// generally a good idea.
    ///
    /// Kingfisher uses this value to identify whether a finished task is the running and
    /// being expected one for a view when you use Kingfisher's view extensions methods.
    var identifier: String {get }
    
    /// Provides the data which represents image. Kingfisher uses the data you pass in the
    /// handler to process images and caches it for later use.
    ///
    /// - Parameter handler: The handler you should call when you prepared your data.
    ///                      If the data is loaded successfully, call the handler with
    ///                      a `.success` with the data associated. Otherwise, call it
    ///                      with a `.failure` and pass the error.
    ///
    /// - Note:
    /// If the `handler` is called with a `.failure` and error, a `dataProviderError` of
    /// `ImageSettingErrorReason` will be finally thrown out to you as the `KingfisherError`
    /// accrossing the framework.
    func data(handler: @escaping (Result<Data, Error>) -> Void)
}

/// Represents an image data provider for loading from a local file URL on disk.
/// Uses this type for adding a disk image to Kingfisher. Compared to loading it
/// directly, you can get benefit of using Kingfisher's extension methods, as well
/// as applying `ImageProcessor`s and storing the image to `ImageCache` of Kingfisher.
public struct LocalFileImageDataProvider: ImageDataProvider {

    /// The file URL from which the image be loaded.
    public let fileURL: URL
    
    /// Creates an image data provider by supplying the target local file URL.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL from which the image be loaded.
    ///   - cacheKey: The key is used for caching the image data. By default,
    ///               the `absoluteString` of `fileURL` is used.
    public init(fileURL: URL, cacheKey: String? = nil) {
        self.fileURL = fileURL
        self.cacheKey = cacheKey ?? fileURL.absoluteString
    }
    
    public var cacheKey: String
    public func data(handler: (Result<Data, Error>) -> Void) {
        handler( Result { try Data(contentsOf: fileURL) } )
    }
    public var identifier: String { return fileURL.absoluteString }
}

/// Represents an image data provider for loading image from a given Base64 encoded string.
public struct Base64ImageDataProvider: ImageDataProvider {
    
    let base64String: String
    
    /// Creates an umage data provider by supplying the Base64 encoded string.
    ///
    /// - Parameters:
    ///   - base64String: The Base64 encoded string for an image.
    ///   - cacheKey: The key is used for caching the image data. You need a different key for any different image.
    public init(base64String: String, cacheKey: String) {
        self.base64String = base64String
        self.cacheKey = cacheKey
    }

    public var cacheKey: String
    public var identifier: String { return cacheKey }
    public func data(handler: (Result<Data, Error>) -> Void) {
        let data = Data(base64Encoded: base64String)!
        handler(.success(data))
    }
}
