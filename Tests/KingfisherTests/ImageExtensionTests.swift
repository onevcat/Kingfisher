//
//  ImageExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/24.
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
import ImageIO
@testable import Kingfisher

class ImageExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testImageFormat() {
        var format: ImageFormat
        format = testImageJEPGData.kf.imageFormat
        XCTAssertEqual(format, ImageFormat.JPEG)
        
        format = testImagePNGData.kf.imageFormat
        XCTAssertEqual(format, ImageFormat.PNG)
        
        format = testImageGIFData.kf.imageFormat
        XCTAssertEqual(format, ImageFormat.GIF)
        
        let raw: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        
        format = Data(bytes: raw).kf.imageFormat
        XCTAssertEqual(format, ImageFormat.unknown)
    }
    
    func testGenerateGIFImage() {
        let image = Kingfisher<Image>.animated(with: testImageGIFData, preloadAll: false)
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        let count = CGImageSourceGetCount(image!.kf.imageSource!.imageRef!)
        XCTAssertEqual(count, 8, "There should be 8 frames.")
#else
        XCTAssertEqual(image!.kf.images!.count, 8, "There should be 8 frames.")
        
        XCTAssertEqualWithAccuracy(image!.kf.duration, 0.8, accuracy: 0.001, "The image duration should be 0.8s")
#endif
    }
    
    func testGIFRepresentation() {
        let image = Kingfisher<Image>.animated(with: testImageGIFData, preloadAll: false)!
        let data = image.kf.gifRepresentation()
        
        XCTAssertNotNil(data, "Data should not be nil")
        XCTAssertEqual(data?.kf.imageFormat, ImageFormat.GIF)
        
        let allLoadImage = Kingfisher<Image>.animated(with: data!, preloadAll: true)!
        let allLoadData = allLoadImage.kf.gifRepresentation()
        XCTAssertNotNil(allLoadData, "Data1 should not be nil")
        XCTAssertEqual(allLoadData?.kf.imageFormat, ImageFormat.GIF)
    }
    
    func testGenerateSingleFrameGIFImage() {
        let image = Kingfisher<Image>.animated(with: testImageSingleFrameGIFData, preloadAll: false)
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        let count = CGImageSourceGetCount(image!.kf.imageSource!.imageRef!)
        XCTAssertEqual(count, 1, "There should be 1 frames.")
#else
        XCTAssertEqual(image!.kf.images!.count, 1, "There should be 1 frames.")
        
        XCTAssertEqual(image!.kf.duration, Double.infinity, "The image duration should be 0 since it is not animated image.")
#endif
    }
    
    func testPreloadAllGIFData() {
        let image = Kingfisher<Image>.animated(with: testImageSingleFrameGIFData, preloadAll: true)!
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        XCTAssertNil(image.kf.imageSource, "Image source should be nil")
#endif
        XCTAssertEqual(image.kf.duration, image.kf.duration)
        XCTAssertEqual(image.kf.images!.count, image.kf.images!.count)
    }
}
