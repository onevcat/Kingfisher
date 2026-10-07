# Common Tasks

Below is a code snippet designed to address the most commonly encountered tasks. You are encouraged to freely integrate 
this snippet into your upcoming projects.

@Metadata {
    @PageImage(purpose: card, source: "common-tasks-card"))
    @PageColor(blue)
}

## Overview

This document provides a comprehensive guide to the most prevalent use cases. The included code snippet is tailored for 
iOS development. Nevertheless, it can be adapted for other platforms, such as macOS or tvOS, with minimal modifications.
This typically involves substituting specific classes (for instance, replacing `UIImage` with `NSImage`). 

To explore detailed instructions for specific components within the Kingfisher framework, please refer to the 
subsequent documentation:

#### Common Tasks for Main Components

@Links(visualStyle: list) {
    - <doc:CommonTasks_Cache>
    - <doc:CommonTasks_Downloader>
    - <doc:CommonTasks_Processor>
}

#### Other Topics

@Links(visualStyle: list) {
    - <doc:Topic_Prefetch>
    - <doc:Topic_ImageDataProvider>
    - <doc:Topic_Indicator>
    - <doc:Topic_Retry>
    - <doc:Topic_LowDataMode> 
    - <doc:Topic_PerformanceTips>
}

## Most Common Tasks

The view extension-based APIs for `UIImageView`, `NSImageView`, `UIButton`, and `NSButton` are recommended as your 
primary choice. They simplify and enhance the elegance of your code.

### Setting Image with a `URL`

```swift
let url = URL(string: "https://example.com/image.jpg")
imageView.kf.setImage(with: url)
```

This code performs the following actions:

1. Verifies if an image is cached using the key `url.absoluteString`.
2. Retrieves and assigns the image to `imageView.image` if found in cache (memory or disk).
3. If absent, initiates a request and downloads from `url`.
4. Transforms the downloaded data into a `UIImage`.
5. Stores the image in both memory and disk caches.
6. Updates `imageView.image` with the new image.

Subsequent calls to `setImage` with the same URL will only execute steps 1 and 2, unless the cache has been cleared.

### Showing a Placeholder

```swift
let image = UIImage(named: "default_profile_icon")
imageView.kf.setImage(with: url, placeholder: image)
```

The `imageView` will display the `image` as the placeholder during its download from the `url`.

> You can also employ a custom `UIView` or `NSView` as a placeholder by making it conform to the `Placeholder` protocol:
> 
> ```swift
> class MyView: UIView { /* Implementation of your view */ }
> 
> extension MyView: Placeholder { /* This can be left empty */ }
> 
> imageView.kf.setImage(with: url, placeholder: MyView())
> ```
> 
> The instance of `MyView` will be dynamically added to or removed from the `imageView` as required.

For SwiftUI:
```swift
KFImage(url)
    .placeholder { ProgressView() }
```

If the image is already in the memory cache, `KFImage` shows it in the first render pass and does not show the
placeholder. This keeps the layout stable in lazy containers such as `LazyVStack` and `List`. To always show the
placeholder first, call `.loadMemoryCacheSynchronously(false)`.

### Showing a Loading Indicator while Downloading

```swift
imageView.kf.indicatorType = .activity
imageView.kf.setImage(with: url)
```

This shows a `UIActivityIndicatorView` in center of image view while downloading.

### Fading in Downloaded Image

For UIKit/AppKit:
```swift
imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
```

For SwiftUI (recommended):
```swift
KFImage(url)
    .fade(duration: 0.2)
    // Or use native SwiftUI transitions:
    .loadTransition(.opacity, animation: .easeInOut(duration: 0.2))
```

> Note: In SwiftUI applications, use `loadTransition` for native SwiftUI transitions instead of the options-based `transition`. This provides better integration with the SwiftUI animation system.

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

### Setting Image to a Button with Configuration

For a `UIButton` that uses `UIButton.Configuration`, set the foreground image with the same method as other buttons.
UIKit applies the image to `configuration.image` in each configuration update:

```swift
let button = UIButton(configuration: .plain())
button.kf.setImage(with: url, for: .normal)
```

UIKit ignores the background images that you set with `setBackgroundImage(with:for:)` on such a button. Use 
`setConfigurationBackgroundImage(with:)` instead. It sets the image to `configuration.background.image`:

```swift
let button = UIButton(configuration: .filled())
button.kf.setConfigurationBackgroundImage(with: url)

// Or with the builder:
KF.url(url).setConfigurationBackground(to: button)
```

> Important: The button must have a `configuration` before you set the background image. Kingfisher sets 
> `configuration.background.image` only once. If you replace `configuration` with a new value later, for example in a 
> `configurationUpdateHandler`, the image is removed. To keep it, change the current configuration instead of creating 
> a new one.

### Getting an Image without Setting to UI

Occasionally, you might need to retrieve an image using Kingfisher without assigning it to an image view. In such
cases, use ``KingfisherManager/retrieveImage(with:options:progressBlock:)-80fw1``


```swift
KingfisherManager.shared.retrieveImage(with: url) { result in 
    // Do something with `result`
}
```
