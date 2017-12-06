//
//  String+MD5.swift
//  Kingfisher
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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
//
// adding CommonCrypto to a Swift framework See:
// http://stackoverflow.com/questions/25248598/importing-commoncrypto-in-a-swift-framework


import Foundation
import CCommonCrypto

public struct StringProxy {
    fileprivate let base: String
    init(proxy: String) {
        base = proxy
    }
}

extension String: KingfisherCompatible {
    public typealias CompatibleType = StringProxy
    public var kf: CompatibleType {
        return StringProxy(proxy: self)
    }
}

extension StringProxy {
    var md5: String {
        guard let cStr = base.cString(using: .utf8) else {
            return base
        }
        let bytesLength = CUnsignedInt(base.lengthOfBytes(using: .utf8))
        let md5DigestLenth = Int(CC_MD5_DIGEST_LENGTH)
        let md5StringPointer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: md5DigestLenth)
        defer {
            md5StringPointer.deallocate(capacity: md5DigestLenth)
        }
        CC_MD5(cStr, bytesLength, md5StringPointer)
        var md5String = ""
        for i in 0 ..< md5DigestLenth {
            md5String = md5String.appendingFormat("%02x", md5StringPointer[i])
        }
        return md5String
    }
}
