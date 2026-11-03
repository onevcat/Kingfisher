//
//  ResponseCacheControlPolicy.swift
//  Kingfisher
//
//  Created by feather2222 on 2026/11/03.
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
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

/// The caching policy declared by an HTTP response's `Cache-Control` header.
///
/// Only the directives Kingfisher can act on are represented: `no-store` and `max-age`.
enum ResponseCacheControlPolicy: Sendable, Equatable {
    /// The response must not be stored anywhere, in either the memory or the disk cache.
    case noStore
    /// The response may be cached for at most the given number of seconds.
    case maxAge(TimeInterval)
}

extension HTTPURLResponse {
    /// Parses the `Cache-Control` header of the response into a ``ResponseCacheControlPolicy``.
    ///
    /// `no-store` takes precedence over `max-age` when both are present. Responses without a
    /// `Cache-Control` header, or with only directives Kingfisher does not handle (such as
    /// `no-cache` or `private`), return `nil` and the regular cache settings apply. Malformed
    /// directives and non-integer `max-age` values (such as `1.5` or `inf`) are ignored.
    var cacheControlPolicy: ResponseCacheControlPolicy? {
        guard let header = value(forHTTPHeaderField: "Cache-Control") else {
            return nil
        }
        var maxAge: TimeInterval?
        for directive in splitCacheControlDirectives(header) {
            let parts = directive.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let name = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            switch name {
            case "no-store":
                return .noStore
            case "max-age":
                // delta-seconds is a non-negative integer per RFC 9111. Reject anything else
                // (`1.5`, `inf`, negative or missing values) instead of silently accepting it.
                guard parts.count == 2 else {
                    continue
                }
                let rawValue = parts[1]
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                guard let seconds = Int(rawValue), seconds >= 0 else {
                    continue
                }
                maxAge = TimeInterval(seconds)
            default:
                continue
            }
        }
        return maxAge.map { .maxAge($0) }
    }

    /// The value of the response's `Age` header in seconds, or `0` when absent or malformed.
    ///
    /// CDN and proxy responses often arrive with a large `Age`; a `max-age` budget should count
    /// the time the response already spent in downstream caches, not just the time it sits in
    /// this one.
    var responseAge: TimeInterval {
        guard let rawValue = value(forHTTPHeaderField: "Age")?
            .trimmingCharacters(in: .whitespaces),
              let seconds = Int(rawValue), seconds > 0
        else {
            return 0
        }
        return TimeInterval(seconds)
    }
}

/// Splits a `Cache-Control` header value into directives on commas, honoring quoted strings.
///
/// A comma inside a quoted-string (including backslash-escaped quotes, per RFC 9110) does not
/// separate directives, so an extension like `x-note="a,b"` never shadows a real directive.
private func splitCacheControlDirectives(_ header: String) -> [Substring] {
    var directives: [Substring] = []
    var segmentStart = header.startIndex
    var index = segmentStart
    var inQuotes = false
    var escaped = false
    while index < header.endIndex {
        let character = header[index]
        if escaped {
            escaped = false
        } else if inQuotes && character == "\\" {
            escaped = true
        } else if character == "\"" {
            inQuotes.toggle()
        } else if character == ",", !inQuotes {
            directives.append(header[segmentStart..<index])
            segmentStart = header.index(after: index)
        }
        index = header.index(after: index)
    }
    directives.append(header[segmentStart...])
    return directives
}
