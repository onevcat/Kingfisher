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
public typealias KFCrossPlatformImage       = NSImage
public typealias KFCrossPlatformView        = NSView
public typealias KFCrossPlatformColor       = NSColor
public typealias KFCrossPlatformImageView   = NSImageView
public typealias KFCrossPlatformButton      = NSButton

// `NSImage` is not yet Sendable. We have to assume it sendable to resolve warnings in Kingfisher.
#if compiler(>=6)
extension KFCrossPlatformImage: @retroactive @unchecked Sendable { }
#else
extension KFCrossPlatformImage: @unchecked Sendable { }
#endif // compiler(>=6)
#else // os(macOS)
import UIKit
public typealias KFCrossPlatformImage       = UIImage
public typealias KFCrossPlatformColor       = UIColor
#if !os(watchOS)
public typealias KFCrossPlatformImageView   = UIImageView
public typealias KFCrossPlatformView        = UIView
public typealias KFCrossPlatformButton      = UIButton
#if canImport(TVUIKit)
import TVUIKit
#endif // canImport(TVUIKit)
#if canImport(CarPlay) && !targetEnvironment(macCatalyst)
import CarPlay
#endif // canImport(CarPlay) && !targetEnvironment(macCatalyst)
#else // !os(watchOS)
import WatchKit
#endif // !os(watchOS)
#endif // os(macOS)

/// Wrapper for Kingfisher compatible types. This type provides an extension point for
/// convenience methods in Kingfisher.
public struct KingfisherWrapper<Base>: @unchecked Sendable {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible with Kingfisher. You can use ``kf`` property to get a
/// value in the namespace of Kingfisher.
///
/// In Kingfisher, most of related classes that contains an image (such as `UIImage`, `UIButton`, `NSImageView` and
/// more) conform to this protocol, and provides the helper methods for setting an image easily. You can access the `kf`
/// property and call its `setImage` method with a certain URL:
///
/// ```swift
/// let imageView: UIImageView
/// let url = URL(string: "https://example.com/image.jpg")
/// imageView.kf.setImage(with: url)
/// ```
///
/// For more about basic usage of Kingfisher, check the <doc:CommonTasks> documentation.
public protocol KingfisherCompatible: AnyObject { }

/// Represents a value type that is compatible with Kingfisher. You can use ``kf`` property to get a
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

extension KFCrossPlatformImage      : KingfisherCompatible { }
#if !os(watchOS)
extension KFCrossPlatformImageView  : KingfisherCompatible { }
extension KFCrossPlatformButton     : KingfisherCompatible { }
extension NSTextAttachment          : KingfisherCompatible { }
#else
extension WKInterfaceImage          : KingfisherCompatible { }
#endif

#if canImport(PhotosUI) && !os(watchOS)
import PhotosUI
extension PHLivePhotoView           : KingfisherCompatible { }
#endif


#if os(tvOS) && canImport(TVUIKit)
@available(tvOS 12.0, *)
extension TVMonogramView            : KingfisherCompatible { }
#endif

#if canImport(CarPlay) && !targetEnvironment(macCatalyst)
@available(iOS 14.0, *)
extension CPListItem                : KingfisherCompatible { }
#endif
