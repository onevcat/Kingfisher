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
        let document = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = document.appendingPathComponent("test")
        try! testImageData.write(to: fileURL)
        
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        XCTAssertEqual(provider.cacheKey, fileURL.localFileCacheKey)
        XCTAssertEqual(fileURL.cacheKey, fileURL.localFileCacheKey)
        
        XCTAssertEqual(provider.fileURL, fileURL)
        
        let exp = expectation(description: #function)
        provider.data { result in
            XCTAssertEqual(result.value, testImageData)
            try! FileManager.default.removeItem(at: fileURL)
            exp.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testLocalFileImageDataProviderAsync() async {
        let fm = FileManager.default
        let document = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = document.appendingPathComponent("test")
        try! testImageData.write(to: fileURL)
        
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        XCTAssertEqual(provider.cacheKey, fileURL.localFileCacheKey)
        XCTAssertEqual(fileURL.cacheKey, fileURL.localFileCacheKey)
        
        XCTAssertEqual(provider.fileURL, fileURL)
        
        let value = try? await provider.data
        XCTAssertEqual(value, testImageData)
        try! fm.removeItem(at: fileURL)
    }

    func testLocalFileImageDataProviderMainQueue() {
        let fm = FileManager.default
        let document = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = document.appendingPathComponent("test")
        try! testImageData.write(to: fileURL)
        
        let provider = LocalFileImageDataProvider(fileURL: fileURL, loadingQueue: .mainCurrentOrAsync)
        XCTAssertEqual(provider.cacheKey, fileURL.localFileCacheKey)
        XCTAssertEqual(provider.fileURL, fileURL)
        
        let called = LockIsolated(false)
        provider.data { result in
            XCTAssertEqual(result.value, testImageData)
            try! FileManager.default.removeItem(at: fileURL)
            called.setValue(true)
        }

        XCTAssertTrue(called.value)
    }
    
    func testAVAssetImageDataProviderCacheKeyVariesForRemote() {
        let remoteURL1 = URL(string: "https://example.com/1/hello.mp4")!
        let remoteURL2 = URL(string: "https://example.com/2/hello.mp4")!
        
        let provider1 = AVAssetImageDataProvider(assetURL: remoteURL1, seconds: 10)
        XCTAssertEqual(provider1.cacheKey, "https://example.com/1/hello.mp4_10.0")
        
        let provider2 = AVAssetImageDataProvider(assetURL: remoteURL2, seconds: 10)
        XCTAssertNotEqual(provider1.cacheKey, provider2.cacheKey)
    }
    
    // AVAssetImageDataProvider fix for appending to #1825
    func testAVAssetImageDataProviderCacheKeyConsistForDifferentAppSandbox() {
        let localURL1 = URL(string: "file:///Users/onevcat/Library/Developer/CoreSimulator/Devices/ABC/data/Containers/Bundle/Application/DEF/Kingfisher-Demo.app/video/hello.mp4")!
        let localURL2 = URL(string: "file:///Users/onevcat/Library/Developer/CoreSimulator/Devices/ABC/data/Containers/Bundle/Application/XYZ/Kingfisher-Demo.app/video/hello.mp4")!
        
        let provider1 = AVAssetImageDataProvider(assetURL: localURL1, seconds: 10)
        XCTAssertEqual(provider1.cacheKey, "\(URL.localFileCacheKeyPrefix)/Kingfisher-Demo.app/video/hello.mp4_10.0")
    
        let provider2 = AVAssetImageDataProvider(assetURL: localURL2, seconds: 10)
        XCTAssertEqual(provider1.cacheKey, provider2.cacheKey)
    }
    

    func testLocalFileImageDataProviderMainQueueAsync() async {
        let fm = FileManager.default
        let document = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = document.appendingPathComponent("test")
        try! testImageData.write(to: fileURL)
        
        let provider = LocalFileImageDataProvider(fileURL: fileURL, loadingQueue: .mainCurrentOrAsync)
        XCTAssertEqual(provider.cacheKey, fileURL.localFileCacheKey)
        XCTAssertEqual(provider.fileURL, fileURL)
        
        var called = false
        let value = try? await provider.data
        XCTAssertEqual(value, testImageData)
        try! fm.removeItem(at: fileURL)
        called = true

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
        let imageResource = KF.ImageResource(downloadURL: url1, cacheKey: "hello")
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
