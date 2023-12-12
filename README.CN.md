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

Kingfisher是一个功能强大的纯Swift库，用于从网络上下载和缓存图像。在下一个App中，它为你提供了可能性——使用纯Swift库来处理远程图像。

## 功能

- [x] 异步图像下载与缓存
- [x] 通过基于`URLSession`的网络或是本地方式加载图像
- [x] 提供了实用的图像处理器及滤镜
- [x] 支持内存及磁盘多级混合缓存
- [x] 强大的缓存行为控制——自定义过期时间与空间限制
- [x] 下载可取消、已下载内容自动复用以提高性能
- [x] Independent components. Use the downloader, caching system, and image processors separately as you need.
- [x] 独立组件。根据需要单独使用下载、缓存和图像处理模块
- [x] 预加载图像并且从缓存直接展示以提升App体验
- [x] 调用`UIImageView`, `NSImageView`, `NSButton`, `UIButton`, `NSTextAttachment`, `WKInterfaceImage`, `TVMonogramView` 和 `CPListItem`的扩展设置URL对应的图像
- [x] 设置图像时内置动画
- [x] 自定义缺省图像及加载指示器
- [x] 可以很容易的扩展图像处理过程和格式化
- [x] 支持低数据模式
- [x] 支持`SwiftUI`

### Kingfisher 101

最简单的使用示例是调用`UIImageView`的扩展方法给图像控件设置图像：

```swift
import Kingfisher

let url = URL(string: "https://example.com/image.png")
imageView.kf.setImage(with: url)
```

Kingfisher会下载`url`下的图像，将它设置到内存及磁盘缓存的同时，在`imageView`中展示。
当你后续设置相同的URL时，图像将直接从缓存中读出并立即展示。

在SwiftUI中亦如是：

```swift
var body: some View {
    KFImage(URL(string: "https://example.com/image.png")!)
}
```

### 进阶示例

由于强大的能力，你可以通过Kingfisher以一种简洁的方式完成十分困难的任务。比如以下代码：

1. 下载一个高清图像
2. 降低采样使其与图像控件的尺寸相匹配
3. 指定半径圆角化
4. 在下载过程中，展示系统的指示器和一张默认图像
5. 当（图像）准备好后，将原来的小的缩略图以渐隐的动画效果隐藏（并渐现展示自身）
6. 原始大图被缓存在磁盘中，防止在详情视图中重复下载
7. 当任务完成时，不论成功或失败，在控制台打印日志

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

这是在日常工作中我经常遇到的普通场景。想像一下如果不使用Kingfisher你需要写多少行代码！

### 链式方法

如果你不是`kf`扩展的拥趸，你也可以使用`KF`创建器并链式调用方法。下面的代码做的是同一件事：

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

而更妙的时，如果你后续要切换到SwiftUI，仅仅需要将上文中的`KF`替换成`KFImage`即可：

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

### 了解更多

想通过示例了解更多Kingfisher的用法，可以查看详尽的[备忘录](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet)。

在这里我们汇总了Kingfisher中最常见的任务，而你可以根据这个库的能力产生更棒的想法。
在这里也有一些关于性能上的小提醒，记得也瞅眼它们。

## 必要条件

- iOS 12.0+ / macOS 10.14+ / tvOS 12.0+ / watchOS 5.0+ (if you use only UIKit/AppKit)
- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+ (if you use it in SwiftUI)
- Swift 5.0+

> 如果你需要支持iOS 10 (UIKit/AppKit）或iOS 13（SwiftUI），使用Kingfisher 6.x版本。
>  但它在Xcode 13.0 和Xcode 13.1中会失效 [#1802](https://github.com/onevcat/Kingfisher/issues/1802).
>
> 如果你需要使用Xcode 13.0和Xcode 13.1 而又无法升级到v7，使用`version6-xcode13`分支版本。
>  由于Xcode 13的另一个Bug，这样做你就不得不放弃支持iOS 10
>
> | UIKit | SwiftUI | Xcode | Kingfisher |
> |---|---|---|---|
> | iOS 10+ | iOS 13+ | 12 | ~> 6.3.1 |
> | iOS 11+ | iOS 13+ | 13 | `version6-xcode13` |
> | iOS 12+ | iOS 14+ | 13 | ~> 7.0 |

### 安装

[安装指南](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide)有更详细的安装指导.

#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- 添加 `https://github.com/onevcat/Kingfisher.git`
- 选择 "Up to Next Major" 为 "7.0.0"

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


### 迁移

[Kingfisher 7.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-7.0-Migration-Guide) - Kingfisher 7.x 与之前的版本非完全兼容。但也仅需要很少的或无需修改即可. 如果你需要更新工程中的Kingfisher，请参考 [迁移指南](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-7.0-Migration-Guide)。

如果你使用更早的版本，可以参考下列步骤迁移：

> - [Kingfisher 6.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-6.0-Migration-Guide) - Kingfisher 6.x 与之前的版本不完全兼容，但迁移并不难。根据你的使用场景，可能不需要，或是几分钟就能将现在代码修改成适配新版本。如果你需要更新工程中的Kingfisher，请参考[迁移指南](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-6.0-Migration-Guide)。
> - [Kingfisher 5.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-5.0-Migration-Guide) - 如果你需要将Kingfisher从4.x更新到5.x，请阅读以获得更多信息。
> - Kingfisher 4.0 Migration - Kingfisher 3.x 与4应该是源码兼容的。做大版本更新的原因是我们需要明确指定Xcode中的Swift版本。所有Kingfisher 3中标记废弃的方法都被删除了，所以请确保在Kingfisher 3迁移到Kingfisher 4前没有警告遗留。如果你在迁移过程中遇到问题，请提交Issue一起讨论。
> - [Kingfisher 3.0 Migration](https://github.com/onevcat/Kingfisher/wiki/Kingfisher-3.0-Migration-Guide) - 如果你需要将Kingfisher从早期版本更新到3.x，请阅读以获得更多信息。


## 后续步骤

我们添加了[wiki page](https://github.com/onevcat/Kingfisher/wiki). 在这里你可以找到很多有用的东西。

* [安装指南](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide) - 按它说的可以让你方便的将Kingfisher集成到工程中。
* [备忘录](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet)- 好奇Kingfisher能做什么？集成到工程是什么样子的？这个页面中可以查看实用的代码片段。如果你对Kingfisher已经很熟悉了，依然可以了解到新的使用技巧！
* [API Reference](https://swiftpackageindex.com/onevcat/Kingfisher/master/documentation/kingfisher) - 最后，无论何时需要更细节的文档，请记得去读一下完整的API参考文档。

## 附

### Kingfisher的未来

我希望保持Kingfisher轻量化。该库致力于提供一个简洁的图像下载缓存解决方案。但这并不意味着它不能被改善。Kingfisher还远不完美，因此必要和实用的更新会让它变得越来越好。

### 开发及测试

任何`Contibuting`与`Pull Requests`都热烈欢迎。然而，在你实现某个功能，或者尝试修复某个不确定的issue之前，建议先提交一个议题讨论。如果你的PR能通过所有单测，我将不胜感激 :)

### 关于Logo

Kingfisher的logo灵感来自[七巧板](http://en.wikipedia.org/wiki/Tangram),来自中文的由7块板子组成的解谜游戏. 她是翠鸟而不是雨燕，还有人坚持说她是鸽子。我想是时候给她个名字了，嗨，兄弟，有没有什么好的建议啊？

### 联系方式

可通过 [Twitter](http://twitter.com/onevcat) 或 [Sina Weibo](http://weibo.com/onevcat)关注或联系我. 如果你发现了问题, [open a ticket](https://github.com/onevcat/Kingfisher/issues/new). Pull requests 也同样热烈欢迎.

## 支持 & 赞助

没有你们的帮助，开源项目很难维持。如果你觉得Kingfisher很实用，请考虑成功资助者要支持这个项目。你的用户头像或公司logo会在[我的博客](https://onevcat.com/tabs/about/)中展示，并链接到你们的主页中。

通过[GitHub Sponsors](https://github.com/sponsors/onevcat)成为赞助者. :heart:

特别鸣谢:

[![imgly](https://user-images.githubusercontent.com/1812216/106253726-271ed000-6218-11eb-98e0-c9c681925770.png)](https://img.ly/)

[![emergetools](https://github-production-user-asset-6210df.s3.amazonaws.com/1019875/254794187-d44f6f50-993f-42e3-b79c-960f69c4adc1.png)](https://www.emergetools.com)



### License

Kingfisher is released under the MIT license. See LICENSE for details.
