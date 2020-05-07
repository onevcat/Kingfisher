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

public class RetryContext {

    public let source: Source

    public let error: KingfisherError
    public var retriedCount: Int

    public internal(set) var userInfo: Any? = nil

    init(source: Source, error: KingfisherError) {
        self.source = source
        self.error = error
        self.retriedCount = 0
    }

    @discardableResult
    func increaseRetryCount() -> RetryContext {
        retriedCount += 1
        return self
    }
}

public enum RetryDecision {
    case retry(userInfo: Any?)
    case stop
}

public protocol RetryStrategy {
    func retry(context: RetryContext, retryHandler: @escaping (RetryDecision) -> Void)
}

public struct DelayRetryStrategy: RetryStrategy {

    public enum Interval {
        case seconds(TimeInterval)
        case accumulated(TimeInterval)
        case custom(block: (_ retriedCount: Int) -> TimeInterval)

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

    public let maxRetryCount: Int
    public let retryInterval: Interval

    public init(maxRetryCount: Int, retryInterval: Interval = .seconds(3)) {
        self.maxRetryCount = maxRetryCount
        self.retryInterval = retryInterval
    }

    public func retry(context: RetryContext, retryHandler: @escaping (RetryDecision) -> Void) {
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
