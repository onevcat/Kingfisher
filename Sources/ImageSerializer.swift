//
//  ImageSerializer.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/09/02.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import Foundation

public protocol CacheSerializer {
    func data(with image: Image, original: Data?) -> Data?
    func image(with data: Data, options: KingfisherOptionsInfo?) -> Image?
}

public struct DefaultCacheSerializer: CacheSerializer {
    
    public static let `default` = DefaultCacheSerializer()
    private init() {}
    
    public func data(with image: Image, original: Data?) -> Data? {
        let imageFormat = original?.kf_imageFormat ?? .unknown
        
        let data: Data?
        switch imageFormat {
        case .PNG: data = image.pngRepresentation()
        case .JPEG: data = image.jpegRepresentation(compressionQuality: 1.0)
        case .GIF: data = image.gifRepresentation()
        case .unknown: data = original ?? image.kf_normalized().pngRepresentation()
        }
        
        return data
    }
    
    public func image(with data: Data, options: KingfisherOptionsInfo?) -> Image? {
        let scale = (options ?? KingfisherEmptyOptionsInfo).scaleFactor
        let preloadAllGIFData = (options ?? KingfisherEmptyOptionsInfo).preloadAllGIFData
        
        return Image.kf_image(data: data, scale: scale, preloadAllGIFData: preloadAllGIFData)
    }
}
