<!-- Generated: 2025-06-15 12:00:00 UTC -->

# Kingfisher Build System Documentation

## Overview

Kingfisher uses a dual build system approach supporting both Swift Package Manager and Fastlane/CocoaPods for maximum flexibility and distribution options.

### Primary Build Tools

- **Swift Package Manager** (`Package.swift`) - Modern dependency management and building
- **Fastlane** (`fastlane/Fastfile`) - Automated testing, building, and release workflows
- **CocoaPods** (`Kingfisher.podspec`) - Legacy distribution and integration
- **GitHub Actions** (`.github/workflows/`) - Continuous integration and testing

### Key Configuration Files

```
.
├── Package.swift                    # Swift Package Manager configuration
├── Kingfisher.podspec              # CocoaPods specification
├── Gemfile                         # Ruby dependencies for Fastlane/CocoaPods
├── fastlane/
│   ├── Fastfile                    # Fastlane automation workflows
│   └── actions/                    # Custom Fastlane actions
└── .github/workflows/
    ├── build.yaml                  # CI build workflow
    └── test.yaml                   # CI test workflow
```

## Build Workflows

### Building with Swift Package Manager

```bash
# Build for default platform
swift build

# Build with specific Swift version
swift build -Xswiftc -swift-version -Xswiftc 5

# Build for release
swift build -c release

# Build and run tests
swift test

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

### Building with Fastlane

First, install dependencies:
```bash
# Install Ruby dependencies
bundle install
```

Common build commands:
```bash
# Run all platform tests (iOS, macOS, tvOS, watchOS)
bundle exec fastlane tests

# Build for CI with specific destination
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=17.5" bundle exec fastlane build_ci

# Test for CI with specific destination  
DESTINATION="platform=macOS" bundle exec fastlane test_ci

# Build specific platform
bundle exec fastlane build destination:"platform=iOS Simulator,name=iPhone 15"

# Lint both CocoaPods and SPM
bundle exec fastlane lint
```

### Release Process

The release workflow automates versioning, tagging, and distribution:

```bash
# Full release (tests, lint, version bump, GitHub release, CocoaPods push)
bundle exec fastlane release version:X.X.X

# Skip tests during release
bundle exec fastlane release version:X.X.X skip_tests:true

# Create XCFramework for distribution
bundle exec fastlane xcframework version:X.X.X
```

Release steps performed:
1. Ensures clean git state and correct branch
2. Runs all tests (unless skipped)
3. Lints CocoaPods spec and SPM package
4. Updates version in all configuration files
5. Extracts and updates changelog
6. Creates signed git tag
7. Builds XCFramework for all platforms
8. Creates GitHub release with assets
9. Pushes to CocoaPods trunk

## Platform-specific Setup

### Supported Platforms

From `Package.swift` and `Kingfisher.podspec`:
- **iOS**: 13.0+
- **macOS**: 10.15+
- **tvOS**: 13.0+
- **watchOS**: 6.0+
- **visionOS**: 1.0+

### CI Test Matrix

From `.github/workflows/test.yaml`:
- **Destinations**: macOS, iOS Simulator, tvOS Simulator, watchOS Simulator
- **Xcode Versions**: 15.4, 16.2

### Platform Build Commands

```bash
# macOS
bundle exec fastlane test destination:"platform=macOS"

# iOS Simulator
bundle exec fastlane test destination:"platform=iOS Simulator,name=iPhone 15,OS=17.5"

# tvOS Simulator  
bundle exec fastlane test destination:"platform=tvOS Simulator,name=Apple TV,OS=17.5"

# watchOS Simulator (build only, no test)
bundle exec fastlane build destination:"platform=watchOS Simulator,name=Apple Watch Series 9 (41mm),OS=10.5"
```

## Reference

### Build Targets

From `Package.swift`:
- **Library**: `Kingfisher` (single library product)
- **Target**: `Kingfisher` (sources in `Sources/` directory)

### Fastlane Lanes

Available lanes in `fastlane/Fastfile`:

| Lane | Description | Parameters |
|------|-------------|------------|
| `tests` | Run tests on all platforms | None |
| `test` | Run tests on specific platform | `destination` |
| `build` | Build for specific platform | `destination` |
| `test_ci` | CI test lane (builds watchOS) | Uses `ENV["DESTINATION"]` |
| `build_ci` | CI build lane | Uses `ENV["DESTINATION"]` |
| `lint` | Lint CocoaPods spec and SPM | None |
| `release` | Full release workflow | `version`, `skip_tests` (optional) |
| `xcframework` | Build XCFramework | `version`, `swift_version`, `xcode_version` |

### Environment Variables

| Variable | Description | Used By |
|----------|-------------|---------|
| `DESTINATION` | Build/test destination | CI workflows |
| `XCODE_VERSION` | Xcode version to use | CI workflows, Fastlane |
| `GITHUB_TOKEN` | GitHub API token | Release workflow |

### Custom Fastlane Actions

Located in `fastlane/actions/`:
- `extract_current_change_log.rb` - Extract changelog for version
- `git_commit_all.rb` - Commit all changes
- `sync_build_number_to_git.rb` - Sync build number with git
- `update_change_log.rb` - Update changelog file

### Troubleshooting

#### Common Issues

1. **Bundle install fails**
   ```bash
   # Update bundler
   gem install bundler
   
   # Install with specific bundler version
   bundle _2.x.x_ install
   ```

2. **Xcode version mismatch**
   ```bash
   # Set Xcode version explicitly
   XCODE_VERSION=16.2 bundle exec fastlane tests
   
   # Or use xcode-select
   sudo xcode-select -s /Applications/Xcode_16.2.app
   ```

3. **Simulator not found**
   ```bash
   # List available simulators
   xcrun simctl list devices
   
   # Update destination string accordingly
   ```

4. **CocoaPods push fails**
   ```bash
   # Verify pod spec locally first
   pod lib lint Kingfisher.podspec
   
   # Register session if needed
   pod trunk register email@example.com
   ```

5. **Swift version issues**
   ```bash
   # Override Swift version in build
   bundle exec fastlane build xcargs:"SWIFT_VERSION=5.9"
   ```

### Build Settings

Key build settings used:
- `BUILD_LIBRARY_FOR_DISTRIBUTION`: YES (for XCFramework)
- `SKIP_INSTALL`: NO (for archiving)
- `SWIFT_VERSION`: 5.0 (default, can be overridden)

### Distribution Artifacts

Release builds generate:
- `Kingfisher-{version}.xcframework.zip` - All platforms XCFramework
- `Kingfisher-iOS-{version}.xcframework.zip` - iOS-only XCFramework

Both are code-signed with Apple Distribution certificate and uploaded to GitHub releases.