<p align="center">
<img src="https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png" alt="Kingfisher" title="Kingfisher" width="557"/>
</p>

<p align="center">
<a href="https://travis-ci.org/onevcat/Kingfisher"><img src="https://img.shields.io/travis/onevcat/Kingfisher/master.svg"></a>
<a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
<a href="http://onevcat.github.io/Kingfisher/"><img src="https://img.shields.io/cocoapods/v/Kingfisher.svg?style=flat"></a>
<a href="https://raw.githubusercontent.com/onevcat/Kingfisher/master/LICENSE"><img src="https://img.shields.io/cocoapods/l/Kingfisher.svg?style=flat"></a>
<a href="http://onevcat.github.io/Kingfisher/"><img src="https://img.shields.io/cocoapods/p/Kingfisher.svg?style=flat"></a>
<a href="https://codebeat.co/projects/github-com-onevcat-kingfisher"><img alt="codebeat badge" src="https://codebeat.co/assets/svg/badges/A-398b39-669406e9e1b136187b91af587d4092b0160370f271f66a651f444b990c2730e9.svg" /></a>
<a href="#backers" alt="sponsors on Open Collective"><img src="https://opencollective.com/Kingfisher/backers/badge.svg" /></a>
<a href="#sponsors" alt="Sponsors on Open Collective"><img src="https://opencollective.com/Kingfisher/sponsors/badge.svg" /></a>
</p>

Kingfisher is a powerful, pure-Swift library for downloading and caching images from the web. It provides you a chance to use a pure-Swift way to work with remote images in your next app.

## Features

- [x] Asynchronous image downloading and caching.
- [x] Loading image from either `URLSession`-based networking or local provided data.
- [x] Useful image processors and filters provided.
- [x] Multiple-layer hybrid cache for both memory and disk.
- [x] Fine control on cache behavior. Customizable expiration date and size limit.
- [x] Cancelable downloading and auto-reusing previous downloaded content to improve performance.
- [x] Independent components. Use the downloader, caching system and image processors separately as you need.
- [x] Prefetching images and showing them from cache to boost your app.
- [x] View extensions for `UIImageView`, `NSImage`, `NSButton` and `UIButton` to directly set an image from a URL.
- [x] Built-in transition animation when setting images.
- [x] Customizable placeholder and indicator while loading images.
- [x] Extensible image processing and image format easily.

### Kingfisher 101

The simplest use-case is setting an image to an image view with the `UIImageView` extension:

```swift
let url = URL(string: "https://example.com/image.png")
imageView.kf.setImage(with: url)
```

Kingfisher will download the image from `url`, send it to both memory cache and disk cache, and display it in `imageView`. When you set with the same URL later, the image will be retrieved from cache and shown immediately.

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
let processor = DownsamplingImageProcessor(size: imageView.size)
             >> RoundCornerImageProcessor(cornerRadius: 20)
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

It is really a very common situation I can meet in my daily work. Think about how many lines you need to write without Kingfisher. You will fall in love with it if you give it a try!

### Learn More

To learn the using of Kingfisher by more examples, take a look at the [Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet). There we summarized most common tasks in Kingfisher, you can get a better idea on what this framework can do. There are also some tips for performance in the same page, remember to check them too.

## Requirements

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Swift 4.0+

[Kingfisher 5.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-5.0-Migration-Guide) - Kingfisher 5.x is NOT fully compatible with version 4.x. However, the migration is not difficult. Depending on your use cases, it may take no effect or several minutes to modify your existing code for the new version. Please follow the [migration guide](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-5.0-Migration-Guide) when you prepare to upgrade Kingfisher in your project.

If you are using an even earlier version, see the guides below to know the steps for migrating.

> - Kingfisher 4.0 Migration - Kingfisher 3.x should be source compatible to Kingfisher 4. The reason for a major update is that we need to specify the Swift version explicitly for Xcode. All deprecated methods in Kingfisher 3 has been removed, so please ensure you have no warning left before you migrate from Kingfisher 3 to Kingfisher 4. If you have any trouble in migrating, please open an issue to discuss.
> - [Kingfisher 3.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-3.0-Migration-Guide) - If you are upgrading to Kingfisher 3.x from an earlier version, please read this for more information.

## Next Steps

We prepared a [wiki page](https://github.com/onevcat/Kingfisher/wiki). You can find tons of useful things there.

* [Installation Guide](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide) - Follow it to integrate Kingfisher into your project.
* [Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet)- Curious about what Kingfisher could do and how would it look like when used in your project? See this page for useful code snippets. If you are already familiar with Kingfisher, you could also learn new tricks to improve the way you use Kingfisher!
* [API Reference](http://onevcat.github.io/Kingfisher/) - Lastly, please remember to read the full whenever you may need a more detailed reference.

## Other

### Future of Kingfisher

I want to keep Kingfisher lightweight. This framework will focus on providing a simple solution for downloading and caching images. This doesn’t mean the framework can’t be improved. Kingfisher is far from perfect, so necessary and useful updates will be made to make it better.

### Developments and Tests

Any contributing and pull requests are warmly welcome. However, before you plan to implement some features or try to fix an uncertain issue, it is recommended to open a discussion first. It would be appreciated if your pull requests could build and with all tests green. :)

### About the logo

The logo of Kingfisher is inspired by [Tangram (七巧板)](http://en.wikipedia.org/wiki/Tangram), a dissection puzzle consisting of seven flat shapes from China. I believe she's a kingfisher bird instead of a swift, but someone insists that she is a pigeon. I guess I should give her a name. Hi, guys, do you have any suggestions?

### Contact

Follow and contact me on [Twitter](http://twitter.com/onevcat) or [Sina Weibo](http://weibo.com/onevcat). If you find an issue, just [open a ticket](https://github.com/onevcat/Kingfisher/issues/new). Pull requests are warmly welcome as well.

## Contributors

This project exists thanks to all the people who contribute. [[Contribute]](https://github.com/onevcat/Kingfisher/blob/master/CONTRIBUTING.md).
<a href="https://opencollective.com/kingfisher#backer"><img src="https://opencollective.com/kingfisher/contributors.svg?width=890" /></a>


## Backers

Thank you to all our backers! Your support is really important for the project and encourages us to continue. 🙏 [[Become a backer](https://opencollective.com/kingfisher#backer)]

<a href="https://opencollective.com/kingfisher#backers" target="_blank"><img src="https://opencollective.com/kingfisher/backers.svg?width=890"></a>


## Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/kingfisher#sponsor)]

<a href="https://opencollective.com/kingfisher/sponsor/0/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/1/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/2/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/3/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/4/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/5/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/6/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/7/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/8/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/kingfisher/sponsor/9/website" target="_blank"><img src="https://opencollective.com/kingfisher/sponsor/9/avatar.svg"></a>

### License

Kingfisher is released under the MIT license. See LICENSE for details.
