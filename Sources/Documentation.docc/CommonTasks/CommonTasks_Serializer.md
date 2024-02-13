# Common Tasks - Serializer

``CacheSerializer`` is utilized to convert data into an image object for retrieval from disk cache, and conversely, 
for storing images to the disk cache.

### Use the default serializer

```swift
// Just without anything
imageView.kf.setImage(with: url)
// It equals to
imageView.kf.setImage(with: url, options: [.cacheSerializer(DefaultCacheSerializer.default)])
```

``DefaultCacheSerializer`` is responsible for converting cached data into a corresponding image object and vice versa. 
It supports PNG, JPEG, and GIF formats by default.

### Enforce a format

To enforce a specific image format, use ``FormatIndicatedCacheSerializer``, which offers serializers for all supported
formats: ``FormatIndicatedCacheSerializer/png``, ``FormatIndicatedCacheSerializer/jpeg``, and 
``FormatIndicatedCacheSerializer/gif``.

#### Use PNG serializer when rounding image corner

While ``DefaultCacheSerializer`` aims to preserve the original format of input image data, there are scenarios where 
this behavior might not meet your needs. For example, when using a ``RoundCornerImageProcessor``, it's often desirable 
to maintain an alpha channel for transparency around the corners. JPEG images, lacking an alpha channel, would not 
support this transparency when saved. To ensure the presence of an alpha channel by converting images to PNG, you can
set the PNG serializer explicitly:

```swift
let roundCorner = RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.setImage(with: url, 
    options: [.processor(roundCorner), 
              .cacheSerializer(FormatIndicatedCacheSerializer.png)]
)
```

### Creating customized serializer

Make a type conforming to `CacheSerializer` by implementing `data(with:original:)` and `image(with:options:)`:
To create a type that conforms to ``CacheSerializer``, implement the ``CacheSerializer/data(with:original:)`` 
and ``CacheSerializer/image(with:options:)``:

```swift
struct MyCacheSerializer: CacheSerializer {
    func data(with image: Image, original: Data?) -> Data? {
        return MyFramework.data(of: image)
    }
    
    func image(with data: Data, options: KingfisherParsedOptionsInfo?) -> Image? {
        return MyFramework.createImage(from: data)
    }
}
```

Then pass it to the ``KingfisherWrapper/setImage(with:placeholder:options:completionHandler:)-3ft7a`` methods:

```swift
let serializer = MyCacheSerializer()
let url = URL(string: "https://yourdomain.com/example.png")
imageView.kf.setImage(with: url, options: [.cacheSerializer(serializer)])
```
