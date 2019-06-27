//
//  ImageExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/24.
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
import ImageIO
@testable import Kingfisher

class ImageExtensionTests: XCTestCase {

    func testImageFormat() {
        var format: ImageFormat
        format = testImageJEPGData.kf.imageFormat
        XCTAssertEqual(format, .JPEG)
        
        format = testImagePNGData.kf.imageFormat
        XCTAssertEqual(format, .PNG)
        
        format = testImageGIFData.kf.imageFormat
        XCTAssertEqual(format, .GIF)
        
        let raw: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        #if swift(>=5.0)
        format = Data(raw).kf.imageFormat
        #else
        format = Data(bytes: raw).kf.imageFormat
        #endif
        XCTAssertEqual(format, .unknown)
    }
    
    func testGenerateJPEGImage() {
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.image(data: testImageJEPGData, options: options)
        XCTAssertNotNil(image)
        XCTAssertTrue(image!.renderEqual(to: KFCrossPlatformImage(data: testImageJEPGData)!))
    }
    
    func testGenerateGIFImage() {
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)
        XCTAssertNotNil(image)
        #if os(iOS) || os(tvOS)
        let count = CGImageSourceGetCount(image!.kf.imageSource!)
        XCTAssertEqual(count, 8)
        #else
        XCTAssertEqual(image!.kf.images!.count, 8)
        XCTAssertEqual(image!.kf.duration, 0.8, accuracy: 0.001)
        #endif
    }

    #if os(iOS) || os(tvOS)
    func testScaleForGIFImage() {
        let options = ImageCreatingOptions(scale: 2.0, duration: 0.0, preloadAll: false, onlyFirstFrame: false)
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)
        XCTAssertNotNil(image)
        XCTAssertEqual(image!.scale, 2.0)
    }
    #endif

    func testGIFRepresentation() {
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)!
        let data = image.kf.gifRepresentation()
        
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.kf.imageFormat, ImageFormat.GIF)
        
        let preloadOptions = ImageCreatingOptions(preloadAll: true)
        let allLoadImage = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: data!, options: preloadOptions)!
        let allLoadData = allLoadImage.kf.gifRepresentation()
        XCTAssertNotNil(allLoadData)
        XCTAssertEqual(allLoadData?.kf.imageFormat, ImageFormat.GIF)
    }
    
    func testGenerateSingleFrameGIFImage() {
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageSingleFrameGIFData, options: options)
        XCTAssertNotNil(image)
        #if os(iOS) || os(tvOS)
        let count = CGImageSourceGetCount(image!.kf.imageSource!)
        XCTAssertEqual(count, 1)
        #else
        XCTAssertEqual(image!.kf.images!.count, 1)
        XCTAssertEqual(image!.kf.duration, Double.infinity)
        #endif
    }
    
    func testGenerateFromNonImage() {
        let data = "hello".data(using: .utf8)!
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.image(data: data, options: options)
        XCTAssertNil(image)
    }
    
    func testPreloadAllAnimationData() {
        let preloadOptions = ImageCreatingOptions(preloadAll: true)
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageSingleFrameGIFData, options: preloadOptions)!
        XCTAssertNotNil(image, "The image should be initiated.")
#if os(iOS) || os(tvOS)
        XCTAssertNil(image.kf.imageSource, "Image source should be nil")
#endif
        XCTAssertEqual(image.kf.duration, image.kf.duration)
        XCTAssertEqual(image.kf.images!.count, image.kf.images!.count)
    }
    
    func testLoadOnlyFirstFrame() {
        let preloadOptions = ImageCreatingOptions(preloadAll: true, onlyFirstFrame: true)
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: preloadOptions)!
        XCTAssertNotNil(image, "The image should be initiated.")
        XCTAssertNil(image.kf.images, "The image should be nil")
    }
    
    func testSizeContent() {
        func getRatio(image: KFCrossPlatformImage) -> CGFloat {
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

        let kf = size.kf

        XCTAssertEqual(
            kf.constrainedRect(for: inSize, anchor: topLeft),
            CGRect(x: 0, y: 0, width: 20, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outX, anchor: topLeft),
            CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outY, anchor: topLeft),
            CGRect(x: 0, y: 0, width: 20, height: 100))
        XCTAssertEqual(
            kf.constrainedRect(for: outSize, anchor: topLeft),
            CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(
            kf.constrainedRect(for: inSize, anchor: top),
            CGRect(x: 40, y: 0, width: 20, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outX, anchor: top),
            CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outY, anchor: top),
            CGRect(x: 40, y: 0, width: 20, height: 100))
        XCTAssertEqual(
            kf.constrainedRect(for: outSize, anchor: top),
            CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(
            kf.constrainedRect(for: inSize, anchor: topRight),
            CGRect(x: 80, y: 0, width: 20, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outX, anchor: topRight),
            CGRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outY, anchor: topRight),
            CGRect(x: 80, y: 0, width: 20, height: 100))
        XCTAssertEqual(
            kf.constrainedRect(for: outSize, anchor: topRight),
            CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(
            kf.constrainedRect(for: inSize, anchor: center),
            CGRect(x: 40, y: 40, width: 20, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outX, anchor: center),
            CGRect(x: 0, y: 40, width: 100, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outY, anchor: center),
            CGRect(x: 40, y: 0, width: 20, height: 100))
        XCTAssertEqual(
            kf.constrainedRect(for: outSize, anchor: center),
            CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(
            kf.constrainedRect(for: inSize, anchor: bottomRight),
            CGRect(x: 80, y: 80, width: 20, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outX, anchor: bottomRight),
            CGRect(x: 0, y: 80, width: 100, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outY, anchor: bottomRight),
            CGRect(x:80, y: 0, width: 20, height: 100))
        XCTAssertEqual(
            kf.constrainedRect(for: outSize, anchor: bottomRight),
            CGRect(x: 0, y: 0, width: 100, height: 100))
        
        XCTAssertEqual(
            kf.constrainedRect(for: inSize, anchor: invalidAnchor),
            CGRect(x: 0, y: 80, width: 20, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outX, anchor: invalidAnchor),
            CGRect(x: 0, y: 80, width: 100, height: 20))
        XCTAssertEqual(
            kf.constrainedRect(for: outY, anchor: invalidAnchor),
            CGRect(x:0, y: 0, width: 20, height: 100))
        XCTAssertEqual(
            kf.constrainedRect(for: outSize, anchor: invalidAnchor),
            CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    
    func testDecodeScale() {
        #if os(iOS) || os(tvOS)
        let image = testImage
        XCTAssertEqual(image.size, CGSize(width: 64, height: 64))
        XCTAssertEqual(image.scale, 1.0)

        let image_2x = KingfisherWrapper<KFCrossPlatformImage>.image(cgImage: image.cgImage!, scale: 2.0, refImage: image)
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
    
    func testNormalized() {
        // Full loaded GIF image should not be normalized since it is a set of images.
        let options = ImageCreatingOptions()
        let gifImage = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)
        
        XCTAssertNotNil(gifImage)
        XCTAssertEqual(gifImage!.kf.normalized, gifImage!)
        
        #if os(iOS) || os(tvOS)
        // No need to normalize up orientation image.
        let normalImage = testImage
        XCTAssertEqual(normalImage.imageOrientation, .up)
        XCTAssertEqual(normalImage.kf.normalized, testImage)

        let colorImage = UIImage.from(color: .red, size: CGSize(width: 100, height: 200))
        let rotatedImage = UIImage(cgImage: colorImage.cgImage!, scale: colorImage.scale, orientation: .right)

        XCTAssertEqual(rotatedImage.imageOrientation, .right)

        let rotatedNormalizedImage = rotatedImage.kf.normalized
        XCTAssertEqual(rotatedNormalizedImage.imageOrientation, .up)
        XCTAssertEqual(rotatedNormalizedImage.size, CGSize(width: 200, height: 100))
        #endif
    }
    
    func testDownsampling() {
        let size = CGSize(width: 15, height: 15)
        XCTAssertEqual(testImage.size, CGSize(width: 64, height: 64))
        let image = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: size, scale: 1)
        XCTAssertEqual(image?.size, size)
        XCTAssertEqual(image?.kf.scale, 1.0)
    }
    
    func testDownsamplingWithScale() {
        let size = CGSize(width: 15, height: 15)
        XCTAssertEqual(testImage.size, CGSize(width: 64, height: 64))
        let image = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: size, scale: 2)
        #if os(macOS)
        XCTAssertEqual(image?.size, CGSize(width: 30, height: 30))
        XCTAssertEqual(image?.kf.scale, 1.0)
        #else
        XCTAssertEqual(image?.size, size)
        XCTAssertEqual(image?.kf.scale, 2.0)
        #endif
    }

    func testDownsamplingWithEdgeCaseSize() {

        // Zero size would fail downsampling.
        let nilImage = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: .zero, scale: 1)
        XCTAssertNil(nilImage)

        let largerSize = CGSize(width: 100, height: 100)
        let largerImage = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: largerSize, scale: 1)
        // You can not "downsample" an image to a larger size.
        XCTAssertEqual(largerImage?.size, CGSize(width: 64, height: 64))
    }
}
