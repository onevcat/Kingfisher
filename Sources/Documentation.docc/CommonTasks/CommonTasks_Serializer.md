# Common Tasks - Serializer

``CacheSerializer`` will be used to convert some data to an image object for retrieving from disk cache and vice versa 
for storing to the disk cache.

### Use the Default Serializer

```swift
// Just without anything
imageView.kf.setImage(with: url)
// It equals to
imageView.kf.setImage(with: url, options: [.cacheSerializer(DefaultCacheSerializer.default)])
```

> `DefaultCacheSerializer` converts cached data to a corresponded image object and vice versa. PNG, JPEG, and GIF are supported by default.

### Serializer to Force a Format

To specify a certain format an image should be, use `FormatIndicatedCacheSerializer`. It provides serializers for all built-in supported format: `FormatIndicatedCacheSerializer.png`, `FormatIndicatedCacheSerializer.jpeg` and `FormatIndicatedCacheSerializer.gif`.

By using the `DefaultCacheSerializer`, Kingfisher respects the input image data format and try to keep it unchanged. However, sometimes this default behavior might be not what you want. A common case is that, when you using a `RoundCornerImageProcessor`, in most cases maybe you want to have an alpha channel (for the corner part). If your original image is JPEG, the alpha channel would be lost when storing to disk. In this case, you may also want to set the png serializer to force converting the images to PNG:

```swift
let roundCorner = RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.setImage(with: url, 
    options: [.processor(roundCorner), 
              .cacheSerializer(FormatIndicatedCacheSerializer.png)]
)
```

### Creating Your Own Serializer

Make a type conforming to `CacheSerializer` by implementing `data(with:original:)` and `image(with:options:)`:

```swift
struct MyCacheSerializer: CacheSerializer {
    func data(with image: Image, original: Data?) -> Data? {
        return MyFramework.data(of: image)
    }
    
    func image(with data: Data, options: KingfisherParsedOptionsInfo?) -> Image? {
        return MyFramework.createImage(from: data)
    }
}

// Then pass it to the `setImage` methods:
let serializer = MyCacheSerializer()
let url = URL(string: "https://yourdomain.com/example.png")
imageView.kf.setImage(with: url, options: [.cacheSerializer(serializer)])
```
