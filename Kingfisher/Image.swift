//
//  Image.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/01/06.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

#if os(OSX)
    import AppKit.NSImage
    public typealias Image = NSImage
#else
    import UIKit.UIImage
    public typealias Image = UIImage
#endif


extension Image {
#if os(OSX)
    
    var CGImage: CGImageRef! {
        return CGImageForProposedRect(nil, context: nil, hints: nil)
    }
    
    var kf_scale: CGFloat {
        return 1.0
    }
    
    var kf_images: [Image]? {
        return nil
    }
    
    var kf_duration: NSTimeInterval {
        return 0
    }

    static func kf_imageWithCGImage(cgImage: CGImageRef, scale: CGFloat, refImage: Image?) -> Image {
        return Image(CGImage: cgImage, size: CGSizeZero)
    }
    
    public func kf_normalizedImage() -> Image {
        return self
    }
    
    static func kf_animatedImageWithImages(images: [Image], duration: NSTimeInterval) -> Image? {
        return nil
    }
    
#else
    var kf_scale: CGFloat {
        return scale
    }
    
    var kf_images: [Image]? {
        return images
    }
    
    var kf_duration: NSTimeInterval {
        return duration
    }
    
    static func kf_imageWithCGImage(cgImage: CGImageRef, scale: CGFloat, refImage: Image?) -> Image {
    if let refImage = refImage {
        return Image(CGImage: cgImage, scale: scale, orientation: refImage.imageOrientation)
    } else {
        return Image(CGImage: cgImage, scale: scale, orientation: .Up)
    }
    
    }
    
    public func kf_normalizedImage() -> Image {
        // prevent animated image (GIF) lose it's images
        if images != nil {
            return self
        }
    
        if imageOrientation == .Up {
            return self
        }
    
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        drawInRect(CGRect(origin: CGPointZero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return normalizedImage
    }
    
    static func kf_animatedImageWithImages(images: [Image], duration: NSTimeInterval) -> Image? {
        return Image.animatedImageWithImages(images, duration: duration)
    }
#endif
}

// MARK: - PNG
func ImagePNGRepresentation(image: Image) -> NSData? {
#if os(OSX)
    let rep = NSBitmapImageRep(CGImage: image.CGImage)
    return rep.representationUsingType(.NSPNGFileType, properties:[:])
#else
    return UIImagePNGRepresentation(image)
#endif
}

// MARK: - JPEG
func ImageJPEGRepresentation(image: Image, _ compressionQuality: CGFloat) -> NSData? {
#if os(OSX)
    let rep = NSBitmapImageRep(CGImage: image.CGImage)
    return rep.representationUsingType(.NSJPEGFileType, properties: [NSImageCompressionFactor: compressionQuality])
#else
    return UIImageJPEGRepresentation(image, compressionQuality)
#endif
}

// MARK: - GIF
func ImageGIFRepresentation(image: Image) -> NSData? {
    return ImageGIFRepresentation(image, duration: 0.0, repeatCount: 0)
}

func ImageGIFRepresentation(image: Image, duration: NSTimeInterval, repeatCount: Int) -> NSData? {
    guard let images = image.kf_images else {
        return nil
    }
    
    let frameCount = images.count
    let gifDuration = duration <= 0.0 ? image.kf_duration / Double(frameCount) : duration / Double(frameCount)
    
    let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: gifDuration]]
    let imageProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: repeatCount]]
    
    let data = NSMutableData()
    
    guard let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, frameCount, nil) else {
        return nil
    }
    CGImageDestinationSetProperties(destination, imageProperties)
    
    for image in images {
        CGImageDestinationAddImage(destination, image.CGImage!, frameProperties)
    }
    
    return CGImageDestinationFinalize(destination) ? NSData(data: data) : nil
}


