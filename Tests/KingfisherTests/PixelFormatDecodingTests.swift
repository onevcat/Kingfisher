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
