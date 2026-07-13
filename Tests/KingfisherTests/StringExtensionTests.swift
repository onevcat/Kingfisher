//
//  StringExtensionTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/8/14.
//  Copyright © 2019 Wei Wang. All rights reserved.
//

import XCTest
@testable import Kingfisher

class StringExtensionTests: XCTestCase {
    func testStringSHA256() {
        let s = "hello"
        XCTAssertEqual(s.kf.sha256, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    }

    func testStringExt() {
        // Basic extension extraction from a key.
        XCTAssertEqual("https://example.com/image.png".kf.ext, "png")
        XCTAssertEqual("https://example.com/image.JPG".kf.ext, "JPG")
        XCTAssertEqual("https://example.com/a.b/photo.gif".kf.ext, "gif")
        // The processor identifier is appended as `@identifier`; it is stripped before extraction.
        XCTAssertEqual("https://example.com/image.png@round-corner".kf.ext, "png")
        // No extension present.
        XCTAssertNil("https://example.com/image".kf.ext)
        XCTAssertNil("plain-key-without-dot".kf.ext)
    }

    // Regression test for https://github.com/onevcat/Kingfisher/issues/2301
    //
    // When the URL path itself contains `@`, the `@`-split used to strip the processor
    // identifier extracted a bogus "extension" that contained a path separator
    // (`net/57373197`). Appended to the hashed file name, that produces a nonexistent
    // sub-directory path, the cache file can never be written, and disk caching breaks.
    func testStringExtRejectsValueWithPathSeparator() {
        let key = "https://t.furaffinity.net/57373197@300-1720981878.jpg"
        let ext = key.kf.ext
        XCTAssertNil(ext, "Expected no extension instead of the broken `net/57373197` value")
        if let ext {
            XCTAssertFalse(ext.contains("/"), "A file extension must never contain a path separator")
        }
    }
}
