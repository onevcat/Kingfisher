//
//  ImageModifier.swift
//  Kingfisher
//
//  Created by Ethan Gill on 2017/11/28.
//
//  Copyright (c) 2019 Ethan Gill <ethan.gill@me.com>
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

/// An `ImageModifier` can be used to change properties on an image in between
/// cache serialization and use of the image. The modified returned image will be
/// only used for current rendering purpose, the serialization data will not contain
/// the changes applied by the `ImageModifier`.
public protocol ImageModifier {
    /// Modify an input `Image`.
    ///
    /// - parameter image:   Image which will be modified by `self`
    ///
    /// - returns: The modified image.
    ///
    /// - Note: The return value will be unmodified if modifying is not possible on
    ///         the current platform.
    /// - Note: Most modifiers support UIImage or NSImage, but not CGImage.
    func modify(_ image: Image) -> Image
}

/// A wrapper for creating an `ImageModifier` easier.
/// This type conforms to `ImageModifier` and wraps an image modify block.
/// If the `block` throws an error, the original image will be used.
public struct AnyImageModifier: ImageModifier {

    /// A block which modifies images, or returns the original image
    /// if modification cannot be performed with an error.
    let block: (Image) throws -> Image

    /// Creates an `AnyImageModifier` with a given `modify` block.
    public init(modify: @escaping (Image) throws -> Image) {
        block = modify
    }

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: Image) -> Image {
        return (try? block(image)) ?? image
    }
}

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

/// Modifier for setting the rendering mode of images.
public struct RenderingModeImageModifier: ImageModifier {

    /// The rendering mode to apply to the image.
    public let renderingMode: UIImage.RenderingMode

    /// Creates a `RenderingModeImageModifier`.
    ///
    /// - Parameter renderingMode: The rendering mode to apply to the image. Default is `.automatic`.
    public init(renderingMode: UIImage.RenderingMode = .automatic) {
        self.renderingMode = renderingMode
    }

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: Image) -> Image {
        return image.withRenderingMode(renderingMode)
    }
}

/// Modifier for setting the `flipsForRightToLeftLayoutDirection` property of images.
public struct FlipsForRightToLeftLayoutDirectionImageModifier: ImageModifier {

    /// Creates a `FlipsForRightToLeftLayoutDirectionImageModifier`.
    public init() {}

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: Image) -> Image {
        return image.imageFlippedForRightToLeftLayoutDirection()
    }
}

/// Modifier for setting the `alignmentRectInsets` property of images.
public struct AlignmentRectInsetsImageModifier: ImageModifier {

    /// The alignment insets to apply to the image
    public let alignmentInsets: UIEdgeInsets

    /// Creates an `AlignmentRectInsetsImageModifier`.
    public init(alignmentInsets: UIEdgeInsets) {
        self.alignmentInsets = alignmentInsets
    }

    /// Modify an input `Image`. See `ImageModifier` protocol for more.
    public func modify(_ image: Image) -> Image {
        return image.withAlignmentRectInsets(alignmentInsets)
    }
}
#endif
