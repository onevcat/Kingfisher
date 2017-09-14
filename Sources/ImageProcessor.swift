//
//  ImageProcessor.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/08/26.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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

/// The item which could be processed by an `ImageProcessor`
///
/// - image: Input image
/// - data:  Input data
public enum ImageProcessItem {
    case image(Image)
    case data(Data)
}

/// An `ImageProcessor` would be used to convert some downloaded data to an image.
public protocol ImageProcessor {
    /// Identifier of the processor. It will be used to identify the processor when 
    /// caching and retriving an image. You might want to make sure that processors with
    /// same properties/functionality have the same identifiers, so correct processed images
    /// could be retrived with proper key.
    /// 
    /// - Note: Do not supply an empty string for a customized processor, which is already taken by
    /// the `DefaultImageProcessor`. It is recommended to use a reverse domain name notation
    /// string of your own for the identifier.
    var identifier: String { get }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: The return value will be `nil` if processing failed while converting data to image.
    ///         If input item is already an image and there is any errors in processing, the input 
    ///         image itself will be returned.
    /// - Note: Most processor only supports CG-based images. 
    ///         watchOS is not supported for processers containing filter, the input image will be returned directly on watchOS.
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image?
}

typealias ProcessorImp = ((ImageProcessItem, KingfisherOptionsInfo) -> Image?)

public extension ImageProcessor {
    
    /// Append an `ImageProcessor` to another. The identifier of the new `ImageProcessor` 
    /// will be "\(self.identifier)|>\(another.identifier)".
    ///
    /// - parameter another: An `ImageProcessor` you want to append to `self`.
    ///
    /// - returns: The new `ImageProcessor` will process the image in the order
    ///            of the two processors concatenated.
    public func append(another: ImageProcessor) -> ImageProcessor {
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

func ==(left: ImageProcessor, right: ImageProcessor) -> Bool {
    return left.identifier == right.identifier
}

func !=(left: ImageProcessor, right: ImageProcessor) -> Bool {
    return !(left == right)
}

fileprivate struct GeneralProcessor: ImageProcessor {
    let identifier: String
    let p: ProcessorImp
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return p(item, options)
    }
}

/// The default processor. It convert the input data to a valid image.
/// Images of .PNG, .JPEG and .GIF format are supported.
/// If an image is given, `DefaultImageProcessor` will do nothing on it and just return that image.
public struct DefaultImageProcessor: ImageProcessor {
    
    /// A default `DefaultImageProcessor` could be used across.
    public static let `default` = DefaultImageProcessor()
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier = ""
    
    /// Initialize a `DefaultImageProcessor`
    public init() {}
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    /// 
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return Kingfisher<Image>.image(
                data: data,
                scale: options.scaleFactor,
                preloadAllAnimationData: options.preloadAllAnimationData,
                onlyFirstFrame: options.onlyLoadFirstFrame)
        }
    }
}

public struct RectCorner: OptionSet {
    public let rawValue: Int
    public static let topLeft = RectCorner(rawValue: 1 << 0)
    public static let topRight = RectCorner(rawValue: 1 << 1)
    public static let bottomLeft = RectCorner(rawValue: 1 << 2)
    public static let bottomRight = RectCorner(rawValue: 1 << 3)
    public static let all: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    
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

/// Processor for making round corner images. Only CG-based images are supported in macOS, 
/// if a non-CG image passed in, the processor will do nothing.
public struct RoundCornerImageProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String

    /// Corner radius will be applied in processing.
    public let cornerRadius: CGFloat
    
    /// The target corners which will be applied rounding.
    public let roundingCorners: RectCorner
    
    /// Target size of output image should be. If `nil`, the image will keep its original size after processing.
    public let targetSize: CGSize?

    /// Background color of the output image. If `nil`, it will stay transparent.
    public let backgroundColor: Color?

    /// Initialize a `RoundCornerImageProcessor`
    ///
    /// - parameter cornerRadius:    Corner radius will be applied in processing.
    /// - parameter targetSize:      Target size of output image should be. If `nil`, 
    ///                              the image will keep its original size after processing.
    ///                              Default is `nil`.
    /// - parameter corners:         The target corners which will be applied rounding. Default is `.all`.
    /// - parameter backgroundColor: Backgroud color to apply for the output image. Default is `nil`.
    public init(cornerRadius: CGFloat, targetSize: CGSize? = nil, roundingCorners corners: RectCorner = .all, backgroundColor: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.targetSize = targetSize
        self.roundingCorners = corners
        self.backgroundColor = backgroundColor

        self.identifier = {
            var identifier = ""

            if let size = targetSize {
                identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor(\(cornerRadius)_\(size)\(corners.cornerIdentifier))"
            } else {
                identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor(\(cornerRadius)\(corners.cornerIdentifier))"
            }
            if let backgroundColor = backgroundColor {
                identifier += "_\(backgroundColor)"
            }

            return identifier
        }()
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let size = targetSize ?? image.kf.size
            return image.kf.image(withRoundRadius: cornerRadius, fit: size, roundingCorners: roundingCorners, backgroundColor: backgroundColor)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}


/// Specify how a size adjusts itself to fit a target size.
///
/// - none: Not scale the content.
/// - aspectFit: Scale the content to fit the size of the view by maintaining the aspect ratio.
/// - aspectFill: Scale the content to fill the size of the view
public enum ContentMode {
    case none
    case aspectFit
    case aspectFill
}

/// Processor for resizing images. Only CG-based images are supported in macOS.
public struct ResizingImageProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String
    
    /// The reference size for resizing operation.
    public let referenceSize: CGSize
    
    /// Target content mode of output image should be.
    /// Default to ContentMode.none
    public let targetContentMode: ContentMode
    
    /// Initialize a `ResizingImageProcessor`.
    ///
    /// - Parameters:
    ///   - referenceSize: The reference size for resizing operation.
    ///   - mode: Target content mode of output image should be.
    ///
    /// - Note:
    ///   The instance of `ResizingImageProcessor` will follow its `mode` property
    ///   and try to resizing the input images to fit or fill the `referenceSize`.
    ///   That means if you are using a `mode` besides of `.none`, you may get an
    ///   image with its size not be the same as the `referenceSize`.
    ///
    ///   **Example**: With input image size: {100, 200}, 
    ///   `referenceSize`: {100, 100}, `mode`: `.aspectFit`,
    ///   you will get an output image with size of {50, 100}, which "fit"s
    ///   the `referenceSize`.
    ///
    ///   If you need an output image exactly to be a specified size, append or use
    ///   a `CroppingImageProcessor`.
    public init(referenceSize: CGSize, mode: ContentMode = .none) {
        self.referenceSize = referenceSize
        self.targetContentMode = mode
        
        if mode == .none {
            self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(referenceSize))"
        } else {
            self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(referenceSize), \(mode))"
        }
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.resize(to: referenceSize, for: targetContentMode)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Processor for adding blur effect to images. `Accelerate.framework` is used underhood for 
/// a better performance. A simulated Gaussian blur with specified blur radius will be applied.
public struct BlurImageProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String
    
    /// Blur radius for the simulated Gaussian blur.
    public let blurRadius: CGFloat

    /// Initialize a `BlurImageProcessor`
    ///
    /// - parameter blurRadius: Blur radius for the simulated Gaussian blur.
    public init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
        self.identifier = "com.onevcat.Kingfisher.BlurImageProcessor(\(blurRadius))"
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let radius = blurRadius * options.scaleFactor
            return image.kf.blurred(withRadius: radius)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Processor for adding an overlay to images. Only CG-based images are supported in macOS.
public struct OverlayImageProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String
    
    /// Overlay color will be used to overlay the input image.
    public let overlay: Color
    
    /// Fraction will be used when overlay the color to image.
    public let fraction: CGFloat
    
    /// Initialize an `OverlayImageProcessor`
    ///
    /// - parameter overlay:  Overlay color will be used to overlay the input image.
    /// - parameter fraction: Fraction will be used when overlay the color to image. 
    ///                       From 0.0 to 1.0. 0.0 means solid color, 1.0 means transparent overlay.
    public init(overlay: Color, fraction: CGFloat = 0.5) {
        self.overlay = overlay
        self.fraction = fraction
        self.identifier = "com.onevcat.Kingfisher.OverlayImageProcessor(\(overlay.hex)_\(fraction))"
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.overlaying(with: overlay, fraction: fraction)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Processor for tint images with color. Only CG-based images are supported.
public struct TintImageProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String
    
    /// Tint color will be used to tint the input image.
    public let tint: Color
    
    /// Initialize a `TintImageProcessor`
    ///
    /// - parameter tint: Tint color will be used to tint the input image.
    public init(tint: Color) {
        self.tint = tint
        self.identifier = "com.onevcat.Kingfisher.TintImageProcessor(\(tint.hex))"
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.tinted(with: tint)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Processor for applying some color control to images. Only CG-based images are supported.
/// watchOS is not supported.
public struct ColorControlsProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String
    
    /// Brightness changing to image.
    public let brightness: CGFloat
    
    /// Contrast changing to image.
    public let contrast: CGFloat
    
    /// Saturation changing to image.
    public let saturation: CGFloat
    
    /// InputEV changing to image.
    public let inputEV: CGFloat
    
    /// Initialize a `ColorControlsProcessor`
    ///
    /// - parameter brightness: Brightness changing to image.
    /// - parameter contrast:   Contrast changing to image.
    /// - parameter saturation: Saturation changing to image.
    /// - parameter inputEV:    InputEV changing to image.
    public init(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.inputEV = inputEV
        self.identifier = "com.onevcat.Kingfisher.ColorControlsProcessor(\(brightness)_\(contrast)_\(saturation)_\(inputEV))"
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Processor for applying black and white effect to images. Only CG-based images are supported.
/// watchOS is not supported.
public struct BlackWhiteProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier = "com.onevcat.Kingfisher.BlackWhiteProcessor"
    
    /// Initialize a `BlackWhiteProcessor`
    public init() {}
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return ColorControlsProcessor(brightness: 0.0, contrast: 1.0, saturation: 0.0, inputEV: 0.7)
            .process(item: item, options: options)
    }
}

/// Processor for cropping an image. Only CG-based images are supported.
/// watchOS is not supported.
public struct CroppingImageProcessor: ImageProcessor {
    
    /// Identifier of the processor.
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public let identifier: String
    
    /// Target size of output image should be.
    public let size: CGSize
    
    /// Anchor point from which the output size should be calculate.
    /// The anchor point is consisted by two values between 0.0 and 1.0.
    /// It indicates a related point in current image. 
    /// See `CroppingImageProcessor.init(size:anchor:)` for more.
    public let anchor: CGPoint
    
    /// Initialize a `CroppingImageProcessor`
    ///
    /// - Parameters:
    ///   - size: Target size of output image should be.
    ///   - anchor: The anchor point from which the size should be calculated.
    ///             Default is `CGPoint(x: 0.5, y: 0.5)`, which means the center of input image.
    /// - Note:
    ///   The anchor point is consisted by two values between 0.0 and 1.0.
    ///   It indicates a related point in current image, eg: (0.0, 0.0) for top-left
    ///   corner, (0.5, 0.5) for center and (1.0, 1.0) for bottom-right corner.
    ///   The `size` property of `CroppingImageProcessor` will be used along with
    ///   `anchor` to calculate a target rectange in the size of image.
    ///    
    ///   The target size will be automatically calculated with a reasonable behavior.
    ///   For example, when you have an image size of `CGSize(width: 100, height: 100)`,
    ///   and a target size of `CGSize(width: 20, height: 20)`: 
    ///   - with a (0.0, 0.0) anchor (top-left), the crop rect will be `{0, 0, 20, 20}`; 
    ///   - with a (0.5, 0.5) anchor (center), it will be `{40, 40, 20, 20}`
    ///   - while with a (1.0, 1.0) anchor (bottom-right), it will be `{80, 80, 20, 20}`
    public init(size: CGSize, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        self.size = size
        self.anchor = anchor
        self.identifier = "com.onevcat.Kingfisher.CroppingImageProcessor(\(size)_\(anchor))"
    }
    
    /// Process an input `ImageProcessItem` item to an image for this processor.
    ///
    /// - parameter item:    Input item which will be processed by `self`
    /// - parameter options: Options when processing the item.
    ///
    /// - returns: The processed image.
    ///
    /// - Note: See documentation of `ImageProcessor` protocol for more.
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.crop(to: size, anchorOn: anchor)
        case .data(_): return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Concatenate two `ImageProcessor`s. `ImageProcessor.appen(another:)` is used internally.
///
/// - parameter left:  First processor.
/// - parameter right: Second processor.
///
/// - returns: The concatenated processor.
public func >>(left: ImageProcessor, right: ImageProcessor) -> ImageProcessor {
    return left.append(another: right)
}

fileprivate extension Color {
    var hex: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rInt = Int(r * 255) << 24
        let gInt = Int(g * 255) << 16
        let bInt = Int(b * 255) << 8
        let aInt = Int(a * 255)
        
        let rgba = rInt | gInt | bInt | aInt
        
        return String(format:"#%08x", rgba)
    }
}
