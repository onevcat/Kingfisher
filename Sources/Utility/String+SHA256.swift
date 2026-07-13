//
//  String+SHA256.swift
//  Kingfisher
//
//  Created by kaimaschke on 28.07.23.
//
//  Copyright (c) 2023 Wei Wang <onevcat@gmail.com>
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
import CryptoKit
import CommonCrypto

extension String: KingfisherCompatibleValue { }
extension KingfisherWrapper where Base == String {
    var sha256: String {
        guard let data = base.data(using: .utf8) else { return base }
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, macCatalyst 13.0, *) {
            let hashed = SHA256.hash(data: data)
            return hashed.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes { bytes in
                _ = CC_SHA256(bytes.baseAddress, UInt32(data.count), &digest)
            }
            return digest.makeIterator().compactMap { String(format: "%02x", $0) }.joined()
        }
    }

    var ext: String? {
        guard let firstSeg = base.split(separator: "@").first else {
            return nil
        }

        var ext = ""
        if let index = firstSeg.lastIndex(of: ".") {
            let extRange = firstSeg.index(index, offsetBy: 1)..<firstSeg.endIndex
            ext = String(firstSeg[extRange])
        }

        // The result is appended to the hashed cache file name as a file extension
        // (e.g. `<hash>.png`). The text after the last `.` is not guaranteed to be a valid
        // extension: when the original URL path itself contains `@` (such as
        // `.../57373197@300-1720981878.jpg`), the `@`-split above yields `.../57373197`, and
        // this extracts `net/57373197`. A value containing a path separator turns the cache
        // file name into a nonexistent sub-directory path, so the file can never be written
        // and disk caching silently breaks. See https://github.com/onevcat/Kingfisher/issues/2301
        //
        // Only accept a plausible file extension: non-empty, short, and alphanumeric.
        guard !ext.isEmpty,
              ext.count <= 20,
              ext.allSatisfy({ $0.isLetter || $0.isNumber })
        else {
            return nil
        }
        return ext
    }
}
