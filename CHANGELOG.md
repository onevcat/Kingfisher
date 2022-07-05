# Change Log

-----

## [7.3.0 - Progressive Progress](https://github.com/onevcat/Kingfisher/releases/tag/7.3.0) (2022-07-06)

#### Add
* Added `ImageProgressive` now contains a delegate `onImageUpdated` which will notify you everytime the progressive scanner can decode an intermediate image. You also have a chance to choose an image update strategy to respond the delegate. [#1957](https://github.com/onevcat/Kingfisher/issues/1957) @jyounus
* Now the `progressive` option can work with `KingfisherManager`. Previously it only works when set in the view extension methods under `kf`. [#1961](https://github.com/onevcat/Kingfisher/pull/1961) @onevcat

#### Fix
* A potential crash in `AnimatedImageView` that releasing on another thread. [#1956](https://github.com/onevcat/Kingfisher/pull/1956) @ufosky
* A few internal clean up and removal of unused code. [#1958](https://github.com/onevcat/Kingfisher/pull/1958) @idrougge

#### Remove
* With the support of `ImageProgressive.onImageUpdated`, the semantic of `ImageProgressive.default` is conflicting with the behavior. `ImageProgressive.default` is now marked as deprecated. To initilize a default `ImageProgressive`, use `ImageProgressive.init()` instead.

---

## [7.2.4 - Removing DocC plugin](https://github.com/onevcat/Kingfisher/releases/tag/7.2.4) (2022-06-15)

#### Fix
* Dependency of DocC plugin is now removed and Swift Package Index can still generate and host the documentation. [#1952](https://github.com/onevcat/Kingfisher/discussions/1952) @marcusziade

---

## [7.2.3 - Track Transform](https://github.com/onevcat/Kingfisher/releases/tag/7.2.3) (2022-06-09)

#### Fix
* Now the URL based `AVAssetImageDataProvider` support tracking transform by default. This could solve some cases that the video thumbnail were not at correct orientation. [#1951](https://github.com/onevcat/Kingfisher/pull/1951) @sgarg4008
* Use DocC as documentation generator and switch to [Swift Package Index as the host](https://swiftpackageindex.com/onevcat/Kingfisher/master/documentation/kingfisher). Big thanks to @daveverwer and all other fellows for the fantastic work!

---

## [7.2.2 - Rainy Season](https://github.com/onevcat/Kingfisher/releases/tag/7.2.2) (2022-05-08)

#### Fix
* Loading an animated images from cache now respects the received options. [#1935](https://github.com/onevcat/Kingfisher/pull/1935) @uclort

---

## [7.2.1 - Spring Earth](https://github.com/onevcat/Kingfisher/releases/tag/7.2.1) (2022-04-11)

#### Fix
* Align `requestModifier` parameter with `AsyncImageDownloadRequestModifier` to allow async request changing. [#1918](https://github.com/onevcat/Kingfisher/pull/1918) @KKirsten
* Fix an issue that data downloading task callbacks are held even when the task is removed. [#1913](https://github.com/onevcat/Kingfisher/pull/1913) @onevcat
* Give correct cache key for local urls in its conformance of `Resource`. [#1914](https://github.com/onevcat/Kingfisher/pull/1914) @onevcat
* Reset placeholder image when loading fails. [#1925](https://github.com/onevcat/Kingfisher/pull/1925) @PJ-LT
* Fix several typos and grammar. [#1926](https://github.com/onevcat/Kingfisher/pull/1926) @johnmckerrell [#1927](https://github.com/onevcat/Kingfisher/pull/1927) @SunsetWan

---

## [7.2.0 - End of the tunnel](https://github.com/onevcat/Kingfisher/releases/tag/7.2.0) (2022-02-27)

#### Add
* An option in memory cache that allows the cached images not be purged while the app is switchted to background. [#1890](https://github.com/onevcat/Kingfisher/pull/1890)

#### Fix
* Now the animated images are reset when deinit. This might fix some ocasional crash when destroying the `AnimatedImageView`. [#1886](https://github.com/onevcat/Kingfisher/pull/1886)
* Fix wrong key override when a local resource created by `ImageResource`'s initializer. [#1903](https://github.com/onevcat/Kingfisher/pull/1903)

---

## [7.1.2 - Cold Days](https://github.com/onevcat/Kingfisher/releases/tag/7.1.2) (2021-12-07)

#### Fix
* Lacking of `diskStoreWriteOptions` from `KFOptionSetter`. Now it supports to be set in a chainable way. [#1862](https://github.com/onevcat/Kingfisher/issues/1862) @ignotusverum
* A duplicated nested `Radius` type which prevents the framework being used in Playground. [#1872](https://github.com/onevcat/Kingfisher/pull/1872)
* An issue that sometimes `KFImage` does not load images correctly when a huge amount of images are being loaded due to animation setting. [#1873](https://github.com/onevcat/Kingfisher/pull/1873) @tatsuz0u
* Remove explicit usage of `@Published` to allow refering `KFImage` even under a deploy target below iOS 13. [#1875](https://github.com/onevcat/Kingfisher/pull/1875)
* Now the image cache calculats the cost animated images correctly with all frames. [#1881](https:://github.com/onevcat/Kingfisher/pull/1881) @pal-aspringfield
* Remove CarPlay support when building against macCatalyst, which is not properly conditionally supported. [#1876](https://github.com/onevcat/Kingfisher/pull/1876)

---

## [7.1.1 - Double Ninth](https://github.com/onevcat/Kingfisher/releases/tag/7.1.1) (2021-10-16)

#### Fix
* In some cases the `KFImage` loading causes a freeze on certain iOS 14 systems. [#1849](https://github.com/onevcat/Kingfisher/issues/1849) Thanks reporting from @JetForMe @benjamincombes @aralatpulat
* Setting image to an `AnimatedImageView` now correctly replaces its layer contents. [#1836](https://github.com/onevcat/Kingfisher/issues/1836) @phantomato

---

## [7.1.0 - Autumn Patch](https://github.com/onevcat/Kingfisher/releases/tag/7.1.0) (2021-10-12)

#### Add
* Extension for CarPlay support. Now you can use Kingfisher's extension image setting methods on `CPListItem`. [#1802](https://github.com/onevcat/Kingfisher/pull/1820) from @waynehartman

#### Fix
* An Xcode issue that not recognizes iOS 15 availability checking for Apple Silicon. [#1822](https://github.com/onevcat/Kingfisher/pull/1822) from @enoktate
* Add `onFailureImage` modifier back to `KFImage`, which was unexpected removed while upgrading. [#1829](https://github.com/onevcat/Kingfisher/pull/1829) from @skellock
* Start binder loading when `body` is evaluated. This fixes an unwanted flickering. This also adds a protection for internal loading state.  [#1828](https://github.com/onevcat/Kingfisher/pull/1828) from @JetForMe and @IvanShah
* Use color description based on `CGFloat` style of a color instead of a hex value to allow extended color space when setting it to a processor. [#1826](https://github.com/onevcat/Kingfisher/pull/1826) from @vonox7
* An issue that the local file provided images are cached for multiple times when an app is updated. This is due to a changing main bundle location on the disk. Now Kingfisher uses a stable version of disk URL as the default cache key. [#1831](https://github.com/onevcat/Kingfisher/pull/1831) from @iaomw
* Now `KFImage`'s internal rendered view is wrapped by a `ZStack`. This prevents a lazy container from recognizing different `KFImage`s with a same URL as the same view. [#1840](https://github.com/onevcat/Kingfisher/pull/1840) from @iOSappssolutions

---

## [7.0.0 - Version 7](https://github.com/onevcat/Kingfisher/releases/tag/7.0.0) (2021-09-21)

#### Add
* Rewrite SwiftUI support based on `@StateObject` instead of the old `@ObservedObject`. It provides a stable and better data model backs the image rendering in SwiftUI. For this, Kingfisher SwiftUI supports from iOS 14 now. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)
* Mark `ImageCache.retrieveImageInMemoryCache(forKey:options:)` as `open` to expose a correct override entry point to outside. [#1703](https://github.com/onevcat/Kingfisher/pull/1703)
* The `NSTextAttachment` extension method now accepts closure instead of a evaluated view. This allows delaying the passing in view to the timing which actually it is needed. [#1746](https://github.com/onevcat/Kingfisher/pull/1746)
* A `KFAnimatedImage` type to display a GIF image in SwiftUI. [#1705](https://github.com/onevcat/Kingfisher/pull/1705)
* Add a `progress` parameter to the `KFImage`'s `placeholder` closure. This allows you create a view based on the loading progress. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)
* Now `KFAnimatedImage` also supports `configure` modifier so you can set options to the underhood `AnimatedImageView`. [#1768](https://github.com/onevcat/Kingfisher/pull/1768)
* Expose `AnimatedImageView` fields to allow consumers to observe GIF progress. [#1789](https://github.com/onevcat/Kingfisher/pull/1789) @AttilaTheFun
* An option to pass in an [write option](https://developer.apple.com/documentation/foundation/nsdata/writingoptions) for writing data to the disk cache. This allows writing cache in a fine-tuned way, such as `.atomic` or `.completeFileProtection`. [#1793](https://github.com/onevcat/Kingfisher/pull/1793) @ignotusverum

#### Fix
* Uses `UIGraphicsImageRenderer` on iOS and tvOS for better image drawing. [#1706](https://github.com/onevcat/Kingfisher/pull/1706)
* An issue that prevents Kingfisher compiling on mac Catalyst target in some certain of Xcode versions. [#1692](https://github.com/onevcat/Kingfisher/pull/1692) @kvyatkovskys
* The `KF.retry(:_)` method now accepts an optional value. It allows to reset the retry strategy by passing in a `nil` value. [#1729](https://github.com/onevcat/Kingfisher/pull/1729)
* The `placeholder` view builder of `KFImage` now works when it gets changed instead of using its initial value forever. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)
* Some minor performance improvement. [#1739](https://github.com/onevcat/Kingfisher/pull/1739) @fuyoufang
* The `LocalFileImageDataProvider` now loads data in a background queue by default. This prevents loading performance issue when the loading is created on main thread. [#1764](https://github.com/onevcat/Kingfisher/pull/1764) @ConfusedVorlon
* Respect transition for SwiftUI view when using `KFImage`. [#1767](https://github.com/onevcat/Kingfisher/pull/1767)
* A type of `AuthenticationChallengeResponsable`. Now use `AuthenticationChallengeResponsible` instead. [#1780](https://github.com/onevcat/Kingfisher/pull/1780) @fakerlogic
* An issue that `AnimatedImageView` dose not change the `tintColor` for templated images. [#1786](https://github.com/onevcat/Kingfisher/pull/1786) @leonpesdk
* A crash when loading a GIF image in iOS 13 and below. [#1805](https://github.com/onevcat/Kingfisher/pull/1805/) @leonpesdk

#### Remove
* Drop support for iOS 10/11, macOS 10.13/10.14, tvOS 10/11 and watch OS 3/4. [#1802](https://github.com/onevcat/Kingfisher/issues/1802)
* The workaround of `KFImage.loadImmediately` is not necessary anymore due to the model switching to `@StateObject`. The interface is kept for backward compatibility, but it does nothing in the new version. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)

---

## [7.0.0-beta.4 - Version 7](https://github.com/onevcat/Kingfisher/releases/tag/7.0.0-beta.4) (2021-09-16)

#### Add
* An option to pass in an [write option](https://developer.apple.com/documentation/foundation/nsdata/writingoptions) for writing data to the disk cache. This allows writing cache in a fine-tuned way, such as `.atomic` or `.completeFileProtection`. [#1793](https://github.com/onevcat/Kingfisher/pull/1793)

#### Fix
* A crash when loading a GIF image in iOS 13 and below. [#1805](https://github.com/onevcat/Kingfisher/pull/1805/files)

---

## [7.0.0-beta.3 - Version 7](https://github.com/onevcat/Kingfisher/releases/tag/7.0.0-beta.3) (2021-08-29)

#### Add
* Now `KFAnimatedImage` also supports `configure` modifier so you can set options to the underhood `AnimatedImageView`. [#1768](https://github.com/onevcat/Kingfisher/pull/1768)
* Expose `AnimatedImageView` fields to allow consumers to observe GIF progress. [#1789](https://github.com/onevcat/Kingfisher/pull/1789)

#### Fix
* Respect transition for SwiftUI view when using `KFImage`. [#1767](https://github.com/onevcat/Kingfisher/pull/1767)
* A type of `AuthenticationChallengeResponsable`. Now use `AuthenticationChallengeResponsible` instead. [#1780](https://github.com/onevcat/Kingfisher/pull/1780/files)
* An issue that `AnimatedImageView` dose not change the `tintColor` for templated images. [#1786](https://github.com/onevcat/Kingfisher/pull/1786)

---

## [7.0.0-beta.2 - Version 7](https://github.com/onevcat/Kingfisher/releases/tag/7.0.0-beta.2) (2021-08-02)

#### Fix

- `LocalFileImageDataProvider` now loads data in a background queue by default. This prevents loading performance issue when the loading is created on main thread. [#1764]

---

## [7.0.0-beta.1 - Version 7](https://github.com/onevcat/Kingfisher/releases/tag/7.0.0-beta.1) (2021-07-27)

#### Add
* Rewrite SwiftUI support based on `@StateObject` instead of the old `@ObservedObject`. It provides a stable and better data model backs the image rendering in SwiftUI. For this, Kingfisher SwiftUI supports from iOS 14 now. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)
* Mark `ImageCache.retrieveImageInMemoryCache(forKey:options:)` as `open` to expose a correct override entry point to outside. [#1703](https://github.com/onevcat/Kingfisher/pull/1703)
* The `NSTextAttachment` extension method now accepts closure instead of a evaluated view. This allows delaying the passing in view to the timing which actually it is needed. [#1746](https://github.com/onevcat/Kingfisher/pull/1746)
* A `KFAnimatedImage` type to display a GIF image in SwiftUI. [#1705](https://github.com/onevcat/Kingfisher/pull/1705)
* Add a `progress` parameter to the `KFImage`'s `placeholder` closure. This allows you create a view based on the loading progress. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)

#### Fix
* Uses `UIGraphicsImageRenderer` on iOS and tvOS for better image drawing. [#1706](https://github.com/onevcat/Kingfisher/pull/1706)
* An issue that prevents Kingfisher compiling on mac Catalyst target in some certain of Xcode versions. [#1692](https://github.com/onevcat/Kingfisher/pull/1692)
* The `KF.retry(:_)` method now accepts an optional value. It allows to reset the retry strategy by passing in a `nil` value. [#1729](https://github.com/onevcat/Kingfisher/pull/1729)
* The `placeholder` view builder of `KFImage` now works when it gets changed instead of using its initial value forever. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)
* Some minor performance improvement. [#1739](https://github.com/onevcat/Kingfisher/pull/1739)

#### Remove
* Drop support for iOS 10, macOS 10.13, tvOS 10 and watch OS 3.
* The workaround of `KFImage.loadImmediately` is not necessary anymore due to the model switching to `@StateObject`. The interface is kept for backward compatibility, but it does nothing in the new version. [#1707](https://github.com/onevcat/Kingfisher/pull/1707)

---

## [6.3.0 - Open To Better](https://github.com/onevcat/Kingfisher/releases/tag/6.3.0) (2021-04-21)

#### Add
* Mark `SessionDelegate` as public to allow a subclass to take over the delegate methods from session tasks. [#1658](https://github.com/onevcat/Kingfisher/pull/1658)
* A new `imageDownloader(_:didDownload:with:)` in `ImageDownloaderDelegate` to pass not only `Data` but also the whole `URLResponse` to delegate method. Now you can determine how to handle these data based on the received response. [#1676](https://github.com/onevcat/Kingfisher/pull/1676)
* An option `autoExtAfterHashedFileName` in `DiskStorage.Config` to allow appending the file extension extracted from the cache key. [#1671](https://github.com/onevcat/Kingfisher/pull/1671)

#### Fix
* Now the GIF continues to play in a collection view cell with highlight support. [#1685](https://github.com/onevcat/Kingfisher/pull/1685)
* Fix a crash when loading GIF files with lots of frames in `AnimatedImageView`. Thanks for contribution from @wow-such-amazing [#1686](https://github.com/onevcat/Kingfisher/pull/1686)

---

## [6.2.1 - Spring Release Fix](https://github.com/onevcat/Kingfisher/releases/tag/6.2.1) (2021-03-09)

#### Fix
* Revert changes for the external delegate in [#1620](https://github.com/onevcat/Kingfisher/pull/1620), which caused some image resource loading failing due to a CFNetwork internal error.

---

## [6.2.0 - Spring Release](https://github.com/onevcat/Kingfisher/releases/tag/6.2.0) (2021-03-08)

#### Add
* The backend of Kingfisher's cache solution, `DiskStorage` and `MemoryStorage`, are now marked as `public`. So you can use them standalone in your project. [#1649](https://github.com/onevcat/Kingfisher/pull/1649)
* An `imageFrameCount` property in image view extensions. It holds the frame count of an animated image if available. [#1647](https://github.com/onevcat/Kingfisher/pull/1647)
* A new `extraSessionDelegateHandler` in `ImageDownloader`. Now you can receive the related session task delegate method by registering an external delegate object. [#1620](https://github.com/onevcat/Kingfisher/pull/1620)
* A new method `loadImmediately` for `KFImage` to start the load manually. It is useful if you want to load the image before `onAppear` is called.

#### Fix
* Drop the use of `@State` for keeping image across `View` update for `KFImage`. This should fix some SwiftUI internal crash when setting the image in `KFImage`. [#1642](https://github.com/onevcat/Kingfisher/pull/1642)
* The image reference in `ImageBinder` now is marked with `weak`. This helps release memory quicker in some cases. [#1640](https://github.com/onevcat/Kingfisher/pull/1640)

---

## [6.1.1 - SwiftUI Issues](https://github.com/onevcat/Kingfisher/releases/tag/6.1.1) (2021-02-17)

#### Fix
* Remove unnecessary queue dispatch when setting image result. This prevents image flickering when some situation. [#1615](https://github.com/onevcat/Kingfisher/pull/1615)
* Now the `KF` builder methods also accept optional `URL` or `Source`. It aligns the syntax with the normal view extension methods. [#1617](https://github.com/onevcat/Kingfisher/pull/1617)
* Fix an issue that wrong hash is calculated for `ImageBinder`. It might cause view state lost for a `KFImage`. [#1624](https://github.com/onevcat/Kingfisher/pull/1624)
* Now the `ImageCache` will disable the disk storage when there is no free space on disk when creating the cache folder, instead of just crashing it. [#1628](https://github.com/onevcat/Kingfisher/pull/1628)
* A workaround for `@State` lost when using a view inside another container in a `Lazy` stack or grid. [#1631](https://github.com/onevcat/Kingfisher/pull/1631)
* Performance improvement for images with an non-up orientation in Exif when displaying in `KFImage`. [#1629](https://github.com/onevcat/Kingfisher/pull/1629)

---

## [6.1.0 - SwiftUI Rework](https://github.com/onevcat/Kingfisher/releases/tag/6.1.0) (2021-02-01)

#### Add
* Rewrite state management for `KFImage`. Now the image reloading works in a more stable way without task dispatching. [#1604](https://github.com/onevcat/Kingfisher/pull/1604)
* Add `fade` and `forceTransition` modifier to `KFImage` to support built-in fade in effect when loading image in SwiftUI. [#1604](https://github.com/onevcat/Kingfisher/pull/1604)

#### Fix
* When an `ImageModifier` is applied, the modified image is not cached to memory cache anymore. The `ImageModifier` is intended to be used just before setting the image to a view and now it works as expected. [#1612](https://github.com/onevcat/Kingfisher/pull/1612)
* Now `SwiftUI` and `Combine` are declared as weak link in podspec. This is a workaround for [some rare case build issue](https://stackoverflow.com/a/60198305). It does not affect supported deploy version of Kingfisher. [#1607](https://github.com/onevcat/Kingfisher/pull/1607)
* Remove header file from podspec to allow Kingfisher built as a static framework in a Swift-ObjC mixed project. [#1608](https://github.com/onevcat/Kingfisher/pull/1608)

---

## [6.0.1 - Bind & Hug](https://github.com/onevcat/Kingfisher/releases/tag/6.0.1) (2021-01-05)

#### Fix
* Start the binder again when `KFImage` initialized, to keep the same behavior as previous versions. [#1594](https://github.com/onevcat/Kingfisher/issues/1594)

---

## [6.0.0 - New Year 2021](https://github.com/onevcat/Kingfisher/releases/tag/6.0.0) (2021-01-03)

#### Add
* A `KF` shorthand to create image setting tasks and config them. It provides a cleaner and modern way to use Kingfisher. Now, instead of using `imageView.kf.setImage(with:options:)`, you can perform chain-able invocation with `KF` helpers. For example, the code below is identical. [#1546](https://github.com/onevcat/Kingfisher/pull/1546)

    ```swift
    // Old way
    imageView.kf.setImage(
      with: url,
      placeholder: localImage,
      options: [.transition(.fade(1)), .loadDiskFileSynchronously],
      progressBlock: { receivedSize, totalSize in
          print("progressBlock")
      },
      completionHandler: { result in
          print(result)
      }
    )

    // New way
    KF.url(url)
      .placeholder(localImage)
      .fade(duration: 1)
      .loadDiskFileSynchronously()
      .onProgress { _ in print("progressBlock") }
      .onSuccess { result in print(result) }
      .onFailure { err in print("Error: \(err)") }
      .set(to: imageView)
    ```
    
* Similar to `KF`, The `KFImage` for SwiftUI is now having the similar chain-able syntax to setup an image task and options. This makes the `KFImage` APIs closer to the way how SwiftUI code is written. [#1586](https://github.com/onevcat/Kingfisher/pull/1586)
* Add support for `TVMonogramView` on tvOS. [#1571](https://github.com/onevcat/Kingfisher/pull/1571)
* Some important properties and method in `AnimatedImageView.Animator` are marked as `public` now. It provides some useful information of the decoded GIF files. [#1575](https://github.com/onevcat/Kingfisher/pull/1575)
* An `AsyncImageDownloadRequestModifier` to support modifying the request in an asynchronous way. [#1589](https://github.com/onevcat/Kingfisher/pull/1589/files)
* Add a `.lowDataMode` option to support for Low Data Mode. When the `.lowDataMode` option is provided with an alternative source (usually a low-resolution version of the original image), Kingfisher will respect user's Low Data Mode setting and download the alternative image instead. [#1590](https://github.com/onevcat/Kingfisher/pull/1590)

#### Fix
* An issue that importing AppKit wrongly in a macCatalyst build. [#1547](https://github.com/onevcat/Kingfisher/pull/1547/commits/096498f7798a6fd34c70efc6f80014dfc6d8a9b7)

#### Remove
* Deprecated types, methods and properties are removed. If you are still using `Kingfisher.Image`, `Kingfisher.ImageView` or `Kingfisher.Button`, use the equivalent `KFCrossPlatform` types (such as `KFCrossPlatformImage`, etc) instead. Please make sure you do not have any warnings before migrate to Kingfisher v6. For more about the removed deprecated things, check [#1525](https://github.com/onevcat/Kingfisher/pull/1525/files).
* The standalone framework target of SwiftUI support is removed. Now the SwiftUI support is a part in the main Kingfisher library. To upgrade to v6, first remove `Kingfisher/SwiftUI` subpod (if you are using CocoaPods) or remove the `KingfisherSwiftUI` target (if you are using Carthage or Swift Package Manager), then reinstall Kingfisher. [#1574](https://github.com/onevcat/Kingfisher/pull/1574)

---

## [5.15.8 - KFImage handler](https://github.com/onevcat/Kingfisher/releases/tag/5.15.8) (2020-11-27)

#### Fix
* An issue caused the `onSuccess` handler not be called when the image is already cached. [#1570](https://github.com/onevcat/Kingfisher/pull/1570)

---

## [5.15.7 - Cancel Lock](https://github.com/onevcat/Kingfisher/releases/tag/5.15.7) (2020-10-29)

#### Fix
* A potential crash when cancelling image downloading task while accessing its original request on iOS 13 or earlier. [#1558](https://github.com/onevcat/Kingfisher/pull/1558)

---

## [5.15.6 - ImageBinder Callback](https://github.com/onevcat/Kingfisher/releases/tag/5.15.6) (2020-10-11)

#### Fix
* Prevent main queue dispatching in `ImageBinder` if it is already on main thread. This prevents unintended flickering when reloading. [#1551](https://github.com/onevcat/Kingfisher/pull/1551)

---

## [5.15.5 - Cancelling Fix](https://github.com/onevcat/Kingfisher/releases/tag/5.15.5) (2020-09-29)

#### Fix
* A possible fix for the crashes when cancelling a huge amount of image tasks too fast. [#1537]

---

## [5.15.4 - Farewell Objective-C (CocoaPods)](https://github.com/onevcat/Kingfisher/releases/tag/5.15.4) (2020-09-24)

#### Fix
* Give `SessionDelegate` an Objective-C name so it can work with other libraries even added by a dependency which generates Objective-C header. [#1532](https://github.com/onevcat/Kingfisher/pull/1532)

---

## [5.15.3 - Farewell Objective-C](https://github.com/onevcat/Kingfisher/releases/tag/5.15.3) (2020-09-21)

#### Fix
* Removed the unnecessary ObjC header generating and module defining due to Xcode 12 is now generating conflicted types even for different libraries. [#1517](https://github.com/onevcat/Kingfisher/issues/1517)
* Set deploy target for SwiftUI target and its pod spec to iOS 10 and macOS 10.12, which aligns to the settings of core framework. That resolves some dependency issues when using CocoaPods for both app target and extension targets. But it does not mean you can use the SwiftUI support on those minimal target. All related APIs are still unavailable on old system versions. [#1524](https://github.com/onevcat/Kingfisher/pull/1524)

---

## [5.15.2 - Xcode 11 Revived](https://github.com/onevcat/Kingfisher/releases/tag/5.15.2) (2020-09-19)

#### Fix
* Fix a build error introduced by the previous SwiftUI fix for Xcode 12. Now Xcode 11 can also build the KingfisherSwiftUI target. [#1515](https://github.com/onevcat/Kingfisher/pull/1515)

---

## [5.15.1 - SwiftUI Layout](https://github.com/onevcat/Kingfisher/releases/tag/5.15.1) (2020-09-16)

#### Fix
* A workaround for a SwiftUI issue that embedding an image view inside the `List` > `NavigationLink` > `HStack` hierarchy could crash the app on iOS 14. [#1508](https://github.com/onevcat/Kingfisher/issues/1508)

---

## [5.15.0 - Video and Text Attachment](https://github.com/onevcat/Kingfisher/releases/tag/5.15.0) (2020-08-17)

#### Add
* An `AVAssetImageDataProvider` to generate an image from a remote video asset at a specified time. All the processing gets benefits from current existing Kingfisher technologies, such as cache and image processors. [#1500](https://github.com/onevcat/Kingfisher/pull/1500)
* New extension methods on `NSTextAttachment` to load an image from network for an attachment. [#1495](https://github.com/onevcat/Kingfisher/pull/1495)
* A general clear cache method which combines clearing for memory cache and disk cache. [#1494](https://github.com/onevcat/Kingfisher/pull/1494)

#### Fix
* Now the sample app has a new look and supports dark mode, finally. [#1496](https://github.com/onevcat/Kingfisher/pull/1496)

---

## [5.14.1 - Summer Fix](https://github.com/onevcat/Kingfisher/releases/tag/5.14.1) (2020-07-06)

#### Fix
* Early return if no valid animator in an `AnimatedImageView`. This prevents a CGImage rendering issue displaying a static image. [#1428](https://github.com/onevcat/Kingfisher/issues/1428)
* Enable Define Module setting to generate module map. So Kingfisher could be used in libraries imported to Objective-C projects. [#1451](https://github.com/onevcat/Kingfisher/pull/1451)
* A fix to workaround on implicitly initializer of queue that might cause a crash. [#1449](https://github.com/onevcat/Kingfisher/issues/1449)
* Improve the disk cache performance by avoiding unnecessary disk operations. [#1480](https://github.com/onevcat/Kingfisher/pull/1480)

---

## [5.14.0 - Retry Strategy](https://github.com/onevcat/Kingfisher/releases/tag/5.14.0) (2020-05-13)

#### Add
* A `.retryStrategy` option and associated `RetryStrategy` to define a highly customizable retry mechanism in Kingfisher. [#1424]
* Built-in `DelayRetryStrategy` to provide a most common used retry strategy implementation. It simplifies the normal retry requirement when downloading an image from network. [#1447](https://github.com/onevcat/Kingfisher/pull/1447)
* Now you can set the round corner radius for a `RoundCornerImageProcessor` in a fraction way. This is useful when you do not know the desire image view size, but still want to clip any received image to a certain round corner ratio (such as a circle for any image). [#1443](https://github.com/onevcat/Kingfisher/pull/1443)
* Add an `isLoaded` binding to `KFImage` to follow SwiftUI pattern better. [#1429](https://github.com/onevcat/Kingfisher/pull/1429)

#### Fix
* An issue that `.imageModifier` option not working on an `ImageProvider` provided image. [#1435](https://github.com/onevcat/Kingfisher/pull/1435)
* A workaround for making xcframework continue to work when exported with Swift 5.2 compiler and Xcode 11.4. [#1444](https://github.com/onevcat/Kingfisher/pull/1444)

---

## [5.13.4 - Build Configurations](https://github.com/onevcat/Kingfisher/releases/tag/5.13.4) (2020-04-11)

#### Fix
* Expose all build configurations in Package.swift file for Swift Package Manager. Now you can choose the linking style by yourself. [#1426](https://github.com/onevcat/Kingfisher/pull/1426)

---

## [5.13.3 - Dynamic SPM](https://github.com/onevcat/Kingfisher/releases/tag/5.13.3) (2020-04-01)

#### Fix
* Allows Carthage to build this library for macOS. [#1413](https://github.com/onevcat/Kingfisher/pull/1413)
* Explicitly specify to build as a dynamic framework for Swift Package Manager. [#1420](https://github.com/onevcat/Kingfisher/pull/1420)

---

## [5.13.2 - KFImage Orientation](https://github.com/onevcat/Kingfisher/releases/tag/5.13.2) (2020-02-28)

#### Fix
* An issue for `KFImage` when resizing images with different EXIF orientation other than top. [#1396](https://github.com/onevcat/Kingfisher/pull/1396)
* A race condition when setting `CacheCallbackCoordinator` state. [#1394](https://github.com/onevcat/Kingfisher/pull/1394)
* Move an `@objc` attribute to prevent warnings in Xcode 11.4.

---

## [5.13.1 - Internal Warning](https://github.com/onevcat/Kingfisher/releases/tag/5.13.1) (2020-02-17)

#### Fix
* Fix an unused variable warning which is on by default in Xcode 11.4 and Swift 5.2, which makes CocoaPods angry when compiling. [#1393](https://github.com/onevcat/Kingfisher/pull/1393)

---

## [5.13.0 - New Year 2020](https://github.com/onevcat/Kingfisher/releases/tag/5.13.0) (2020-01-17)

#### Add
* Mark `DefaultCacheSerializer` as `public` and enables the ability of original data caching. [#1373](https://github.com/onevcat/Kingfisher/pull/1373/)
* Add image compression quality parameter to `DefaultCacheSerializer`. [#1372](https://github.com/onevcat/Kingfisher/pull/1372/)
* A new `contentURL` property in `ImageDataProvider` to provide a URL when it makes sense. [#1386](https://github.com/onevcat/Kingfisher/pull/1386/)

#### Fix
* Now, local file URLs can be loaded as `Resource`s without converted to `LocalFileImageDataProvider` explicitly. [#1386](https://github.com/onevcat/Kingfisher/pull/1386/)

---

## [5.12.0 - White Overflow](https://github.com/onevcat/Kingfisher/releases/tag/5.12.0) (2019-12-13)

#### Add
* Two error cases under `KingfisherError.CacheErrorReason` to give out the detail error information and reason when a failure happens when caching the file on disk. Check `.cannotCreateCacheFile` and `.cannotSetCacheFileAttribute` if you need to handle these errors. [#1365](https://github.com/onevcat/Kingfisher/pull/1365)

#### Fix
* A 32-bit `Int` overflow when calculating expiration duration when a large `days` value is set for `StorageExpiration`. [#1371](https://github.com/onevcat/Kingfisher/pull/1371)
* The build config for SwiftUI sub-pod now only applies to the KingfisherSwiftUI scheme. [#1368](https://github.com/onevcat/Kingfisher/pull/1368)

---

## [5.11.0 - macCatalyst](https://github.com/onevcat/Kingfisher/releases/tag/5.11.0) (2019-11-30)

#### Add
* Support macCatalyst platform when building with Carthage. [#1356](https://github.com/onevcat/Kingfisher/pull/1356)

#### Fix
* Fix an issue that image orientation not correctly applied when an image processor used. [#1358](https://github.com/onevcat/Kingfisher/pull/1358)

---

## [5.10.1 - Repeat Count](https://github.com/onevcat/Kingfisher/releases/tag/5.10.1) (2019-11-20)

#### Fix
* Fix a wrong calculation of `repeatCount` of `AnimatedImageView`. Now it can play correct count for an animated image. [#1350](https://github.com/onevcat/Kingfisher/pull/1350)
* Make sure to skip disk cache when `fromMemoryCacheOrRefresh` set. [#1351](https://github.com/onevcat/Kingfisher/pull/1351)
* Fix a issue which prevents building with Xcode 10. [#1353](https://github.com/onevcat/Kingfisher/pull/1353)

---

## [5.10.0 - Rex Rabbit](https://github.com/onevcat/Kingfisher/releases/tag/5.10.0) (2019-11-17)

#### Add
* An `.alternativeSources` option to provide a list of alternative image loading `Source`s. These `Source`s act as a fallback when the original `Source` downloading fails where Kingfisher will try to load images from. [#1343](https://github.com/onevcat/Kingfisher/pull/1343)

#### Fix
* The `.waitForCache` option now also waits for caching for original image if the `.cacheOriginalImage` is also set. [#1344](https://github.com/onevcat/Kingfisher/pull/1344)
* Now the `retrieveImage` methods in `ImageCache` calls its `callbackQueue` is `.mainCurrentOrAsync` by default instead of `.untouch`. It aligns the behavior of other parts in the framework. [#1338](https://github.com/onevcat/Kingfisher/pull/1338)
* An issue that causes customize indicator not being placed with correct size. [#1345](https://github.com/onevcat/Kingfisher/pull/1345)
* Performance improvement for loading progressive images. [#1332](https://github.com/onevcat/Kingfisher/pull/1332)

---

## [5.9.0 - Combination](https://github.com/onevcat/Kingfisher/releases/tag/5.9.0) (2019-10-24)

#### Add
* Introduce a `|>` operator for combining image processors. [#1320](https://github.com/onevcat/Kingfisher/pull/1320)

#### Fix
* Improve performance of reading task identifier when handling downloading side effect. [#1310](https://github.com/onevcat/Kingfisher/pull/1310)
* Improve some type conversion to boost building. [#1321](https://github.com/onevcat/Kingfisher/pull/1321)

---

## [5.8.3 - Carthage Cache](https://github.com/onevcat/Kingfisher/releases/tag/5.8.3) (2019-10-09)

#### Fix
* Generate Objective-C header to make carthage cache work again. [#1308](https://github.com/onevcat/Kingfisher/pull/1308)

---

## [5.8.2 - Game of Thrones](https://github.com/onevcat/Kingfisher/releases/tag/5.8.2) (2019-10-04)

#### Fix
* Fix broken semantic versioning introduced by 5.8.0. [#1304](https://github.com/onevcat/Kingfisher/pull/1304)
* Remove implicit animations in SwiftUI when a `.fade` animation applied in the option. Now Kingfisher respect all animations set by users instead of overwriting it internally. [#1301](https://github.com/onevcat/Kingfisher/pull/1301)
* Now project uses KingfisherSwiftUI with Swift Package Manager can be archived correctly. [#1300](https://github.com/onevcat/Kingfisher/pull/1300)

---

## [5.8.1 - Borderless](https://github.com/onevcat/Kingfisher/releases/tag/5.8.1) (2019-09-27)

#### Fix
* Remove the unexpected border in `KFImage` while loading the image. [#1293](https://github.com/onevcat/Kingfisher/pull/1293)

---

## [5.8.0 - Xcode 11 & SwiftUI](https://github.com/onevcat/Kingfisher/releases/tag/5.8.0) (2019-09-25)

#### Add
* Add support for Swift Package Manager. Now you can build and use Kingfisher with SPM under Xcode 11 and use it in all targets.
* Add support for iPad Apps for Mac. You can use Kingfisher's UIKit extensions (like `UIImage` and `UIImageView`) on a catalyst project.
* Add support for SwiftUI. Build and import KingfisherSwiftUI.framework or contain the "Kingfisher/SwiftUI" subpod, then you can use `KFImage` to load image asynchronously. `KFImage` provides a similar interface as `View.Image`.
* Add support for building as a binary framework. A zipped file containing `xcframework` and related dSYMs is provided in the release page.
* A `diskCacheAccessExtendingExpiration` option to give more control of disk cache extending behavior. [#1287](https://github.com/onevcat/Kingfisher/pull/1287)
* Combine all targets into one. Now Kingfisher is a cross-platform target and you need to specify an SDK to build it.

#### Fix
* Rename too generic typealias names in Kingfisher, to avoid conflicting with SwiftUI types. Original `Kingfisher.Image` is now `Kingfisher.KFCrossPlatformImage`. The similar rules are applied to other cross-platform typealias too, such as `Kingfisher.View`, `Kingfisher.Color` and more.
* A potential thread issue in `taskIdentifier` which might cause a crash when using data provider. [#1276](https://github.com/onevcat/Kingfisher/pull/1276)
* An issue that causes memory shortage when a large number of network images are loaded in a short time. [#1270](https://github.com/onevcat/Kingfisher/pull/1270)

---

## [5.7.1 - Thread Things](https://github.com/onevcat/Kingfisher/releases/tag/5.7.1) (2019-08-11)

#### Fix
* Setting `runLoopMode` for `AnimatedImageView` will trigger animation restart normally. [#1253](https://github.com/onevcat/Kingfisher/pull/1253)
* A possible thread issue when removing storage object from memory cache by the cache policy. [#1255](https://github.com/onevcat/Kingfisher/pull/1255)
* Manipulating on `AnimateImageView`'s frame array is now thread safe. [#1257](https://github.com/onevcat/Kingfisher/pull/1257)

---

## [5.7.0 - Summer Bird](https://github.com/onevcat/Kingfisher/releases/tag/5.7.0) (2019-07-03)

#### Add
* Mark `cacheFileURL(forKey:)` of `DiskStorage` to public. [#1214](https://github.com/onevcat/Kingfisher/issues/1214)
* Mark `KingfisherManager` initializer to public so other dependencies can customize the manager behavior. [#1216](https://github.com/onevcat/Kingfisher/issues/1216)

#### Fix
* Performance improvement on progressive JPEG scanning. [#1218](https://github.com/onevcat/Kingfisher/pull/1218)
* Fix a potential thread issue when checking progressive JPEG. [#1220](https://github.com/onevcat/Kingfisher/pull/1220)

#### Remove
* The deprecated `Result` extensions for Swift 4 back compatibility are removed. [#1224](https://github.com/onevcat/Kingfisher/pull/1224)

---

## [5.6.0 - The Sands of Time](https://github.com/onevcat/Kingfisher/releases/tag/5.6.0) (2019-06-11)

#### Add
* Support extending memory cache TTL to a specified time instead of the fixed original expire setting. Use the `.memoryCacheAccessExtendingExpiration` to set a customize expiration extending duration when accessing the image. [#1196](https://github.com/onevcat/Kingfisher/pull/1196)
* Add prebuilt binary framework when releasing to GitHub. Further supporting of fully compatible binary framework would come after Swift module stability. [#1194](https://github.com/onevcat/Kingfisher/pull/1194)

#### Fix
* Resizing performance for animated images should be improved dramatically. [#1189](https://github.com/onevcat/Kingfisher/pull/1189)
* A small optimization on MD5 calculation for image file cache key. [#1183](https://github.com/onevcat/Kingfisher/pull/1183)

---

## [5.5.0 - Progressive JPEG](https://github.com/onevcat/Kingfisher/releases/tag/5.5.0) (2019-05-17)

#### Add
* Add support for loading progressive JPEG images. This feature is still in beta and will be improved in the next few releases. To try it out, make sure you are loading a progressive JPEG image with a `.progressiveJPEG` options passed in. Thanks @lixiang1994 [#1181](https://github.com/onevcat/Kingfisher/pull/1181)
* Choose to use `Swift.Result` as the default result type when Swift 5.0 or above is applied. [#1146](https://github.com/onevcat/Kingfisher/pull/1146)

#### Fix
* Apply to some modern Swift syntax, which may also improve internal performance a bit. [#1181](https://github.com/onevcat/Kingfisher/pull/1181)

---

## [5.4.0 - Accio Support](https://github.com/onevcat/Kingfisher/releases/tag/5.4.0) (2019-04-24)

#### Add
* Add support for building project with [Accio](https://github.com/JamitLabs/Accio) (and Swift Package Manager). [#1153](https://github.com/onevcat/Kingfisher/pull/1153)

#### Fix
* Now `maxCachePeriodInSecond` of cache would treat 0 as expiring correctly. [#1160](https://github.com/onevcat/Kingfisher/pull/1160)
* Normalization of image now returns an image with `.up` as orientation. [#1163](https://github.com/onevcat/Kingfisher/pull/1163)

---

## [5.3.1 - Prefetching Thread](https://github.com/onevcat/Kingfisher/releases/tag/5.3.1) (2019-03-28)

#### Fix
* Some thread issues which may cause crash when loading images by `ImagePrefetcher`. [#1150](https://github.com/onevcat/Kingfisher/pull/1150)
* Setting a negative value by the deprecated `maxCachePeriodInSecond` API now expires the cache correctly. [#1145](https://github.com/onevcat/Kingfisher/pull/1145)

---

## [5.3.0 - Prefetching Sources](https://github.com/onevcat/Kingfisher/releases/tag/5.3.0) (2019-03-24)

#### Add
* Now `ImagePretcher` also supports using `Source` as fetching target. [#1142](https://github.com/onevcat/Kingfisher/pull/1142)
* An option to skip file name hashing when storing image to disk cashe. [#1140](https://github.com/onevcat/Kingfisher/pull/1140)
* Supports multiple Swift versions for CocoaPods 1.7.0.

#### Fix
* An issue that loading a downsampled image from original version might lead to different scale and potential memory performance problem. [#1126](https://github.com/onevcat/Kingfisher/pull/1126)
* Marking setter of `kf` wrapper as `nonmutating` and seperate value/reference version of `KingfisherCompatible`. This allows mutating properties on `kf` even with a `let` declaration. [#1134](https://github.com/onevcat/Kingfisher/pull/1134)
* A regression which causes stack overflow when using `ImagePretcher` to load huge ammount of images. [#1143](https://github.com/onevcat/Kingfisher/pull/1143)

---

## [5.2.0 - Swift 5.0](https://github.com/onevcat/Kingfisher/releases/tag/5.2.0) (2019-02-27)

#### Add
* Compatible with Swift 5.0 and Xcode 10.2. Now Kingfisher builds against Swift 4.0, 4.2 and 5.0. [#1098](https://github.com/onevcat/Kingfisher/pull/1098)

#### Fix
* A possible dead lock when using `ImagePretcher` heavily in another thread. [#1122](https://github.com/onevcat/Kingfisher/pull/1122)
* Redesign `Result` type based on Swift `Result` in standard library. Deprecate `value` and `error` getter for `Kingfisher.Result`.

---

## [5.1.1 - Racing](https://github.com/onevcat/Kingfisher/releases/tag/5.1.1) (2019-02-11)

#### Fix
* Deprecate incorrect `ImageCache` initializer with `path` parameter. Now use the `cacheDirectoryURL` version for clearer implemetation. [#1114](https://github.com/onevcat/Kingfisher/pull/1114/)
* Fix a race condition when setting download delegate from multiple `ImagePrefetcher`s. [#1109](https://github.com/onevcat/Kingfisher/issues/1109)
* Now `directoryURL` of disk storage backend is marked as public correctly. [#1108](https://github.com/onevcat/Kingfisher/issues/1108)

---

## [5.1.0 - Redirecting & Racing](https://github.com/onevcat/Kingfisher/releases/tag/5.1.0) (2019-01-12)

#### Add
* Add a `ImageDownloadRedirectHandler` for intercepting HTTP request which redirects. [#1072](https://github.com/onevcat/Kingfisher/pull/1072)

#### Fix
* Some thread racing when downloading and resetting images in the same image view. [#1089](https://github.com/onevcat/Kingfisher/pull/1089)

---

## [5.0.1 - Interweave](https://github.com/onevcat/Kingfisher/releases/tag/5.0.1) (2018-12-17)

#### Fix
* Retrieving images from cache now respect options `callbackQueue` setting. [#1066](https://github.com/onevcat/Kingfisher/issues/1066)
* A crash when passing zero or negative size to `DownsamplingImageProcessor`. [#1073](https://github.com/onevcat/Kingfisher/issues/1073)

---

## [5.0.0 - Reborn](https://github.com/onevcat/Kingfisher/releases/tag/5.0.0) (2018-12-08)

#### Add
* Add `Result` type to Kingfisher. Now all callbacks in Kingfisher are using `Result` instead of tuples. This is more future-friendly and provides a modern way to make error handling better.
* Make `KingfisherError` much more elaborate and accurate. Instead of simply provides the error code, now `KingfisherError` contains error reason and necessary associated values. It will help to understand and track the errors easier.
* Better cache management by separating memory cache and disk cache to their own storages. Now you can use `MemoryStorage` and `DiskStorage` as the `ImageCache` backend.
* Image cache of memory storage would be purged automatically in a certain time interval. This reduce memory pressure for other parts of your app.
* The `ImageCache` is rewritten from scratch, to get benefit from new created `MemoryStorage` and `DiskStorage`. At the same time, this hybrid cache abstract keeps most API compatibility from the earlier versions.
* Now the `ImageCache` can receive only raw `Data` object and cache it as needed.
* A `KingfisherParsedOptionsInfo` type to parse `KingfisherOptionsInfoItem`s in related API. This improves reusability and performance when handling options in Kingfisher.
* An option to specify whether an image should also prefetched to memory cache or not.
* An option to make the disk file loading synchronously instead of in its own I/O queue.
* Options to specify cache expiration for either memory cache or disk cache. This gives you a chance to control cache lifetime in a per-task grain size.
* Add a default maximum size for memory cache. Now only at most 25% of your device memory will be used to kept images in memory. You can also change this value if needed.
* An option to specify a processing queue for image processors. This gives your flexibility if you want to use main queue or if you want to dispatch the processing to a different queue.
* A `DownsamplingImageProcessor` for downsampling an image to a given size before loading it to memory.
* Add `ImageDataProvider` protocol to make it possible to provide image data locally instead of downloading from network. Several concrete types are provided to load images from data format. Use `LocalFileImageDataProvider` to load an image from a local disk path, `Base64ImageDataProvider` to load image from a Base64 string representation and `RawImageDataProvider` to provide a raw `Data object`.
* A general `Source` protocol to define from where the image should be loaded. Currently, we support to load an image from `ImageDataProvider` or from network now.

#### Fix
* Now CommonCrypto from system is used to calculate file name from cache key, instead of using a customized hash algorithm.
* An issue which causes `ImageDownloader` crashing when a lot of downloading tasks running at the same time.
* All operations like image pretching and data receiving should now be performed in non-UI threads correctly.
* Now `KingfisherCompatible` uses struct for `kf` namespacing for better performance.

---

## [4.10.1 - Time Machine](https://github.com/onevcat/Kingfisher/releases/tag/4.10.1) (2018-11-03)

#### Fix
* Add Swift 4 compatibility back.
* Increase watchOS target to 3.0 in podspec.

---

## [4.10.0 - Swift 4.2](https://github.com/onevcat/Kingfisher/releases/tag/4.10.0) (2018-09-20)

#### Add
* Support for building with Xcode 10 and Swift 4.2. This version requires Xcode 10 or later with Swift 4.2 compiler.

#### Fix
* Improve performance when an invalide HTTP status code received. [#985](https://github.com/onevcat/Kingfisher/pull/985)

---

## [4.9.0 - Patience is a Virtue](https://github.com/onevcat/Kingfisher/releases/tag/4.9.0) (2018-09-04)

#### Add
* Add a `waitForCache` option to allowing cache callback called after cache operation finishes. [#963](https://github.com/onevcat/Kingfisher/pull/963)

#### Fix
* Animated image now will recognize `.once` and `.finite(1)` the same thing. [#982](https://github.com/onevcat/Kingfisher/pull/982)
* Replace class-only protocol keyword with AnyObject as Swift convention. [#983](https://github.com/onevcat/Kingfisher/pull/983)
* A wrong cache callback parameter when storing cache with background decoding. [#986](https://github.com/onevcat/Kingfisher/pull/986)
* Access `downloadHolder` in a serial queue to avoid racing. [#984](https://github.com/onevcat/Kingfisher/pull/984)

---

## [4.8.1 - Prefetch Improvement](https://github.com/onevcat/Kingfisher/releases/tag/4.8.1) (2018-07-26)

#### Fix
* Fix a performance issue when prefetching images by moving related operation away from main queue. [#957](https://github.com/onevcat/Kingfisher/pull/957)
* Improvement on stability of some test cases.

---

## [4.8.0 - Watch & Watching](https://github.com/onevcat/Kingfisher/releases/tag/4.8.0) (2018-05-15)

#### Add
* WKInterfaceImage setting image interface for watchOS. [#913](https://github.com/onevcat/Kingfisher/pull/913)
* A new delegate method for watching `ImageDownloader` object completes a downloading request with success or failure. [#901](https://github.com/onevcat/Kingfisher/pull/901)

#### Fix

* Use newly created operation queue for downloader. 
* Filter.init(tranform:) is renamed to Filter.init(transform:) 
* Some internal minor fix on constant and typo, etc.

---

## [4.7.0 - Cancel All](https://github.com/onevcat/Kingfisher/releases/tag/4.7.0) (2018-04-06)

#### Add
* ImageDownloader now contains a method `cancelAll` to cancel all downloading tasks. [#894](https://github.com/onevcat/Kingfisher/pull/894)
* Supports Swift 4.1 and Xcode 9.3. [#889](https://github.com/onevcat/Kingfisher/pull/889)

---

## [4.6.4 - Customize Activity Indicator](https://github.com/onevcat/Kingfisher/releases/tag/4.6.4) (2018-03-20)

#### Fix
* An issue caused customize activity indicator not working for Swift 4. [#872](https://github.com/onevcat/Kingfisher/issues/872)
* Specify Swift compiler version explicity in pod spec file for CocoaPods 1.4. [#875](https://github.com/onevcat/Kingfisher/pull/875)

---

## [4.6.3 - Clean Demo](https://github.com/onevcat/Kingfisher/releases/tag/4.6.3) (2018-03-01)

#### Fix
* Move demo project out from Kingfisher framework project. [#867](https://github.com/onevcat/Kingfisher/pull/867)
* An issue that caused stack overflow when prefetching too many images, while they are already cached. [#866](https://github.com/onevcat/Kingfisher/pull/866)

---

## [4.6.2 - GIF frames](https://github.com/onevcat/Kingfisher/releases/tag/4.6.2) (2018-02-14)

#### Fix
* Animated image view now will call finished delegate method in correct timing. [#860](https://github.com/onevcat/Kingfisher/issues/860)

---

## [4.6.1 - MD5](https://github.com/onevcat/Kingfisher/releases/tag/4.6.1) (2017-12-28)

#### Fix
* Revert to use non-dependency way to handle MD5, to solve issues which redefination of dependency library. [#834](https://github.com/onevcat/Kingfisher/pull/834)

---

## [4.6.0 - AniBird](https://github.com/onevcat/Kingfisher/releases/tag/4.6.0) (2017-12-27)

#### Add
* Delegate methods for `AnimatedImageView` to inspect finishing event and/or end of an animation loop. [#829](https://github.com/onevcat/Kingfisher/pull/829)

#### Fix
* Minor performance improvement by `final` some classes.
* Remove unnecessary `Box` type since Objective-C world takes `Any`. [#832](https://github.com/onevcat/Kingfisher/pull/832).
* Some internal failing tests on earlier macOS, in which color space giving different result.

---

## [4.5.0 - Blending](https://github.com/onevcat/Kingfisher/releases/tag/4.5.0) (2017-12-05)

#### Add
* New image processors to blend an image. See `BlendImageProcessor` on iOS/tvOS and `CompositingImageProcessor` on macOS. [#818](https://github.com/onevcat/Kingfisher/pull/818)

#### Fix
* A crash when prefetching too many images in a single batch. [#692](https://github.com/onevcat/Kingfisher/issues/692)
* A possible invalid redeclaration on `Array` from `AnimatedImageView`. [#819](https://github.com/onevcat/Kingfisher/pull/819)

---

## [4.4.0 - Image Modifier](https://github.com/onevcat/Kingfisher/releases/tag/4.4.0) (2017-12-01)

#### Add
* Add `ImageModifier` to give a final chance for setting image object related properties just before getting back the image from either network or cache. [#810](https://github.com/onevcat/Kingfisher/issues/810)

#### Fix
* Apply scale on all image based processor methods, including the existing ones from memory cache. [#813](https://github.com/onevcat/Kingfisher/issues/813)

---

## [4.3.1 - Cache Regression](https://github.com/onevcat/Kingfisher/releases/tag/4.3.1) (2017-11-21)

#### Fix
* A regression introduced in 4.3.0 which cause the cache not working well for processed images.

---

## [4.3.0 - Memory Or Refresh](https://github.com/onevcat/Kingfisher/releases/tag/4.3.0) (2017-11-17)

#### Add
* An option for only getting cached images from memory or refresh it by downloading. It could be useful for fetching images behind the same URL while keeping to use the latest memory cached ones. [#806](https://github.com/onevcat/Kingfisher/pull/806)

#### Fix
* A problem when setting customized indicator with non-zero frame. Now the indicator will be no longer resized to image view size incorrectly. [#798](https://github.com/onevcat/Kingfisher/pull/798)
* Improve store performance by avoiding re-encode images as long as the original data could be provided. [#805](https://github.com/onevcat/Kingfisher/pull/805)

---

## [4.2.0 - A Tale of Two Caches](https://github.com/onevcat/Kingfisher/releases/tag/4.2.0) (2017-10-22)

#### Add
* An option to provice a specific cache for original image. This gives us a change to caching original iamges on a different cache. [#794](https://github.com/onevcat/Kingfisher/pull/794)

---

## [4.1.1 - Love Barrier Again](https://github.com/onevcat/Kingfisher/releases/tag/4.1.1) (2017-10-17)

#### Fix
* A potential race condition in `ImageDownloader`. [#763](https://github.com/onevcat/Kingfisher/issues/763)

---

## [4.1.0 - Data in Hand](https://github.com/onevcat/Kingfisher/releases/tag/4.1.0) (2017-09-28)

#### Add
* An `ImageDownloader` delegate method to provide a chance for you to check and modify the data. [#773](https://github.com/onevcat/Kingfisher/pull/773)

#### Fix
* Now Kingfisher also supports Swift 3.2, as a workaround for CocoaPods not respecting pod spec build setting. [CocoaPods_#6791](https://github.com/CocoaPods/CocoaPods/issues/6791)

---

## [4.0.1 - Swift 4](https://github.com/onevcat/Kingfisher/releases/tag/4.0.1) (2017-09-15)

#### Add
* Supports for Swift 4. The new major version of Kingfisher should be source compatible with Kingfisher 3. Please make sure you have no warning left with Kingfisher related APIs before migrating to version 4, since all deprecated methods are removed from our code base. [#704](https://github.com/onevcat/Kingfisher/pull/704)
* A cleaner API to track whether an image is cached and its cache type. Use `imageChachedType` and `CacheType.cached` instead of `isImageCached` and `CacheCheckResult`. [#704](https://github.com/onevcat/Kingfisher/pull/704/commits/38860911310931842f2d44e020204e894b7b2ae8)

#### Fix
* Update pod spec to use Swift 4.0 as Swift Version configuration.

---

## [4.0.0 - Swift 4](https://github.com/onevcat/Kingfisher/releases/tag/4.0.0) (2017-09-14)

#### Add
* Supports for Swift 4. The new major version of Kingfisher should be source compatible with Kingfisher 3. Please make sure you have no warning left with Kingfisher related APIs before migrating to version 4, since all deprecated methods are removed from our code base. [#704](https://github.com/onevcat/Kingfisher/pull/704)
* A cleaner API to track whether an image is cached and its cache type. Use `imageChachedType` and `CacheType.cached` instead of `isImageCached` and `CacheCheckResult`. [#704](https://github.com/onevcat/Kingfisher/pull/704/commits/38860911310931842f2d44e020204e894b7b2ae8)

---

## [3.13.1 - Evil Setting](https://github.com/onevcat/Kingfisher/releases/tag/3.13.1) (2017-09-14)

#### Fix
* Disable code coverage for all targets in build setting to avoid rejecting from iTunes when building with Xcode 9. [#753](https://github.com/onevcat/Kingfisher/pull/753)

---

## [3.13.0 - Rum Bird](https://github.com/onevcat/Kingfisher/releases/tag/3.13.0) (2017-09-12)

#### Add
* Introduces a `backgroundColor` property to `RoundCornerImageProcessor` allowing to specify a desired backgroud color. It could be useful for a JPEG based image to prevent alpha blending. [#766](https://github.com/onevcat/Kingfisher/pull/766)

---

## [3.12.2 - Scaling Background Decoding](https://github.com/onevcat/Kingfisher/releases/tag/3.12.2) (2017-09-02)

#### Fix
* Fix an issue which causes image scale not correct when background decoding option is used. [#761](https://github.com/onevcat/Kingfisher/issues/761)

---

## [3.12.1 - Placeholder](https://github.com/onevcat/Kingfisher/releases/tag/3.12.1) (2017-08-30)

#### Add
* Now you could use a customized view (subclass of `UIView` or `NSView`) as placeholder in image view setting extension method. [#746](https://github.com/onevcat/Kingfisher/issues/746)

---

## [3.12.0 - Placeholder](https://github.com/onevcat/Kingfisher/releases/tag/3.12.0) (2017-08-30)

#### Add
* Now you could use a customized view (subclass of `UIView` or `NSView`) as placeholder in image view setting extension method. [#746](https://github.com/onevcat/Kingfisher/issues/746)

---

## [3.11.0 - Task Auth](https://github.com/onevcat/Kingfisher/releases/tag/3.11.0) (2017-08-16)

#### Add
* A task based authentication challenge handler for some auth methods like HTTP Digest. [#742](https://github.com/onevcat/Kingfisher/issues/742)

#### Fix
* The option of `keepCurrentImageWhileLoading` now will respect your placeholder if the original image is `nil` in the image view. [#747](https://github.com/onevcat/Kingfisher/pull/747)

---

## [3.10.4 - Indicator Size](https://github.com/onevcat/Kingfisher/releases/tag/3.10.4) (2017-07-26)

#### Fix
* Respect image and custom indicator size. Now Kingfisher will not resize the indicators to the image size for you automatically.

---

## [3.10.3 - ProMotion](https://github.com/onevcat/Kingfisher/releases/tag/3.10.3) (2017-07-06)

#### Fix
* Fix a problem which causes the GIF playing in a slow rate on ProMotion enabled devices (iPad Pro 10.5) [#718](https://github.com/onevcat/Kingfisher/issues/718)

---

## [3.10.2 - Missing Boys](https://github.com/onevcat/Kingfisher/releases/tag/3.10.2) (2017-06-16)

#### Fix
* Now the processed images result from a cache original image could be cached correctly. [#711](https://github.com/onevcat/Kingfisher/issues/711)
* Some internal minor clean up.

---

## [3.10.1 - Order, order!](https://github.com/onevcat/Kingfisher/releases/tag/3.10.1) (2017-06-04)

#### Fix
* Change an inline function order to make Swift 3.0 compiler happy. [#700](https://github.com/onevcat/Kingfisher/issues/700)

---

## [3.10.0 - Hot Bird](https://github.com/onevcat/Kingfisher/releases/tag/3.10.0) (2017-06-03)

#### Add
* New cache retriving strategy for a request with certain `ImageProcessor` applied. Now Kingfisher will first try to get the processed images from cache. If not existing, it will be smart enough to check whether the original image exists in cache to avoid downloading it.
* A `cacheOriginalImage` option to also cache original images while an `ImageProcessor` is applied. It is required if you want the new cache strategy. [#650](https://github.com/onevcat/Kingfisher/issues/650)
* A `FormatIndicatedCacheSerializer` to serialize the image into a certain format (`png`, `jpg` or `gif`). [#693](https://github.com/onevcat/Kingfisher/issues/693)

#### Fix
* A timing issue when you try to cancel an on-going download task, and start the same one again immediately. Now the previous one will received an error and the later one could be completed normally. [#532](https://github.com/onevcat/Kingfisher/issues/532)
* Fix the showing/hiding logic for activity indicator in image view to make them independent from race condition.
* A possible race condition that accessing downloading fetch load conccurently.
* Invalidate the download session when the downloader gets released. It might cause problem if you were using your own downloader instance.
* Some internal stability improvement.

---

## [3.9.1 - Compatibility](https://github.com/onevcat/Kingfisher/releases/tag/3.9.1) (2017-05-13)

#### Fix
* Fix a problem which prevents building under Xcode 8.2 / Swift 3.0. [#677](https://github.com/onevcat/Kingfisher/issues/677)

---

## [3.9.0 - Follow the Rules](https://github.com/onevcat/Kingfisher/releases/tag/3.9.0) (2017-05-11)

#### Add
* A default option in `KingfisherManager` to let users set a global default option to all `KingfisherManager` related methods, as well as all UI extension methods. [#674](https://github.com/onevcat/Kingfisher/pull/674)

#### Fix
* Now the options appended will overwrite the previous one. This makes users be able to set proper options in a per-image-way, even when there is already a default option set in `KingfisherManager`.
* Deprecate `requestsUsePipeling` in `ImageDownloader` since there was a typo. Now use `requestsUsePipelining` instead. [#673](https://github.com/onevcat/Kingfisher/pull/673)
* Some internal improvement for private APIs.

---

## [3.8.0 - Prowess](https://github.com/onevcat/Kingfisher/releases/tag/3.8.0) (2017-05-10)

#### Add
* An API to apply rect round for specified corner in `RoundCornerImageProcessor`. Instead of making all four corners rounded, you can now set only some corners rounding. [#668](https://github.com/onevcat/Kingfisher/issues/668)

---

## [3.7.2 - Never Do Things by Halves](https://github.com/onevcat/Kingfisher/releases/tag/3.7.2) (2017-05-09)

#### Fix
* A wrong design which causes completion handler for previous downloading not called when setting to another url. [#665](https://github.com/onevcat/Kingfisher/issues/665)

---

## [3.7.1 - GIF is Animated](https://github.com/onevcat/Kingfisher/releases/tag/3.7.1) (2017-05-08)

#### Fix
* Deprecated `preloadAllGIFData`. Change to a more generic name `preloadAllAnimationData` since it could be used for other format with `ImageProcessor`. [#664](https://github.com/onevcat/Kingfisher/pull/664)

---

## [3.7.0 - Summer Bird](https://github.com/onevcat/Kingfisher/releases/tag/3.7.0) (2017-05-04)

#### Add
* A delegate method in `ImageDownloaderDelegate` to notify starting of a downloading progress.

#### Fix
* Better documentation for `Resource` parameter in image setting extension.

---

## [3.6.2 - Naughty CGImage](https://github.com/onevcat/Kingfisher/releases/tag/3.6.2) (2017-04-11)

#### Fix
* A problem in `CroppingImageProcessor` and `crop` method of images which crops wrong area for images with a non-`1` scale. [#649](https://github.com/onevcat/Kingfisher/pull/649)
* Refactor for `ResizingImageProcessor`. `targetSize` of `ResizingImageProcessor` is now deprecated. Use `referenceSize` instead. It's just a name changing for clearer API. [#646](https://github.com/onevcat/Kingfisher/pull/646)

---

## [3.6.1 - Some Optimization](https://github.com/onevcat/Kingfisher/releases/tag/3.6.1) (2017-04-01)

#### Fix
* Fix warnings when build Kingfisher in Swift 3.1 compiler. [#632](https://github.com/onevcat/Kingfisher/pull/632)
* Wrong size when decoding images with a passed-in scale option. [#633](https://github.com/onevcat/Kingfisher/pull/633)
* Speed up MD5 calculation by turing to a pure Swift implementation. [#636](https://github.com/onevcat/Kingfisher/pull/636)
* Host docs directly in GitHub. [#641](https://github.com/onevcat/Kingfisher/pull/641)

---

## [3.6.0 - Cropping](https://github.com/onevcat/Kingfisher/releases/tag/3.6.0) (2017-03-26)

#### Add
* A built-in image processor to crop images with a targeted size and anchor. [#465](https://github.com/onevcat/Kingfisher/issues/465)

---

## [3.5.2 - Bad Apple](https://github.com/onevcat/Kingfisher/releases/tag/3.5.2) (2017-03-09)

#### Fix
* An issue which causes app crashing while folder enumerating encountered an error in `ImageCache`. [#620](https://github.com/onevcat/Kingfisher/pull/620)

---

## [3.5.1 - Fast is better than slow](https://github.com/onevcat/Kingfisher/releases/tag/3.5.1) (2017-03-01)

#### Fix
* A minor improvement on slow compiling time due to a method in `Image`. [#611](https://github.com/onevcat/Kingfisher/issues/611)

---

## [3.5.0 - New age, new content](https://github.com/onevcat/Kingfisher/releases/tag/3.5.0) (2017-02-21)

#### Add
* Resizing processor now support to resize images with content mode. You could choose from `aspectFill`, `aspectFit` or just respect the target size. [#597](https://github.com/onevcat/Kingfisher/issues/597)

#### Fix
* A problem which might cause the downloaded image set unexpected for a cell which already not in use. [#598](https://github.com/onevcat/Kingfisher/pull/598)

---

## [3.4.0 - Spring is here](https://github.com/onevcat/Kingfisher/releases/tag/3.4.0) (2017-02-11)

#### Add
* Use the `onlyLoadFirstFrame` option to load only the first frame from a GIF file. It will be useful when you want to display a static preview of the first frame from a GIF image. By doing so, you could save huge ammount of memory. [#591](https://github.com/onevcat/Kingfisher/pull/591)

#### Fix
* Now `cancel` on a `RetrieveImageTask` will work properly even when the downloading not started for `UIButton` and `NSButton` too. [#580](https://github.com/onevcat/Kingfisher/pull/580)
* Progress block of extensions setting methods will not be called multiple times if you set another task while the previous one still in downloading. [#583](https://github.com/onevcat/Kingfisher/pull/583)
* Image cache will work properly when `ImagePrefetcher` trying to prefetch images with an `ImageProcessor`. Now the fetched and processed images could be retrieved correctly. [#590](https://github.com/onevcat/Kingfisher/pull/590)

---

## [3.3.4 - Cancellation means a new start!](https://github.com/onevcat/Kingfisher/releases/tag/3.3.4) (2017-02-04)

#### Fix
* Now `cancel` on a `RetrieveImageTask` will work properly even when the downloading not started. [#578](https://github.com/onevcat/Kingfisher/pull/578)
* Use modern float constant of pi. [#576](https://github.com/onevcat/Kingfisher/pull/576)

---

## [3.3.3 - Xcode 8.0 is not dead yet](https://github.com/onevcat/Kingfisher/releases/tag/3.3.3) (2017-01-30)

#### Fix
* A type inference to make Kingfisher compiles on Xcode 8.0 again. [#572](https://github.com/onevcat/Kingfisher/issues/572)

---

## [3.3.2 - Upside Down](https://github.com/onevcat/Kingfisher/releases/tag/3.3.2) (2017-01-23)

#### Fix
* An issue which causes the background decoded images drawn upside down.

---

## [3.3.1 - Lunar Eve](https://github.com/onevcat/Kingfisher/releases/tag/3.3.1) (2017-01-21)

#### Add
* Expose default `pngRepresentation`, `jpegRepresentation` and `gifRepresentation` as public. [#560](https://github.com/onevcat/Kingfisher/pull/560)
* Support unlimited disk cache duration. [#566](https://github.com/onevcat/Kingfisher/pull/566)

#### Fix
* A mismatch of CG image component when creating `CGContext` for blur filter. [#567](https://github.com/onevcat/Kingfisher/pull/567)
* Remove test images from repo to keep slim. [#568](https://github.com/onevcat/Kingfisher/pull/568)

---

## [3.3.0 - Lunar Eve](https://github.com/onevcat/Kingfisher/releases/tag/3.3.0) (2017-01-21)

#### Add
* Expose default `pngRepresentation`, `jpegRepresentation` and `gifRepresentation` as public. [#560](https://github.com/onevcat/Kingfisher/pull/560)
* Support unlimited disk cache duration. [#566](https://github.com/onevcat/Kingfisher/pull/566)

#### Fix
* A mismatch of CG image component when creating `CGContext` for blur filter. [#567](https://github.com/onevcat/Kingfisher/pull/567)
* Remove test images from repo to keep slim. [#568](https://github.com/onevcat/Kingfisher/pull/568)

---

## [3.2.4 - Love SPM again](https://github.com/onevcat/Kingfisher/releases/tag/3.2.4) (2016-12-22)

#### Fix
* A problem that causes framework cannot be compiled by Swift Package Manager. [#547](https://github.com/onevcat/Kingfisher/issues/547)
* Removed an unused parameter from round corner image API. [#548](https://github.com/onevcat/Kingfisher/issues/548)

---

## [3.2.3 - LI ZHENG](https://github.com/onevcat/Kingfisher/releases/tag/3.2.3) (2016-12-20)

#### Fix
* An issue which caused processed images igoring exif orientation information. [#535](https://github.com/onevcat/Kingfisher/issues/535)

---

## [3.2.2 - Faster GIF](https://github.com/onevcat/Kingfisher/releases/tag/3.2.2) (2016-12-02)

#### Fix
* Improve preload animated image loading strategy by using background queue. This should improve framerate when loading a lot of GIF files in the same time. [#529](https://github.com/onevcat/Kingfisher/pull/529)
* Make `ImageDownloader` a pure Swift class to avoid the SDK bug which might leak memory in iOS 10. [#520](https://github.com/onevcat/Kingfisher/issues/520)
* Fix some typos. [#523](https://github.com/onevcat/Kingfisher/issues/523)

---

## [3.2.1 - Helper Helps](https://github.com/onevcat/Kingfisher/releases/tag/3.2.1) (2016-11-14)

#### Add
* A new set of `KingfisherOptionsInfo` extension helpers to extract options easiser. It will be useful when you are trying to implement your own processors or serializers. [#505](https://github.com/onevcat/Kingfisher/issues/505)
* Mark the empty task for downloader as `public`. [#508](https://github.com/onevcat/Kingfisher/issues/508)

#### Fix
* Set placeholder image even when the input resource is `nil`. This is a regression from version 3.2.0. [#510](https://github.com/onevcat/Kingfisher/issues/510)

---

## [3.2.0 - Quiet](https://github.com/onevcat/Kingfisher/releases/tag/3.2.0) (2016-11-07)

#### Add
* A new option to ignore placeholder and keep current image while loading/downloading a new one. This would be useful when you want to display the earlier image while loading a new one. [494](https://github.com/onevcat/Kingfisher/issues/494)
* A disk cache path closure to let you fully customize the disk cache path. [#499](https://github.com/onevcat/Kingfisher/pull/499)

#### Fix
* Move methods which were marked as `open` to their class defination scope, to avoid the compiler restriction when overridden. [#500](https://github.com/onevcat/Kingfisher/pull/500)

---

## [3.1.4 - CIImageProcessor with Data](https://github.com/onevcat/Kingfisher/releases/tag/3.1.4) (2016-10-19)

#### Fix
* Fix a problem that `CIImageProcessor` not get called when feeding data to the processor. [#485](https://github.com/onevcat/Kingfisher/issues/485)

---

## [3.1.3 - Collocalia](https://github.com/onevcat/Kingfisher/releases/tag/3.1.3) (2016-10-06)

#### Fix
* A compiling time issue. Now the compile time of Kingfisher should drop dramatically. [#467](https://github.com/onevcat/Kingfisher/pull/467)
* kf wrapper of all Kingfisher compatible types now a class instead of struct, to make mutating opearation on it possible. [#469](https://github.com/onevcat/Kingfisher/issues/469)

#### Remove
* requestModifier of `ImageDownloader` is removed to prevent leading to misunderstanding.

---

## [3.1.1 - Kingfisher likes more](https://github.com/onevcat/Kingfisher/releases/tag/3.1.1) (2016-09-28)

#### Fix
* An issue which prevents using multiple image processors at the same time. Now you can use different `ImageProcessor` at the same time for an image, while keeping high performance since only one downloading process would be fired. [#460](https://github.com/onevcat/Kingfisher/pull/460)
* A crash when processing some images with built-in `ResizingImageProcessor` and `OverlayImageProcessor` while the input images not having a standard format. [#440](https://github.com/onevcat/Kingfisher/issues/440), [#461](https://github.com/onevcat/Kingfisher/pull/461)
* ImageCache could accept a path extension as key now. [#456](https://github.com/onevcat/Kingfisher/pull/456)

---

## [3.1.0 - Namespace](https://github.com/onevcat/Kingfisher/releases/tag/3.1.0) (2016-09-21)

#### Add
* Add `kf` namespace for all extension APIs in Kingfisher. Now no need to worry about name conflicting any more. [#435](https://github.com/onevcat/Kingfisher/pull/435)

#### Fix
* Mark `AnimateImageView` to open so you can extend this class again. [#442](https://github.com/onevcat/Kingfisher/pull/442)
* Update demo code to adopt iOS 10 prefetching cell feature and new cell life cycle. [#447](https://github.com/onevcat/Kingfisher/issues/447)

#### Remove
* Since `kf` namespace is added, all original `kf_` prefix methods are marked as deprecated.

---

## [3.0.1 - New Age - Swift 3](https://github.com/onevcat/Kingfisher/releases/tag/3.0.1) (2016-09-14)

#### Add
* Swift 3 compatibility. This version follows Swift 3 API design guideline as well as contains a lot of breaking changes from version 2.x. See [Kingfisher 3.0 Migration Guide](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-3.0-Migration-Guide) for more about how to migrate your project to 3.0. Kingfisher 2.6.x is still supporting both Swift 2.2 and 2.3.
* Image Processor. Now you can specify an image processor and it will be used to process images after downloaded. It is useful when you need to apply some transforming or filter to the image. You can also use the processor to support any other image format, like WebP. See [Processor](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#processor) section in the wiki for more. The default processor should behave the same as before. [#420](https://github.com/onevcat/Kingfisher/pull/420)
* Built-in processors from simple round corner and resizing to filters like tint and blur. Check [Built-in processors of Kingfisher](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#built-in-processors-of-kingfisher) for more.
* Cache Serializer. [CacheSerializer](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#serializer) will be used to convert some data to an image object for retrieving from disk cache and vice versa for storing to disk cache.
* New indicator type. Now you should be able to use your own indicators. [#430](https://github.com/onevcat/Kingfisher/pull/430)
* ImageDownloadRequestModifier. Use this protocol to modify requests being sent to your server.

#### Fix
* Resource is now a protocol instead of a struct. Use `ImageResource` for your original `Resource` type. And now `URL` conforms `Resource` so the APIs could be clearer.
* Now Kingfisher cache will store re-encoded image data instead of the original data by default. This is needed due to we want to store the processed data from `ImageProcessor`. If this is not what you want, you should supply your customized instanse of `CacheSerializer`.

#### Remove
* KingfisherManager.init is removed since you should never create your own manager.
* cachedImageExistsforURL in `ImageCache` is removed since it introduced unnecessary coupling. Use `isImageCached` instead.
* requestModifier` is removed. Use `.requestModifier` and pass a `ImageDownloadRequestModifier`.
* kf_showIndicatorWhenLoading is removed since we have a better and flexible way to use indicator by `kf_indicatorType`.

---

## [3.0.0 - New Age - Swift 3](https://github.com/onevcat/Kingfisher/releases/tag/3.0.0) (2016-09-14)

#### Add
* Swift 3 compatibility. This version follows Swift 3 API design guideline as well as contains a lot of breaking changes from version 2.x. See [Kingfisher 3.0 Migration Guide](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-3.0-Migration-Guide) for more about how to migrate your project to 3.0. Kingfisher 2.6.x is still supporting both Swift 2.2 and 2.3.
* Image Processor. Now you can specify an image processor and it will be used to process images after downloaded. It is useful when you need to apply some transforming or filter to the image. You can also use the processor to support any other image format, like WebP. See [Processor](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#processor) section in the wiki for more. The default processor should behave the same as before. [#420](https://github.com/onevcat/Kingfisher/pull/420)
* Built-in processors from simple round corner and resizing to filters like tint and blur. Check [Built-in processors of Kingfisher](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#built-in-processors-of-kingfisher) for more.
* Cache Serializer. [CacheSerializer](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet#serializer) will be used to convert some data to an image object for retrieving from disk cache and vice versa for storing to disk cache.
* New indicator type. Now you should be able to use your own indicators. [#430](https://github.com/onevcat/Kingfisher/pull/430)
* ImageDownloadRequestModifier. Use this protocol to modify requests being sent to your server.

#### Fix
* Resource is now a protocol instead of a struct. Use `ImageResource` for your original `Resource` type. And now `URL` conforms `Resource` so the APIs could be clearer.
* Now Kingfisher cache will store re-encoded image data instead of the original data by default. This is needed due to we want to store the processed data from `ImageProcessor`. If this is not what you want, you should supply your customized instanse of `CacheSerializer`.

---

## [2.6.0 - Indicator Customization](https://github.com/onevcat/Kingfisher/releases/tag/2.6.0) (2016-09-12)

#### Add
* Support for different types of indicators, including gif images. [#425](https://github.com/onevcat/Kingfisher/pull/425)

---

## [2.5.1 - Prefetcher Trap](https://github.com/onevcat/Kingfisher/releases/tag/2.5.1) (2016-09-06)

#### Fix
* Fix a possible trap of range making in prefetcher. [#422](https://github.com/onevcat/Kingfisher/pull/422)

---

## [2.5.0 - Swift 2.3](https://github.com/onevcat/Kingfisher/releases/tag/2.5.0) (2016-08-29)

#### Add
* Support for Swift 2.3

---

## [2.4.3 - Longer Cache](https://github.com/onevcat/Kingfisher/releases/tag/2.4.3) (2016-08-17)

#### Fix
* The disk cache now will use access date for expiring checking, which should work better than modification date. [#381](https://github.com/onevcat/Kingfisher/issues/381) [#405](https://github.com/onevcat/Kingfisher/issues/405)

---

## [2.4.2 - Optional Welcome](https://github.com/onevcat/Kingfisher/releases/tag/2.4.2) (2016-07-10)

#### Add
* Accept `nil` as valid URL parameter for image view's extension methods.

#### Fix
* The completion handler of image view setting method will not be called any more if `self` is released.
* Improve empty task so some performance improvment could be achieved.
* Remove SwiftLint since it keeps adding new rules but without a back compatible support. It makes the users confusing when using a different version of SwiftLint.
* Removed Implicit Unwrapping of CacheType that caused crashes if the image is not cached.

---

## [2.4.1 - Force Transition](https://github.com/onevcat/Kingfisher/releases/tag/2.4.1) (2016-05-10)

#### Add
* An option (`ForceTransition`) to force image setting for an image view with transition. By default the transition will only happen when downloaded. [#317](https://github.com/onevcat/Kingfisher/pull/317)

---

## [2.4.0 - Animate Me](https://github.com/onevcat/Kingfisher/releases/tag/2.4.0) (2016-05-04)

#### Add
* A standalone `AnimatedImageView` to reduce memory usage when parsing and displaying GIF images. See README for more about using Kingfisher for GIF images. [#300](https://github.com/onevcat/Kingfisher/pull/300)

#### Fix
* An issue which may cause iOS app crasing when switching background/foreground multiple times. [#309](https://github.com/onevcat/Kingfisher/pull/309)
* Change license of String+MD5.swift to a more precise one. [#302](https://github.com/onevcat/Kingfisher/issues/302)

---

## [2.3.1 - Pod Me up](https://github.com/onevcat/Kingfisher/releases/tag/2.3.1) (2016-04-22)

#### Fix
* Exclude NSButton extension from no related target. [#292](https://github.com/onevcat/Kingfisher/pull/292)

---

## [2.3.0 - Warmly Welcome](https://github.com/onevcat/Kingfisher/releases/tag/2.3.0) (2016-04-21)

#### Add
* Add support for App Extension target. [#290](https://github.com/onevcat/Kingfisher/pull/290)
* Add support for NSButton. [#287](https://github.com/onevcat/Kingfisher/pull/287)

---

## [2.2.2 - Spring Bird II](https://github.com/onevcat/Kingfisher/releases/tag/2.2.2) (2016-04-06)

#### Fix
* Add default values to optional parameters, which should be a part of 2.2.1. [#284](https://github.com/onevcat/Kingfisher/issues/284)

---

## [2.2.1 - Spring Bird](https://github.com/onevcat/Kingfisher/releases/tag/2.2.1) (2016-04-06)

#### Fix
* A memory leak caused by closure based Generator. [#281](https://github.com/onevcat/Kingfisher/pull/281)
* Remove duplicated APIs since auto completion gets improved in Swift 2.2. [#283](https://github.com/onevcat/Kingfisher/pull/283)
* Enable all recongnized format for `UIImage`. [#278](https://github.com/onevcat/Kingfisher/pull/278)

---

## [2.2.0 - Open Source Swift](https://github.com/onevcat/Kingfisher/releases/tag/2.2.0) (2016-03-24)

#### Add
* Compatible with latest Swift 2.2 and Xcode 7.3. [#270](https://github.com/onevcat/Kingfisher/pull/270). If you need to use Kingfisher in Swift 2.1, please consider to pin to version 2.1.0.

#### Fix
* A trivial issue that a context holder should not exist when decoding images background.

---

## [2.1.0 - Prefetching](https://github.com/onevcat/Kingfisher/releases/tag/2.1.0) (2016-03-10)

#### Add
* Add `ImagePrefetcher` and related prefetching methods to allow downloading and caching images before you need to display them. [#249](https://github.com/onevcat/Kingfisher/pull/249)
* A protocol (`AuthenticationChallengeResponable`) for responsing authentication challenge. You can now set `authenticationChallengeResponder` of `ImageDownloader` and use your own authentication policy. [#226](https://github.com/onevcat/Kingfisher/issues/226)
* An API (`cachePathForKey(:)`) to get real path for a specified key in a cache. [#256](https://github.com/onevcat/Kingfisher/pull/256)

#### Fix
* Disable background decoding for images from memory cache. This improves the performance of image loading for in-memory cached images and fix a flicker when you try to load image with background decoding. [#257](https://github.com/onevcat/Kingfisher/pull/257)
* A potential crash in `ImageCache` when an empty image is passed into.

---

## [2.0.4 - Sorry Pipelining](https://github.com/onevcat/Kingfisher/releases/tag/2.0.4) (2016-02-27)

#### Fix
* Make pipeling support to be disabled by default since it requiring server support. You can enable it by setting `requestsUsePipeling` in `ImageDownloader`. [#253](https://github.com/onevcat/Kingfisher/pull/253)
* Image transition now allows user interaction. [#252](https://github.com/onevcat/Kingfisher/pull/252)

---

## [2.0.3 - Holiday Issues](https://github.com/onevcat/Kingfisher/releases/tag/2.0.3) (2016-02-17)

#### Fix
* A memory leak caused by retain cycle of downloader session and its delegate. [#235](https://github.com/onevcat/Kingfisher/issues/235)
* Now the `callbackDispatchQueue` in option should be applied to `ImageDownloader` as well. [#238](https://github.com/onevcat/Kingfisher/pull/238) and [#240](https://github.com/onevcat/Kingfisher/pull/240)
* Fix warnings when the latest version of SwiftLint is used. [#189](https://github.com/onevcat/Kingfisher/issues/189#issuecomment-185205010)

---

## [2.0.2 - Single Frame GIF](https://github.com/onevcat/Kingfisher/releases/tag/2.0.2) (2016-02-14)

#### Fix
* An issue which causes GIF images with only one frame failing to be loaded correctly. [#231](https://github.com/onevcat/Kingfisher/issues/231)

---

## [2.0.1 - Disk is back](https://github.com/onevcat/Kingfisher/releases/tag/2.0.1) (2016-01-28)

#### Fix
* An issue which causes the downloaded image not cached in disk. [#224](https://github.com/onevcat/Kingfisher/pull/224)

---

## [2.0.0 - Kingfisher 2](https://github.com/onevcat/Kingfisher/releases/tag/2.0.0) (2016-01-23)

#### Add
* OS X support. Now Kingfisher can work seamlessly for `NSImage`. [#201](https://github.com/onevcat/Kingfisher/pull/201)
* watchOS 2.x support. [#210](https://github.com/onevcat/Kingfisher/pull/210)
* Swift Package Manager support. [#218](https://github.com/onevcat/Kingfisher/issues/218)
* Unified `KingfisherOptionsInfo` API. Now all options across the framework are represented by `KingfisherOptionsInfo` with type same behavior. [#194](https://github.com/onevcat/Kingfisher/pull/194)
* API for changing download priority of image download task after the download started. [#73](https://github.com/onevcat/Kingfisher/issues/73)
* You can cancel image or background image downloading task now for button as well. [#205](https://github.com/onevcat/Kingfisher/issues/205)

#### Fix
* A potential thread issue when asking for cache state right after downloading finished.
* Improve MD5 calculating speed. [#220](https://github.com/onevcat/Kingfisher/pull/220)
* The scale was not correct when processing GIF files.

---

## [1.9.3](https://github.com/onevcat/Kingfisher/releases/tag/1.9.3) (2016-01-22)

#### Fix
* Stop indicator animation when loading failed. [#215](https://github.com/onevcat/Kingfisher/issues/215)

---

## [1.9.2 - IOIOIO](https://github.com/onevcat/Kingfisher/releases/tag/1.9.2) (2016-01-14)

#### Fix
* A potential issue causes image cache checking method not working when the image just stored.
* Better performance and image quality when storing images with original data.

---

## [1.9.1 - You happy, I happy](https://github.com/onevcat/Kingfisher/releases/tag/1.9.1) (2016-01-04)

#### Fix
* Making SwiftLint happy when building with Carthage. #189

---

## [1.9.0 - What a Task](https://github.com/onevcat/Kingfisher/releases/tag/1.9.0) (2015-12-31)

#### Add
* Download methods in `ImageDownloader` now returns a cancelable task. So you can cancel the downloading process when using downloader separately.
* Add a cancelling method in image view extension for easier cancel operation.
* Mark some properties of downloading task as public.

#### Fix
* Cancelling of image downloading now triggers completion handler with `NSURLErrorCancelled` correctly now.

---

## [1.8.5 - Single Dog](https://github.com/onevcat/Kingfisher/releases/tag/1.8.5) (2015-12-16)

#### Fix
* Use single url session to download images.
* Ignore and return error immediately for empty URL.
* Internal update for testing stability and code style.

---

## [1.8.4 - GIF is GIF](https://github.com/onevcat/Kingfisher/releases/tag/1.8.4) (2015-12-12)

#### Fix
* Opt out the normalization and decoding for GIF, which would lead an issue that the GIF images missing.
* Proper cost count for GIF image.


---

## [1.8.3 - Internal beauty](https://github.com/onevcat/Kingfisher/releases/tag/1.8.3) (2015-12-05)

#### Fix
* Fix for code base styles and formats.

---

## [1.8.2 - Path matters](https://github.com/onevcat/Kingfisher/releases/tag/1.8.2) (2015-11-19)

#### Add
* Cache path is customizable now. You can use Document folder to cache user generated images (But be caution that the disk cache files might be removed if limitation condition met).


---

## [1.8.1 - Transition needs rest](https://github.com/onevcat/Kingfisher/releases/tag/1.8.1) (2015-11-13)

#### Fix
* Only apply transition when images are downloaded. It will not show transition animation now if images loaded from either memory or disk cache now.
* Code style.

---

## [1.8.0 - Bigger is Better](https://github.com/onevcat/Kingfisher/releases/tag/1.8.0) (2015-11-07)

#### Add
* Support for tvOS. Now enjoy downloading and cacheing images in the tvOS.

#### Fix
* An issue which causes images not stored properly if the original data is not supplied. #142

---

## [1.7.1 - EXIF is JPEG!](https://github.com/onevcat/Kingfisher/releases/tag/1.7.1) (2015-10-27)

#### Fix
* EXIF JPEG support which was broken in 1.7.0.
* Correct timing of completion handler for use case with transition of UIImageView extension.

---

## [1.7.0 - Kingfisher with animation](https://github.com/onevcat/Kingfisher/releases/tag/1.7.0) (2015-10-25)

#### Add
* GIF support. Now you can download and show an animated GIF by Kingfisher `UIImageView` extension.

#### Fix
* Type safe options.
* A potential retain of cache in loading task.

---

## [1.6.1 - No More Blinking](https://github.com/onevcat/Kingfisher/releases/tag/1.6.1) (2015-10-09)

#### Fix
* The blinking when reloading images in a cell.
* Indicator is now in center of image view.

---

## [1.6.0 - Transition](https://github.com/onevcat/Kingfisher/releases/tag/1.6.0) (2015-09-19)

#### Add
* Add transition option. You can now use some view transition (like fade in) easier.

#### Fix
* Image data presenting when storing in disk.

---

## [1.5.0 - Swift 2.0](https://github.com/onevcat/Kingfisher/releases/tag/1.5.0) (2015-09-10)

#### Add
* Support for Swift 2.0.

#### Fix
* Remove the disk retrieve task canceling temporarily since there is an issue in Xcode 7 beta.
* Remove support for watchOS since it now requires a separated framework. It will be added later as a standalone library instead a fat one.

---

## [1.4.5 - Key decoupling](https://github.com/onevcat/Kingfisher/releases/tag/1.4.5) (2015-08-14)

#### Fix
* Added resource APIs so you can specify a cacheKey for an image. The default implementation will use the URL string as key.

---

## [1.4.4 - Bug fix release](https://github.com/onevcat/Kingfisher/releases/tag/1.4.4) (2015-08-07)

#### Fix
* Explicitly type casting in ImageCache. #86

---

## [1.4.3](https://github.com/onevcat/Kingfisher/releases/tag/1.4.0) (2015-08-06)

#### Fix
* Fix orientation of PNG files.
* Indicator hiding logic.

---

## [1.4.2 - Scaling](https://github.com/onevcat/Kingfisher/releases/tag/1.4.0) (2015-07-09)

#### Add
* Support for store and decode with scale parameter.

#### Fix
* A retain cycle which prevents image retrieving task releasing.

---

## [1.4.1](https://github.com/onevcat/Kingfisher/releases/tag/1.4.1) (2015-05-12)

#### Fix
* Fix library dependency to weak link for WatchKit.

---

## [1.4.0 - Hello, Apple Watch](https://github.com/onevcat/Kingfisher/releases/tag/1.4.0) (2015-05-11)

#### Add
* Apple Watch support and category on `WKInterfaceImage`.

---

## [1.3.1](https://github.com/onevcat/Kingfisher/releases/tag/1.3.1) (2015-05-06)

#### Fix
* Fix tests for CI.

---

## [1.3.0 - 304? What is 304?](https://github.com/onevcat/Kingfisher/releases/tag/1.3.0) (2015-05-01)

#### Add
* ImageDownloaderDelegate for getting information from response.
* A cacheType key in completion handler to let you know which does the image come from.
* A notification when disk images are cleaned due to image expired or size exceeded.

#### Fix
* Changed `ForceRefresh` behavior to respect server response when got a 304.
* Documentation and test coverage.

---

## [1.2.0 - More, I need more!](https://github.com/onevcat/Kingfisher/releases/tag/1.2.0) (2015-04-24)

#### Add
* Multiple cache/downloader system. You can know specify the cache/downloader you need to use for each image request. It will be useful if you need different cache or download policy for different images.
* Changed `Options` to `OptionsInfo` for flexible options passing.

#### Fix
* An issue which preventing image downloading when modifying the url of request.

### Deprecate
* All extension methods with `KingfisherOptions` are deprecated now. Use `KingfisherOptionsInfo` instead.

---

## [1.1.3 - Internal is Important](https://github.com/onevcat/Kingfisher/releases/tag/1.1.3) (2015-04-23)

#### Fix
* Update the naming convention used in internal queues, for easier debug purpose.
* Fix some tests.

---

## [1.1.2 - Who cares disk size](https://github.com/onevcat/Kingfisher/releases/tag/1.1.1) (2015-04-21)

#### Add
* API for calculation total disk cache size.
* API for modifying request before sending it.
* Handle challenge when accessing a server trust site.

#### Fix
* Fix grammar in README.
* Fix demo project to make it simpler.

---

## [1.1.1](https://github.com/onevcat/Kingfisher/releases/tag/1.1.1) (2015-04-17)

#### Fix
* Update PodSpec version

---

## [1.1.0 - Not only image](https://github.com/onevcat/Kingfisher/releases/tag/1.1.0) (2015-04-17)

#### Add
* UIButton extension.

#### Fix
* Fix typo in project.
* Improve documentation.

---

## [1.0.0 - Kingfisher, take off](https://github.com/onevcat/Kingfisher/releases/tag/1.0.0) (2015-04-13)

First public release.


