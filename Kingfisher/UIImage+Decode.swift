//
//  UIImage+Decode.swift
//  Kingfisher-Demo
//
//  Created by Wei Wang on 15/4/7.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

import Foundation

extension UIImage {
    func kf_decodedImage() -> UIImage? {
        let imageRef = self.CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context = CGBitmapContextCreate(nil, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef), 8, 0, colorSpace, bitmapInfo)
        if let context = context {
            let rect = CGRectMake(0, 0, CGFloat(CGImageGetWidth(imageRef)), CGFloat(CGImageGetHeight(imageRef)))
            CGContextDrawImage(context, rect, imageRef)
            let decompressedImageRef = CGBitmapContextCreateImage(context)
            return UIImage(CGImage: decompressedImageRef)
        } else {
            return nil
        }
    }
}