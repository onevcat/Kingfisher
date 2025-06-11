# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

### Primary Build System
This project uses **Fastlane** for primary build automation. Key commands:

```bash
# Install dependencies
bundle install

# Run all tests across platforms (iOS, macOS, tvOS, watchOS)
bundle exec fastlane tests

# Run specific platform tests (used in CI)
bundle exec fastlane test_ci

# Build for specific platform
bundle exec fastlane build_ci

# Lint CocoaPods spec and Swift Package Manager
bundle exec fastlane lint

# Swift Package Manager (alternative)
swift build
swift test
```

### Release Process
```bash
# Full release workflow (tests, linting, versioning, GitHub release, CocoaPods push)
bundle exec fastlane release version:X.X.X
```

## Architecture Overview

Kingfisher is a modular image loading and caching library with clear separation of concerns:

### Core Components Flow
1. **KingfisherManager** (`Sources/General/KingfisherManager.swift`) - Central coordinator
2. **ImageDownloader** (`Sources/Networking/ImageDownloader.swift`) - Network layer
3. **ImageCache** (`Sources/Cache/ImageCache.swift`) - Dual-layer caching (memory + disk)
4. **ImageProcessor** (`Sources/Image/ImageProcessor.swift`) - Image transformation pipeline

### Key Architectural Patterns
- **Protocol-oriented design** with `KingfisherCompatible` protocol
- **Namespace wrapper pattern** - All functionality accessed via `.kf` property
- **Builder pattern** - `KF.url()...` method chaining
- **Options pattern** - `KingfisherOptionsInfo` for configuration

### Module Structure
```
Sources/
├── General/           # Core managers, options, data providers
├── Networking/        # Download, prefetch, session management  
├── Cache/            # Multi-layer caching system
├── Image/            # Processing, filters, formats, transitions
├── Extensions/       # UIKit/AppKit/SwiftUI integration
├── SwiftUI/         # SwiftUI-specific components
├── Utility/         # Helper utilities and extensions
└── Views/           # Custom UI components
```

### Integration Points
- **UIKit**: Extensions for `UIImageView`, `UIButton` via `.kf` namespace
- **SwiftUI**: `KFImage` and `KFAnimatedImage` components
- **Cross-platform**: Extensive conditional compilation for iOS/macOS/tvOS/watchOS/visionOS

## Platform Support
- **UIKit/AppKit**: iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+ / visionOS 1.0+
- **SwiftUI**: iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+ / visionOS 1.0+
- **Swift**: 5.9+ (with Swift 6 strict concurrency support)

## Testing

### Test Structure
- **Location**: `Tests/KingfisherTests/`
- **Framework**: XCTest with custom `KingfisherTestHelper`
- **Network mocking**: Uses Nocilla dependency for HTTP stubbing
- **Test assets**: `dancing-banana.gif`, `single-frame.gif`

### Running Tests
```bash
# All platforms (preferred)
bundle exec fastlane tests

# Swift Package Manager only
swift test

# Single platform via destination
bundle exec fastlane test destination:"platform=iOS Simulator,name=iPhone 15"
```

## Key Files for Development

### Essential Files to Understand
1. `Sources/General/Kingfisher.swift` - Base types, protocols, and KingfisherCompatible
2. `Sources/General/KingfisherManager.swift` - Central coordinator managing all operations
3. `Sources/General/KingfisherOptionsInfo.swift` - Options system and configuration
4. `Sources/Extensions/ImageView+Kingfisher.swift` - Primary UIKit integration
5. `Sources/SwiftUI/KFImage.swift` - Primary SwiftUI integration

### Configuration Files
- `Package.swift` / `Package@swift-5.9.swift` - Swift Package Manager configuration
- `Kingfisher.podspec` - CocoaPods specification
- `fastlane/Fastfile` - Build automation and release process
- `Sources/PrivacyInfo.xcprivacy` - App Store privacy compliance

## Documentation System
- **DocC integration** with comprehensive tutorials and API docs
- **Location**: `Sources/Documentation.docc/`
- **Online**: Swift Package Index hosted documentation
- **Tutorials**: Both UIKit and SwiftUI getting started guides available