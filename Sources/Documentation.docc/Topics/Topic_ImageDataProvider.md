# Understanding the ImageDataProvider

Loading a local image or loading from data.

## Overview

Kingfisher supports setting images from a local data source, allowing you to leverage its features for processing and
managing local image data, bypassing the need for network downloads. 

This allows for uniform API calls for both remote and local images, facilitating the reuse of familiar concepts, such 
as existing processors and cache serializers.

### Image from local file

``LocalFileImageDataProvider`` is a type that conforms to ``ImageDataProvider``. It is specifically designed for 
loading images from local file URLs:

```swift
let url = URL(fileURLWithPath: path)
let provider = LocalFileImageDataProvider(fileURL: url)
imageView.kf.setImage(with: provider)
```

You can also pass options to it:

```swift
let processor = RoundCornerImageProcessor(cornerRadius: 20)
imageView.kf.setImage(with: provider, options: [.processor(processor)])
```

### Image from Base64 string

Utilize ``Base64ImageDataProvider`` to supply an image from base64 encoded string. All standard features, including
caching and image processing, function identically to how they operate when retrieving images via a URL.

```swift
let provider = Base64ImageDataProvider(base64String: "\/9j\/4AAQSkZJRgABAQA...", cacheKey: "some-cache-key")
imageView.kf.setImage(with: provider)
```

### Generating image from AVAsset

Employ ``AVAssetImageDataProvider`` to create an image from a video URL or `AVAsset` at a specified time, 
leveraging Kingfisher's capabilities for handling video-based image sources.

```swift
let provider = AVAssetImageDataProvider(
    assetURL: URL(string: "https://example.com/your_video.mp4")!,
    seconds: 15.0
)
```

### Creating a customize ``ImageDataProvider``

To create your own image data provider, implement the ``ImageDataProvider`` protocol. This requires implementing a
``ImageDataProvider/cacheKey`` for unique identification and a ``ImageDataProvider/data(handler:)`` method to supply
image data:

```swift
struct UserNameLetterIconImageProvider: ImageDataProvider {
    var cacheKey: String { return letter }
    let letter: String
    
    init(userNameFirstLetter: String) {
        self.letter = userNameFirstLetter
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        
        // You can ignore these detail below.
        // It generates some data for an image with `letter` being rendered in the center.

        let rect = CGRect(x: 0, y: 0, width: 250, height: 250)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let data = renderer.pngData { context in
            UIColor.systemYellow.setFill()
            context.fill(rect)
            
            let attributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                                      .font: UIFont.systemFont(ofSize: 200)
            ]
            
            let textSize = letter.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height)
            letter.draw(in: textRect, withAttributes: attributes)
        }

        // Provide the image data in `handler`.
        handler(.success(data))
    }
}

// Set image for user "John"
let provider = UserNameLetterIconImageProvider(userNameFirstLetter: "J")
imageView.kf.setImage(
    with: provider,
    options: [.processor(RoundCornerImageProcessor(radius: .point(75)))]
)
```

This generates a result like:

@Image(source: imagedataprovider-sample)

You might have noticed that ``ImageDataProvider/data(handler:)`` includes a callback. This allows you to supply the
image data asynchronously from a different thread, which is useful if processing on the main thread is too heavy.
