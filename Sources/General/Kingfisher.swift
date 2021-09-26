//
//  Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/9/14.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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
public typealias KFCrossPlatformImage = NSImage
public typealias KFCrossPlatformView = NSView
public typealias KFCrossPlatformColor = NSColor
public typealias KFCrossPlatformImageView = NSImageView
public typealias KFCrossPlatformButton = NSButton
#else
import UIKit
public typealias KFCrossPlatformImage = UIImage
public typealias KFCrossPlatformColor = UIColor
#if !os(watchOS)
public typealias KFCrossPlatformImageView = UIImageView
public typealias KFCrossPlatformView = UIView
public typealias KFCrossPlatformButton = UIButton
#if canImport(TVUIKit)
import TVUIKit
#endif
#if canImport(CarPlay)
import CarPlay
#endif
#else
import WatchKit
#endif
#endif

/// Wrapper for Kingfisher compatible types. This type provides an extension point for
/// convenience methods in Kingfisher.
public struct KingfisherWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible with Kingfisher. You can use `kf` property to get a
/// value in the namespace of Kingfisher.
public protocol KingfisherCompatible: AnyObject { }

/// Represents a value type that is compatible with Kingfisher. You can use `kf` property to get a
/// value in the namespace of Kingfisher.
public protocol KingfisherCompatibleValue {}

extension KingfisherCompatible {
    /// Gets a namespace holder for Kingfisher compatible types.
    public var kf: KingfisherWrapper<Self> {
        get { return KingfisherWrapper(self) }
        set { }
    }
}

extension KingfisherCompatibleValue {
    /// Gets a namespace holder for Kingfisher compatible types.
    public var kf: KingfisherWrapper<Self> {
        get { return KingfisherWrapper(self) }
        set { }
    }
}

extension KFCrossPlatformImage: KingfisherCompatible { }
#if !os(watchOS)
extension KFCrossPlatformImageView: KingfisherCompatible { }
extension KFCrossPlatformButton: KingfisherCompatible { }
extension NSTextAttachment: KingfisherCompatible { }
#else
extension WKInterfaceImage: KingfisherCompatible { }
#endif

#if os(tvOS) && canImport(TVUIKit)
@available(tvOS 12.0, *)
extension TVMonogramView: KingfisherCompatible { }
#endif

#if canImport(CarPlay)
@available(iOS 14.0, *)
extension CPListItem: KingfisherCompatible { }
#endif
