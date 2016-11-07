# Change Log

-----

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


