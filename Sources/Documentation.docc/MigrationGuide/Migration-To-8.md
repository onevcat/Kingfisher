# Migrating from v7 to v8

This guide assists you in updating Kingfisher from version 7 to version 8.

## Overview

Kingfisher 8.0 introduces breaking changes from its predecessor. This document highlights the major updates and significant API modifications.

## Deployment Target

Starting with Kingfisher 8.0, the minimum supported versions are:

- iOS 13.0
- macOS 10.15
- tvOS 13.0
- watchOS 6.0
- visionOS 1.0

## Migration Steps and Insights

First, ensure there are no existing warnings from Kingfisher. Several deprecated methods and properties have been removed in version 8.

For the breaking changes, review the sections below for any utilized features and symbols.

### MainActor Requirement

As support for Swift Concurrency is introduced in Kingfisher 8, some APIs, usually the view extension ones, require the `MainActor` attribute. Ensure your codebase is updated to include this attribute where necessary. For usage in `UIViewController` and `UIView`, since they are already implicitly under `MainActor`, no additional changes are required. For other cases, if you encounter a compiler error:


```swift
class Foo {
    func bar() {
        UIImageView().kf.setImage(with: URL(string: "https://example.com/image.png"))
    }
}
```

> warning:
>
> Call to main actor-isolated instance method 'setImage(with:placeholder:options:completionHandler:)' in a synchronous nonisolated context.

Try to limit the access to the `MainActor`. For example, add the `MainActor` attribute to the method:

```swift
class Foo {
    @MainActor
    func bar() {
        UIImageView().kf.setImage(with: URL(string: "https://example.com/image.png"))
    }
}
```

The concurrence support in Kingfisher 8 is not yet fully "strictly-compatible". That means if you set `SWIFT_STRICT_CONCURRENCY` to `Complete`, you may still see some warnings. The current status of Swift Concurrency does not contain all the necessary isolation for us to make the library fully compatible. We are working on it and will provide a fully compatible version in the future.

### Disk Cache Changes

Version 8 updates the disk cache hash calculation method, invalidating existing caches. Kingfisher's disk cache is resilient, automatically re-downloading and caching data if missing. Typically, no action is required unless your application's logic heavily relies on the disk cache, which is generally not recommended.

### Swift Concurrency APIs

Kingfisher now embraces Swift's `async` keyword, enhancing most asynchronous APIs previously implemented with completion handlers. While the traditional APIs remain in struct and class types, some protocol methods have transitioned to `async` without the traditional ones. 

Ensure your implementations conform to these changes.

#### `ImageDownloadRedirectHandler` Protocol

The `handleHTTPRedirection(for:response:newRequest:completionHandler:)` method has been replaced with an asynchronous counterpart. Update your implementation accordingly:

```swift
// Old
extension YourType: ImageDownloadRedirectHandler {
    func handleHTTPRedirection(
        for task: Kingfisher.SessionDataTask,
        response: HTTPURLResponse, 
        newRequest: URLRequest, 
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Do something with the result, potentially in async way
        requestUpdater.update(newRequest) { result in
            completionHandler(result)
        }
    }
}
```

```swift
// New
extension YourType: ImageDownloadRedirectHandler {
    func handleHTTPRedirection(
        for task: Kingfisher.SessionDataTask,
        response: HTTPURLResponse, 
        newRequest: URLRequest
    ) async -> URLRequest? {
        let result = await requestUpdater.update(newRequest)
        return result
    }
}
```

#### `AsyncImageDownloadRequestModifier` Protocol

The `modified(for:reportModified:)` method is now asynchronous. Reimplement it if used:

```swift
// Old
extension YourType: AsyncImageDownloadRequestModifier {
    func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void) {
        reportModified(request)
    }
}
```

```swift
// New
extension YourType: AsyncImageDownloadRequestModifier {
    func modified(for request: URLRequest) async -> URLRequest? {
        return request
    }
}
```

#### `AuthenticationChallengeResponsible` Protocol

The following methods have been updated to async versions:

- `downloader(_:didReceive:completionHandler:)`
- `downloader(_:task:didReceive:completionHandler:)`

Ensure your implementation is current:

```swift
// Old
extension YourType: AuthenticationChallengeResponsible {
    func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
    {
        generateCredential { credential in
            completionHandler(.useCredential, credential)
        }
    }

    func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
    {
        generateCredential { credential in
            completionHandler(.useCredential, credential)
        }
    }
}
```

```swift
// New
extension YourType: AuthenticationChallengeResponsible {
    func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        let credential = await generateCredential()
        return (.useCredential, credential)
    }

    func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        let credential = await generateCredential()
        return (.useCredential, credential)
    }
}
```

### Type Adjustments

#### `ColorElement`

`Filter.ColorElement` has evolved from a typealias for a tuple to a `struct`. Instantiate `ColorElement` using its initializer:

```swift
let brightness, contrast, saturation, inputEV: CGFloat

// Old
let colorElement: Filter.ColorElement = (brightness, contrast, saturation, inputEV)

// New
let colorElement = Filter.ColorElement(brightness, contrast, saturation, inputEV)
```

#### `DownloadTask`

`DownloadTask` has been redefined as a `class` instead of a `struct`.

For `ImageDownloader.download` methods that previously returned optional `DownloadTask`` values, now return non-optional values instead. For example:

```swift
// old
open func downloadImage(
  with url: URL,
  options: KingfisherParsedOptionsInfo,
  completionHandler: (@Sendable (Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil
) -> DownloadTask?

// new
open func downloadImage(
  with url: URL,
  options: KingfisherParsedOptionsInfo,
  completionHandler: (@Sendable (Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil
) -> DownloadTask
```

To check if a download task is valid, instead of checking `nil`, use `isInitialized` instead:

```swift
// old
let downloadTask: DownloadTask? = downloader.downloadImage(with: url, options: options)

func doSomethingWithTask() {
    if let task = downloadTask {
        // Do something with the task, for example, cancel it
    }
}

// new
let downloadTask: DownloadTask = downloader.downloadImage(with: url, options: options)

func doSomethingWithTask() {
    if downloadTask.isInitialized {
        // Do something with the task, for example, cancel it
    }
}
```

##### Cancel Token of DownloadTask

In the current implementation, the cancel token of a `DownloadTask` is an optional value, meaning it does not exist until the download task has actually started. 

Typically, there is no need to interact directly with the cancel token; you can simply invoke the `cancel()` method to terminate an ongoing download task.
