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

    // The gain map encoder misreads three 32-bit float components per pixel.
    func testSerializerKeepsDefaultEncodingForHDRImageWithFloatRGBComponents() throws {
        let image = try HDRTestImage.hdrImage(layout: .floatRGB)
        XCTAssertEqual(image.kf.cgImage?.bitsPerPixel, 96)

        let jpegOriginal = Data(fileName: "hdr-gainmap.jpg")
        XCTAssertEqual(
            DefaultCacheSerializer.default.data(with: image, original: jpegOriginal),
            image.kf.jpegRepresentation(compressionQuality: 1.0)
        )
        let heicOriginal = Data(fileName: "hdr-gainmap.heic")
        XCTAssertEqual(
            DefaultCacheSerializer.default.data(with: image, original: heicOriginal),
            image.kf.data(format: .unknown)
        )
    }

    func testSerializerKeepsPixelsOfHDRImageWith16BitFloatComponents() throws {
        try skipIfGainMapEncodingUnavailable(type: .heic)
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try HDRTestImage.hdrImage(layout: .littleEndianFloatOpaque)

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertTrue(HDRTestImage.containsGainMap(data))
        try assertDecodesToHDRTestImage(data)
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

final class HighDynamicRangeOptionTests: XCTestCase {

    var manager: KingfisherManager!

    override func setUp() {
        super.setUp()
        let uuid = UUID()
        manager = KingfisherManager(
            downloader: ImageDownloader.stubbed(name: "test.hdr.\(uuid.uuidString)"),
            cache: ImageCache(name: "test.hdr.\(uuid.uuidString)")
        )
        manager.defaultOptions = [.waitForCache]
    }

    override func tearDown() {
        clearStubs(afterCancelling: manager)
        clearCaches([manager.cache])
        manager = nil
        super.tearDown()
    }

    // MARK: - Options

    @MainActor
    func testParsingOption() {
        XCTAssertFalse(KingfisherParsedOptionsInfo(nil).preferHighDynamicRange)
        XCTAssertFalse(KingfisherParsedOptionsInfo(nil).imageCreatingOptions.prefersHighDynamicRange)

        let options = KingfisherParsedOptionsInfo([.preferHighDynamicRange])
        XCTAssertTrue(options.preferHighDynamicRange)
        XCTAssertTrue(options.imageCreatingOptions.prefersHighDynamicRange)

        XCTAssertTrue(KF.url(testURLs[0]).preferHighDynamicRange().options.preferHighDynamicRange)
        XCTAssertFalse(KF.url(testURLs[0]).preferHighDynamicRange().preferHighDynamicRange(false).options.preferHighDynamicRange)
    }

    func testCacheIdentifierIsUnchangedWithoutOption() {
        var options = KingfisherParsedOptionsInfo(nil)
        XCTAssertEqual(options.cacheProcessorIdentifier, "")
        options.processor = RoundCornerImageProcessor(cornerRadius: 4)
        XCTAssertEqual(options.cacheProcessorIdentifier, options.processor.identifier)
        XCTAssertEqual(options.cacheProcessorIdentifier(for: ""), "")
    }

    func testCacheIdentifierIsMarkedWithOption() {
        var options = KingfisherParsedOptionsInfo([.preferHighDynamicRange])
        let defaultIdentifier = options.cacheProcessorIdentifier
        XCTAssertFalse(defaultIdentifier.isEmpty)
        options.processor = RoundCornerImageProcessor(cornerRadius: 4)
        XCTAssertNotEqual(options.cacheProcessorIdentifier, options.processor.identifier)
        XCTAssertNotEqual(options.cacheProcessorIdentifier, defaultIdentifier)
        XCTAssertTrue(options.cacheProcessorIdentifier.hasPrefix(options.processor.identifier))
    }

    // MARK: - Decoding

    func testDecodingWithoutOptionIsNotMarked() throws {
        let data = Data(fileName: "hdr-gainmap.jpg")
        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: .init()))
        XCTAssertFalse(image.kf.prefersHighDynamicRange)
    }

    func testDecodingGainMapImageWithOption() throws {
        let data = Data(fileName: "hdr-gainmap.jpg")
        var options = ImageCreatingOptions(scale: 2)
        options.prefersHighDynamicRange = true

        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options))

        XCTAssertTrue(image.kf.prefersHighDynamicRange)
        #if !os(macOS)
        XCTAssertEqual(image.scale, 2)
        #endif
        if HDRTestImage.canDecodeGainMapToHDR {
            XCTAssertTrue(image.kf.isHighDynamicRange)
        }
    }

    // A system that cannot apply gain maps, such as the simulators, must still give the regular image, not an
    // empty one.
    func testDecodingGainMapImageWithOptionHasPixels() throws {
        let data = Data(fileName: "hdr-gainmap.jpg")
        var options = ImageCreatingOptions(scale: 3)
        options.prefersHighDynamicRange = true

        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options))

        try HDRTestImage.assertHasRightPixel(of: image)
    }

    func testDownsamplingGainMapImageWithOptionHasPixels() throws {
        let data = Data(fileName: "hdr-gainmap.heic")
        let processor = DownsamplingImageProcessor(size: CGSize(width: 8, height: 8))

        let image = try XCTUnwrap(processor.process(item: .data(data), options: .init([.preferHighDynamicRange])))

        try HDRTestImage.assertHasRightPixel(of: image)
    }

    func testDecodingNativeHDRImageWithOption() throws {
        let data = try XCTUnwrap(try HDRTestImage.hdrImage().kf.pngRepresentation())
        var options = ImageCreatingOptions()
        options.prefersHighDynamicRange = true

        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options))

        XCTAssertTrue(image.kf.isHighDynamicRange)
        XCTAssertTrue(image.kf.prefersHighDynamicRange)
    }

    func testDecodingGIFWithOptionKeepsAnimatedImage() throws {
        var options = ImageCreatingOptions()
        options.prefersHighDynamicRange = true
        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: testImageGIFData, options: options))
        XCTAssertEqual(image.kf.gifRepresentation(), testImageGIFData)
    }

    func testDownsamplingWithOption() throws {
        try XCTSkipUnless(HDRTestImage.canDecodeGainMapToHDR, "This platform cannot apply gain maps.")
        let data = Data(fileName: "hdr-gainmap.heic")
        let processor = DownsamplingImageProcessor(size: CGSize(width: 8, height: 8))

        let sdr = try XCTUnwrap(processor.process(item: .data(data), options: .init(nil)))
        let hdr = try XCTUnwrap(processor.process(item: .data(data), options: .init([.preferHighDynamicRange])))

        XCTAssertFalse(sdr.kf.isHighDynamicRange)
        XCTAssertFalse(sdr.kf.prefersHighDynamicRange)
        XCTAssertTrue(hdr.kf.isHighDynamicRange)
        XCTAssertTrue(hdr.kf.prefersHighDynamicRange)
        XCTAssertEqual(hdr.kf.cgImage?.width, 8)
    }

    // MARK: - Decoded

    func testDecodedKeepsHDRContentOfMarkedImage() throws {
        let image = try HDRTestImage.hdrImage(layout: .defaultOrderOpaque)
        image.kf.prefersHighDynamicRange = true

        let decoded = image.kf.decoded

        XCTAssertTrue(decoded.kf.prefersHighDynamicRange)
        let cgImage = try XCTUnwrap(decoded.kf.cgImage)
        XCTAssertTrue(cgImage.usesHighDynamicRangeTransferFunction)
        XCTAssertTrue(cgImage.isSupportedByGainMapEncoder, "The decoded image can be stored with a gain map")
        let left = try HDRTestImage.linearPixel(of: cgImage, x: 2, y: 8)
        XCTAssertEqual(left[0], HDRTestImage.leftPixel[0], accuracy: 0.1)
    }

    func testDecodedKeepsOrientationOfMarkedImage() throws {
        #if os(macOS)
        throw XCTSkip("Orientation is a UIKit property.")
        #else
        let cgImage = try HDRTestImage.hdrCGImage(width: 8, height: 4)
        let image = UIImage(cgImage: cgImage, scale: 2, orientation: .right)
        image.kf.prefersHighDynamicRange = true

        let decoded = image.kf.decoded

        XCTAssertEqual(decoded.imageOrientation, .right)
        XCTAssertEqual(decoded.scale, 2)
        XCTAssertEqual(decoded.size, image.size)
        #endif
    }

    #if !os(macOS)
    // `normalized` redraws an oriented image. For a marked HDR image, it must keep the HDR content.
    func testNormalizedKeepsHDRContentOfOrientedMarkedImage() throws {
        for layout in [HDRTestImage.Layout.littleEndianOpaque, .littleEndianTranslucent] {
            let image = try orientedMarkedHDRImage(layout: layout)

            let normalized = image.kf.normalized

            XCTAssertEqual(normalized.imageOrientation, .up)
            XCTAssertEqual(normalized.size, image.size)
            XCTAssertEqual(normalized.scale, image.scale)
            XCTAssertTrue(normalized.kf.prefersHighDynamicRange)
            try assertHDRContent(of: normalized)
        }
    }

    func testSerializerKeepsHDRContentOfOrientedMarkedImage() throws {
        for layout in [HDRTestImage.Layout.littleEndianOpaque, .littleEndianTranslucent] {
            let image = try orientedMarkedHDRImage(layout: layout)
            for original in [Data(fileName: "hdr-gainmap.jpg"), nil] {
                let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))
                var options = ImageCreatingOptions(scale: image.scale)
                options.prefersHighDynamicRange = true
                let decoded = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options))

                XCTAssertEqual(decoded.size, image.size)
                try assertHDRContent(of: decoded)
            }
        }
    }

    func testDownsamplingImageKeepsHDRContentOfOrientedMarkedImage() throws {
        let image = try orientedMarkedHDRImage(layout: .littleEndianOpaque)
        let processor = DownsamplingImageProcessor(size: CGSize(width: 4, height: 8))

        let result = try XCTUnwrap(processor.process(item: .image(image), options: .init([.preferHighDynamicRange])))

        XCTAssertGreaterThan(result.size.height, result.size.width, "The orientation is applied")
        try assertHDRContent(of: result)
    }

    func testNormalizedIsUnchangedForUnmarkedOrientedImage() throws {
        let cgImage = try HDRTestImage.hdrCGImage(width: 16, height: 8)
        let image = UIImage(cgImage: cgImage, scale: 2, orientation: .right)

        let normalized = image.kf.normalized

        XCTAssertFalse(normalized.kf.prefersHighDynamicRange)
        XCTAssertEqual(normalized.imageOrientation, .up)
    }

    private func orientedMarkedHDRImage(layout: HDRTestImage.Layout) throws -> UIImage {
        let cgImage = try HDRTestImage.hdrCGImage(width: 16, height: 8, layout: layout)
        let image = UIImage(cgImage: cgImage, scale: 2, orientation: .right)
        image.kf.prefersHighDynamicRange = true
        XCTAssertEqual(image.size, CGSize(width: 4, height: 8))
        return image
    }

    /// The image keeps the HDR transfer function and has pixels brighter than the SDR white.
    private func assertHDRContent(of image: UIImage, file: StaticString = #filePath, line: UInt = #line) throws {
        let cgImage = try XCTUnwrap(image.kf.cgImage, file: file, line: line)
        XCTAssertTrue(cgImage.usesHighDynamicRangeTransferFunction, "Not HDR: \(cgImage)", file: file, line: line)
        var brightest: Float = 0
        for y in 0..<cgImage.height {
            for x in 0..<cgImage.width {
                brightest = max(brightest, try HDRTestImage.linearPixel(of: cgImage, x: x, y: y)[0])
            }
        }
        XCTAssertGreaterThan(brightest, 2, "No pixel is brighter than the SDR white", file: file, line: line)
    }
    #endif

    func testDecodedIsUnchangedForUnmarkedImage() throws {
        let image = try HDRTestImage.hdrImage(layout: .defaultOrderOpaque)

        let decoded = image.kf.decoded

        XCTAssertFalse(decoded.kf.prefersHighDynamicRange)
    }

    // MARK: - Cache

    func testSerializerUsesGainMapForMarkedImage() throws {
        try XCTSkipUnless(HDRTestImage.canEncodeGainMap(type: .heic), "Gain map encoding is not available.")
        let original = Data(fileName: "hdr-gainmap.heic")
        let image = try HDRTestImage.hdrImage()
        image.kf.prefersHighDynamicRange = true

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertTrue(HDRTestImage.containsGainMap(data))
    }

    // An 8-bit JPEG would band an HDR image. A marked HDR image that cannot get a gain map is stored as 16-bit PNG.
    func testSerializerUsesPNGForMarkedHDRImageWithoutGainMapEncoding() throws {
        let original = Data(fileName: "hdr-gainmap.jpg")
        let image = try HDRTestImage.hdrImage(layout: .littleEndianTranslucent)
        image.kf.prefersHighDynamicRange = true

        let data = try XCTUnwrap(DefaultCacheSerializer.default.data(with: image, original: original))

        XCTAssertEqual(HDRTestImage.typeIdentifier(of: data), UTType.png.identifier)
        let decoded = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: .init()))
        XCTAssertTrue(decoded.kf.isHighDynamicRange)
        XCTAssertEqual(decoded.kf.cgImage?.bitsPerComponent, 16)
    }

    func testSerializerKeepsJPEGForMarkedSDRImage() throws {
        let original = try HDRTestImage.sdrData(type: .jpeg)
        let image = try HDRTestImage.sdrImage()
        image.kf.prefersHighDynamicRange = true

        let data = DefaultCacheSerializer.default.data(with: image, original: original)

        XCTAssertEqual(data, image.kf.jpegRepresentation(compressionQuality: 1.0))
    }

    func testCacheProcessorIdentifierRemovesHDREntry() async throws {
        let url = testURLs[0]
        stub(url, data: Data(fileName: "hdr-gainmap.jpg"))
        _ = try await manager.retrieveImage(with: url, options: [.preferHighDynamicRange])
        let identifier = KingfisherParsedOptionsInfo([.preferHighDynamicRange]).cacheProcessorIdentifier
        XCTAssertTrue(manager.cache.isCached(forKey: url.cacheKey, processorIdentifier: identifier))
        XCTAssertFalse(manager.cache.isCached(forKey: url.cacheKey))

        await withCheckedContinuation { continuation in
            manager.cache.removeImage(forKey: url.cacheKey, processorIdentifier: identifier) {
                continuation.resume()
            }
        }

        XCTAssertFalse(manager.cache.isCached(forKey: url.cacheKey, processorIdentifier: identifier))
    }

    func testOptionUsesSeparateCacheEntries() async throws {
        let url = testURLs[0]
        let stub = stub(url, data: Data(fileName: "hdr-gainmap.jpg"))

        let sdr = try await manager.retrieveImage(with: url)
        XCTAssertEqual(sdr.cacheType, .none)
        XCTAssertFalse(sdr.image.kf.prefersHighDynamicRange)

        let hdr = try await manager.retrieveImage(with: url, options: [.preferHighDynamicRange])
        XCTAssertEqual(hdr.cacheType, .none, "An SDR image in the cache must not be used for an HDR request")
        XCTAssertTrue(hdr.image.kf.prefersHighDynamicRange)
        XCTAssertEqual(stub.requestCount, 2)

        let hdrAgain = try await manager.retrieveImage(with: url, options: [.preferHighDynamicRange])
        XCTAssertEqual(hdrAgain.cacheType, .memory)
        XCTAssertTrue(hdrAgain.image.kf.prefersHighDynamicRange)

        manager.cache.clearMemoryCache()
        let sdrFromDisk = try await manager.retrieveImage(with: url)
        XCTAssertEqual(sdrFromDisk.cacheType, .disk)
        XCTAssertFalse(sdrFromDisk.image.kf.prefersHighDynamicRange)
        let hdrFromDisk = try await manager.retrieveImage(with: url, options: [.preferHighDynamicRange])
        XCTAssertEqual(hdrFromDisk.cacheType, .disk)
        XCTAssertTrue(hdrFromDisk.image.kf.prefersHighDynamicRange)
    }

    func testOptionUsesSeparateImagesForSharedDownload() async throws {
        let url = testURLs[0]
        let stub = heldStub(url, data: Data(fileName: "hdr-gainmap.jpg"))
        let manager = self.manager!

        async let sdr = manager.retrieveImage(with: url)
        async let hdr = manager.retrieveImage(with: url, options: [.preferHighDynamicRange])
        await stub.waitForRequest()
        stub.release()

        let (sdrResult, hdrResult) = try await (sdr, hdr)
        XCTAssertEqual(stub.requestCount, 1, "Both requests share one download")
        XCTAssertFalse(sdrResult.image.kf.prefersHighDynamicRange)
        XCTAssertTrue(hdrResult.image.kf.prefersHighDynamicRange)
    }

    func testOptionUsesSeparateOriginalCacheEntries() async throws {
        let url = testURLs[0]
        stub(url, data: Data(fileName: "hdr-gainmap.jpg"))
        let processor = RoundCornerImageProcessor(cornerRadius: 2)

        _ = try await manager.retrieveImage(with: url)
        let hdr = try await manager.retrieveImage(with: url, options: [.preferHighDynamicRange, .processor(processor)])

        XCTAssertEqual(hdr.cacheType, .none, "The SDR original must not be processed for an HDR request")
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
        /// Little-endian 16-bit float components, no alpha.
        case littleEndianFloatOpaque
        /// Three little-endian 32-bit float components per pixel (96 bits), no alpha.
        case floatRGB
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
        if layout == .floatRGB {
            return try floatRGBCGImage(from: linear, space: space)
        }
        let bitmapInfo: UInt32
        switch layout {
        case .littleEndianOpaque:
            bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        case .defaultOrderOpaque:
            bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
        case .littleEndianTranslucent:
            bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        case .littleEndianFloatOpaque:
            bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue |
                CGBitmapInfo.floatComponents.rawValue |
                CGBitmapInfo.byteOrder16Little.rawValue
        case .floatRGB:
            preconditionFailure("Handled above.")
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

    // A bitmap context cannot have three channels, so draw into four 32-bit float channels and drop the fourth.
    private static func floatRGBCGImage(from image: CGImage, space: CGColorSpace) throws -> CGImage {
        let width = image.width, height = image.height
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 32,
            bytesPerRow: width * 16,
            space: space,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue |
                CGBitmapInfo.floatComponents.rawValue |
                CGBitmapInfo.byteOrder32Little.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let rgba = try XCTUnwrap(context.data).bindMemory(to: Float.self, capacity: width * height * 4)
        var rgb = [Float](repeating: 0, count: width * height * 3)
        for pixel in 0..<(width * height) {
            for channel in 0..<3 {
                rgb[pixel * 3 + channel] = rgba[pixel * 4 + channel]
            }
        }
        let data = rgb.withUnsafeBufferPointer { Data(buffer: $0) }
        return try XCTUnwrap(CGImage(
            width: width,
            height: height,
            bitsPerComponent: 32,
            bitsPerPixel: 96,
            bytesPerRow: width * 12,
            space: space,
            bitmapInfo: CGBitmapInfo(rawValue:
                CGImageAlphaInfo.none.rawValue |
                CGBitmapInfo.floatComponents.rawValue |
                CGBitmapInfo.byteOrder32Little.rawValue
            ),
            provider: try XCTUnwrap(CGDataProvider(data: data as CFData)),
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
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

    /// Checks that the right half of an image made from ``hdrCGImage`` or the gain map fixtures is not empty.
    ///
    /// The values are compared loosely: an SDR image from a gain map file has its own tone mapping.
    static func assertHasRightPixel(of image: KFCrossPlatformImage, file: StaticString = #filePath, line: UInt = #line) throws {
        let cgImage = try XCTUnwrap(image.kf.cgImage, file: file, line: line)
        let pixel = try linearPixel(of: cgImage, x: cgImage.width * 3 / 4, y: cgImage.height / 2)
        XCTAssertGreaterThan(pixel[0], 0.1, "The image is empty: \(pixel)", file: file, line: line)
    }

    /// Decodes `data` as HDR, applying a gain map if there is one.
    static func decodeToHDR(_ data: Data) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let options = [kCGImageSourceDecodeRequest: kCGImageSourceDecodeToHDR] as CFDictionary
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, options))
    }

    /// Whether the system applies gain maps when it decodes an image. The simulators do not.
    static var canDecodeGainMapToHDR: Bool {
        guard let image = try? decodeToHDR(Data(fileName: "hdr-gainmap.heic")) else { return false }
        return image.usesHighDynamicRangeTransferFunction
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
