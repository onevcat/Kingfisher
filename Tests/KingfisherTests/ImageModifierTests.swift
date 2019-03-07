//
//  ImageModifierTests.swift
//  Kingfisher
//
//  Created by Ethan Gill on 2017/11/29.
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
import Kingfisher

class ImageModifierTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAnyImageModifier() {
        let m = AnyImageModifier { image in
            return image
        }
        let image = Image(data: testImagePNGData)!
        let modifiedImage = m.modify(image)
        XCTAssert(modifiedImage == image)
    }

#if os(iOS) || os(tvOS) || os(watchOS)

    func testRenderingModeImageModifier() {
        let m1 = RenderingModeImageModifier(renderingMode: .alwaysOriginal)
        let image = Image(data: testImagePNGData)!
        let alwaysOriginalImage = m1.modify(image)
        XCTAssert(alwaysOriginalImage.renderingMode == .alwaysOriginal)

        let m2 = RenderingModeImageModifier(renderingMode: .alwaysTemplate)
        let alwaysTemplateImage = m2.modify(image)
        XCTAssert(alwaysTemplateImage.renderingMode == .alwaysTemplate)
    }

    func testFlipsForRightToLeftLayoutDirectionImageModifier() {
        let m = FlipsForRightToLeftLayoutDirectionImageModifier()
        let image = Image(data: testImagePNGData)!
        let modifiedImage = m.modify(image)
        XCTAssert(modifiedImage.flipsForRightToLeftLayoutDirection == true)
    }

    func testAlignmentRectInsetsImageModifier() {
        let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let m = AlignmentRectInsetsImageModifier(alignmentInsets: insets)
        let image = Image(data: testImagePNGData)!
        let modifiedImage = m.modify(image)
        XCTAssert(modifiedImage.alignmentRectInsets == insets)
    }

#endif

}
