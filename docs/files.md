# File Catalog - Kingfisher

<!-- Generated: 2025-06-15 12:00:00 UTC -->

## Overview

Kingfisher is a modern Swift library for loading and caching images, built with a modular structure and protocol-oriented design. The project clearly separates different concerns and uses a namespace pattern (.kf) to provide a consistent API for UIKit, AppKit, and SwiftUI. Its core components include KingfisherManager as the central coordinator, ImageDownloader for handling network tasks, ImageCache for a dual-layer caching system, and ImageProcessor for managing image transformation pipelines.

The project supports multiple platforms (iOS, macOS, tvOS, watchOS, visionOS) and uses Fastlane as its main build system. It employs the XCTest framework for testing and integrates the DocC documentation system. Files are organized based on functionality, with the Sources directory divided by modules, configuration files centrally managed, and Demo projects offering complete usage examples.

## Core Source Files

### Primary Framework Components
- **`Sources/General/KingfisherManager.swift`** - Central coordinator managing image loading workflow
- **`Sources/General/KF.swift`** - Main entry point providing builder pattern API for image tasks  
- **`Sources/General/Kingfisher.swift`** - Core framework module with KingfisherCompatible protocol
- **`Sources/General/KingfisherOptionsInfo.swift`** - Configuration options container for all operations
- **`Sources/General/KingfisherError.swift`** - Error handling system with detailed error types
- **`Sources/General/KFOptionsSetter.swift`** - Options configuration builder for method chaining

### Image Source and Data Providers
- **`Sources/General/ImageSource/Resource.swift`** - URL resource definitions and transformations
- **`Sources/General/ImageSource/Source.swift`** - Abstract image source protocols and implementations
- **`Sources/General/ImageSource/ImageDataProvider.swift`** - Data provider protocol for custom image sources
- **`Sources/General/ImageSource/AVAssetImageDataProvider.swift`** - AVAsset image frame extraction
- **`Sources/General/ImageSource/PHPickerResultImageDataProvider.swift`** - Photo picker integration
- **`Sources/General/ImageSource/LivePhotoSource.swift`** - Live Photo support implementation

### Network Layer
- **`Sources/Networking/ImageDownloader.swift`** - HTTP image downloading with session management
- **`Sources/Networking/ImageDownloader+LivePhoto.swift`** - Live Photo downloading extensions
- **`Sources/Networking/ImageDownloaderDelegate.swift`** - Download progress and completion delegation
- **`Sources/Networking/SessionDelegate.swift`** - URLSession delegate handling authentication and redirects
- **`Sources/Networking/SessionDataTask.swift`** - Custom data task wrapper with cancellation support
- **`Sources/Networking/ImagePrefetcher.swift`** - Batch image prefetching for performance optimization
- **`Sources/Networking/RequestModifier.swift`** - HTTP request modification protocols
- **`Sources/Networking/ImageModifier.swift`** - Response image modification protocols
- **`Sources/Networking/RedirectHandler.swift`** - HTTP redirect handling strategies
- **`Sources/Networking/RetryStrategy.swift`** - Failed request retry logic and policies
- **`Sources/Networking/AuthenticationChallengeResponsable.swift`** - Authentication challenge handling
- **`Sources/Networking/ImageDataProcessor.swift`** - Raw image data processing pipeline

### Caching System
- **`Sources/Cache/ImageCache.swift`** - Dual-layer (memory + disk) caching coordinator
- **`Sources/Cache/MemoryStorage.swift`** - In-memory LRU cache with automatic cleanup
- **`Sources/Cache/DiskStorage.swift`** - Persistent disk storage with expiration policies
- **`Sources/Cache/Storage.swift`** - Abstract storage protocols and configurations
- **`Sources/Cache/CacheSerializer.swift`** - Image serialization for disk persistence
- **`Sources/Cache/FormatIndicatedCacheSerializer.swift`** - Format-aware image serialization

### Image Processing and Transformation
- **`Sources/Image/Image.swift`** - Cross-platform image type definitions and utilities
- **`Sources/Image/ImageProcessor.swift`** - Image transformation and processing pipeline
- **`Sources/Image/Filter.swift`** - Built-in image filters (blur, tint, overlay, etc.)
- **`Sources/Image/ImageFormat.swift`** - Image format detection and handling
- **`Sources/Image/ImageDrawing.swift`** - Core graphics drawing utilities and extensions
- **`Sources/Image/ImageTransition.swift`** - View transition animations for image loading
- **`Sources/Image/ImageProgressive.swift`** - Progressive JPEG loading implementation
- **`Sources/Image/GIFAnimatedImage.swift`** - GIF animation support and playback
- **`Sources/Image/GraphicsContext.swift`** - Graphics context management and utilities
- **`Sources/Image/Placeholder.swift`** - Placeholder image definitions and protocols

## Platform Implementation Files

### UIKit Extensions
- **`Sources/Extensions/ImageView+Kingfisher.swift`** - UIImageView integration with .kf namespace
- **`Sources/Extensions/UIButton+Kingfisher.swift`** - UIButton background/image loading support
- **`Sources/Extensions/NSTextAttachment+Kingfisher.swift`** - Text attachment image loading

### AppKit Extensions  
- **`Sources/Extensions/NSButton+Kingfisher.swift`** - macOS NSButton image loading integration
- **`Sources/Extensions/HasImageComponent+Kingfisher.swift`** - Generic image component protocol

### Cross-Platform Extensions
- **`Sources/Extensions/PHLivePhotoView+Kingfisher.swift`** - Live Photo view integration
- **`Sources/Extensions/CPListItem+Kingfisher.swift`** - CarPlay list item support

### SwiftUI Components
- **`Sources/SwiftUI/KFImage.swift`** - Main SwiftUI image view component
- **`Sources/SwiftUI/KFAnimatedImage.swift`** - Animated image support for SwiftUI
- **`Sources/SwiftUI/KFImageOptions.swift`** - SwiftUI-specific configuration options
- **`Sources/SwiftUI/KFImageProtocol.swift`** - Shared protocol for KF SwiftUI components
- **`Sources/SwiftUI/KFImageRenderer.swift`** - SwiftUI view rendering and update logic
- **`Sources/SwiftUI/ImageBinder.swift`** - Binding layer between SwiftUI and Kingfisher core
- **`Sources/SwiftUI/ImageContext.swift`** - SwiftUI image loading context management

### Custom Views
- **`Sources/Views/AnimatedImageView.swift`** - Custom animated image view for GIF playback
- **`Sources/Views/Indicator.swift`** - Loading indicator views and protocols

## Build System Files

### Package Management
- **`Package.swift`** - Swift Package Manager manifest with dependencies and targets
- **`Package@swift-5.9.swift`** - Swift 5.9 compatibility package manifest
- **`Kingfisher.podspec`** - CocoaPods specification for distribution
- **`Gemfile`** - Ruby dependencies for Fastlane and build tools
- **`Gemfile.lock`** - Locked Ruby gem versions for reproducible builds

### Fastlane Build Automation
- **`fastlane/Fastfile`** - Main Fastlane configuration with lanes for testing, building, and releasing
- **`fastlane/actions/extract_current_change_log.rb`** - Extracts current version changelog
- **`fastlane/actions/git_commit_all.rb`** - Git commit automation with custom messages
- **`fastlane/actions/sync_build_number_to_git.rb`** - Synchronizes build numbers with git commits
- **`fastlane/actions/update_change_log.rb`** - Automated changelog management
- **`fastlane/README.md`** - Fastlane documentation and usage instructions

### Xcode Project Files
- **`Kingfisher.xcodeproj/`** - Main Xcode project with targets and build settings
- **`Kingfisher.xcworkspace/`** - Xcode workspace for integrated development
- **`Demo/Kingfisher-Demo.xcodeproj/`** - Demo application Xcode project

## Configuration Files

### Framework Configuration
- **`Sources/Info.plist`** - Framework bundle information and version metadata
- **`Sources/PrivacyInfo.xcprivacy`** - Privacy manifest for App Store compliance

### Development Assets
- **`images/`** - Sample images for testing and demo applications
  - `kingfisher-1.jpg` through `kingfisher-10.jpg` - Test image assets
  - `logo.png` - Project logo and branding
- **`Tests/KingfisherTests/dancing-banana.gif`** - GIF test asset for animation testing
- **`Tests/KingfisherTests/single-frame.gif`** - Single-frame GIF for edge case testing

### Demo Applications
- **`Demo/Demo/Kingfisher-Demo/`** - iOS demo app showcasing all features
  - `ViewControllers/` - Various demo screens (GIF, transitions, processors, etc.)
  - `SwiftUIViews/` - SwiftUI demonstration views and regression tests
- **`Demo/Demo/Kingfisher-macOS-Demo/`** - macOS demo application
- **`Demo/Demo/Kingfisher-tvOS-Demo/`** - Apple TV demo application  
- **`Demo/Demo/Kingfisher-watchOS-Demo/`** - watchOS demo application

### Git and CI Configuration
- **`pre-change.yml`** - Pre-commit hook configuration for code quality
- **`.gitignore`** - Git ignore patterns for build artifacts and dependencies

## Utility and Helper Files

### Core Utilities
- **`Sources/Utility/ExtensionHelpers.swift`** - Cross-platform compatibility helpers
- **`Sources/Utility/CallbackQueue.swift`** - Thread-safe callback queue management
- **`Sources/Utility/Box.swift`** - Reference wrapper for value types
- **`Sources/Utility/Result.swift`** - Result type utilities and extensions
- **`Sources/Utility/Delegate.swift`** - Weak delegate wrapper to prevent retain cycles
- **`Sources/Utility/Runtime.swift`** - Runtime reflection and dynamic dispatch utilities
- **`Sources/Utility/DisplayLink.swift`** - Cross-platform display link abstraction
- **`Sources/Utility/SizeExtensions.swift`** - CGSize manipulation and calculations
- **`Sources/Utility/String+SHA256.swift`** - String hashing for cache key generation

### Test Infrastructure
- **`Tests/KingfisherTests/KingfisherTestHelper.swift`** - Shared testing utilities and mocks
- **`Tests/KingfisherTests/Utils/StubHelpers.swift`** - HTTP stubbing helpers for network tests
- **`Tests/Dependency/Nocilla/`** - HTTP mocking framework for isolated testing

### Documentation System
- **`Sources/Documentation.docc/`** - DocC documentation bundle
  - `Documentation.md` - Main documentation entry point
  - `GettingStarted.md` - Quick start guide for new users
  - `Tutorials/` - Step-by-step tutorials for UIKit and SwiftUI
  - `CommonTasks/` - Task-oriented documentation for common use cases
  - `Topics/` - Advanced topic guides (prefetching, indicators, etc.)
  - `Resources/` - Documentation assets, images, and code samples

## Reference

### File Organization Patterns
- **Modular Structure**: Core functionality separated into logical modules (General, Networking, Cache, Image, etc.)
- **Platform Abstraction**: Cross-platform code in core modules, platform-specific extensions separate
- **Protocol-Oriented**: Heavy use of protocols for customization and testing
- **Namespace Pattern**: All public APIs accessed through `.kf` property extension

### Naming Conventions
- **Files**: PascalCase with descriptive names indicating functionality
- **Protocols**: Suffix with `-able` for capabilities (e.g., `AuthenticationChallengeResponsable`)
- **Extensions**: Platform prefix for clarity (e.g., `UIButton+Kingfisher.swift`)
- **Tests**: Mirror source structure with `Tests` suffix

### Dependency Relationships
- **Core Dependencies**: Foundation, UIKit/AppKit conditionally imported
- **SwiftUI Module**: Depends on core modules but isolated for optional usage
- **Extensions**: Depend on core but platform-specific
- **Test Dependencies**: Isolated with Nocilla for HTTP mocking
- **Build Dependencies**: Fastlane for automation, Ruby gems for tooling

### Key Integration Points
- **KingfisherCompatible Protocol**: Entry point for all functionality via `.kf` namespace
- **Options System**: Centralized configuration through `KingfisherOptionsInfo`
- **Result Types**: Consistent error handling with `Result<Success, KingfisherError>`
- **Callback Queues**: Thread-safe completion handling across all async operations