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
import CommonCrypto

extension String: KingfisherCompatible { }
extension Kingfisher where Base == String {
    var md5: String {
        guard let data = base.data(using: .utf8) else {
            return base
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { bytes in
            return CC_MD5(bytes, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
