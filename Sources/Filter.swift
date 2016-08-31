//
//  Filter.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/08/31.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import CoreImage
import Accelerate

// Reuse the same CI Context for all CI drawing.
private let ciContext = CIContext(options: nil)

public typealias Transformer = (CIImage) -> CIImage?
public protocol CIImageProcessor: ImageProcessor {
    var filter: Filter { get }
}

public struct Filter {
    
    let transform: Transformer
    
    public static var tint: (Color) -> Filter = {
        color in
        Filter { input in
            let colorFilter = CIFilter(name: "CIConstantColorGenerator")!
            colorFilter.setValue(CIColor(color: color), forKey: kCIInputColorKey)
            
            let colorImage = colorFilter.outputImage
            let filter = CIFilter(name: "CISourceOverCompositing")!
            filter.setValue(colorImage, forKey: kCIInputImageKey)
            filter.setValue(input, forKey: kCIInputBackgroundImageKey)
            return filter.outputImage?.cropping(to: input.extent)
        }
    }
    
    public typealias ColorElement = (CGFloat, CGFloat, CGFloat, CGFloat)
    public static var colorControl: (ColorElement) -> Filter = {
        brightness, contrast, saturation, inputEV in
        Filter { input in
            let paramsColor = [kCIInputBrightnessKey: brightness,
                               kCIInputContrastKey: contrast,
                               kCIInputSaturationKey: saturation]
            
            let blackAndWhite = input.applyingFilter("CIColorControls", withInputParameters: paramsColor)
            let paramsExposure = [kCIInputEVKey: inputEV]
            return blackAndWhite.applyingFilter("CIExposureAdjust", withInputParameters: paramsExposure)
        }
        
    }
}



extension CIImageProcessor {
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf_apply(filter)
        case .data(let data):
            return Image.kf_image(data: data, scale: options.scaleFactor, preloadAllGIFData: options.preloadAllGIFData)
        }
    }
}

extension Image {
    func kf_apply(_ filter: Filter) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Tint image only works for CG-based image.")
            return self
        }
        
        let inputImage = CIImage(cgImage: cgImage)
        guard let outputImage = filter.transform(inputImage) else {
            return self
        }
        
        guard let result = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            assertionFailure("[Kingfisher] Can not make an tint image within context.")
            return self
        }
        
        #if os(macOS)
            return Image(cgImage: result, size: .zero)
        #else
            return Image(cgImage: result)
        #endif
    }
}
