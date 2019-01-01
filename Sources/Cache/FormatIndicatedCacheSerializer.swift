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

/// `FormatIndicatedCacheSerializer` lets you indicate an image format for serialized caches.
///
/// It could serialize and deserialize PNG, JPEG and GIF images. For
/// image other than these formats, a normalized `pngRepresentation` will be used.
///
/// Example:
/// ````
/// let profileImageSize = CGSize(width: 44, height: 44)
///
/// // A round corner image.
/// let imageProcessor = RoundCornerImageProcessor(
///     cornerRadius: profileImageSize.width / 2, targetSize: profileImageSize)
///
/// let optionsInfo: KingfisherOptionsInfo = [
///     .cacheSerializer(FormatIndicatedCacheSerializer.png), 
///     .processor(imageProcessor)]
///
/// A URL pointing to a JPEG image.
/// let url = URL(string: "https://example.com/image.jpg")!
///
/// // Image will be always cached as PNG format to preserve alpha channel for round rectangle.
/// // So when you load it from cache again later, it will be still round cornered.
/// // Otherwise, the corner part would be filled by white color (since JPEG does not contain an alpha channel).
/// imageView.kf.setImage(with: url, options: optionsInfo)
/// ````
public struct FormatIndicatedCacheSerializer: CacheSerializer {
    
    /// A `FormatIndicatedCacheSerializer` which converts image from and to PNG format. If the image cannot be
    /// represented by PNG format, it will fallback to its real format which is determined by `original` data.
    public static let png = FormatIndicatedCacheSerializer(imageFormat: .PNG)
    
    /// A `FormatIndicatedCacheSerializer` which converts image from and to JPEG format. If the image cannot be
    /// represented by JPEG format, it will fallback to its real format which is determined by `original` data.
    public static let jpeg = FormatIndicatedCacheSerializer(imageFormat: .JPEG)
    
    /// A `FormatIndicatedCacheSerializer` which converts image from and to GIF format. If the image cannot be
    /// represented by GIF format, it will fallback to its real format which is determined by `original` data.
    public static let gif = FormatIndicatedCacheSerializer(imageFormat: .GIF)
    
    /// The indicated image format.
    private let imageFormat: ImageFormat
    
    /// Creates data which represents the given `image` under a format.
    public func data(with image: Image, original: Data?) -> Data? {
        
        func imageData(withFormat imageFormat: ImageFormat) -> Data? {
            switch imageFormat {
            case .PNG: return image.kf.pngRepresentation()
            case .JPEG: return image.kf.jpegRepresentation(compressionQuality: 1.0)
            case .GIF: return image.kf.gifRepresentation()
            case .unknown: return nil
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
    
    /// Same implementation as `DefaultCacheSerializer`.
    public func image(with data: Data, options: KingfisherParsedOptionsInfo) -> Image? {
        return KingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
    }
}
