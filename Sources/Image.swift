//
//  Image.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/6.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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
#endif

#if !os(watchOS)
import CoreImage
#endif

import Accelerate
import CoreGraphics
import ImageIO

private var animatedImageDataKey: Void?

func getAssociatedObject<T>(_ object: Any, _ key: UnsafeRawPointer) -> T? {
    return objc_getAssociatedObject(object, key) as? T
}

func setRetainedAssociatedObject<T>(_ object: Any, _ key: UnsafeRawPointer, _ value: T) {
    objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

// MARK: - Image Properties
extension KingfisherClass where Base: Image {
    private(set) var animatedImageData: Data? {
        get { return getAssociatedObject(base, &animatedImageDataKey) }
        set { setRetainedAssociatedObject(base, &animatedImageDataKey, newValue) }
    }
    
    #if os(macOS)
    var cgImage: CGImage? {
        return base.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    var scale: CGFloat {
        return 1.0
    }
    
    private(set) var images: [Image]? {
        get { return getAssociatedObject(base, &imagesKey) }
        set { setRetainedAssociatedObject(base, &imagesKey, newValue) }
    }
    
    private(set) var duration: TimeInterval {
        get { return getAssociatedObject(base, &durationKey) ?? 0.0 }
        set { setRetainedAssociatedObject(base, &durationKey, newValue) }
    }
    
    var size: CGSize {
        return base.representations.reduce(.zero) { size, rep in
            let width = max(size.width, CGFloat(rep.pixelsWide))
            let height = max(size.height, CGFloat(rep.pixelsHigh))
            return CGSize(width: width, height: height)
        }
    }
    #else
    var cgImage: CGImage? { return base.cgImage }
    var scale: CGFloat { return base.scale }
    var images: [Image]? { return base.images }
    var duration: TimeInterval { return base.duration }
    var size: CGSize { return base.size }
    
    private(set) var imageSource: CGImageSource? {
        get { return getAssociatedObject(base, &imageSourceKey) }
        set { setRetainedAssociatedObject(base, &imageSourceKey, newValue) }
    }
    #endif
}

// MARK: - Image Conversion
extension KingfisherClass where Base: Image {
    #if os(macOS)
    static func image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
        return Image(cgImage: cgImage, size: .zero)
    }
    
    /// Normalize the image. This getter does nothing on macOS but return the image itself.
    public var normalized: Image { return base }

    #else
    /// Creating an image from a give `CGImage` at scale and orientation for refImage. The method signature is for
    /// compability of macOS version.
    static func image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
        return Image(cgImage: cgImage, scale: scale, orientation: refImage?.imageOrientation ?? .up)
    }
    
    /// Normalized image of current `base`.
    /// This method will try to redraw an image with orientation and scale considered.
    public var normalized: Image {
        // prevent animated image (GIF) lose it's images
        guard images == nil else { return base }
        // No need to do anything if already up
        guard base.imageOrientation != .up else { return base }
    
        return draw(to: size) {
            base.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    #endif
}

// MARK: - Image Representation
extension KingfisherClass where Base: Image {
    // MARK: - PNG
    
    /// Returns PNG representation of `base` image.
    ///
    /// - Returns: PNG data of image.
    public func pngRepresentation() -> Data? {
        #if os(macOS)
            guard let cgimage = cgImage else {
                return nil
            }
            let rep = NSBitmapImageRep(cgImage: cgimage)
            return rep.representation(using: .png, properties: [:])
        #else
            return base.pngData()
        #endif
    }
    
    // MARK: - JPEG
    
    /// Returns JPEG representation of `base` image.
    ///
    /// - Parameter compressionQuality: The compression quality when converting image to JPEG data.
    /// - Returns: JPEG data of image.
    public func jpegRepresentation(compressionQuality: CGFloat) -> Data? {
        #if os(macOS)
            guard let cgImage = cgImage else {
                return nil
            }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using:.jpeg, properties: [.compressionFactor: compressionQuality])
        #else
            return base.jpegData(compressionQuality: compressionQuality)
        #endif
    }
    
    // MARK: - GIF
    
    /// Returns GIF representation of `base` image.
    ///
    /// - Returns: Original GIF data of image.
    public func gifRepresentation() -> Data? {
        return animatedImageData
    }
}

// MARK: - Create images from data
extension KingfisherClass where Base: Image {

    /// Creates an animated image from a given data and options. Currently only GIF data is supported.
    ///
    /// - Parameters:
    ///   - data: The animated image data.
    ///   - options: Options to use when creating the animated image.
    /// - Returns: An `Image` object represents the animated image. It is in form of an array of image frames with a
    ///            certain duration. `nil` if anything wrong when creating animated image.
    public static func animatedImage(data: Data, options: ImageCreatingOptions) -> Image? {
        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, info as CFDictionary) else {
            return nil
        }
        
        #if os(macOS)
        guard let animatedImage = GIFAnimatedImage(from: imageSource, for: info, options: options) else {
            return nil
        }
        let image: Image?
        if options.onlyFirstFrame {
            image = animatedImage.images.first
        } else {
            image = Image(data: data)
            let kf = image?.kf
            kf?.images = animatedImage.images
            kf?.duration = animatedImage.duration
        }
        image?.kf.animatedImageData = data
        return image
        #else
        
        let image: Image?
        if options.preloadAll || options.onlyFirstFrame {
            // Use `images` image if you want to preload all animated data
            guard let animatedImage = GIFAnimatedImage(from: imageSource, for: info, options: options) else {
                return nil
            }
            if options.onlyFirstFrame {
                image = animatedImage.images.first
            } else {
                let duration = options.duration <= 0.0 ? animatedImage.duration : options.duration
                image = .animatedImage(with: animatedImage.images, duration: duration)
            }
            image?.kf.animatedImageData = data
        } else {
            image = Image(data: data)
            let kf = image?.kf
            kf?.imageSource = imageSource
            kf?.animatedImageData = data
        }
        
        return image
        #endif
    }
    
    @available(*, deprecated, message:
    "Pass parameters with `ImageCreatingOptions`, use `animatedImage(with:options:)` instead.")
    public static func animated(
        with data: Data,
        scale: CGFloat = 1.0,
        duration: TimeInterval = 0.0,
        preloadAll: Bool,
        onlyFirstFrame: Bool = false) -> Image?
    {
        let options = ImageCreatingOptions(
            scale: scale, duration: duration, preloadAll: preloadAll, onlyFirstFrame: onlyFirstFrame)
        return animatedImage(data: data, options: options)
    }

    public static func image(data: Data, options: ImageCreatingOptions) -> Image? {
        var image: Image?
        switch data.kf.imageFormat {
        case .JPEG:
            image = Image(data: data, scale: options.scale)
        case .PNG:
            image = Image(data: data, scale: options.scale)
        case .GIF:
            image = KingfisherClass.animatedImage(data: data, options: options)
        case .unknown:
            image = Image(data: data, scale: options.scale)
        }
        return image
    }
    
    @available(*, deprecated, message:
    "Pass parameters with `ImageCreatingOptions`, use `image(with:options:)` instead.")
    public static func image(
        data: Data,
        scale: CGFloat,
        preloadAllAnimationData: Bool,
        onlyFirstFrame: Bool) -> Image?
    {
        let options = ImageCreatingOptions(
            scale: scale,
            duration: 0.0,
            preloadAll: preloadAllAnimationData,
            onlyFirstFrame: onlyFirstFrame)
        return KingfisherClass.image(data: data, options: options)
    }
}

#if os(macOS)
extension Image {
    // macOS does not support scale. This is just for code compatibility accross platforms.
    convenience init?(data: Data, scale: CGFloat) {
        self.init(data: data)
    }
}
#endif

// MARK: - Image Transforming
extension KingfisherClass where Base: Image {
    // MARK: - Blend Mode
    /// Create image from `base` image and apply blend mode.
    ///
    /// - parameter blendMode:       The blend mode of creating image.
    /// - parameter alpha:           The alpha should be used for image.
    /// - parameter backgroundColor: The background color for the output image.
    ///
    /// - returns: An image with blend mode applied.
    ///
    /// - Note: This method only works for CG-based image.
    #if !os(macOS)
    public func image(withBlendMode blendMode: CGBlendMode,
                      alpha: CGFloat = 1.0,
                      backgroundColor: Color? = nil) -> Image
    {
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Blend mode image only works for CG-based image.")
            return base
        }

        let rect = CGRect(origin: .zero, size: size)
        return draw(cgImage: cgImage, to: rect.size) {
            if let backgroundColor = backgroundColor {
                backgroundColor.setFill()
                UIRectFill(rect)
            }

            base.draw(in: rect, blendMode: blendMode, alpha: alpha)
        }
    }
    #endif
    
    #if os(macOS)
    // MARK: - Compositing Operation
    /// Creates image from `base` image and apply compositing operation.
    ///
    /// - Parameters:
    ///   - compositingOperation: The compositing operation of creating image.
    ///   - alpha: The alpha should be used for image.
    ///   - backgroundColor: The background color for the output image.
    /// - Returns: An image with compositing operation applied.
    ///
    /// - Note: This method only works for CG-based image. For any non-CG-based image, `base` itself is returned.
    public func image(withCompositingOperation compositingOperation: NSCompositingOperation,
                      alpha: CGFloat = 1.0,
                      backgroundColor: Color? = nil) -> Image
    {
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Compositing Operation image only works for CG-based image.")
            return base
        }

        let rect = CGRect(origin: .zero, size: size)
        return draw(cgImage: cgImage, to: rect.size) {
            if let backgroundColor = backgroundColor {
                backgroundColor.setFill()
                rect.fill()
            }

            base.draw(in: rect, from: .zero, operation: compositingOperation, fraction: alpha)
        }
    }
    #endif

    // MARK: - Round Corner
    /// Creates a round corner image from on `base` image.
    ///
    /// - Parameters:
    ///   - radius: The round corner radius of creating image.
    ///   - size: The target size of creating image.
    ///   - corners: The target corners which will be applied rounding.
    ///   - backgroundColor: The background color for the output image
    /// - Returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func image(withRoundRadius radius: CGFloat,
                      fit size: CGSize,
                      roundingCorners corners: RectCorner = .all,
                      backgroundColor: Color? = nil) -> Image
    {   
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Round corner image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(cgImage: cgImage, to: size) {
            #if os(macOS)
                if let backgroundColor = backgroundColor {
                    let rectPath = NSBezierPath(rect: rect)
                    backgroundColor.setFill()
                    rectPath.fill()
                }

                let path = NSBezierPath(roundedRect: rect, byRoundingCorners: corners, radius: radius)
                path.windingRule = .evenOdd
                path.addClip()
                base.draw(in: rect)
            #else
                guard let context = UIGraphicsGetCurrentContext() else {
                    assertionFailure("[Kingfisher] Failed to create CG context for image.")
                    return
                }

                if let backgroundColor = backgroundColor {
                    let rectPath = UIBezierPath(rect: rect)
                    backgroundColor.setFill()
                    rectPath.fill()
                }

                let path = UIBezierPath(roundedRect: rect,
                                        byRoundingCorners: corners.uiRectCorner,
                                        cornerRadii: CGSize(width: radius, height: radius)).cgPath
                context.addPath(path)
                context.clip()
                base.draw(in: rect)
            #endif
        }
    }
    
    #if os(iOS) || os(tvOS)
    func resize(to size: CGSize, for contentMode: UIView.ContentMode) -> Image {
        switch contentMode {
        case .scaleAspectFit:
            return resize(to: size, for: .aspectFit)
        case .scaleAspectFill:
            return resize(to: size, for: .aspectFill)
        default:
            return resize(to: size)
        }
    }
    #endif
    
    // MARK: - Resize
    /// Resizes `base` image to an image with new size.
    ///
    /// - Parameter size: The target size.
    /// - Returns: An image with new size.
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func resize(to size: CGSize) -> Image {
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Resize only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(cgImage: cgImage, to: size) {
            #if os(macOS)
                base.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
            #else
                base.draw(in: rect)
            #endif
        }
    }
    
    /// Resizes `base` image to an image of new size, respecting the given content mode.
    ///
    /// - Parameters:
    ///   - size: The target size.
    ///   - contentMode: Content mode of output image should be.
    /// - Returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func resize(to size: CGSize, for contentMode: ContentMode) -> Image {
        switch contentMode {
        case .aspectFit:
            let newSize = self.size.kf.constrained(size)
            return resize(to: newSize)
        case .aspectFill:
            let newSize = self.size.kf.filling(size)
            return resize(to: newSize)
        case .none:
            return resize(to: size)
        }
    }
    
    
    /// Crops `base` image to a new size with a given anchor.
    ///
    /// - Parameters:
    ///   - size: The target size.
    ///   - anchor: The anchor point from which the size should be calculated.
    /// - Returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func crop(to size: CGSize, anchorOn anchor: CGPoint) -> Image {
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Crop only works for CG-based image.")
            return base
        }
        
        let rect = self.size.kf.constrainedRect(for: size, anchor: anchor)
        guard let image = cgImage.cropping(to: rect.scaled(scale)) else {
            assertionFailure("[Kingfisher] Cropping image failed.")
            return base
        }
        
        return KingfisherClass.image(cgImage: image, scale: scale, refImage: base)
    }
    
    // MARK: - Blur
    /// Creates an image with blur effect based on `base` image.
    ///
    /// - Parameter radius: The blur radius should be used when creating blur effect.
    /// - Returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func blurred(withRadius radius: CGFloat) -> Image {

        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Blur only works for CG-based image.")
            return base
        }
        
        // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
        // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
        // if d is odd, use three box-blurs of size 'd', centered on the output pixel.
        let s = Float(max(radius, 2.0))
        // We will do blur on a resized image (*0.5), so the blur radius could be half as well.
        
        // Fix the slow compiling time for Swift 3.
        // See https://github.com/onevcat/Kingfisher/issues/611
        let pi2 = 2 * Float.pi
        let sqrtPi2 = sqrt(pi2)
        var targetRadius = floor(s * 3.0 * sqrtPi2 / 4.0 + 0.5)
        
        if targetRadius.isEven { targetRadius += 1 }
        
        // Determine necessary iteration count by blur radius.
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
        
        func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
            let data = context.data
            let width = vImagePixelCount(context.width)
            let height = vImagePixelCount(context.height)
            let rowBytes = context.bytesPerRow
            
            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }

        guard let context = beginContext(size: size, scale: scale) else {
            assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
            return base
        }
        defer { endContext() }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        
        var inBuffer = createEffectBuffer(context)
        
        guard let outContext = beginContext(size: size, scale: scale) else {
            assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
            return base
        }
        defer { endContext() }
        var outBuffer = createEffectBuffer(outContext)
        
        for _ in 0 ..< iterations {
            let flag = vImage_Flags(kvImageEdgeExtend)
            vImageBoxConvolve_ARGB8888(
                &inBuffer, &outBuffer, nil, 0, 0, UInt32(targetRadius), UInt32(targetRadius), nil, flag)
            // Next inBuffer should be the outButter of current iteration
            (inBuffer, outBuffer) = (outBuffer, inBuffer)
        }
        
        #if os(macOS)
            let result = outContext.makeImage().flatMap {
                fixedForRetinaPixel(cgImage: $0, to: size)
            }
        #else
            let result = outContext.makeImage().flatMap {
                Image(cgImage: $0, scale: base.scale, orientation: base.imageOrientation)
            }
        #endif
        guard let blurredImage = result else {
            assertionFailure("[Kingfisher] Can not make an blurred image within this context.")
            return base
        }
        
        return blurredImage
    }
    
    // MARK: - Overlay
    /// Creates an image from `base` image with a color overlay layer.
    ///
    /// - Parameters:
    ///   - color: The color should be use to overlay.
    ///   - fraction: Fraction of input color. From 0.0 to 1.0. 0.0 means solid color,
    ///               1.0 means transparent overlay.
    /// - Returns: An image with a color overlay applied.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
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
                    rect.fill(using: .sourceAtop)
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
    /// Creates an image from `base` image with a color tint.
    ///
    /// - Parameter color: The color should be used to tint `base`
    /// - Returns: An image with a color tint applied.
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
    /// - Parameters:
    ///   - brightness: Brightness changing to image.
    ///   - contrast: Contrast changing to image.
    ///   - saturation: Saturation changing to image.
    ///   - inputEV: InputEV changing to image.
    /// - Returns:  An image with color control applied.
    public func adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> Image {
        #if os(watchOS)
            return base
        #else
            return apply(.colorControl((brightness, contrast, saturation, inputEV)))
        #endif
    }

    /// Return an image with given scale.
    ///
    /// - Parameter scale: Target scale factor the new image should have.
    /// - Returns: The image with target scale. If the base image is already in the scale, `base` will be returned.
    public func scaled(to scale: CGFloat) -> Image {
        guard scale != self.scale else {
            return base
        }
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Scaling only works for CG-based image.")
            return base
        }
        return KingfisherClass.image(cgImage: cgImage, scale: scale, refImage: base)
    }
}

// MARK: - Decode
extension KingfisherClass where Base: Image {
    
    /// Returns the decoded image of the `base` image. It will draw the image in a plain context and return the data
    /// from it. This could improve the drawing performance when an image is just created from data but not yet
    /// displayed for the first time.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public var decoded: Image { return decoded(scale: scale) }
    
    /// Returns decoded image of the `base` image at a given scale. It will draw the image in a plain context and
    /// return the data from it. This could improve the drawing performance when an image is just created from
    /// data but not yet displayed for the first time.
    ///
    /// - Parameter scale: The given scale of target image should be.
    /// - Returns: The decoded image ready to be displayed.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public func decoded(scale: CGFloat) -> Image {
        // Prevent animated image (GIF) losing it's images
        #if os(iOS)
            if imageSource != nil { return base }
        #else
            if images != nil { return base }
        #endif
        
        guard let imageRef = self.cgImage else {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }
        
        // Draw CGImage in a plain context with scale of 1.0.
        guard let context = beginContext(
            size: CGSize(width: imageRef.width, height: imageRef.height), scale: 1.0) else
        {
            assertionFailure("[Kingfisher] Decoding fails to create a valid context.")
            return base
        }
        
        defer { endContext() }
        
        let rect = CGRect(x: 0, y: 0, width: CGFloat(imageRef.width), height: CGFloat(imageRef.height))
        context.draw(imageRef, in: rect)
        let decompressedImageRef = context.makeImage()
        return KingfisherClass.image(cgImage: decompressedImageRef!, scale: scale, refImage: base)
    }
}

// MARK: - Image format
private struct ImageHeaderData {
    static var PNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    static var JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    static var JPEG_IF: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47, 0x49, 0x46]
}


/// Represents image format.
///
/// - unknown: The format cannot be recognized or not supported yet.
/// - PNG: PNG image format.
/// - JPEG: JPEG image format.
/// - GIF: GIF image format.
public enum ImageFormat {
    case unknown, PNG, JPEG, GIF
}

// MARK: - Misc Helpers
extension Data: KingfisherStructCompatible {}
extension KingfisherStruct where Base == Data {
    
    /// Gets the image format corresponding to the data.
    public var imageFormat: ImageFormat {
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

extension CGSize: KingfisherStructCompatible {}
extension KingfisherStruct where Base == CGSize {

    public func resize(to size: CGSize, for contentMode: ContentMode) -> CGSize {
        switch contentMode {
        case .aspectFit:
            return constrained(size)
        case .aspectFill:
            return filling(size)
        case .none:
            return base
        }
    }
    
    public func constrained(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)

        return aspectWidth > size.width ?
            CGSize(width: size.width, height: aspectHeight) :
            CGSize(width: aspectWidth, height: size.height)
    }

    public func filling(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)

        return aspectWidth < size.width ?
            CGSize(width: size.width, height: aspectHeight) :
            CGSize(width: aspectWidth, height: size.height)
    }
    
    public func constrainedRect(for size: CGSize, anchor: CGPoint) -> CGRect {
        
        let unifiedAnchor = CGPoint(x: anchor.x.clamped(to: 0.0...1.0),
                                    y: anchor.y.clamped(to: 0.0...1.0))
        
        let x = unifiedAnchor.x * base.width - unifiedAnchor.x * size.width
        let y = unifiedAnchor.y * base.height - unifiedAnchor.y * size.height
        let r = CGRect(x: x, y: y, width: size.width, height: size.height)
        
        let ori = CGRect(origin: .zero, size: base)
        return ori.intersection(r)
    }
    
    private var aspectRatio: CGFloat {
        return base.height == 0.0 ? 1.0 : base.width / base.height
    }
}

extension CGRect {
    func scaled(_ scale: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scale, y: origin.y * scale,
                      width: size.width * scale, height: size.height * scale)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension KingfisherClass where Base: Image {
    
    func beginContext(size: CGSize, scale: CGFloat) -> CGContext? {
        #if os(macOS)
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(size.width),
                pixelsHigh: Int(size.height),
                bitsPerSample: cgImage?.bitsPerComponent ?? 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .calibratedRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0) else
            {
                assertionFailure("[Kingfisher] Image representation cannot be created.")
                return nil
            }
            rep.size = size
            NSGraphicsContext.saveGraphicsState()
            guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
                assertionFailure("[Kingfisher] Image contenxt cannot be created.")
                return nil
            }
            
            NSGraphicsContext.current = context
            return context.cgContext
        #else
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -size.height)
            return context
        #endif
    }
    
    func endContext() {
        #if os(macOS)
            NSGraphicsContext.restoreGraphicsState()
        #else
            UIGraphicsEndImageContext()
        #endif
    }
    
    func draw(cgImage: CGImage? = nil, to size: CGSize, draw: ()->()) -> Image {
        #if os(macOS)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: cgImage?.bitsPerComponent ?? 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0) else
        {
            assertionFailure("[Kingfisher] Image representation cannot be created.")
            return base
        }
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context
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

extension Float {
    var isEven: Bool {
        return truncatingRemainder(dividingBy: 2.0) == 0
    }
}

#if os(macOS)
extension NSBezierPath {
    convenience init(roundedRect rect: NSRect, topLeftRadius: CGFloat, topRightRadius: CGFloat,
         bottomLeftRadius: CGFloat, bottomRightRadius: CGFloat)
    {
        self.init()
        
        let maxCorner = min(rect.width, rect.height) / 2
        
        let radiusTopLeft = min(maxCorner, max(0, topLeftRadius))
        let radiusTopRight = min(maxCorner, max(0, topRightRadius))
        let radiusBottomLeft = min(maxCorner, max(0, bottomLeftRadius))
        let radiusBottomRight = min(maxCorner, max(0, bottomRightRadius))
        
        guard !NSIsEmptyRect(rect) else {
            return
        }
        
        let topLeft = NSPoint(x: rect.minX, y: rect.maxY)
        let topRight = NSPoint(x: rect.maxX, y: rect.maxY)
        let bottomRight = NSPoint(x: rect.maxX, y: rect.minY)
        
        move(to: NSPoint(x: rect.midX, y: rect.maxY))
        appendArc(from: topLeft, to: rect.origin, radius: radiusTopLeft)
        appendArc(from: rect.origin, to: bottomRight, radius: radiusBottomLeft)
        appendArc(from: bottomRight, to: topRight, radius: radiusBottomRight)
        appendArc(from: topRight, to: topLeft, radius: radiusTopRight)
        close()
    }
    
    convenience init(roundedRect rect: NSRect, byRoundingCorners corners: RectCorner, radius: CGFloat) {
        let radiusTopLeft = corners.contains(.topLeft) ? radius : 0
        let radiusTopRight = corners.contains(.topRight) ? radius : 0
        let radiusBottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let radiusBottomRight = corners.contains(.bottomRight) ? radius : 0
        
        self.init(roundedRect: rect, topLeftRadius: radiusTopLeft, topRightRadius: radiusTopRight,
                  bottomLeftRadius: radiusBottomLeft, bottomRightRadius: radiusBottomRight)
    }
}
    
#else
extension RectCorner {
    var uiRectCorner: UIRectCorner {
        
        var result: UIRectCorner = []
        
        if contains(.topLeft) { result.insert(.topLeft) }
        if contains(.topRight) { result.insert(.topRight) }
        if contains(.bottomLeft) { result.insert(.bottomLeft) }
        if contains(.bottomRight) { result.insert(.bottomRight) }
        
        return result
    }
}
#endif

