# Common tasks - Processor

Common tasks related to the ``ImageProcessor`` in Kingfisher.

## Overview

``ImageProcessor`` is used to transform an image (or data) into another image. By supplying a processor to 
``KingfisherManager`` when setting the image, it can be applied to the downloaded data. The processed image will then 
be sent to the image view and stored in the cache.

### Use the default processor

```swift
// Just without anything
imageView.kf.setImage(with: url)
// It equals to
imageView.kf.setImage(with: url, options: [.processor(DefaultImageProcessor.default)])
```

> The ``DefaultImageProcessor`` converts downloaded data into a corresponding image object. 
> It supports PNG, JPEG, and GIF formats.

### Built-in Processors

@Row {
    @Column(size: 3) {
        ```swift
        // Round corner
        RoundCornerImageProcessor(cornerRadius: 20)
        ```
    }
    
    @Column {
        ![A screenshot of the power picker user interface with four powers displayed – ice, fire, wind, and lightning](common-tasks-card)
    }
}

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

### Creating your own processor

Make a type conforming to `ImageProcessor` by implementing `identifier` and `process`:

> important: ``ImageProcessor/identifier`` is used to determine the cache key when this processor is applied. It is your
> responsibility to keep it the same for processors with the same properties/functionality.

```swift
struct MyProcessor: ImageProcessor {

    let someValue: Int

    var identifier: String { "com.yourdomain.myprocessor-\(someValue)" }
    
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
```

Then pass it to the ``KingfisherWrapper/setImage(with:placeholder:options:completionHandler:)-3ft7a`` methods:

```swift
let processor = MyProcessor(someValue: 10)
let url = URL(string: "https://example.com/my_image.png")
imageView.kf.setImage(with: url, options: [.processor(processor)])
```

### Creating a processor from CIFilter

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
