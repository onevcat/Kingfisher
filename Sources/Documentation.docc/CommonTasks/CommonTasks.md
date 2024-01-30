# Common Tasks

Code snippet that covers the most common tasks. Feel free to copy and paste them to your next great project.

@Metadata {
    @PageImage(purpose: card, source: "common-tasks-card"))
    @PageColor(blue)
}

## Overview

This documentation will describe some of the most common usage in general. The code snippet is based on iOS. 
However, the similar code should also work for other platforms like macOS or tvOS, by replacing the corresponding class 
(such as `UIImage` to `NSImage`, etc).

For common tasks of a specific part of Kingfisher, check the documentation below as well:

#### Common Tasks for Main Components

- <doc:CommonTasks_Cache>
- <doc:CommonTasks_Downloader>
- <doc:CommonTasks_Processor>

#### Other Topics

- <doc:Topic_Prefetch>
- <doc:Topic_ImageDataProvider>
- <doc:Topic_Indicator>
- <doc:Topic_Retry>
- <doc:Topic_LowDataMode> 
- <doc:Topic_PerformanceTips>

## Most Common Tasks

The view extension based APIs (for `UIImageView`, `NSImageView`, `UIButton` and `NSButton`) should be your first choice
whenever possible. It keeps your code simple and elegant.

### Setting Image with a `URL`

```swift
let url = URL(string: "https://example.com/image.jpg")
imageView.kf.setImage(with: url)
```

This simple code does these things:

1. Checks whether an image is cached under the key `url.absoluteString`.
2. If an image was found in the cache (either in memory or disk), sets it to `imageView.image`.
3. If not, creates a request and download it from `url`.
4. Converts the downloaded data to a `UIImage` object.
5. Caches the image to memory and disk.
6. Sets the `imageView.image` to display it.

Later, when you call the `setImage` with the same url again, only step 1 and 2 will be performed, unless the cache is 
purged.


### Showing a Placeholder

```swift
let image = UIImage(named: "default_profile_icon")
imageView.kf.setImage(with: url, placeholder: image)
```

The `image` will show in the `imageView` while downloading from `url`.

> You could also use a customized `UIView` or `NSView` as placeholder, by conforming it to `Placeholder`:
>
> ```swift
> class MyView: UIView { /* Your implementation of view */ }
>
> extension MyView: Placeholder { /* Just leave it empty */}
> 
> imageView.kf.setImage(with: url, placeholder: MyView())
> ```
>
> The `MyView` instance will be added to / removed from the `imageView` as needed.

### Showing a Loading Indicator while Downloading

```swift
imageView.kf.indicatorType = .activity
imageView.kf.setImage(with: url)
```

Show a `UIActivityIndicatorView` in center of image view while downloading.

### Fading in Downloaded Image

```swift
imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
```

### Completion Handler

```swift
imageView.kf.setImage(with: url) { result in
    // `result` is either a `.success(RetrieveImageResult)` or a `.failure(KingfisherError)`
    switch result {
    case .success(let value):
        // The image was set to image view:
        print(value.image)

        // From where the image was retrieved:
        // - .none - Just downloaded.
        // - .memory - Got from memory cache.
        // - .disk - Got from disk cache.
        print(value.cacheType)

        // The source object which contains information like `url`.
        print(value.source)

    case .failure(let error):
        print(error) // The error happens
    }
}
```

### Getting an Image without Setting to UI

Sometimes, you just want to get the image with Kingfisher instead of setting it to an image view. Use `KingfisherManager` for it:

```swift
KingfisherManager.shared.retrieveImage(with: url) { result in 
    // Do something with `result`
}
```
