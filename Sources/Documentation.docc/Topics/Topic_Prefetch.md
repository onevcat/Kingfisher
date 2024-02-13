# Prefetching images before actually loading  

Preloading images before actually required. Feeding them to the table view or collection view to improve the display speed.

## Overview

Use ``ImagePrefetcher`` to prefetch and cache images that are likely to be displayed later. This improves loading times 
and ensures smoother image display.

### Prefetch some images

```swift
let urls = [
    "https://example.com/image1.jpg", 
    "https://example.com/image2.jpg"
].map { URL(string: $0)! }

let prefetcher = ImagePrefetcher(urls: urls) {
    skippedResources, failedResources, completedResources in
    print("These resources are prefetched: \(completedResources)")
}
prefetcher.start()

// Later when you need to display these images:
imageView.kf.setImage(with: urls[0])
anotherImageView.kf.setImage(with: urls[1])
```

### Prefetch images for table view or collection view

Starting with iOS 10, Apple introduced cell prefetching behavior, which can seamlessly integrate with Kingfisher's 
``ImagePrefetcher``.

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
