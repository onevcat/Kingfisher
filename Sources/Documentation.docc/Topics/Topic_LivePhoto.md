# Loading Live Photos

Load and cache Live Photos from network sources using Kingfisher.

## Overview

Kingfisher provides a seamless way to load Live Photos, which consist of a still image and a video, from network sources. This guide will walk you through the process of utilizing Kingfisher's Live Photo support.

## Live Photo Data Preparation

Before loading a Live Photo with Kingfisher, you need to prepare and host the data. Kingfisher can download and cache the live photo data from the network (usually your server or a CDN). This section demonstrates how to get the necessary data from a `PHAsset`.

If you've already set up the data and prepared the necessary URLs for the live photo components, you can skip to the next section to learn how to load it.

Assuming you have a valid `PHAsset` from the Photos framework, here's a sample of how to extract its data:

```swift
let asset: PHAsset = // ... your PHAsset
if !asset.mediaSubtypes.contains(.photoLive) {
    print("Not a live photo")
    return
}

let resources = PHAssetResource.assetResources(for: asset)
var allData = [Data]()

let group = DispatchGroup()
group.notify(queue: .main) {
    allData.forEach { data in
        // Upload data to your server
        serverRequest.upload(data)
    }
}

resources.forEach { resource in
    group.enter()
    var data = Data()
    PHAssetResourceManager.default().requestData(for: resource, options: nil) { chunk in
        data.append(chunk)
    } completionHandler: { error in
        defer { group.leave() }
        if let error = error {
            print("Error: \(error)")
            return
        }
        allData.append(data)
    }
}
```

Important notes:
- This is a basic example showing how to retrieve data from a live photo asset.
- Use [`PHAssetResource.type`]((https://developer.apple.com/documentation/photokit/phassetresource/1623987-type)) to get more information about each live photo resource. Typically, resources with `.photo` and `.pairedVideo` types are necessary for a minimal Live Photo.
- Do not modify the metadata or actual data of the resources, as this may cause problems when loading in Kingfisher later.
- When serving the files, it's recommended to include the file extensions (`.heic` for the still image, and `.mov` for the video) in the URL. While not mandatory, this helps Kingfisher identify the file type more accurately.
- You can use [`PHAssetResource.originalFilename`](https://developer.apple.com/documentation/photokit/phassetresource/1623985-originalfilename) to get and preserve the original file extension.


## Loading Live Photos

### Step 1: Import Required Frameworks and Set Up PHLivePhotoView

```swift
import Kingfisher
import PhotosUI

let livePhotoView = PHLivePhotoView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
view.addSubview(livePhotoView)
```

### Step 2: Prepare URLs

```swift
let imageURL = URL(string: "https://example.com/image.heic")!
let videoURL = URL(string: "https://example.com/video.mov")!
let urls = [imageURL, videoURL]
```

### Step 3: Load the Live Photo

```swift
livePhotoView.kf.setImage(with: urls) { result in
    switch result {
    case .success(let retrieveResult):
        print("Live photo loaded: \(retrieveResult.livePhoto)")
        print("Cache type: \(retrieveResult.loadingInfo.cacheType)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

The loaded live photo will be stored in the disk cache of Kingfisher to boost future loading requests. 

## Notes

- Verify that the provided URLs are valid and accessible.
- Loading may take time, especially for resources fetched over the network.
- Certain `KingfisherOptionsInfo` options, such as custom processors, are not supported for Live Photos.
- To load a Live Photo, its data must be cached on disk at least during the loading process. If you prefer not to retain the Live Photo data on disk, you can set a short disk cache expiration using options like `.diskCacheExpiration(.seconds(10))`, or manually clear the disk cache regularly after using.

## Conclusion

By following these steps, you can efficiently load and cache Live Photos in your iOS applications using Kingfisher, enhancing the user experience with smooth integration of this dynamic content type.