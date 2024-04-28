//
//  Storage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
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

/// Constants for certain time intervals.
struct TimeConstants {
    // Seconds in a day, a.k.a 86,400s, roughly.
    static let secondsInOneDay = 86_400
}

/// Represents the expiration strategy utilized in storage.
public enum StorageExpiration: Sendable {
    
    /// The item never expires.
    case never
    
    /// The item expires after a duration of the provided number of seconds from now.
    case seconds(TimeInterval)
    
    /// The item expires after a duration of the provided number of days from now.
    case days(Int)
    
    /// The item expires after a specified date.
    case date(Date)
    
    /// Indicates that the item has already expired.
    ///
    /// Use this to bypass the cache.
    case expired

    
    func estimatedExpirationSince(_ date: Date) -> Date {
        switch self {
        case .never: 
            return .distantFuture
        case .seconds(let seconds):
            return date.addingTimeInterval(seconds)
        case .days(let days):
            let duration: TimeInterval = TimeInterval(TimeConstants.secondsInOneDay * days)
            return date.addingTimeInterval(duration)
        case .date(let ref):
            return ref
        case .expired:
            return .distantPast
        }
    }
    
    var estimatedExpirationSinceNow: Date {
        estimatedExpirationSince(Date())
    }
    
    var isExpired: Bool {
        timeInterval <= 0
    }

    var timeInterval: TimeInterval {
        switch self {
        case .never: return .infinity
        case .seconds(let seconds): return seconds
        case .days(let days): return TimeInterval(TimeConstants.secondsInOneDay * days)
        case .date(let ref): return ref.timeIntervalSinceNow
        case .expired: return -(.infinity)
        }
    }
}

/// Represents the expiration extension strategy used in storage after access.
public enum ExpirationExtending: Sendable {
    /// The item expires after the original time, without extension after access.
    case none
    /// The item expiration extends to the original cache time after each access.
    case cacheTime
    /// The item expiration extends by the provided time after each access.
    case expirationTime(_ expiration: StorageExpiration)
}

/// Represents types for which the memory cost can be calculated.
public protocol CacheCostCalculable {
    var cacheCost: Int { get }
}

/// Represents types that can be converted to and from data.
public protocol DataTransformable {
    
    /// Converts the current value to a `Data` representation.
    /// - Returns: The data object which can represent the value of the conforming type.
    /// - Throws: If any error happens during the conversion.
    func toData() throws -> Data
    
    /// Convert some data to the value.
    /// - Parameter data: The data object which should represent the conforming value.
    /// - Returns: The converted value of the conforming type.
    /// - Throws: If any error happens during the conversion.
    static func fromData(_ data: Data) throws -> Self
    
    /// An empty object of `Self`.
    ///
    /// > In the cache, when the data is not actually loaded, this value will be returned as a placeholder.
    /// > This variable should be returned quickly without any heavy operation inside.
    static var empty: Self { get }
}
