//
//  ImageProcessor.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/08/26.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import Foundation

enum ImageProcessItem {
    case image(Image)
    case data(Data)
}

protocol ImageProcessor {
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

struct DefaultProcessor: ImageProcessor {
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return Image.kf_image(data: data, scale: options.scaleFactor, preloadAllGIFData: options.preloadAllGIFData)
        }
    }
}

struct RoundCornerImageProcessor: ImageProcessor {
    
    let cornerRadius: Float
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            return (DefaultProcessor() |> self).process(item: .data(data), options: options)
        }
    }
}

infix operator |>: DefaultPrecedence
func |>(left: ImageProcessor, right: ImageProcessor) -> ImageProcessor {
    return left.append(another: right)
}
