//
//  LivePhotoSourceTests.swift
//  Kingfisher
//
//  Created by onevcat on 2024/10/01.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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

class LivePhotoSourceTests: XCTestCase {
    
    func testLivePhotoResourceInitialization() {
        let url = URL(string: "https://example.com/photo.heic")!
        let resource = LivePhotoResource(downloadURL: url)
        
        XCTAssertEqual(resource.downloadURL, url)
        XCTAssertEqual(resource.referenceFileType, .heic)
    }
    
    func testLivePhotoResourceInitializationWithResource() {
        let url = URL(string: "https://example.com/photo.mov")!
        let imageResource = KF.ImageResource(downloadURL: url)
        let resource = LivePhotoResource(resource: imageResource)
        
        XCTAssertEqual(resource.downloadURL, url)
        XCTAssertEqual(resource.referenceFileType, .mov)
    }
    
    func testLivePhotoResourceFileExtensionByType() {
        let mov = LivePhotoResource.FileType.mov
        XCTAssertEqual(mov.determinedFileExtension(Data()), "mov")
        XCTAssertEqual(mov.fileExtension, "mov")
        
        let heic = LivePhotoResource.FileType.heic
        XCTAssertEqual(heic.determinedFileExtension(Data()), "heic")
        XCTAssertEqual(heic.fileExtension, "heic")
        
        let other = LivePhotoResource.FileType.other("exe")
        XCTAssertEqual(other.fileExtension, "exe")
    }
    
    func testLivePhotoResourceFileTypeDeterminationForHEIC() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63])
        let fileType = LivePhotoResource.FileType.other("")
        let determinedExtension = fileType.determinedFileExtension(data)
        
        XCTAssertEqual(determinedExtension, "heic")
    }

    func testLivePhotoResourceFileTypeDeterminationForQT() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20])
        let fileType = LivePhotoResource.FileType.other("")
        let determinedExtension = fileType.determinedFileExtension(data)
        
        XCTAssertEqual(determinedExtension, "mov")
    }

    func testLivePhotoResourceFileTypeDeterminationForExplicitFileType() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x20])
        let fileType = LivePhotoResource.FileType.other("ext")
        let determinedExtension = fileType.determinedFileExtension(data)
        
        XCTAssertEqual(determinedExtension, "ext")
    }

    func testLivePhotoResourceFileTypeDeterminationForUnknown() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x66, 0x74, 0x79, 0x70, 0x71, 0x74, 0x20, 0x22])
        let fileType = LivePhotoResource.FileType.other("")
        let determinedExtension = fileType.determinedFileExtension(data)
        
        XCTAssertEqual(determinedExtension, nil)
    }
    
    func testLivePhotoResourceFileTypeDeterminationForNonFYTP() {
        let data = Data([0x00, 0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78, 0x71, 0x74, 0x20, 0x20])
        let fileType = LivePhotoResource.FileType.other("")
        let determinedExtension = fileType.determinedFileExtension(data)
        
        XCTAssertEqual(determinedExtension, nil)
    }
    
    func testLivePhotoResourceFileTypeDeterminationForNotEnoughData() {
        let data = Data([0x00, 0x00, 0x00, 0x00])
        let fileType = LivePhotoResource.FileType.other("")
        let determinedExtension = fileType.determinedFileExtension(data)
        
        XCTAssertEqual(determinedExtension, nil)
    }
    
    func testLivePhotoSourceInitializationWithResources() {
        let url1 = URL(string: "https://example.com/photo1.heic")!
        let url2 = URL(string: "https://example.com/photo2.mov")!
        let resources = [KF.ImageResource(downloadURL: url1), KF.ImageResource(downloadURL: url2)]
        let livePhotoSource = LivePhotoSource(resources: resources)
        
        XCTAssertEqual(livePhotoSource.resources.count, 2)
        XCTAssertEqual(livePhotoSource.resources[0].downloadURL, url1)
        XCTAssertEqual(livePhotoSource.resources[1].downloadURL, url2)
    }
    
    func testLivePhotoSourceInitializationWithURLs() {
        let url1 = URL(string: "https://example.com/photo1.heic")!
        let url2 = URL(string: "https://example.com/photo2.mov")!
        let livePhotoSource = LivePhotoSource(urls: [url1, url2])
        
        XCTAssertEqual(livePhotoSource.resources.count, 2)
        XCTAssertEqual(livePhotoSource.resources[0].downloadURL, url1)
        XCTAssertEqual(livePhotoSource.resources[1].downloadURL, url2)
    }
    
    func testLivePhotoResourceInitializationWithCacheKey() {
        let url = URL(string: "https://example.com/photo.heic")!
        let cacheKey = "customCacheKey"
        let resource = LivePhotoResource(downloadURL: url, cacheKey: cacheKey)
        
        XCTAssertEqual(resource.downloadURL, url)
        XCTAssertEqual(resource.cacheKey, cacheKey)
        XCTAssertEqual(resource.referenceFileType, .heic)
    }

    func testLivePhotoResourceInitializationWithFileType() {
        let url = URL(string: "https://example.com/photo.unknown")!
        let resource = LivePhotoResource(downloadURL: url, fileType: .other("unknown"))
        
        XCTAssertEqual(resource.downloadURL, url)
        XCTAssertEqual(resource.referenceFileType, .other("unknown"))
    }

    func testLivePhotoResourceGuessedFileType() {
        let url1 = URL(string: "https://example.com/photo.heic")!
        let url2 = URL(string: "https://example.com/photo.mov")!
        let url3 = URL(string: "https://example.com/photo.unknown")!
        
        let resource1 = KF.ImageResource(downloadURL: url1)
        let resource2 = KF.ImageResource(downloadURL: url2)
        let resource3 = KF.ImageResource(downloadURL: url3)
        
        XCTAssertEqual(resource1.guessedFileType, .heic)
        XCTAssertEqual(resource2.guessedFileType, .mov)
        XCTAssertEqual(resource3.guessedFileType, .other("unknown"))
    }

    func testLivePhotoSourceInitializationWithMixedResources() {
        let url1 = URL(string: "https://example.com/photo1.heic")!
        let url2 = URL(string: "https://example.com/photo2.mov")!
        let url3 = URL(string: "https://example.com/photo3.unknown")!
        let resources = [
            KF.ImageResource(downloadURL: url1),
            KF.ImageResource(downloadURL: url2),
            KF.ImageResource(downloadURL: url3)
        ]
        let livePhotoSource = LivePhotoSource(resources: resources)
        
        XCTAssertEqual(livePhotoSource.resources.count, 3)
        XCTAssertEqual(livePhotoSource.resources[0].downloadURL, url1)
        XCTAssertEqual(livePhotoSource.resources[1].downloadURL, url2)
        XCTAssertEqual(livePhotoSource.resources[2].downloadURL, url3)
        XCTAssertEqual(livePhotoSource.resources[0].referenceFileType, .heic)
        XCTAssertEqual(livePhotoSource.resources[1].referenceFileType, .mov)
        XCTAssertEqual(livePhotoSource.resources[2].referenceFileType, .other("unknown"))
    }

}
