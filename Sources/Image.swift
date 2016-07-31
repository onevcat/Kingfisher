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

private var imageSourceKey: Void?
private var animatedImageDataKey: Void?
#endif

import ImageIO

// MARK: - Image Properties
extension Image {
#if os(OSX)
    var cgImage: CGImage! {
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
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
    
    private(set) var kf_duration: TimeInterval {
        get {
            return objc_getAssociatedObject(self, &durationKey) as? TimeInterval ?? 0.0
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
    
    var kf_duration: TimeInterval {
        return duration
    }
    
    private(set) var kf_imageSource: ImageSource? {
            get {
                return objc_getAssociatedObject(self, &imageSourceKey) as? ImageSource
            }
            set {
                objc_setAssociatedObject(self, &imageSourceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        
    private(set) var kf_animatedImageData: Data? {
            get {
                return objc_getAssociatedObject(self, &animatedImageDataKey) as? Data
            }
            set {
                objc_setAssociatedObject(self, &animatedImageDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
#endif
}

// MARK: - Image Conversion
extension Image {
#if os(OSX)
    static func kf_image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
        return Image(cgImage: cgImage, size: CGSize.zero)
    }
    
    /**
    Normalize the image. This method does nothing in OS X.
    
    - returns: The image itself.
    */
    public func kf_normalizedImage() -> Image {
        return self
    }
    
    static func kf_animatedImage(images: [Image], duration: TimeInterval) -> Image? {
        return nil
    }
#else
    static func kf_image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
        if let refImage = refImage {
            return Image(cgImage: cgImage, scale: scale, orientation: refImage.imageOrientation)
        } else {
            return Image(cgImage: cgImage, scale: scale, orientation: .up)
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
    
        if imageOrientation == .up {
            return self
        }
    
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return normalizedImage!
    }
    
    static func kf_animatedImage(images: [Image], duration: TimeInterval) -> Image? {
        return Image.animatedImage(with: images, duration: duration)
    }
#endif
}

extension Image {
    // MARK: - PNG
    func pngRepresentation() -> Data? {
        #if os(OSX)
            if let cgimage = cgImage {
                let rep = NSBitmapImageRep(cgImage: cgimage)
                return rep.representation(using: .PNG, properties: [:])
            }
            return nil
        #else
            return UIImagePNGRepresentation(self)
        #endif
    }
    
    // MARK: - JPEG
    func jpegRepresentation(compressionQuality: CGFloat) -> Data? {
        #if os(OSX)
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using:.JPEG, properties: [NSImageCompressionFactor: compressionQuality])
        #else
            return UIImageJPEGRepresentation(self, compressionQuality)
        #endif
    }
    
    func gifRepresentation() -> Data? {
        #if os(OSX)
            return gifRepresentation(duration: 0.0, repeatCount: 0)
        #else
            return kf_animatedImageData
        #endif
    }
    
    func gifRepresentation(duration: TimeInterval, repeatCount: Int) -> Data? {
        guard let images = kf_images else {
            return nil
        }
        
        let frameCount = images.count
        let gifDuration = duration <= 0.0 ? kf_duration / Double(frameCount) : duration / Double(frameCount)
        
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: gifDuration]]
        let imageProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: repeatCount]]
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, frameCount, nil) else {
            return nil
        }
        CGImageDestinationSetProperties(destination, imageProperties)
        
        for image in images {
            CGImageDestinationAddImage(destination, image.cgImage!, frameProperties)
        }
        
        return CGImageDestinationFinalize(destination) ? (NSData(data: data as Data) as Data) : nil
    }
}

extension Image {
    static func kf_animatedImage(gifData data: Data, preloadAll: Bool) -> Image? {
        return kf_animatedImage(gifData: data, scale: 1.0, duration: 0.0, preloadAll: preloadAll)
    }
    
    static func kf_animatedImage(gifData data: Data, scale: CGFloat, duration: TimeInterval, preloadAll: Bool) -> Image? {
        
        func decode(fromSource imageSource: CGImageSource, options: NSDictionary) -> ([Image], TimeInterval)? {

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
                        let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
                        let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) else
                    {
                        return nil
                    }
                    gifDuration += frameDuration.doubleValue
                }
                
                images.append(Image.kf_image(cgImage: imageRef, scale: scale, refImage: nil))
            }
            
            return (images, gifDuration)
        }
        
        // Start of kf_animatedImageWithGIFData
        let options: NSDictionary = [kCGImageSourceShouldCache as String: NSNumber(value: true), kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data, options) else {
            return nil
        }
        
#if os(OSX)
        guard let (images, gifDuration) = decode(fromSource: imageSource, options: options) else {
            return nil
        }
        let image = Image(data: data)
        image?.kf_images = images
        image?.kf_duration = gifDuration
    
        return image
#else
    
        if preloadAll {
            guard let (images, gifDuration) = decode(fromSource: imageSource, options: options) else {
                return nil
            }
            let image = Image.kf_animatedImage(images: images, duration: duration <= 0.0 ? gifDuration : duration)
            image?.kf_animatedImageData = data
            return image
        } else {
            let image = Image(data: data)
            image?.kf_animatedImageData = data
            image?.kf_imageSource = ImageSource(ref: imageSource)
            return image
        }
#endif
        
    }
}

// MARK: - Create images from data
extension Image {
    static func kf_image(data: Data, scale: CGFloat, preloadAllGIFData: Bool) -> Image? {
        var image: Image?
        #if os(OSX)
            switch data.kf_imageFormat {
            case .JPEG: image = Image(data: data)
            case .PNG: image = Image(data: data)
            case .GIF: image = Image.kf_animatedImage(gifData: data, scale: scale, duration: 0.0, preloadAll: preloadAllGIFData)
            case .unknown: image = Image(data: data)
            }
        #else
            switch data.kf_imageFormat {
            case .JPEG: image = Image(data: data, scale: scale)
            case .PNG: image = Image(data: data, scale: scale)
            case .GIF: image = Image.kf_animatedImage(gifData: data, scale: scale, duration: 0.0, preloadAll: preloadAllGIFData)
            case .unknown: image = Image(data: data, scale: scale)
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
    
    func kf_decodedImage(scale: CGFloat) -> Image? {
        // prevent animated image (GIF) lose it's images
#if os(iOS)
        if kf_imageSource != nil {
            return self
        }
#else
        if kf_images != nil {
            return self
        }
#endif
        
        let imageRef = self.cgImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
        
        let context = CGContext(data: nil, width: (imageRef?.width)!, height: (imageRef?.height)!, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)
        if let context = context {
            let rect = CGRect(x: 0, y: 0, width: (imageRef?.width)!, height: (imageRef?.height)!)
            context.draw(in: rect, image: imageRef!)
            let decompressedImageRef = context.makeImage()
            return Image.kf_image(cgImage: decompressedImageRef!, scale: scale, refImage: self)
        } else {
            return nil
        }
    }
}

/// Reference the source image reference
class ImageSource {
    var imageRef: CGImageSource?
    init(ref: CGImageSource) {
        self.imageRef = ref
    }
}

// MARK: - Image format
private struct ImageHeaderData {
    static var PNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    static var JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    static var JPEG_IF: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47, 0x49, 0x46]
}

enum ImageFormat {
    case unknown, PNG, JPEG, GIF
}

extension Data {
    var kf_imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 8)
        (self as NSData).getBytes(&buffer, length: 8)
        if buffer == ImageHeaderData.PNG {
            return .PNG
        } else if buffer[0] == ImageHeaderData.JPEG_SOI[0] &&
            buffer[1] == ImageHeaderData.JPEG_SOI[1] &&
            buffer[2] == ImageHeaderData.JPEG_IF[0]
        {
            return .JPEG
        } else if buffer[0] == ImageHeaderData.GIF[0] &&
            buffer[1] == ImageHeaderData.GIF[1] &&
            buffer[2] == ImageHeaderData.GIF[2]
        {
            return .GIF
        }
        
        return .unknown
    }
}
