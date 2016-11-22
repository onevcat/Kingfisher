//
//  ImageProcessorTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/08/30.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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
import Kingfisher

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
        let image1 = Image(data: testImageData! as Data)!
        let image2 = Image(data: testImagePNGData)!
        
        XCTAssertTrue(image1.renderEqual(to: image2))
    }
    
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

    func testResizingProcessor() {
        let p = ResizingImageProcessor(targetSize: CGSize(width: 120, height: 120))
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.ResizingImageProcessor((120.0, 120.0))")
        checkProcessor(p, with: "resize-120")
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
        XCTAssertEqual(p1.identifier, "com.onevcat.Kingfisher.OverlayImageProcessor(#ff0000ff_0.5)")
        checkProcessor(p1, with: "overlay-red")
        
        let p2 = OverlayImageProcessor(overlay: .red, fraction: 0.7)
        XCTAssertEqual(p2.identifier, "com.onevcat.Kingfisher.OverlayImageProcessor(#ff0000ff_0.7)")
        checkProcessor(p2, with: "overlay-red-07")
    }

    func testTintProcessor() {
        let color = Color.yellow.withAlphaComponent(0.2)
        let p = TintImageProcessor(tint: color)
        XCTAssertEqual(p.identifier, "com.onevcat.Kingfisher.TintImageProcessor(#ffff0033)")
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
            .map { Image(fileName: $0) }
        
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
