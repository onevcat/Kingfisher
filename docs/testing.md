<!-- Generated: 2025-06-15 08:30:00 UTC -->

# Kingfisher Testing Documentation

## Overview

Kingfisher's test suite is located in the `Tests/KingfisherTests/` directory and provides comprehensive coverage for all major components of the library. The test suite uses XCTest framework with custom helper utilities. It has no third-party dependency: HTTP requests are stubbed by a small `URLProtocol` subclass in the test target.

### Test Infrastructure

- **Test Framework**: XCTest
- **Network Mocking**: `StubURLProtocol` and `NetworkStub` (`Tests/KingfisherTests/Utils/NetworkStub.swift`)
- **Test Helper**: `Tests/KingfisherTests/KingfisherTestHelper.swift`
- **Stub Utilities**: `Tests/KingfisherTests/Utils/StubHelpers.swift`
- **Test Observer**: `Tests/KingfisherTests/Utils/KingfisherTestObserver.swift` (the `NSPrincipalClass` of the test bundle)
- **Test Assets**: 
  - `Tests/KingfisherTests/dancing-banana.gif` - Animated GIF for testing
  - `Tests/KingfisherTests/single-frame.gif` - Single frame GIF for testing

## Test Categories

### 1. Core Component Tests

**Cache Layer Tests**
- `Tests/KingfisherTests/ImageCacheTests.swift` - Tests for the main ImageCache functionality
- `Tests/KingfisherTests/MemoryStorageTests.swift` - Memory cache specific tests
- `Tests/KingfisherTests/DiskStorageTests.swift` - Disk storage specific tests
- `Tests/KingfisherTests/StorageExpirationTests.swift` - Cache expiration policy tests

**Networking Tests**
- `Tests/KingfisherTests/ImageDownloaderTests.swift` - Image downloading and session management
- `Tests/KingfisherTests/ImagePrefetcherTests.swift` - Batch image prefetching functionality
- `Tests/KingfisherTests/DataReceivingSideEffectTests.swift` - Data processing side effects

**Manager Tests**
- `Tests/KingfisherTests/KingfisherManagerTests.swift` - Central coordinator tests
- `Tests/KingfisherTests/KingfisherOptionsInfoTests.swift` - Configuration options tests

### 2. Image Processing Tests

- `Tests/KingfisherTests/ImageProcessorTests.swift` - Image transformation pipeline tests
- `Tests/KingfisherTests/ImageDrawingTests.swift` - Image drawing and rendering tests
- `Tests/KingfisherTests/ImageExtensionTests.swift` - Core image extensions tests
- `Tests/KingfisherTests/ImageModifierTests.swift` - Request modifier tests

### 3. UI Integration Tests

**UIKit Tests**
- `Tests/KingfisherTests/ImageViewExtensionTests.swift` - UIImageView extension tests
- `Tests/KingfisherTests/UIButtonExtensionTests.swift` - UIButton extension tests

**AppKit Tests**
- `Tests/KingfisherTests/NSButtonExtensionTests.swift` - NSButton extension tests (macOS)

### 4. Specialized Feature Tests

- `Tests/KingfisherTests/LivePhotoSourceTests.swift` - Live Photo support tests
- `Tests/KingfisherTests/ImageDataProviderTests.swift` - Custom data provider tests
- `Tests/KingfisherTests/RetryStrategyTests.swift` - Network retry strategy tests
- `Tests/KingfisherTests/StringExtensionTests.swift` - String utility extension tests

## Running Tests

### Using Fastlane

```bash
# Install dependencies first
bundle install

# Run all tests across all platforms
bundle exec fastlane tests

# Expected output:
# [08:30:00]: ------------------------------
# [08:30:00]: --- Step: default_platform ---
# [08:30:00]: ------------------------------
# [08:30:00]: Driving the lane 'ios tests' 🚀
# [08:30:01]: ------------------
# [08:30:01]: --- Step: scan ---
# [08:30:01]: ------------------
# [08:30:01]: Running Tests: ▸ Touching Kingfisher.framework
# [08:30:45]: Test Succeeded

# Run tests for specific platform
bundle exec fastlane test destination:"platform=iOS Simulator,name=iPhone 15"
bundle exec fastlane test destination:"platform=macOS"
bundle exec fastlane test destination:"platform=tvOS Simulator,name=Apple TV"

# CI-specific test command (used in continuous integration)
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=17.5" bundle exec fastlane test_ci

# Build only (for watchOS where full testing isn't supported)
bundle exec fastlane build destination:"platform=watchOS Simulator,name=Apple Watch Series 9 (41mm)"
```

### Using Xcode

```bash
# Open workspace in Xcode
open Kingfisher.xcworkspace

# Then use Xcode's test navigator or press Cmd+U to run all tests
# Or use xcodebuild directly:
xcodebuild test -workspace Kingfisher.xcworkspace -scheme Kingfisher -destination "platform=iOS Simulator,name=iPhone 15"
```

## Test File Organization Reference

### Directory Structure
```
Tests/
└── KingfisherTests/
    ├── Info.plist                      # Sets KingfisherTestObserver as NSPrincipalClass
    ├── KingfisherTestHelper.swift      # Main test helper utilities (TestClock, poll, ...)
    ├── Utils/
    │   ├── KingfisherTestObserver.swift  # Bundle-level setup and per-test reset
    │   ├── NetworkStub.swift           # URLProtocol based HTTP stub
    │   └── StubHelpers.swift           # Network stubbing helpers
    ├── dancing-banana.gif              # Animated test image
    ├── single-frame.gif                # Static test image
    └── *Tests.swift                    # Individual test files
```

### Build System Test Targets

**Xcode Scheme**: `Kingfisher.xcscheme`
- Configured for testing on all supported platforms
- Includes code coverage collection
- Uses parallel testing when available

**Fastlane Configuration**: `fastlane/Fastfile`
- `tests` lane: Runs tests on all platforms
- `test_ci` lane: CI-specific testing with environment-based destination
- `test` lane: Core test execution with scan action
- `build` lane: Build-only verification (used for watchOS)

**Platform Test Destinations**:
- iOS: `platform=iOS Simulator,name=iPhone 15,OS=17.5`
- macOS: `platform=macOS`
- tvOS: `platform=tvOS Simulator,name=Apple TV,OS=17.5`
- watchOS: `platform=watchOS Simulator,name=Apple Watch Series 9 (41mm),OS=10.5` (build only)

### Test Helper Utilities

The `KingfisherTestHelper.swift` provides:
- Pre-encoded test image data in various formats (PNG, JPEG, GIF, HEIC, MOV)
- Test URLs and keys for stubbing
- Cache cleanup utilities (`cleanDefaultCache`, `clearCaches`)
- Image comparison with tolerance (`renderEqual`)
- `TestClock` - A clock for cache expiration that a test moves forward by hand
- `poll(until:then:)` - Waits for an asynchronous side effect without a fixed delay
- Platform-specific test helpers

The `StubHelpers.swift` provides:
- `stub()` - Create HTTP response stubs with custom data and headers, optionally only for requests with given headers
- `heldStub()` - Create a stub that holds its requests until `release()` is called
- `stub(_:error:)` / `stub(_:errorCode:)` - Network error stubbing
- `ImageDownloader.stubbed(name:)` - A downloader whose session uses the stub

## Writing Network and Time-Dependent Tests

Do not wait for a fixed time. A fixed delay is too short on a busy CI machine and too long everywhere else. Wait for the event that the test is about.

### Network

- Every request goes to `StubURLProtocol`. `KingfisherTestObserver` sets it up for `ImageDownloader.default` (which `KingfisherManager.shared` uses) and for `URLSession.shared`. A session with its own configuration does not use it automatically: create downloaders with `ImageDownloader.stubbed(name:)` and sessions with `URLSessionConfiguration.stubbed`.
- A request without a matching stub fails with `UnexpectedRequestError`. Stub every URL that a test loads, also when the test only checks a failure.
- `heldStub()` keeps requests open until `release()`. No thread is blocked while a request is held, and a request that is cancelled while held never gets the response.
- To act after a request reached the network, wait for it: `await stub.waitForRequest()` or `wait(for: [stub.requestExpectation()])`.
- To check that a cancellation stopped the network request, wait for `stub.waitForStoppedRequest()` or `stub.stoppedRequestExpectation()`.
- Stubs are removed after each test. `clearStubs(afterCancelling:)` in `tearDown` also cancels the downloads of the test.

### Cache Expiration

- The cache reads the current date only through `ExpirationClock`. Use `TestClock().install()` and `clock.advance(by:)` instead of waiting for an expiration. The real clock is restored after each test.
- A `TestClock` starts at a whole second. Disk cache dates are stored as file attributes rounded up to whole seconds, so check expiration with dates between whole seconds (for example, `start.addingTimeInterval(2.5)`).

### Other Asynchronous Work

- Use `poll(until:then:)` to wait for a side effect that has no callback, for example a disk cache write when `.waitForCache` is not set.
- A short fixed window is still acceptable when the test checks that something does *not* happen (for example, a completion handler called only once) and there is no event to wait for. Keep such a window short and explain it in a comment.