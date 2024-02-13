# Common Tasks - Cache

Common tasks related to the ``ImageCache`` in Kingfisher.

## Overview

Kingfisher employs a hybrid ``ImageCache`` for managing cached images, comprising both memory and disk storage. It 
offers high-level APIs for cache management. Unless otherwise specified, the ``ImageCache/default`` instance is 
used throughout Kingfisher.

### Using another cache key

By default, the URL is converted into a string to generate the cache key. For network URLs, `absoluteString` is 
utilized. You can customize the key by creating an ``ImageResource`` object with a specified key.

```swift
let resource = ImageResource(
    downloadURL: url, 
    cacheKey: "my_cache_key"
)
imageView.kf.setImage(with: resource)
```

Kingfisher uses the `cacheKey` to locate images in the cache. Ensure you use a distinct key for each different image.

#### Checking whether an image in the cache

```swift
let cache = ImageCache.default
let cached = cache.isCached(forKey: cacheKey)

// To know where the cached image is:
let cacheType = cache.imageCachedType(forKey: cacheKey)
// `.memory`, `.disk` or `.none`.
```

If a processor is applied when retrieving an image, the processed image will be cached. In this scenario, remember to 
also include the processor identifier when manipulating the cache:

```swift
let processor = RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.setImage(with: url, options: [.processor(processor)])

// Later
cache.isCached(forKey: cacheKey, processorIdentifier: processor.identifier)
```

#### Getting an image from the cache

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

#### Set limit for the cache

For memory storage, you can set its ``MemoryStorage/Config/totalCostLimit`` and ``MemoryStorage/Config/countLimit``:

```swift
// Limit memory cache size to 300 MB.
cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024

// Limit memory cache to hold 150 images at most. 
cache.memoryStorage.config.countLimit = 150
```

The default ``MemoryStorage/Config/totalCostLimit`` for the memory cache is set to 25% of the device's total memory, 
with no limit on the ``MemoryStorage/Config/countLimit``.

For disk storage, you have the option to set a ``DiskStorage/Config/sizeLimit`` to manage the space used on the file 
system.

```swift
// Limit disk cache size to 1 GB.
cache.diskStorage.config.sizeLimit =  = 1000 * 1024 * 1024
```

#### Set the default expiration for cache

Both memory and disk storage in Kingfisher have default expiration settings. Images in memory storage expire 5 minutes 
after the last access, whereas images in disk storage expire after one week. These values can be modified as follows:

```swift
// Set memory image expires after 10 minutes.
cache.memoryStorage.config.expiration = .seconds(600)

// Set disk image never expires.
cache.diskStorage.config.expiration = .never
```

To override this default expiration for a specific image when caching it, include an option as follows during image 
setting:

```swift
// This image will never expire in memory cache.
imageView.kf.setImage(with: url, options: [.memoryCacheExpiration(.never)])
```

The expired memory cache is purged every 2 minutes by default. To adjust this frequency:

```swift
// Check memory clean up every 30 seconds.
cache.memoryStorage.config.cleanInterval = 30
```

#### Store images to cache manually

By default, view extension methods and ``KingfisherManager`` automatically store retrieved images in the cache. 
However, you can also manually store an image to the cache:

```swift
let image: UIImage = //...
cache.store(image, forKey: cacheKey)
```

If you possess the original data of the image, pass it along to ``ImageCache``. This assists Kingfisher in determining 
the appropriate format for storing the image:

```swift
let data: Data = //...
let image: UIImage = //...
cache.store(image, original: data, forKey: cacheKey)
```

#### Remove images from cache manually

Kingfisher manages its cache automatically. But you still can manually remove a certain image from cache:

```swift
cache.removeImage(forKey: cacheKey)
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

If the image does not exist in the cache, an ``KingfisherError/CacheErrorReason/imageNotExisting(key:)`` error will be
triggered.

#### Waiting for cache to finish

Storing images in the disk cache is asynchronous and doesn't need to be completed before setting the image view and 
invoking the completion handler in view extension methods. This means that the disk cache might not be fully updated at
the time the completion handler is executed, as shown below:

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

For most scenarios, this asynchronous behavior isn't an issue. However, if your logic relies on the existence of the 
disk cache, use the `.waitForCache` option. With this option, Kingfisher will delay the execution of the handler until 
the disk cache operation is complete:

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

This consideration applies specifically to disk image caching, which involves asynchronous I/O operations. In contrast,
memory cache operations are synchronous, ensuring that the image is always available in the memory cache.
