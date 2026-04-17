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
