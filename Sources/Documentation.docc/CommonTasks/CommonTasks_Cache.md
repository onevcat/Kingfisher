# Common Tasks - Cache

Common tasks related to the ``ImageCache`` in Kingfisher.

## Overview

Kingfisher is using a hybrid `ImageCache` to manage the cached images, It consists of a memory storage and a disk
storage, and provides high-level APIs to manipulate the cache system. If not specified, the `ImageCache.default` 
instance will be used across in Kingfisher.

### Using another cache key

By default, URL will be used to create a string for the cache key. For network URLs, the `absoluteString` will be used. 
In any case, you change the key by creating an `ImageResource` with your own key.

```swift
let resource = ImageResource(downloadURL: url, cacheKey: "my_cache_key")
imageView.kf.setImage(with: resource)
```

Kingfisher will use the `cacheKey` to search images in cache later. Use a different key for a different image.

#### Check whether an image in the cache

```swift
let cache = ImageCache.default
let cached = cache.isCached(forKey: cacheKey)

// To know where the cached image is:
let cacheType = cache.imageCachedType(forKey: cacheKey)
// `.memory`, `.disk` or `.none`.
```

If you used a processor when you retrieve the image, the processed image will be stored in cache. In this case, also 
pass the processor identifier:

```swift
let processor = RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.setImage(with: url, options: [.processor(processor)])

// Later
cache.isCached(forKey: cacheKey, processorIdentifier: processor.identifier)
```

#### Get an image from cache

```swift
cache.retrieveImage(forKey: "cacheKey") { result in
    switch result {
    case .success(let value):
        print(value.cacheType)

        // If the `cacheType is `.none`, `image` will be `nil`.
        print(value.image)

    case .failure(let error):
        print(error)
    }
}
```

#### Set limit for cache

For memory storage, you can set its `totalCostLimit` and `countLimit`:

```swift
// Limit memory cache size to 300 MB.
cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024

// Limit memory cache to hold 150 images at most. 
cache.memoryStorage.config.countLimit = 150
```

By default, the `totalCostLimit` of memory cache is 25% of your total memory in the device, and there is no limit on image count.

For disk storage, you can set `sizeLimit` for space on the file system.

```swift
// Limit disk cache size to 1 GB.
cache.diskStorage.config.sizeLimit =  = 1000 * 1024 * 1024
```

#### Set default expiration for cache

Both memory storage and disk storage have default expiration setting. Images in memory storage will expire after 5 minutes from last accessed, while it is a week for images in disk storage. You can change this value by:

```swift
// Memory image expires after 10 minutes.
cache.memoryStorage.config.expiration = .seconds(600)

// Disk image never expires.
cache.diskStorage.config.expiration = .never
```

If you want to override this expiration for a certain image when caching it, pass in with an option:

```swift
// This image will never expire in memory cache.
imageView.kf.setImage(with: url, options: [.memoryCacheExpiration(.never)])
```

The expired memory cache will be purged with a duration of 2 minutes. If you want it happens more frequently:

```swift
// Check memory clean up every 30 seconds.
cache.memoryStorage.config.cleanInterval = 30
```

#### Store images to cache manually

By default, view extension methods and `KingfisherManager` will store the retrieved image to cache automatically. But you can also store an image to cache yourself:

```swift
let image: UIImage = //...
cache.store(image, forKey: cacheKey)
```

If you have the original data of that image, also pass it to `ImageCache`, it helps Kingfisher to determine in which format the image should be stored:

```swift
let data: Data = //...
let image: UIImage = //...
cache.store(image, original: data, forKey: cacheKey)
```

#### Remove images from cache manually

Kingfisher manages its cache automatically. But you still can manually remove a certain image from cache:

```swift
cache.default.removeImage(forKey: cacheKey)
```

Or, with more control:

```swift
cache.removeImage(
    forKey: cacheKey,
    processorIdentifier: processor.identifier,
    fromMemory: false,
    fromDisk: true)
{
    print("Removed!")
}
```

#### Clear the cache

```swift
// Remove all.
cache.clearMemoryCache()
cache.clearDiskCache { print("Done") }

// Remove only expired.
cache.cleanExpiredMemoryCache()
cache.cleanExpiredDiskCache { print("Done") }
```

#### Report the disk storage size

```swift
ImageCache.default.calculateDiskStorageSize { result in
    switch result {
    case .success(let size):
        print("Disk cache size: \(Double(size) / 1024 / 1024) MB")
    case .failure(let error):
        print(error)
    }
}
```

#### Create your own cache and use it

```swift
// The `name` parameter is used to identify the disk cache bound to the `ImageCache`.
let cache = ImageCache(name: "my-own-cache")
imageView.kf.setImage(with: url, options: [.targetCache(cache)])
```

#### Skipping cache searching, force downloading image again 

```swift
imageView.kf.setImage(with: url, options: [.forceRefresh])
```

#### Only search cache for the image, do not download if not existing

This makes your app to an "offline" mode.

```swift
imageView.kf.setImage(with: url, options: [.onlyFromCache])
```

If the image is not existing in the cache, a `.cacheError` with `.imageNotExisting` reason will be raised.

#### Waiting for cache finishing

Storing images to disk cache is an asynchronous operation. However, it is not required to be done before we can set the image view and call the completion handler in view extension methods. In other words, the disk cache may not exist yet in the completion handler below:

```swift
imageView.kf.setImage(with: url) { _ in
    ImageCache.default.retrieveImageInDiskCache(forKey: url.cacheKey) { result in
        switch result {
        case .success(let image):
            // `image` might be `nil` here.
        case .failure: break
        }
    }
}
```

This is not a problem for most use cases. However, if your logic depends on the existing of disk cache, pass `.waitForCache` as an option. Kingfisher will then wait until the disk cache finishes before calling the handler:

```swift
imageView.kf.setImage(with: url, options: [.waitForCache]) { _ in
    ImageCache.default.retrieveImageInDiskCache(forKey: url.cacheKey) { result in
        switch result {
        case .success(let image):
            // `image` exists.
        case .failure: break
        }
    }
}
```

This is only for disk image cache, which involves to async I/O. For the memory cache, everything goes synchronously, so the image should be always in the memory cache.
