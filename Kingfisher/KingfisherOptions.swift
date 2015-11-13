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
public struct KingfisherOptions: OptionSetType {

    public let rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// None options. Kingfisher will keep its default behavior.
    public static let None = KingfisherOptions(rawValue: 0)
    
    /// Download in a low priority.
    public static let LowPriority = KingfisherOptions(rawValue: 1 << 0)
    
    /// Try to send request to server first. If response code is 304 (Not Modified), use the cached image. Otherwise, download the image and cache it again.
    public static var ForceRefresh = KingfisherOptions(rawValue: 1 << 1)
    
    /// Only cache downloaded image to memory, not cache in disk.
    public static var CacheMemoryOnly = KingfisherOptions(rawValue: 1 << 2)
    
    /// Decode the image in background thread before using.
    public static var BackgroundDecode = KingfisherOptions(rawValue: 1 << 3)

    /// If set it will dispatch callbacks asynchronously to the global queue DISPATCH_QUEUE_PRIORITY_DEFAULT. Otherwise it will use the queue defined at KingfisherManager.DefaultOptions.queue
    public static var BackgroundCallback = KingfisherOptions(rawValue: 1 << 4)
    
    /// Decode the image using the same scale as the main screen. Otherwise it will use the same scale as defined on the KingfisherManager.DefaultOptions.scale.
    public static var ScreenScale = KingfisherOptions(rawValue: 1 << 5)
}
