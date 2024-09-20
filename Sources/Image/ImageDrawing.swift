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

extension KingfisherWrapper where Base: KFCrossPlatformImage {
    // MARK: - Image Transforming
    
    // MARK: Blend Mode
    
#if !os(macOS)
    /// Create an image from the `base` image and apply a blend mode.
    ///
    /// - Parameters:
    ///   - blendMode: The blend mode to be applied to the image.
    ///   - alpha: The alpha value to be used for the image.
    ///   - backgroundColor: The background color for the output image.
    /// - Returns: An image with the specified blend mode applied.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Create an image from the `base` image and apply a compositing operation.
    ///
    /// - Parameters:
    ///   - compositingOperation: The compositing operation to be applied to the image.
    ///   - alpha: The alpha value to be used for the image.
    ///   - backgroundColor: The background color for the output image.
    /// - Returns: An image with the specified compositing operation applied.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Create a rounded corner image from the `base` image.
    ///
    /// - Parameters:
    ///   - radius: The radius for rounding the corners of the image.
    ///   - size: The target size of the resulting image.
    ///   - corners: The corners to which rounding will be applied.
    ///   - backgroundColor: The background color for the output image.
    /// - Returns: An image with rounded corners based on `self`.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Create a round corner image from the `base` image.
    ///
    /// - Parameters:
    ///   - radius: The radius for rounding the corners of the image.
    ///   - size: The target size of the resulting image.
    ///   - corners: The corners to which rounding will be applied.
    ///   - backgroundColor: The background color for the output image.
    /// - Returns: An image with rounded corners based on `self`.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Resize the `base` image to a new size.
    ///
    /// - Parameter size: The target size in points.
    /// - Returns: An image with the new size.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
    ///
    /// > Tip: This method resizes the `base` image to a specified size by drawing it into that size. If you require a
    /// smaller thumbnail of the image, consider using ``downsampledImage(data:to:scale:)`` instead, as it offers
    /// improved efficiency.
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
    
    /// Resize the `base` image to a new size while respecting the specified content mode.
    ///
    /// - Parameters:
    ///   - targetSize: The target size in points.
    ///   - contentMode: The desired content mode for the output image.
    /// - Returns: An image with the new size.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
    ///
    /// > Tip: This method resizes the `base` image to a specified size by drawing it into that size. If you require a
    /// smaller thumbnail of the image, consider using ``downsampledImage(data:to:scale:)`` instead, as it offers
    /// improved efficiency.
    public func resize(to targetSize: CGSize, for contentMode: ContentMode) -> KFCrossPlatformImage {
        let newSize = size.kf.resize(to: targetSize, for: contentMode)
        return resize(to: newSize)
    }

    // MARK: Cropping
    
    /// Crop the `base` image to a new size with a specified anchor point.
    ///
    /// - Parameters:
    ///   - size: The target size.
    ///   - anchor: The anchor point from which the size should be calculated.
    /// - Returns: An image with the new size.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Create an image with a blur effect based on the `base` image.
    ///
    /// - Parameter radius: The blur radius to be used when creating the blur effect.
    /// - Returns: An image with the blur effect applied.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
        
        func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
            let data = context.data
            let width = vImagePixelCount(context.width)
            let height = vImagePixelCount(context.height)
            let rowBytes = context.bytesPerRow
            
            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }
        
        guard let inputContext = CGContext.fresh(cgImage: cgImage) else {
            return base
        }
        inputContext.draw(
            cgImage,
            in: CGRect(
                x: 0,
                y: 0,
                width: size.width * scale,
                height: size.height * scale
            )
        )
        var inBuffer = createEffectBuffer(inputContext)

        guard let outContext = CGContext.fresh(cgImage: cgImage) else {
            return base
        }
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
    
    /// Create an image from the `base` image with a color overlay layer.
    ///
    /// - Parameters:
    ///   - color: The color to be used for the overlay.
    ///   - fraction: The fraction of the input color to apply, ranging from 0.0 (solid color) to 1.0 (transparent overlay).
    /// - Returns: An image with a color overlay applied.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Create an image from the `base` image with a color tint.
    ///
    /// - Parameter color: The color to be used for tinting the `base` image.
    /// - Returns: An image with a color tint applied.
    ///
    /// > Important: This method does not work on watchOS, where the original image is returned.
    public func tinted(with color: KFCrossPlatformColor) -> KFCrossPlatformImage {
#if os(watchOS)
        return base
#else
        return apply(.tint(color))
#endif
    }
    
    // MARK: Color Control
    
    /// Create an image from `self` with color control adjustments.
    ///
    /// - Parameters:
    ///   - brightness: The degree of brightness adjustment to apply to the image.
    ///   - contrast: The degree of contrast adjustment to apply to the image.
    ///   - saturation: The degree of saturation adjustment to apply to the image.
    ///   - inputEV: The exposure value (EV) adjustment to apply to the image.
    /// - Returns: An image with color control adjustments applied.
    ///
    /// > Important: This method does not work on watchOS, where the original image is returned.
    public func adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> KFCrossPlatformImage {
#if os(watchOS)
        return base
#else
        let colorElement = Filter.ColorElement(
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            inputEV: inputEV
        )
        return apply(.colorControl(colorElement))
#endif
    }
    
    /// Return an image with the specified scale.
    ///
    /// - Parameter scale: The target scale factor for the new image.
    /// - Returns: The image with the target scale. If the base image is already at the target scale, the `base` image 
    /// will be returned.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image, the `base` image itself is returned.
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
    
    /// Returns the decoded image of the `base` image. 
    ///
    /// On iOS 15 or later, this is identical to the `UIImage.preparingForDisplay` method.
    ///
    /// In previous versions, this method draws the image in a plain context and returns the data from it. Using this
    ///  method can improve drawing performance when an image is created from data but hasn't been displayed for the
    ///  first time.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image or animated image, the `base` image itself is returned.
    public var decoded: KFCrossPlatformImage { return decoded(scale: scale) }
    
    /// Returns the decoded image of the `base` image at a given `scale`.
    ///
    /// On iOS 15 or later, this is identical to the `UIImage.preparingForDisplay` method.
    ///
    /// In previous versions, this method draws the image in a plain context and returns the data from it. Using this
    ///  method can improve drawing performance when an image is created from data but hasn't been displayed for the
    ///  first time.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image or animated image, the `base` image itself is returned.
    public func decoded(scale: CGFloat) -> KFCrossPlatformImage {

        // Prevent animated image (GIF) losing it's images
        #if os(iOS) || os(visionOS)
        if frameSource != nil { return base }
        #else
        if images != nil { return base }
        #endif
        
        // For older system versions, revert to the drawing for decoding.
        guard let imageRef = cgImage else {
            assertionFailure("[Kingfisher] Decoding only works for CG-based image.")
            return base
        }
        
        #if !os(watchOS) && !os(macOS)
        // In newer system versions, use `preparingForDisplay`.
        if #available(iOS 15.0, tvOS 15.0, visionOS 1.0, *) {
            if base.scale == scale, let image = base.preparingForDisplay() {
                return image
            }
            let scaledImage = KFCrossPlatformImage(cgImage: imageRef, scale: scale, orientation: base.imageOrientation)
            if let image = scaledImage.preparingForDisplay() {
                return image
            }
        }
        #endif

        let size = CGSize(width: CGFloat(imageRef.width) / scale, height: CGFloat(imageRef.height) / scale)
        return draw(to: size, inverting: true, scale: scale) { context in
            context.draw(imageRef, in: CGRect(origin: .zero, size: size))
            return true
        }
    }

    /// Returns the decoded image of the `base` image on a given `context`.
    ///
    /// This method draws the image in the given context and returns the data from it. Using this
    /// method can improve drawing performance when an image is created from data but hasn't been displayed for the
    /// first time.
    ///
    /// > This method is only applicable to CG-based images. The current image scale is preserved.
    /// > For any non-CG-based image or animated image, the `base` image itself is returned.
    public func decoded(on context: CGContext) -> KFCrossPlatformImage {
        // Prevent animated image (GIF) losing it's images
        if frameSource != nil { return base }

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
    
    static func create(ref: CGImage) -> CGImage? {
        guard let space = ref.colorSpace, let provider = ref.dataProvider else {
            return nil
        }
        return CGImage(
            width: ref.width,
            height: ref.height,
            bitsPerComponent: ref.bitsPerComponent,
            bitsPerPixel: ref.bitsPerPixel,
            bytesPerRow: ref.bytesPerRow,
            space: space,
            bitmapInfo: ref.bitmapInfo,
            provider: provider,
            decode: ref.decode,
            shouldInterpolate: ref.shouldInterpolate,
            intent: ref.renderingIntent
        )
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

extension CGContext {
    fileprivate static func fresh(cgImage: CGImage) -> CGContext? {
        CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * cgImage.width,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }
}
