# Loading a local image or loading from data

## Overview

Kingfisher can set images from a local data source, enabling the processing and management of local image data using 
Kingfisher's features, without requiring network downloads.

### Image from Local File

`LocalFileImageDataProvider` is a type conforming to `ImageDataProvider`. It is used to load an image from a local file URL:

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

### Image from Base64 String

Use `Base64ImageDataProvider` to provide an image from base64 encoded data. All other features you expected, such as cache or image processors, should work as they are as when getting images from an URL.

```swift
let provider = Base64ImageDataProvider(base64String: "\/9j\/4AAQSkZJRgABAQA...", cacheKey: "some-cache-key")
imageView.kf.setImage(with: provider)
```

### Generating Image from AVAsset

Use `AVAssetImageDataProvider` to generate an image from a video URL or `AVAsset` at a given time:

```swift
let provider = AVAssetImageDataProvider(
    assetURL: URL(string: "https://example.com/your_video.mp4")!,
    seconds: 15.0
)
```

### Creating Your Own Image Data Provider

If you want to create your own image data provider type, conform to `ImageDataProvider` protocol by implementing a `cacheKey` and a `data(handler:)` method to provide image data:

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

        let letter = self.letter as NSString
        let rect = CGRect(x: 0, y: 0, width: 250, height: 250)
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let data = renderer.pngData { context in
            UIColor.black.setFill()
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
imageView.kf.setImage(with: provider)
```

Maybe you have already noticed, the `data(handler:)` contains a callback to you. You can provide the image data in an asynchronous way from another thread if it is too heavy in the main thread.
