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
        format = Data(raw).kf.imageFormat
        XCTAssertEqual(format, .unknown)
    }
    
    func testGenerateJPEGImage() {
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.image(data: testImageJEPGData, options: options)
        XCTAssertNotNil(image)
        XCTAssertNil(image?.kf.imageFrameCount)
        XCTAssertTrue(image!.renderEqual(to: KFCrossPlatformImage(data: testImageJEPGData)!))
    }
    
    func testGenerateGIFImage() {
        let options = ImageCreatingOptions()
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)
        XCTAssertNotNil(image)
        #if os(iOS) || os(tvOS) || os(visionOS)
        XCTAssertEqual(image!.kf.imageFrameCount!, 8)
        #else
        XCTAssertEqual(image!.kf.images!.count, 8)
        XCTAssertEqual(image!.kf.duration, 0.8, accuracy: 0.001)
        #endif
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
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
        #if os(iOS) || os(tvOS) || os(visionOS)
        XCTAssertEqual(image!.kf.imageFrameCount!, 1)
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
#if os(iOS) || os(tvOS) || os(visionOS)
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
        #if os(iOS) || os(tvOS) || os(visionOS)
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
        
        #if os(iOS) || os(tvOS) || os(visionOS)
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
        XCTAssertEqual(testImage.kf.scale, 1.0)
        
        let image = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: size, scale: 1)
        XCTAssertEqual(image?.size, size)
        XCTAssertEqual(image?.kf.scale, 1.0)
    }
    
    func testDownsamplingWithScale() {
        let size = CGSize(width: 15, height: 15)
        XCTAssertEqual(testImage.size, CGSize(width: 64, height: 64))
        XCTAssertEqual(testImage.kf.scale, 1.0)
        
        let image2x = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: size, scale: 2)
        #if os(macOS)
        XCTAssertEqual(image2x?.size, CGSize(width: 30, height: 30))
        XCTAssertEqual(image2x?.kf.scale, 1.0)
        #else
        XCTAssertEqual(image2x?.size, size)
        XCTAssertEqual(image2x?.kf.scale, 2.0)
        #endif
        
        let image3x = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: size, scale: 3)
        #if os(macOS)
        XCTAssertEqual(image3x?.size, CGSize(width: 45, height: 45))
        XCTAssertEqual(image3x?.kf.scale, 1.0)
        #else
        XCTAssertEqual(image3x?.size, size)
        XCTAssertEqual(image3x?.kf.scale, 3.0)
        #endif
    }

    func testDownsamplingWithEdgeCaseSize() {

        // Zero size would fail downsampling before iOS 17.4.
        let result = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: .zero, scale: 1)
        if #available(iOS 17.4, macOS 14.4, tvOS 17.4, *) {
            XCTAssertEqual(result?.size, CGSize(width: 64, height: 64))
        } else {
            XCTAssertNil(result)
        }

        let largerSize = CGSize(width: 100, height: 100)
        let largerImage = KingfisherWrapper<KFCrossPlatformImage>.downsampledImage(data: testImageData, to: largerSize, scale: 1)
        // You can not "downsample" an image to a larger size.
        XCTAssertEqual(largerImage?.size, CGSize(width: 64, height: 64))
    }

    // MARK: - Image Cost Tests

    func testCostForStaticImage() {
        let image = testImage
        let cost = image.kf.cost

        let expectedPixels = Int(image.kf.size.width * image.kf.size.height * image.kf.scale * image.kf.scale)
        let bytesPerPixel = image.kf.cgImage!.bitsPerPixel / 8
        XCTAssertEqual(cost, expectedPixels * bytesPerPixel)
        XCTAssertGreaterThan(cost, 0)
    }

    func testCostForAnimatedImageWithUniqueFrames() {
        let options = ImageCreatingOptions(preloadAll: true)
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)!

        let frameCount = image.kf.images!.count
        XCTAssertGreaterThan(frameCount, 1, "Test requires a multi-frame GIF")

        let expectedPixels = Int(image.kf.size.width * image.kf.size.height * image.kf.scale * image.kf.scale)
        let bytesPerPixel = image.kf.cgImage!.bitsPerPixel / 8
        let expectedCost = expectedPixels * bytesPerPixel * frameCount

        XCTAssertEqual(image.kf.cost, expectedCost)
    }

    #if os(iOS) || os(tvOS) || os(visionOS)
    func testCostForAnimatedImageWithDuplicateFrames() {
        let frame1 = UIImage.from(color: .red, size: CGSize(width: 10, height: 10))
        let frame2 = UIImage.from(color: .blue, size: CGSize(width: 10, height: 10))

        // 5 entries but only 2 unique objects
        let animatedImage = UIImage.animatedImage(with: [frame1, frame1, frame2, frame1, frame2], duration: 1.0)!

        let expectedPixels = Int(animatedImage.kf.size.width * animatedImage.kf.size.height * animatedImage.kf.scale * animatedImage.kf.scale)
        let bytesPerPixel = animatedImage.kf.cgImage!.bitsPerPixel / 8
        let expectedCost = expectedPixels * bytesPerPixel * 2 // only 2 unique frames

        XCTAssertEqual(animatedImage.kf.images!.count, 5)
        XCTAssertEqual(animatedImage.kf.cost, expectedCost)
    }

    func testCostForAnimatedImageWithAllIdenticalFrames() {
        let frame = UIImage.from(color: .green, size: CGSize(width: 20, height: 20))

        // 10 entries all referencing the same object
        let frames = Array(repeating: frame, count: 10)
        let animatedImage = UIImage.animatedImage(with: frames, duration: 1.0)!

        let expectedPixels = Int(animatedImage.kf.size.width * animatedImage.kf.size.height * animatedImage.kf.scale * animatedImage.kf.scale)
        let bytesPerPixel = animatedImage.kf.cgImage!.bitsPerPixel / 8
        let singleFrameCost = expectedPixels * bytesPerPixel

        XCTAssertEqual(animatedImage.kf.images!.count, 10)
        XCTAssertEqual(animatedImage.kf.cost, singleFrameCost, "Cost should equal a single frame when all frames are identical")
    }
    #endif

    func testCostMatchesCacheCost() {
        let image = testImage
        XCTAssertEqual(image.cacheCost, image.kf.cost)

        let options = ImageCreatingOptions(preloadAll: true)
        let gifImage = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: options)!
        XCTAssertEqual(gifImage.cacheCost, gifImage.kf.cost)
    }

    func testCostForSingleFrameGIF() {
        let options = ImageCreatingOptions(preloadAll: true)
        let image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageSingleFrameGIFData, options: options)!

        let expectedPixels = Int(image.kf.size.width * image.kf.size.height * image.kf.scale * image.kf.scale)
        let bytesPerPixel = image.kf.cgImage!.bitsPerPixel / 8
        let singleFrameCost = expectedPixels * bytesPerPixel

        XCTAssertEqual(image.kf.cost, singleFrameCost)
    }

    #if os(macOS)
    func testSVGImageSize() {
        let svgString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="100px" height="200px" viewBox="0 0 100 200" version="1.1" xmlns="http://www.w3.org/2000/svg">
            <rect width="100" height="200" fill="red"/>
        </svg>
        """
        
        guard let data = svgString.data(using: .utf8),
              let image = NSImage(data: data)
        else {
            XCTFail("Failed to create image from SVG data")
            return
        }
        
        let size = image.kf.size
        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 200)
    }
    #endif
}

#if !os(watchOS)

#if canImport(UIKit)
import UIKit
#endif

final class AnimatedImageViewAnimatorTests: XCTestCase {

    func testAnimatorPurgeFramesKeepsCurrentFrameByDefault() {
        let source = CGImageSourceCreateWithData(testImageGIFData as CFData, nil)!
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")

        #if os(macOS)
        let contentMode: KFCrossPlatformContentMode = .scaleAxesIndependently
        #else
        let contentMode: KFCrossPlatformContentMode = .scaleToFill
        #endif

        let animator = AnimatedImageView.Animator(
            imageSource: source,
            contentMode: contentMode,
            size: CGSize(width: 40, height: 40),
            imageSize: CGSize(width: 40, height: 40),
            imageScale: 1,
            framePreloadCount: 2,
            repeatCount: .infinite,
            preloadQueue: queue
        )

        animator.prepareFramesAsynchronously()
        queue.sync { }

        XCTAssertNotNil(animator.frame(at: 0))
        XCTAssertNotNil(animator.frame(at: 1))

        animator.purgeFrames()
        queue.sync { }

        XCTAssertNotNil(animator.frame(at: 0))
        XCTAssertNil(animator.frame(at: 1))
    }

    func testAnimatorPurgeFramesCanPurgeCurrentFrame() {
        let source = CGImageSourceCreateWithData(testImageGIFData as CFData, nil)!
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")

        #if os(macOS)
        let contentMode: KFCrossPlatformContentMode = .scaleAxesIndependently
        #else
        let contentMode: KFCrossPlatformContentMode = .scaleToFill
        #endif

        let animator = AnimatedImageView.Animator(
            imageSource: source,
            contentMode: contentMode,
            size: CGSize(width: 40, height: 40),
            imageSize: CGSize(width: 40, height: 40),
            imageScale: 1,
            framePreloadCount: 2,
            repeatCount: .infinite,
            preloadQueue: queue
        )

        animator.prepareFramesAsynchronously()
        queue.sync { }

        XCTAssertNotNil(animator.frame(at: 0))

        animator.purgeFrames(keepCurrentFrame: false)
        queue.sync { }

        XCTAssertNil(animator.frame(at: 0))
    }

    func testFrameSourceDownsamplesToFitMaxSize() {
        let source = CGImageSourceCreateWithData(testImageGIFData as CFData, nil)!
        let frameSource = CGImageFrameSource(data: testImageGIFData, imageSource: source, options: nil)

        let original = frameSource.frame(at: 0, maxSize: nil)
        XCTAssertEqual(original?.width, 365)
        XCTAssertEqual(original?.height, 360)

        for maxSize in [CGSize(width: 40, height: 40), CGSize(width: 100, height: 20), CGSize(width: 20, height: 100)] {
            let frame = frameSource.frame(at: 0, maxSize: maxSize)
            XCTAssertNotNil(frame, "\(maxSize)")
            XCTAssertLessThanOrEqual(CGFloat(frame?.width ?? .max), maxSize.width, "\(maxSize)")
            XCTAssertLessThanOrEqual(CGFloat(frame?.height ?? .max), maxSize.height, "\(maxSize)")
            XCTAssertGreaterThanOrEqual(CGFloat(frame?.height ?? 0), min(maxSize.width, maxSize.height) - 1, "\(maxSize)")
        }
    }

    func testDownsampledFramesMatchFullFrameRendering() throws {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(testImageGIFData as CFData, nil))
        let frameSource = CGImageFrameSource(data: testImageGIFData, imageSource: source, options: nil)

        func pixels(of image: CGImage, width: Int, height: Int) throws -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            try bytes.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(
                    data: buffer.baseAddress, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ))
                context.interpolationQuality = .high
                context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            return bytes
        }

        for index in 0..<frameSource.frameCount {
            let original = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, index, nil))
            let thumbnail = try XCTUnwrap(frameSource.frame(at: index, maxSize: CGSize(width: 40, height: 40)))
            let expected = try pixels(of: original, width: thumbnail.width, height: thumbnail.height)
            let actual = try pixels(of: thumbnail, width: thumbnail.width, height: thumbnail.height)
            XCTAssertTrue(actual == expected, "Frame \(index) should preserve the composited pixels")
        }
    }

    func testFrameSourceKeepsOriginalSizeWhenMaxSizeDoesNotLimit() {
        let source = CGImageSourceCreateWithData(testImageGIFData as CFData, nil)!
        let frameSource = CGImageFrameSource(data: testImageGIFData, imageSource: source, options: nil)

        for maxSize in [CGSize(width: 1000, height: 1000), CGSize(width: 0, height: 1), CGSize(width: 40, height: 0)] {
            let frame = frameSource.frame(at: 0, maxSize: maxSize)
            XCTAssertEqual(frame?.width, 365, "\(maxSize)")
            XCTAssertEqual(frame?.height, 360, "\(maxSize)")
        }
    }

    func testFrameSourceDownsamplesEveryFrame() {
        let source = CGImageSourceCreateWithData(testImageGIFData as CFData, nil)!
        let frameSource = CGImageFrameSource(data: testImageGIFData, imageSource: source, options: nil)
        XCTAssertGreaterThan(frameSource.frameCount, 1)

        for index in 0..<frameSource.frameCount {
            let frame = frameSource.frame(at: index, maxSize: CGSize(width: 40, height: 40))
            XCTAssertLessThanOrEqual(frame?.width ?? .max, 40, "Frame \(index) should fit in the max size")
            XCTAssertLessThanOrEqual(frame?.height ?? .max, 40, "Frame \(index) should fit in the max size")
        }
    }

    func testFrameSizingFollowsContentMode() {
        typealias Animator = AnimatedImageView.Animator
        let wide = CGSize(width: 800, height: 200)
        let target = CGSize(width: 120, height: 120)

        #if os(macOS)
        let fill: KFCrossPlatformContentMode = .scaleAxesIndependently
        let fit: KFCrossPlatformContentMode = .scaleProportionallyDown
        let unscaled: KFCrossPlatformContentMode = .scaleNone
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: target, contentMode: .scaleProportionallyUpOrDown, needsPrescaling: true),
            .limited(CGSize(width: 120, height: 30))
        )
        #else
        let fill: KFCrossPlatformContentMode = .scaleAspectFill
        let fit: KFCrossPlatformContentMode = .scaleAspectFit
        let unscaled: KFCrossPlatformContentMode = .center
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: target, contentMode: .scaleToFill, needsPrescaling: true),
            .limited(CGSize(width: 480, height: 120))
        )
        #endif

        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: target, contentMode: fill, needsPrescaling: true),
            .limited(CGSize(width: 480, height: 120))
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: target, contentMode: fit, needsPrescaling: true),
            .limited(CGSize(width: 120, height: 30))
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: target, contentMode: unscaled, needsPrescaling: true),
            .original
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: CGSize(width: 300, height: 300), contentMode: fill, needsPrescaling: true),
            .original
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: CGSize(width: 0, height: 120), contentMode: fill, needsPrescaling: true),
            .pending
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: .zero, contentMode: unscaled, needsPrescaling: true),
            .original
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: target, contentMode: fill, needsPrescaling: false),
            .original
        )
        XCTAssertEqual(
            Animator.frameSizing(imageSize: wide, targetSize: .zero, contentMode: fill, needsPrescaling: false),
            .original
        )
    }

    func testFrameSizingOnlyGrows() {
        typealias FrameSizing = AnimatedImageView.Animator.FrameSizing
        let small = FrameSizing.limited(CGSize(width: 40, height: 40))
        let large = FrameSizing.limited(CGSize(width: 60, height: 60))

        XCTAssertEqual(small.growing(to: large), large)
        XCTAssertNil(large.growing(to: small))
        XCTAssertNil(large.growing(to: large))
        XCTAssertNil(large.growing(to: .pending))
        XCTAssertEqual(FrameSizing.pending.growing(to: small), small)
        XCTAssertEqual(small.growing(to: .original), .original)
        XCTAssertNil(FrameSizing.original.growing(to: large))
        XCTAssertNil(FrameSizing.pending.growing(to: .pending))
        XCTAssertNil(small.growing(to: .limited(CGSize(width: 40.5, height: 40.5))))
    }

    func testAnimatorDownsamplesFramesToTargetSize() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)

        animator.prepareFramesAsynchronously()
        queue.sync { }

        let frame = animator.frame(at: 0)?.kf.cgImage
        XCTAssertEqual(frame?.width, 41)
        XCTAssertEqual(frame?.height, 40, "The short side of the frame should fill the target")
        XCTAssertFalse(maxSizes.value.isEmpty)
        XCTAssertFalse(maxSizes.value.contains(nil), "Frames should not be decoded at the original size")
    }

    func testAnimatorDecodesEnoughPixelsToFillTarget() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(
            data: makeAnimatedImageData(size: CGSize(width: 800, height: 200), frameCount: 2),
            imageSize: CGSize(width: 800, height: 200),
            maxSizes: maxSizes,
            size: CGSize(width: 120, height: 120),
            queue: queue
        )

        animator.prepareFramesAsynchronously()
        queue.sync { }

        let frame = animator.frame(at: 0)?.kf.cgImage
        XCTAssertEqual(frame?.width, 480)
        XCTAssertEqual(frame?.height, 120, "The short side of the frame should fill the target")
    }

    func testAnimatorDecodesLargerFramesWhenTargetGrows() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)

        animator.prepareFramesAsynchronously()
        queue.sync { }
        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.width, 41)

        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(animator.currentFrameIndex, 0)
        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.height, 60)
        XCTAssertEqual(animator.frame(at: 1)?.kf.cgImage?.height, 60)

        let decodeCount = maxSizes.value.count
        animator.updateTargetSize(CGSize(width: 20, height: 20), contentMode: fillContentMode)
        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(maxSizes.value.count, decodeCount, "Frames should not be decoded again when they are large enough")
        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.height, 60)
    }

    func testAnimatorReloadsFramesFromCurrentFrame() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)

        animator.prepareFramesAsynchronously()
        queue.sync { }
        for index in 1...4 {
            animator.currentFrameIndex = index
            queue.sync { }
        }
        XCTAssertNil(animator.frame(at: 0))

        let decodeCount = maxSizes.value.count
        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(animator.currentFrameIndex, 4)
        XCTAssertEqual(animator.frame(at: 4)?.kf.cgImage?.height, 60)
        XCTAssertEqual(animator.frame(at: 5)?.kf.cgImage?.height, 60)
        XCTAssertNil(animator.frame(at: 0), "Frames out of the buffer should not be decoded again")
        XCTAssertNil(animator.frame(at: 3), "Frames out of the buffer should not be decoded again")
        XCTAssertEqual(maxSizes.value.count - decodeCount, 2)
    }

    func testAnimatorReleasesFramesOutOfBufferWhenTargetGrows() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)

        animator.prepareFramesAsynchronously()
        queue.sync { }
        animator.currentFrameIndex = 4
        queue.sync { }
        XCTAssertNotNil(animator.frame(at: 1))

        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertNil(animator.frame(at: 1), "Frames out of the buffer should be released")
        XCTAssertEqual(animator.frame(at: 5)?.kf.cgImage?.height, 60)
    }

    func testAnimatorDoesNotDecodePurgedFramesWhenTargetGrows() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)

        animator.prepareFramesAsynchronously()
        queue.sync { }
        animator.purgeFrames()
        queue.sync { }

        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.height, 60)
        XCTAssertNil(animator.frame(at: 1), "Purged frames should stay purged")
    }

    func testAnimatorDoesNotReloadFramesSetUpForNewTarget() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)

        queue.suspend()
        animator.prepareFramesAsynchronously()
        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.resume()
        queue.sync { }

        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.height, 60)
        XCTAssertEqual(maxSizes.value.count, 2, "Frames should be decoded once")
    }

    @MainActor
    func testAnimatorAsksToDisplayReloadedCurrentFrame() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)
        let delegate = ReloadRecordingAnimatorDelegate()
        animator.delegate = delegate

        animator.prepareFramesAsynchronously()
        queue.sync { }
        delegate.reloaded = expectation(description: "Current frame reloaded")

        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        wait(for: [delegate.reloaded!], timeout: 3)

        XCTAssertEqual(animator.frame(at: animator.currentFrameIndex)?.kf.cgImage?.height, 60)
    }

    func testAnimatorDoesNotDecodeFramesUntilTargetHasArea() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 0, height: 1), queue: queue)

        animator.prepareFramesAsynchronously()
        queue.sync { }

        XCTAssertEqual(animator.frameSizing, .pending)
        XCTAssertEqual(maxSizes.value.count, 0)
        XCTAssertNil(animator.frame(at: 0))
        XCTAssertGreaterThan(animator.loopDuration, 0)

        animator.updateTargetSize(CGSize(width: 40, height: 40), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.height, 40)
        XCTAssertFalse(maxSizes.value.contains(nil), "Frames should not be decoded at the original size")
    }

    func testAnimatorFillsInitialBufferAfterConsecutiveLayoutChanges() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(
            data: makeAnimatedImageData(size: CGSize(width: 100, height: 100), frameCount: 2),
            imageSize: CGSize(width: 100, height: 100),
            maxSizes: maxSizes,
            size: .zero,
            queue: queue
        )
        animator.prepareFramesAsynchronously()
        queue.sync { }

        queue.suspend()
        animator.updateTargetSize(CGSize(width: 40, height: 40), contentMode: fillContentMode)
        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.resume()
        queue.sync { }

        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.height, 60)
        XCTAssertEqual(animator.frame(at: 1)?.kf.cgImage?.height, 60)
        XCTAssertEqual(maxSizes.value.count, 2)
    }

    func testCancelledAnimatorStopsAnActivePreloadBatch() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let cancellingAnimator = LockIsolated<AnimatedImageView.Animator?>(nil)
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(
            maxSizes: maxSizes,
            size: CGSize(width: 40, height: 40),
            queue: queue,
            framePreloadCount: 3,
            onFrame: { cancellingAnimator.value?.cancel() }
        )
        animator.prepareFramesAsynchronously()
        queue.sync { }
        let initialDecodeCount = maxSizes.value.count
        cancellingAnimator.setValue(animator)
        defer { cancellingAnimator.setValue(nil) }

        animator.currentFrameIndex = 4
        queue.sync { }

        XCTAssertEqual(maxSizes.value.count - initialDecodeCount, 1,
                       "Only the frame in flight should finish after cancellation")
    }

    func testAnimatorWithoutPrescalingDecodesOriginalFrames() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(maxSizes: maxSizes, size: CGSize(width: 40, height: 40), queue: queue)
        animator.needsPrescaling = false

        animator.prepareFramesAsynchronously()
        queue.sync { }

        XCTAssertEqual(animator.frameSizing, .original)
        XCTAssertEqual(animator.frame(at: 0)?.kf.cgImage?.width, 365)
        XCTAssertFalse(maxSizes.value.isEmpty)
        XCTAssertEqual(maxSizes.value.compactMap { $0 }, [])

        let decodeCount = maxSizes.value.count
        animator.updateTargetSize(CGSize(width: 20, height: 20), contentMode: fillContentMode)
        animator.updateTargetSize(.zero, contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(maxSizes.value.count, decodeCount)
    }

    func testCancelledAnimatorStopsDecodingFrames() {
        let maxSizes = LockIsolated<[CGSize?]>([])
        let cancellingAnimator = LockIsolated<AnimatedImageView.Animator?>(nil)
        let queue = DispatchQueue(label: "com.onevcat.KingfisherTests.AnimatorPreload")
        let animator = makeAnimator(
            maxSizes: maxSizes,
            size: CGSize(width: 40, height: 40),
            queue: queue,
            onFrame: { cancellingAnimator.value?.cancel() }
        )
        cancellingAnimator.setValue(animator)
        defer { cancellingAnimator.setValue(nil) }

        animator.prepareFramesAsynchronously()
        queue.sync { }

        XCTAssertEqual(maxSizes.value.count, 1, "No frame should be decoded after the animator is cancelled")

        animator.updateTargetSize(CGSize(width: 60, height: 60), contentMode: fillContentMode)
        queue.sync { }

        XCTAssertEqual(maxSizes.value.count, 1, "No frame should be decoded after the animator is cancelled")
    }

    private var fillContentMode: KFCrossPlatformContentMode {
        #if os(macOS)
        return .scaleAxesIndependently
        #else
        return .scaleToFill
        #endif
    }

    private func makeAnimator(
        data: Data = testImageGIFData,
        imageSize: CGSize = CGSize(width: 365, height: 360),
        maxSizes: LockIsolated<[CGSize?]>,
        size: CGSize,
        queue: DispatchQueue,
        framePreloadCount: Int = 1,
        onFrame: (@Sendable () -> Void)? = nil
    ) -> AnimatedImageView.Animator {
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let frameSource = RecordingFrameSource(
            base: CGImageFrameSource(data: nil, imageSource: source, options: nil),
            maxSizes: maxSizes,
            onFrame: onFrame
        )
        return AnimatedImageView.Animator(
            frameSource: frameSource,
            contentMode: fillContentMode,
            size: size,
            imageSize: imageSize,
            imageScale: 1,
            framePreloadCount: framePreloadCount,
            repeatCount: .infinite,
            preloadQueue: queue
        )
    }

    private func makeAnimatedImageData(size: CGSize, frameCount: Int) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, "com.compuserve.gif" as CFString, frameCount, nil)!
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        for index in 0..<frameCount {
            context.setFillColor(red: CGFloat(index % 2), green: 0, blue: 1, alpha: 1)
            context.fill(CGRect(origin: .zero, size: size))
            CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        }
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}

final class AnimatedImageViewLayoutTests: XCTestCase {

    #if os(macOS)
    @MainActor
    func testAnimatedImageViewFollowsFrameSizeWithoutRebuildingAnimator() {
        let imageView = AnimatedImageView(frame: .zero)
        imageView.imageScaling = .scaleAxesIndependently
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: .init())
        defer { imageView.image = nil }

        let animator = imageView.animator
        XCTAssertNotNil(animator)
        XCTAssertEqual(animator?.frameSizing, .pending)

        imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        guard case .limited(let small)? = imageView.animator?.frameSizing else {
            return XCTFail("Frames should be limited to the view size")
        }

        imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        guard case .limited(let large)? = imageView.animator?.frameSizing else {
            return XCTFail("Frames should be limited to the view size")
        }
        XCTAssertGreaterThan(large.width, small.width)

        imageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        XCTAssertEqual(imageView.animator?.frameSizing, .limited(large))

        imageView.imageScaling = .scaleNone
        XCTAssertEqual(imageView.animator?.frameSizing, .original)
        XCTAssertTrue(animator === imageView.animator, "Layout should not restart the animation")
    }

    @MainActor
    func testAnimatedImageViewUsesWindowBackingScale() {
        let window = ScaledWindow(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let imageView = AnimatedImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.imageScaling = .scaleAxesIndependently
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: .init())
        defer { imageView.image = nil }

        window.contentView?.addSubview(imageView)

        XCTAssertEqual(imageView.animator?.frameSizing, .limited(CGSize(width: 122, height: 120)))
    }

    @MainActor
    func testReplacingImageCancelsPreviousAnimator() {
        let imageView = AnimatedImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(data: testImageGIFData, options: .init())
        let animator = imageView.animator
        XCTAssertEqual(animator?.isCancelled, false)

        imageView.image = nil

        XCTAssertEqual(animator?.isCancelled, true)
    }
    #else
    @MainActor
    func testAnimatedImageViewFollowsLayoutWithoutRebuildingAnimator() {
        let imageView = AnimatedImageView()
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )
        defer { imageView.image = nil }

        let animator = imageView.animator
        XCTAssertNotNil(animator)
        XCTAssertEqual(animator?.frameSizing, .pending)

        layout(imageView, size: CGSize(width: 40, height: 40))
        guard case .limited(let small)? = imageView.animator?.frameSizing else {
            return XCTFail("Frames should be limited to the view size")
        }

        layout(imageView, size: CGSize(width: 60, height: 60))
        guard case .limited(let large)? = imageView.animator?.frameSizing else {
            return XCTFail("Frames should be limited to the view size")
        }
        XCTAssertGreaterThan(large.width, small.width)

        layout(imageView, size: CGSize(width: 20, height: 20))
        XCTAssertEqual(imageView.animator?.frameSizing, .limited(large))

        imageView.contentMode = .center
        XCTAssertEqual(imageView.animator?.frameSizing, .original)
        XCTAssertTrue(animator === imageView.animator, "Layout should not restart the animation")
    }

    @MainActor
    func testAnimatedImageViewWithoutPrescalingIgnoresLayout() {
        let imageView = AnimatedImageView()
        imageView.needsPrescaling = false
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )
        defer { imageView.image = nil }

        let animator = imageView.animator
        XCTAssertEqual(animator?.frameSizing, .original)

        layout(imageView, size: CGSize(width: 40, height: 40))
        layout(imageView, size: CGSize(width: 60, height: 60))

        XCTAssertEqual(imageView.animator?.frameSizing, .original)
        XCTAssertTrue(animator === imageView.animator)
    }

    @MainActor
    func testReplacingImageCancelsPreviousAnimator() {
        let imageView = AnimatedImageView()
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )
        let animator = imageView.animator
        XCTAssertEqual(animator?.isCancelled, false)

        imageView.image = nil

        XCTAssertEqual(animator?.isCancelled, true)
    }

    #if os(iOS)
    @MainActor
    func testLayoutDoesNotRestartStoppedAnimation() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let host = UIViewController()
        window.rootViewController = host
        window.makeKeyAndVisible()

        let imageView = AnimatedImageView()
        host.view.addSubview(imageView)
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )
        defer { imageView.image = nil }
        XCTAssertTrue(imageView.isAnimating)

        imageView.stopAnimating()
        layout(imageView, size: CGSize(width: 40, height: 40))

        XCTAssertFalse(imageView.isAnimating)
    }

    @MainActor
    func testPlayingViewLeavesPendingSizingWithoutLayoutSubviews() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let host = UIViewController()
        window.rootViewController = host
        window.makeKeyAndVisible()

        let imageView = LayoutSkippingAnimatedImageView()
        host.view.addSubview(imageView)
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )
        defer { imageView.image = nil }
        XCTAssertEqual(imageView.animator?.frameSizing, .pending)

        layout(imageView, size: CGSize(width: 40, height: 40))
        let sized = expectation(for: NSPredicate { _, _ in
            MainActor.runUnsafely { imageView.animator?.frameSizing != .pending }
        }, evaluatedWith: nil)
        wait(for: [sized], timeout: 3)
    }
    #endif

    @MainActor
    private func layout(_ view: UIView, size: CGSize) {
        view.frame = CGRect(origin: .zero, size: size)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    #endif
}

@MainActor
private final class ReloadRecordingAnimatorDelegate: AnimatorDelegate {
    var reloaded: XCTestExpectation?

    func animator(_ animator: AnimatedImageView.Animator, didPlayAnimationLoops count: UInt) {}

    func animatorDidReloadCurrentFrame(_ animator: AnimatedImageView.Animator) {
        reloaded?.fulfill()
    }
}

#if os(macOS)
private final class ScaledWindow: NSWindow {
    override var backingScaleFactor: CGFloat { 3 }
}
#elseif os(iOS)
private final class LayoutSkippingAnimatedImageView: AnimatedImageView {
    override func layoutSubviews() {}
}
#endif

private struct RecordingFrameSource: ImageFrameSource {
    let base: CGImageFrameSource
    let maxSizes: LockIsolated<[CGSize?]>
    let onFrame: (@Sendable () -> Void)?

    var data: Data? { base.data }
    var frameCount: Int { base.frameCount }

    func frame(at index: Int, maxSize: CGSize?) -> CGImage? {
        maxSizes.withValue { $0.append(maxSize) }
        onFrame?()
        return base.frame(at: index, maxSize: maxSize)
    }

    func duration(at index: Int) -> TimeInterval {
        base.duration(at: index)
    }
}

#if os(iOS)

final class AnimatedImageViewBackgroundPurgeTests: XCTestCase {

    @MainActor
    func testPurgeFramesOnBackgroundStopsAnimation() {
        let imageView = AnimatedImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.purgeFramesOnBackground = true
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )

        imageView.startAnimating()
        XCTAssertTrue(imageView.isAnimating)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertFalse(imageView.isAnimating)
    }

    @MainActor
    func testPurgeFramesOnBackgroundCanResumeOnForegroundWhenViewAttached() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let host = UIViewController()
        window.rootViewController = host
        window.makeKeyAndVisible()

        let imageView = AnimatedImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.purgeFramesOnBackground = true
        imageView.image = KingfisherWrapper<KFCrossPlatformImage>.animatedImage(
            data: testImageGIFData,
            options: .init(scale: 1, duration: 0, preloadAll: false, onlyFirstFrame: false)
        )
        host.view.addSubview(imageView)

        imageView.startAnimating()
        XCTAssertTrue(imageView.isAnimating)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertFalse(imageView.isAnimating)

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertTrue(imageView.isAnimating)
    }
}

#endif

#endif
