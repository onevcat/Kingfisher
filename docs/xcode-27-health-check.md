# Xcode 27 health check

Date: 2026-09-15. Baseline: `ab1c1de54a1ce1adfe1733c7195056a153029d3a`.
Branch: `fix/xcode-27-health-check`.

## Environment

- macOS 27.0 (26A428), Xcode 27.0 (27A266a), Apple Swift 6.4.
- Developer directory: `/Applications/Xcode-27.0.app/Contents/Developer`.
- iOS, tvOS, watchOS, and visionOS SDKs and simulator runtimes: 27.0.
- Raw logs, result bundles, and screenshots:
  `/Users/onevcat/Downloads/kingfisher-xcode27-audit-20260915`.
- Derived data remains in `/tmp/kingfisher-xcode27-audit`.

## Findings and changes

1. **Unsupported deployment targets blocked builds.** Xcode 27 rejects the previous
   iOS/tvOS 13 and macOS 10.15 settings. SDK metadata also requires watchOS 9.
   With the maintainer's explicit approval, Xcode projects, both package manifests,
   and the podspec now require iOS/tvOS 15, macOS 12, watchOS 9, and visionOS 1.
   XCTest targets require iOS/tvOS 17 and macOS 14 to match the SDK's XCTest binaries.
   This is a compatibility change for the next release; no release version was chosen.
2. **The iOS demo failed to launch.** The simulator log reported that UIScene life
   cycle adoption is required. The iOS/visionOS and tvOS demos now use a scene
   manifest and a window scene delegate, with the existing main storyboard.
   This follows [Apple's migration guide](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle).
3. **The visionOS demo did not compile.** `Issue2352View` used unavailable `UIScreen`.
   It now reads SwiftUI's `displayScale` environment value.
4. **Mac Catalyst dependencies were inconsistent.** The demo enabled Catalyst while
   its framework dependency disabled it. The framework now enables Catalyst.
   The removed derived-bundle-ID setting is replaced by a conditional bundle ID.
5. **Compiler and package warnings.** Replaced legacy GIF/JPEG type constants with
   `UTType`, made an existing strong capture explicit, used button configurations,
   isolated tvOS nib UI setup on the main actor, updated the test's `onChange`, and
   excluded `Sources/Info.plist` from the Swift package target. The original NSImage
   duplicate-conformance warning occurred with a temporary macOS 14 override;
   it does not occur at the final library minimum of macOS 12. No conformance change
   was needed.
6. **A test assumed a Foundation allocation detail.** On all three baseline test
   platforms, `Data(existingData)` shared storage and failed an address-inequality
   assertion. The test now verifies snapshot isolation after both mutation and
   subsequent download appends. Production behavior is unchanged; forcing a large
   allocation would defeat the memory-pressure fix. The internal comment now
   distinguishes older Foundation allocation behavior.
7. **The shared scheme skipped all prefetch tests.** Enabled all 11 tests and ran
   complete suites. A follow-up investigation addresses the stress-test scaling
   issue and four independent correctness bugs; see below.
8. **Local automation still selected older Xcode/runtimes.** Fastlane now defaults
   to Xcode 27 and 27.0 simulators, and includes visionOS in its serial test lane.
   Explicit `XCODE_VERSION` overrides and existing CI matrices are preserved.

## Verification

All final tests used the shared `Kingfisher` scheme, random test ordering, and no
retry option. WatchOS has build and demo coverage, not an XCTest run.

| Platform | Final test result | Evidence log |
| --- | --- | --- |
| macOS 27 | 392 passed | `mac-all.log` |
| iOS 27, iPhone 17 Pro | 431 passed | `ios-all.log` |
| tvOS 27, Apple TV 4K | 429 passed | `tvos-all-serial.log` |
| visionOS 27, Apple Vision Pro | 409 passed | `vision-all.log` |

Total: 1,661 platform test executions passed in the final runs. No compiler or
linker warnings in these runs. Earlier failures remain in their original bundles.

- Swift 6 Release framework builds, with `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`,
  passed for `iphoneos`, `appletvos`, `watchos`, `xros`, and `macosx`, with no
  compiler/linker warnings. See `release-<sdk>.log`.
- Debug demo builds passed for iOS, macOS, tvOS, watchOS, visionOS, and Mac Catalyst.
- `swift build` passed without warnings (`spm-final.log`). The explicit Swift 6
  package build also passed; SwiftPM emitted its command-line language-override
  warning for `-Xswiftc -swift-version -Xswiftc 6`.
- `swift package dump-package`, Ruby syntax checks for Fastlane and the podspec,
  and `git diff --check` passed.
- Tests/builds used direct `xcodebuild` with raw logs retained through `tee` and
  parsed by `xcsift -f toon -w`. Fastlane itself and CocoaPods lint were not run.

Representative commands (each raw build log contains the exact invocation):

```bash
xcodebuild test -project Kingfisher.xcodeproj -scheme Kingfisher \
  -destination 'platform=macOS' -derivedDataPath /tmp/kingfisher-xcode27-audit/mac \
  -resultBundlePath /tmp/kingfisher-xcode27-audit/mac-all.xcresult CODE_SIGNING_ALLOWED=NO

xcodebuild build -project Kingfisher.xcodeproj -scheme Kingfisher \
  -configuration Release -sdk iphoneos SWIFT_VERSION=6.0 \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES CODE_SIGNING_ALLOWED=NO
```

## Demo observations

- **iOS, iPhone 18 Pro:** launched after scene migration; UIKit bird images loaded;
  GIF page displayed; SwiftUI Basic Image loaded, advanced to the next image, and
  applied the black-and-white processor. Network Metrics showed a network response
  (HTTP 200), then memory and disk cache hits with no network request. The memory
  button clears disk storage, so the disk check first warmed disk through a network
  load. Background/resume preserved the page and process. Screenshots use the `ios-`
  prefix; cache-result text is in `ios-metrics-*.log`.
- **iPadOS 27, iPad Pro 11-inch (M5):** launched and opened the Basic image
  grid (`ipad-basic.png`). Stage Manager and window-resizing modes were not tested.
- **macOS:** bird grid loaded; Heavy GIFs displayed changing content across captures;
  SwiftUI Next Image completed a download. Screenshots use the `mac-` prefix.
- **tvOS:** launched and displayed the bird-image grid and focused image styling
  (`tvos-basic.png`). Remote-navigation coverage was not performed.
- **watchOS, Series 12:** launched and displayed the downloaded bird image
  (`watch-loaded.png`). Paging/background behavior was not exercised.
- **visionOS:** scene-based demo launched and displayed its menu (`vision-menu.png`).
  The simulator accessibility tool does not support its frontmost-app lookup;
  in-scene navigation was not tested. Library tests ran successfully on this runtime.
- **Mac Catalyst:** launched, opened Basic, and displayed the bird-image grid
  (`catalyst-basic.png`).

## Remaining warnings and decisions for review

- The first complete tvOS run failed only `testPrefetchMultiTimes`: 10,000 prefetchers
  exceeded the unchanged 15-second expectation timeout while other simulators were
  initializing. The isolated run passed in 5.403 seconds; the subsequent full serial
  run passed, with this case taking 8.414 seconds. These results suggest load
  sensitivity, but do not establish the root cause. The first failure is retained
  in `tvos-all.xcresult`. The [follow-up investigation](prefetch-concurrency-investigation.md)
  found quadratic subscriber registration and dispatch-thread saturation, plus four
  separately reproduced correctness bugs. These are now fixed, with the original
  workload and timeout unchanged. The original failure's exact cause remains unproved.
- WatchKit storyboard deprecation remains in the watch demo. Keeping the example
  preserves coverage of `WKInterfaceImage.kf`; replacing it with SwiftUI would be
  a separate demo migration.
- visionOS reports deprecated Interface Builder/segue APIs in the shared UIKit
  demo. The demo now builds and launches. A complete programmatic UI migration is
  deferred; these warnings are not suppressed.
- Raw logs also contain Apple's AppIntents metadata-extraction notices, test asset
  PNG notices, and simulator service messages. These are distinct from compiler
  warnings and are preserved in the artifacts.
- No physical devices, release signing/archive packaging, old OS runtimes, or remote
  CI jobs were verified. The increased deployment minimums require release planning.
