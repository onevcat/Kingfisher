//
//  Image.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/6.
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


#if os(OSX)
import AppKit.NSImage
public typealias Image = NSImage

private var imagesKey: Void?
private var durationKey: Void?
#else
import UIKit.UIImage
import MobileCoreServices
public typealias Image = UIImage
#endif

import ImageIO

// MARK: - Image Properties
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
#endif
}

// MARK: - Image Conversion
extension Image {
#if os(OSX)
    static func kf_imageWithCGImage(cgImage: CGImageRef, scale: CGFloat, refImage: Image?) -> Image {
        return Image(CGImage: cgImage, size: CGSize.zero)
    }
    
    /**
    Normalize the image. This method does nothing in OS X.
    
    - returns: The image itself.
    */
    public func kf_normalizedImage() -> Image {
        return self
    }
    
    static func kf_animatedImageWithImages(images: [Image], duration: NSTimeInterval) -> Image? {
        return nil
    }
#else
    static func kf_imageWithCGImage(cgImage: CGImageRef, scale: CGFloat, refImage: Image?) -> Image {
        if let refImage = refImage {
            return Image(CGImage: cgImage, scale: scale, orientation: refImage.imageOrientation)
        } else {
            return Image(CGImage: cgImage, scale: scale, orientation: .Up)
        }
    }
    
    /**
     Normalize the image. This method will try to redraw an image with orientation and scale considered.
     
     - returns: The normalized image with orientation set to up and correct scale.
     */
    public func kf_normalizedImage() -> Image {
        // prevent animated image (GIF) lose it's images
        if images != nil {
            return self
        }
    
        if imageOrientation == .Up {
            return self
        }
    
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        drawInRect(CGRect(origin: CGPoint.zero, size: size))
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
    if let cgimage = image.CGImage {
        let rep = NSBitmapImageRep(CGImage: cgimage)
        return rep.representationUsingType(.NSPNGFileType, properties:[:])
    }
    return nil
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
            
            if frameCount == 1 {
                // Single frame
                gifDuration = Double.infinity
            } else {
                // Animated GIF
                guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil),
                    gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                    frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else
                {
                    return nil
                }
                gifDuration += frameDuration.doubleValue
            }
            
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
        return Image.kf_animatedImageWithImages(images, duration: duration <= 0.0 ? gifDuration : duration)
#endif
    }
}

// MARK: - Create images from data
extension Image {
    static func kf_imageWithData(data: NSData, scale: CGFloat) -> Image? {
        var image: Image?
        #if os(OSX)
            switch data.kf_imageFormat {
            case .JPEG: image = Image(data: data)
            case .PNG: image = Image(data: data)
            case .GIF: image = Image.kf_animatedImageWithGIFData(gifData: data, scale: scale, duration: 0.0)
            case .Unknown: image = Image(data: data)
            }
        #else
            switch data.kf_imageFormat {
            case .JPEG: image = Image(data: data, scale: scale)
            case .PNG: image = Image(data: data, scale: scale)
            case .GIF: image = Image.kf_animatedImageWithGIFData(gifData: data, scale: scale, duration: 0.0)
            case .Unknown: image = Image(data: data, scale: scale)
            }
        #endif
        
        return image
    }
}

// MARK: - Decode
extension Image {
    func kf_decodedImage() -> Image? {
        return self.kf_decodedImage(scale: kf_scale)
    }
    
    func kf_decodedImage(scale scale: CGFloat) -> Image? {
        // prevent animated image (GIF) lose it's images
        if kf_images != nil {
            return self
        }
        
        let imageRef = self.CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue
        
        let context = CGBitmapContextCreate(nil, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef), 8, 0, colorSpace, bitmapInfo)
        if let context = context {
            let rect = CGRect(x: 0, y: 0, width: CGImageGetWidth(imageRef), height: CGImageGetHeight(imageRef))
            CGContextDrawImage(context, rect, imageRef)
            let decompressedImageRef = CGBitmapContextCreateImage(context)
            return Image.kf_imageWithCGImage(decompressedImageRef!, scale: scale, refImage: self)
        } else {
            return nil
        }
    }
}

// MARK: - Image format
private let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
private let jpgHeaderSOI: [UInt8] = [0xFF, 0xD8]
private let jpgHeaderIF: [UInt8] = [0xFF]
private let gifHeader: [UInt8] = [0x47, 0x49, 0x46]

enum ImageFormat {
    case Unknown, PNG, JPEG, GIF
}

extension NSData {
    var kf_imageFormat: ImageFormat {
        var buffer = [UInt8](count: 8, repeatedValue: 0)
        self.getBytes(&buffer, length: 8)
        if buffer == pngHeader {
            return .PNG
        } else if buffer[0] == jpgHeaderSOI[0] &&
            buffer[1] == jpgHeaderSOI[1] &&
            buffer[2] == jpgHeaderIF[0]
        {
            return .JPEG
        } else if buffer[0] == gifHeader[0] &&
            buffer[1] == gifHeader[1] &&
            buffer[2] == gifHeader[2]
        {
            return .GIF
        }
        
        return .Unknown
    }
}
