# Controlling the Retry Mechanism when Error Happens

Use ``KingfisherOptionsInfoItem/retryStrategy(_:)`` and ``RetryStrategy`` to implement a simple retry mechanism 
when setting an image and an error happens.

## Basic Retry Strategy

Use ``KingfisherOptionsInfoItem/retryStrategy(_:)`` and ``DelayRetryStrategy`` to implement a simple retry mechanism 
when setting an image:

```swift
let retry = DelayRetryStrategy(maxRetryCount: 5, retryInterval: .seconds(3))
imageView.kf.setImage(with: url, options: [.retryStrategy(retry)])
```

This will retry the target URL for at most 5 times, with a constant 3 seconds as the interval between each attempt.
You can also choose an `.accumulated(3)` as the retry interval, which gives you an accumulated `3 -> 6 -> 9 -> 12 -> 15` 
retry interval. Or you can even define your own interval pattern by `.custom`.

If you need more control for the retry strategy, implement your own type conforming to the [`RetryStrategy` protocol](https://swiftpackageindex.com/onevcat/Kingfisher/master/documentation/kingfisher/retrystrategy/).
