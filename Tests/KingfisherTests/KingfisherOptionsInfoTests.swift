//
//  KingfisherOptionsInfoTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/4.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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
        XCTAssertNil(options.targetCache)
        XCTAssertNil(options.downloader)

#if !os(OSX)
        switch options.transition {
        case .None: break
        default: XCTFail("The transition for empty option should be .None. But \(options.transition)")
        }
#endif
        
        XCTAssertEqual(options.downloadPriority, NSURLSessionTaskPriorityDefault)
        XCTAssertFalse(options.forceRefresh)
        XCTAssertFalse(options.cacheMemoryOnly)
        XCTAssertFalse(options.backgroundDecode)
        XCTAssertEqual(dispatch_queue_get_label(options.callbackDispatchQueue), dispatch_queue_get_label(dispatch_get_main_queue()))
        XCTAssertEqual(options.scaleFactor, 1.0)
    }
    

    func testSetOptionsShouldParseCorrectly() {
        let cache = ImageCache(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        let downloader = ImageDownloader(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        
#if os(OSX)
        let transition = ImageTransition.None
#else
        let transition = ImageTransition.Fade(0.5)
#endif
            
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        let options: KingfisherOptionsInfo = [
            .TargetCache(cache),
            .Downloader(downloader),
            .Transition(transition),
            .DownloadPriority(0.8),
            .ForceRefresh,
            .CacheMemoryOnly,
            .BackgroundDecode,
            .CallbackDispatchQueue(queue),
            .ScaleFactor(2.0)
        ]
        
        XCTAssertTrue(options.targetCache === cache)
        XCTAssertTrue(options.downloader === downloader)

#if !os(OSX)
        switch options.transition {
        case .Fade(let duration): XCTAssertEqual(duration, 0.5)
        default: XCTFail()
        }
#endif
        
        XCTAssertEqual(options.downloadPriority, 0.8)
        XCTAssertTrue(options.forceRefresh)
        XCTAssertTrue(options.cacheMemoryOnly)
        XCTAssertTrue(options.backgroundDecode)
        
        XCTAssertEqual(dispatch_queue_get_label(options.callbackDispatchQueue), dispatch_queue_get_label(queue))
        XCTAssertEqual(options.scaleFactor, 2.0)
        
    }
    
}
