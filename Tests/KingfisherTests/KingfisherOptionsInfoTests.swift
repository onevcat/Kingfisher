//
//  KingfisherOptionsInfoTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/4.
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
#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine
#endif

class KingfisherOptionsInfoTests: XCTestCase {

    func testEmptyOptionsShouldParseCorrectly() {
        let options = KingfisherParsedOptionsInfo(KingfisherOptionsInfo.empty)
        XCTAssertTrue(options.targetCache === nil)
        XCTAssertTrue(options.downloader === nil)

#if os(iOS) || os(tvOS) || os(visionOS)
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
        XCTAssertEqual(options.callbackQueue.queue.label, DispatchQueue.main.label)
        XCTAssertEqual(options.scaleFactor, 1.0)
        XCTAssertFalse(options.keepCurrentImageWhileLoading)
        XCTAssertFalse(options.onlyLoadFirstFrame)
        XCTAssertFalse(options.cacheOriginalImage)
        XCTAssertEqual(options.diskStoreWriteOptions, [])
    }
    
    func testSetOptionsShouldParseCorrectly() {
        let cache = ImageCache(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        let downloader = ImageDownloader(name: "com.onevcat.Kingfisher.KingfisherOptionsInfoTests")
        
        let queue = DispatchQueue.global(qos: .default)
        let testModifier = TestModifier()
        let testRedirectHandler = TestRedirectHandler()
        let processor = RoundCornerImageProcessor(cornerRadius: 20)
        let serializer = FormatIndicatedCacheSerializer.png
        let modifier = AnyImageModifier { i in return i }
        let alternativeSource = Source.network(URL(string: "https://onevcat.com")!)

        var options = KingfisherParsedOptionsInfo([
            .targetCache(cache),
            .downloader(downloader),
            .originalCache(cache),
            .downloadPriority(0.8),
            .forceRefresh,
            .forceTransition,
            .fromMemoryCacheOrRefresh,
            .cacheMemoryOnly,
            .waitForCache,
            .onlyFromCache,
            .backgroundDecode,
            .callbackQueue(.dispatch(queue)),
            .scaleFactor(2.0),
            .preloadAllAnimationData,
            .requestModifier(testModifier),
            .redirectHandler(testRedirectHandler),
            .processor(processor),
            .cacheSerializer(serializer),
            .imageModifier(modifier),
            .keepCurrentImageWhileLoading,
            .onlyLoadFirstFrame,
            .cacheOriginalImage,
            .diskStoreWriteOptions([.atomic]),
            .alternativeSources([alternativeSource]),
            .retryStrategy(DelayRetryStrategy(maxRetryCount: 10))
        ])
        
        XCTAssertTrue(options.targetCache === cache)
        XCTAssertTrue(options.originalCache === cache)
        XCTAssertTrue(options.downloader === downloader)

        #if os(iOS) || os(tvOS) || os(visionOS)
        let transition = ImageTransition.fade(0.5)
        options.transition = transition
        switch options.transition {
        case .fade(let duration): XCTAssertEqual(duration, 0.5)
        default: XCTFail()
        }
        #endif
        
        XCTAssertEqual(options.downloadPriority, 0.8)
        XCTAssertTrue(options.forceRefresh)
        XCTAssertTrue(options.fromMemoryCacheOrRefresh)
        XCTAssertTrue(options.forceTransition)
        XCTAssertTrue(options.cacheMemoryOnly)
        XCTAssertTrue(options.waitForCache)
        XCTAssertTrue(options.onlyFromCache)
        XCTAssertTrue(options.backgroundDecode)
        
        XCTAssertEqual(options.callbackQueue.queue.label, queue.label)
        XCTAssertEqual(options.scaleFactor, 2.0)
        XCTAssertTrue(options.preloadAllAnimationData)
        XCTAssertTrue(options.requestModifier is TestModifier)
        XCTAssertTrue(options.redirectHandler is TestRedirectHandler)
        XCTAssertEqual(options.processor.identifier, processor.identifier)
        XCTAssertTrue(options.cacheSerializer is FormatIndicatedCacheSerializer)
        XCTAssertTrue(options.imageModifier is AnyImageModifier)
        XCTAssertTrue(options.keepCurrentImageWhileLoading)
        XCTAssertTrue(options.onlyLoadFirstFrame)
        XCTAssertTrue(options.cacheOriginalImage)
        XCTAssertEqual(options.diskStoreWriteOptions, [Data.WritingOptions.atomic])
        XCTAssertEqual(options.alternativeSources?.count, 1)
        XCTAssertEqual(options.alternativeSources?.first?.url, alternativeSource.url)

        let retry = options.retryStrategy as? DelayRetryStrategy
        XCTAssertNotNil(retry)
        XCTAssertEqual(retry?.maxRetryCount, 10)
    }
    
    func testOptionCouldBeOverwritten() {
        var options = KingfisherParsedOptionsInfo([.downloadPriority(0.5), .onlyFromCache])
        XCTAssertEqual(options.downloadPriority, 0.5)

        options = KingfisherParsedOptionsInfo([.downloadPriority(0.5), .onlyFromCache, .downloadPriority(0.8)])
        XCTAssertEqual(options.downloadPriority, 0.8)
    }

    #if canImport(SwiftUI) && canImport(Combine)
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @MainActor
    func testKFImageContextModifiersDoNotMutateOriginalImage() {
        let url = URL(string: "https://example.com/image.png")!
        let image = KFImage(url)

        let withPlaceholder = image.placeholder {
            Text("Loading")
        }
        let withCancelOnDisappear = image.cancelOnDisappear(true)

        XCTAssertFalse(image.context === withPlaceholder.context)
        XCTAssertFalse(image.context === withCancelOnDisappear.context)
        XCTAssertNil(image.context.placeholder)
        XCTAssertFalse(image.context.cancelOnDisappear)

        XCTAssertNotNil(withPlaceholder.context.placeholder)
        XCTAssertFalse(withPlaceholder.context.cancelOnDisappear)

        XCTAssertNil(withCancelOnDisappear.context.placeholder)
        XCTAssertTrue(withCancelOnDisappear.context.cancelOnDisappear)
    }
    
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @MainActor
    func testKFImageOptionModifiersDoNotMutateOriginalImage() {
        let url = URL(string: "https://example.com/image.png")!
        let image = KFImage(url)

        let withMemoryExpiration = image.memoryCacheExpiration(.seconds(60))
        let withForceRefresh = image.forceRefresh(true)

        XCTAssertFalse(image.context === withMemoryExpiration.context)
        XCTAssertFalse(image.context === withForceRefresh.context)
        XCTAssertNil(image.context.options.memoryCacheExpiration)
        XCTAssertFalse(image.context.options.forceRefresh)

        switch withMemoryExpiration.context.options.memoryCacheExpiration {
        case .seconds(let seconds):
            XCTAssertEqual(seconds, 60)
        default:
            XCTFail("Expected memory cache expiration to be set on derived image.")
        }
        XCTAssertFalse(withMemoryExpiration.context.options.forceRefresh)

        XCTAssertNil(withForceRefresh.context.options.memoryCacheExpiration)
        XCTAssertTrue(withForceRefresh.context.options.forceRefresh)
    }
    
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @MainActor
    func testKFImageCallbackModifiersDoNotShareDelegateState() {
        let url = URL(string: "https://example.com/image.png")!
        let image = KFImage(url)

        let withSuccess = image.onSuccess { _ in }
        let withFailure = image.onFailure { _ in }

        XCTAssertFalse(image.context === withSuccess.context)
        XCTAssertFalse(image.context === withFailure.context)
        XCTAssertFalse(image.context.onSuccessDelegate.isSet)
        XCTAssertFalse(image.context.onFailureDelegate.isSet)

        XCTAssertTrue(withSuccess.context.onSuccessDelegate.isSet)
        XCTAssertFalse(withSuccess.context.onFailureDelegate.isSet)

        XCTAssertFalse(withFailure.context.onSuccessDelegate.isSet)
        XCTAssertTrue(withFailure.context.onFailureDelegate.isSet)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @MainActor
    func testKFImageModifierChainPreservesEarlierSettings() {
        let url = URL(string: "https://example.com/image.png")!
        let image = KFImage(url)
            .placeholder { Text("Loading") }
            .cancelOnDisappear(true)
            .resizable()
            .forceRefresh()
            .onSuccess { _ in }

        // Every modifier copies the context, so settings applied earlier in the chain must survive each copy.
        // This fails if `Context.copy()` misses a stored property.
        XCTAssertNotNil(image.context.placeholder)
        XCTAssertTrue(image.context.cancelOnDisappear)
        XCTAssertEqual(image.context.configurations.count, 1)
        XCTAssertTrue(image.context.options.forceRefresh)
        XCTAssertTrue(image.context.onSuccessDelegate.isSet)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    @available(*, deprecated) // Silences the deprecation warning for `onFailureImage` under test.
    @MainActor
    func testKFImageOnFailureImageDoesNotMutateOriginalImage() {
        let url = URL(string: "https://example.com/image.png")!
        let image = KFImage(url)

        let withFailureImage = image.onFailureImage(testImage)

        XCTAssertFalse(image.context === withFailureImage.context)
        XCTAssertNil(image.context.options.onFailureImage ?? nil)
        XCTAssertNotNil(withFailureImage.context.options.onFailureImage ?? nil)
    }
    #endif
}

final class TestModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        return nil
    }
}

final class TestRedirectHandler: ImageDownloadRedirectHandler {
    func handleHTTPRedirection(
        for task: Kingfisher.SessionDataTask, response: HTTPURLResponse, newRequest: URLRequest
    ) async -> URLRequest? {
        newRequest
    }
}
