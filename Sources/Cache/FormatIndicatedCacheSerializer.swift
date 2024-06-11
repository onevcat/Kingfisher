//
//  RequestModifier.swift
//  Kingfisher
//
//  Created by Junyu Kuang on 5/28/17.
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

/// The ``FormatIndicatedCacheSerializer`` enables you to specify an image format for serialized caches.
///
/// It can serialize and deserialize PNG, JPEG, and GIF images. For images other than these formats, a normalized 
/// ``KingfisherWrapper/pngRepresentation()`` will be used.
///
/// **Example:**
///
/// ```swift
/// let profileImageSize = CGSize(width: 44, height: 44)
///
/// // A round corner image.
/// let imageProcessor = RoundCornerImageProcessor(
///     cornerRadius: profileImageSize.width / 2, targetSize: profileImageSize)
///
/// let optionsInfo: KingfisherOptionsInfo = [
///     .cacheSerializer(FormatIndicatedCacheSerializer.png),
///     .processor(imageProcessor)
/// ]
///
/// // A URL pointing to a JPEG image.
/// let url = URL(string: "https://example.com/image.jpg")!
///
/// // The image will always be cached as PNG format to preserve the alpha channel for the round rectangle.
/// // When you load it from the cache later, it will still be round cornered.
/// // Otherwise, the corner part would be filled by a white color (since JPEG does not contain an alpha channel).
/// imageView.kf.setImage(with: url, options: optionsInfo)
/// ```
public struct FormatIndicatedCacheSerializer: CacheSerializer {
    
    /// A ``FormatIndicatedCacheSerializer`` instance that converts images to and from the PNG format. 
    ///
    /// If the image cannot be represented in the PNG format, it will fallback to its actual format determined by the
    /// `original` data in ``CacheSerializer/data(with:original:)``.
    public static let png = FormatIndicatedCacheSerializer(imageFormat: .PNG, jpegCompressionQuality: nil)
    
    /// A `FormatIndicatedCacheSerializer` which converts image from and to JPEG format. If the image cannot be
    /// represented by JPEG format, it will fallback to its real format which is determined by `original` data.
    /// The compression quality is 1.0 when using this serializer. If you need to set a customized compression quality,
    /// use `jpeg(compressionQuality:)`.
    ///
    
    /// A ``FormatIndicatedCacheSerializer`` instance that converts images to and from the JPEG format.
    ///
    /// If the image cannot be represented in the JPEG format, it will fallback to its actual format determined by the
    /// `original` data in ``CacheSerializer/data(with:original:)``.
    ///
    /// > The compression quality is 1.0 when using this serializer. To set a customized compression quality,
    /// use ``FormatIndicatedCacheSerializer/jpeg(compressionQuality:)``.
    public static let jpeg = FormatIndicatedCacheSerializer(imageFormat: .JPEG, jpegCompressionQuality: 1.0)

    /// A ``FormatIndicatedCacheSerializer`` instance that converts images to and from the JPEG format.
    ///
    /// - Parameter compressionQuality: The compression quality when converting image to JPEG data.
    ///
    /// If the image cannot be represented in the JPEG format, it will fallback to its actual format determined by the
    /// `original` data in ``CacheSerializer/data(with:original:)``.
    public static func jpeg(compressionQuality: CGFloat) -> FormatIndicatedCacheSerializer {
        return FormatIndicatedCacheSerializer(imageFormat: .JPEG, jpegCompressionQuality: compressionQuality)
    }
    
    /// A ``FormatIndicatedCacheSerializer`` instance that converts images to and from the GIF format.
    ///
    /// If the image cannot be represented in the GIF format, it will fallback to its actual format determined by the
    /// `original` data in ``CacheSerializer/data(with:original:)``.
    public static let gif = FormatIndicatedCacheSerializer(imageFormat: .GIF, jpegCompressionQuality: nil)
    
    // The specified image format.
    private let imageFormat: ImageFormat

    // The compression quality used for lossy image formats (like JPEG).
    private let jpegCompressionQuality: CGFloat?
    
    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        
        func imageData(withFormat imageFormat: ImageFormat) -> Data? {
            return autoreleasepool { () -> Data? in
                switch imageFormat {
                case .PNG: return image.kf.pngRepresentation()
                case .JPEG: return image.kf.jpegRepresentation(compressionQuality: jpegCompressionQuality ?? 1.0)
                case .GIF: return image.kf.gifRepresentation()
                case .unknown: return nil
                }
            }
        }
        
        // generate data with indicated image format
        if let data = imageData(withFormat: imageFormat) {
            return data
        }
        
        let originalFormat = original?.kf.imageFormat ?? .unknown
        
        // generate data with original image's format
        if originalFormat != imageFormat, let data = imageData(withFormat: originalFormat) {
            return data
        }
        
        return original ?? image.kf.normalized.kf.pngRepresentation()
    }
    
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return KingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
    }
}
