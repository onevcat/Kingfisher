<!-- Generated: 2025-06-15 08:30:00 UTC -->

# Kingfisher Testing Documentation

## Overview

Kingfisher's test suite is located in the `Tests/KingfisherTests/` directory and provides comprehensive coverage for all major components of the library. The test suite uses XCTest framework with custom helper utilities and the Nocilla dependency for HTTP request stubbing.

### Test Infrastructure

- **Test Framework**: XCTest
- **Network Mocking**: Nocilla (located at `Tests/Dependency/Nocilla/`)
- **Test Helper**: `Tests/KingfisherTests/KingfisherTestHelper.swift`
- **Stub Utilities**: `Tests/KingfisherTests/Utils/StubHelpers.swift`
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
├── Dependency/
│   └── Nocilla/              # HTTP stubbing framework
│       ├── LICENSE
│       ├── README.md
│       └── Nocilla/          # Nocilla source files
│           ├── Categories/   # NSData and NSString extensions
│           ├── DSL/          # Domain-specific language for stubbing
│           ├── Diff/         # Request diff utilities
│           ├── Hooks/        # HTTP client hooks (NSURLSession, etc.)
│           ├── Matchers/     # Request matching logic
│           ├── Model/        # HTTP request/response models
│           └── Stubs/        # Stub implementation
└── KingfisherTests/
    ├── Info.plist
    ├── KingfisherTestHelper.swift      # Main test helper utilities
    ├── KingfisherTests-Bridging-Header.h  # Objective-C bridging
    ├── Utils/
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
- Timing utilities (`delay`)
- Platform-specific test helpers

The `StubHelpers.swift` provides:
- `stub()` - Create HTTP response stubs with custom data and headers
- `delayedStub()` - Create delayed response stubs for timing tests
- Network error stubbing capabilities