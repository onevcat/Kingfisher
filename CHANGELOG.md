# Change Log

-----

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


