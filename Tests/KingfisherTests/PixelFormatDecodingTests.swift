import Foundation
import XCTest
@testable import Kingfisher

final class PixelFormatDecodingTests: XCTestCase {
    private struct Sample {
        let fileName: String
        let expectedBitsAfterDecoding: Int
        let expectedColorSpaceName: String?
    }
    
    private let samples: [Sample] = [
        Sample(fileName: "gradient-8b-srgb-opaque.png", expectedBitsAfterDecoding: 8, expectedColorSpaceName: CGColorSpace.sRGB as String),
        Sample(fileName: "gradient-8b-srgb-alpha.png", expectedBitsAfterDecoding: 8, expectedColorSpaceName: CGColorSpace.sRGB as String),
        Sample(fileName: "gradient-8b-displayp3-alpha.png", expectedBitsAfterDecoding: 8, expectedColorSpaceName: CGColorSpace.displayP3 as String),
        Sample(fileName: "gradient-8b-gray.png", expectedBitsAfterDecoding: 8, expectedColorSpaceName: CGColorSpace.genericGrayGamma2_2 as String),
        Sample(fileName: "gradient-10b-srgb-opaque.heic", expectedBitsAfterDecoding: 16, expectedColorSpaceName: CGColorSpace.sRGB as String),
        Sample(fileName: "gradient-10b-srgb-alpha.heic", expectedBitsAfterDecoding: 16, expectedColorSpaceName: CGColorSpace.sRGB as String),
        Sample(fileName: "gradient-10b-displayp3-alpha.heic", expectedBitsAfterDecoding: 16, expectedColorSpaceName: CGColorSpace.displayP3 as String),
        Sample(fileName: "gradient-16b-srgb-alpha.png", expectedBitsAfterDecoding: 16, expectedColorSpaceName: CGColorSpace.sRGB as String),
        Sample(fileName: "gradient-16b-gray.png", expectedBitsAfterDecoding: 16, expectedColorSpaceName: CGColorSpace.genericGrayGamma2_2 as String)
    ]
    
    #if os(macOS)
    func testDecodingRedrawsIndexedColorSpaceImageToDeviceRGB() {
        // Issue #2467: On macOS, images with an indexed color space
        // (CGColorSpaceModel.indexed) could crash or fail when `.backgroundDecode(true)`
        // (or equivalently, `image.kf.decoded`) tried to create a destination
        // CGBitmapContext using the source's indexed color space, which is not
        // supported as a bitmap context color space.
        let data = Data(fileName: "gradient-8b-indexed.png")
        let options = ImageCreatingOptions()
        guard let image = KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options) else {
            XCTFail("Failed to construct indexed-color image")
            return
        }
        // Sanity check the fixture really is indexed on load.
        XCTAssertEqual(image.kf.cgImage?.colorSpace?.model, .indexed, "Fixture should load as an indexed-color CGImage")

        // Must not crash. Must produce a usable CGImage.
        let decoded = image.kf.decoded
        guard let cgImage = decoded.kf.cgImage else {
            XCTFail("Decoded image lost its CGImage for indexed-color source")
            return
        }
        // The destination bitmap context must not retain the indexed color space.
        XCTAssertNotEqual(cgImage.colorSpace?.model, .indexed, "Decoded image must not keep an indexed color space")
        XCTAssertEqual(cgImage.width, image.kf.cgImage?.width)
        XCTAssertEqual(cgImage.height, image.kf.cgImage?.height)
    }

    func testDrawingSixteenBitGrayImageWithAlpha() throws {
        // A 16-bit gray PNG with alpha loads as a gray color space with alpha at 16 bits per component.
        // `CGBitmapContext` does not support that combination as a destination, so every redraw on macOS
        // (`kf.decoded`, `.backgroundDecode(true)` and the drawing processors) failed to create its context.
        let data = try sixteenBitGrayPNGWithAlpha()
        let image = try XCTUnwrap(KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: ImageCreatingOptions()))
        let source = try XCTUnwrap(image.kf.cgImage)
        XCTAssertEqual(source.colorSpace?.model, .monochrome, "Fixture should load as a gray CGImage")
        XCTAssertEqual(source.bitsPerComponent, 16, "Fixture should load at 16 bits per component")
        XCTAssertEqual(source.alphaInfo, .last, "Fixture should load with alpha")

        let white: [UInt8] = [255, 255, 255, 255]
        let clear: [UInt8] = [0, 0, 0, 0]
        let decoded = image.kf.decoded
        XCTAssertNotIdentical(decoded, image, "Decoding should redraw the image")
        let decodedCGImage = try XCTUnwrap(decoded.kf.cgImage)
        XCTAssertEqual(decodedCGImage.bitsPerComponent, 16)
        XCTAssertEqual(decoded.pixelRows(), (0..<8).map { y in Array(repeating: y < 4 ? white : clear, count: 8) })

        let resized = image.kf.resize(to: CGSize(width: 4, height: 4))
        XCTAssertEqual(resized.kf.cgImage?.width, 4)
        XCTAssertEqual(resized.kf.cgImage?.height, 4)
        XCTAssertEqual(resized.rgbaPixel(x: 0, y: 0), white)
        XCTAssertEqual(resized.rgbaPixel(x: 3, y: 3), clear)
    }

    // An 8x8 PNG in 16-bit gray with alpha: opaque white in the top half, transparent in the bottom half.
    private func sixteenBitGrayPNGWithAlpha() throws -> Data {
        let width = 8, height = 8
        let bytesPerRow = width * 4
        let bytes: [UInt8] = (0..<height).flatMap { y in
            Array(repeating: y < height / 2 ? [0xFF, 0xFF, 0xFF, 0xFF] : [0x00, 0x00, 0x00, 0x00], count: width).flatMap { $0 }
        }
        let cgImage = try XCTUnwrap(CGImage(
            width: width,
            height: height,
            bitsPerComponent: 16,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGBitmapInfo.byteOrder16Big.rawValue),
            provider: try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData)),
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, cgImage, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }
    #endif

    func testDecodingSupportsVariousPixelFormats() {
        for sample in samples {
            let data = Data(fileName: sample.fileName)
            let options = ImageCreatingOptions()
            guard let image = KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options) else {
                XCTFail("Failed to construct image for \(sample.fileName)")
                continue
            }
            let decoded = image.kf.decoded
            guard let cgImage = decoded.kf.cgImage else {
                XCTFail("Decoded image lost CGImage for \(sample.fileName)")
                continue
            }
            #if os(macOS)
            if sample.expectedBitsAfterDecoding > 8 {
                XCTAssertNotIdentical(decoded, image, "Decoding should redraw \(sample.fileName)")
            }
            XCTAssertEqual(cgImage.bitsPerComponent, sample.expectedBitsAfterDecoding, "Unexpected bitsPerComponent for \(sample.fileName)")
            if let expectedColorSpaceName = sample.expectedColorSpaceName {
                XCTAssertEqual(cgImage.colorSpace?.name as String?, expectedColorSpaceName, "Unexpected color space for \(sample.fileName)")
            } else {
                XCTFail("expectedColorSpaceName not existing, but needed for \(sample.fileName)")
            }
            #else
            // On iOS/tvOS/visionOS, `decoded` may go through `preparingForDisplay`,
            // which can keep 10-bit HEIC as 10 bpc or promote it to 16 bpc depending
            // on the runtime display/decode pipeline.
            if sample.fileName.contains("gradient-10b") {
                XCTAssertTrue(
                    cgImage.bitsPerComponent == 10 || cgImage.bitsPerComponent == 16,
                    "Unexpected bitsPerComponent for \(sample.fileName): \(cgImage.bitsPerComponent)"
                )
            } else {
                XCTAssertEqual(
                    cgImage.bitsPerComponent,
                    sample.expectedBitsAfterDecoding,
                    "Unexpected bitsPerComponent for \(sample.fileName)"
                )
            }
            #endif
        }
    }
}
