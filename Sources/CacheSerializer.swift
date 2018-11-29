//
//  CacheSerializer.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/09/02.
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

/// An `CacheSerializer` would be used to convert some data to an image object for 
/// retrieving from disk cache and vice versa for storing to disk cache.
public protocol CacheSerializer {
    
    /// Get the serialized data from a provided image
    /// and optional original data for caching to disk.
    ///
    ///
    /// - parameter image:    The image needed to be serialized.
    /// - parameter original: The original data which is just downloaded. 
    ///                       If the image is retrieved from cache instead of
    ///                       downloaded, it will be `nil`.
    ///
    /// - returns: A data which will be stored to cache, or `nil` when no valid
    ///            data could be serialized.
    func data(with image: Image, original: Data?) -> Data?
    
    /// Get an image deserialized from provided data.
    ///
    /// - parameter data:    The data from which an image should be deserialized.
    /// - parameter options: Options for deserialization.
    ///
    /// - returns: An image deserialized or `nil` when no valid image 
    ///            could be deserialized.
    func image(with data: Data, options: KingfisherOptionsInfo?) -> Image?
}


/// `DefaultCacheSerializer` is a basic `CacheSerializer` used in default cache of
/// Kingfisher. It could serialize and deserialize PNG, JEPG and GIF images. For 
/// image other than these formats, a normalized `pngRepresentation` will be used.
public struct DefaultCacheSerializer: CacheSerializer {
    
    public static let `default` = DefaultCacheSerializer()
    private init() {}
    
    public func data(with image: Image, original: Data?) -> Data? {
        let imageFormat = original?.kf.imageFormat ?? .unknown

        let data: Data?
        switch imageFormat {
        case .PNG: data = image.kf.pngRepresentation()
        case .JPEG: data = image.kf.jpegRepresentation(compressionQuality: 1.0)
        case .GIF: data = image.kf.gifRepresentation()
        case .unknown: data = original ?? image.kf.normalized.kf.pngRepresentation()
        }

        return data
    }
    
    public func image(with data: Data, options: KingfisherOptionsInfo?) -> Image? {
        let options = options ?? KingfisherEmptyOptionsInfo
        return Kingfisher<Image>.image(
            data: data,
            scale: options.scaleFactor,
            preloadAllAnimationData: options.preloadAllAnimationData,
            onlyFirstFrame: options.onlyLoadFirstFrame)
    }
}
