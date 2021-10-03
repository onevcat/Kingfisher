//
//  ImageProcessorTests.swift
//  Kingfisher
//
//  Created by onevcat on 2019/03/02.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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

class ImageProcessorTests: XCTestCase {

    // Issue 1125. https://github.com/onevcat/Kingfisher/issues/1125
    func testDownsamplingSizes() {
        XCTAssertEqual(testImage.size, CGSize(width: 64, height: 64))

        let emptyOption = KingfisherParsedOptionsInfo(nil)

        let targetSize = CGSize(width: 20, height: 40)
        let downsamplingProcessor = DownsamplingImageProcessor(size: targetSize)

        let resultFromData = downsamplingProcessor.process(item: .data(testImageData), options: emptyOption)
        XCTAssertEqual(resultFromData!.size, CGSize(width: 40, height: 40))

        let resultFromImage = downsamplingProcessor.process(item: .image(testImage), options: emptyOption)
        XCTAssertEqual(resultFromImage!.size, CGSize(width: 40, height: 40))

    }

    func testProcessorConcating() {
        let p1 = BlurImageProcessor(blurRadius: 10)
        let p2 = RoundCornerImageProcessor(cornerRadius: 10)
        let p3 = TintImageProcessor(tint: .blue)

        let two = p1 |> p2
        let three = p1 |> p2 |> p3

        XCTAssertNotNil(two)
        XCTAssertNotNil(three)
    }
    
    func testParsingColorRGBA() {
        let sRGB = KFCrossPlatformColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 0.8)
        let rgba = sRGB.rgba
        XCTAssertEqual(rgba.r, 0.5, accuracy: 0.01)
        XCTAssertEqual(rgba.g, 0.6, accuracy: 0.01)
        XCTAssertEqual(rgba.b, 0.7, accuracy: 0.01)
        XCTAssertEqual(rgba.a, 0.8, accuracy: 0.01)
        
        let extended = KFCrossPlatformColor(displayP3Red: 0, green: 1, blue: 0, alpha: 0.8)
        let rgbaExt = extended.rgba
        // extended sRGB
        XCTAssertTrue(rgbaExt.r < 0)
        XCTAssertTrue(rgbaExt.g > 1)
        XCTAssertTrue(rgbaExt.b < 0)
        XCTAssertEqual(rgbaExt.a, 0.8)
        
        let blackWhite = KFCrossPlatformColor(white: 0.3, alpha: 1.0)
        let rgbaBlackWhite = blackWhite.rgba
        XCTAssertEqual(rgbaBlackWhite.r, 0.3, accuracy: 0.01)
        XCTAssertEqual(rgbaBlackWhite.g, 0.3, accuracy: 0.01)
        XCTAssertEqual(rgbaBlackWhite.b, 0.3, accuracy: 0.01)
        XCTAssertEqual(rgbaBlackWhite.a, 1.0, accuracy: 0.01)
    }
}
