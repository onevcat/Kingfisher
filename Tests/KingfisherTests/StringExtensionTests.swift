//
//  StringExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/8/14.
//  Copyright © 2019 Wei Wang. All rights reserved.
//

@testable import Kingfisher
import XCTest

class StringExtensionTests: XCTestCase {
    func testStringMD5() {
        let s = "hello"
        XCTAssertEqual(s.kf.md5, "5d41402abc4b2a76b9719d911017c592")
    }
}
