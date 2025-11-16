import Foundation
import XCTest
@testable import Kingfisher

final class PixelFormatDecodingTests: XCTestCase {
    private struct Sample {
        let fileName: String
        let expectedBitsOnMac: Int
        #if os(macOS)
        let expectedColorSpaceName: String
        #endif
    }
    
    #if os(macOS)
    private lazy var samples: [Sample] = [
        Sample(
            fileName: "gradient-8b-srgb-opaque.png",
            expectedBitsOnMac: 8,
            expectedColorSpaceName: CGColorSpace.sRGB as String
        ),
        Sample(
            fileName: "gradient-8b-srgb-alpha.png",
            expectedBitsOnMac: 8,
            expectedColorSpaceName: CGColorSpace.sRGB as String
        ),
        Sample(
            fileName: "gradient-8b-displayp3-alpha.png",
            expectedBitsOnMac: 8,
            expectedColorSpaceName: CGColorSpace.displayP3 as String
        ),
        Sample(
            fileName: "gradient-8b-gray.png",
            expectedBitsOnMac: 8,
            expectedColorSpaceName: CGColorSpace.genericGrayGamma2_2 as String
        ),
        Sample(
            fileName: "gradient-10b-srgb-opaque.heic",
            expectedBitsOnMac: 16,
            expectedColorSpaceName: CGColorSpace.sRGB as String
        ),
        Sample(
            fileName: "gradient-10b-srgb-alpha.heic",
            expectedBitsOnMac: 16,
            expectedColorSpaceName: CGColorSpace.sRGB as String
        ),
        Sample(
            fileName: "gradient-10b-displayp3-alpha.heic",
            expectedBitsOnMac: 16,
            expectedColorSpaceName: CGColorSpace.displayP3 as String
        ),
        Sample(
            fileName: "gradient-16b-srgb-alpha.png",
            expectedBitsOnMac: 16,
            expectedColorSpaceName: CGColorSpace.sRGB as String
        ),
        Sample(
            fileName: "gradient-16b-gray.png",
            expectedBitsOnMac: 16,
            expectedColorSpaceName: CGColorSpace.genericGrayGamma2_2 as String
        )
    ]
    #else
    private lazy var samples: [Sample] = [
        Sample(fileName: "gradient-8b-srgb-opaque.png", expectedBitsOnMac: 8),
        Sample(fileName: "gradient-8b-srgb-alpha.png", expectedBitsOnMac: 8),
        Sample(fileName: "gradient-8b-displayp3-alpha.png", expectedBitsOnMac: 8),
        Sample(fileName: "gradient-8b-gray.png", expectedBitsOnMac: 8),
        Sample(fileName: "gradient-10b-srgb-opaque.heic", expectedBitsOnMac: 16),
        Sample(fileName: "gradient-10b-srgb-alpha.heic", expectedBitsOnMac: 16),
        Sample(fileName: "gradient-10b-displayp3-alpha.heic", expectedBitsOnMac: 16),
        Sample(fileName: "gradient-16b-srgb-alpha.png", expectedBitsOnMac: 16),
        Sample(fileName: "gradient-16b-gray.png", expectedBitsOnMac: 16)
    ]
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
            if sample.expectedBitsOnMac > 8 {
                XCTAssertNotIdentical(decoded, image, "Decoding should redraw \(sample.fileName)")
            }
            XCTAssertEqual(cgImage.bitsPerComponent, sample.expectedBitsOnMac, "Unexpected bitsPerComponent for \(sample.fileName)")
            XCTAssertEqual(cgImage.colorSpace?.name as String?, sample.expectedColorSpaceName, "Unexpected color space for \(sample.fileName)")
            #else
            XCTAssertGreaterThanOrEqual(cgImage.bitsPerComponent, 8, "bitsPerComponent lower than expected for \(sample.fileName)")
            #endif
        }
    }
}
