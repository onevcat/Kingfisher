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
public struct KingfisherOptions : OptionSetType {
    public var rawValue: UInt = 0
    
    /**
    Init an option
    
    - parameter value: Raw value of the option.
    
    - returns: An option represets input value.
    */
    public init(rawValue value: UInt) { self.rawValue = value }
    
    /// An option represents None.
    public static var allZeros = KingfisherOptions(rawValue: 0)

    /// None options. Kingfisher will keep its default behavior.
    public static var None = KingfisherOptions(rawValue: 0)
    
    /// Download in a low priority.
    public static var LowPriority = KingfisherOptions(rawValue: 1 << 0)
    
    /// Try to send request to server first. If response code is 304 (Not Modified), use the cached image. Otherwise, download the image and cache it again.
    public static var ForceRefresh = KingfisherOptions(rawValue: 1 << 1)
    
    /// Only cache downloaded image to memory, not cache in disk.
    public static var CacheMemoryOnly = KingfisherOptions(rawValue: 1 << 2)
    
    /// Decode the image in background thread before using.
    public static var BackgroundDecode = KingfisherOptions(rawValue: 1 << 3)
    
    /// Cache the downloaded image to Apple Watch app. By default the downloaded image will not be cached in the watch. By containing this in options could improve performance when setting the same URL later. However, the cache size in the Watch is limited. So you will want to cache often used images only.
    public static var CacheInWatch = KingfisherOptions(rawValue: 1 << 4)
}
