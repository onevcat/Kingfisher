//
//  ImageProcessorTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/08/30.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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
@testable import Kingfisher

#if os(macOS)
import AppKit
#endif

class ImageProcessorTests: XCTestCase {
    
    let imageNames = ["kingfisher.jpg", "onevcat.jpg", "unicorn.png"]
    var nonPNGIamgeNames: [String] {
        return imageNames.filter { !$0.contains(".png") }
    }
    
    func imageData(noAlpha: Bool = false) -> [Data] {
        return noAlpha ? nonPNGIamgeNames.map { Data(fileName: $0) } : imageNames.map { Data(fileName: $0) }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRenderEqual() {
        let image1 = Image(data: testImageData as Data)!
        let image2 = Image(data: testImagePNGData)!
        
        XCTAssertTrue(image1.renderEqual(to: image2))
    }

    #if !os(macOS)
    func testBlendProcessor() {
        let p = BlendImageProcessor(blendMode: .darken, alpha: 1.0, backgroundColor: .lightGray)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.BlendImageProcessor(\(CGBlendMode.darken.rawValue),\(p.alpha))_#aaaaaaff")
        checkProcessor(p, with: "blend-\(CGBlendMode.darken.rawValue)")
    }
    #endif

    #if os(macOS)
    func testCompositingProcessor() {
        let p = CompositingImageProcessor(compositingOperation: .darken, alpha: 1.0, backgroundColor: .lightGray)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.CompositingImageProcessor(\(NSCompositingOperation.darken.rawValue),\(p.alpha))_\(Color.lightGray.hex)")
        checkProcessor(p, with: "compositing-\(NSCompositingOperation.darken.rawValue)")
    }
    #endif
    
    func testRoundCornerProcessor() {
        let p = RoundCornerImageProcessor(cornerRadius: 40)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.RoundCornerImageProcessor(40.0)")
        checkProcessor(p, with: "round-corner-40")
    }

    func testRoundCornerWithResizingProcessor() {
        let p = RoundCornerImageProcessor(cornerRadius: 60, targetSize: CGSize(width: 100, height: 100))
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.RoundCornerImageProcessor(60.0_(100.0, 100.0))")
        checkProcessor(p, with: "round-corner-60-resize-100")
    }
    
    func testRoundCornerWithRectCornerProcessor() {
        let p1 = RoundCornerImageProcessor(cornerRadius: 40, roundingCorners: [.topLeft, .topRight])
        XCTAssertEqual(p1.identifier, "com.onevcat.Kingfisher.RoundCornerImageProcessor(40.0_corner(3))")
        checkProcessor(p1, with: "round-corner-40-corner-3")
        
        let p2 = RoundCornerImageProcessor(cornerRadius: 40, roundingCorners: [.bottomLeft, .bottomRight])
        XCTAssertEqual(p2.identifier, "com.onevcat.Kingfisher.RoundCornerImageProcessor(40.0_corner(12))")
        checkProcessor(p2, with: "round-corner-40-corner-12")
        
        let p3 = RoundCornerImageProcessor(cornerRadius: 40, roundingCorners: .all)
        XCTAssertEqual(p3.identifier, "com.onevcat.Kingfisher.RoundCornerImageProcessor(40.0)")
        checkProcessor(p3, with: "round-corner-40")
    }

    func testResizingProcessor() {
        let p = ResizingImageProcessor(referenceSize: CGSize(width: 120, height: 120))
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.ResizingImageProcessor((120.0, 120.0))")
        checkProcessor(p, with: "resize-120")
    }
    
    func testResizingProcessorWithContentMode() {
        let p1 = ResizingImageProcessor(referenceSize: CGSize(width: 240, height: 60), mode: .aspectFill)
        XCTAssertEqual(p1.identifier, "com.onevcat.Kingfisher.ResizingImageProcessor((240.0, 60.0), aspectFill)")
        checkProcessor(p1, with: "resize-240-60-aspectFill")
        
        let p2 = ResizingImageProcessor(referenceSize: CGSize(width: 240, height: 60), mode: .aspectFit)
        XCTAssertEqual(p2.identifier, "com.onevcat.Kingfisher.ResizingImageProcessor((240.0, 60.0), aspectFit)")
        checkProcessor(p2, with: "resize-240-60-aspectFit")
    }
    
    func testBlurProcessor() {
        let p = BlurImageProcessor(blurRadius: 10)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.BlurImageProcessor(10.0)")
        // Alpha convolving would vary due to context. So we do not test blur for PNGs.
        // See results in Resource folder.
        checkProcessor(p, with: "blur-10", noAlpha: true)
    }
    
    func testOverlayProcessor() {
        let p1 = OverlayImageProcessor(overlay: .red)
        XCTAssertEqual(p1.identifier, "com.onevcat.Kingfisher.OverlayImageProcessor(\(Color.red.hex)_0.5)")
        checkProcessor(p1, with: "overlay-red")
        
        let p2 = OverlayImageProcessor(overlay: .red, fraction: 0.7)
        XCTAssertEqual(p2.identifier, "com.onevcat.Kingfisher.OverlayImageProcessor(\(Color.red.hex)_0.7)")
        checkProcessor(p2, with: "overlay-red-07")
    }

    func testTintProcessor() {
        let color = Color.yellow.withAlphaComponent(0.2)
        let p = TintImageProcessor(tint: color)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.TintImageProcessor(\(color.hex))")
        checkProcessor(p, with: "tint-yellow-02")
    }

    func testColorControlProcessor() {
        let p = ColorControlsProcessor(brightness: 0, contrast: 1.1, saturation: 1.2, inputEV: 0.7)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.ColorControlsProcessor(0.0_1.1_1.2_0.7)")
        checkProcessor(p, with: "color-control-b00-c11-s12-ev07")
    }
    
    func testBlackWhiteProcessor() {
        let p = BlackWhiteProcessor()
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.BlackWhiteProcessor")
        checkProcessor(p, with: "b&w")
    }

    func testCompositionProcessor() {
        let p = BlurImageProcessor(blurRadius: 4) >> RoundCornerImageProcessor(cornerRadius: 60)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.BlurImageProcessor(4.0)|>com.onevcat.Kingfisher.RoundCornerImageProcessor(60.0)")
        // Alpha convolving would vary due to context. So we do not test blur for PNGs.
        // See results in Resource folder.
        checkProcessor(p, with: "blur-4-round-corner-60", noAlpha: true)
    }
    
    func testCIImageProcessor() {
        let p = TestCIImageProcessor(filter: .tint(Color.yellow.withAlphaComponent(0.2)))
        checkProcessor(p, with: "tint-yellow-02")
    }
    
    func testCroppingImageProcessor() {
        let p = CroppingImageProcessor(size: CGSize(width: 50, height: 50), anchor: CGPoint(x: 0.5, y: 0.5))
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.CroppingImageProcessor((50.0, 50.0)_(0.5, 0.5))")
        checkProcessor(p, with: "cropping-50-50-anchor-center")
    }

    #if os(iOS) || os(tvOS)
    func testImageProcessorRespectOptionScale() {
        let image = testImage
        XCTAssertEqual(image.scale, 1.0)

        let size = CGSize(width: 2, height: 2)

        let processors: [ImageProcessor] = [
            DefaultImageProcessor(),
            RoundCornerImageProcessor(cornerRadius: 1.0, targetSize: size),
            ResizingImageProcessor(referenceSize: size),
            BlurImageProcessor(blurRadius: 1.0),
            OverlayImageProcessor(overlay: .red),
            TintImageProcessor(tint: .red),
            ColorControlsProcessor(brightness: 0, contrast: 0, saturation: 0, inputEV: 0),
            BlackWhiteProcessor(),
            CroppingImageProcessor(size: size)
        ]

        let images = processors.map { $0.process(item: .image(image), options: [.scaleFactor(2.0)]) }
        images.forEach {
            XCTAssertEqual($0!.scale, 2.0)
        }
    }
    #endif
}

struct TestCIImageProcessor: CIImageProcessor {
    let identifier = "com.onevcat.kingfishertest.tint"
    let filter: Filter
}

extension ImageProcessorTests {
    
    func checkProcessor(_ p: ImageProcessor, with suffix: String, noAlpha: Bool = false) {
        
        let specifiedSuffix = getSuffix(with: suffix)
        
        let filteredImageNames = noAlpha ? nonPNGIamgeNames : imageNames
        
        let targetImages = filteredImageNames
            .map { $0.replacingOccurrences(of: ".", with: "-\(specifiedSuffix).") }
            .flatMap { name -> Image? in
                if #available(iOS 11, tvOS 11.0, macOS 10.13, *) {
                    // Look for the version specified target first. Then roll back to base.
                    return Image(fileName: name.replacingOccurrences(of: ".", with: "-iOS11.")) ??
                        Image(fileName: name.replacingOccurrences(of: ".", with: "-macOS1013.")) ??
                        Image(fileName: name)
                }

                return Image(fileName: name)
            }
        
        let resultImages = imageData(noAlpha: noAlpha).flatMap { p.process(item: .data($0), options: []) }
        
        checkImagesEqual(targetImages: targetImages, resultImages: resultImages, for: specifiedSuffix)
    }
    
    func checkImagesEqual(targetImages: [Image], resultImages: [Image], for suffix: String) {
        XCTAssertEqual(targetImages.count, resultImages.count)

        for (i, (resultImage, targetImage)) in zip(resultImages, targetImages).enumerated() {
            guard resultImage.renderEqual(to: targetImage) else {
                let originalName = imageNames[i]
                let excutingName = originalName.replacingOccurrences(of: ".", with: "-\(suffix).")
                XCTFail("Result image is not the same to target. Failed at: \(excutingName)) for \(originalName)")
                let t = targetImage.write("target-\(excutingName)")
                let r = resultImage.write("result-\(excutingName)")
                print("Expected: \(t)")
                print("But Got: \(r)")
                continue
            }
        }
    }
    
    func getSuffix(with ori: String) -> String {
        #if os(macOS)
        return "\(ori)-mac"
        #else
        return ori
        #endif
    }
}


extension ImageProcessorTests {
    //Helper Writer
    func _testWrite() {
        
        let p = BlurImageProcessor(blurRadius: 4) >> RoundCornerImageProcessor(cornerRadius: 60)
        let suffix = "blur-4-round-corner-60-mac"
        let resultImages = imageData().flatMap { p.process(item: .data($0), options: []) }
        for i in 0..<resultImages.count {
            resultImages[i].write(imageNames[i].replacingOccurrences(of: ".", with: "-\(suffix)."))
        }
    }
}
