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

    func increasedRetryCount() -> RetryContext {
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

public struct SimpleRetryStrategy: RetryStrategy {
    public let maxRetryCount: Int
    public let retryInterval: TimeInterval

    public init(maxRetryCount: Int, retryInterval: TimeInterval = 3.0) {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + self.retryInterval) {
            retryHandler(.retry(userInfo: nil))
        }
    }
}
