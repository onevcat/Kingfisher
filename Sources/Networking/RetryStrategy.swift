//
//  RetryStrategy.swift
//  Kingfisher
//
//  Created by onevcat on 2020/05/04.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// Represents a retry context that could be used to determine the current retry status.
///
/// The instance of this type can be shared between different retry attempts.
public class RetryContext: @unchecked Sendable {

    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.RetryContextPropertyQueue")

    /// The source from which the target image should be retrieved.
    public let source: Source

    /// The source from which the target image should be retrieved.
    public let error: KingfisherError

    private var _retriedCount: Int

    /// The number of retries attempted before the current retry happens.
    ///
    /// This value is `0` if the current retry is for the first time.
    public var retriedCount: Int {
        get { propertyQueue.sync { _retriedCount } }
        set { propertyQueue.sync { _retriedCount = newValue } }
    }

    private var _userInfo: Any? = nil

    /// A user-set value for passing any other information during the retry.
    ///
    /// If you choose to use ``RetryDecision/retry(userInfo:)`` as the retry decision for
    /// ``RetryStrategy/retry(context:retryHandler:)``, the associated value of ``RetryDecision/retry(userInfo:)`` will
    /// be delivered to you in the next retry.
    public internal(set) var userInfo: Any? {
        get { propertyQueue.sync { _userInfo } }
        set { propertyQueue.sync { _userInfo = newValue } }
    }

    init(source: Source, error: KingfisherError) {
        self.source = source
        self.error = error
        _retriedCount = 0
    }

    @discardableResult
    func increaseRetryCount() -> RetryContext {
        retriedCount += 1
        return self
    }
}

/// Represents the decision on the behavior for the current retry.
public enum RetryDecision {
    /// A retry should happen. The associated `userInfo` value will be passed to the next retry in the
    /// ``RetryContext`` parameter.
    case retry(userInfo: Any?)
    /// There should be no more retry attempts. The image retrieving process will fail with an error.
    case stop
}

/// Defines a retry strategy that can be applied to the ``KingfisherOptionsInfoItem/retryStrategy(_:)`` option.
public protocol RetryStrategy: Sendable {

    /// Kingfisher calls this method if an error occurs during the image retrieving process from ``KingfisherManager``.
    ///
    /// You implement this method to provide the necessary logic based on the `context` parameter. Then you need to call
    /// `retryHandler` to pass the retry decision back to Kingfisher.
    ///
    /// - Parameters:
    ///   - context: The retry context containing information of the current retry attempt.
    ///   - retryHandler: A block you need to call with a decision on whether the retry should happen or not.
    func retry(context: RetryContext, retryHandler: @escaping @Sendable (RetryDecision) -> Void)
}

/// A retry strategy that guides Kingfisher to perform retry operation with some delay.
///
/// When an error of ``KingfisherError/ResponseErrorReason`` happens, Kingfisher uses the retry strategy in its option
/// to retry. This strategy defines a specified maximum retry count and a certain interval mechanism.
public struct DelayRetryStrategy: RetryStrategy {

    /// Represents the interval mechanism used in a ``DelayRetryStrategy``.
    public enum Interval : Sendable{

        /// The next retry attempt should happen in a fixed number of seconds.
        ///
        /// For example, if the associated value is 3, the attempt happens 3 seconds after the previous decision is
        /// made.
        case seconds(TimeInterval)

        /// The next retry attempt should happen in an accumulated duration.
        ///
        /// For example, if the associated value is 3, the attempts happen with intervals of 3, 6, 9, 12, ... seconds.
        case accumulated(TimeInterval)

        /// Uses a block to determine the next interval.
        ///
        /// The current retry count is given as a parameter.
        case custom(block: @Sendable (_ retriedCount: Int) -> TimeInterval)

        func timeInterval(for retriedCount: Int) -> TimeInterval {
            let retryAfter: TimeInterval
            switch self {
            case .seconds(let interval):
                retryAfter = interval
            case .accumulated(let interval):
                retryAfter = Double(retriedCount + 1) * interval
            case .custom(let block):
                retryAfter = block(retriedCount)
            }
            return retryAfter
        }
    }

    /// The maximum number of retries allowed by the retry strategy.
    public let maxRetryCount: Int

    /// The interval between retry attempts in the retry strategy.
    public let retryInterval: Interval

    /// Creates a delayed retry strategy.
    ///
    /// - Parameters:
    ///   - maxRetryCount: The maximum number of retries allowed.
    ///   - retryInterval: The mechanism defining the interval between retry attempts.
    ///
    /// By default, ``Interval/seconds(_:)`` with an associated value `3` is used to establish a constant retry
    /// interval.
    public init(maxRetryCount: Int, retryInterval: Interval = .seconds(3)) {
        self.maxRetryCount = maxRetryCount
        self.retryInterval = retryInterval
    }

    public func retry(context: RetryContext, retryHandler: @escaping @Sendable (RetryDecision) -> Void) {
        // Retry count exceeded.
        guard context.retriedCount < maxRetryCount else {
            retryHandler(.stop)
            return
        }

        // User cancel the task. No retry.
        guard !context.error.isTaskCancelled else {
            retryHandler(.stop)
            return
        }

        // Only retry for a response error.
        guard case KingfisherError.responseError = context.error else {
            retryHandler(.stop)
            return
        }

        let interval = retryInterval.timeInterval(for: context.retriedCount)
        if interval == 0 {
            retryHandler(.retry(userInfo: nil))
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                retryHandler(.retry(userInfo: nil))
            }
        }
    }
}

/// A retry strategy that observes network state and retries on reconnect.
///
/// This strategy only retries when network becomes available after a disconnection.
/// It does not use any delay mechanisms - it retries immediately when network is restored.
///
/// The network monitor is created lazily only when this strategy is first used,
/// ensuring no unnecessary resource usage when the strategy is not in use.
public struct NetworkRetryStrategy: RetryStrategy {

    /// The timeout for waiting for network reconnection (in seconds).
    private let timeoutInterval: TimeInterval?

    /// The network monitoring service used to observe connectivity changes.
    private let networkMonitor: NetworkMonitoring

    /// Creates a network-aware retry strategy.
    ///
    /// - Parameters:
    ///   - timeoutInterval: The timeout for waiting for network reconnection. If nil, no timeout is applied. Defaults to 30 seconds.
    public init(timeoutInterval: TimeInterval? = 30) {
        self.init(
            timeoutInterval: timeoutInterval,
            networkMonitor: NetworkMonitor.default
        )
    }

    internal init(
        timeoutInterval: TimeInterval?,
        networkMonitor: NetworkMonitoring
    ) {
        self.timeoutInterval = timeoutInterval
        self.networkMonitor = networkMonitor
    }

    public func retry(context: RetryContext, retryHandler: @escaping @Sendable (RetryDecision) -> Void) {
        // Dispose of any previous disposable from userInfo
        if let previousObserver = context.userInfo as? NetworkObserver {
            previousObserver.cancel()
        }

        // User cancel the task. No retry.
        guard !context.error.isTaskCancelled else {
            retryHandler(.stop)
            return
        }

        // Only retry for a response error.
        guard case KingfisherError.responseError = context.error else {
            retryHandler(.stop)
            return
        }

        // Check if we have network connectivity
        if networkMonitor.isConnected {
            // Network is available, retry immediately
            retryHandler(.retry(userInfo: nil))
        } else {
            // Network is not available, wait for reconnection
            waitForReconnection(context: context, retryHandler: retryHandler)
        }
    }

    // MARK: - Private helpers

    private func waitForReconnection(
        context: RetryContext,
        retryHandler: @escaping @Sendable (RetryDecision) -> Void
    ) {
        let observer = networkMonitor.observeConnectivity(timeoutInterval: timeoutInterval) { [weak context] isConnected in
            if isConnected {
                // Connection is restored, retry immediately
                retryHandler(.retry(userInfo: context?.userInfo))
            } else {
                // Timeout reached or cancelled
                retryHandler(.stop)
            }
        }

        // Store the observer in userInfo so it can be cancelled if needed
        context.userInfo = observer
    }
}
