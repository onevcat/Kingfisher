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
#if !os(macOS) && !targetEnvironment(simulator)
import os
#endif
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

    /// Indicates whether ``data(with:original:)`` writes a self-describing image format, such as PNG, JPEG or GIF.
    ///
    /// When `true`, Kingfisher may hand the cached bytes straight to an ``ImageProcessor`` as
    /// ``ImageProcessItem/data(_:)`` instead of deserializing them first. Data-based processors — most notably
    /// ``DownsamplingImageProcessor`` — re-encode an image input to get back to data, so deserializing first costs a
    /// full size decode and re-encode that the processor immediately discards.
    ///
    /// By default it is `false`, and ``image(with:options:)`` is always used. Return `true` only if the bytes this
    /// serializer writes can be decoded by the system image APIs on their own; a serializer that encrypts or
    /// otherwise wraps its payload must leave it `false`.
    var producesDecodableImageData: Bool { get }
}

public extension CacheSerializer {
    var originalDataUsed: Bool { false }
    var producesDecodableImageData: Bool { false }
}

/// Controls whether a built-in cache serializer starts encoding an image under memory pressure.
///
/// Set the serializer's `memoryPolicy` to ``availableMemory`` to opt in. The default is ``unrestricted``.
/// Existing original or GIF data can still be reused without encoding.
///
/// ```swift
/// var serializer = DefaultCacheSerializer.default
/// serializer.memoryPolicy = .availableMemory
/// let options: KingfisherOptionsInfo = [.cacheSerializer(serializer)]
/// ```
public struct CacheSerializationMemoryPolicy: Sendable {
    /// Encodes images without checking the available process memory.
    public static let unrestricted = CacheSerializationMemoryPolicy(availableMemory: { nil })

    /// Skips encoding when its estimated working memory exceeds the available process memory.
    ///
    /// The estimate is twice the bitmap size, with at least four bytes per pixel. It is a heuristic,
    /// not an upper bound on encoder allocations. Memory availability can change after the check.
    /// This policy does not guarantee protection from out-of-memory termination or limit queued images.
    ///
    /// Enable this policy for apps with observed memory pressure during image encoding; it does not reduce
    /// the memory cost of accepted writes. Skipping writes can reduce disk cache hits and require images
    /// to be downloaded or processed again, even when encoding would have succeeded.
    ///
    /// On macOS and Simulator, the process memory query is unavailable, so encoding proceeds.
    /// A skipped write returns `nil` from the serializer. `ImageCache` keeps its memory entry and reports
    /// ``KingfisherError/CacheErrorReason/cannotSerializeImage(image:original:serializer:)`` for the disk write.
    public static let availableMemory = CacheSerializationMemoryPolicy {
        #if !os(macOS) && !targetEnvironment(simulator)
        return os_proc_available_memory()
        #else
        return nil
        #endif
    }

    private let availableMemory: @Sendable () -> Int?

    init(availableMemory: @escaping @Sendable () -> Int?) {
        self.availableMemory = availableMemory
    }

    func allowsSerialization(of image: KFCrossPlatformImage) -> Bool {
        guard let available = availableMemory() else { return true }
        let bitmapBytes: Double
        if let cgImage = image.kf.cgImage {
            bitmapBytes = max(Double(cgImage.bytesPerRow), Double(cgImage.width) * 4) * Double(cgImage.height)
        } else {
            let scale = Double(image.kf.scale)
            bitmapBytes = Double(image.size.width) * Double(image.size.height) * scale * scale * 4
        }
        // Floating-point arithmetic avoids an integer overflow for unusually large image dimensions.
        return bitmapBytes.isFinite && bitmapBytes >= 0 && bitmapBytes * 2 <= Double(available)
    }
}

/// Represents a basic and default `CacheSerializer` used in the Kingfisher disk cache system.
///
/// It can serialize and deserialize images in PNG, JPEG, and GIF formats. For images other than these formats, a 
/// normalized ``KingfisherWrapper/pngRepresentation()`` will be used.
///
/// When converting an `image` to the data, it will only be converted to the corresponding data type when `original`
/// contains valid PNG, JPEG, and GIF format data. If the `original` is provided but not valid, or if `original` is
/// `nil`, the input `image` will be encoded as PNG data.
///
/// If `original` is `nil` but the input `image` contains embedded GIF data (for example, a cached animated image
/// created from GIF data), the serializer will prefer the embedded GIF data and store it as GIF instead of falling
/// back to PNG.
///
/// > Tip: If you create a new image instance from an animated image in a custom processor, use
/// > ``KingfisherWrapper/copyKingfisherState(to:)`` to propagate the embedded animated data to the new image.
public struct DefaultCacheSerializer: CacheSerializer {

    /// Writes PNG, JPEG or GIF, so the cached bytes can be decoded directly.
    public var producesDecodableImageData: Bool { true }
    
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

    /// The memory policy checked once before encoding. The default is ``CacheSerializationMemoryPolicy/unrestricted``.
    public var memoryPolicy: CacheSerializationMemoryPolicy = .unrestricted

    public var originalDataUsed: Bool { preferCacheOriginalData }
    
    /// Creates a cache serializer that serializes and deserializes images in PNG, JPEG, and GIF formats.
    ///
    /// > Prefer to use the ``DefaultCacheSerializer/default`` value unless you need to specify your own properties.
    public init() { }

    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        let format: ImageFormat = {
            if let original = original { return original.kf.imageFormat }

            if let animatedData = image.kf.gifRepresentation(), animatedData.kf.imageFormat == .GIF {
                return .GIF
            }
            return .unknown
        }()

        if preferCacheOriginalData {
            if let original = original { return original }
            if format == .GIF { return image.kf.gifRepresentation() }
        }

        if format != .GIF, !memoryPolicy.allowsSerialization(of: image) { return nil }
        return image.kf.data(format: format, compressionQuality: compressionQuality)
    }
    
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return KingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
    }
}
