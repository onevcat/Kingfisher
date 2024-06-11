# Common Tasks - Downloader

Common tasks related to the ``ImageDownloader`` in Kingfisher.

## Overview

``ImageDownloader`` wraps a `URLSession` for downloading an image from the Internet. Similar to ``ImageCache``, there
is a ``ImageDownloader/default`` downloader for downloading tasks.

### Download an image manually

Typically, you might use Kingfisher's view extension methods or ``KingfisherManager`` for image retrieval. These methods 
prioritize searching the cache to avoid unnecessary downloads. If you need to download an image without caching it, 
consider the following approach:

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

### Modify a request before sending

When managing access to your image resources with permission controls, you can customize the request using a
``KingfisherOptionsInfoItem/requestModifier(_:)``:

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

### Use async request modifier

If an asynchronous operation is required before modifying the request, create a type that conforms to 
``AsyncImageDownloadRequestModifier``:

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

Similarly, use the ``KingfisherOptionsInfoItem/requestModifier(_:)`` to apply this modifier. In such scenarios, the
``KingfisherWrapper/setImage(with:placeholder:options:progressBlock:completionHandler:)-2uid3`` or
``ImageDownloader/downloadImage(with:options:completionHandler:)-5x6sa`` method will no longer return a ``DownloadTask``
directly, as the download task isn't initiated instantly. To reference the task, monitor the
``AsyncImageDownloadRequestModifier/onDownloadTaskStarted`` callback.

```swift
let modifier = AsyncModifier()
modifier.onDownloadTaskStarted = { task in
    if let task = task {
        print("A download task started: \(task)")
    }
}
let nilTask = imageView.kf.setImage(with: url, options: [.requestModifier(modifier)])
```

### Cancel a download task

Once the download has started, a ``DownloadTask`` will be created and returned. This can be used to cancel an ongoing 
download task.

```swift
let task = downloader.downloadImage(with: url) { result in
    // ...
    case .failure(let error):
        print(error.isTaskCancelled) // true
    }

}

// After some time, but before the download task completes.
task?.cancel()
```

If you call ``DownloadTask/cancel()`` after the task has already finished, no action will be taken.

Likewise, the view extension methods return a ``DownloadTask`` as well. This allows you to store the task and cancel it 
if needed:

```swift
let task = imageView.kf.set(with: url)
task?.cancel()
```

Alternatively, you can invoke ``KingfisherWrapper/cancelDownloadTask()-2gg15`` on the image view to cancel the 
**current downloading task**.

```swift
let task1 = imageView.kf.set(with: url1)
let task2 = imageView.kf.set(with: url2)

imageView.kf.cancelDownloadTask()
// `task2` will be cancelled, but `task1` is still running. 
// However, the downloaded image for `task1` will not be set because the image view expects a result from `url2`.
```

### Authentication with `NSURLCredential`

The ``ImageDownloader`` defaults to `.performDefaultHandling` upon receiving a server challenge. To supply custom 
credentials, configure an ``ImageDownloader/authenticationChallengeResponder``:

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

### Set customize timeout

The default download timeout for a request is 15 seconds. To customize this for the downloader:

```swift
// Set the timeout to 1 minute.
downloader.downloadTimeout = 60
```

For setting a timeout specific to a request, utilize a ``KingfisherOptionsInfoItem/requestModifier(_:)``:

```swift
let modifier = AnyModifier { request in
    var r = request
    r.timeoutInterval = 60
    return r
}
downloader.downloadImage(with: url, options: [.requestModifier(modifier)])
```
