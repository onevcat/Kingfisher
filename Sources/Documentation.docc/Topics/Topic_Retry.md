# Retry the Image Loading

Managing the retry mechanism when an error happens during loading.

## Overview

Use ``KingfisherOptionsInfoItem/retryStrategy(_:)`` along with a `RetryStrategy` implementation to easily set up a
retry mechanism for image setting operations when an error occurs.

This combination allows you to define retry logic, including the number of retries and the conditions under which a
retry should be attempted, ensuring a more resilient image loading process.


## Built-in Retry Strategies

Kingfisher provides two built-in retry strategies to handle different scenarios:

### DelayRetryStrategy

``DelayRetryStrategy`` is a time-based retry strategy that allows you to specify the `maxRetryCount` and
the `retryInterval` to easily configure retry behavior. This setup enables quick implementation of a retry mechanism:

```swift
let retry = DelayRetryStrategy(
  maxRetryCount: 5,
  retryInterval: .seconds(3)
)
imageView.kf.setImage(with: url, options: [.retryStrategy(retry)])
```

This implements a retry mechanism that attempts to reload the target URL up to 5 times, with a fixed 3-second interval
between each try.

#### Other retry interval

For a more dynamic approach, you can also select `.accumulated(3)` as the retry interval results in progressively
increasing delays between attempts, specifically `3 -> 6 -> 9 -> 12 -> 15` seconds for each subsequent retry.
Additionally, for ultimate flexibility, `.custom` allows you to define a unique pattern for retry intervals, tailoring
the retry logic to your specific requirements.

### NetworkRetryStrategy

``NetworkRetryStrategy`` is a network-aware retry strategy that handles network connectivity issues.
It only retries when the network becomes available after a disconnection, this is suitable to handle unstable user connection.

```swift
// Basic usage - retries immediately when network becomes available
let networkRetry = NetworkRetryStrategy()
imageView.kf.setImage(with: url, options: [.retryStrategy(networkRetry)])

// With timeout - stops waiting after specified duration
let networkRetryWithTimeout = NetworkRetryStrategy(timeoutInterval: 30.0)
imageView.kf.setImage(with: url, options: [.retryStrategy(networkRetryWithTimeout)])
```

## Custom Retry Strategies

If you need more control for the retry strategy, implement your own type that conforms to ``RetryStrategy``.
