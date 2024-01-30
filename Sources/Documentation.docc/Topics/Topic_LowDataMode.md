# Loading Image for Low Data Mode

## Overview

From iOS 13, Apple allows user to choose to turn on [Low Data Mode] to save cellular and Wi-Fi usage. To respect this setting, you can provide an alternative (usually low-resolution) version of the image and Kingfisher will use that when Low Data Mode is enabled:

```swift
imageView.kf.setImage(
    with: highResolutionURL, 
    options: [.lowDataSource(.network(lowResolutionURL)]
)
```

If there is no network restriction applied by user, `highResolutionURL` will be used. Otherwise, when the device is under Low Data Mode and the `highResolutionURL` version is not hit in the cache, `lowResolutionURL` will be used.

Since `.lowDataSource` accept any `Source` parameter instead of only a URL, you can also pass in a local image provider to prevent any downloading task:

```swift
imageView.kf.setImage(
    with: highResolutionURL, 
    options: [
        .lowDataSource(
            .provider(LocalFileImageDataProvider(fileURL: localFileURL))
        )
    ]
)
```

> If `.lowDataSource` option is not provided, the `highResolutionURL` will be always used, regardless of the Low Data Mode setting on the device.
