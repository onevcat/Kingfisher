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
    
    /// Cache the downloaded image to Apple Watch app. By default the downloaded image will not be cached in the watch. By containing this in options could improve performance when setting the same URL later. However, the cache size in the Watch is limited. So you will want to cache often used images only.
    public static var CacheInWatch: KingfisherOptions { return KingfisherOptions(1 << 4) }
    
    /// If set it will dispatch callbacks asynchronously to the global queue DISPATCH_QUEUE_PRIORITY_DEFAULT. Otherwise it will use the queue defined at KingfisherManager.DefaultOptions.queue
    public static var BackgroundCallback: KingfisherOptions { return KingfisherOptions(1 << 5) }
    
    /// Decode the image using the same scale as the main screen. Otherwise it will use the same scale as defined on the KingfisherManager.DefaultOptions.scale.
    public static var ScreenScale: KingfisherOptions { return KingfisherOptions(1 << 6) }
}
