<p align="center">

<img src="https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png" alt="Kingfisher" title="Kingfisher" width="557"/>

</p>

<p align="center">

<a href="https://travis-ci.org/onevcat/Kingfisher"><img src="https://img.shields.io/travis/onevcat/Kingfisher/master.svg"></a>

<a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>

<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-ready-orange.svg"></a>

<a href="http://cocoadocs.org/docsets/Kingfisher"><img src="https://img.shields.io/cocoapods/v/Kingfisher.svg?style=flat"></a>

<a href="https://raw.githubusercontent.com/onevcat/Kingfisher/master/LICENSE"><img src="https://img.shields.io/cocoapods/l/Kingfisher.svg?style=flat"></a>

<a href="http://cocoadocs.org/docsets/Kingfisher"><img src="https://img.shields.io/cocoapods/p/Kingfisher.svg?style=flat"></a>

<a href="https://codebeat.co/projects/github-com-onevcat-kingfisher"><img alt="codebeat" src="https://codebeat.co/badges/30b4386d-46e5-46ee-bcc6-251158bb5ef7" /></a>

<img src="https://img.shields.io/badge/made%20with-%3C3-orange.svg">


</p>

Kingfisher is a lightweight and pure Swift implemented library for downloading and caching image from the web. This project is heavily inspired by the popular [SDWebImage](https://github.com/rs/SDWebImage). And it provides you a chance to use pure Swift alternative in your next app.

## Features

- [x] Asynchronous image downloading and caching.
- [x] `URLSession` based networking. Basic image processors and filters supplied.
- [x] Multiple-layer cache for both memory and disk.
- [x] Cancelable downloading and processing task to improve performance.
- [x] Independent components. Use the downloader or caching system separately as you need.
- [x] Prefetching images and show them from cache later when necessary.
- [x] Extension over `UIImageView`, `NSImage` and `UIButton` for setting image from a URL directly.
- [x] Built-in transition animation when setting images.
- [x] Extendable image processing and more image format support.

The simplest using case is setting an image to an image view with extension:

```swift
let url = URL(string: "url_of_your_image")
imageView.kf_setImage(with: url)
```

It will download the image from `url`, send it to both memory and disk cache, then show it in the `imageView`. When you use the same code later, the image will be retrieved from cache and show immediately.

## Requirements

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Swift 3 (Kingfisher 3.x), Swift 2.3 (Kingfisher 2.x)

The main development of Kingfisher is based on Swift 3. There will be only fatal issue fix update for Kingfisher 2.x.

If you are upgrading to Kingfisher 3.x from an earlier version, please read the [Kingfisher 3.0 Migration Guide](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-3.0-Migration-Guide) for more information.

## Next Step

Check [wiki page](https://github.com/onevcat/Kingfisher/wiki) of Kingfisher.

* Follow the [Installation Guide](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide) to integrate Kingfisher to your project.
* Curious about what Kingfisher could do and how would it look like when used in your project? See our [Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet) page, in which some useful code snippet are listed. There you can learn how to use Kingfisher in your project better.
* At last, please also remember to check the full [API Reference](http://cocoadocs.org/docsets/Kingfisher/) whenever you need to know more about Kingfisher.

## Other

### Future of Kingfisher

I want to keep Kingfisher slim. This framework will focus on providing a simple solution for image downloading and caching. But that does not mean the framework will not be improved. Kingfisher is far away from perfect, and necessary and useful features will be added later to make it better.

### About the logo

The logo of Kingfisher is inspired by [Tangram (七巧板)](http://en.wikipedia.org/wiki/Tangram), a dissection puzzle consisting of seven flat shapes from China. I believe she's a kingfisher bird instead of a swift, but someone insists that she is a pigeon. I guess I should give her a name. Hi, guys, do you have any suggestion?

### Contact

Follow and contact me on [Twitter](http://twitter.com/onevcat) or [Sina Weibo](http://weibo.com/onevcat). If you find an issue, just [open a ticket](https://github.com/onevcat/Kingfisher/issues/new) on it. Pull requests are warmly welcome as well.

### License

Kingfisher is released under the MIT license. See LICENSE for details.


