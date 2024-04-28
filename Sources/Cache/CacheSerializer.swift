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
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A `CacheSerializer` is used to convert some data to an image object after retrieving it from disk storage,
/// and vice versa, to convert an image to a data object for storing it to the disk storage.
public protocol CacheSerializer: Sendable {
    
    /// Retrieves the serialized data from a provided image and optional original data for caching to disk.
    ///
    /// - Parameters:
    ///   - image: The image to be serialized.
    ///   - original: The original data that was just downloaded.
    ///   If the image is retrieved from the cache instead of being downloaded, it will be `nil`.
    /// - Returns: The data object for storing to disk, or `nil` when no valid data can be serialized.
    func data(with image: KFCrossPlatformImage, original: Data?) -> Data?

    /// Retrieves an image from the provided serialized data.
    ///
    /// - Parameters:
    ///   - data: The data from which an image should be deserialized.
    ///   - options: The parsed options for deserialization.
    /// - Returns: A deserialized image, or `nil` when no valid image can be deserialized.
    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
    
    /// Indicates whether this serializer prefers to cache the original data in its implementation.
    ///
    /// If `true`, during storing phase, the original data is preferred to be stored to the disk if exists. When
    /// retrieving image from the disk cache, after creating the image from the loaded data, Kingfisher will continue
    /// to apply the processor to get the final image.
    ///
    /// By default, it is `false`, and the actual processed image is assumed to be serialized to and later deserialized
    /// from the disk. That means the processed version of the image is stored and loaded.
    var originalDataUsed: Bool { get }
}

public extension CacheSerializer {
    var originalDataUsed: Bool { false }
}

/// Represents a basic and default `CacheSerializer` used in the Kingfisher disk cache system.
///
/// It can serialize and deserialize images in PNG, JPEG, and GIF formats. For images other than these formats, a 
/// normalized ``KingfisherWrapper/pngRepresentation()`` will be used.
///
/// When converting an `image` to the date, it will only be converted to the corresponding data type when `original`
/// contains valid PNG, JPEG, and GIF format data. If the `original` is provided but not valid, or if `original` is
/// `nil`, the input `image` will be encoded as PNG data.
public struct DefaultCacheSerializer: CacheSerializer {
    
    /// The default general cache serializer utilized throughout Kingfisher's caching mechanism.
    public static let `default` = DefaultCacheSerializer()

    /// The compression quality used when converting an image to lossy format data (such as JPEG).
    ///
    /// Default is 1.0.
    public var compressionQuality: CGFloat = 1.0

    /// Determines whether the original data should be prioritized during image serialization.
    ///
    /// If set to `true`, the original input data will be initially inspected and used, unless the data is `nil`.
    /// In the event of a `nil` data, the serialization process will revert to generating data from the image.
    ///
    /// > This value is used as ``CacheSerializer/originalDataUsed-d2v9``.
    public var preferCacheOriginalData: Bool = false

    public var originalDataUsed: Bool { preferCacheOriginalData }
    
    /// Creates a cache serializer that serializes and deserializes images in PNG, JPEG, and GIF formats.
    ///
    /// > Prefer to use the ``DefaultCacheSerializer/default`` value unless you need to specify your own properties.
    public init() { }

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
    
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return KingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
    }
}
