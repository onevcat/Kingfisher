<!-- Generated: 2025-06-15 12:45:00 UTC -->

# Kingfisher

Kingfisher is a powerful, pure-Swift library for downloading and caching images from the web, providing elegant async APIs for iOS, macOS, tvOS, watchOS, and visionOS applications. The library handles the complete image lifecycle with multi-layer caching, built-in processing, and extensive UI component integrations.

## Quick Start

**Core API Entry Points:**
- `Sources/General/KingfisherManager.swift` - Central coordinator
- `Sources/General/KF.swift` - Builder pattern API (`KF.url()...`)
- `Sources/Extensions/ImageView+Kingfisher.swift` - UIKit/AppKit extensions
- `Sources/SwiftUI/KFImage.swift` - SwiftUI components

**Essential Build Commands:**
```bash
# Install dependencies and run all tests
bundle install && bundle exec fastlane tests

# Build for specific platform
swift build

# Full release workflow
bundle exec fastlane release version:X.X.X
```

## Documentation

**For LLMs and Developers:**

- **[Project Overview](docs/project-overview.md)** - What Kingfisher does, core purpose, technology stack, and platform support
- **[Architecture](docs/architecture.md)** - System organization, component map, key files, and data flow with specific file references  
- **[Build System](docs/build-system.md)** - Swift Package Manager and Fastlane workflows, platform setup, and troubleshooting
- **[Testing](docs/testing.md)** - Test categories, running tests, and test infrastructure with file locations
- **[Development](docs/development.md)** - Code style, implementation patterns, workflows, and common solutions
- **[Deployment](docs/deployment.md)** - Package types, platform deployment, release management, and CI/CD
- **[File Catalog](docs/files.md)** - Comprehensive file organization with specific file purposes and relationships

**Configuration Files:**
- `Package.swift` - Swift Package Manager manifest
- `Kingfisher.podspec` - CocoaPods specification  
- `fastlane/Fastfile` - Build automation
- `Sources/Documentation.docc/` - DocC documentation

**Key Patterns:**
- Namespace wrapper (`.kf` property) in `Sources/General/Kingfisher.swift`
- Builder pattern API in `Sources/General/KF.swift` 
- Options system in `Sources/General/KingfisherOptionsInfo.swift`
- Protocol-oriented design throughout `Sources/Image/ImageProcessor.swift`

## Requirements

- **Swift 5.9+** (Swift 6 strict concurrency ready)
- **iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+ / visionOS 1.0+**
- **SwiftUI support**: iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+ / visionOS 1.0+