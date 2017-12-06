//
//  String+MD5.swift
//  Kingfisher
//
// To date, adding CommonCrypto to a Swift framework is problematic. See:
// http://stackoverflow.com/questions/25248598/importing-commoncrypto-in-a-swift-framework
// We're using a subset and modified version of CryptoSwift as an alternative.
// The following is an altered source version that only includes MD5. The original software can be found at:
// https://github.com/krzyzanowskim/CryptoSwift
// This is the original copyright notice:

/*
Copyright (C) 2014 Marcin Krzyżanowski <marcin.krzyzanowski@gmail.com>
This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
- The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
- Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
- This notice may not be removed or altered from any source or binary distribution.
*/

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
