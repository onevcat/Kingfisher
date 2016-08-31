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

public enum ImageProcessItem {
    case image(Image)
    case data(Data)
}

public protocol ImageProcessor {
    var identifier: String { get }
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image?
}

typealias ProcessorImp = ((ImageProcessItem, KingfisherOptionsInfo) -> Image?)

public extension ImageProcessor {
    func append(another: ImageProcessor) -> ImageProcessor {
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

public struct DefaultProcessor: ImageProcessor {
    public let identifier = ""
    public init() {}
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return Image.kf_image(data: data, scale: options.scaleFactor, preloadAllGIFData: options.preloadAllGIFData)
        }
    }
}

public struct RoundCornerImageProcessor: ImageProcessor {
    public let identifier: String
    public let cornerRadius: CGFloat
    public let targetSize: CGSize?
    
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
            let size = targetSize ?? image.kf_size
            return image.kf_image(withRoundRadius: cornerRadius, fit: size, scale: options.scaleFactor)
        case .data(_):
            return (DefaultProcessor() |> self).process(item: item, options: options)
        }
    }
}

public struct ResizingImageProcessor: ImageProcessor {
    public let identifier: String
    public let targetSize: CGSize
    
    public init(targetSize: CGSize) {
        self.targetSize = targetSize
        self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(targetSize))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf_resize(to: targetSize)
        case .data(_):
            return (DefaultProcessor() |> self).process(item: item, options: options)
        }
    }
}

public struct BlurImageProcessor: ImageProcessor {
    public let identifier: String
    public let blurRadius: CGFloat

    public init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
        self.identifier = "com.onevcat.Kingfisher.BlurImageProcessor(\(blurRadius))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let radius = blurRadius * options.scaleFactor
            return image.kf_blurred(withRadius: radius)
        case .data(_):
            return (DefaultProcessor() |> self).process(item: item, options: options)
        }
    }
}

public struct OverlayImageProcessor: ImageProcessor {
    public var identifier: String
    public let overlay: Color
    public let fraction: CGFloat
    
    public init(overlay: Color, fraction: CGFloat = 0.5) {
        self.overlay = overlay
        self.fraction = fraction
        self.identifier = "com.onevcat.Kingfisher.OverlayImageProcessor(\(overlay.hex)_\(fraction))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf_overlaying(with: overlay, fraction: fraction)
        case .data(_):
            return (DefaultProcessor() |> self).process(item: item, options: options)
        }
    }
}

public struct TintImageProcessor: ImageProcessor {
    public let identifier: String
    public let tint: Color
    public init(tint: Color) {
        self.tint = tint
        self.identifier = "com.onevcat.Kingfisher.TintImageProcessor(\(tint.hex))"
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf_tinted(with: tint)
        case .data(_):
            return (DefaultProcessor() |> self).process(item: item, options: options)
        }
    }
}

public struct ColorControlsProcessor: ImageProcessor {
    public let identifier: String
    public let brightness: CGFloat
    public let contrast: CGFloat
    public let saturation: CGFloat
    public let inputEV: CGFloat
    
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
            return image.kf_adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
        case .data(_):
            return (DefaultProcessor() |> self).process(item: item, options: options)
        }
    }
}

public struct BlackWhiteProcessor: ImageProcessor {
    public let identifier = "com.onevcat.Kingfisher.BlackWhiteProcessor"
    public init() {}
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return ColorControlsProcessor(brightness: 0.0, contrast: 1.0, saturation: 0.0, inputEV: 0.7)
            .process(item: item, options: options)
    }
}

infix operator |>: AdditionPrecedence
public func |>(left: ImageProcessor, right: ImageProcessor) -> ImageProcessor {
    return left.append(another: right)
}

fileprivate extension Color {
    var hex: String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgba = Int(r*255) << 24 | Int(g*255) << 16 | Int(b*255) << 8 | Int(a*255)
        
        return String(format:"#%08x", rgba)
    }
}
