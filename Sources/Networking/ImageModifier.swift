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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// An ``ImageModifier`` can be used to change properties on an image between cache serialization and the actual use of
/// the image.
///
/// The ``ImageModifier/modify(_:)`` method will be called after the image is retrieved from its source and before it
/// is returned to the caller. This modified image is expected to be used only for rendering purposes; any changes
/// applied by the ``ImageModifier`` will not be serialized or cached.
public protocol ImageModifier: Sendable {
    
    /// Modify an input `Image`.
    ///
    /// - Parameter image: The image which will be modified by `self`.
    ///
    /// - Returns: The modified image.
    ///
    /// > Important: The return value will be unmodified if modification is not possible on the current platform.
    func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage
}

/// A wrapper that simplifies the creation of an ``ImageModifier``.
///  
/// This type conforms to ``ImageModifier`` and encapsulates an image modification block. If the `block` throws an
/// error, the original image will be used.
public struct AnyImageModifier: ImageModifier {

    /// A block that modifies images, or returns the original image if modification cannot be performed, along with an 
    /// error.
    let block: @Sendable (KFCrossPlatformImage) throws -> KFCrossPlatformImage

    /// Creates an ``AnyImageModifier`` with a given `modify` block.
    /// - Parameter modify: A block which is used to modify the input image.
    public init(modify: @escaping @Sendable (KFCrossPlatformImage) throws -> KFCrossPlatformImage) {
        block = modify
    }

    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return (try? block(image)) ?? image
    }
}

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit

/// Modifier for setting the rendering mode of images.
public struct RenderingModeImageModifier: ImageModifier {

    /// The rendering mode to apply to the image.
    public let renderingMode: UIImage.RenderingMode

    /// Creates a ``RenderingModeImageModifier``.
    ///
    /// - Parameter renderingMode: The rendering mode to apply to the image. The default is `.automatic`.
    public init(renderingMode: UIImage.RenderingMode = .automatic) {
        self.renderingMode = renderingMode
    }

    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return image.withRenderingMode(renderingMode)
    }
}

/// Modifier for setting the `flipsForRightToLeftLayoutDirection` property of images.
public struct FlipsForRightToLeftLayoutDirectionImageModifier: ImageModifier {

    /// Creates a ``FlipsForRightToLeftLayoutDirectionImageModifier``.
    public init() {}

    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return image.imageFlippedForRightToLeftLayoutDirection()
    }
}

/// Modifier for setting the `alignmentRectInsets` property of images.
public struct AlignmentRectInsetsImageModifier: ImageModifier {

    /// The alignment insets to apply to the image.
    public let alignmentInsets: UIEdgeInsets
    
    /// Creates a ``AlignmentRectInsetsImageModifier``.
    /// - Parameter alignmentInsets: The alignment insets to apply to the image.
    public init(alignmentInsets: UIEdgeInsets) {
        self.alignmentInsets = alignmentInsets
    }

    public func modify(_ image: KFCrossPlatformImage) -> KFCrossPlatformImage {
        return image.withAlignmentRectInsets(alignmentInsets)
    }
}
#endif
