//
//  ImageDrawing.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/28.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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

import Accelerate

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Image Transforming
extension KingfisherWrapper where Base: KFCrossPlatformImage {
    // MARK: Blend Mode
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
                      backgroundColor: KFCrossPlatformColor? = nil) -> KFCrossPlatformImage
    {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Blend mode image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: .zero, size: size)
        return draw(to: rect.size, inverting: false) { _ in
            if let backgroundColor = backgroundColor {
                backgroundColor.setFill()
                UIRectFill(rect)
            }
            
            base.draw(in: rect, blendMode: blendMode, alpha: alpha)
            return false
        }
    }
    #endif
    
    #if os(macOS)
    // MARK: Compositing
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
                      backgroundColor: KFCrossPlatformColor? = nil) -> KFCrossPlatformImage
    {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Compositing Operation image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: .zero, size: size)
        return draw(to: rect.size, inverting: false) { _ in
            if let backgroundColor = backgroundColor {
                backgroundColor.setFill()
                rect.fill()
            }
            base.draw(in: rect, from: .zero, operation: compositingOperation, fraction: alpha)
            return false
        }
    }
    #endif
    
    // MARK: Round Corner
    
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
    public func image(
        withRadius radius: Radius,
        fit size: CGSize,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> KFCrossPlatformImage
    {

        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Round corner image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(to: size, inverting: false) { _ in
            #if os(macOS)
            if let backgroundColor = backgroundColor {
                let rectPath = NSBezierPath(rect: rect)
                backgroundColor.setFill()
                rectPath.fill()
            }
            
            let path = pathForRoundCorner(rect: rect, radius: radius, corners: corners)
            path.addClip()
            base.draw(in: rect)
            #else
            guard let context = UIGraphicsGetCurrentContext() else {
                assertionFailure("[Kingfisher] Failed to create CG context for image.")
                return false
            }
            
            if let backgroundColor = backgroundColor {
                let rectPath = UIBezierPath(rect: rect)
                backgroundColor.setFill()
                rectPath.fill()
            }
            
            let path = pathForRoundCorner(rect: rect, radius: radius, corners: corners)
            context.addPath(path.cgPath)
            context.clip()
            base.draw(in: rect)
            #endif
            return false
        }
    }
    
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
    public func image(
        withRoundRadius radius: CGFloat,
        fit size: CGSize,
        roundingCorners corners: RectCorner = .all,
        backgroundColor: KFCrossPlatformColor? = nil
    ) -> KFCrossPlatformImage
    {
        image(withRadius: .point(radius), fit: size, roundingCorners: corners, backgroundColor: backgroundColor)
    }
    
    #if os(macOS)
    func pathForRoundCorner(rect: CGRect, radius: Radius, corners: RectCorner, offsetBase: CGFloat = 0) -> NSBezierPath {
        let cornerRadius = radius.compute(with: rect.size)
        let path = NSBezierPath(roundedRect: rect, byRoundingCorners: corners, radius: cornerRadius - offsetBase / 2)
        path.windingRule = .evenOdd
        return path
    }
    #else
    func pathForRoundCorner(rect: CGRect, radius: Radius, corners: RectCorner, offsetBase: CGFloat = 0) -> UIBezierPath {
        let cornerRadius = radius.compute(with: rect.size)
        return UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners.uiRectCorner,
            cornerRadii: CGSize(
                width: cornerRadius - offsetBase / 2,
                height: cornerRadius - offsetBase / 2
            )
        )
    }
    #endif
    
    #if os(iOS) || os(tvOS) || os(visionOS)
    func resize(to size: CGSize, for contentMode: UIView.ContentMode) -> KFCrossPlatformImage {
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
    
    // MARK: Resizing
    /// Resizes `base` image to an image with new size.
    ///
    /// - Parameter size: The target size in point.
    /// - Returns: An image with new size.
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func resize(to size: CGSize) -> KFCrossPlatformImage {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Resize only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(to: size, inverting: false) { _ in
            #if os(macOS)
            base.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
            #else
            base.draw(in: rect)
            #endif
            return false
        }
    }
    
    /// Resizes `base` image to an image of new size, respecting the given content mode.
    ///
    /// - Parameters:
    ///   - targetSize: The target size in point.
    ///   - contentMode: Content mode of output image should be.
    /// - Returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func resize(to targetSize: CGSize, for contentMode: ContentMode) -> KFCrossPlatformImage {
        let newSize = size.kf.resize(to: targetSize, for: contentMode)
        return resize(to: newSize)
    }

    // MARK: Cropping
    /// Crops `base` image to a new size with a given anchor.
    ///
    /// - Parameters:
    ///   - size: The target size.
    ///   - anchor: The anchor point from which the size should be calculated.
    /// - Returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func crop(to size: CGSize, anchorOn anchor: CGPoint) -> KFCrossPlatformImage {
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Crop only works for CG-based image.")
            return base
        }
        
        let rect = self.size.kf.constrainedRect(for: size, anchor: anchor)
        guard let image = cgImage.cropping(to: rect.scaled(scale)) else {
            assertionFailure("[Kingfisher] Cropping image failed.")
            return base
        }
        
        return KingfisherWrapper.image(cgImage: image, scale: scale, refImage: base)
    }
    
    // MARK: Blur
    /// Creates an image with blur effect based on `base` image.
    ///
    /// - Parameter radius: The blur radius should be used when creating blur effect.
    /// - Returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image, `base` itself is returned.
    public func blurred(withRadius radius: CGFloat) -> KFCrossPlatformImage {
        
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Blur only works for CG-based image.")
            return base
        }
        
        // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
        // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
        // if d is odd, use three box-blurs of size 'd', centered on the output pixel.
        let s = max(radius, 2.0)
        // We will do blur on a resized image (*0.5), so the blur radius could be half as well.
        
        // Fix the slow compiling time for Swift 3.
        // See https://github.com/onevcat/Kingfisher/issues/611
        let pi2 = 2 * CGFloat.pi
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
        
        func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
            let data = context.data
            let width = vImagePixelCount(context.width)
            let height = vImagePixelCount(context.height)
            let rowBytes = context.bytesPerRow
            
            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }
        GraphicsContext.begin(size: size, scale: scale)
        guard let context = GraphicsContext.current(size: size, scale: scale, inverting: true, cgImage: cgImage) else {
            assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
            return base
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        GraphicsContext.end()
        
        var inBuffer = createEffectBuffer(context)
        
        GraphicsContext.begin(size: size, scale: scale)
        guard let outContext = GraphicsContext.current(size: size, scale: scale, inverting: true, cgImage: cgImage) else {
            assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
            return base
        }
        defer { GraphicsContext.end() }
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
            KFCrossPlatformImage(cgImage: $0, scale: base.scale, orientation: base.imageOrientation)
        }
        #endif
        guard let blurredImage = result else {
            assertionFailure("[Kingfisher] Can not make an blurred image within this context.")
            return base
        }
        
        return blurredImage
    }
    
    public func addingBorder(_ border: Border) -> KFCrossPlatformImage
    {
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Blend mode image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: .zero, size: size)
        return draw(to: rect.size, inverting: false) { context in
            
            #if os(macOS)
            base.draw(in: rect)
            #else
            base.draw(in: rect, blendMode: .normal, alpha: 1.0)
            #endif
            
            
            let strokeRect =  rect.insetBy(dx: border.lineWidth / 2, dy: border.lineWidth / 2)
            context.setStrokeColor(border.color.cgColor)
            context.setAlpha(border.color.rgba.a)
            
            let line = pathForRoundCorner(
                rect: strokeRect,
                radius: border.radius,
                corners: border.roundingCorners,
                offsetBase: border.lineWidth
            )
            line.lineCapStyle = .square
            line.lineWidth = border.lineWidth
            line.stroke()
            
            return false
        }
    }
    
    // MARK: Overlay
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
    public func overlaying(with color: KFCrossPlatformColor, fraction: CGFloat) -> KFCrossPlatformImage {
        
        guard let _ = cgImage else {
            assertionFailure("[Kingfisher] Overlaying only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return draw(to: rect.size, inverting: false) { context in
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
            return false
        }
    }
    
    // MARK: Tint
    /// Creates an image from `base` image with a color tint.
    ///
    /// - Parameter color: The color should be used to tint `base`
    /// - Returns: An image with a color tint applied.
    public func tinted(with color: KFCrossPlatformColor) -> KFCrossPlatformImage {
        #if os(watchOS)
        return base
        #else
        return apply(.tint(color))
        #endif
    }
    
    // MARK: Color Control
    
    /// Create an image from `self` with color control.
    ///
    /// - Parameters:
    ///   - brightness: Brightness changing to image.
    ///   - contrast: Contrast changing to image.
    ///   - saturation: Saturation changing to image.
    ///   - inputEV: InputEV changing to image.
    /// - Returns:  An image with color control applied.
    public func adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> KFCrossPlatformImage {
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
    public func scaled(to scale: CGFloat) -> KFCrossPlatformImage {
        guard scale != self.scale else {
            return base
        }
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Scaling only works for CG-based image.")
            return base
        }
        return KingfisherWrapper.image(cgImage: cgImage, scale: scale, refImage: base)
    }
}

// MARK: - Decoding Image
extension KingfisherWrapper where Base: KFCrossPlatformImage {
    
    /// Returns the decoded image of the `base` image. It will draw the image in a plain context and return the data
    /// from it. This could improve the drawing performance when an image is just created from data but not yet
    /// displayed for the first time.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public var decoded: KFCrossPlatformImage { return decoded(scale: scale) }
    
    /// Returns decoded image of the `base` image at a given scale. It will draw the image in a plain context and
    /// return the data from it. This could improve the drawing performance when an image is just created from
    /// data but not yet displayed for the first time.
    ///
    /// - Parameter scale: The given scale of target image should be.
    /// - Returns: The decoded image ready to be displayed.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public func decoded(scale: CGFloat) -> KFCrossPlatformImage {
        // Prevent animated image (GIF) losing it's images
        #if os(iOS) || os(visionOS)
        if frameSource != nil { return base }
        #else
        if images != nil { return base }
        #endif

        guard let imageRef = cgImage else {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }

        let size = CGSize(width: CGFloat(imageRef.width) / scale, height: CGFloat(imageRef.height) / scale)
        return draw(to: size, inverting: true, scale: scale) { context in
            context.draw(imageRef, in: CGRect(origin: .zero, size: size))
            return true
        }
    }

    /// Returns decoded image of the `base` image at a given scale. It will draw the image in a plain context and
    /// return the data from it. This could improve the drawing performance when an image is just created from
    /// data but not yet displayed for the first time.
    ///
    /// - Parameter context: The context for drawing.
    /// - Returns: The decoded image ready to be displayed.
    ///
    /// - Note: This method only works for CG-based image. The current image scale is kept.
    ///         For any non-CG-based image or animated image, `base` itself is returned.
    public func decoded(on context: CGContext) -> KFCrossPlatformImage {
        // Prevent animated image (GIF) losing it's images
        #if os(iOS) || os(visionOS)
        if frameSource != nil { return base }
        #else
        if images != nil { return base }
        #endif

        guard let refImage = cgImage,
              let decodedRefImage = refImage.decoded(on: context, scale: scale) else
        {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }
        return KingfisherWrapper.image(cgImage: decodedRefImage, scale: scale, refImage: base)
    }
}

extension CGImage {
    func decoded(on context: CGContext, scale: CGFloat) -> CGImage? {
        let size = CGSize(width: CGFloat(self.width) / scale, height: CGFloat(self.height) / scale)
        context.draw(self, in: CGRect(origin: .zero, size: size))
        guard let decodedImageRef = context.makeImage() else {
            return nil
        }
        return decodedImageRef
    }
}

extension KingfisherWrapper where Base: KFCrossPlatformImage {
    func draw(
        to size: CGSize,
        inverting: Bool,
        scale: CGFloat? = nil,
        refImage: KFCrossPlatformImage? = nil,
        draw: (CGContext) -> Bool // Whether use the refImage (`true`) or ignore image orientation (`false`)
    ) -> KFCrossPlatformImage
    {
        #if os(macOS) || os(watchOS)
        let targetScale = scale ?? self.scale
        GraphicsContext.begin(size: size, scale: targetScale)
        guard let context = GraphicsContext.current(size: size, scale: targetScale, inverting: inverting, cgImage: cgImage) else {
            assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
            return base
        }
        defer { GraphicsContext.end() }
        let useRefImage = draw(context)
        guard let cgImage = context.makeImage() else {
            return base
        }
        let ref = useRefImage ? (refImage ?? base) : nil
        return KingfisherWrapper.image(cgImage: cgImage, scale: targetScale, refImage: ref)
        #else
        
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = scale ?? self.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        var useRefImage: Bool = false
        let image = renderer.image { rendererContext in
            
            let context = rendererContext.cgContext
            if inverting { // If drawing a CGImage, we need to make context flipped.
                context.scaleBy(x: 1.0, y: -1.0)
                context.translateBy(x: 0, y: -size.height)
            }
            
            useRefImage = draw(context)
        }
        if useRefImage {
            guard let cgImage = image.cgImage else {
                return base
            }
            let ref = refImage ?? base
            return KingfisherWrapper.image(cgImage: cgImage, scale: format.scale, refImage: ref)
        } else {
            return image
        }
        #endif
    }
    
    #if os(macOS)
    func fixedForRetinaPixel(cgImage: CGImage, to size: CGSize) -> KFCrossPlatformImage {
        
        let image = KFCrossPlatformImage(cgImage: cgImage, size: base.size)
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        
        return draw(to: self.size, inverting: false) { context in
            image.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
            return false
        }
    }
    #endif
}
