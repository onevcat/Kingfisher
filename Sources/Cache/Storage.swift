//
//  Storage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
//
//  Copyright (c) 2018年 Wei Wang <onevcat@gmail.com>
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

public enum StorageExpiration {
    case never
    case seconds(TimeInterval)
    case days(Int)
    case date(Date)

    func dateSince(_ date: Date) -> Date {
        switch self {
        case .never: return .distantFuture
        case .seconds(let seconds): return date.addingTimeInterval(seconds)
        case .days(let days): return date.addingTimeInterval(TimeInterval(60 * 60 * 24 * days))
        case .date(let ref): return ref
        }
    }
}

protocol Storage {
    associatedtype ValueType
    associatedtype KeyType
    func store(
        value: ValueType,
        forKey key: KeyType,
        expiration: StorageExpiration?) throws
    func value(forKey key: KeyType) throws -> ValueType?
    func remove(forKey key: String) throws
    func removeAll() throws
}

class StorageObject<T> {
    let value: T
    let expiration: StorageExpiration

    private(set) var estimatedExpiration: Date

    init(_ value: T, expiration: StorageExpiration) {
        self.value = value
        self.expiration = expiration

        self.estimatedExpiration = expiration.dateSince(Date())
    }

    func extendExpiration() {
        self.estimatedExpiration = expiration.dateSince(Date())
    }
}

public protocol CacheCostCalculatable {
    var cost: Int { get }
}

public protocol DataTransformable {
    func toData() throws -> Data
    static func fromData(_ data: Data) throws -> Self
}
