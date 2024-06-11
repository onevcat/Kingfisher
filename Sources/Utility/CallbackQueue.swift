//
//  CallbackQueue.swift
//  Kingfisher
//
//  Created by onevcat on 2018/10/15.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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

public typealias ExecutionQueue = CallbackQueue

/// Represents the behavior of the callback queue selection when a closure is dispatched.
public enum CallbackQueue: Sendable {
    
    /// Dispatches the closure to `DispatchQueue.main` with an `async` behavior.
    case mainAsync
    
    /// Dispatches the closure to `DispatchQueue.main` with an `async` behavior if the current queue is not `.main`.
    ///  Otherwise, it calls the closure immediately on the current main queue.
    case mainCurrentOrAsync
    
    /// Does not change the calling queue for the closure.
    case untouch
    
    /// Dispatches the closure to a specified `DispatchQueue`.
    case dispatch(DispatchQueue)
    
    /// Executes the `block` in a dispatch queue defined by `self`.
    /// - Parameter block: The block needs to be executed.
    public func execute(_ block: @Sendable @escaping () -> Void) {
        switch self {
        case .mainAsync:
            CallbackQueueMain.async { block() }
        case .mainCurrentOrAsync:
            CallbackQueueMain.currentOrAsync { block() }
        case .untouch:
            block()
        case .dispatch(let queue):
            queue.async { block() }
        }
    }

    var queue: DispatchQueue {
        switch self {
        case .mainAsync: return .main
        case .mainCurrentOrAsync: return .main
        case .untouch: return OperationQueue.current?.underlyingQueue ?? .main
        case .dispatch(let queue): return queue
        }
    }
}

enum CallbackQueueMain {
    static func currentOrAsync(_ block: @MainActor @Sendable @escaping () -> Void) {
        if Thread.isMainThread {
            MainActor.runUnsafely { block() }
        } else {
            DispatchQueue.main.async { block() }
        }
    }
    
    static func async(_ block: @MainActor @Sendable @escaping () -> Void) {
        DispatchQueue.main.async { block() }
    }
}

extension MainActor {
    @_unavailableFromAsync
    static func runUnsafely<T: Sendable>(_ body: @MainActor () throws -> T) rethrows -> T {
#if swift(>=5.10)
        return try MainActor.assumeIsolated(body)
#else
        dispatchPrecondition(condition: .onQueue(.main))
        return try withoutActuallyEscaping(body) { fn in
            try unsafeBitCast(fn, to: (() throws -> T).self)()
        }
#endif
    }
}
