# Performance Tips

Some useful tips for better performance when using Kingfisher.

### Cancelling unnecessary downloading tasks

Once a download task is initiated, it will continue until completion, even if you set a different URL to the image view.

```swift
imageView.kf.setImage(with: url1) { result in 
    // `result` is `.failure(.imageSettingError(.notCurrentSourceTask))`
    // due to another `setImage` below.
    //
    // But the download (and cache) is done normally.
}

// Set again immediately.
imageView.kf.setImage(with: url2) { result in 
    // `result` is `.success`
}
```

Even if the setting for `url1` ends in a `.failure` because it was overridden by `url2`, the download task itself 
completes. The downloaded image data is processed and cached accordingly.

The download and caching of the image at `url1` consume network resources, CPU time, memory, and battery. If there's a 
likelihood the image from `url1` will be displayed to the user again, these resources are well spent. If you are certain 
that the image from `url1` is no longer needed, cancelling the download before initiating another one can be a better 
idea:

```swift
imageView.kf.setImage(with: url1) { result in
    // `result` is `.failure(.requestError(.taskCancelled))`
    // Now the download task is cancelled.
}

imageView.kf.cancelDownloadTask()
imageView.kf.setImage(with: url2) { result in
    // `result` is `.success`
}
```

This approach is particularly useful in table views or collection views. When users scroll through the list quickly, 
many image downloading tasks may be initiated. To optimize performance, you can cancel unnecessary tasks using the 
`didEndDisplaying` delegate method.

```swift
func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath)
{
    // This will cancel the unfinished downloading task when the cell disappearing.
    cell.imageView.kf.cancelDownloadTask()
}
```

### Cache original image when using a processor

If your goal is to either:

1. Use different processors on the same image to obtain various versions.
2. Apply a non-default processor to an image and later display the original.

Consider using the ``KingfisherOptionsInfoItem/cacheOriginalImage`` option. This option not only caches the processed 
image but also stores the original downloaded image in the cache.

```swift
let p1 = MyProcessor()
imageView.kf.setImage(with: url, options: [.processor(p1), .cacheOriginalImage])
```

Both the image processed by `p1` and the original downloaded image are cached. Later, when processing with another 
processor:

```swift
let p2 = AnotherProcessor()
imageView.kf.setImage(with: url, options: [.processor(p2)])
```

Kingfisher is clear enough to verify that the original image for the URL is cached. Instead of downloading the image 
again, Kingfisher will reuse the original image and apply `p2` to it directly.

### Downsampling the excessively high resolution images

In scenarios where you need to display large images in a table view or collection view cell, it's optimal to use 
smaller thumbnails to decrease download times and memory usage. However, if your server doesn't provide thumbnails, 
the ``DownsamplingImageProcessor`` comes to the rescue. It downsamples high-resolution images to a specified size
before they're loaded into memory, effectively optimizing performance:

```swift
imageView.kf.setImage(
    with: resource,
    placeholder: placeholderImage,
    options: [
        .processor(DownsamplingImageProcessor(size: imageView.size)),
        .scaleFactor(UIScreen.main.scale),
        .cacheOriginalImage
    ])
```

``DownsamplingImageProcessor`` is commonly used alongside ``KingfisherOptionsInfoItem/scaleFactor(_:)`` and 
``KingfisherOptionsInfoItem/cacheOriginalImage`` options. This combination ensures images are scaled appropriately for 
your UI's pixel density while also caching the original high-resolution image to avoid future downloads, providing an 
efficient balance between image quality and resource utilization.
