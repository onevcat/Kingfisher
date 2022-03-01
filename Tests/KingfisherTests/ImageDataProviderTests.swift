//
//  ImageDataProviderTests.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/18.
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
@testable import Kingfisher

class ImageDataProviderTests: XCTestCase {
    
    func testLocalFileImageDataProvider() {
        let fm = FileManager.default
        let document = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = document.appendingPathComponent("test")
        try! testImageData.write(to: fileURL)
        
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        XCTAssertEqual(provider.cacheKey, fileURL.localFileCacheKey)
        XCTAssertEqual(fileURL.cacheKey, fileURL.localFileCacheKey)
        
        XCTAssertEqual(provider.fileURL, fileURL)
        
        let exp = expectation(description: #function)
        provider.data { result in
            XCTAssertEqual(result.value, testImageData)
            try! fm.removeItem(at: fileURL)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testLocalFileImageDataProviderMainQueue() {
        let fm = FileManager.default
        let document = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = document.appendingPathComponent("test")
        try! testImageData.write(to: fileURL)
        
        let provider = LocalFileImageDataProvider(fileURL: fileURL, loadingQueue: .mainCurrentOrAsync)
        XCTAssertEqual(provider.cacheKey, fileURL.localFileCacheKey)
        XCTAssertEqual(provider.fileURL, fileURL)
        
        var called = false
        provider.data { result in
            XCTAssertEqual(result.value, testImageData)
            try! fm.removeItem(at: fileURL)
            called = true
        }

        XCTAssertTrue(called)
    }
    
    func testLocalFileCacheKey() {
        let url1 = URL(string: "file:///Users/onevcat/Library/Developer/CoreSimulator/Devices/ABC/data/Containers/Bundle/Application/DEF/Kingfisher-Demo.app/images/kingfisher-1.jpg")!
        XCTAssertEqual(url1.localFileCacheKey, "\(URL.localFileCacheKeyPrefix)/Kingfisher-Demo.app/images/kingfisher-1.jpg")
    
        let url2 = URL(string: "file:///private/var/containers/Bundle/Application/ABC/Kingfisher-Demo.app/images/kingfisher-1.jpg")!
        XCTAssertEqual(url2.localFileCacheKey, "\(URL.localFileCacheKeyPrefix)/Kingfisher-Demo.app/images/kingfisher-1.jpg")
        
        let url3 = URL(string: "file:///private/var/containers/Bundle/Application/ABC/Kingfisher-Demo.app/images/kingfisher-1.jpg?foo=bar")!
        XCTAssertEqual(url3.localFileCacheKey, "\(URL.localFileCacheKeyPrefix)/Kingfisher-Demo.app/images/kingfisher-1.jpg?foo=bar")
        
        let url4 = URL(string: "file:///private/var/containers/Bundle/Application/ABC/Kingfisher-Demo.appex/images/kingfisher-1.jpg")!
        XCTAssertEqual(url4.localFileCacheKey, "\(URL.localFileCacheKeyPrefix)/Kingfisher-Demo.appex/images/kingfisher-1.jpg")
        
        let url5 = URL(string: "file:///private/var/containers/Bundle/Application/ABC/Kingfisher-Demo.other/images/kingfisher-1.jpg")!
        XCTAssertEqual(url5.localFileCacheKey, "\(URL.localFileCacheKeyPrefix)///private/var/containers/Bundle/Application/ABC/Kingfisher-Demo.other/images/kingfisher-1.jpg")
    }
    
    func testLocalFileExplicitKey() {
        let url1 = URL(string: "file:///Users/onevcat/Library/Developer/CoreSimulator/Devices/ABC/data/Containers/Bundle/Application/DEF/Kingfisher-Demo.app/images/kingfisher-1.jpg")!
        let imageResource = ImageResource(downloadURL: url1, cacheKey: "hello")
        let source = imageResource.convertToSource()
        XCTAssertEqual(source.cacheKey, "hello")
    }
    
    func testBase64ImageDataProvider() {
        let base64String = testImageData.base64EncodedString()
        let provider = Base64ImageDataProvider(base64String: base64String, cacheKey: "123")
        XCTAssertEqual(provider.cacheKey, "123")
        var syncCalled = false
        provider.data { result in
            XCTAssertEqual(result.value, testImageData)
            syncCalled = true
        }
        
        XCTAssertTrue(syncCalled)
    }
    
}
