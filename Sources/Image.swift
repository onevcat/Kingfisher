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


#if os(macOS)
import AppKit
private var imagesKey: Void?
private var durationKey: Void?
#else
import UIKit
import MobileCoreServices
private var imageSourceKey: Void?
private var animatedImageDataKey: Void?
#endif

import ImageIO
import CoreGraphics

#if !os(watchOS)
import Accelerate
import CoreImage
#endif

// MARK: - Image Properties
extension Kingfisher where Base: Image {
    #if os(macOS)
    var cgImage: CGImage? {
        return base.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    var scale: CGFloat {
        return 1.0
    }
    
    fileprivate(set) var images: [Image]? {
        get {
            return objc_getAssociatedObject(base, &imagesKey) as? [Image]
        }
        set {
            objc_setAssociatedObject(base, &imagesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate(set) var duration: TimeInterval {
        get {
            return objc_getAssociatedObject(base, &durationKey) as? TimeInterval ?? 0.0
        }
        set {
            objc_setAssociatedObject(base, &durationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var size: CGSize {
        return base.representations.reduce(CGSize.zero, { size, rep in
            return CGSize(width: max(size.width, CGFloat(rep.pixelsWide)), height: max(size.height, CGFloat(rep.pixelsHigh)))
        })
    }
    
    #else
    var cgImage: CGImage? {
        return base.cgImage
    }
    
    var scale: CGFloat {
    return base.scale
    }
    
    var images: [Image]? {
    return base.images
    }
    
    var duration: TimeInterval {
    return base.duration
    }
    
    fileprivate(set) var imageSource: ImageSource? {
        get {
            return objc_getAssociatedObject(base, &imageSourceKey) as? ImageSource
        }
        set {
            objc_setAssociatedObject(base, &imageSourceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate(set) var animatedImageData: Data? {
    get {
        return objc_getAssociatedObject(base, &animatedImageDataKey) as? Data
    }
    set {
        objc_setAssociatedObject(base, &animatedImageDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    }
    
    var size: CGSize {
        return base.size
    }
    #endif
}

// MARK: - Image Conversion
extension Kingfisher where Base: Image {
    #if os(macOS)
    static func image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
        return Image(cgImage: cgImage, size: CGSize.zero)
    }
    
    /**
     Normalize the image. This method does nothing in OS X.
     
     - returns: The image itself.
     */
    public var normalized: Image {
        return base
    }
    
    static func animated(with images: [Image], forDuration forDurationduration: TimeInterval) -> Image? {
        return nil
    }
    #else
    static func image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
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
    public var normalized: Image {
        // prevent animated image (GIF) lose it's images
        guard images == nil else { return base }
        // No need to do anything if already up
        guard base.imageOrientation != .up else { return base }
    
        return draw(cgImage: nil, to: size) {
            base.draw(in: CGRect(origin: CGPoint.zero, size: size))
        }
    }
    
    static func animated(with images: [Image], forDuration duration: TimeInterval) -> Image? {
        return .animatedImage(with: images, duration: duration)
    }
    #endif
}

// MARK: - Image Representation
extension Kingfisher where Base: Image {
    // MARK: - PNG
    func pngRepresentation() -> Data? {
        #if os(macOS)
            guard let cgimage = cgImage else {
                return nil
            }
            let rep = NSBitmapImageRep(cgImage: cgimage)
            return rep.representation(using: .PNG, properties: [:])
        #else
            return UIImagePNGRepresentation(base)
        #endif
    }
    
    // MARK: - JPEG
    func jpegRepresentation(compressionQuality: CGFloat) -> Data? {
        #if os(macOS)
            guard let cgImage = cgImage else {
                return nil
            }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using:.JPEG, properties: [NSImageCompressionFactor: compressionQuality])
        #else
            return UIImageJPEGRepresentation(base, compressionQuality)
        #endif
    }
    
    // MARK: - GIF
    func gifRepresentation() -> Data? {
        #if os(macOS)
            return gifRepresentation(duration: 0.0, repeatCount: 0)
        #else
            return animatedImageData
        #endif
    }
    
    #if os(macOS)
    func gifRepresentation(duration: TimeInterval, repeatCount: Int) -> Data? {
        guard let images = images else {
            return nil
        }
        
        let frameCount = images.count
        let gifDuration = duration <= 0.0 ? duration / Double(frameCount) : duration / Double(frameCount)
        
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: gifDuration]]
        let imageProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: repeatCount]]
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, frameCount, nil) else {
            return nil
        }
        CGImageDestinationSetProperties(destination, imageProperties as CFDictionary)
        
        for image in images {
            CGImageDestinationAddImage(destination, image.kf.cgImage!, frameProperties as CFDictionary)
        }
        
        return CGImageDestinationFinalize(destination) ? data.copy() as? Data : nil
    }
    #endif
}

// MARK: - Create images from data
extension Kingfisher where Base: Image {
    static func animated(with data: Data, scale: CGFloat = 1.0, duration: TimeInterval = 0.0, preloadAll: Bool) -> Image? {
        
        func decode(from imageSource: CGImageSource, for options: NSDictionary) -> ([Image], TimeInterval)? {
            
            //Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary
            func frameDuration(from gifInfo: NSDictionary) -> Double {
                let gifDefaultFrameDuration = 0.100
                
                let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
                let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
                let duration = unclampedDelayTime ?? delayTime
                
                guard let frameDuration = duration else { return gifDefaultFrameDuration }
                
                return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : gifDefaultFrameDuration
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
                        let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary else
                    {
                        return nil
                    }
                    gifDuration += frameDuration(from: gifInfo)
                }
                
                images.append(Kingfisher<Image>.image(cgImage: imageRef, scale: scale, refImage: nil))
            }
            
            return (images, gifDuration)
        }
        
        // Start of kf.animatedImageWithGIFData
        let options: NSDictionary = [kCGImageSourceShouldCache as String: true, kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options) else {
            return nil
        }
        
        #if os(macOS)
            guard let (images, gifDuration) = decode(from: imageSource, for: options) else {
                return nil
            }
            let image = Image(data: data)
            image?.kf.images = images
            image?.kf.duration = gifDuration
            
            return image
        #else
            
            if preloadAll {
                guard let (images, gifDuration) = decode(from: imageSource, for: options) else {
                    return nil
                }
                let image = Kingfisher<Image>.animated(with: images, forDuration: duration <= 0.0 ? gifDuration : duration)
                image?.kf.animatedImageData = data
                return image
            } else {
                let image = Image(data: data)
                image?.kf.animatedImageData = data
                image?.kf.imageSource = ImageSource(ref: imageSource)
                return image
            }
        #endif
    }
    
    static func image(data: Data, scale: CGFloat, preloadAllGIFData: Bool) -> Image? {
        var image: Image?
        
        #if os(macOS)
            switch data.kf.imageFormat {
            case .JPEG: image = Image(data: data)
            case .PNG: image = Image(data: data)
            case .GIF: image = Kingfisher<Image>.animated(with: data, scale: scale, duration: 0.0, preloadAll: preloadAllGIFData)
            case .unknown: image = Image(data: data)
            }
        #else
            switch data.kf.imageFormat {
            case .JPEG: image = Image(data: data, scale: scale)
            case .PNG: image = Image(data: data, scale: scale)
            case .GIF: image = Kingfisher<Image>.animated(with: data, scale: scale, duration: 0.0, preloadAll: preloadAllGIFData)
            case .unknown: image = Image(data: data, scale: scale)
            }
        #endif
        
        return image
    }
}

// MARK: - Image Transforming
extension Kingfisher where Base: Image {

    // MARK: - Round Corner
    /// Create a round corner image based on `self`.
    ///
    /// - parameter radius: The round corner radius of creating image.
    /// - parameter size:   The target size of creating image.
    ///
    /// - returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image.
    public func image(withRoundRadius radius: CGFloat, fit size: CGSize) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Round corder image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(cgImage: cgImage, to: size) {
            #if os(macOS)
                let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
                path.windingRule = .evenOddWindingRule
                path.addClip()
                base.draw(in: rect)
            #else
                guard let context = UIGraphicsGetCurrentContext() else {
                    assertionFailure("[Kingfisher] Failed to create CG context for image.")
                    return
                }
                let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius)).cgPath
                context.addPath(path)
                context.clip()
                base.draw(in: rect)
            #endif
        }
    }
    
    #if os(iOS) || os(tvOS)
    func resize(to size: CGSize, for contentMode: UIViewContentMode) -> Image {
        switch contentMode {
        case .scaleAspectFit:
            let newSize = self.size.kf.constrained(size)
            return resize(to: newSize)
        case .scaleAspectFill:
            let newSize = self.size.kf.filling(size)
            return resize(to: newSize)
        default:
            return resize(to: size)
        }
    }
    #endif
    
    // MARK: - Resize
    
    /// Resize `self` to an image of new size.
    ///
    /// - parameter size: The target size.
    ///
    /// - returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image.
    public func resize(to size: CGSize) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Resize only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(cgImage: cgImage, to: size) {
            #if os(macOS)
                base.draw(in: rect, from: NSRect.zero, operation: .copy, fraction: 1.0)
            #else
                base.draw(in: rect)
            #endif
        }
    }
    
    // MARK: - Blur
    
    /// Create an image with blur effect based on `self`.
    ///
    /// - parameter radius: The blur radius should be used when creating blue.
    ///
    /// - returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image.
    public func blurred(withRadius radius: CGFloat) -> Image {
        #if os(watchOS)
            return base
        #else
            guard let cgImage = cgImage else {
                assertionFailure("[Kingfisher] Blur only works for CG-based image.")
                return base
            }
            
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            // if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            let s = max(radius, 2.0)
            // We will do blur on a resized image (*0.5), so the blur radius could be half as well.
            var targetRadius = floor((Double(s * 3.0) * sqrt(2 * M_PI) / 4.0 + 0.5))
            
            if targetRadius.isEven {
                targetRadius += 1
            }
            
            let iterations: Int
            if radius < 0.5 {
                iterations = 1
            } else if radius < 1.5 {
                iterations = 2
            } else {
                iterations = 3
            }
            
            let w = Int(size.width)
            let h = Int(size.height)
            let rowBytes = Int(CGFloat(cgImage.bytesPerRow))
            
            let inDataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: rowBytes * Int(h))
            inDataPointer.initialize(to: 0)
            defer {
                inDataPointer.deinitialize()
                inDataPointer.deallocate(capacity: rowBytes * Int(h))
        }
            
            let bitmapInfo = cgImage.bitmapInfo.fixed
            guard let context = CGContext(data: inDataPointer,
                                          width: w,
                                          height: h,
                                          bitsPerComponent: cgImage.bitsPerComponent,
                                          bytesPerRow: rowBytes,
                                          space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: bitmapInfo.rawValue) else
            {
                assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
                return base
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
            
            
            var inBuffer = vImage_Buffer(data: inDataPointer, height: vImagePixelCount(h), width: vImagePixelCount(w), rowBytes: rowBytes)
            
            let outDataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: rowBytes * Int(h))
            outDataPointer.initialize(to: 0)
            defer {
                outDataPointer.deinitialize()
                outDataPointer.deallocate(capacity: rowBytes * Int(h))
        }
            
            var outBuffer = vImage_Buffer(data: outDataPointer, height: vImagePixelCount(h), width: vImagePixelCount(w), rowBytes: rowBytes)
            
            for _ in 0 ..< iterations {
                vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, UInt32(targetRadius), UInt32(targetRadius), nil, vImage_Flags(kvImageEdgeExtend))
                (inBuffer, outBuffer) = (outBuffer, inBuffer)
            }
            
            guard let outContext = CGContext(data: inDataPointer,
                                             width: w,
                                             height: h,
                                             bitsPerComponent: cgImage.bitsPerComponent,
                                             bytesPerRow: rowBytes,
                                             space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: bitmapInfo.rawValue) else
            {
                assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
                return base
            }
            
            #if os(macOS)
                let result = outContext.makeImage().flatMap { fixedForRetinaPixel(cgImage: $0, to: size) }
            #else
                let result = outContext.makeImage().flatMap { Image(cgImage: $0, scale: base.scale, orientation: base.imageOrientation) }
            #endif
            guard let blurredImage = result else {
                assertionFailure("[Kingfisher] Can not make an blurred image within this context.")
                return base
            }
            
            return blurredImage
        #endif
    }
    
    // MARK: - Overlay
    
    /// Create an image from `self` with a color overlay layer.
    ///
    /// - parameter color:    The color should be use to overlay.
    /// - parameter fraction: Fraction of input color. From 0.0 to 1.0. 0.0 means solid color, 1.0 means transparent overlay.
    ///
    /// - returns: An image with a color overlay applied.
    ///
    /// - Note: This method only works for CG-based image.
    public func overlaying(with color: Color, fraction: CGFloat) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Overlaying only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return draw(cgImage: cgImage, to: rect.size) {
            #if os(macOS)
                base.draw(in: rect)
                if fraction > 0 {
                    color.withAlphaComponent(1 - fraction).set()
                    NSRectFillUsingOperation(rect, .sourceAtop)
                }
            #else
                color.set()
                UIRectFill(rect)
                base.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
                
                if fraction > 0 {
                    base.draw(in: rect, blendMode: .sourceAtop, alpha: fraction)
                }
            #endif
        }
    }
    
    // MARK: - Tint
    
    /// Create an image from `self` with a color tint.
    ///
    /// - parameter color: The color should be used to tint `self`
    ///
    /// - returns: An image with a color tint applied.
    public func tinted(with color: Color) -> Image {
        #if os(watchOS)
            return base
        #else
            return apply(.tint(color))
        #endif
    }
    
    // MARK: - Color Control
    
    /// Create an image from `self` with color control.
    ///
    /// - parameter brightness: Brightness changing to image.
    /// - parameter contrast:   Contrast changing to image.
    /// - parameter saturation: Saturation changing to image.
    /// - parameter inputEV:    InputEV changing to image.
    ///
    /// - returns: An image with color control applied.
    public func adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> Image {
        #if os(watchOS)
            return base
        #else
            return apply(.colorControl(brightness, contrast, saturation, inputEV))
        #endif
    }
}

// MARK: - Decode
extension Kingfisher where Base: Image {
    var decoded: Image? {
        return decoded(scale: scale)
    }
    
    func decoded(scale: CGFloat) -> Image {
        // prevent animated image (GIF) lose it's images
        #if os(iOS)
            if imageSource != nil { return base }
        #else
            if images != nil { return base }
        #endif
        
        guard let imageRef = self.cgImage else {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = imageRef.bitmapInfo.fixed
        
        guard let context = CGContext(data: nil, width: imageRef.width, height: imageRef.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            assertionFailure("[Kingfisher] Decoding fails to create a valid context.")
            return base
        }
        
        let rect = CGRect(x: 0, y: 0, width: imageRef.width, height: imageRef.height)
        context.draw(imageRef, in: rect)
        let decompressedImageRef = context.makeImage()
        return Kingfisher<Image>.image(cgImage: decompressedImageRef!, scale: scale, refImage: base)
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


// MARK: - Misc Helpers
public struct DataProxy {
    fileprivate let base: Data
    init(proxy: Data) {
        base = proxy
    }
}

extension Data: KingfisherCompatible {
    public typealias CompatibleType = DataProxy
    public var kf: DataProxy {
        return DataProxy(proxy: self)
    }
}

extension DataProxy {
    var imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 8)
        (base as NSData).getBytes(&buffer, length: 8)
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

public struct CGSizeProxy {
    fileprivate let base: CGSize
    init(proxy: CGSize) {
        base = proxy
    }
}

extension CGSize: KingfisherCompatible {
    public typealias CompatibleType = CGSizeProxy
    public var kf: CGSizeProxy {
        return CGSizeProxy(proxy: self)
    }
}

extension CGSizeProxy {
    func constrained(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)

        return aspectWidth > size.width ? CGSize(width: size.width, height: aspectHeight) : CGSize(width: aspectWidth, height: size.height)
    }

    func filling(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)

        return aspectWidth < size.width ? CGSize(width: size.width, height: aspectHeight) : CGSize(width: aspectWidth, height: size.height)
    }

    private var aspectRatio: CGFloat {
        return base.height == 0.0 ? 1.0 : base.width / base.height
    }
}

extension CGBitmapInfo {
    var fixed: CGBitmapInfo {
        var fixed = self
        let alpha = (rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        if alpha == CGImageAlphaInfo.none.rawValue {
            fixed.remove(.alphaInfoMask)
            fixed = CGBitmapInfo(rawValue: fixed.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        } else if !(alpha == CGImageAlphaInfo.noneSkipFirst.rawValue) || !(alpha == CGImageAlphaInfo.noneSkipLast.rawValue) {
            fixed.remove(.alphaInfoMask)
            fixed = CGBitmapInfo(rawValue: fixed.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        }
        return fixed
    }
}


extension Kingfisher where Base: Image {
    
    func draw(cgImage: CGImage?, to size: CGSize, draw: ()->()) -> Image {
        #if os(macOS)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: cgImage?.bitsPerComponent ?? 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 0,
            bitsPerPixel: 0) else
        {
            assertionFailure("[Kingfisher] Image representation cannot be created.")
            return base
        }
        rep.size = size
        
        NSGraphicsContext.saveGraphicsState()
        
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.setCurrent(context)
        draw()
        NSGraphicsContext.restoreGraphicsState()
        
        let outputImage = Image(size: size)
        outputImage.addRepresentation(rep)
        return outputImage
        #else
            
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw()
        return UIGraphicsGetImageFromCurrentImageContext() ?? base
        
        #endif
    }
    
    #if os(macOS)
    func fixedForRetinaPixel(cgImage: CGImage, to size: CGSize) -> Image {
        
        let image = Image(cgImage: cgImage, size: base.size)
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        
        return draw(cgImage: cgImage, to: self.size) {
            image.draw(in: rect, from: NSRect.zero, operation: .copy, fraction: 1.0)
        }
    }
    #endif
}


extension CGContext {
    static func createARGBContext(from imageRef: CGImage) -> CGContext? {
        
        let w = imageRef.width
        let h = imageRef.height
        let bytesPerRow = w * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let data = malloc(bytesPerRow * h)
        defer {
            free(data)
        }
        
        let bitmapInfo = imageRef.bitmapInfo.fixed
        
        // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
        // per component. Regardless of what the source image format is
        // (CMYK, Grayscale, and so on) it will be converted over to the format
        // specified here.
        return CGContext(data: data,
                         width: w,
                         height: h,
                         bitsPerComponent: imageRef.bitsPerComponent,
                         bytesPerRow: bytesPerRow,
                         space: colorSpace,
                         bitmapInfo: bitmapInfo.rawValue)
    }
}

extension Double {
    var isEven: Bool {
        return truncatingRemainder(dividingBy: 2.0) == 0
    }
}

// MARK: - Deprecated. Only for back compatibility.
extension Image {
    /**
     Normalize the image. This method does nothing in OS X.
     
     - returns: The image itself.
     */
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.normalized` instead.",
    renamed: "kf.normalized")
    public func kf_normalized() -> Image {
        return kf.normalized
    }
    
    // MARK: - Round Corner
    
    /// Create a round corner image based on `self`.
    ///
    /// - parameter radius: The round corner radius of creating image.
    /// - parameter size:   The target size of creating image.
    /// - parameter scale:  The image scale of creating image.
    ///
    /// - returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.image(withRoundRadius:fit:scale:)` instead.",
    renamed: "kf.image")
    public func kf_image(withRoundRadius radius: CGFloat, fit size: CGSize, scale: CGFloat) -> Image {
        return kf.image(withRoundRadius: radius, fit: size)
    }
    
    // MARK: - Resize
    /// Resize `self` to an image of new size.
    ///
    /// - parameter size: The target size.
    ///
    /// - returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.resize(to:)` instead.",
    renamed: "kf.resize")
    public func kf_resize(to size: CGSize) -> Image {
        return kf.resize(to: size)
    }
    
    // MARK: - Blur
    /// Create an image with blur effect based on `self`.
    ///
    /// - parameter radius: The blur radius should be used when creating blue.
    ///
    /// - returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.blurred(withRadius:)` instead.",
    renamed: "kf.blurred")
    public func kf_blurred(withRadius radius: CGFloat) -> Image {
        return kf.blurred(withRadius: radius)
    }
    
    // MARK: - Overlay
    /// Create an image from `self` with a color overlay layer.
    ///
    /// - parameter color:    The color should be use to overlay.
    /// - parameter fraction: Fraction of input color. From 0.0 to 1.0. 0.0 means solid color, 1.0 means transparent overlay.
    ///
    /// - returns: An image with a color overlay applied.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.overlaying(with:fraction:)` instead.",
    renamed: "kf.overlaying")
    public func kf_overlaying(with color: Color, fraction: CGFloat) -> Image {
        return kf.overlaying(with: color, fraction: fraction)
    }
    
    // MARK: - Tint
    
    /// Create an image from `self` with a color tint.
    ///
    /// - parameter color: The color should be used to tint `self`
    ///
    /// - returns: An image with a color tint applied.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.tinted(with:)` instead.",
    renamed: "kf.tinted")
    public func kf_tinted(with color: Color) -> Image {
        return kf.tinted(with: color)
    }
    
    // MARK: - Color Control
    
    /// Create an image from `self` with color control.
    ///
    /// - parameter brightness: Brightness changing to image.
    /// - parameter contrast:   Contrast changing to image.
    /// - parameter saturation: Saturation changing to image.
    /// - parameter inputEV:    InputEV changing to image.
    ///
    /// - returns: An image with color control applied.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `kf.adjusted` instead.",
    renamed: "kf.adjusted")
    public func kf_adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> Image {
        return kf.adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
    }
}

extension Kingfisher where Base: Image {
    @available(*, deprecated,
    message: "`scale` is not used. Use the version without scale instead. (Remove the `scale` argument)")
    public func image(withRoundRadius radius: CGFloat, fit size: CGSize, scale: CGFloat) -> Image {
        return image(withRoundRadius: radius, fit: size)
    }
}
