# Low Data Mode

Loading image and customizing behaviors for the Low Data Mode.

## Overview

Starting with iOS 13, Apple has introduced the option for users to enable 
 [Low Data Mode](https://support.apple.com/en-us/102433) to reduce cellular and Wi-Fi data usage. To accommodate this 
setting, you can offer an alternative version of your image, typically in lower resolution. Kingfisher will 
automatically switch to this version when Low Data Mode is activated, helping to conserve data.

```swift
imageView.kf.setImage(
    with: highResolutionURL, 
    options: [.lowDataSource(.network(lowResolutionURL)]
)
```

In the scenario described, if the user has not applied any network restrictions, the `highResolutionURL` will be 
utilized for fetching the image. However, if the device is in Low Data Mode and the `highResolutionURL` version is not
found in the cache, the `lowResolutionURL` will be selected as the fallback option to save data.

Given that the `.lowDataSource` option accepts any `Source` parameter, not just a URL, you have the flexibility to pass 
in a local image provider. This approach effectively eliminates the need for a downloading task, allowing for the use 
of locally stored images when operating under Low Data Mode or other restrictive network conditions.

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

> For more about this topic, check <doc:Topic_ImageDataProvider> and ``ImageDataProvider`` documentation.

> tip: If the `.lowDataSource` option is not specified, the `highResolutionURL` will be used by default, regardless of 
> the Low Data Mode setting on the device.
