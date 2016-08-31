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
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image?
}

typealias ProcessorImp = ((ImageProcessItem, KingfisherOptionsInfo) -> Image?)

public extension ImageProcessor {
    func append(another: ImageProcessor) -> ImageProcessor {
        return GeneralProcessor { item, options in
            if let image = self.process(item: item, options: options) {
                return another.process(item: .image(image), options: options)
            } else {
                return nil
            }
        }
    }
}

fileprivate struct GeneralProcessor: ImageProcessor {
    let p: ProcessorImp
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return p(item, options)
    }
}

public struct DefaultProcessor: ImageProcessor {
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
    
    public let cornerRadius: CGFloat
    public let targetSize: CGSize?
    
    public init(cornerRadius: CGFloat, targetSize: CGSize? = nil) {
        self.cornerRadius = cornerRadius
        self.targetSize = targetSize
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
    public let targetSize: CGSize
    public init(targetSize: CGSize) {
        self.targetSize = targetSize
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
    public let blurRadius: CGFloat

    public init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
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
    public let overlay: Color
    public let fraction: CGFloat
    
    public init(overlay: Color, fraction: CGFloat = 0.5) {
        self.overlay = overlay
        self.fraction = fraction
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
    public let tint: Color
    public init(tint: Color) {
        self.tint = tint
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
    public let brightness: CGFloat
    public let contrast: CGFloat
    public let saturation: CGFloat
    public let inputEV: CGFloat
    
    public init(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.inputEV = inputEV
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
