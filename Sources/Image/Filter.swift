//
//  Filter.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/08/31.
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

#if !os(watchOS)

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import CoreImage

// Reuses the same CI Context for all CI drawings.
struct SendableBox<T>: @unchecked Sendable {
    let value: T
}

private let ciContext = SendableBox(value: CIContext(options: nil))

/// Represents the type of transformer method, which will be used to provide a ``Filter``.
public typealias Transformer = (CIImage) -> CIImage?

/// Represents an ``ImageProcessor`` based on a ``Filter``, for images of `CIImage`.
///
/// You can use any ``Filter``, or in other words, a ``Transformer`` to convert a `CIImage` to another, to create a
/// ``ImageProcessor`` type easily.
public protocol CIImageProcessor: ImageProcessor {
    var filter: Filter { get }
}

extension CIImageProcessor {
    
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.kf.apply(filter)
        case .data:
            return (DefaultImageProcessor.default |> self).process(item: item, options: options)
        }
    }
}

/// A wrapper struct for a `Transformer` of CIImage filters. 
///
/// A ``Filter`` value can be used to create an ``ImageProcessor`` for `CIImage`s.
public struct Filter {
    
    let transform: Transformer
    
    /// Creates a ``Filter`` from a given ``Transformer``.
    ///
    /// - Parameter transform: The value defines how a `CIImage` can be converted to another one.
    public init(transform: @escaping Transformer) {
        self.transform = transform
    }
    
    /// Tint filter that applies a tint color to images.
    public static let tint: @Sendable (KFCrossPlatformColor) -> Filter = {
        color in
        Filter {
            input in
            
            let colorFilter = CIFilter(name: "CIConstantColorGenerator")!
            colorFilter.setValue(CIColor(color: color), forKey: kCIInputColorKey)
            
            let filter = CIFilter(name: "CISourceOverCompositing")!
            
            let colorImage = colorFilter.outputImage
            filter.setValue(colorImage, forKey: kCIInputImageKey)
            filter.setValue(input, forKey: kCIInputBackgroundImageKey)
            
            return filter.outputImage?.cropped(to: input.extent)
        }
    }
    
    /// Represents color control elements.
    ///
    /// It contains necessary variables which can be applied as a filter to `CIImage.applyingFilter` feature as
    /// "CIColorControls".
    public struct ColorElement {
        public let brightness: CGFloat
        public let contrast: CGFloat
        public let saturation: CGFloat
        public let inputEV: CGFloat
        
        /// Creates a ``ColorElement`` value with given parameters.
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
        }
    }
    
    /// Color control filter that applies color control changes to images.
    public static let colorControl: @Sendable (ColorElement) -> Filter = { arg -> Filter in
        return Filter { input in
            let paramsColor = [kCIInputBrightnessKey: arg.brightness,
                                 kCIInputContrastKey: arg.contrast,
                               kCIInputSaturationKey: arg.saturation]
            let blackAndWhite = input.applyingFilter("CIColorControls", parameters: paramsColor)
            let paramsExposure = [kCIInputEVKey: arg.inputEV]
            return blackAndWhite.applyingFilter("CIExposureAdjust", parameters: paramsExposure)
        }
    }
}

extension KingfisherWrapper where Base: KFCrossPlatformImage {

    /// Applies a `Filter` containing a `CIImage` transformer to `self`.
    ///
    /// - Parameters:
    ///     - filter: The filter used to transform `self`.
    /// - Returns: A transformed image by the input `Filter`.
    ///
    /// > Important: Only CG-based images are supported. If an error occurs during transformation,
    /// ``KingfisherWrapper/base`` will be returned.
    public func apply(_ filter: Filter) -> KFCrossPlatformImage {
        
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Tint image only works for CG-based image.")
            return base
        }
        
        let inputImage = CIImage(cgImage: cgImage)
        guard let outputImage = filter.transform(inputImage) else {
            return base
        }

        guard let result = ciContext.value.createCGImage(outputImage, from: outputImage.extent) else {
            assertionFailure("[Kingfisher] Can not make an tint image within context.")
            return base
        }
        
        #if os(macOS)
            return fixedForRetinaPixel(cgImage: result, to: size)
        #else
            return KFCrossPlatformImage(cgImage: result, scale: base.scale, orientation: base.imageOrientation)
        #endif
    }

}

#endif
