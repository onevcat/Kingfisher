//
//  Source.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/17.
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


/// Represents an image source setting for Kingfisher methods.
///
/// A ``Source`` value indicates the way in which the target image can be retrieved and cached.
///
/// - `network`: The target image should be retrieved from the network remotely. The associated ``Resource``
///            value defines detailed information like image URL and cache key.
/// - `provider`: The target image should be provided in a data format. Normally, it can be an image
///             from local storage or in any other encoding format (like Base64).
///
public enum Source: Sendable {

    /// Represents the source task identifier when setting an image to a view with extension methods.
    public enum Identifier {

        /// The underlying value type of source identifier.
        public typealias Value = UInt
        
        @MainActor static private(set) var current: Value = 0
        
        // Not thread safe. Expected to be always called on the main thread.
        @MainActor static func next() -> Value {
            current += 1
            return current
        }
    }

    // MARK: Member Cases

    /// The target image should be fetched from the network remotely. The associated `Resource`
    /// value defines detailed information such as the image URL and cache key.
    case network(any Resource)

    /// The target image should be provided in a data format, typically as an image
    /// from local storage or in any other encoding format, such as Base64.
    case provider(any ImageDataProvider)

    // MARK: Getting Properties

    /// The cache key defined for this source value.
    public var cacheKey: String {
        switch self {
        case .network(let resource): return resource.cacheKey
        case .provider(let provider): return provider.cacheKey
        }
    }

    /// The URL defined for this source value.
    ///
    /// For a ``Source/network(_:)`` source, it is the ``Resource/downloadURL`` of associated ``Resource`` instance.
    /// For a ``Source/provider(_:)`` value, it is always `nil`.
    public var url: URL? {
        switch self {
        case .network(let resource): return resource.downloadURL
        case .provider(let provider): return provider.contentURL
        }
    }
}

extension Source: Hashable {
    public static func == (lhs: Source, rhs: Source) -> Bool {
        switch (lhs, rhs) {
        case (.network(let r1), .network(let r2)):
            return r1.cacheKey == r2.cacheKey && r1.downloadURL == r2.downloadURL
        case (.provider(let p1), .provider(let p2)):
            return p1.cacheKey == p2.cacheKey && p1.contentURL == p2.contentURL
        case (.provider(_), .network(_)):
            return false
        case (.network(_), .provider(_)):
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .network(let r):
            hasher.combine(r.cacheKey)
            hasher.combine(r.downloadURL)
        case .provider(let p):
            hasher.combine(p.cacheKey)
            hasher.combine(p.contentURL)
        }
    }
}

extension Source {
    var asResource: (any Resource)? {
        guard case .network(let resource) = self else {
            return nil
        }
        return resource
    }
}
