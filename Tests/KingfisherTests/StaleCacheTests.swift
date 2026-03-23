//
//  StaleCacheTests.swift
//  Kingfisher
//
//  Tests for issue #2495: Disk cache retrieval should skip deserialization
//  when the requesting task is no longer current.
//

import XCTest
@testable import Kingfisher

// MARK: - ImageCache Stale Tests

class ImageCacheStaleDiskRetrievalTests: XCTestCase {

    var cache: ImageCache!

    override func setUp() {
        super.setUp()
        let uuid = UUID().uuidString
        cache = ImageCache(name: "test-stale-\(uuid)")
    }

    override func tearDown() {
        clearCaches([cache])
        cache = nil
        super.tearDown()
    }

    // MARK: - Helper

    /// Store an image to disk only (clear memory after store).
    private func storeToDiskOnly(
        image: KFCrossPlatformImage = testImage,
        data: Data = testImageData,
        forKey key: String,
        options: KingfisherParsedOptionsInfo = KingfisherParsedOptionsInfo(nil),
        completion: @escaping () -> Void
    ) {
        cache.store(image, original: data, forKey: key, options: options, toDisk: true) { _ in
            self.cache.memoryStorage.remove(forKey: key)
            let computedKey = key.computedKey(with: options.processor.identifier)
            self.cache.memoryStorage.remove(forKey: computedKey)
            XCTAssertTrue(
                self.cache.imageCachedType(
                    forKey: key,
                    processorIdentifier: options.processor.identifier
                ).cached
            )
            XCTAssertNil(
                self.cache.retrieveImageInMemoryCache(forKey: key, options: options)
            )
            completion()
        }
    }

    // MARK: - Test 1: Stale checker skips serializer

    /// When `sourceTaskIdentifierChecker` returns `false` before disk retrieval starts,
    /// `CacheSerializer.image(with:)` must NOT be called, and the result should indicate
    /// the task was skipped. Memory cache must NOT be populated.
    func testRetrieveImageInDiskCacheReturnsStaleWithoutCallingSerializerWhenCheckerIsAlreadyFalse() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let spy = SpyCacheSerializer()

        storeToDiskOnly(forKey: key) {
            var options = KingfisherParsedOptionsInfo(nil)
            options.cacheSerializer = spy
            // Checker already false — task is stale from the start.
            options.sourceTaskIdentifierChecker = { false }

            self.cache.retrieveImage(forKey: key, options: options) { result in
                // The stale request should not produce a valid image.
                XCTAssertNil(result.value?.image, "Stale task should not return a decoded image")

                // Serializer must not have been called.
                XCTAssertEqual(spy.imageCallCount, 0, "Serializer should not be called for stale tasks")

                // Memory cache must not be populated.
                XCTAssertNil(
                    self.cache.retrieveImageInMemoryCache(forKey: key),
                    "Stale task should not promote image to memory cache"
                )
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Test 2: Valid checker proceeds normally

    /// When `sourceTaskIdentifierChecker` returns `true`, the full deserialization path
    /// should run: serializer called, image returned, image promoted to memory cache.
    func testRetrieveImageInDiskCacheReturnsImageWhenCheckerStaysTrue() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let spy = SpyCacheSerializer()

        storeToDiskOnly(forKey: key) {
            var options = KingfisherParsedOptionsInfo(nil)
            options.cacheSerializer = spy
            options.sourceTaskIdentifierChecker = { true }

            self.cache.retrieveImage(forKey: key, options: options) { result in
                XCTAssertNotNil(result.value?.image, "Valid task should return a decoded image")
                XCTAssertEqual(result.value?.cacheType, .disk)

                // Serializer must have been called exactly once.
                XCTAssertEqual(spy.imageCallCount, 1, "Serializer should be called for valid tasks")

                // Image should be promoted to memory cache.
                XCTAssertNotNil(
                    self.cache.retrieveImageInMemoryCache(forKey: key),
                    "Valid task should promote image to memory cache"
                )
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Test 3: Checker flips after disk read, before deserialize

    /// Use a count-based checker to deterministically test CHECK 2: the checker
    /// returns `true` on its first invocation (passes CHECK 1), then `false` on
    /// its second invocation (caught by CHECK 2, before deserialize).
    func testRetrieveImageInDiskCacheReturnsStaleWhenCheckerTurnsFalseAfterDiskReadBeforeDeserialize() {
        let exp = expectation(description: #function)
        let key = testKeys[0]
        let spy = SpyCacheSerializer()

        storeToDiskOnly(forKey: key) {
            var options = KingfisherParsedOptionsInfo(nil)
            options.cacheSerializer = spy

            // First call (CHECK 1) returns true, second call (CHECK 2) returns false.
            let callCount = LockIsolated(0)
            options.sourceTaskIdentifierChecker = {
                callCount.withValue { count -> Bool in
                    count += 1
                    return count <= 1
                }
            }

            self.cache.retrieveImage(forKey: key, options: options) { result in
                // The request became stale after disk read but before deserialize.
                XCTAssertNil(result.value?.image, "Should not return image when checker flips before deserialize")

                // Serializer should NOT have been called — CHECK 2 fires first.
                XCTAssertEqual(spy.imageCallCount, 0, "Serializer should not run for stale tasks")

                // Memory should not be populated.
                XCTAssertNil(self.cache.retrieveImageInMemoryCache(forKey: key))
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Test 4: Skip backgroundDecode when checker turns false after deserialize

    /// The third check point: after `cacheSerializer.image()` succeeds but before
    /// `backgroundDecode` runs, the checker flips to false. The result should be stale
    /// and `decoded(scale:)` should not execute.
    func testRetrieveImageInDiskCacheSkipsBackgroundDecodeWhenCheckerTurnsFalseAfterDeserialize() {
        let exp = expectation(description: #function)
        let key = testKeys[0]

        storeToDiskOnly(forKey: key) {
            // Use a spy that flips the stale flag after being called.
            let serializerCalled = LockIsolated(false)
            let spy = SpyCacheSerializer()
            let isStale = LockIsolated(false)

            // Wrap the spy to flip stale after it runs.
            let flippingSerializer = FlipAfterDeserializeSerializer(
                wrapped: spy,
                onDeserialized: { isStale.setValue(true) }
            )

            var options = KingfisherParsedOptionsInfo(nil)
            options.cacheSerializer = flippingSerializer
            options.backgroundDecode = true
            options.sourceTaskIdentifierChecker = { !isStale.value }

            self.cache.retrieveImage(forKey: key, options: options) { result in
                // Serializer was called (CHECK 2 passed because checker was still true).
                XCTAssertEqual(spy.imageCallCount, 1, "Serializer should have been called")
                _ = serializerCalled

                // But the result should be stale because the checker flipped
                // after deserialize and before backgroundDecode.
                XCTAssertNil(result.value?.image, "Should not return image when stale before backgroundDecode")

                // Memory should not be populated.
                XCTAssertNil(self.cache.retrieveImageInMemoryCache(forKey: key))
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}

// MARK: - Retry Strategy Stale Tests

class RetryStrategyStaleCacheTests: XCTestCase {

    var manager: KingfisherManager!

    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        let uuid = UUID()
        let downloader = ImageDownloader(name: "test.retry.stale.\(uuid.uuidString)")
        let cache = ImageCache(name: "test.retry.stale.cache.\(uuid.uuidString)")
        manager = KingfisherManager(downloader: downloader, cache: cache)
        manager.defaultOptions = [.waitForCache]
    }

    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }

    // MARK: - Test 5: Stale disk cache result does not enter retry

    /// When a disk-cached image retrieval becomes stale, the retry strategy must NOT be
    /// consulted. This prevents the retry loop described in the analysis document.
    func testKingfisherManagerDoesNotRetryWhenDiskCacheRetrievalBecomesStale() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let counter = CountingRetryStrategy()

        // Stub network just in case — it should never be hit.
        stub(url, data: testImageData)

        // Pre-populate disk cache.
        manager.cache.store(testImage, original: testImageData, forKey: url.cacheKey, toDisk: true) { _ in
            self.manager.cache.clearMemoryCache()

            // Use the internal API with a stale checker and retry strategy.
            _ = self.manager.retrieveImage(
                with: .network(url),
                options: KingfisherParsedOptionsInfo([.retryStrategy(counter)]),
                downloadTaskUpdated: nil,
                progressiveImageSetter: nil,
                referenceTaskIdentifierChecker: { false },
                completionHandler: { result in
                    // Retry strategy should never have been called.
                    XCTAssertEqual(counter.retryCount, 0, "Stale cache result must not trigger retry")
                    exp.fulfill()
                }
            )
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    /// Same scenario as above, but also verify that the completion handler is called
    /// exactly once even when a retry strategy is configured.
    func testKingfisherManagerStaleDiskCacheResultInvokesCompletionOnceEvenWithRetryStrategy() {
        let exp = expectation(description: #function)
        let url = testURLs[1]
        let counter = CountingRetryStrategy()
        let completionCount = LockIsolated(0)

        stub(url, data: testImageData)

        manager.cache.store(testImage, original: testImageData, forKey: url.cacheKey, toDisk: true) { _ in
            self.manager.cache.clearMemoryCache()

            var options = KingfisherParsedOptionsInfo([.retryStrategy(counter)])
            options.sourceTaskIdentifierChecker = { false }

            _ = self.manager.retrieveImage(
                with: .network(url),
                options: options,
                downloadTaskUpdated: nil,
                progressiveImageSetter: nil,
                referenceTaskIdentifierChecker: { false },
                completionHandler: { result in
                    completionCount.withValue { $0 += 1 }

                    // Give a moment for any spurious extra calls.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        XCTAssertEqual(completionCount.value, 1, "Completion must be called exactly once")
                        XCTAssertEqual(counter.retryCount, 0, "Retry must not be triggered")
                        exp.fulfill()
                    }
                }
            )
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}

// MARK: - KingfisherManager Stale Tests

class KingfisherManagerStaleCacheTests: XCTestCase {

    var manager: KingfisherManager!

    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        let uuid = UUID()
        let downloader = ImageDownloader(name: "test.manager.stale.\(uuid.uuidString)")
        let cache = ImageCache(name: "test.manager.stale.cache.\(uuid.uuidString)")
        manager = KingfisherManager(downloader: downloader, cache: cache)
        manager.defaultOptions = [.waitForCache]
    }

    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        clearCaches([manager.cache])
        cleanDefaultCache()
        manager = nil
        super.tearDown()
    }

    // MARK: - Test 7: Stale result does not use alternative sources

    /// When the primary source's disk cache retrieval is stale, `alternativeSources`
    /// must NOT be attempted.
    func testRetrieveImageFromCacheDoesNotUseAlternativeSourcesWhenResultIsStale() {
        let exp = expectation(description: #function)
        let primaryURL = testURLs[0]
        let alternativeURL = testURLs[1]
        let recorder = RequestRecorder()

        // Stub both URLs.
        stub(primaryURL, data: testImageData)
        stub(alternativeURL, data: testImageData)

        // Pre-populate primary in disk cache.
        manager.cache.store(testImage, original: testImageData, forKey: primaryURL.cacheKey, toDisk: true) { _ in
            self.manager.cache.clearMemoryCache()

            var options = KingfisherParsedOptionsInfo([
                .alternativeSources([.network(alternativeURL)]),
                .requestModifier(recorder)
            ])
            options.sourceTaskIdentifierChecker = { false }

            _ = self.manager.retrieveImage(
                with: .network(primaryURL),
                options: options,
                downloadTaskUpdated: nil,
                progressiveImageSetter: nil,
                referenceTaskIdentifierChecker: { false },
                completionHandler: { result in
                    if case .success(let value) = result {
                        XCTFail("Stale task should not succeed via alternative source. Got image from: \(value.source)")
                    }

                    // Verify at the request level that the alternative URL was never hit.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        XCTAssertFalse(
                            recorder.requestedURLs.contains(alternativeURL),
                            "Alternative source URL must not be requested for stale tasks"
                        )
                        XCTAssertTrue(
                            recorder.requestedURLs.isEmpty,
                            "No network requests should be made for stale disk-cached tasks"
                        )
                        exp.fulfill()
                    }
                }
            )
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Test 8: Path 2 (original + processor) does not download when stale

    /// When only the original (unprocessed) image is on disk and a custom processor is
    /// configured (path 2), a stale checker must prevent `loadAndCacheImage` from being called.
    func testRetrieveImageFromOriginalCacheWithProcessorDoesNotDownloadWhenResultIsStale() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let key = url.cacheKey
        let processor = RoundCornerImageProcessor(cornerRadius: 20)
        let recorder = RequestRecorder()

        // Stub the URL. If download is triggered, the network will be hit.
        stub(url, data: testImageData)

        // Store the ORIGINAL (unprocessed) image to disk only.
        manager.cache.store(
            testImage, original: testImageData, forKey: key,
            toDisk: true
        ) { _ in
            self.manager.cache.clearMemoryCache()

            // Verify: original is cached, processed is NOT cached.
            let originalCached = self.manager.cache.imageCachedType(
                forKey: key, processorIdentifier: DefaultImageProcessor.default.identifier)
            XCTAssertTrue(originalCached.cached, "Original image must be cached for this test")

            let processedCached = self.manager.cache.imageCachedType(
                forKey: key, processorIdentifier: processor.identifier)
            XCTAssertFalse(processedCached.cached, "Processed image must NOT be cached for this test")

            let downloadTaskUpdated = LockIsolated(false)

            var options = KingfisherParsedOptionsInfo([
                .processor(processor),
                .requestModifier(recorder)
            ])
            options.sourceTaskIdentifierChecker = { false }

            _ = self.manager.retrieveImage(
                with: .network(url),
                options: options,
                downloadTaskUpdated: { task in
                    if task != nil {
                        downloadTaskUpdated.setValue(true)
                    }
                },
                progressiveImageSetter: nil,
                referenceTaskIdentifierChecker: { false },
                completionHandler: { result in
                    // Download should not have been triggered.
                    XCTAssertFalse(downloadTaskUpdated.value, "Stale task must not trigger download in path 2")

                    // Verify at the network request level.
                    XCTAssertTrue(recorder.requestedURLs.isEmpty, "No network request should be made for stale path-2 tasks")

                    // Result should not be a success with a processed image.
                    if case .success = result {
                        XCTFail("Stale task should not produce a success result")
                    }
                    exp.fulfill()
                }
            )
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Test 9: Path 2 happy path (valid checker)

    /// Same path 2 scenario, but checker stays `true`. The processor must be called,
    /// processed image returned, and stored in the target cache.
    func testRetrieveImageFromOriginalCacheWithProcessorProcessesNormallyWhenCurrent() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let key = url.cacheKey
        let processor = RoundCornerImageProcessor(cornerRadius: 20)

        stub(url, data: testImageData)

        manager.cache.store(
            testImage, original: testImageData, forKey: key,
            toDisk: true
        ) { _ in
            self.manager.cache.clearMemoryCache()

            _ = self.manager.retrieveImage(
                with: .network(url),
                options: KingfisherParsedOptionsInfo([.processor(processor), .waitForCache]),
                downloadTaskUpdated: nil,
                progressiveImageSetter: nil,
                referenceTaskIdentifierChecker: { true },
                completionHandler: { result in
                    XCTAssertNotNil(result.value?.image, "Valid task should return processed image")

                    // Processed image should now be cached.
                    let processedCached = self.manager.cache.imageCachedType(
                        forKey: key, processorIdentifier: processor.identifier)
                    XCTAssertTrue(processedCached.cached, "Processed image should be stored in cache")
                    exp.fulfill()
                }
            )
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Test 10: No checker keeps existing behavior

    /// When `sourceTaskIdentifierChecker` is nil (direct API usage without view extensions),
    /// the behavior must be identical to current: cache miss leads to download, etc.
    func testRetrieveImageWithoutCheckerKeepsExistingBehavior() {
        let exp = expectation(description: #function)
        let url = testURLs[0]

        stub(url, data: testImageData)

        // No pre-cached image. Should fall through to download.
        manager.retrieveImage(with: url, options: [.waitForCache]) { result in
            XCTAssertNotNil(result.value?.image, "Should download and return image")
            XCTAssertEqual(result.value!.cacheType, .none, "Should be a fresh download")

            // Second call should hit memory cache.
            self.manager.retrieveImage(with: url) { result in
                XCTAssertEqual(result.value?.cacheType, .memory, "Should be from memory cache")
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}

// MARK: - ImageView Extension Stale Tests

#if os(iOS) || os(tvOS) || os(visionOS)
class ImageViewExtensionStaleCacheTests: XCTestCase, @unchecked Sendable {

    var imageView: KFCrossPlatformImageView!

    override class func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
    }

    override class func tearDown() {
        LSNocilla.sharedInstance().stop()
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        imageView = KFCrossPlatformImageView()
        KingfisherManager.shared.downloader = ImageDownloader(name: "testDownloader.stale")
        KingfisherManager.shared.defaultOptions = [.waitForCache]
        cleanDefaultCache()
    }

    override func tearDown() {
        LSNocilla.sharedInstance().clearStubs()
        imageView = nil
        cleanDefaultCache()
        KingfisherManager.shared.defaultOptions = .empty
        super.tearDown()
    }

    // MARK: - Test 11: Stale disk retrieval does not promote to memory

    /// Verify that a superseded disk cache retrieval does not promote its decoded
    /// image to memory cache. Uses `CoordinatingCacheSerializer` to deterministically
    /// hold url1's ioQueue block in the serializer, then supersede with url2. After
    /// the serializer proceeds, CHECK 3 detects the stale token and discards url1's
    /// result. Only url2 ends up in memory cache.
    @MainActor func testStaleDiskCacheRetrievalDoesNotPromoteToMemoryWhenSuperseded() {
        let exp = expectation(description: #function)
        let url1 = testURLs[0]
        let url2 = testURLs[1]
        let coordinator = CoordinatingCacheSerializer()

        // Pre-cache both images to disk via the shared cache.
        let cache = KingfisherManager.shared.cache
        let group = DispatchGroup()

        group.enter()
        cache.store(testImage, original: testImageData, forKey: url1.cacheKey, toDisk: true) { _ in
            group.leave()
        }
        group.enter()
        cache.store(testImage, original: testImageData, forKey: url2.cacheKey, toDisk: true) { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            // Clear memory so both must come from disk.
            cache.clearMemoryCache()

            let completionGroup = DispatchGroup()

            // Step 1: Start url1's retrieval. Its ioQueue block will enter the
            //         coordinator serializer and block there.
            completionGroup.enter()
            self.imageView.kf.setImage(
                with: url1,
                options: [.cacheSerializer(coordinator)]
            ) { result in
                XCTAssertNotNil(result.error)
                if case .imageSettingError(reason: .notCurrentSourceTask) = result.error! {
                    // Expected
                } else {
                    XCTFail("First setImage should receive .notCurrentSourceTask, got: \(result.error!)")
                }
                completionGroup.leave()
            }

            // Step 2: Wait (on background) for url1's serializer to start,
            //         then supersede on main thread.
            DispatchQueue.global().async {
                coordinator.waitUntilFirstCallEntered()

                DispatchQueue.main.async {
                    // Step 3: url1's token is now cancelled by the second setImage.
                    completionGroup.enter()
                    self.imageView.kf.setImage(
                        with: url2,
                        options: [.cacheSerializer(coordinator)]
                    ) { result in
                        XCTAssertNotNil(result.value?.image, "Second setImage should succeed")
                        completionGroup.leave()
                    }

                    // Step 4: Let url1's serializer proceed. CHECK 3 will detect
                    //         stale (token1 is cancelled) and discard the result.
                    coordinator.allowFirstCallToProceed()
                }
            }

            completionGroup.notify(queue: .main) {
                // url1's serializer ran (call 1) but CHECK 3 discarded the result.
                // url2's serializer ran (call 2) and succeeded.
                // The key assertion: url1 was NOT promoted to memory cache.
                XCTAssertNil(
                    cache.retrieveImageInMemoryCache(forKey: url1.cacheKey),
                    "Stale task's image must not be promoted to memory cache"
                )
                XCTAssertNotNil(
                    cache.retrieveImageInMemoryCache(forKey: url2.cacheKey),
                    "Current task's image must be in memory cache"
                )
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    // MARK: - Test 12: Each completion called exactly once

    /// Same dual-setImage scenario. Verify that each completion handler is called
    /// exactly once: first with `.notCurrentSourceTask`, second with `.success`.
    @MainActor func testSettingTwoDiskCachedImagesOnSameViewCallsEachCompletionExactlyOnce() {
        let exp = expectation(description: #function)
        let url1 = testURLs[0]
        let url2 = testURLs[1]

        let cache = KingfisherManager.shared.cache
        let group = DispatchGroup()

        group.enter()
        cache.store(testImage, original: testImageData, forKey: url1.cacheKey, toDisk: true) { _ in
            group.leave()
        }
        group.enter()
        cache.store(testImage, original: testImageData, forKey: url2.cacheKey, toDisk: true) { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            cache.clearMemoryCache()

            let completion1Count = LockIsolated(0)
            let completion2Count = LockIsolated(0)
            let completion1IsError = LockIsolated(false)
            let completion2IsSuccess = LockIsolated(false)

            let completionGroup = DispatchGroup()

            completionGroup.enter()
            self.imageView.kf.setImage(with: url1) { result in
                completion1Count.withValue { $0 += 1 }
                if case .failure(let error) = result,
                   case .imageSettingError(reason: .notCurrentSourceTask) = error {
                    completion1IsError.setValue(true)
                }
                completionGroup.leave()
            }

            completionGroup.enter()
            self.imageView.kf.setImage(with: url2) { result in
                completion2Count.withValue { $0 += 1 }
                if case .success = result {
                    completion2IsSuccess.setValue(true)
                }
                completionGroup.leave()
            }

            completionGroup.notify(queue: .main) {
                // Allow time for any spurious extra callbacks.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    XCTAssertEqual(completion1Count.value, 1, "First completion must be called exactly once")
                    XCTAssertEqual(completion2Count.value, 1, "Second completion must be called exactly once")
                    XCTAssertTrue(completion1IsError.value, "First completion should be .notCurrentSourceTask")
                    XCTAssertTrue(completion2IsSuccess.value, "Second completion should be .success")
                    exp.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    // MARK: - Test 13: cancelDownloadTask cancels disk cache retrieval

    /// When `cancelDownloadTask()` is called on a view whose current request is
    /// a disk cache hit (no DownloadTask), the CancellationToken must still be
    /// cancelled so the ioQueue skips deserialization. This is the exact scenario
    /// described in issue #2495.
    @MainActor func testCancelDownloadTaskCancelsDiskCacheRetrieval() {
        let exp = expectation(description: #function)
        let url = testURLs[0]
        let coordinator = CoordinatingCacheSerializer()
        let cache = KingfisherManager.shared.cache

        let storeExp = expectation(description: "store")
        cache.store(testImage, original: testImageData, forKey: url.cacheKey, toDisk: true) { _ in
            storeExp.fulfill()
        }
        wait(for: [storeExp], timeout: 3)
        cache.clearMemoryCache()

        // Start a disk cache retrieval. The ioQueue block will block in
        // the coordinator serializer.
        imageView.kf.setImage(
            with: url,
            options: [.cacheSerializer(coordinator)]
        ) { result in
            exp.fulfill()
        }

        // Wait for the ioQueue block to reach the serializer.
        DispatchQueue.global().async {
            coordinator.waitUntilFirstCallEntered()

            DispatchQueue.main.async {
                // Cancel via the public API — this is the #2495 scenario.
                self.imageView.kf.cancelDownloadTask()

                // Let the serializer proceed. CHECK 3 should detect stale.
                coordinator.allowFirstCallToProceed()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)

        // The image must NOT be promoted to memory — the cancel was effective.
        XCTAssertNil(
            cache.retrieveImageInMemoryCache(forKey: url.cacheKey),
            "cancelDownloadTask() must prevent disk cache result from being promoted to memory"
        )
    }
}
#endif

// MARK: - FlipAfterDeserializeSerializer

/// A serializer wrapper that calls `onDeserialized` after the inner serializer runs.
/// Used to simulate the timing window between deserialization and backgroundDecode.
final class FlipAfterDeserializeSerializer: CacheSerializer, @unchecked Sendable {
    private let wrapped: SpyCacheSerializer
    private let onDeserialized: @Sendable () -> Void

    init(wrapped: SpyCacheSerializer, onDeserialized: @escaping @Sendable () -> Void) {
        self.wrapped = wrapped
        self.onDeserialized = onDeserialized
    }

    func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        wrapped.data(with: image, original: original)
    }

    func image(with data: Data, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        let result = wrapped.image(with: data, options: options)
        onDeserialized()
        return result
    }
}
