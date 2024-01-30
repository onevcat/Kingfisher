# Common tasks - Processor

Common tasks related to the ``ImageProcessor`` in Kingfisher.

## Overview

``ImageProcessor`` transforms an image (or data) to another image. You can provide a processor to ``ImageDownloader`` 
to  apply it to the downloaded data. Then processed image will be sent to the image view and the cache.

### Use the Default Processor

```swift
// Just without anything
imageView.kf.setImage(with: url)
// It equals to
imageView.kf.setImage(with: url, options: [.processor(DefaultImageProcessor.default)])
```

> `DefaultImageProcessor` converts downloaded data to a corresponded image object. PNG, JPEG, and GIF are supported.

### Built-in Processors

```swift
// Round corner
let processor = RoundCornerImageProcessor(cornerRadius: 20)

// Downsampling
let processor = DownsamplingImageProcessor(size: CGSize(width: 100, height: 100))

// Cropping
let processor = CroppingImageProcessor(size: CGSize(width: 100, height: 100), anchor: CGPoint(x: 0.5, y: 0.5))

// Blur
let processor = BlurImageProcessor(blurRadius: 5.0)

// Overlay with a color & fraction
let processor = OverlayImageProcessor(overlay: .red, fraction: 0.7)

// Tint with a color
let processor = TintImageProcessor(tint: .blue)

// Adjust color
let processor = ColorControlsProcessor(brightness: 1.0, contrast: 0.7, saturation: 1.1, inputEV: 0.7)

// Black & White
let processor = BlackWhiteProcessor()

// Blend (iOS)
let processor = BlendImageProcessor(blendMode: .darken, alpha: 1.0, backgroundColor: .lightGray)

// Compositing
let processor = CompositingImageProcessor(compositingOperation: .darken, alpha: 1.0, backgroundColor: .lightGray)

// Use the process in view extension methods.
imageView.kf.setImage(with: url, options: [.processor(processor)])
```

### Multiple Processors

```swift
// First blur the image, then make it round cornered.
let processor = BlurImageProcessor(blurRadius: 4) |> RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.setImage(with: url, options: [.processor(processor)])
```

### Creating Your Own Processor

Make a type conforming to `ImageProcessor` by implementing `identifier` and `process`:

```swift
struct MyProcessor: ImageProcessor {

    // `identifier` should be the same for processors with the same properties/functionality
    // It will be used when storing and retrieving the image to/from cache.
    let identifier = "com.yourdomain.myprocessor"
    
    // Convert input data/image to target image and return it.
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            // A previous processor already converted the image to an image object.
            // You can do whatever you want to apply to the image and return the result.
            return image
        case .data(let data):
            // Your own way to convert some data to an image.
            return createAnImage(data: data)
        }
    }
}

// Then pass it to the `setImage` methods:
let processor = MyProcessor()
let url = URL(string: "https://example.com/my_image.png")
imageView.kf.setImage(with: url, options: [.processor(processor)])
```

### Creating a Processor from `CIFilter`

If you have a prepared `CIFilter`, you can create a processor quickly from it.

```swift
struct MyCIFilter: CIImageProcessor {

    let identifier = "com.yourdomain.myCIFilter"
    
    let filter = Filter { input in
        guard let filter = CIFilter(name: "xxx") else { return nil }
        filter.setValue(input, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }
}
```
