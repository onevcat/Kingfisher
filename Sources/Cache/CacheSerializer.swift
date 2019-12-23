//
//  CacheSerializer.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/09/02.
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
import CoreGraphics

/// An `CacheSerializer` is used to convert some data to an image object after
/// retrieving it from disk storage, and vice versa, to convert an image to data object
/// for storing to the disk storage.
public protocol CacheSerializer {
    
    /// Gets the serialized data from a provided image
    /// and optional original data for caching to disk.
    ///
    /// - Parameters:
    ///   - image: The image needed to be serialized.
    ///   - original: The original data which is just downloaded.
    ///               If the image is retrieved from cache instead of
    ///               downloaded, it will be `nil`.
    /// - Returns: The data object for storing to disk, or `nil` when no valid
    ///            data could be serialized.
    func data(with image: KFCrossPlatformImage, original: Data?) -> Data?

    /// Gets an image from provided serialized data.
    ///
    /// - Parameters:
    ///   - data: The data from which an image should be deserialized.
    ///   - options: The parsed options for deserialization.
    /// - Returns: An image deserialized or `nil` when no valid image
    ///            could be deserialized.
    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
    
    /// Gets an image deserialized from provided data.
    ///
    /// - Parameters:
    ///   - data: The data from which an image should be deserialized.
    ///   - options: Options for deserialization.
    /// - Returns: An image deserialized or `nil` when no valid image
    ///            could be deserialized.
    /// - Note:
    /// This method is deprecated. Please implement the version with
    /// `KingfisherParsedOptionsInfo` as parameter instead.
    @available(*, deprecated,
    message: "Deprecated. Implement the method with same name but with `KingfisherParsedOptionsInfo` instead.")
    func image(with data: Data, options: KingfisherOptionsInfo?) -> KFCrossPlatformImage?
}

extension CacheSerializer {
    public func image(with data: Data, options: KingfisherOptionsInfo?) -> KFCrossPlatformImage? {
        return image(with: data, options: KingfisherParsedOptionsInfo(options))
    }
}

/// Represents a basic and default `CacheSerializer` used in Kingfisher disk cache system.
/// It could serialize and deserialize images in PNG, JPEG and GIF format. For
/// image other than these formats, a normalized `pngRepresentation` will be used.
public struct DefaultCacheSerializer: CacheSerializer {
    
    /// The default general cache serializer used across Kingfisher's cache.
    public static let `default` = DefaultCacheSerializer()

    /// The compression quality when converting image to a lossy format data. Default is 1.0.
    public var compressionQuality: CGFloat = 1.0

    /// Whether the original data should be preferred when serializing the image.
    /// If `true`, the input original data will be checked first and used unless the data is `nil`.
    /// In that case, the serialization will fall back to creating data from image.
    public var preferCacheOriginalData: Bool = false

    /// Creates a cache serializer that serialize and deserialize images in PNG, JPEG and GIF format.
    ///
    /// - Note:
    /// Use `DefaultCacheSerializer.default` unless you need to specify your own properties.
    ///
    public init() { }

    /// - Parameters:
    ///   - image: The image needed to be serialized.
    ///   - original: The original data which is just downloaded.
    ///               If the image is retrieved from cache instead of
    ///               downloaded, it will be `nil`.
    /// - Returns: The data object for storing to disk, or `nil` when no valid
    ///            data could be serialized.
    ///
    /// - Note:
    /// Only when `original` contains valid PNG, JPEG and GIF format data, the `image` will be
    /// converted to the corresponding data type. Otherwise, if the `original` is provided but it is not
    /// If `original` is `nil`, the input `image` will be encoded as PNG data.
    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        if preferCacheOriginalData {
            return original ??
                image.kf.data(
                    format: original?.kf.imageFormat ?? .unknown,
                    compressionQuality: compressionQuality
                )
        } else {
            return image.kf.data(
                format: original?.kf.imageFormat ?? .unknown,
                compressionQuality: compressionQuality
            )
        }
    }
    
    /// Gets an image deserialized from provided data.
    ///
    /// - Parameters:
    ///   - data: The data from which an image should be deserialized.
    ///   - options: Options for deserialization.
    /// - Returns: An image deserialized or `nil` when no valid image
    ///            could be deserialized.
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return KingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
    }
}
