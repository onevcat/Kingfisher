//
//  HighDynamicRange.swift
//  Kingfisher
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import ImageIO
import UniformTypeIdentifiers

extension CGImage {
    /// Whether the image uses an HDR transfer function (PQ or HLG) of ITU-R BT.2100.
    ///
    /// Images in an extended-range color space are not counted: UIKit draws SDR content into extended-range
    /// contexts too, so the color space alone does not tell that the content is HDR.
    var usesHighDynamicRangeTransferFunction: Bool {
        guard let colorSpace else { return false }
        return CGColorSpaceUsesITUR_2100TF(colorSpace)
    }

    /// Whether the ISO gain map encoder reads the pixels of this HDR image correctly.
    ///
    /// The encoder misreads some layouts and still writes data with a gain map, so the result cannot be checked
    /// after encoding. On macOS 27, it misreads 16-bit components in the default (big-endian) order of a
    /// `CGContext`, which Kingfisher's own drawing produces, and it loses the colors of an image with alpha. Only
    /// opaque images with an explicit little-endian order are accepted, such as the 10-bit images that ImageIO
    /// decodes from a gain map file.
    var isSupportedByGainMapEncoder: Bool {
        guard usesHighDynamicRangeTransferFunction else { return false }
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            break
        default:
            return false
        }
        let byteOrder = bitmapInfo.intersection(.byteOrderMask)
        return byteOrder == .byteOrder16Little || byteOrder == .byteOrder32Little
    }
}

extension KingfisherWrapper where Base: KFCrossPlatformImage {
    /// Whether the image holds HDR content that a plain SDR encoding would lose.
    var isHighDynamicRange: Bool {
        cgImage?.usesHighDynamicRangeTransferFunction ?? false
    }

    /// Encodes an HDR image with an ISO gain map, in the same format as `original`.
    ///
    /// A plain JPEG encoding of an HDR image stores it at 8 bits per component, and a PNG encoding of a full size
    /// photo is very large. With a gain map, the encoded data has an SDR base image and the information to restore
    /// the HDR version.
    ///
    /// This is done only when decoding the encoded data again restores the HDR image:
    ///
    /// - `original` has a gain map too. When `original` is HDR without a gain map (PQ or HLG), decoders that ignore
    ///   gain maps read it as HDR, and a gain map encoding would make it SDR for them.
    /// - The decoding applies the gain map. `NSImage(data:)` does. `UIImage(data:)` reads only the SDR base image.
    /// - The encoder reads the pixels of the image correctly. See ``CGImage/isSupportedByGainMapEncoder``.
    ///
    /// - Returns: The encoded data, or `nil` when one of the conditions above is not met, the image is not HDR, or
    ///   the system cannot encode gain maps. In that case, use the regular encoding.
    func highDynamicRangeData(matching original: Data, compressionQuality: CGFloat) -> Data? {
        guard #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) else { return nil }
        guard decodingAppliesGainMap, let cgImage, cgImage.isSupportedByGainMapEncoder else { return nil }
        guard let type = Self.gainMapEncodingType(of: original) else { return nil }

        var properties: [CFString: Any] = [
            kCGImageDestinationEncodeRequest: kCGImageDestinationEncodeToISOGainmap,
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        #if !os(macOS)
        properties[kCGImagePropertyOrientation] = CGImagePropertyOrientation(base.imageOrientation).rawValue
        #endif

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination),
              let source = CGImageSourceCreateWithData(data, nil),
              source.containsGainMap else
        {
            return nil
        }
        return data as Data
    }

    /// Whether ``KingfisherWrapper/image(data:options:)`` applies the gain map when it decodes this image again.
    private var decodingAppliesGainMap: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /// The format to use for a gain map encoding that matches `original`: JPEG or HEIC, and only when `original`
    /// has a gain map.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private static func gainMapEncodingType(of original: Data) -> UTType? {
        guard let source = CGImageSourceCreateWithData(original as CFData, nil),
              let identifier = CGImageSourceGetType(source) as String?,
              let type = UTType(identifier) else
        {
            return nil
        }
        let encodingType: UTType
        if type.conforms(to: .jpeg) {
            encodingType = .jpeg
        } else if type.conforms(to: .heic) {
            encodingType = .heic
        } else {
            return nil
        }
        guard source.containsGainMap else { return nil }
        return encodingType
    }
}

extension CGImageSource {
    /// Whether the first image has an ISO gain map or an Apple HDR gain map.
    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    var containsGainMap: Bool {
        CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeISOGainMap) != nil
            || CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeHDRGainMap) != nil
    }
}

#if !os(macOS)
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif
