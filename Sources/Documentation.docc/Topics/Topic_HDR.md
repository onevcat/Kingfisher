# HDR Images

Loading and showing images with high dynamic range (HDR) content.

## Overview

Many images now have an HDR version. A photo taken with a recent iPhone, or an "Ultra HDR" JPEG, stores an SDR base
image and a gain map: the information to restore the HDR version. Other HDR images use the PQ or HLG format directly.

Kingfisher shows HDR images in the PQ or HLG format as HDR by default. An image with a gain map is decoded as SDR on
iOS, tvOS and visionOS by default, because `UIImage(data:)` reads only its base image. To decode it as HDR, use the
``KingfisherOptionsInfoItem/preferHighDynamicRange`` option:

```swift
imageView.kf.setImage(with: url, options: [.preferHighDynamicRange])
imageView.preferredImageDynamicRange = .high
```

The view must allow HDR content too. A `UIImageView` or an `NSImageView` shows HDR content within a limited range by
default. Set its `preferredImageDynamicRange` to `.high` to use the full range of the display.

In SwiftUI, use the `allowedDynamicRange(_:)` modifier:

```swift
KFImage(url)
    .preferHighDynamicRange()
    .resizable()
    .allowedDynamicRange(.high)
```

## What the Option Changes

With ``KingfisherOptionsInfoItem/preferHighDynamicRange``:

- An image with a gain map is decoded with the gain map applied (iOS 17, tvOS 17 or visionOS 1 or later). On a system
  that cannot apply gain maps, such as the simulators, the image is decoded as usual.
- ``DownsamplingImageProcessor`` creates HDR thumbnails.
- ``KingfisherOptionsInfoItem/backgroundDecode`` keeps the image HDR.
- ``DefaultCacheSerializer`` stores the image with a gain map when the original file has one (iOS 18, tvOS 18,
  visionOS 2 or later), so it is HDR again when it is loaded from the disk cache. When that is not possible, an HDR
  image is stored as a 16-bit PNG file instead of an 8-bit JPEG file.
- The cache keys are different from the ones of the same image loaded without the option. An HDR image is not used
  for a request without the option, and the reverse.

An HDR image needs more memory than its SDR version: usually 8 bytes per pixel instead of 4. Use the option for the
images that benefit from HDR, and use ``DownsamplingImageProcessor`` for large images.

> On macOS, `NSImage` decodes an image with a gain map as HDR already. The option changes the thumbnails of
> ``DownsamplingImageProcessor``, background decoding and the cache keys there. On watchOS, the option has no effect.

## Managing the Cache

Because the option is part of the cache keys, pass
``KingfisherParsedOptionsInfo/cacheProcessorIdentifier`` as the processor identifier to check or remove the entry of
an image loaded with it:

```swift
let options = KingfisherParsedOptionsInfo([.preferHighDynamicRange])
let identifier = options.cacheProcessorIdentifier

cache.isCached(forKey: url.cacheKey, processorIdentifier: identifier)
cache.removeImage(forKey: url.cacheKey, processorIdentifier: identifier)
```

With a processor, set it in the options too, for example `[.preferHighDynamicRange, .processor(processor)]`.
