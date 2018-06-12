//
//  Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/9/14.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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
import ImageIO

#if os(macOS)
    import AppKit
    public typealias Image = NSImage
    public typealias View = NSView
    public typealias Color = NSColor
    public typealias ImageView = NSImageView
    public typealias Button = NSButton
#else
    import UIKit
    public typealias Image = UIImage
    public typealias Color = UIColor
    #if !os(watchOS)
    public typealias ImageView = UIImageView
    public typealias View = UIView
    public typealias Button = UIButton
    #else
    import WatchKit
    #endif
#endif

public final class Kingfisher<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/**
 A type that has Kingfisher extensions.
 */
public protocol KingfisherCompatible {
    associatedtype CompatibleType
    var kf: CompatibleType { get }
}

public extension KingfisherCompatible {
    public var kf: Kingfisher<Self> {
        return Kingfisher(self)
    }
}

extension Image: KingfisherCompatible { }
#if !os(watchOS)
extension ImageView: KingfisherCompatible { }
extension Button: KingfisherCompatible { }
#else
extension WKInterfaceImage: KingfisherCompatible { }
#endif
