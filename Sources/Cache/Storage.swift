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

/// Constants for some time intervals
struct TimeConstants {
    static let secondsInOneMinute = 60
    static let minutesInOneHour = 60
    static let hoursInOneDay = 24
    static let secondsInOneDay = 86_400
}

/// Represents the expiration strategy used in storage.
///
/// - never: The item never expires.
/// - seconds: The item expires after a time duration of given seconds from now.
/// - days: The item expires after a time duration of given days from now.
/// - date: The item expires after a given date.
public enum StorageExpiration {
    /// The item never expires.
    case never
    /// The item expires after a time duration of given seconds from now.
    case seconds(TimeInterval)
    /// The item expires after a time duration of given days from now.
    case days(Int)
    /// The item expires after a given date.
    case date(Date)
    /// Indicates the item is already expired. Use this to skip cache.
    case expired

    func estimatedExpirationSince(_ date: Date) -> Date {
        switch self {
        case .never: return .distantFuture
        case .seconds(let seconds):
            return date.addingTimeInterval(seconds)
        case .days(let days):
            let duration: TimeInterval = TimeInterval(TimeConstants.secondsInOneDay) * TimeInterval(days)
            return date.addingTimeInterval(duration)
        case .date(let ref):
            return ref
        case .expired:
            return .distantPast
        }
    }
    
    var estimatedExpirationSinceNow: Date {
        return estimatedExpirationSince(Date())
    }
    
    var isExpired: Bool {
        return timeInterval <= 0
    }

    var timeInterval: TimeInterval {
        switch self {
        case .never: return .infinity
        case .seconds(let seconds): return seconds
        case .days(let days): return TimeInterval(TimeConstants.secondsInOneDay) * TimeInterval(days)
        case .date(let ref): return ref.timeIntervalSinceNow
        case .expired: return -(.infinity)
        }
    }
}

/// Represents the expiration extending strategy used in storage to after access.
///
/// - none: The item expires after the original time, without extending after access.
/// - cacheTime: The item expiration extends by the original cache time after each access.
/// - expirationTime: The item expiration extends by the provided time after each access.
public enum ExpirationExtending {
    /// The item expires after the original time, without extending after access.
    case none
    /// The item expiration extends by the original cache time after each access.
    case cacheTime
    /// The item expiration extends by the provided time after each access.
    case expirationTime(_ expiration: StorageExpiration)
}

/// Represents types which cost in memory can be calculated.
public protocol CacheCostCalculable {
    var cacheCost: Int { get }
}

/// Represents types which can be converted to and from data.
public protocol DataTransformable {
    func toData() throws -> Data
    static func fromData(_ data: Data) throws -> Self
    static var empty: Self { get }
}
