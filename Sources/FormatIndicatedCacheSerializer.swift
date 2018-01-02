//
//  RequestModifier.swift
//  Kingfisher
//
//  Created by Junyu Kuang on 5/28/17.
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

/// `FormatIndicatedCacheSerializer` let you indicate an image format for serialized caches.
///
/// It could serialize and deserialize PNG, JEPG and GIF images. For
/// image other than these formats, a normalized `pngRepresentation` will be used.
///
/// Example:
/// ````
/// private let profileImageSize = CGSize(width: 44, height: 44)
///
/// private let imageProcessor = RoundCornerImageProcessor(
///     cornerRadius: profileImageSize.width / 2, targetSize: profileImageSize)
///
/// private let optionsInfo: KingfisherOptionsInfo = [
///     .cacheSerializer(FormatIndicatedCacheSerializer.png), 
///     .backgroundDecode, .processor(imageProcessor), .scaleFactor(UIScreen.main.scale)]
///
/// extension UIImageView {
///    func setProfileImage(with url: URL) {
///        // Image will always cached as PNG format to preserve alpha channel for round rect.
///        _ = kf.setImage(with: url, options: optionsInfo)
///    }
///}
/// ````
public struct FormatIndicatedCacheSerializer: CacheSerializer {
    
    public static let png = FormatIndicatedCacheSerializer(imageFormat: .PNG)
    public static let jpeg = FormatIndicatedCacheSerializer(imageFormat: .JPEG)
    public static let gif = FormatIndicatedCacheSerializer(imageFormat: .GIF)
    
    /// The indicated image format.
    private let imageFormat: ImageFormat
    
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
    public func image(with data: Data, options: KingfisherOptionsInfo?) -> Image? {
        let options = options ?? KingfisherEmptyOptionsInfo
        return Kingfisher<Image>.image(
            data: data,
            scale: options.scaleFactor,
            preloadAllAnimationData: options.preloadAllAnimationData,
            onlyFirstFrame: options.onlyLoadFirstFrame)
    }
}
