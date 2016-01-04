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
}
