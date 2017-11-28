//
//  ImageModifier.swift
//  Kingfisher
//
//  Created by Ethan Gill on 2017/11/28.
//
//  Copyright (c) 2017 Ethan Gill <ethan.gill@me.com>
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

/// An `ImageModifier` can be used to change properties on an Image in between
/// cache serialization and use of the image.
public protocol ImageModifier {
    /// Identifier of the modifier. It will be used to identify the modifier when
    /// modifying an image.
    ///
    /// - Note: Do not supply an empty string for a customized modifier, as the
    /// `DefaultImageModifier` uses this idenfifier. It is recommended to use a
    /// reverse domain name notation string of your own for the identifier.
    var identifier: String { get }

    /// Modify an input `Image`.
    ///
    /// - parameter image:   Image which will be modified by `self`
    /// - parameter options: Options when modifying the image.
    ///
    /// - returns: The modified image.
    ///
    /// - Note: The return value will be unmodified if modifying is not possible on
    ///         the current platform.
    /// - Note: Most modifiers support UIImage or NSImage, but not CGImage.
    func modify(image: Image, options: KingfisherOptionsInfo) -> Image?
}

typealias ModifierImp = ((Image, KingfisherOptionsInfo) -> Image?)

public extension ImageModifier {

    /// Append an `ImageModifier` to another. The identifier of the new `ImageModifier`
    /// will be "\(self.identifier)|>\(another.identifier)".
    ///
    /// - parameter another: An `ImageModifier` you want to append to `self`.
    ///
    /// - returns: The new `ImageModifier` will process the image in the order
    ///            of the two modifiers concatenated.
    public func append(another: ImageModifier) -> ImageModifier {
        let newIdentifier = identifier.appending("|>\(another.identifier)")
        return GeneralModifier(identifier: newIdentifier) {
            image, options in
            if let image = self.modify(image: image, options: options) {
                return another.modify(image: image, options: options)
            } else {
                return nil
            }
        }
    }
}

func ==(left: ImageModifier, right: ImageModifier) -> Bool {
    return left.identifier == right.identifier
}

func !=(left: ImageModifier, right: ImageModifier) -> Bool {
    return !(left == right)
}

fileprivate struct GeneralModifier: ImageModifier {
    let identifier: String
    let m: ModifierImp
    func modify(image: Image, options: KingfisherOptionsInfo) -> Image? {
        return m(image, options)
    }
}

/// The default modifier.
/// Does nothing and returns the image it was given
public struct DefaultImageModifier: ImageModifier {

    /// A default `DefaultImageModifier` which can be used everywhere.
    public static let `default` = DefaultImageModifier()

    /// Identifier of the modifier.
    /// - Note: See documentation of `ImageModifier` protocol for more.
    public let identifier = ""

    /// Initialize a `DefaultImageModifier`
    public init() {}

    /// Modify an input `Image`.
    ///
    /// - parameter image:   Image which will be modified by `self`
    /// - parameter options: Options when modifying the image.
    ///
    /// - returns: The modified image.
    ///
    /// - Note: See documentation of `ImageModifier` protocol for more.
    public func modify(image: Image, options: KingfisherOptionsInfo) -> Image? {
        return image
    }
}

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

/// Modifier for setting the rendering mode of images.
/// Only UI-based images are supported; if a non-UI image is passed in, the modifier
/// will do nothing.
public struct RenderingModeImageModifier: ImageModifier {

    /// Identifier of the modifier.
    /// - Note: See documentation of `ImageModifier` protocol for more.
    public let identifier: String

    /// The rendering mode to apply to the image.
    public let renderingMode: UIImageRenderingMode

    /// Initialize a `RenderingModeImageModifier`
    ///
    /// - parameter renderingMode: The rendering mode to apply to the image.
    ///                            Default is .automatic
    public init(renderingMode: UIImageRenderingMode = .automatic) {
        self.renderingMode = renderingMode
        self.identifier = "com.onevcat.Kingfisher.RenderingModeImageModifier(\(renderingMode))"
    }

    /// Modify an input `Image`.
    ///
    /// - parameter image:   Image which will be modified by `self`
    /// - parameter options: Options when modifying the image.
    ///
    /// - returns: The modified image.
    ///
    /// - Note: See documentation of `ImageModifier` protocol for more.
    public func modify(image: Image, options: KingfisherOptionsInfo) -> Image? {
        return image.withRenderingMode(renderingMode)
    }
}

public struct FlipsForRightToLeftLayoutDirectionImageModifier: ImageModifier {
    /// Identifier of the modifier.
    /// - Note: See documentation of `ImageModifier` protocol for more.
    public let identifier: String

    /// Initialize a `FlipsForRightToLeftLayoutDirectionImageModifier`
    ///
    /// - Note: On versions of iOS lower than 9.0, the image will be returned
    ///         unmodified.
    public init() {
        self.identifier = "com.onevcat.Kingfisher.FlipsForRightToLeftLayoutDirectionImageModifier"
    }

    /// Modify an input `Image`.
    ///
    /// - parameter image:   Image which will be modified by `self`
    /// - parameter options: Options when modifying the image.
    ///
    /// - returns: The modified image.
    ///
    /// - Note: See documentation of `ImageModifier` protocol for more.
    public func modify(image: Image, options: KingfisherOptionsInfo) -> Image? {
        if #available(iOS 9.0, *) {
            return image.imageFlippedForRightToLeftLayoutDirection()
        } else {
            return image
        }
    }
}

#endif
