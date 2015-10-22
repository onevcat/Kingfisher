//
//  KingfisherManagerTests.swift
//  Kingfisher
//
//  Created by WANG WEI on 2015/10/22.
//  Copyright © 2015年 Wei Wang. All rights reserved.
//

import XCTest
@testable import Kingfisher

class KingfisherManagerTests: XCTestCase {
    
    var manager: KingfisherManager!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        manager = KingfisherManager()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        manager = nil
        super.tearDown()
    }
    
    func testParseNilOptions() {
        let optionsInfo: KingfisherOptionsInfo? = nil
        let result = manager.parseOptionsInfo(optionsInfo)
        
        XCTAssertEqual(result.0.forceRefresh, KingfisherManager.DefaultOptions.forceRefresh)
        XCTAssertEqual(result.0.lowPriority, KingfisherManager.DefaultOptions.lowPriority)
        XCTAssertEqual(result.0.cacheMemoryOnly, KingfisherManager.DefaultOptions.cacheMemoryOnly)
        XCTAssertEqual(result.0.shouldDecode, KingfisherManager.DefaultOptions.shouldDecode)
        XCTAssertEqual(result.0.scale, KingfisherManager.DefaultOptions.scale)
        
        XCTAssertTrue(result.1 === manager.cache)
        XCTAssertEqual(result.2, manager.downloader)
    }
    
    func testParseSingleOptions() {
        let cache = ImageCache(name: "KingfisherManagerTests")
        let optionsInfo: KingfisherOptionsInfo = [.Options(.ForceRefresh), .TargetCache(cache)]
        let result = manager.parseOptionsInfo(optionsInfo)
        
        XCTAssertEqual(result.0.forceRefresh, true)
        XCTAssertEqual(result.0.lowPriority, KingfisherManager.DefaultOptions.lowPriority)
        XCTAssertEqual(result.0.cacheMemoryOnly, KingfisherManager.DefaultOptions.cacheMemoryOnly)
        XCTAssertEqual(result.0.shouldDecode, KingfisherManager.DefaultOptions.shouldDecode)
        XCTAssertEqual(result.0.scale, KingfisherManager.DefaultOptions.scale)
        
        XCTAssertTrue(result.1 === cache)
        XCTAssertTrue(result.1 !== manager.cache)
        XCTAssertEqual(result.2, manager.downloader)
    }
    
    func testParseMultipleOptions() {
        let cache = ImageCache(name: "KingfisherManagerTests")
        let downloader = ImageDownloader(name: "KingfisherManagerTests")
        let optionsInfo: KingfisherOptionsInfo = [.Options([.ForceRefresh, .CacheMemoryOnly]),
                                                  .TargetCache(cache),
                                                  .Downloader(downloader)]
        let result = manager.parseOptionsInfo(optionsInfo)
        
        XCTAssertEqual(result.0.forceRefresh, true)
        XCTAssertEqual(result.0.lowPriority, KingfisherManager.DefaultOptions.lowPriority)
        XCTAssertEqual(result.0.cacheMemoryOnly, true)
        XCTAssertEqual(result.0.shouldDecode, KingfisherManager.DefaultOptions.shouldDecode)
        XCTAssertEqual(result.0.scale, KingfisherManager.DefaultOptions.scale)
        
        XCTAssertTrue(result.1 === cache)
        XCTAssertFalse(result.1 === manager.cache)
        XCTAssertEqual(result.2, downloader)
        XCTAssertNotEqual(result.2, manager.downloader)
    }
}
