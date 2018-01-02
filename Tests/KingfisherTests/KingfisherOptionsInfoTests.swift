//
//  KingfisherOptionsInfoTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/4.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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

class KingfisherOptionsInfoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEmptyOptionsShouldParseCorrectly() {
        let options = KingfisherEmptyOptionsInfo
        XCTAssertTrue(options.targetCache === ImageCache.default)
        XCTAssertTrue(options.downloader === ImageDownloader.default)

#if !os(macOS)
        switch options.transition {
        case .none: break
        default: XCTFail("The transition for empty option should be .None. But \(options.transition)")
        }
#endif
        
        XCTAssertEqual(options.downloadPriority, URLSessionTask.defaultPriority)
        XCTAssertFalse(options.forceRefresh)
        XCTAssertFalse(options.fromMemoryCacheOrRefresh)
        XCTAssertFalse(options.cacheMemoryOnly)
        XCTAssertFalse(options.backgroundDecode)
        XCTAssertEqual(options.callbackDispatchQueue.label, DispatchQueue.main.label)
        XCTAssertEqual(options.scaleFactor, 1.0)
        XCTAssertFalse(options.keepCurrentImageWhileLoading)
        XCTAssertFalse(options.onlyLoadFirstFrame)
        XCTAssertFalse(options.cacheOriginalImage)
    }
    

    func testSetOptionsShouldParseCorrectly() {
        let cache = ImageCache(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        let downloader = ImageDownloader(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        
#if os(macOS)
        let transition = ImageTransition.none
#else
        let transition = ImageTransition.fade(0.5)
#endif
            
        let queue = DispatchQueue.global(qos: .default)
        let testModifier = TestModifier()
        let processor = RoundCornerImageProcessor(cornerRadius: 20)
        
        let options: KingfisherOptionsInfo = [
            .targetCache(cache),
            .downloader(downloader),
            .transition(transition),
            .downloadPriority(0.8),
            .forceRefresh,
            .fromMemoryCacheOrRefresh,
            .cacheMemoryOnly,
            .onlyFromCache,
            .backgroundDecode,
            .callbackDispatchQueue(queue),
            KingfisherOptionsInfoItem.scaleFactor(2.0),
            .requestModifier(testModifier),
            .processor(processor),
            .keepCurrentImageWhileLoading,
            .onlyLoadFirstFrame,
            .cacheOriginalImage
        ]
        
        XCTAssertTrue(options.targetCache === cache)
        XCTAssertTrue(options.downloader === downloader)

#if !os(macOS)
        switch options.transition {
        case .fade(let duration): XCTAssertEqual(duration, 0.5)
        default: XCTFail()
        }
#endif
        
        XCTAssertEqual(options.downloadPriority, 0.8)
        XCTAssertTrue(options.forceRefresh)
        XCTAssertTrue(options.fromMemoryCacheOrRefresh)
        XCTAssertTrue(options.cacheMemoryOnly)
        XCTAssertTrue(options.onlyFromCache)
        XCTAssertTrue(options.backgroundDecode)
        
        XCTAssertEqual(options.callbackDispatchQueue.label, queue.label)
        XCTAssertEqual(options.scaleFactor, 2.0)
        XCTAssertTrue(options.modifier is TestModifier)
        XCTAssertEqual(options.processor.identifier, processor.identifier)
        XCTAssertTrue(options.keepCurrentImageWhileLoading)
        XCTAssertTrue(options.onlyLoadFirstFrame)
        XCTAssertTrue(options.cacheOriginalImage)
    }
    
    func testOptionCouldBeOverwritten() {
        var options: KingfisherOptionsInfo = [.downloadPriority(0.5), .onlyFromCache]
        XCTAssertEqual(options.downloadPriority, 0.5)
        
        options.append(.downloadPriority(0.8))
        XCTAssertEqual(options.downloadPriority, 0.8)
        
        options.append(.downloadPriority(1.0))
        XCTAssertEqual(options.downloadPriority, 1.0)
    }
}

class TestModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        return nil
    }
}
