//
//  ImageExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/24.
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
        XCTAssertEqual(image!.kf.duration, 0.8, accuracy: 0.001, "The image duration should be 0.8s")
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
    
    func testPreloadAllAnimationData() {
        let image = Kingfisher<Image>.animated(with: testImageSingleFrameGIFData, preloadAll: true)!
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        XCTAssertNil(image.kf.imageSource, "Image source should be nil")
#endif
        XCTAssertEqual(image.kf.duration, image.kf.duration)
        XCTAssertEqual(image.kf.images!.count, image.kf.images!.count)
    }
    
    func testLoadOnlyFirstFrame() {
        let image = Kingfisher<Image>.animated(with: testImageGIFData,
                                               scale: 1.0,
                                               duration: 0.0,
                                               preloadAll: true,
                                               onlyFirstFrame: true)!
        XCTAssertNotNil(image, "The image should be initiated.")
        XCTAssertNil(image.kf.images, "The image should be nil")
    }
    
    func testSizeContent() {
        func getRatio(image: Image) -> CGFloat {
            return image.size.height / image.size.width
        }
        
        let image = testImage
        let ratio = getRatio(image: image)
        
        let targetSize = CGSize(width: 100, height: 50)
        
        let fillImage = image.kf.resize(to: targetSize, for: .aspectFill)
        XCTAssertEqual(getRatio(image: fillImage), ratio)
        XCTAssertEqual(max(fillImage.size.width, fillImage.size.height), 100)
        
        let fitImage = image.kf.resize(to: targetSize, for: .aspectFit)
        XCTAssertEqual(getRatio(image: fitImage), ratio)
        XCTAssertEqual(max(fitImage.size.width, fitImage.size.height), 50)
        
        let resizeImage = image.kf.resize(to: targetSize)
        XCTAssertEqual(resizeImage.size.width, 100)
        XCTAssertEqual(resizeImage.size.height, 50)
    }
    
    func testSizeConstraintByAnchor() {
        let size = CGSize(width: 100, height: 100)
        
        let topLeft = CGPoint(x: 0, y: 0)
        let top = CGPoint(x: 0.5, y: 0)
        let topRight = CGPoint(x: 1, y: 0)
        let center = CGPoint(x: 0.5, y: 0.5)
        let bottomRight = CGPoint(x: 1, y: 1)
        let invalidAnchor = CGPoint(x: -1, y: 2)
        
        let inSize = CGSize(width: 20, height: 20)
        let outX = CGSize(width: 120, height: 20)
        let outY = CGSize(width: 20, height: 120)
        let outSize = CGSize(width: 120, height: 120)
        
        XCTAssertEqual(size.kf.constrainedRect(for: inSize, anchor: topLeft), CGRect(x: 0, y: 0, width: 20, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outX, anchor: topLeft), CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outY, anchor: topLeft), CGRect(x: 0, y: 0, width: 20, height: 100))
        XCTAssertEqual(size.kf.constrainedRect(for: outSize, anchor: topLeft), CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(size.kf.constrainedRect(for: inSize, anchor: top), CGRect(x: 40, y: 0, width: 20, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outX, anchor: top), CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outY, anchor: top), CGRect(x: 40, y: 0, width: 20, height: 100))
        XCTAssertEqual(size.kf.constrainedRect(for: outSize, anchor: top), CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(size.kf.constrainedRect(for: inSize, anchor: topRight), CGRect(x: 80, y: 0, width: 20, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outX, anchor: topRight), CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outY, anchor: topRight), CGRect(x: 80, y: 0, width: 20, height: 100))
        XCTAssertEqual(size.kf.constrainedRect(for: outSize, anchor: topRight), CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(size.kf.constrainedRect(for: inSize, anchor: center), CGRect(x: 40, y: 40, width: 20, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outX, anchor: center), CGRect(x: 0, y: 40, width: 100, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outY, anchor: center), CGRect(x: 40, y: 0, width: 20, height: 100))
        XCTAssertEqual(size.kf.constrainedRect(for: outSize, anchor: center), CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(size.kf.constrainedRect(for: inSize, anchor: bottomRight), CGRect(x: 80, y: 80, width: 20, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outX, anchor: bottomRight), CGRect(x: 0, y: 80, width: 100, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outY, anchor: bottomRight), CGRect(x:80, y: 0, width: 20, height: 100))
        XCTAssertEqual(size.kf.constrainedRect(for: outSize, anchor: bottomRight), CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(size.kf.constrainedRect(for: inSize, anchor: invalidAnchor), CGRect(x: 0, y: 80, width: 20, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outX, anchor: invalidAnchor), CGRect(x: 0, y: 80, width: 100, height: 20))
        XCTAssertEqual(size.kf.constrainedRect(for: outY, anchor: invalidAnchor), CGRect(x:0, y: 0, width: 20, height: 100))
        XCTAssertEqual(size.kf.constrainedRect(for: outSize, anchor: invalidAnchor), CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    
    func testDecodeScale() {
        #if os(iOS) || os(tvOS)
        let image = testImage
        XCTAssertEqual(image.size, CGSize(width: 64, height: 64))
        XCTAssertEqual(image.scale, 1.0)

        let image_2x = Kingfisher<Image>.image(cgImage: image.cgImage!, scale: 2.0, refImage: image)
        XCTAssertEqual(image_2x.size, CGSize(width: 32, height: 32))
        XCTAssertEqual(image_2x.scale, 2.0)
        
        let decoded = image.kf.decoded
        XCTAssertEqual(decoded.size, CGSize(width: 64, height: 64))
        XCTAssertEqual(decoded.scale, 1.0)
        
        let decodedDifferentScale = image.kf.decoded(scale: 2.0)
        XCTAssertEqual(decodedDifferentScale.size, CGSize(width: 32, height: 32))
        XCTAssertEqual(decodedDifferentScale.scale, 2.0)
        
        let decoded_2x = image_2x.kf.decoded
        XCTAssertEqual(decoded_2x.size, CGSize(width: 32, height: 32))
        XCTAssertEqual(decoded_2x.scale, 2.0)
        #endif
        
    }
}
