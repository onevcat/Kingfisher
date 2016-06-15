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
        format = testImageJEPGData.kf_imageFormat
        XCTAssertEqual(format, ImageFormat.jpeg)
        
        format = testImagePNGData.kf_imageFormat
        XCTAssertEqual(format, ImageFormat.png)
        
        format = testImageGIFData.kf_imageFormat
        XCTAssertEqual(format, ImageFormat.gif)
        
        let raw = [1, 2, 3, 4, 5, 6, 7, 8]
        format = Data(bytes: UnsafePointer<UInt8>(raw), count: 8) .kf_imageFormat
        XCTAssertEqual(format, ImageFormat.unknown)
    }
    
    func testGenerateGIFImage() {
        let image = Image.kf_animatedImageWithGIFData(gifData: testImageGIFData, preloadAll: false)
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        let count = ImagesCountWithImageSource(image!.kf_imageSource!.imageRef!)
        XCTAssertEqual(count, 8, "There should be 8 frames.")
#else
        XCTAssertEqual(image!.kf_images!.count, 8, "There should be 8 frames.")
        
        XCTAssertEqualWithAccuracy(image!.kf_duration, 0.8, accuracy: 0.001, "The image duration should be 0.8s")
#endif
    }
    
    func testGIFRepresentation() {
        let image = Image.kf_animatedImageWithGIFData(gifData: testImageGIFData, preloadAll: false)!
        let data = ImageGIFRepresentation(image)
        
        XCTAssertNotNil(data, "Data should not be nil")
        XCTAssertEqual(data?.kf_imageFormat, ImageFormat.gif)
        
        let allLoadImage = Image.kf_animatedImageWithGIFData(gifData: data!, preloadAll: true)!
        let allLoadData = ImageGIFRepresentation(allLoadImage)
        XCTAssertNotNil(allLoadData, "Data1 should not be nil")
        XCTAssertEqual(allLoadData?.kf_imageFormat, ImageFormat.gif)
    }
    
    func testGenerateSingleFrameGIFImage() {
        let image = Image.kf_animatedImageWithGIFData(gifData: testImageSingleFrameGIFData, preloadAll: false)
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        let count = ImagesCountWithImageSource(image!.kf_imageSource!.imageRef!)
        XCTAssertEqual(count, 1, "There should be 1 frames.")
#else
        XCTAssertEqual(image!.kf_images!.count, 1, "There should be 1 frames.")
        
        XCTAssertEqual(image!.kf_duration, Double.infinity, "The image duration should be 0 since it is not animated image.")
#endif
    }
    
    func testPreloadAllGIFData() {
        let image = Image.kf_animatedImageWithGIFData(gifData: testImageSingleFrameGIFData, preloadAll: true)!
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        XCTAssertNil(image.kf_imageSource, "Image source should be nil")
#endif
        XCTAssertEqual(image.kf_duration, image.kf_duration)
        XCTAssertEqual(image.kf_images!.count, image.kf_images!.count)
    }
}
