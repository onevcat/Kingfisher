//
//  ImageProcessor.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/08/26.
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
import CoreGraphics

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#else
import UIKit
#endif

/// Represents an item which could be processed by an `ImageProcessor`.
public enum ImageProcessItem: Sendable {
    
    /// Input image. The processor should provide a method to apply
    /// processing to this `image` and return the resulting image.
    case image(KFCrossPlatformImage)
    
    /// Input data. The processor should provide a method to apply
    /// processing to this `data` and return the resulting image.
    case data(Data)
}

/// An `ImageProcessor` is used to convert downloaded data into an image.
public protocol ImageProcessor: Sendable {
    
    /// Identifier for the processor.
    ///
    /// This identifier is used to distinguish the processor when caching and retrieving an image. Ensure that
    /// processors with the same properties or functionality share the same identifier so that processed images can be
    /// retrieved with the correct key.
    ///
    /// > Important: Avoid using an empty string for a custom processor, as it is already reserved by the
    /// > `DefaultImageProcessor`. It is recommended to use a reverse domain name notation string for your identifier.
    var identifier: String { get }

    /// Process the input `ImageProcessItem` using this processor.
    ///
    /// - Parameters:
    ///   - item: The input item to be processed by `self`.
    ///   - options: The parsed options for processing the item.
    /// - Returns: The processed image.
    ///
    /// You should return `nil` if processing fails when converting an input item to an image. If the processing
    /// caller receives `nil`, an error will be reported, and the processing flow will stop. If processing flow is not
    /// critical for your use case, and the input item is already an image (`.image` case), you can also choose to
    /// return the input image itself to continue the processing pipeline.
    ///
    /// > Important: Most processors only support CG-based images. The watchOS is not supported for processors
    /// > containing a filter, and the input image will be returned directly on watchOS.
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
}

extension ImageProcessor {
    
    /// Append an `ImageProcessor` to another. The identifier of the new `ImageProcessor` will 
    /// be `"\(self.identifier)|>\(another.identifier)"`.
    ///
    /// - Parameter another: An `ImageProcessor` to be appended to `self`.
    /// - Returns: The new `ImageProcessor` that will process the image in the order of the two processors concatenated.
    public func append(another: any ImageProcessor) -> any ImageProcessor {
        let newIdentifier = identifier.appending("|>\(another.identifier)")
        return GeneralProcessor(identifier: newIdentifier) {
            item, options in
            if let image = self.process(item: item, options: options) {
                return another.process(item: .image(image), options: options)
            } else {
                return nil
            }
        }
    }
}

func ==(left: any ImageProcessor, right: any ImageProcessor) -> Bool {
    return left.identifier == right.identifier
}

func !=(left: any ImageProcessor, right: any ImageProcessor) -> Bool {
    return !(left == right)
}

typealias ProcessorImp = (@Sendable (ImageProcessItem, KingfisherParsedOptionsInfo) -> KFCrossPlatformImage?)
struct GeneralProcessor: ImageProcessor {
    let identifier: String
    let p: ProcessorImp
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return p(item, options)
    }
}

/// The default processor. It converts the input data into a valid image.
///
/// Supported image formats include .PNG, .JPEG, and .GIF. If an image item is provided as the
/// ``ImageProcessItem/image(_:)`` case, ``DefaultImageProcessor`` will leave it unchanged and return the associated
/// image.
public struct DefaultImageProcessor: ImageProcessor {
    
    /// A default instance of ``DefaultImageProcessor`` can be used across the framework.
    public static let `default` = DefaultImageProcessor()
    
    public let identifier = ""
    
    /// Create a ``DefaultImageProcessor``.
    ///
    /// Use ``DefaultImageProcessor/default`` to obtain an instance if you have no specific reason to create your own
    /// ``DefaultImageProcessor``.
    public init() {}
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
        case .data(let data):
            return KingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
        }
    }
}

/// Represents the rect corner setting when processing a round corner image.
public struct RectCorner: OptionSet, Sendable {
    
    /// Raw value for the corner radius.
    public let rawValue: Int
    
    /// Represents the top left corner.
    public static let topLeft = RectCorner(rawValue: 1 << 0)
    
    /// Represents the top right corner.
    public static let topRight = RectCorner(rawValue: 1 << 1)
    
    /// Represents the bottom left corner.
    public static let bottomLeft = RectCorner(rawValue: 1 << 2)
    
    /// Represents the bottom right corner.
    public static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    /// Represents all corners.
    public static let all: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    
    /// Create a `RectCorner` option set with a specified value.
    ///
    /// - Parameter rawValue: The value representing a specific corner option.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    var cornerIdentifier: String {
        if self == .all {
            return ""
        }
        return "_corner(\(rawValue))"
    }
}

#if !os(macOS)
/// Processor for applying a blend mode to images. 
///
/// Supported for CG-based images only.
public struct BlendImageProcessor: ImageProcessor {

    public let identifier: String

    /// The blend mode used to blend the input image.
    public let blendMode: CGBlendMode

    /// The alpha value used when blending the image.
    public let alpha: CGFloat

    /// The background color of the output image.
    ///
    /// If `nil`, the background will remain transparent.
    public let backgroundColor: KFCrossPlatformColor?

    /// Create a `BlendImageProcessor`.
    ///
    /// - Parameters:
    ///   - blendMode: The blend mode to be used for blending the input image.
    ///   - alpha: The alpha value to be used when blending the image, ranging from 0.0 (completely transparent) to 
    ///   1.0 (completely solid). Default is 1.0.
    ///   - backgroundColor: The background color to apply to the output image. Default is `nil`.
    public init(blendMode: CGBlendMode, alpha: CGFloat = 1.0, backgroundColor: KFCrossPlatformColor? = nil) {
        self.blendMode = blendMode
        self.alpha = alpha
        self.backgroundColor = backgroundColor
        var identifier = "com.onevcat.Kingfisher.BlendImageProcessor(\(blendMode.rawValue),\(alpha))"
        if let color = backgroundColor {
            identifier.append("_\(color.rgbaDescription)")
        }
        self.identifier = identifier
    }

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.image(withBlendMode: blendMode, alpha: alpha, backgroundColor: backgroundColor)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}
#endif

#if os(macOS)
/// Processor for applying a compositing operation to images.
///
/// Supported for CG-based images on macOS.
public struct CompositingImageProcessor: ImageProcessor {

    public let identifier: String

    /// The compositing operation applied to the input image.
    public let compositingOperation: NSCompositingOperation

    /// The alpha value used when compositing the image.
    public let alpha: CGFloat

    /// The background color of the output image. If `nil`, the background will remain transparent.
    public let backgroundColor: KFCrossPlatformColor?

    /// Create a `CompositingImageProcessor`.
    ///
    /// - Parameters:
    ///   - compositingOperation: The compositing operation to be applied to the input image.
    ///   - alpha: The alpha value to be used when compositing the image, ranging from 0.0 (completely transparent) to 
    ///   1.0 (completely solid). Default is 1.0.
    ///   - backgroundColor: The background color to apply to the output image. Default is `nil`.
    public init(compositingOperation: NSCompositingOperation,
                alpha: CGFloat = 1.0,
                backgroundColor: KFCrossPlatformColor? = nil)
    {
        self.compositingOperation = compositingOperation
        self.alpha = alpha
        self.backgroundColor = backgroundColor
        var identifier = "com.onevcat.Kingfisher.CompositingImageProcessor(\(compositingOperation.rawValue),\(alpha))"
        if let color = backgroundColor {
            identifier.append("_\(color.rgbaDescription)")
        }
        self.identifier = identifier
    }

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.image(
                            withCompositingOperation: compositingOperation,
                            alpha: alpha,
                            backgroundColor: backgroundColor)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}
#endif

/// Represents a radius specified in a ``RoundCornerImageProcessor``.
public enum Radius: Sendable {
    
    /// The radius should be calculated as a fraction of the image width. Typically, the associated value should be
    /// between 0 and 0.5, where 0 represents no radius, and 0.5 represents using half of the image width.
    case widthFraction(CGFloat)
    
    /// The radius should be calculated as a fraction of the image height. Typically, the associated value should be
    /// between 0 and 0.5, where 0 represents no radius, and 0.5 represents using half of the image height.
    case heightFraction(CGFloat)
    
    /// Use a fixed point value as the round corner radius.
    case point(CGFloat)

    var radiusIdentifier: String {
        switch self {
        case .widthFraction(let f):
            return "w_frac_\(f)"
        case .heightFraction(let f):
            return "h_frac_\(f)"
        case .point(let p):
            return p.description
        }
    }
    
    public func compute(with size: CGSize) -> CGFloat {
        let cornerRadius: CGFloat
        switch self {
        case .point(let point):
            cornerRadius = point
        case .widthFraction(let widthFraction):
            cornerRadius = size.width * widthFraction
        case .heightFraction(let heightFraction):
            cornerRadius = size.height * heightFraction
        }
        return cornerRadius
    }
}

/// Processor for creating round corner images. 
///
/// Supported for CG-based images on macOS. If a non-CG image is passed in, the processor will have no effect.
///
/// > Tip: The input image will be rendered with round corner pixels removed. If the image itself does not contain an
/// > alpha channel (for example, a JPEG image), the processed image will contain an alpha channel in memory for
/// > correct rendering. However, when cached to disk, Kingfisher defaults to preserving the original image format.
/// > This means the alpha channel will be removed for these images. If you load the processed image from the cache 
/// > again, you will lose the transparent corners.
/// >
/// > You can use ``FormatIndicatedCacheSerializer/png`` to force Kingfisher to serialize the image to PNG format in this
/// > case.

public struct RoundCornerImageProcessor: ImageProcessor {

    public let identifier: String

    /// The radius to be applied during processing. 
    ///
    /// Specify a specific point value with ``Radius/point(_:)``, or a fraction of the target image with
    /// ``Radius/widthFraction(_:)`` or ``Radius/heightFraction(_:)``. For example, if you have a square image with
    /// equal width and height, `.widthFraction(0.5)` means using half of the width of the size to create a round image.
    public let radius: Radius
    
    /// The target corners to round.
    public let roundingCorners: RectCorner
    
    /// The target size for the output image. If `nil`, the image will retain its original size after processing.
    public let targetSize: CGSize?

    /// The background color for the output image. If `nil`, it will use a transparent background.
    public let backgroundColor: KFCrossPlatformColor?

    /// Create a ``RoundCornerImageProcessor`` with given parameters.
    ///
    /// - Parameters:
    ///   - cornerRadius: The corner radius in points to be applied during processing.
    ///   - targetSize: The target size for the output image. If `nil`, the image will retain its original size after 
    ///   processing. Default is `nil`.
    ///   - corners: The target corners to round. Default is ``RectCorner/all``.
    ///   - backgroundColor: The background color to apply to the output image. Default is `nil`.
    ///
    /// This initializer accepts a specific point value for `cornerRadius`. If you don't know the image size but still 
    /// want to apply a full round corner (making the final image round), or specify the corner radius as a fraction of
    /// one dimension of the target image, use the ``init(radius:targetSize:roundingCorners:backgroundColor:)``
    /// instead.
    public init(
        cornerRadius: CGFloat,
        targetSize: CGSize? = nil,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    )
    {
        let radius = Radius.point(cornerRadius)
        self.init(radius: radius, targetSize: targetSize, roundingCorners: corners, backgroundColor: backgroundColor)
    }

    /// Create a `RoundCornerImageProcessor`.
    ///
    /// - Parameters:
    ///   - radius: The radius to be applied during processing.
    ///   - targetSize: The target size for the output image. If `nil`, the image will retain its original size after 
    ///   processing. Default is `nil`.
    ///   - corners: The target corners to round. Default is ``RectCorner/all``.
    ///   - backgroundColor: The background color to apply to the output image. Default is `nil`.
    public init(
        radius: Radius,
        targetSize: CGSize? = nil,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    )
    {
        self.radius = radius
        self.targetSize = targetSize
        self.roundingCorners = corners
        self.backgroundColor = backgroundColor

        self.identifier = {
            var identifier = ""

            if let size = targetSize {
                identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor" +
                             "(\(radius.radiusIdentifier)_\(size)\(corners.cornerIdentifier))"
            } else {
                identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor" +
                             "(\(radius.radiusIdentifier)\(corners.cornerIdentifier))"
            }
            if let backgroundColor = backgroundColor {
                identifier += "_\(backgroundColor)"
            }

            return identifier
        }()
    }

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            let size = targetSize ?? image.kf.size
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.image(
                            withRadius: radius,
                            fit: size,
                            roundingCorners: roundingCorners,
                            backgroundColor: backgroundColor)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Represents a border to be added to the image.
///
/// Typically used with ``BorderImageProcessor``, which adds the border to the image.
public struct Border: Sendable {
    
    /// The color of the border to create.
    public var color: KFCrossPlatformColor
    
    /// The line width of the border to create.
    public var lineWidth: CGFloat
    
    /// The radius to be applied during processing.
    ///
    /// Specify a specific point value with ``Radius/point(_:)``, or a fraction of the target image with
    /// ``Radius/widthFraction(_:)`` or ``Radius/heightFraction(_:)``. For example, if you have a square image with
    /// equal width and height, `.widthFraction(0.5)` means using half of the width of the size to create a round image.
    public var radius: Radius
    
    /// The target corners which will be applied rounding.
    public var roundingCorners: RectCorner
    
    /// Creates a border.
    /// - Parameters:
    ///   - color: The color will be used to render the border.
    ///   - lineWidth: The line width of the border.
    ///   - radius: The radius of the border corner.
    ///   - roundingCorners: The target corners type.
    public init(
        color: KFCrossPlatformColor = .black,
        lineWidth: CGFloat = 4,
        radius: Radius = .point(0),
        roundingCorners: RectCorner = .all
    ) {
        self.color = color
        self.lineWidth = lineWidth
        self.radius = radius
        self.roundingCorners = roundingCorners
    }
    
    var identifier: String {
        "\(color.rgbaDescription)_\(lineWidth)_\(radius.radiusIdentifier)_\(roundingCorners.cornerIdentifier)"
    }
}

/// Processor for creating bordered images.
public struct BorderImageProcessor: ImageProcessor {
    
    public var identifier: String { "com.onevcat.Kingfisher.BorderImageProcessor(\(border)" }
    
    /// The border to be added to the image.
    public let border: Border
    
    /// Create a `BorderImageProcessor` with a given `Border`.
    ///
    /// - Parameter border: The border to be added to the image.
    public init(border: Border) {
        self.border = border
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.addingBorder(border)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Represents how a size of content adjusts itself to fit a target size.
public enum ContentMode: Sendable {
    /// Does not scale the content.
    case none
    /// Scales the content to fit the size of the view while maintaining the aspect ratio.
    case aspectFit
    /// Scales the content to fill the size of the view.
    case aspectFill
}

/// Processor for resizing images.
///
/// If you need to resize an image represented by data to a smaller size, use ``DownsamplingImageProcessor`` instead,
/// which is more efficient and uses less memory.
public struct ResizingImageProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// The reference size for the resizing operation in points.
    public let referenceSize: CGSize
    
    /// The target content mode of the output image.
    public let targetContentMode: ContentMode
    
    /// Create a ``ResizingImageProcessor``.
    ///
    /// - Parameters:
    ///   - referenceSize: The reference size for the resizing operation in points.
    ///   - mode: The target content mode of the output image.
    ///
    /// The instance of ``ResizingImageProcessor`` will follow the `mode` argument and attempt to resize the input
    /// images to fit or fill the `referenceSize`. This means if you are using a `mode` besides `.none`, you may get an
    /// image with a size that is not the same as the `referenceSize`.
    ///
    /// For example, with an input image size of {100, 200}, `referenceSize` of {100, 100}, and `mode` of `.aspectFit`,
    /// you will get an output image with a size of {50, 100} that "fits" the `referenceSize`.
    ///
    /// > If you need an output image to be exactly a specified size, append or use a ``CroppingImageProcessor``.
    public init(referenceSize: CGSize, mode: ContentMode = .none) {
        self.referenceSize = referenceSize
        self.targetContentMode = mode
        
        if mode == .none {
            self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(referenceSize))"
        } else {
            self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(referenceSize), \(mode))"
        }
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.resize(to: referenceSize, for: targetContentMode)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Processor for adding a blur effect to images. 
///
/// Uses `Accelerate.framework` under the hood for better performance. Applies a simulated Gaussian blur with the
/// specified blur radius.
public struct BlurImageProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// The blur radius for the simulated Gaussian blur.
    public let blurRadius: CGFloat

    /// Create a `BlurImageProcessor`.
    ///
    /// - Parameter blurRadius: The blur radius for the simulated Gaussian blur.
    public init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
        self.identifier = "com.onevcat.Kingfisher.BlurImageProcessor(\(blurRadius))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            let radius = blurRadius * options.scaleFactor
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.blurred(withRadius: radius)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Processor for adding an overlay to images.
///
/// > Only CG-based images are supported.
public struct OverlayImageProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// The overlay color used to overlay the input image.
    public let overlay: KFCrossPlatformColor
    
    /// The fraction used when overlaying the color to the image.
    public let fraction: CGFloat
    
    /// Create an ``OverlayImageProcessor``.
    ///
    /// - Parameters:
    ///   - overlay: The overlay color used to overlay the input image.
    ///   - fraction: The fraction used when overlaying the color to the image.
    ///               Ranges from 0.0 to 1.0. 0.0 means a solid color, and 1.0 means a transparent overlay.
    public init(overlay: KFCrossPlatformColor, fraction: CGFloat = 0.5) {
        self.overlay = overlay
        self.fraction = fraction
        self.identifier = "com.onevcat.Kingfisher.OverlayImageProcessor(\(overlay.rgbaDescription)_\(fraction))"
    }

    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.overlaying(with: overlay, fraction: fraction)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Processor for tinting images with color.
///
/// > Only CG-based images are supported.
///
/// > Important: On watchOS, there is no tint support and the original image will be returned.
public struct TintImageProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// The tint color used to tint the input image.
    public let tint: KFCrossPlatformColor
    
    /// Create a ``TintImageProcessor``.
    ///
    /// - Parameter tint: The tint color used to tint the input image.
    public init(tint: KFCrossPlatformColor) {
        self.tint = tint
        self.identifier = "com.onevcat.Kingfisher.TintImageProcessor(\(tint.rgbaDescription))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.tinted(with: tint)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Processor for applying color control to images.
///
/// > Only CG-based images are supported.
///
/// > Important: On watchOS, there is no color control support and the original image will be returned.
public struct ColorControlsProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// The brightness change applied to the image.
    public let brightness: CGFloat
    
    /// The contrast change applied to the image.
    public let contrast: CGFloat
    
    /// The saturation change applied to the image.
    public let saturation: CGFloat
    
    /// The EV (F-stops brighter or darker) change applied to the image.
    public let inputEV: CGFloat
    
    /// Create a ``ColorControlsProcessor``.
    ///
    /// - Parameters:
    ///   - brightness: The brightness change applied to the image.
    ///   - contrast: The contrast change applied to the image.
    ///   - saturation: The saturation change applied to the image.
    ///   - inputEV: The EV (F-stops brighter or darker) change applied to the image.
    public init(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.inputEV = inputEV
        self.identifier = "com.onevcat.Kingfisher.ColorControlsProcessor(\(brightness)_\(contrast)_\(saturation)_\(inputEV))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Processor for applying black and white effect to images. Only CG-based images are supported.
///
/// > Only CG-based images are supported.
///
/// > Important: On watchOS, there is no color control support and the original image will be returned.
public struct BlackWhiteProcessor: ImageProcessor {
    
    public let identifier = "com.onevcat.Kingfisher.BlackWhiteProcessor"
    
    /// Creates a ``BlackWhiteProcessor``
    public init() {}
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return ColorControlsProcessor(brightness: 0.0, contrast: 1.0, saturation: 0.0, inputEV: 0.7)
            .process(item: item, options: options)
    }
}

/// Processor for cropping an image.
public struct CroppingImageProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// The target size of the output image.
    public let size: CGSize
    
    /// Anchor point from which the output size should be calculate.
    ///
    /// The anchor point is consisted by two values between 0.0 and 1.0.
    /// It indicates a related point in current image.
    ///
    /// See ``CroppingImageProcessor/init(size:anchor:)`` for more.
    public let anchor: CGPoint
    
    /// Create a ``CroppingImageProcessor``.
    ///
    /// - Parameters:
    ///   - size: The target size of the output image.
    ///   - anchor: The anchor point from which the size should be calculated. Default is `CGPoint(x: 0.5, y: 0.5)`,
    ///             which represents the center of the input image.
    ///
    /// The anchor point is composed of two values between 0.0 and 1.0. It indicates a relative point in the current
    /// image, e.g:
    /// - (0.0, 0.0) for the top-left corner
    /// - (0.5, 0.5) for the center
    /// - (1.0, 1.0) for the bottom-right corner
    ///
    /// The ``CroppingImageProcessor/size`` property will be used along with ``CroppingImageProcessor/anchor`` to
    /// calculate a target rectangle in the image size.
    ///
    /// > The target size will be automatically calculated with a reasonable behavior. For example, when you have an
    /// > image size of `CGSize(width: 100, height: 100)` and a target size of `CGSize(width: 20, height: 20)`:
    /// >
    /// > - with a (0.0, 0.0) anchor (top-left), the crop rect will be `{0, 0, 20, 20}`;
    /// > - with a (0.5, 0.5) anchor (center), it will be `{40, 40, 20, 20}`;
    /// > - while with a (1.0, 1.0) anchor (bottom-right), it will be `{80, 80, 20, 20}`.
    public init(size: CGSize, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        self.size = size
        self.anchor = anchor
        self.identifier = "com.onevcat.Kingfisher.CroppingImageProcessor(\(size)_\(anchor))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                        .kf.crop(to: size, anchorOn: anchor)
        case .data: return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// Processor for downsampling an image. 
///
/// Compared to ``ResizingImageProcessor``, this processor does not render the images to resize. Instead, it
/// downsamples the input data directly to an image. It is more efficient than ``ResizingImageProcessor``.
///
/// > Tip: It is preferable to use ``DownsamplingImageProcessor`` whenever possible rather than the
/// > ``ResizingImageProcessor``.
///
/// > Important: Only CG-based images are supported. Animated images (such as GIFs) are not supported.
public struct DownsamplingImageProcessor: ImageProcessor {
    
    /// The target size of the output image.
    ///
    /// It should be smaller than the size of the input image. If it is larger, the resulting image will be the same
    /// size as the input data without downsampling.
    public let size: CGSize
    
    public let identifier: String
    
    /// Creates a `DownsamplingImageProcessor`.
    ///
    /// - Parameters:
    ///     - size: The target size of the downsampling operation.
    ///
    /// > Important: The size should be smaller than the size of the input image. If it is larger, the resulting image
    /// will be the same size as the input data without downsampling.
    public init(size: CGSize) {
        self.size = size
        self.identifier = "com.onevcat.Kingfisher.DownsamplingImageProcessor(\(size))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            guard let data = image.kf.data(format: .unknown) else {
                return nil
            }
            return KingfisherWrapper.downsampledImage(data: data, to: size, scale: options.scaleFactor)
        case .data(let data):
            return KingfisherWrapper.downsampledImage(data: data, to: size, scale: options.scaleFactor)
        }
    }
}

// This is an internal processor to provide the same interface for Live Photos.
// It is not intended to be open and used from external.
struct LivePhotoImageProcessor: ImageProcessor {
    
    public static let `default` = LivePhotoImageProcessor()
    private init() { }
    
    public let identifier = "com.onevcat.Kingfisher.LivePhotoImageProcessor"
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data:
            return KFCrossPlatformImage()
        }
    }
}

infix operator |>: AdditionPrecedence

/// Concatenates two `ImageProcessor`s to create a new one, in which the `left` and `right` are combined in order to 
/// process the image.
///
/// - Parameters:
///     - left: The first processor.
///     - right: The second processor that follows the `left`.
/// - Returns: The new processor that processes the image or the image data in left-to-right order.
public func |>(left: any ImageProcessor, right: any ImageProcessor) -> any ImageProcessor {
    return left.append(another: right)
}

extension KFCrossPlatformColor {
    
    var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if os(macOS)
        (usingColorSpace(.extendedSRGB) ?? self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        
        return (r, g, b, a)
    }
    
    var rgbaDescription: String {
        let components = self.rgba
        return String(format: "(%.2f,%.2f,%.2f,%.2f)", components.r, components.g, components.b, components.a)
    }
}
