# ``Kingfisher``

@Metadata {
    @PageImage(
        purpose: icon, 
        source: "logo", 
        alt: "The logo icon of Kingfisher")
    @PageColor(blue)
}

A lightweight, pure-Swift library for downloading and caching images from the web.

## Overview

Kingfisher is a powerful, pure-Swift library for downloading and caching images from the web. It provides you a chance 
to use a pure-Swift way to work with remote images in your next app, regardless you are using UIKit, AppKit or SwiftUI.

With Kingfisher, you can easily:

- **Download** the images from a remote URL and display it in an image view or button.
- **Cache** the images in both the memory and the disk. When loading for the next time, it shows immediately without
downloading again.
- **Process** the downloaded images with pre-defined or customized processors. 

### Featured

@Links(visualStyle: detailedGrid) {
    - <doc:GettingStarted>
    - <doc:CommonTasks>
}


## Topics

### Essentials

- <doc:GettingStarted>
- <doc:CommonTasks>
- <doc:KingfisherInDepth>

### Loading Images in Simple Way

- <doc:UsingViewExtensions>
- ``KingfisherManager``
- ``KingfisherWrapper``
- ``Source``

### Loading Options

- ``KingfisherOptionsInfoItem``

### Image Downloader

- ``ImageDownloader``
- ``ImagePrefetcher``
- ``DownloadTask``

### Image Processor

- ``ImageProcessor``

### Image Cache & Serializer

- ``ImageCache``
- ``CacheSerializer``

### GIF

- ``AnimatedImageView``
- ``GIFAnimatedImage``

### SwiftUI

- ``KFImage``

### Help & Communication

- <doc:MigrationGuide>
- [Change Log](https://onevcat.com)
