# Common Tasks - Downloader

Common tasks related to the ``ImageDownloader`` in Kingfisher.

## Overview

``ImageDownloader`` wraps a `URLSession` for downloading an image from the Internet. Similar to ``ImageCache``, there
is a ``ImageDownloader/default`` downloader for downloading tasks.

### Downloading an image manually

Usually, you may use Kingfisher's view extension methods or `KingfisherManager` to retrieve an image. They will try to search in the cache first to prevent unnecessary download task. In some cases, if you only want to download a target image without caching it:

```swift
let downloader = ImageDownloader.default
downloader.downloadImage(with: url) { result in
    switch result {
    case .success(let value):
        print(value.image)
    case .failure(let error):
        print(error)
    }
}
```

### Modify a Request Before Sending

When you have permission control for your image resource, you can modify the request by using a `.requestModifier`:

```swift
let modifier = AnyModifier { request in
    var r = request
    r.setValue("abc", forHTTPHeaderField: "Access-Token")
    return r
}
downloader.downloadImage(with: url, options: [.requestModifier(modifier)]) { 
    result in
    // ...
}

// This option also works for view extension methods.
imageView.kf.setImage(with: url, options: [.requestModifier(modifier)])
```

### Async Request Modifier

If you need to perform some asynchronous operation before modifying the request, create a type and conform to `AsyncImageDownloadRequestModifier`:

```swift
class AsyncModifier: AsyncImageDownloadRequestModifier {
    var onDownloadTaskStarted: ((DownloadTask?) -> Void)?

    func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void) {
        var r = request
        someAsyncOperation { result in
            r.someProperty = result.property
            reportModified(r)
        }
    }
}
```

Similar as above, you can use the `.requestModifier` to use this modifier. In this case, the `setImage(with:options:)` or `ImageDownloader.downloadImage(with:options:)` method will not return a `DownloadTask` anymore (since it does not start the download task immediately). Instead, you observe one from the `onDownloadTaskStarted` callback if you need a reference to the task:

```swift
let modifier = AsyncModifier()
modifier.onDownloadTaskStarted = { task in
    if let task = task {
        print("A download task started: \(task)")
    }
}
let nilTask = imageView.kf.setImage(with: url, options: [.requestModifier(modifier)])
```

### Cancelling a Download Task

If the downloading started, a `DownloadTask` will be returned. You can use it to cancel an on-going download task:

```swift
let task = downloader.downloadImage(with: url) { result in
    // ...
    case .failure(let error):
        print(error.isTaskCancelled) // true
    }

}

// After for a while, before download task finishes.
task?.cancel()
```

If the task already finished when you call `task?.cancel()`, nothing will happen.

Similar, the view extension methods also return `DownloadTask`. You can store and cancel it:

```swift
let task = imageView.kf.set(with: url)
task?.cancel()
```

Or, you can call `cancelDownloadTask` on the image view to cancel the **current downloading task**:

```swift
let task1 = imageView.kf.set(with: url1)
let task2 = imageView.kf.set(with: url2)

imageView.kf.cancelDownloadTask()
// `task2` will be cancelled, but `task1` is still running. 
// However, the downloaded image for `task1` will not be set because the image view expects a result from `url2`.
```

### Authentication with `NSURLCredential`

The `ImageDownloader` uses a default behavior (`.performDefaultHandling`) when receives a challenge from server. If you need to provide your own credentials, setup an `authenticationChallengeResponder`:

```swift
// In ViewController
ImageDownloader.default.authenticationChallengeResponder = self

extension ViewController: AuthenticationChallengeResponsable {

    var disposition: URLSession.AuthChallengeDisposition { /* */ }
    let credential: URLCredential? { /* */ }

    func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        // Provide your `AuthChallengeDisposition` and `URLCredential`
        completionHandler(disposition, credential)
    }

    func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        // Provide your `AuthChallengeDisposition` and `URLCredential`
        completionHandler(disposition, credential)
    }
}
```

### Download Timeout

By default, the download timeout for a request is 15 seconds. To set it for the downloader:

```swift
// Set timeout to 1 minute.
downloader.downloadTimeout = 60
```

To define a timeout for a certain request, use a `.requestModifier`:

```swift
let modifier = AnyModifier { request in
    var r = request
    r.timeoutInterval = 60
    return r
}
downloader.downloadImage(with: url, options: [.requestModifier(modifier)])
```
