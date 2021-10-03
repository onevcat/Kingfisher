//
//  Result.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/22.
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

// These helper methods are not public since we do not want them to be exposed or cause any conflicting.
// However, they are just wrapper of `ResultUtil` static methods.
extension Result where Failure: Error {

    /// Evaluates the given transform closures to create a single output value.
    ///
    /// - Parameters:
    ///   - onSuccess: A closure that transforms the success value.
    ///   - onFailure: A closure that transforms the error value.
    /// - Returns: A single `Output` value.
    func match<Output>(
        onSuccess: (Success) -> Output,
        onFailure: (Failure) -> Output) -> Output {
        switch self {
        case let .success(value):
            return onSuccess(value)
        case let .failure(error):
            return onFailure(error)
        }
    }

    func matchSuccess<Output>(with folder: (Success?) -> Output) -> Output {
        return match(
            onSuccess: { value in return folder(value) },
            onFailure: { _ in return folder(nil) }
        )
    }

    func matchFailure<Output>(with folder: (Error?) -> Output) -> Output {
        return match(
            onSuccess: { _ in return folder(nil) },
            onFailure: { error in return folder(error) }
        )
    }

    func match<Output>(with folder: (Success?, Error?) -> Output) -> Output {
        return match(
            onSuccess: { return folder($0, nil) },
            onFailure: { return folder(nil, $0) }
        )
    }
}
