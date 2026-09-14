//
//  ImageDrawingTests.swift
//  Kingfisher
//
//  Created by onevcat on 2018/10/26.
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

class ImageDrawingTests: XCTestCase {

    func testImageResizing() {
        let result = testImage.kf.resize(to: CGSize(width: 20, height: 20))
        XCTAssertEqual(result.size, CGSize(width: 20, height: 20))
    }
    
    func testImageCropping() {
        let result = testImage.kf.crop(to: CGSize(width: 20, height: 20), anchorOn: .zero)
        XCTAssertEqual(result.size, CGSize(width: 20, height: 20))
    }
    
    func testImageScaling() {
        XCTAssertEqual(testImage.kf.scale, 1)
        let result = testImage.kf.scaled(to: 2.0)
        #if os(macOS)
        // No scale supported on macOS.
        XCTAssertEqual(result.kf.scale, 1)
        XCTAssertEqual(result.size.height, testImage.size.height)
        #else
        XCTAssertEqual(result.kf.scale, 2)
        XCTAssertEqual(result.size.height, testImage.size.height / 2)
        #endif
    }

    func testImageFlipping() {
        let image = KFCrossPlatformImage.quadrants()
        let red: [UInt8] = [255, 0, 0, 255]
        let green: [UInt8] = [0, 255, 0, 255]
        let blue: [UInt8] = [0, 0, 255, 255]
        let white: [UInt8] = [255, 255, 255, 255]

        assertPixels(of: image, equalTo: [red, green, blue, white])
        assertPixels(of: image.kf.flipped(horizontal: true, vertical: false), equalTo: [green, red, white, blue])
        assertPixels(of: image.kf.flipped(horizontal: false, vertical: true), equalTo: [blue, white, red, green])
        assertPixels(of: image.kf.flipped(horizontal: true, vertical: true), equalTo: [white, blue, green, red])
    }

    func testImageFlippingWithoutDirectionReturnsSameImage() {
        let image = KFCrossPlatformImage.quadrants()
        XCTAssertTrue(image.kf.flipped(horizontal: false, vertical: false) === image)
    }

    func testImageFlippingKeepsScale() {
        #if os(macOS)
        let image = KFCrossPlatformImage.quadrants(blockSize: 2)
        #else
        let image = KFCrossPlatformImage.quadrants(blockSize: 2, scale: 2)
        XCTAssertEqual(image.size, CGSize(width: 2, height: 2))
        #endif

        let result = image.kf.flipped(horizontal: true, vertical: false)
        XCTAssertEqual(result.size, image.size)
        XCTAssertEqual(result.kf.scale, image.kf.scale)
        XCTAssertEqual(result.kf.cgImage?.width, 4)
        XCTAssertEqual(result.kf.cgImage?.height, 4)
        XCTAssertEqual(result.rgbaPixel(x: 0, y: 0), [0, 255, 0, 255])
        XCTAssertEqual(result.rgbaPixel(x: 3, y: 3), [0, 0, 255, 255])
    }

    // Asserts the pixels of a 2x2 image, in the order of top-left, top-right, bottom-left and bottom-right.
    private func assertPixels(
        of image: KFCrossPlatformImage,
        equalTo expected: [[UInt8]],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pixels = [(0, 0), (1, 0), (0, 1), (1, 1)].map { image.rgbaPixel(x: $0.0, y: $0.1) }
        XCTAssertEqual(pixels, expected, file: file, line: line)
    }
}
