//
//  ImageProcessor.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/08/26.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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
    /// will be "\(self.identifier)|>\(another.identifier)>".
    ///
    /// - parameter another: An `ImageProcessor` you want to append to `self`.
    ///
    /// - returns: The new `ImageProcessor`. It will process the image in the order
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
    
    public let identifier = ""
    
    /// Initialize a `DefaultImageProcessor`
    ///
    /// - returns: An initialized `DefaultImageProcessor`.
    public init() {}
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return Kingfisher<Image>.image(data: data, scale: options.scaleFactor, preloadAllGIFData: options.preloadAllGIFData)
        }
    }
}

/// Processor for making round corner images. Only CG-based images are supported in macOS, 
/// if a non-CG image passed in, the processor will do nothing.
public struct RoundCornerImageProcessor: ImageProcessor {
    public let identifier: String

    /// Corner radius will be applied in processing.
    public let cornerRadius: CGFloat
    
    /// Target size of output image should be. If `nil`, the image will keep its original size after processing.
    public let targetSize: CGSize?
    
    /// Initialize a `RoundCornerImageProcessor`
    ///
    /// - parameter cornerRadius: Corner radius will be applied in processing.
    /// - parameter targetSize:   Target size of output image should be. If `nil`, 
    ///                           the image will keep its original size after processing.
    ///                           Default is `nil`.
    ///
    /// - returns: An initialized `RoundCornerImageProcessor`.
    public init(cornerRadius: CGFloat, targetSize: CGSize? = nil) {
        self.cornerRadius = cornerRadius
        self.targetSize = targetSize
        if let size = targetSize {
            self.identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor(\(cornerRadius)_\(size))"
        } else {
            self.identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor(\(cornerRadius))"
        }
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let size = targetSize ?? image.kf.size
            return image.kf.image(withRoundRadius: cornerRadius, fit: size, scale: options.scaleFactor)
        case .data(_):
            return (DefaultImageProcessor() >> self).process(item: item, options: options)
        }
    }
}

/// Processor for resizing images. Only CG-based images are supported in macOS.
public struct ResizingImageProcessor: ImageProcessor {
    public let identifier: String
    
    /// Target size of output image should be.
    public let targetSize: CGSize
    
    /// Initialize a `ResizingImageProcessor`
    ///
    /// - parameter targetSize: Target size of output image should be.
    ///
    /// - returns: An initialized `ResizingImageProcessor`.
    public init(targetSize: CGSize) {
        self.targetSize = targetSize
        self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(targetSize))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.resize(to: targetSize)
        case .data(_):
            return (DefaultImageProcessor() >> self).process(item: item, options: options)
        }
    }
}

/// Processor for adding blur effect to images. `Accelerate.framework` is used underhood for 
/// a better performance. A simulated Gaussian blur with specified blur radius will be applied.
public struct BlurImageProcessor: ImageProcessor {
    public let identifier: String
    
    /// Blur radius for the simulated Gaussian blur.
    public let blurRadius: CGFloat

    /// Initialize a `BlurImageProcessor`
    ///
    /// - parameter blurRadius: Blur radius for the simulated Gaussian blur.
    ///
    /// - returns: An initialized `BlurImageProcessor`.
    public init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
        self.identifier = "com.onevcat.Kingfisher.BlurImageProcessor(\(blurRadius))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let radius = blurRadius * options.scaleFactor
            return image.kf.blurred(withRadius: radius)
        case .data(_):
            return (DefaultImageProcessor() >> self).process(item: item, options: options)
        }
    }
}

/// Processor for adding an overlay to images. Only CG-based images are supported in macOS.
public struct OverlayImageProcessor: ImageProcessor {
    
    public var identifier: String
    
    /// Overlay color will be used to overlay the input image.
    public let overlay: Color
    
    /// Fraction will be used when overlay the color to image.
    public let fraction: CGFloat
    
    /// Initialize an `OverlayImageProcessor`
    ///
    /// - parameter overlay:  Overlay color will be used to overlay the input image.
    /// - parameter fraction: Fraction will be used when overlay the color to image. 
    ///                       From 0.0 to 1.0. 0.0 means solid color, 1.0 means transparent overlay.
    ///
    /// - returns: An initialized `OverlayImageProcessor`.
    public init(overlay: Color, fraction: CGFloat = 0.5) {
        self.overlay = overlay
        self.fraction = fraction
        self.identifier = "com.onevcat.Kingfisher.OverlayImageProcessor(\(overlay.hex)_\(fraction))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.overlaying(with: overlay, fraction: fraction)
        case .data(_):
            return (DefaultImageProcessor() >> self).process(item: item, options: options)
        }
    }
}

/// Processor for tint images with color. Only CG-based images are supported.
public struct TintImageProcessor: ImageProcessor {
    
    public let identifier: String
    
    /// Tint color will be used to tint the input image.
    public let tint: Color
    
    /// Initialize a `TintImageProcessor`
    ///
    /// - parameter tint: Tint color will be used to tint the input image.
    ///
    /// - returns: An initialized `TintImageProcessor`.
    public init(tint: Color) {
        self.tint = tint
        self.identifier = "com.onevcat.Kingfisher.TintImageProcessor(\(tint.hex))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.tinted(with: tint)
        case .data(_):
            return (DefaultImageProcessor() >> self).process(item: item, options: options)
        }
    }
}

/// Processor for applying some color control to images. Only CG-based images are supported.
/// watchOS is not supported.
public struct ColorControlsProcessor: ImageProcessor {
    
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
    ///
    /// - returns: An initialized `ColorControlsProcessor`
    public init(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.inputEV = inputEV
        self.identifier = "com.onevcat.Kingfisher.ColorControlsProcessor(\(brightness)_\(contrast)_\(saturation)_\(inputEV))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
        case .data(_):
            return (DefaultImageProcessor() >> self).process(item: item, options: options)
        }
    }
}

/// Processor for applying black and white effect to images. Only CG-based images are supported.
/// watchOS is not supported.
public struct BlackWhiteProcessor: ImageProcessor {
    public let identifier = "com.onevcat.Kingfisher.BlackWhiteProcessor"
    
    /// Initialize a `BlackWhiteProcessor`
    ///
    /// - returns: An initialized `BlackWhiteProcessor`
    public init() {}
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return ColorControlsProcessor(brightness: 0.0, contrast: 1.0, saturation: 0.0, inputEV: 0.7)
            .process(item: item, options: options)
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
        
        let rgba = Int(r * 255) << 24 | Int(g * 255) << 16 | Int(b * 255) << 8 | Int(a * 255)
        
        return String(format:"#%08x", rgba)
    }
}
