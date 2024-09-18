//
//  Image.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/6.
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


#if os(macOS)
import AppKit
#else // os(macOS)
import UIKit
import MobileCoreServices
#endif // os(macOS)

#if !os(watchOS)
import CoreImage
#endif

import CoreGraphics
import ImageIO

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if compiler(>=5.10)
nonisolated(unsafe) private let animatedImageDataKey = malloc(1)!
nonisolated(unsafe) private let imageFrameCountKey = malloc(1)!
nonisolated(unsafe) private let imageSourceKey = malloc(1)!
#if os(macOS)
nonisolated(unsafe) private let imagesKey = malloc(1)!
nonisolated(unsafe) private let durationKey = malloc(1)!
#endif // os(macOS)
#else // compiler(>=5.10)
private let animatedImageDataKey = malloc(1)!
private let imageFrameCountKey = malloc(1)!
private let imageSourceKey = malloc(1)!
#if os(macOS)
private let imagesKey = malloc(1)!
private let durationKey = malloc(1)!
#endif // os(macOS)
#endif // compiler(>=5.10)

// MARK: - Image Properties
extension KingfisherWrapper where Base: KFCrossPlatformImage {
    private(set) var animatedImageData: Data? {
        get { return getAssociatedObject(base, animatedImageDataKey) }
        set { setRetainedAssociatedObject(base, animatedImageDataKey, newValue) }
    }
    
    public var imageFrameCount: Int? {
        get { return getAssociatedObject(base, imageFrameCountKey) }
        set { setRetainedAssociatedObject(base, imageFrameCountKey, newValue) }
    }
    
    #if os(macOS)
    var cgImage: CGImage? {
        return base.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    var scale: CGFloat {
        return 1.0
    }
    
    private(set) var images: [KFCrossPlatformImage]? {
        get { return getAssociatedObject(base, imagesKey) }
        set { setRetainedAssociatedObject(base, imagesKey, newValue) }
    }
    
    private(set) var duration: TimeInterval {
        get { return getAssociatedObject(base, durationKey) ?? 0.0 }
        set { setRetainedAssociatedObject(base, durationKey, newValue) }
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
    var images: [KFCrossPlatformImage]? { return base.images }
    var duration: TimeInterval { return base.duration }
    var size: CGSize { return base.size }
    
    /// The source reference for the current image.
    public var imageSource: CGImageSource? {
        get {
            guard let frameSource = frameSource as? CGImageFrameSource else { return nil }
            return frameSource.imageSource
        }
    }
    #endif
    
    /// The custom frame source for the current image.
    public private(set) var frameSource: (any ImageFrameSource)? {
        get { return getAssociatedObject(base, imageSourceKey) }
        set { setRetainedAssociatedObject(base, imageSourceKey, newValue) }
    }

    // Bitmap memory cost with bytes.
    var cost: Int {
        let pixel = Int(size.width * size.height * scale * scale)
        guard let cgImage = cgImage else {
            return pixel * 4
        }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard let imageCount = images?.count else {
            return pixel * bytesPerPixel
        }
        return pixel * bytesPerPixel * imageCount
    }
}

// MARK: - Image Conversion
extension KingfisherWrapper where Base: KFCrossPlatformImage {
    #if os(macOS)
    static func image(cgImage: CGImage, scale: CGFloat, refImage: KFCrossPlatformImage?) -> KFCrossPlatformImage {
        return KFCrossPlatformImage(cgImage: cgImage, size: .zero)
    }
    
    /// The normalized image. On macOS, this getter returns the image itself without performing any additional operations.
    public var normalized: KFCrossPlatformImage { return base }
    #else

    /// Create an image from a given `CGImage` with specified scale and orientation, tailored for `refImage`. This
    /// method signature is designed for compatibility with macOS versions.
    ///
    /// - Parameters:
    ///   - cgImage: The `CGImage` which is used to create the `UIImage` object.
    ///   - scale: The scale.
    ///   - refImage: The ref image which is used to determine the image orientation.
    /// - Returns: The created image object.
    static func image(cgImage: CGImage, scale: CGFloat, refImage: KFCrossPlatformImage?) -> KFCrossPlatformImage {
        return KFCrossPlatformImage(cgImage: cgImage, scale: scale, orientation: refImage?.imageOrientation ?? .up)
    }
    
    /// The normalized image for the current `base` image.
    ///
    /// This method attempts to redraw the image, taking orientation and scale into account.
    public var normalized: KFCrossPlatformImage {
        // prevent animated image (GIF) lose it's images
        guard images == nil else { return base.copy() as! KFCrossPlatformImage }
        // No need to do anything if already up
        guard base.imageOrientation != .up else { return base.copy() as! KFCrossPlatformImage }

        return draw(to: size, inverting: true, refImage: KFCrossPlatformImage()) {
            fixOrientation(in: $0)
            return true
        }
    }

    func fixOrientation(in context: CGContext) {
        guard let cgImage else { return }

        var transform = CGAffineTransform.identity
        let orientation = base.imageOrientation

        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: .pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }

        // Flip image one more time if needed for mirrored images. This is to prevent the flipped image.
        switch orientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }

        context.concatenate(transform)
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
    #endif
}

// MARK: - Image Representation
extension KingfisherWrapper where Base: KFCrossPlatformImage {
    /// Returns a data object that contains the specified image in PNG format.
    ///
    /// - Returns: PNG data of image.
    public func pngRepresentation() -> Data? {
        #if os(macOS)
            guard let cgImage = cgImage else {
                return nil
            }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            return rep.representation(using: .png, properties: [:])
        #else
            return base.pngData()
        #endif
    }

    /// Returns a data object that contains the specified image in JPEG format.
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

    /// Returns GIF representation of `base` image.
    ///
    /// - Returns: Original GIF data of image.
    public func gifRepresentation() -> Data? {
        return animatedImageData
    }

    /// Returns a data representation for the `base` image with the specified `format`.
    ///
    /// - Parameters:
    ///   - format: The desired format for the output data. If set to `unknown`, the `base` image will be
    ///             converted to PNG representation.
    ///   - compressionQuality: The compression quality when converting the image to a lossy format data.
    ///
    /// - Returns: The resulting data representation.
    public func data(format: ImageFormat, compressionQuality: CGFloat = 1.0) -> Data? {
        return autoreleasepool { () -> Data? in
            let data: Data?
            switch format {
            case .PNG: data = pngRepresentation()
            case .JPEG: data = jpegRepresentation(compressionQuality: compressionQuality)
            case .GIF: data = gifRepresentation()
            case .unknown: data = normalized.kf.pngRepresentation()
            }
            
            return data
        }
    }
}

// MARK: - Creating Images
extension KingfisherWrapper where Base: KFCrossPlatformImage {
    
    /// Creates an animated image from provided data and options.
    ///
    /// - Parameters:
    ///   - data: The data containing the animated image.
    ///   - options: Options to be used when creating the animated image.
    /// - Returns: An `Image` object representing the animated image. It's structured as an array of image frames, 
    /// each with a specific duration. Returns `nil` if any issues occur during animated image creation.
    ///
    /// - Note: Currently, only GIF data is supported.
    public static func animatedImage(data: Data, options: ImageCreatingOptions) -> KFCrossPlatformImage? {
        #if os(visionOS)
        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: UTType.gif.identifier
        ]
        #else
        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        #endif
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, info as CFDictionary) else {
            return nil
        }
        let frameSource = CGImageFrameSource(data: data, imageSource: imageSource, options: info)
        #if os(macOS)
        let baseImage = KFCrossPlatformImage(data: data)
        #else
        let baseImage = KFCrossPlatformImage(data: data, scale: options.scale)
        #endif
        return animatedImage(source: frameSource, options: options, baseImage: baseImage)
    }
    
    /// Creates an animated image from a given frame source.
    ///
    /// - Parameters:
    ///   - source: The frame source from which to create the animated image.
    ///   - options: Options to be used during animated image creation.
    ///   - baseImage: An optional image object to serve as the key frame of the animated image. If `nil`, the first
    ///                frame of the `source` will be used.
    /// - Returns: An `Image` object representing the animated image. It consists of an array of image frames, each with a
    ///            specific duration. Returns `nil` if any issues arise during animated image creation.
    public static func animatedImage(source: any ImageFrameSource, options: ImageCreatingOptions, baseImage: KFCrossPlatformImage? = nil) -> KFCrossPlatformImage? {
        #if os(macOS)
        guard let animatedImage = GIFAnimatedImage(from: source, options: options) else {
            return nil
        }
        var image: KFCrossPlatformImage?
        if options.onlyFirstFrame {
            image = animatedImage.images.first
        } else {
            if let baseImage = baseImage {
                image = baseImage
            } else {
                image = animatedImage.images.first
            }
            var kf = image?.kf
            kf?.images = animatedImage.images
            kf?.duration = animatedImage.duration
        }
        image?.kf.animatedImageData = source.data
        image?.kf.imageFrameCount = source.frameCount
        image?.kf.frameSource = source
        return image
        #else
        
        var image: KFCrossPlatformImage?
        if options.preloadAll || options.onlyFirstFrame {
            // Use `images` image if you want to preload all animated data
            guard let animatedImage = GIFAnimatedImage(from: source, options: options) else {
                return nil
            }
            if options.onlyFirstFrame {
                image = animatedImage.images.first
            } else {
                let duration = options.duration <= 0.0 ? animatedImage.duration : options.duration
                image = .animatedImage(with: animatedImage.images, duration: duration)
            }
            image?.kf.animatedImageData = source.data
        } else {
            if let baseImage = baseImage {
                image = baseImage
            } else {
                guard let firstFrame = source.frame(at: 0) else {
                    return nil
                }
                image = KFCrossPlatformImage(cgImage: firstFrame, scale: options.scale, orientation: .up)
            }
            var kf = image?.kf
            kf?.frameSource = source
            kf?.animatedImageData = source.data
        }
        
        image?.kf.imageFrameCount = source.frameCount
        return image
        #endif
    }

    /// Creates an image from provided data and options. Supported formats include `.JPEG`, `.PNG`, or `.GIF`. For 
    /// other image formats, the system's image initializer will be used. If no image object can be created from the
    /// given `data`, `nil` will be returned.
    ///
    /// - Parameters:
    ///   - data: The data representing the image.
    ///   - options: Options to be used when creating the image.
    /// - Returns: An `Image` object representing the image if successfully created. If the `data` is invalid or 
    /// unsupported, `nil` will be returned.
    public static func image(data: Data, options: ImageCreatingOptions) -> KFCrossPlatformImage? {
        var image: KFCrossPlatformImage?
        switch data.kf.imageFormat {
        case .JPEG:
            image = KFCrossPlatformImage(data: data, scale: options.scale)
        case .PNG:
            image = KFCrossPlatformImage(data: data, scale: options.scale)
        case .GIF:
            image = KingfisherWrapper.animatedImage(data: data, options: options)
        case .unknown:
            image = KFCrossPlatformImage(data: data, scale: options.scale)
        }
        return image
    }

    /// Creates a downsampled image from the given data to a specified size and scale.
    ///
    /// - Parameters:
    ///   - data: The image data containing a JPEG or PNG image.
    ///   - pointSize: The target size in points to which the image should be downsampled.
    ///   - scale: The scale of the resulting image.
    /// - Returns: A downsampled `Image` object adhering to the specified conditions.
    ///
    /// Unlike image `resize` methods, downsampling does not render the original input image in pixel format.
    /// Instead, it downsamples directly from the image data, making it more memory-efficient and friendly. Whenever
    /// possible, consider using downsampling.
    ///
    /// > Important: The `pointSize` should be smaller than the size of the input image. If it is larger than the original image
    /// > size, the resulting image will have the same dimensions as the input without downsampling.
    public static func downsampledImage(data: Data, to pointSize: CGSize, scale: CGFloat) -> KFCrossPlatformImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions: [CFString : Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        return KingfisherWrapper.image(cgImage: downsampledImage, scale: scale, refImage: nil)
    }
}
