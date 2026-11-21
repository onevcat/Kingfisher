//
//  HighDynamicRangeTests.swift
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

import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import Kingfisher

final class HighDynamicRangeTests: XCTestCase {

    // MARK: - Cache serialization

    #if os(macOS)
    // `NSImage(data:)` applies gain maps, so the serializer can store an HDR image with a gain map.
    func testSerializerKeepsGainMapForHDRImageFromGainMapJPEG() throws {
        try skipIfGainMapEncodingUnavailable(type: .jpeg)
        let original = Data(fileName: "hdr-gainmap.jpg")
        let image = try HDRTestImage.hdrImage()

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertEqual(HDRTestImage.typeIdentifier(of: data), UTType.jpeg.identifier)
        XCTAssertTrue(HDRTestImage.containsGainMap(data), "HDR image should be stored with a gain map")
        try assertDecodesToHDRTestImage(data)
    }

    func testSerializerKeepsGainMapForHDRImageFromGainMapHEIC() throws {
        try skipIfGainMapEncodingUnavailable(type: .heic)
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try HDRTestImage.hdrImage()

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertEqual(HDRTestImage.typeIdentifier(of: data), UTType.heic.identifier)
        XCTAssertTrue(HDRTestImage.containsGainMap(data), "HDR image should be stored with a gain map")
        try assertDecodesToHDRTestImage(data)
    }

    func testSerializerStoresDataThatDecodesBackToHDR() throws {
        try skipIfGainMapEncodingUnavailable(type: .heic)
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: original, options: .init()))
        XCTAssertTrue(image.kf.isHighDynamicRange, "NSImage applies the gain map")

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))
        let decoded = DefaultCacheSerializer.default.image(with: data, options: .init(nil))

        XCTAssertTrue(HDRTestImage.containsGainMap(data))
        XCTAssertEqual(decoded?.kf.isHighDynamicRange, true)
    }

    func testSerializerUsesCompressionQualityForGainMapEncoding() throws {
        try skipIfGainMapEncodingUnavailable(type: .jpeg)
        let original = Data(fileName: "hdr-gainmap.jpg")
        let image = try HDRTestImage.hdrImage(width: 128, height: 128, noise: true)

        var low = DefaultCacheSerializer()
        low.compressionQuality = 0.1
        let lowData = try XCTUnwrap(low.data(with: image, original: original))
        let highData = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertTrue(HDRTestImage.containsGainMap(lowData))
        XCTAssertLessThan(lowData.count, highData.count)
    }

    // The gain map encoder misreads 16-bit components in the default (big-endian) order, but still writes a gain
    // map. Kingfisher's own drawing on macOS, such as `kf.decoded`, produces this layout.
    func testSerializerKeepsDefaultEncodingForHDRImageWithBigEndianComponents() throws {
        let original = Data(fileName: "hdr-gainmap.jpg")
        let image = try HDRTestImage.hdrImage(layout: .defaultOrderOpaque)

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.jpegRepresentation(compressionQuality: 1.0))
    }

    func testSerializerKeepsDefaultEncodingForDecodedHDRImage() throws {
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: original, options: .init()))
        let decoded = image.kf.decoded
        XCTAssertTrue(decoded.kf.isHighDynamicRange)

        let data = DefaultCacheSerializer.default.data(with: decoded, original: original)

        XCTAssertEqual(data, decoded.kf.data(format: .unknown))
    }

    // The gain map encoder loses the colors of an image with alpha.
    func testSerializerKeepsDefaultEncodingForHDRImageWithAlpha() throws {
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try HDRTestImage.hdrImage(layout: .littleEndianTranslucent)

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.data(format: .unknown))
    }
    #else
    func testSerializerKeepsDefaultEncodingForHDRImageFromGainMapJPEG() throws {
        // `UIImage(data:)` reads only the SDR base image of a gain map file. A gain map encoding would turn this HDR
        // image into SDR when it is read back from the disk.
        let original = Data(fileName: "hdr-gainmap.jpg")
        let image = try HDRTestImage.hdrImage()

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.jpegRepresentation(compressionQuality: 1.0))
    }

    func testSerializerKeepsDefaultEncodingForHDRImageFromGainMapHEIC() throws {
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try HDRTestImage.hdrImage()

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertEqual(data, image.kf.data(format: .unknown))
        let decoded = try XCTUnwrap(DefaultCacheSerializer.default.image(with: data, options: .init(nil)))
        XCTAssertTrue(decoded.kf.isHighDynamicRange, "A 16-bit PNG keeps the PQ color space")
    }
    #endif

    func testSerializerKeepsDefaultEncodingForSDRImageFromGainMapJPEG() throws {
        let original = Data(fileName: "hdr-gainmap.jpg")
        let image = try HDRTestImage.sdrImage()

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.jpegRepresentation(compressionQuality: 1.0))
    }

    func testSerializerKeepsDefaultEncodingForHDRImageFromJPEGWithoutGainMap() throws {
        // An HDR JPEG without a gain map (for example, tagged with a PQ profile) is read as HDR by every decoder.
        // A gain map encoding would make it SDR for decoders that ignore gain maps.
        let image = try HDRTestImage.hdrImage()
        let original = try HDRTestImage.sdrData(type: .jpeg)

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.jpegRepresentation(compressionQuality: 1.0))
    }

    func testSerializerKeepsDefaultEncodingForHDRImageFromHEICWithoutGainMap() throws {
        let image = try HDRTestImage.hdrImage()
        let original = Data(fileName: "gradient-10b-srgb-opaque.heic")

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertEqual(data, image.kf.data(format: .unknown))
        let decoded = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: .init()))
        XCTAssertTrue(decoded.kf.isHighDynamicRange, "A 16-bit PNG keeps the PQ color space")
    }

    func testSerializerKeepsPNGEncodingForHDRImageFromPNG() throws {
        let image = try HDRTestImage.hdrImage()
        let original = try XCTUnwrap(image.kf.pngRepresentation())

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertEqual(data, image.kf.pngRepresentation())
    }

    func testSerializerKeepsDefaultEncodingForSDRImage() throws {
        let original = try HDRTestImage.sdrData(type: .jpeg)
        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: original, options: .init()))
        XCTAssertFalse(image.kf.isHighDynamicRange)

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.jpegRepresentation(compressionQuality: 1.0))
    }

    func testSerializerKeepsDefaultEncodingForHDRImageWithoutOriginalData() throws {
        let image = try HDRTestImage.hdrImage()

        let data = DefaultCacheSerializer.default.data(with: image, original: nil)

        XCTAssertEqual(data, image.kf.data(format: .unknown))
    }

    func testSerializerUsesOriginalDataWhenPreferred() throws {
        var serializer = DefaultCacheSerializer()
        serializer.preferCacheOriginalData = true
        let original = Data(fileName: "hdr-gainmap.jpg")

        let data = serializer.data(with: try HDRTestImage.hdrImage(), original: original)

        XCTAssertEqual(data, original)
    }

    // MARK: - Helpers

    private func skipIfGainMapEncodingUnavailable(type: UTType) throws {
        guard HDRTestImage.canEncodeGainMap(type: type) else {
            throw XCTSkip("Gain map encoding to \(type.identifier) is not available on this platform.")
        }
    }

    /// Checks that `data` decodes to an HDR image with the pixel values of ``HDRTestImage/hdrCGImage``.
    private func assertDecodesToHDRTestImage(_ data: Data, file: StaticString = #filePath, line: UInt = #line) throws {
        let cgImage = try HDRTestImage.decodeToHDR(data)
        let colorSpace = try XCTUnwrap(cgImage.colorSpace, file: file, line: line)
        XCTAssertTrue(CGColorSpaceUsesITUR_2100TF(colorSpace), "Expected an HDR image after decoding", file: file, line: line)
        let left = try HDRTestImage.linearPixel(of: cgImage, x: 2, y: cgImage.height / 2)
        let right = try HDRTestImage.linearPixel(of: cgImage, x: cgImage.width - 3, y: cgImage.height / 2)
        assertClose(left, HDRTestImage.leftPixel, file: file, line: line)
        assertClose(right, HDRTestImage.rightPixel, file: file, line: line)
    }

    private func assertClose(_ actual: [Float], _ expected: [Float], file: StaticString = #filePath, line: UInt = #line) {
        for (a, e) in zip(actual, expected) {
            XCTAssertEqual(a, e, accuracy: e * 0.1 + 0.02, "\(actual) is not close to \(expected)", file: file, line: line)
        }
    }
}

/// Builds HDR test images in code. Only gain map images, which the simulators cannot encode, are fixture files.
enum HDRTestImage {

    /// The pixel layout of an HDR test image, all with 16 bits per component.
    enum Layout {
        /// Little-endian components, no alpha.
        case littleEndianOpaque
        /// The default component order of a `CGContext` (big-endian), no alpha. Kingfisher draws into such a context.
        case defaultOrderOpaque
        /// Little-endian components, premultiplied alpha. The alpha is 0.5.
        case littleEndianTranslucent
    }

    /// The pixel values of ``hdrCGImage(width:height:noise:layout:)`` in extended linear Display P3, without alpha
    /// premultiplication: the left half is 4x the SDR white, the right half is in the SDR range.
    static let leftPixel: [Float] = [4.0, 3.2, 2.4]
    static let rightPixel: [Float] = [0.5, 0.4, 0.3]

    /// An image with an HDR color space (PQ), 16 bits per component.
    static func hdrCGImage(
        width: Int = 16, height: Int = 16, noise: Bool = false, layout: Layout = .littleEndianOpaque
    ) throws -> CGImage {
        let alpha: Float = layout == .littleEndianTranslucent ? 0.5 : 1.0
        let linear = try extendedLinearCGImage(width: width, height: height, noise: noise, alpha: alpha)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.itur_2100_PQ))
        let bitmapInfo: UInt32
        switch layout {
        case .littleEndianOpaque:
            bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        case .defaultOrderOpaque:
            bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
        case .littleEndianTranslucent:
            bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        }
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 16,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: bitmapInfo
        ))
        context.draw(linear, in: CGRect(x: 0, y: 0, width: width, height: height))
        return try XCTUnwrap(context.makeImage())
    }

    static func hdrImage(
        width: Int = 16, height: Int = 16, noise: Bool = false, layout: Layout = .littleEndianOpaque
    ) throws -> KFCrossPlatformImage {
        let cgImage = try hdrCGImage(width: width, height: height, noise: noise, layout: layout)
        return KingfisherWrapper<KFCrossPlatformImage>.image(cgImage: cgImage, scale: 1, refImage: nil)
    }

    /// The RGB values of a pixel in extended linear Display P3, without alpha premultiplication.
    static func linearPixel(of image: CGImage, x: Int, y: Int) throws -> [Float] {
        let width = image.width, height = image.height
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 32,
            bytesPerRow: width * 16,
            space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                CGBitmapInfo.floatComponents.rawValue |
                CGBitmapInfo.byteOrder32Little.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixels = try XCTUnwrap(context.data).bindMemory(to: Float.self, capacity: width * height * 4)
        let index = ((height - 1 - y) * width + x) * 4
        let alpha = pixels[index + 3]
        guard alpha > 0 else { return [0, 0, 0] }
        return (0..<3).map { pixels[index + $0] / alpha }
    }

    /// Decodes `data` as HDR, applying a gain map if there is one.
    static func decodeToHDR(_ data: Data) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let options = [kCGImageSourceDecodeRequest: kCGImageSourceDecodeToHDR] as CFDictionary
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, options))
    }

    /// Whether the system can encode an HDR image with an ISO gain map as `type`.
    static func canEncodeGainMap(type: UTType) -> Bool {
        guard #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
              let image = try? hdrCGImage(width: 4, height: 4) else
        {
            return false
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            return false
        }
        let properties = [kCGImageDestinationEncodeRequest: kCGImageDestinationEncodeToISOGainmap] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        return CGImageDestinationFinalize(destination) && containsGainMap(data as Data)
    }

    static func sdrImage() throws -> KFCrossPlatformImage {
        let data = try sdrData(type: .png)
        return try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: .init()))
    }

    static func sdrData(type: UTType) throws -> Data {
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 16, height: 16, bitsPerComponent: 8, bytesPerRow: 0, space: space,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        return try encode(try XCTUnwrap(context.makeImage()), type: type, properties: [:])
    }

    static func typeIdentifier(of data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceGetType(source) as String?
    }

    static func containsGainMap(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return false }
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
           CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeISOGainMap) != nil {
            return true
        }
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeHDRGainMap) != nil
    }

    // RGBA, 32-bit float, extended linear Display P3. `Float16` is not available on Intel Macs.
    private static func extendedLinearCGImage(width: Int, height: Int, noise: Bool, alpha: Float = 1) throws -> CGImage {
        var generator = SystemRandomNumberGenerator()
        var pixels = [Float](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                var value: Float = x < width / 2 ? 4.0 : 0.5
                if noise { value *= Float.random(in: 0.5...1.0, using: &generator) }
                let index = (y * width + x) * 4
                pixels[index] = value * alpha
                pixels[index + 1] = value * 0.8 * alpha
                pixels[index + 2] = value * 0.6 * alpha
                pixels[index + 3] = alpha
            }
        }
        let data = pixels.withUnsafeBufferPointer { Data(buffer: $0) }
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedLast.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGBitmapInfo.byteOrder32Little.rawValue
        )
        return try XCTUnwrap(CGImage(
            width: width,
            height: height,
            bitsPerComponent: 32,
            bitsPerPixel: 128,
            bytesPerRow: width * 16,
            space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)),
            bitmapInfo: bitmapInfo,
            provider: try XCTUnwrap(CGDataProvider(data: data as CFData)),
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
    }

    private static func encode(_ image: CGImage, type: UTType, properties: [CFString: Any]) throws -> Data {
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw XCTSkip("Encoding \(type.identifier) is not available on this platform.")
        }
        return data as Data
    }
}
