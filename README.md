<p align="center">
<img src="https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png" alt="Kingfisher" title="Kingfisher" width="557"/>
</p>

<p align="center">
<a href="https://github.com/onevcat/Kingfisher/actions?query=workflow%3Abuild"><img src="https://github.com/onevcat/kingfisher/workflows/build/badge.svg?branch=master"></a>
<a href="https://swiftpackageindex.com/onevcat/Kingfisher/master/documentation/kingfisher"><img src="https://img.shields.io/badge/Swift-Doc-DE5C43.svg?style=flat"></a>
<a href="https://cocoapods.org/pods/Kingfisher"><img src="https://img.shields.io/github/v/tag/onevcat/Kingfisher.svg?color=blue&include_prereleases=&sort=semver"></a>
<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat"></a>
<a href="https://raw.githubusercontent.com/onevcat/Kingfisher/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-black"></a>
</p>

Kingfisher is a powerful, pure-Swift library for downloading and caching images from the web. It provides you a chance to use a pure-Swift way to work with remote images in your next app.

## Features

- [x] Asynchronous image downloading and caching.
- [x] Loading image from either `URLSession`-based networking or local provided data.
- [x] Useful image processors and filters provided.
- [x] Multiple-layer hybrid cache for both memory and disk.
- [x] Fine control on cache behavior. Customizable expiration date and size limit.
- [x] Cancelable downloading and auto-reusing previous downloaded content to improve performance.
- [x] Independent components. Use the downloader, caching system, and image processors separately as you need.
- [x] Prefetching images and showing them from the cache to boost your app.
- [x] Extensions for `UIImageView`, `NSImageView`, `NSButton`, `UIButton`, `NSTextAttachment`, `WKInterfaceImage`, `TVMonogramView` and `CPListItem` to directly set an image from a URL.
- [x] Built-in transition animation when setting images.
- [x] Customizable placeholder and indicator while loading images.
- [x] Extensible image processing and image format easily.
- [x] Low Data Mode support.
- [x] SwiftUI support.

### Kingfisher 101

The simplest use-case is setting an image to an image view with the `UIImageView` extension:

```swift
import Kingfisher

let url = URL(string: "https://example.com/image.png")
imageView.kf.setImage(with: url)
```

Kingfisher will download the image from `url`, send it to both memory cache and disk cache, and display it in `imageView`. 
When you set it with the same URL later, the image will be retrieved from the cache and shown immediately.

It also works if you use SwiftUI:

```swift
var body: some View {
    KFImage(URL(string: "https://example.com/image.png")!)
}
```

### A More Advanced Example

With the powerful options, you can do hard tasks with Kingfisher in a simple way. For example, the code below: 

1. Downloads a high-resolution image.
2. Downsamples it to match the image view size.
3. Makes it round cornered with a given radius.
4. Shows a system indicator and a placeholder image while downloading.
5. When prepared, it animates the small thumbnail image with a "fade in" effect. 
6. The original large image is also cached to disk for later use, to get rid of downloading it again in a detail view.
7. A console log is printed when the task finishes, either for success or failure.

```swift
let url = URL(string: "https://example.com/high_resolution_image.png")
let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
             |> RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.indicatorType = .activity
imageView.kf.setImage(
    with: url,
    placeholder: UIImage(named: "placeholderImage"),
    options: [
        .processor(processor),
        .scaleFactor(UIScreen.main.scale),
        .transition(.fade(1)),
        .cacheOriginalImage
    ])
{
    result in
    switch result {
    case .success(let value):
        print("Task done for: \(value.source.url?.absoluteString ?? "")")
    case .failure(let error):
        print("Job failed: \(error.localizedDescription)")
    }
}
```

It is a common situation I can meet in my daily work. Think about how many lines you need to write without
Kingfisher!

### Method Chaining

If you are not a fan of the `kf` extension, you can also prefer to use the `KF` builder and chained the method 
invocations. The code below is doing the same thing:

```swift
// Use `kf` extension
imageView.kf.setImage(
    with: url,
    placeholder: placeholderImage,
    options: [
        .processor(processor),
        .loadDiskFileSynchronously,
        .cacheOriginalImage,
        .transition(.fade(0.25)),
        .lowDataMode(.network(lowResolutionURL))
    ],
    progressBlock: { receivedSize, totalSize in
        // Progress updated
    },
    completionHandler: { result in
        // Done
    }
)

// Use `KF` builder
KF.url(url)
  .placeholder(placeholderImage)
  .setProcessor(processor)
  .loadDiskFileSynchronously()
  .cacheMemoryOnly()
  .fade(duration: 0.25)
  .lowDataModeSource(.network(lowResolutionURL))
  .onProgress { receivedSize, totalSize in  }
  .onSuccess { result in  }
  .onFailure { error in }
  .set(to: imageView)
```

And even better, if later you want to switch to SwiftUI, just change the `KF` above to `KFImage`, and you've done:

```swift
struct ContentView: View {
    var body: some View {
        KFImage.url(url)
          .placeholder(placeholderImage)
          .setProcessor(processor)
          .loadDiskFileSynchronously()
          .cacheMemoryOnly()
          .fade(duration: 0.25)
          .lowDataModeSource(.network(lowResolutionURL))
          .onProgress { receivedSize, totalSize in  }
          .onSuccess { result in  }
          .onFailure { error in }
    }
}
```

### Learn More

To learn the use of Kingfisher by more examples, take a look at the well-prepared [Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet).
There we summarized the most common tasks in Kingfisher, you can get a better idea of what this framework can do. 
There are also some performance tips, remember to check them too.

## Requirements

- iOS 12.0+ / macOS 10.14+ / tvOS 12.0+ / watchOS 5.0+ (if you use only UIKit/AppKit)
- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+ (if you use it in SwiftUI)
- Swift 5.0+

> If you need support from iOS 10 (UIKit/AppKit) or iOS 13 (SwiftUI), use Kingfisher version 6.x. But it won't work 
> with Xcode 13.0 and Xcode 13.1 [#1802](https://github.com/onevcat/Kingfisher/issues/1802).
>
> If you need to use Xcode 13.0 and 13.1 but cannot upgrade to v7, use the `version6-xcode13` branch. However, you have to drop 
> iOS 10 support due to another Xcode 13 bug.
>
> | UIKit | SwiftUI | Xcode | Kingfisher |
> |---|---|---|---|
> | iOS 10+ | iOS 13+ | 12 | ~> 6.3.1 |
> | iOS 11+ | iOS 13+ | 13 | `version6-xcode13` |
> | iOS 12+ | iOS 14+ | 13 | ~> 7.0 |

### Installation

A detailed guide for installation can be found in [Installation Guide](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide).

#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/onevcat/Kingfisher.git`
- Select "Up to Next Major" with "7.0.0"

#### CocoaPods

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'
use_frameworks!

target 'MyApp' do
  pod 'Kingfisher', '~> 7.0'
end
```

#### Carthage

```
github "onevcat/Kingfisher" ~> 7.0
```


### Migrating

[Kingfisher 7.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-7.0-Migration-Guide) - Kingfisher 7.x is NOT fully compatible with the previous version. However, changes should be trivial or not required at all. Please follow the [migration guide](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-7.0-Migration-Guide) when you prepare to upgrade Kingfisher in your project.

If you are using an even earlier version, see the guides below to know the steps for migrating.

> - [Kingfisher 6.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-6.0-Migration-Guide) - Kingfisher 6.x is NOT fully compatible with the previous version. However, migration is not difficult. Depending on your use cases, it may take no effect or several minutes to modify your existing code for the new version. Please follow the [migration guide](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-6.0-Migration-Guide) when you prepare to upgrade Kingfisher in your project.
> - [Kingfisher 5.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-5.0-Migration-Guide) - If you are upgrading to Kingfisher 5.x from 4.x, please read this for more information.
> - Kingfisher 4.0 Migration - Kingfisher 3.x should be source compatible to Kingfisher 4. The reason for a major update is that we need to specify the Swift version explicitly for Xcode. All deprecated methods in Kingfisher 3 were removed, so please ensure you have no warning left before you migrate from Kingfisher 3 with Kingfisher 4. If you have any trouble when migrating, please open an issue to discuss.
> - [Kingfisher 3.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-3.0-Migration-Guide) - If you are upgrading to Kingfisher 3.x from an earlier version, please read this for more information.

## Next Steps

We prepared a [wiki page](https://github.com/onevcat/Kingfisher/wiki). You can find tons of useful things there.

* [Installation Guide](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide) - Follow it to integrate Kingfisher into your project.
* [Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet)- Curious about what Kingfisher could do and how would it look like when used in your project? See this page for useful code snippets. If you are already familiar with Kingfisher, you could also learn new tricks to improve the way you use Kingfisher!
* [API Reference](https://swiftpackageindex.com/onevcat/Kingfisher/master/documentation/kingfisher) - Lastly, please remember to read the full API reference whenever you need more detailed documentation.

## Other

### Future of Kingfisher

I want to keep Kingfisher lightweight. This framework focuses on providing a simple solution for downloading and caching images. This doesn’t mean the framework can’t be improved. Kingfisher is far from perfect, so necessary and useful updates will be made to make it better.

### Developments and Tests

Any contributing and pull requests are warmly welcome. However, before you plan to implement some features or try to fix an uncertain issue, it is recommended to open a discussion first. It would be appreciated if your pull requests could build with all tests green. :)

### About the logo

The logo of Kingfisher is inspired by [Tangram (七巧板)](http://en.wikipedia.org/wiki/Tangram), a dissection puzzle consisting of seven flat shapes from China. I believe she's a kingfisher bird instead of a swift, but someone insists that she is a pigeon. I guess I should give her a name. Hi, guys, do you have any suggestions?

### Contact

Follow and contact me on [Twitter](http://twitter.com/onevcat) or [Sina Weibo](http://weibo.com/onevcat). If you find an issue, [open a ticket](https://github.com/onevcat/Kingfisher/issues/new). Pull requests are warmly welcome as well.

## Backers & Sponsors

Open-source projects cannot live long without your help. If you find Kingfisher to be useful, please consider supporting this 
project by becoming a sponsor. Your user icon or company logo shows up [on my blog](https://onevcat.com/tabs/about/) with a link to your home page. 

Become a sponsor through [GitHub Sponsors](https://github.com/sponsors/onevcat). :heart:

Special thanks to:

[![imgly](https://user-images.githubusercontent.com/1812216/106253726-271ed000-6218-11eb-98e0-c9c681925770.png)](https://img.ly/)

[![emergetools](https://github-production-user-asset-6210df.s3.amazonaws.com/1019875/254794187-d44f6f50-993f-42e3-b79c-960f69c4adc1.png)](https://www.emergetools.com)



### License

Kingfisher is released under the MIT license. See LICENSE for details.
