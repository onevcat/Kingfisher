# Deployment Guide

<!-- Generated: 2025-06-15 10:15:30 UTC -->

This document provides comprehensive guidance for deploying Kingfisher across different platforms and distribution channels.

## Overview

Kingfisher supports multiple deployment strategies:

- **CocoaPods**: Traditional CocoaPods spec deployment
- **Swift Package Manager**: Native Swift package distribution
- **XCFramework**: Pre-built universal frameworks
- **GitHub Releases**: Automated release management

The deployment process is fully automated using Fastlane with comprehensive platform coverage across iOS, macOS, tvOS, watchOS, and visionOS.

## Package Types

### CocoaPods Distribution

**Configuration File**: `/Users/onevcat/Sync/github/Kingfisher/Kingfisher.podspec`

**Build Targets**:
- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 9.0+
- visionOS 1.0+

**Key Features**:
- Module stability enabled (`BUILD_LIBRARY_FOR_DISTRIBUTION`)
- Privacy manifest included (`PrivacyInfo.xcprivacy`)
- Required frameworks (CFNetwork, Accelerate)

### Swift Package Manager

**Configuration File**: `/Users/onevcat/Sync/github/Kingfisher/Package.swift`

**Build Targets**:
- Single library target: `Kingfisher`
- Source path: `Sources/`
- Minimum toolchain: Xcode 26.0+ / Swift 6.2+
- Swift tools version: 6.2; Swift 5 language mode
- Privacy manifest resource: `Sources/PrivacyInfo.xcprivacy`

**Platform Support**:
- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 9.0+
- visionOS 1.0+

### XCFramework Distribution

**Output Locations**:
```
build/
├── Kingfisher-{version}.xcframework.zip          # All platforms
├── Kingfisher-iOS-{version}.xcframework.zip      # iOS only
├── Kingfisher-{version}/
│   └── Kingfisher.xcframework/
│       ├── ios-arm64/
│       ├── ios-arm64_x86_64-simulator/
│       ├── macos-arm64_x86_64/
│       ├── tvos-arm64/
│       ├── tvos-arm64_x86_64-simulator/
│       ├── watchos-arm64_arm64_32_armv7k/
│       ├── watchos-arm64_i386_x86_64-simulator/
│       ├── xros-arm64/
│       └── xros-arm64_x86_64-simulator/
```

**Platform-Specific Archives**:
```
build/
├── Kingfisher-iphoneos.xcarchive/
├── Kingfisher-iphonesimulator.xcarchive/
├── Kingfisher-macosx.xcarchive/
├── Kingfisher-appletvos.xcarchive/
├── Kingfisher-appletvsimulator.xcarchive/
├── Kingfisher-watchos.xcarchive/
├── Kingfisher-watchsimulator.xcarchive/
├── Kingfisher-xros.xcarchive/
└── Kingfisher-xrsimulator.xcarchive/
```

## Platform-Specific Deployment

### iOS Deployment
- **Device**: `iphoneos` SDK
- **Simulator**: `iphonesimulator` SDK
- **Architectures**: arm64, x86_64 (simulator)
- **Framework Path**: `build/Kingfisher-iOS-{version}.xcframework.zip`

### macOS Deployment
- **SDK**: `macosx`
- **Architectures**: arm64, x86_64 (universal)
- **Framework Structure**: Traditional bundle format with versioning

### tvOS Deployment
- **Device**: `appletvos` SDK
- **Simulator**: `appletvsimulator` SDK
- **Architectures**: arm64, x86_64 (simulator)

### watchOS Deployment
- **Device**: `watchos` SDK
- **Simulator**: `watchsimulator` SDK
- **Architectures**: arm64, arm64_32, armv7k (device), i386, x86_64, arm64 (simulator)

### visionOS Deployment
- **Device**: `xros` SDK
- **Simulator**: `xrsimulator` SDK
- **Architectures**: arm64, x86_64 (simulator)

## Deployment Commands

### Complete Release Process

```bash
# Full release workflow
bundle exec fastlane release version:X.X.X

# Skip tests during release (not recommended)
bundle exec fastlane release version:X.X.X skip_tests:true
```

### Individual Components

```bash
# Create XCFramework only
bundle exec fastlane xcframework version:X.X.X

# Run linting
bundle exec fastlane lint

# Build for specific platform
bundle exec fastlane build_ci
```

### CocoaPods Deployment

```bash
# Lint podspec
pod lib lint Kingfisher.podspec

# Push to CocoaPods trunk (automated in release)
pod trunk push Kingfisher.podspec
```

### Swift Package Manager

```bash
# Build with SPM
swift build

# Test with SPM
swift test

# Validate package
swift package resolve
```

## Continuous Integration

### GitHub Actions Workflows

**Build Workflow**: `.github/workflows/build.yaml`
- Compile-only checks across older Xcode 26 and 27 versions; see `.github/workflows/build.yaml` for the current matrix
- Covers macOS, iOS Simulator, tvOS Simulator and watchOS Simulator for each Xcode version
- Verifies SwiftPM consumer integration and the privacy manifest

**Test Workflow**: `.github/workflows/test.yaml`
- Runs the test suite on the newest Xcode 26 and the newest Xcode 27; see `.github/workflows/test.yaml` for the current matrix
- Covers all platform destinations (watchOS is build-only)
- Concurrent execution with cancellation

**Matrix Rotation Rule**:
- The newest Xcode of each supported major runs tests; every other version is build-only
- Xcode 26.0.1 stays in the build matrix as the minimum supported toolchain
- When a new Xcode arrives, the previous test version moves to build-only and the oldest non-floor build version is dropped to keep CI time flat

**Runners**:
- `macos-26` (GitHub-hosted, macOS 26) for Xcode 26.x
- `xcode-27` (GitHub-hosted, macOS 27) for Xcode 27.x

## Release Management

### Automated Release Process

The release process handles:

1. **Pre-release Validation**:
   - Git branch verification
   - Clean git status check
   - Comprehensive testing across platforms
   - Podspec and SPM linting

2. **Version Management**:
   - Build number synchronization
   - Version number increment
   - Podspec version update
   - Changelog extraction

3. **Build Artifacts**:
   - XCFramework creation for all platforms
   - Code signing with Apple Distribution certificate
   - ZIP archive creation

4. **Distribution**:
   - Git tag creation with signing
   - GitHub release creation
   - Asset upload (both full and iOS-only XCFrameworks)
   - CocoaPods trunk push

### Changelog Management

**Configuration**: `/Users/onevcat/Sync/github/Kingfisher/pre-change.yml`

**Structure**:
```yaml
version: X.X.X
name: Release Name
fix:
  - Bug fix descriptions with issue links
add:
  - New feature descriptions
```

### Version Tagging

- **Format**: Semantic versioning (X.X.X)
- **Signing**: GPG signed tags
- **Automation**: Integrated with release workflow

## Reference

### Deployment Scripts

| Script Location | Purpose |
|----------------|---------|
| `fastlane/Fastfile` | Main deployment automation |
| `.github/workflows/build.yaml` | CI build workflow |
| `.github/workflows/test.yaml` | CI test workflow |
| `Gemfile` | Ruby dependencies |

### Build Output Locations

| Package Type | Location |
|-------------|----------|
| CocoaPods | Published to CocoaPods trunk |
| Swift Package Manager | Git repository tags |
| XCFramework (All) | `build/Kingfisher-{version}.xcframework.zip` |
| XCFramework (iOS) | `build/Kingfisher-iOS-{version}.xcframework.zip` |
| GitHub Release Assets | Attached to release tags |

### Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `GITHUB_TOKEN` | GitHub API authentication | Yes (release) |
| `DESTINATION` | CI build destination | Yes (CI) |
| `XCODE_VERSION` | Xcode version selection | Yes (CI) |

### Code Signing

- **Certificate**: Apple Distribution: Wei Wang (A4YJ9MRZ66)
- **Timestamp**: Enabled for all XCFramework builds
- **Verification**: Automated signature verification

### Server Configurations

**GitHub Actions**:
- **Runner Type**: GitHub-hosted (`macos-26`, `xcode-27`)
- **Concurrency**: Group-based with cancellation
- **Shell**: `bash -eo pipefail {0}`

**Ruby Environment**:
- **Fastlane**: Latest version
- **CocoaPods**: Latest version  
- **xcodes**: For Xcode version management

This deployment system ensures reliable, automated distribution across all supported Apple platforms with comprehensive testing and validation at each step.
