# Performance Tips

Some useful tips for better performance when using Kingfisher.

#### Cancelling unnecessary downloading tasks

Once a downloading task initialized, even when you set another URL to the image view, that task will continue until finishes.

```swift
imageView.kf.setImage(with: url1) { result in 
    // `result` is `.failure(.imageSettingError(.notCurrentSourceTask))`
    // But the download (and cache) is done.
}

// Set again immediately.
imageView.kf.setImage(with: url2) { result in 
    // `result` is `.success`
}
```

Although setting for `url1` results in a `.failure` since the setting task was overridden by `url2`, the download task itself is finished. The downloaded image data is also processed and cached.

The downloading and caching operation for the image at `url1` is not free, it costs network, CPU time, memory and also, battery. 

In most cases, it worths to do that. Since there is a chance that the image is shown to the user again. But if you are sure that you do not need the image from `url1`, you can cancel the downloading before starting another one:

```swift
imageView.kf.setImage(with: ImageLoader.sampleImageURLs[8]) { result in
    // `result` is `.failure(.requestError(.taskCancelled))`
    // Now the download task is cancelled.
}

imageView.kf.cancelDownloadTask()
imageView.kf.setImage(with: ImageLoader.sampleImageURLs[9]) { result in
    // `result` is `.success`
}
```

This technology sometimes is useful in a table view or collection view. When users scrolling the list fast, maybe quite a lot of image downloading tasks would be created. You can cancel unnecessary tasks in the `didEndDisplaying` delegate method:

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

#### Using processor with `ImageCache`

Kingfisher is smart enough to cache the processed images and then get it back if you specify the correct `ImageProcessor` in the option. Each `ImageProcessor` contains an `identifier`. It is used when caching the processed images.

Without the `identifier`, Kingfisher will not be able to tell which is the correct image in cache. Think about the case you have to store two versions of an image from the same url, one should be round cornered and another should be blurred. You need two different cache keys. In all Kingfisher's built-in image processors, the identifier will be determined by the kind of processor, combined with its parameters for each instance. For example, a round corner processor with 20 as its corner radius might have an `identifier` as `round-corner-20`, while a 40 radius one's could be `round-corner-40`. (Just for demonstrating, they are not that simple value in real)

So, when you create your own processor, you need to make sure that you provide a different `identifier` for any different processor instance, with its parameter considered. This helps the processors work well with the cache. Furthermore, it prevents unnecessary downloading and processing.

#### Cache original image when using a processor

If you are trying to do one of these:

1. Process the same image with different processors to get different versions of the image.
2. Process an image with a processor other than the default one, and later need to display the original image.

It worths passing `.cacheOriginalImage` as an option. This will store the original downloaded image to cache as well:

```swift
let p1 = MyProcessor()
imageView.kf.setImage(with: url, options: [.processor(p1), .cacheOriginalImage])
```

Both the processed image by `p1` and the original downloaded image will be cached. Later, when you process with another processor:

```swift
let p2 = AnotherProcessor()
imageView.kf.setImage(with: url, options: [.processor(p2)])
```

The processed image for `p2` is not in cache yet, but Kingfisher now has a chance to check whether the original image for `url` being in cache or not. Instead of downloading the image again, Kingfisher will reuse the original image and then apply `p2` on it directly.

#### Using `DownsamplingImageProcessor` for high resolution images

Think about the case we want to show some large images in a table view or a collection view. In the ideal world, we expect to get smaller thumbnails for them, to reduce downloading time and memory use. But in the real world, maybe your server doesn't prepare such a thumbnail version for you. The newly added `DownsamplingImageProcessor` rescues. It downsamples the high-resolution images to a certain size before loading to memory:

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

Typically, `DownsamplingImageProcessor` is used with `.scaleFactor` and `.cacheOriginalImage`. It provides a reasonable image pixel scale for your UI, and prevent future downloading by caching the original high-resolution image.
