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

#if swift(>=4.3)
/// Result type already built-in
#else
/// A value that represents either a success or failure, capturing associated
/// values in both cases.
public enum Result<Success, Failure> {
    /// A success, storing a `Value`.
    case success(Success)

    /// A failure, storing an `Error`.
    case failure(Failure)

    /// Evaluates the given transform closure when this `Result` instance is
    /// `.success`, passing the value as a parameter.
    ///
    /// Use the `map` method with a closure that returns a non-`Result` value.
    ///
    /// - Parameter transform: A closure that takes the successful value of the
    ///   instance.
    /// - Returns: A new `Result` instance with the result of the transform, if
    ///   it was applied.
    public func map<NewSuccess>(
        _ transform: (Success) -> NewSuccess
        ) -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(success):
            return .success(transform(success))
        case let .failure(failure):
            return .failure(failure)
        }
    }

    /// Evaluates the given transform closure when this `Result` instance is
    /// `.failure`, passing the error as a parameter.
    ///
    /// Use the `mapError` method with a closure that returns a non-`Result`
    /// value.
    ///
    /// - Parameter transform: A closure that takes the failure value of the
    ///   instance.
    /// - Returns: A new `Result` instance with the result of the transform, if
    ///   it was applied.
    public func mapError<NewFailure>(
        _ transform: (Failure) -> NewFailure
        ) -> Result<Success, NewFailure> {
        switch self {
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return .failure(transform(failure))
        }
    }

    /// Evaluates the given transform closure when this `Result` instance is
    /// `.success`, passing the value as a parameter and flattening the result.
    ///
    /// - Parameter transform: A closure that takes the successful value of the
    ///   instance.
    /// - Returns: A new `Result` instance, either from the transform or from
    ///   the previous error value.
    public func flatMap<NewSuccess>(
        _ transform: (Success) -> Result<NewSuccess, Failure>
        ) -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(success):
            return transform(success)
        case let .failure(failure):
            return .failure(failure)
        }
    }

    /// Evaluates the given transform closure when this `Result` instance is
    /// `.failure`, passing the error as a parameter and flattening the result.
    ///
    /// - Parameter transform: A closure that takes the error value of the
    ///   instance.
    /// - Returns: A new `Result` instance, either from the transform or from
    ///   the previous success value.
    public func flatMapError<NewFailure>(
        _ transform: (Failure) -> Result<Success, NewFailure>
        ) -> Result<Success, NewFailure> {
        switch self {
        case let .success(success):
            return .success(success)
        case let .failure(failure):
            return transform(failure)
        }
    }
}

extension Result where Failure: Error {
    /// Returns the success value as a throwing expression.
    ///
    /// Use this method to retrieve the value of this result if it represents a
    /// success, or to catch the value if it represents a failure.
    ///
    ///     let integerResult: Result<Int, Error> = .success(5)
    ///     do {
    ///         let value = try integerResult.get()
    ///         print("The value is \(value).")
    ///     } catch error {
    ///         print("Error retrieving the value: \(error)")
    ///     }
    ///     // Prints "The value is 5."
    ///
    /// - Returns: The success value, if the instance represents a success.
    /// - Throws: The failure value, if the instance represents a failure.
    public func get() throws -> Success {
        switch self {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }
}

extension Result where Failure == Swift.Error {
    /// Creates a new result by evaluating a throwing closure, capturing the
    /// returned value as a success, or any thrown error as a failure.
    ///
    /// - Parameter body: A throwing closure to evaluate.
    @_transparent
    public init(catching body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch {
            self = .failure(error)
        }
    }
}

extension Result : Equatable where Success : Equatable, Failure: Equatable { }

extension Result : Hashable where Success : Hashable, Failure : Hashable { }

extension Result : CustomDebugStringConvertible {
    public var debugDescription: String {
        var output = "Result."
        switch self {
        case let .success(value):
            output += "success("
            debugPrint(value, terminator: "", to: &output)
        case let .failure(error):
            output += "failure("
            debugPrint(error, terminator: "", to: &output)
        }
        output += ")"

        return output
    }
}
#endif

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
        onFailure: (Failure) -> Output) -> Output
    {
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
