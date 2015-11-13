//
//  ImageExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/10/24.
//  Copyright © 2015年 Wei Wang. All rights reserved.
//

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
        XCTAssertEqual(format, ImageFormat.JPEG)
        
        format = testImagePNGData.kf_imageFormat
        XCTAssertEqual(format, ImageFormat.PNG)
        
        format = testImageGIFData.kf_imageFormat
        XCTAssertEqual(format, ImageFormat.GIF)
        
        let raw = [1, 2, 3, 4, 5, 6, 7, 8]
        format = NSData(bytes: raw, length: 8) .kf_imageFormat
        XCTAssertEqual(format, ImageFormat.Unknown)
    }
    
    func testGenerateGIFImage() {
        let image = UIImage.kf_animatedImageWithGIFData(gifData: testImageGIFData)
        XCTAssertNotNil(image, "The image should be initiated.")
        XCTAssertEqual(image!.images!.count, 8, "There should be 8 frames.")
        
        XCTAssertEqualWithAccuracy(image!.duration, 0.8, accuracy: 0.001, "The image duration should be 0.8s")
    }
    
    func testGIFRepresentation() {
        let image = UIImage.kf_animatedImageWithGIFData(gifData: testImageGIFData)!
        let data = UIImageGIFRepresentation(image)
        
        XCTAssertNotNil(data, "Data should not be nil")
        XCTAssertEqual(data?.kf_imageFormat, ImageFormat.GIF)
        
        let image1 = UIImage.kf_animatedImageWithGIFData(gifData: data!)!
        XCTAssertEqual(image1.duration, image.duration)
        XCTAssertEqual(image1.images!.count, image.images!.count)
    }
}
