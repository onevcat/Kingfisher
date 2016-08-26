//
//  ImageProcessor.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/08/26.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

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

extension ImageProcessor {
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

struct GeneralProcessor: ImageProcessor {
    let p: ProcessorImp
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return p(item, options)
    }
}

public struct DefaultProcessor: ImageProcessor {
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
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let targetSize: CGSize
            #if os(macOS)
                targetSize = image.representations.reduce(CGSize.zero, { size, rep in
                    return CGSize(width: max(size.width, CGFloat(rep.pixelsWide)), height: max(size.height, CGFloat(rep.pixelsHigh)))
                })
            #else
                targetSize = image.size
            #endif
            return image.kf_image(withRoundRadius: cornerRadius, fit: targetSize, scale: options.scaleFactor)
        case .data(let data):
            return (DefaultProcessor() |> self).process(item: .data(data), options: options)
        }
    }
}

infix operator |>: DefaultPrecedence
public func |>(left: ImageProcessor, right: ImageProcessor) -> ImageProcessor {
    return left.append(another: right)
}
