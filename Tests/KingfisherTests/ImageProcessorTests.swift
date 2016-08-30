//
//  ImageProcessorTests.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/08/30.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import XCTest
import Kingfisher

class ImageProcessorTests: XCTestCase {
    
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
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
