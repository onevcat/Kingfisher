//
//  StringExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/8/14.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import XCTest
@testable import Kingfisher

class StringExtensionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStringMD5() {
        let s = "hello"
        XCTAssertEqual(s.kf.md5, "5d41402abc4b2a76b9719d911017c592")
    }
    
}
