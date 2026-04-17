//  ImageDataProviderCancellationTests.swift
//  Regression tests for issue #2511:
//  "Images loaded with ImageDataProvider cannot be cancelled".
//
//  Before the fix, calling `DownloadTask.cancel()` or
//  `imageView.kf.cancelDownloadTask()` on a provider-backed load was a no-op,
//  and the completion handler still fired with `.success` after the provider
//  eventually delivered. After the fix, cancelling suppresses the success
//  callback and delivers `.failure(.requestError(.dataProviderCancelled))`,
//  matching the network source's behavior.

import XCTest
@testable import Kingfisher

private final class SlowDataProvider: ImageDataProvider, @unchecked Sendable {
    let cacheKey: String
    let delay: TimeInterval
    let payload: Data

    init(
        cacheKey: String = "slow-provider-\(UUID().uuidString)",
        delay: TimeInterval,
        payload: Data
    ) {
        self.cacheKey = cacheKey
        self.delay = delay
        self.payload = payload
    }

    func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        let payload = self.payload
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            handler(.success(payload))
        }
    }
}

final class ImageDataProviderCancellationTests: XCTestCase {

    private func makeManager() -> KingfisherManager {
        KingfisherManager(
            downloader: .default,
            cache: ImageCache(name: "provider-cancel-\(UUID().uuidString.prefix(8))")
        )
    }

    // Baseline: without cancel, the callback fires with .success.
    func testProviderDeliversWhenNotCancelled() {
        let manager = makeManager()
        let provider = SlowDataProvider(delay: 0.2, payload: testImageData)
        let done = expectation(description: "manager completion")

        _ = manager.retrieveImage(with: .provider(provider), options: nil) { result in
            if case .failure(let error) = result {
                XCTFail("unexpected failure: \(error)")
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 2.0)
    }

    // The `DownloadTask` returned for a provider source must now be non-nil
    // and its `cancel()` must actually stop the completion chain.
    func testCancellingProviderTaskDeliversCancelledError() {
        let manager = makeManager()
        let provider = SlowDataProvider(delay: 0.3, payload: testImageData)
        let done = expectation(description: "manager completion")

        let task = manager.retrieveImage(with: .provider(provider), options: nil) { result in
            switch result {
            case .success:
                XCTFail("provider load should have been cancelled, but got .success")
            case .failure(let error):
                if case .requestError(reason: .dataProviderCancelled) = error {
                    // expected
                } else {
                    XCTFail("expected .dataProviderCancelled, got: \(error)")
                }
            }
            done.fulfill()
        }

        XCTAssertNotNil(task, "retrieveImage should now return a cancellable task for provider sources (#2511)")
        task?.cancel()

        wait(for: [done], timeout: 2.0)
    }

    // End-to-end through the UIImageView/NSImageView extension path:
    // `imageView.kf.cancelDownloadTask()` must cancel the provider load and
    // deliver `.dataProviderCancelled` to the setImage completion.
    @MainActor
    func testImageViewCancelDownloadTaskCancelsProvider() {
        let imageView = KFCrossPlatformImageView()
        let provider = SlowDataProvider(delay: 0.3, payload: testImageData)
        let done = expectation(description: "setImage completion")

        imageView.kf.setImage(with: .provider(provider)) { result in
            switch result {
            case .success:
                XCTFail("setImage should have been cancelled, but got .success")
            case .failure(let error):
                if case .requestError(reason: .dataProviderCancelled) = error {
                    // expected
                } else {
                    XCTFail("expected .dataProviderCancelled, got: \(error)")
                }
            }
            done.fulfill()
        }

        imageView.kf.cancelDownloadTask()
        wait(for: [done], timeout: 2.0)
    }
}
