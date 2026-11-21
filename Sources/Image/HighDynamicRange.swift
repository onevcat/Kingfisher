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

extension CGImage {
    /// The same pixels, with the alpha channel marked as unused. The pixels are not copied.
    ///
    /// Core Image creates HDR images with premultiplied alpha, four little-endian 16-bit components. The gain map
    /// encoder accepts only opaque images, and a gain map file is much smaller than the 16-bit PNG file of an image
    /// with alpha. Use it only when every pixel is known to be opaque: then the premultiplied colors are the colors.
    ///
    /// - Returns: The image, or `nil` if the image does not have that layout.
    var withoutAlphaChannel: CGImage? {
        guard alphaInfo == .premultipliedLast, bitsPerComponent == 16, bitsPerPixel == 64,
              !bitmapInfo.contains(.floatComponents), bitmapInfo.intersection(.byteOrderMask) == .byteOrder16Little,
              let provider = dataProvider else
        {
            return nil
        }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 16,
            bitsPerPixel: 64,
            bytesPerRow: bytesPerRow,
            space: colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: shouldInterpolate,
            intent: renderingIntent
        )
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

    /// Whether drawing should keep the HDR content of this image: it was created with
    /// ``ImageCreatingOptions/prefersHighDynamicRange``, and it is HDR.
    var drawsInHighDynamicRange: Bool {
        prefersHighDynamicRange && isHighDynamicRange
    }

    /// A bitmap that keeps the HDR content of this image: the color space of the image and four little-endian 16-bit
    /// components.
    ///
    /// The default drawing contexts are SDR, or use a pixel format that the gain map encoder misreads. This layout is
    /// one that it reads correctly when the bitmap is opaque. See ``CGImage/isSupportedByGainMapEncoder``.
    func highDynamicRangeContext(width: Int, height: Int, opaque: Bool) -> CGContext? {
        guard let cgImage, let colorSpace = cgImage.colorSpace, width > 0, height > 0 else { return nil }
        let alphaInfo: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 16,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: alphaInfo.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        ) else {
            return nil
        }
        context.keepRange(of: cgImage)
        return context
    }

    /// Whether the image has no alpha channel.
    var isOpaque: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else { return false }
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return true
        default: return false
        }
    }

    /// Draws an HDR image into a bitmap that keeps its HDR content, and returns the result.
    ///
    /// `UIImage.preparingForDisplay()` returns the SDR version of an image decoded from a gain map, so background
    /// decoding draws the image itself.
    ///
    /// - Returns: The decoded image, marked with ``prefersHighDynamicRange``, or `nil` if the image is not HDR or
    ///   the bitmap cannot be created.
    func highDynamicRangeDecoded(scale: CGFloat) -> KFCrossPlatformImage? {
        guard let cgImage, cgImage.usesHighDynamicRangeTransferFunction,
              let context = highDynamicRangeContext(width: cgImage.width, height: cgImage.height, opaque: isOpaque) else
        {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        guard let decoded = context.makeImage() else { return nil }
        let image = KingfisherWrapper.image(cgImage: decoded, scale: scale, refImage: base)
        image.kf.prefersHighDynamicRange = true
        return image
    }

    /// The HDR version of ``draw(to:inverting:scale:refImage:keepsOpacity:draw:)``, for an image that
    /// ``drawsInHighDynamicRange``.
    ///
    /// The drawing happens in ``highDynamicRangeContext(width:height:opaque:)``, set up like the context of the regular
    /// version: it is the current UIKit or AppKit context, in points, with the same coordinate system. Pass `opaque` when
    /// the drawing covers the whole size with opaque content: an opaque result can be stored with a gain map. The
    /// bitmap is opaque only if the size is also a whole number of pixels.
    ///
    /// - Returns: The drawn image, marked with ``prefersHighDynamicRange``, or `nil` if the bitmap cannot be created.
    func highDynamicRangeDraw(
        to size: CGSize,
        inverting: Bool,
        scale: CGFloat,
        refImage: KFCrossPlatformImage?,
        opaque: Bool = false,
        draw: (CGContext) -> Bool
    ) -> KFCrossPlatformImage? {
        // The same pixel size as the regular version.
        #if os(macOS)
        let width = max(Int((size.width * scale).rounded(.down)), 1)
        let height = max(Int((size.height * scale).rounded(.down)), 1)
        #else
        let width = Int((size.width * scale).rounded(.up))
        let height = Int((size.height * scale).rounded(.up))
        #endif
        // When the size is not a whole number of pixels, the drawing does not cover the edge pixels completely. They
        // need alpha, or they would be mixed with the black of an opaque bitmap.
        let coversBitmap = abs(size.width * scale - CGFloat(width)) < 0.001
            && abs(size.height * scale - CGFloat(height)) < 0.001
        guard let context = highDynamicRangeContext(width: width, height: height, opaque: opaque && coversBitmap) else {
            return nil
        }

        #if os(macOS)
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        graphicsContext.imageInterpolation = .high
        NSGraphicsContext.current = graphicsContext
        context.scaleBy(x: scale, y: scale)
        #else
        // UIKit draws with the origin at the top left.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        if inverting { // If drawing a CGImage, we need to make context flipped.
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -size.height)
        }
        context.interpolationQuality = .high
        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }
        #endif

        let useRefImage = draw(context)
        guard let cgImage = context.makeImage() else { return nil }
        let image = KingfisherWrapper.image(
            cgImage: cgImage, scale: scale, refImage: useRefImage ? (refImage ?? base) : nil
        )
        image.kf.prefersHighDynamicRange = true
        return image
    }

    #if os(macOS)
    /// Returns `cgImage`, a filter result of this image, with the pixel size of this image, keeping its HDR content.
    ///
    /// The regular path, ``fixedForRetinaPixel(cgImage:to:)``, draws the result again at the size of the image, which
    /// tone maps an HDR result to the headroom of the new bitmap. This one draws only when the sizes differ, in a
    /// bitmap with the headroom of the result.
    ///
    /// - Returns: The image, marked with ``prefersHighDynamicRange``, or `nil` if the bitmap cannot be created.
    func highDynamicRangeImage(fitting cgImage: CGImage) -> KFCrossPlatformImage? {
        let width = max(Int(size.width.rounded(.down)), 1)
        let height = max(Int(size.height.rounded(.down)), 1)
        var result = cgImage
        if cgImage.width != width || cgImage.height != height {
            guard let colorSpace = cgImage.colorSpace, let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 16,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
            ) else {
                return nil
            }
            context.keepRange(of: cgImage)
            context.interpolationQuality = .high
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            guard let drawn = context.makeImage() else { return nil }
            result = drawn
        }
        let image = KingfisherWrapper.image(cgImage: result, scale: 1, refImage: base)
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
            _ = setEDRTargetHeadroom(max(image.contentHeadroom, Self.defaultHighDynamicRangeHeadroom))
        }
    }

    /// The value of `kCGDefaultHDRImageContentHeadroom`: 1000 nits for a reference white of 203 nits. The constant
    /// is a mutable global, which Swift 6 does not allow to read from a nonisolated context.
    static let defaultHighDynamicRangeHeadroom: Float = 1000 / 203
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
