# Prefetching images before actually loading  

Loading images before actually needed. Feed them to the table view or collection view.

## Overview

You could use ``ImagePrefetcher`` to prefetch some images and cache them before you display them on the screen. This is
useful when you know a list of image resources you know they would probably be shown later.

### Prefetch some Images

```swift
let urls = ["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
           .map { URL(string: $0)! }
let prefetcher = ImagePrefetcher(urls: urls) {
    skippedResources, failedResources, completedResources in
    print("These resources are prefetched: \(completedResources)")
}
prefetcher.start()

// Later when you need to display these images:
imageView.kf.setImage(with: urls[0])
anotherImageView.kf.setImage(with: urls[1])
```

### Prefetch Images for Table View or Collection View

From iOS 10, Apple introduced a cell prefetching behavior. It could work seamlessly with Kingfisher's `ImagePrefetcher`.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.prefetchDataSource = self
}

extension ViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.flatMap { URL(string: $0.urlString) }
        ImagePrefetcher(urls: urls).start()
    }
}
```

See [WWDC 16 - Session 219](https://developer.apple.com/videos/play/wwdc2016/219/) for more about changing of it in iOS 10.
