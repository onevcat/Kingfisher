# Development Guide

<!-- Generated: 2025-06-15 12:40:15 UTC -->

## Overview

Kingfisher follows a modular architecture designed for maintainability, testability, and cross-platform compatibility. The development environment emphasizes protocol-oriented programming, namespace safety, and comprehensive test coverage. The codebase is organized into distinct functional modules with clear separation of concerns, following Swift's modern concurrency patterns and maintaining compatibility across iOS, macOS, tvOS, watchOS, and visionOS platforms.

The codebase implements several sophisticated design patterns including the namespace wrapper pattern for API safety, builder patterns for fluent configuration, and options patterns for flexible customization. All components are designed to be thread-safe with explicit concurrency annotations where needed. Development follows strict code style guidelines with comprehensive documentation, ensuring consistency across the large codebase.

Testing is integral to the development process, with extensive unit tests covering all major components, network mocking for reliable testing, and cross-platform validation. The build system uses Fastlane for automation, supporting multiple deployment targets and maintaining high quality standards through automated linting and testing workflows.

## Code Style Conventions

### File Headers and Documentation

All source files must include the standard license header:

```swift
//
//  FileName.swift
//  Kingfisher
//
//  Created by [Author] on [Date].
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software")...
```

### Naming Conventions

- **Files**: Use PascalCase with descriptive names (`ImageProcessor.swift`, `KingfisherManager.swift`)
- **Types**: PascalCase for classes, structs, protocols, and enums
- **Methods/Properties**: camelCase starting with lowercase
- **Constants**: Use `static let` for type constants, `let` for instance constants
- **Protocols**: Use descriptive names, often ending with `-able` or describing capability

Example from `/Users/onevcat/Sync/github/Kingfisher/Sources/General/Kingfisher.swift`:
```swift
public protocol KingfisherCompatible: AnyObject { }
public protocol KingfisherCompatibleValue {}
```

### Cross-Platform Type Aliases

Kingfisher uses consistent cross-platform type aliases defined in `/Users/onevcat/Sync/github/Kingfisher/Sources/General/Kingfisher.swift`:

```swift
#if os(macOS)
public typealias KFCrossPlatformImage       = NSImage
public typealias KFCrossPlatformView        = NSView
public typealias KFCrossPlatformColor       = NSColor
public typealias KFCrossPlatformImageView   = NSImageView
public typealias KFCrossPlatformButton      = NSButton
#else
public typealias KFCrossPlatformImage       = UIImage
public typealias KFCrossPlatformColor       = UIColor
// ... additional platform-specific definitions
#endif
```

### Sendable Compliance

Modern Swift concurrency is enforced throughout the codebase:

```swift
public struct KingfisherWrapper<Base>: @unchecked Sendable {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
```

## Common Implementation Patterns

### 1. Namespace Wrapper Pattern

The core pattern used throughout Kingfisher, implemented in `/Users/onevcat/Sync/github/Kingfisher/Sources/General/Kingfisher.swift`:

```swift
/// Wrapper for Kingfisher compatible types
public struct KingfisherWrapper<Base>: @unchecked Sendable {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/// Protocol for types that can use .kf namespace
public protocol KingfisherCompatible: AnyObject { }

extension KingfisherCompatible {
    /// Gets a namespace holder for Kingfisher compatible types
    public var kf: KingfisherWrapper<Self> {
        get { return KingfisherWrapper(self) }
        set { }
    }
}

// Usage in extensions
extension KFCrossPlatformImage: KingfisherCompatible { }
```

### 2. Builder Pattern

Fluent API implementation in `/Users/onevcat/Sync/github/Kingfisher/Sources/General/KF.swift`:

```swift
public enum KF {
    /// Creates a builder for a given URL
    public static func url(_ url: URL?, cacheKey: String? = nil) -> KF.Builder {
        source(url?.convertToSource(overrideCacheKey: cacheKey))
    }
}

extension KF {
    public class Builder: @unchecked Sendable {
        private let source: Source?
        private var _options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions)
        
        // Fluent configuration methods
        public func placeholder(_ image: KFCrossPlatformImage?) -> Self {
            self.placeholder = image
            return self
        }
    }
}
```

### 3. Options Pattern

Comprehensive options system in `/Users/onevcat/Sync/github/Kingfisher/Sources/General/KingfisherOptionsInfo.swift`:

```swift
/// Represents the available option items
public enum KingfisherOptionsInfoItem: Sendable {
    case targetCache(ImageCache)
    case downloader(ImageDownloader)
    case transition(ImageTransition)
    case downloadPriority(Float)
    case forceRefresh
    case processor(any ImageProcessor)
    // ... many more options
}

/// Parsed options for internal use
public struct KingfisherParsedOptionsInfo: Sendable {
    public var targetCache: ImageCache? = nil
    public var downloader: ImageDownloader? = nil
    public var transition: ImageTransition = .none
    // ... corresponding properties
    
    public init(_ info: KingfisherOptionsInfo?) {
        guard let info = info else { return }
        for option in info {
            switch option {
            case .targetCache(let value): targetCache = value
            case .downloader(let value): downloader = value
            // ... handle all options
            }
        }
    }
}
```

### 4. Protocol-Oriented Design

Example from `/Users/onevcat/Sync/github/Kingfisher/Sources/Image/ImageProcessor.swift`:

```swift
/// Protocol for image processing
public protocol ImageProcessor: Sendable {
    /// Identifier for caching and retrieval
    var identifier: String { get }
    
    /// Process the input item
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
}

extension ImageProcessor {
    /// Append processors in pipeline
    public func append(another: any ImageProcessor) -> any ImageProcessor {
        let newIdentifier = identifier.appending("|>\(another.identifier)")
        return GeneralProcessor(identifier: newIdentifier) { item, options in
            if let image = self.process(item: item, options: options) {
                return another.process(item: .image(image), options: options)
            } else {
                return nil
            }
        }
    }
}
```

### 5. Fluent Configuration with KFOptionSetter

Protocol-based fluent API in `/Users/onevcat/Sync/github/Kingfisher/Sources/General/KFOptionsSetter.swift`:

```swift
@MainActor
public protocol KFOptionSetter {
    var options: KingfisherParsedOptionsInfo { get nonmutating set }
    var onFailureDelegate: Delegate<KingfisherError, Void> { get }
    var onSuccessDelegate: Delegate<RetrieveImageResult, Void> { get }
    var onProgressDelegate: Delegate<(Int64, Int64), Void> { get }
}

extension KFOptionSetter {
    public func targetCache(_ cache: ImageCache) -> Self {
        options.targetCache = cache
        return self
    }
    
    public func downloader(_ downloader: ImageDownloader) -> Self {
        options.downloader = downloader
        return self
    }
}
```

## Development Workflows

### Setting Up Images for UI Components

**Common pattern for UIImageView/NSImageView** (file: `/Users/onevcat/Sync/github/Kingfisher/Sources/Extensions/ImageView+Kingfisher.swift`):

```swift
// Basic usage
imageView.kf.setImage(with: url)

// With configuration
imageView.kf.setImage(
    with: url,
    placeholder: placeholderImage,
    options: [.transition(.fade(0.2)), .cacheMemoryOnly],
    completionHandler: { result in
        // Handle result
    }
)
```

**Builder pattern approach**:
```swift
KF.url(imageURL)
    .placeholder(placeholderImage)
    .fade(duration: 0.2)
    .cacheMemoryOnly()
    .onSuccess { result in
        print("Image loaded: \(result.image)")
    }
    .set(to: imageView)
```

### Adding New Image Processors

1. **Create processor conforming to ImageProcessor protocol**:
```swift
struct CustomProcessor: ImageProcessor {
    var identifier: String { "com.example.custom" }
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        // Implementation
    }
}
```

2. **Add convenience method to KFOptionSetter** (file: `/Users/onevcat/Sync/github/Kingfisher/Sources/General/KFOptionsSetter.swift`):
```swift
extension KFOptionSetter {
    public func customEffect() -> Self {
        appendProcessor(CustomProcessor())
    }
}
```

### Extending Platform Support

**Add platform-specific extensions** (pattern from existing platform extensions):

1. **Update type aliases** in `/Users/onevcat/Sync/github/Kingfisher/Sources/General/Kingfisher.swift`
2. **Add compatibility conformance**:
```swift
#if os(newOS)
extension NewOSImageView: KingfisherCompatible { }
#endif
```
3. **Implement platform-specific extensions** following the pattern in existing platform files

### Cache Management Tasks

**Working with ImageCache** (main class: `/Users/onevcat/Sync/github/Kingfisher/Sources/Cache/ImageCache.swift`):

```swift
// Configure cache
let cache = ImageCache(name: "custom")
cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024 // 50MB
cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024 // 200MB

// Use with options
imageView.kf.setImage(with: url, options: [.targetCache(cache)])

// Manual cache operations
cache.store(image, forKey: key)
cache.retrieveImage(forKey: key) { result in
    // Handle cached image
}
```

## Reference

### File Organization

```
Sources/
├── General/           # Core managers, options, data providers
│   ├── KingfisherManager.swift     # Central coordinator
│   ├── KF.swift                    # Builder pattern API
│   ├── Kingfisher.swift            # Core protocols and wrappers
│   ├── KingfisherOptionsInfo.swift # Options system
│   └── ImageSource/                # Data source abstractions
├── Networking/        # Download, prefetch, session management
│   ├── ImageDownloader.swift       # Network layer
│   ├── ImagePrefetcher.swift       # Batch prefetching
│   └── RetryStrategy.swift         # Retry logic
├── Cache/            # Multi-layer caching system
│   ├── ImageCache.swift            # Main cache interface
│   ├── MemoryStorage.swift         # Memory cache backend
│   └── DiskStorage.swift           # Disk cache backend
├── Image/            # Processing, filters, formats, transitions
│   ├── ImageProcessor.swift        # Processing protocols
│   ├── Filter.swift                # Built-in processors
│   └── ImageTransition.swift       # UI transition effects
├── Extensions/       # UIKit/AppKit integration
│   ├── ImageView+Kingfisher.swift  # Main UI extensions
│   └── UIButton+Kingfisher.swift   # Button extensions
├── SwiftUI/         # SwiftUI-specific components
│   ├── KFImage.swift               # SwiftUI image component
│   └── KFAnimatedImage.swift       # Animated SwiftUI component
├── Utility/         # Helper utilities and extensions
└── Views/           # Custom UI components
```

### Naming Conventions

- **Manager classes**: `*Manager` (e.g., `KingfisherManager`)
- **Data providers**: `*Provider` or `*DataProvider` (e.g., `ImageDataProvider`)
- **Processors**: `*Processor` or `*ImageProcessor` (e.g., `BlurImageProcessor`)
- **Extensions**: `Type+Kingfisher.swift` (e.g., `UIButton+Kingfisher.swift`)
- **Protocols**: Descriptive names often with `-able` suffix (`KingfisherCompatible`)
- **Internal utilities**: Plain descriptive names (`CallbackQueue`, `Result`)

### Common Issues and Solutions

**Thread Safety**: All public APIs are designed to be thread-safe. Use `@MainActor` for UI-related operations and `@unchecked Sendable` for wrapper types.

**Memory Management**: Kingfisher uses both memory and disk caching. Configure limits appropriately:
```swift
ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
ImageCache.default.diskStorage.config.sizeLimit = 200 * 1024 * 1024
```

**Platform Differences**: Use platform-specific compilation directives and the provided cross-platform type aliases to ensure compatibility.

**Testing**: Use the testing utilities in `/Users/onevcat/Sync/github/Kingfisher/Tests/KingfisherTests/KingfisherTestHelper.swift` and follow the mocking patterns established in existing tests.

**Performance**: For large images, prefer `DownsamplingImageProcessor` over `ResizingImageProcessor` for better memory efficiency.