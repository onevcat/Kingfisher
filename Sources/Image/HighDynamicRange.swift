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
    /// The encoder misreads some pixel formats and still writes data with a gain map, so the result cannot be
    /// checked after encoding. On macOS 27, for example, it misreads 16-bit components in the default (big-endian)
    /// order of a `CGContext`, which Kingfisher's own drawing produces, three 32-bit float components per pixel, and
    /// any image with alpha. So only complete pixel formats that were verified are accepted:
    ///
    /// - 10-bit components packed in 32 bits (`RGB101010`, little-endian, unused bits first), as ImageIO decodes a
    ///   gain map file.
    /// - Four 16-bit components, integer or float, in little-endian order, with the last one skipped.
    var isSupportedByGainMapEncoder: Bool {
        guard usesHighDynamicRangeTransferFunction else { return false }
        let byteOrder = bitmapInfo.intersection(.byteOrderMask)
        switch pixelFormatInfo {
        case .RGB101010:
            return bitsPerComponent == 10 && bitsPerPixel == 32 &&
                alphaInfo == .noneSkipFirst && byteOrder == .byteOrder32Little
        case .packed:
            return bitsPerComponent == 16 && bitsPerPixel == 64 &&
                alphaInfo == .noneSkipLast && byteOrder == .byteOrder16Little
        default:
            return false
        }
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
    ///
    /// `NSImage(data:)` always applies it. On the other platforms, only an image created with
    /// ``ImageCreatingOptions/prefersHighDynamicRange`` is decoded with the gain map applied. Its cache entries are
    /// read only with that option, because the option is part of the cache key.
    private var decodingAppliesGainMap: Bool {
        #if os(macOS)
        return true
        #else
        return prefersHighDynamicRange
        #endif
    }

    /// Decodes `data` with the gain map applied, if it has one.
    ///
    /// The result is marked with ``prefersHighDynamicRange``, so that the following steps keep the HDR content.
    static func highDynamicRangeImage(data: Data, scale: CGFloat) -> KFCrossPlatformImage? {
        #if os(watchOS)
        // An image is not shown as HDR on watchOS.
        return KFCrossPlatformImage(data: data, scale: scale)
        #else
        var image: KFCrossPlatformImage?
        #if os(iOS) || os(tvOS) || os(visionOS)
        // Only data with a gain map needs another decoder. `UIImage(data:)` reads other HDR images as HDR.
        if #available(iOS 17.0, tvOS 17.0, visionOS 1.0, *),
           let source = CGImageSourceCreateWithData(data as CFData, nil), source.containsGainMap
        {
            var configuration = UIImageReader.Configuration()
            configuration.prefersHighDynamicRange = true
            // A system that cannot apply gain maps, such as the simulators, returns an SDR image with empty pixels.
            // Use the result only when it is HDR. Otherwise, decode as usual.
            if let read = UIImageReader(configuration: configuration).image(data: data),
               read.cgImage?.usesHighDynamicRangeTransferFunction == true
            {
                if read.scale == scale {
                    image = read
                } else if let cgImage = read.cgImage {
                    image = KFCrossPlatformImage(cgImage: cgImage, scale: scale, orientation: read.imageOrientation)
                }
            }
        }
        #endif
        // `NSImage(data:)` applies a gain map already.
        let result = image ?? KFCrossPlatformImage(data: data, scale: scale)
        result?.kf.prefersHighDynamicRange = true
        return result
        #endif
    }

    /// Adds the request to apply a gain map to the options of a `CGImageSource` decoding.
    static func addHighDynamicRangeDecodeRequest(to options: inout [CFString: Any]) {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            options[kCGImageSourceDecodeRequest] = kCGImageSourceDecodeToHDR
        }
    }

    /// Draws an HDR image into a bitmap that keeps its HDR content, and returns the result.
    ///
    /// `UIImage.preparingForDisplay()` returns the SDR version of an image decoded from a gain map, and the default
    /// drawing contexts are SDR or use a pixel format that the gain map encoder misreads. This bitmap uses the color
    /// space of the image and four little-endian 16-bit components. See ``CGImage/isSupportedByGainMapEncoder``.
    ///
    /// - Returns: The decoded image, marked with ``prefersHighDynamicRange``, or `nil` if the image is not HDR or
    ///   the bitmap cannot be created.
    func highDynamicRangeDecoded(scale: CGFloat) -> KFCrossPlatformImage? {
        guard let cgImage, cgImage.usesHighDynamicRangeTransferFunction, let colorSpace = cgImage.colorSpace else {
            return nil
        }
        let alphaInfo: CGImageAlphaInfo
        switch cgImage.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: alphaInfo = .noneSkipLast
        default: alphaInfo = .premultipliedLast
        }
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 16,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: alphaInfo.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        ) else {
            return nil
        }
        context.keepRange(of: cgImage)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard let decoded = context.makeImage() else { return nil }
        let image = KingfisherWrapper.image(cgImage: decoded, scale: scale, refImage: base)
        image.kf.prefersHighDynamicRange = true
        return image
    }

    #if !os(macOS)
    /// Applies the orientation of a marked HDR image, in a bitmap that keeps its HDR content.
    ///
    /// The regular ``normalized`` image is drawn by `UIGraphicsImageRenderer`, which is SDR. The bitmap here is the
    /// same as the one of ``highDynamicRangeDecoded(scale:)``.
    ///
    /// - Returns: The image with the `.up` orientation, marked with ``prefersHighDynamicRange``, or `nil` if the image
    ///   is not a marked HDR image or the bitmap cannot be created.
    func highDynamicRangeNormalized() -> KFCrossPlatformImage? {
        guard prefersHighDynamicRange, let cgImage, cgImage.usesHighDynamicRangeTransferFunction,
              let colorSpace = cgImage.colorSpace else
        {
            return nil
        }
        let scale = base.scale
        let alphaInfo: CGImageAlphaInfo
        switch cgImage.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: alphaInfo = .noneSkipLast
        default: alphaInfo = .premultipliedLast
        }
        guard let context = CGContext(
            data: nil,
            width: Int((size.width * scale).rounded()),
            height: Int((size.height * scale).rounded()),
            bitsPerComponent: 16,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: alphaInfo.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        ) else {
            return nil
        }
        context.keepRange(of: cgImage)
        // A `CGContext` has its origin at the bottom left, as `fixOrientation(in:)` expects.
        context.scaleBy(x: scale, y: scale)
        fixOrientation(in: context)
        guard let normalized = context.makeImage() else { return nil }
        let image = KFCrossPlatformImage(cgImage: normalized, scale: scale, orientation: .up)
        image.kf.prefersHighDynamicRange = true
        return image
    }
    #endif

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
    var containsGainMap: Bool {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
           CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeISOGainMap) != nil
        {
            return true
        }
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeHDRGainMap) != nil
    }
}

extension CGContext {
    /// Sets the headroom of this bitmap so that drawing `image` into it keeps the range of `image`.
    ///
    /// Core Graphics tone maps an image to the headroom of the bitmap it is drawn into. The default headroom of an HDR
    /// color space is lower than the one of a bright image, such as one with a raised exposure, which would then lose
    /// most of its range.
    func keepRange(of image: CGImage) {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            _ = setEDRTargetHeadroom(max(image.contentHeadroom, kCGDefaultHDRImageContentHeadroom))
        }
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
