<!-- Generated: 2025-06-15 00:00:00 UTC -->

# Kingfisher Project Overview

## Project Purpose

Kingfisher is a powerful, pure-Swift library for downloading and caching images from the web. It provides an elegant, asynchronous API for managing remote images in iOS, macOS, tvOS, watchOS, and visionOS applications. The library handles the complete lifecycle of image loading - from network downloading to multi-layer caching (memory and disk), with built-in image processing capabilities and extensive platform-specific UI component integrations.

The framework follows a modular architecture with clear separation of concerns, allowing developers to use individual components (downloader, cache, processors) independently or as a unified solution. Through its namespace wrapper pattern (`.kf` property) and builder pattern (`KF.url()`), Kingfisher offers both UIKit and SwiftUI support with minimal code overhead.

## Main Entry Points

### Core Configuration
- **Package.swift** - Swift Package Manager manifest defining library targets and platform requirements
- **Kingfisher.podspec** - CocoaPods specification (version 8.3.2)
- **Sources/General/Kingfisher.swift** - Core type definitions and protocol declarations
- **Sources/General/KingfisherManager.swift** - Central coordinator managing download and cache operations

### Primary APIs
- **Sources/General/KF.swift** - Builder pattern entry point for fluent API
- **Sources/Extensions/ImageView+Kingfisher.swift** - UIImageView/NSImageView extensions
- **Sources/SwiftUI/KFImage.swift** - SwiftUI image component
- **Sources/SwiftUI/KFAnimatedImage.swift** - SwiftUI animated image support

## Technology Stack

### Core Components
- **Image Downloading**: `Sources/Networking/ImageDownloader.swift` - URLSession-based networking layer
- **Cache System**: 
  - `Sources/Cache/ImageCache.swift` - Dual-layer cache coordinator
  - `Sources/Cache/MemoryStorage.swift` - In-memory cache implementation
  - `Sources/Cache/DiskStorage.swift` - Persistent disk storage
- **Image Processing**: `Sources/Image/ImageProcessor.swift` - Transformation pipeline with filters
- **Format Support**: `Sources/Image/ImageFormat.swift` - Multi-format detection (JPEG, PNG, GIF, WebP)

### Platform Integrations
- **UIKit Extensions**: `Sources/Extensions/UIButton+Kingfisher.swift`, `Sources/Extensions/NSTextAttachment+Kingfisher.swift`
- **SwiftUI Components**: `Sources/SwiftUI/KFImageProtocol.swift`, `Sources/SwiftUI/ImageBinder.swift`
- **Specialized Views**: `Sources/Views/AnimatedImageView.swift`, `Sources/Extensions/PHLivePhotoView+Kingfisher.swift`

### Build & Testing
- **Fastlane**: `fastlane/Fastfile` - Primary build automation
- **Test Suite**: `Tests/KingfisherTests/` - XCTest-based unit tests with Nocilla HTTP stubbing
- **Documentation**: `Sources/Documentation.docc/` - DocC integrated documentation

## Platform Support

### Minimum Requirements
- **Swift**: 5.9+ (Swift 6 strict concurrency ready)
- **UIKit/AppKit**: 
  - iOS 13.0+ (`#if os(iOS)`)
  - macOS 10.15+ (`#if os(macOS)`)
  - tvOS 13.0+ (`#if os(tvOS)`)
  - watchOS 6.0+ (`#if os(watchOS)`)
  - visionOS 1.0+ (`#if os(visionOS)`)
- **SwiftUI**: iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+ / visionOS 1.0+

### Platform-Specific Files
- **macOS**: `Sources/Extensions/NSButton+Kingfisher.swift` - NSButton image loading
- **iOS/tvOS**: `Sources/Extensions/UIButton+Kingfisher.swift` - UIButton extensions
- **watchOS**: `Sources/Extensions/WKInterfaceImage+Kingfisher.swift` - WatchKit support
- **CarPlay**: `Sources/Extensions/CPListItem+Kingfisher.swift` - CarPlay list items (iOS 14.0+)
- **tvOS**: `Sources/Extensions/TVMonogramView+Kingfisher.swift` - Apple TV monogram views