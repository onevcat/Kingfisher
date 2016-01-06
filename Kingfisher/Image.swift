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
import MobileCoreServices
public typealias Image = UIImage
#endif

import ImageIO

private var imagesKey: Void?
private var durationKey: Void?

extension Image {
#if os(OSX)
    
    var CGImage: CGImageRef! {
        return CGImageForProposedRect(nil, context: nil, hints: nil)
    }
    
    var kf_scale: CGFloat {
        return 1.0
    }
    
    private(set) var kf_images: [Image]? {
        get {
            return objc_getAssociatedObject(self, &imagesKey) as? [Image]
        }
        set {
            objc_setAssociatedObject(self, &imagesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private(set) var kf_duration: NSTimeInterval {
        get {
            return objc_getAssociatedObject(self, &durationKey) as? NSTimeInterval ?? 0.0
        }
        set {
            objc_setAssociatedObject(self, &durationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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

extension Image {
    static func kf_animatedImageWithGIFData(gifData data: NSData) -> Image? {
        return kf_animatedImageWithGIFData(gifData: data, scale: 1.0, duration: 0.0)
    }
    
    static func kf_animatedImageWithGIFData(gifData data: NSData, scale: CGFloat, duration: NSTimeInterval) -> Image? {
        
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(bool: true), kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data, options) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        var images = [Image]()
        
        var gifDuration = 0.0
        
        for i in 0 ..< frameCount {
            guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, options) else {
                return nil
            }
            
            guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil),
                gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else
            {
                return nil
            }
            
            gifDuration += frameDuration.doubleValue
            images.append(Image.kf_imageWithCGImage(imageRef, scale: scale, refImage: nil))
        }
        
#if os(OSX)
        if let image = Image(data: data) {
            image.kf_images = images
            image.kf_duration = gifDuration
            return image
        }
        return nil
#else
        if frameCount == 1 {
            return images.first
        } else {
            return Image.kf_animatedImageWithImages(images, duration: duration <= 0.0 ? gifDuration : duration)
        }
#endif
        

        
    }
}


