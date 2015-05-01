//
//  KingfisherOptions.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

/**
*  Options to control Kingfisher behaviors.
*/
public struct KingfisherOptions : RawOptionSetType {
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    
    /**
    Init an option
    
    :param: value Raw value of the option.
    
    :returns: An option represets input value.
    */
    public init(rawValue value: UInt) { self.value = value }
    
    /**
    Init a None option
    
    :param: nilLiteral Void.
    
    :returns: An option represents None.
    */
    public init(nilLiteral: ()) { self.value = 0 }
    
    /// An option represents None.
    public static var allZeros: KingfisherOptions { return self(0) }
    
    /// Raw value of the option.
    public var rawValue: UInt { return self.value }
    
    static func fromMask(raw: UInt) -> KingfisherOptions { return self(raw) }

    /// None options. Kingfisher will keep its default behavior.
    public static var None: KingfisherOptions { return self(0) }
    
    /// Download in a low priority.
    public static var LowPriority: KingfisherOptions { return KingfisherOptions(1 << 0) }
    
    /// Try to send request to server first. If response code is 304 (Not Modified), use the cached image. Otherwise, download the image and cache it again.
    public static var ForceRefresh: KingfisherOptions { return KingfisherOptions(1 << 1) }
    
    /// Only cache downloaded image to memory, not cache in disk.
    public static var CacheMemoryOnly: KingfisherOptions { return KingfisherOptions(1 << 2) }
    
    /// Decode the image in background thread before using.
    public static var BackgroundDecode: KingfisherOptions { return KingfisherOptions(1 << 3) }
}
