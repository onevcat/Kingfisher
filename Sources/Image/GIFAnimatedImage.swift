//
//  AnimatedImage.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/26.
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

import Foundation
import ImageIO

/// Represents a set of image creation options used in Kingfisher.
public struct ImageCreatingOptions: Equatable {

    /// The target scale of the image that needs to be created.
    public var scale: CGFloat

    /// The expected animation duration if an animated image is being created.
    public var duration: TimeInterval

    /// For an animated image, indicates whether or not all frames should be loaded before displaying.
    public var preloadAll: Bool

    /// For an animated image, indicates whether only the first image should be
    /// loaded as a static image. It is useful for previewing an animated image.
    public var onlyFirstFrame: Bool
    
    /// Creates an `ImageCreatingOptions` object.
    ///
    /// - Parameters:
    ///     - scale: The target scale of the image that needs to be created. Default is `1.0`.
    ///     - duration: The expected animation duration if an animated image is being created.
    ///                 A value less than or equal to `0.0` means the animated image duration will
    ///                 be determined by the frame data. Default is `0.0`.
    ///     - preloadAll: For an animated image, whether or not all frames should be loaded before displaying.
    ///                   Default is `false`.
    ///     - onlyFirstFrame: For an animated image, whether only the first image should be
    ///                       loaded as a static image. It is useful for previewing an animated image.
    ///                       Default is `false`.
    public init(
        scale: CGFloat = 1.0,
        duration: TimeInterval = 0.0,
        preloadAll: Bool = false,
        onlyFirstFrame: Bool = false
    )
    {
        self.scale = scale
        self.duration = duration
        self.preloadAll = preloadAll
        self.onlyFirstFrame = onlyFirstFrame
    }
}

/// Represents the decoding for a GIF image. This class extracts frames from an ``ImageFrameSource``, and then
/// holds the images for later use.
public class GIFAnimatedImage {
    let images: [KFCrossPlatformImage]
    let duration: TimeInterval
    
    init?(from frameSource: any ImageFrameSource, options: ImageCreatingOptions) {
        let frameCount = frameSource.frameCount
        var images = [KFCrossPlatformImage]()
        var gifDuration = 0.0
        
        for i in 0 ..< frameCount {
            guard let imageRef = frameSource.frame(at: i) else {
                return nil
            }
            
            if frameCount == 1 {
                gifDuration = .infinity
            } else {
                // Get current animated GIF frame duration
                gifDuration += frameSource.duration(at: i)
            }
            images.append(KingfisherWrapper.image(cgImage: imageRef, scale: options.scale, refImage: nil))
            if options.onlyFirstFrame { break }
        }
        self.images = images
        self.duration = gifDuration
    }
    
    convenience init?(from imageSource: CGImageSource, for info: [String: Any], options: ImageCreatingOptions) {
        let frameSource = CGImageFrameSource(data: nil, imageSource: imageSource, options: info)
        self.init(from: frameSource, options: options)
    }
    
    /// Calculates the frame duration for a GIF frame out of the `kCGImagePropertyGIFDictionary` dictionary.
    public static func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else { return defaultFrameDuration }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }

    /// Calculates the frame duration at a specific index for a GIF from an `CGImageSource`.
    /// 
    /// - Parameters:
    ///   - imageSource: The image source where the animated image information should be extracted from.
    ///   - index: The index of the target frame in the image.
    /// - Returns: The time duration of the frame at given index in the image.
    public static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }
}

/// Represents a frame source for an animated image.
public protocol ImageFrameSource {
    
    /// Source data associated with this frame source.
    var data: Data? { get }
    
    /// Count of the total frames in this frame source.
    var frameCount: Int { get }
    
    /// Retrieves the frame at a specific index. 
    ///
    /// The resulting image is expected to be no larger than `maxSize`. If the index is invalid,
    /// implementors should return `nil`.
    func frame(at index: Int, maxSize: CGSize?) -> CGImage?
    
    /// Retrieves the duration at a specific index. If the index is invalid, implementors should return `0.0`.
    func duration(at index: Int) -> TimeInterval
    
    /// Creates a copy of the current `ImageFrameSource` instance.
    ///
    /// - Returns: A new instance of the same type as `self` with identical properties.
    ///            If not overridden by conforming types, this default implementation
    ///            simply returns `self`, which may not create an actual copy if the type is a reference type.
    func copy() -> Self
}

public extension ImageFrameSource {
    
    /// Retrieves the frame at a specific index. If the index is invalid, implementors should return `nil`.
    func frame(at index: Int) -> CGImage? {
        return frame(at: index, maxSize: nil)
    }
    
    func copy() -> Self {
        return self
    }
}

struct CGImageFrameSource: ImageFrameSource {
    let data: Data?
    let imageSource: CGImageSource
    let options: [String: Any]?
    
    var frameCount: Int {
        return CGImageSourceGetCount(imageSource)
    }

    func frame(at index: Int, maxSize: CGSize?) -> CGImage? {
        var options = self.options as? [CFString: Any]
        if let maxSize = maxSize, maxSize != .zero {
            options = (options ?? [:]).merging([
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: max(maxSize.width, maxSize.height)
            ], uniquingKeysWith: { $1 })
        }
        return CGImageSourceCreateImageAtIndex(imageSource, index, options as CFDictionary?)
    }

    func duration(at index: Int) -> TimeInterval {
        return GIFAnimatedImage.getFrameDuration(from: imageSource, at: index)
    }
    
    func copy() -> Self {
        guard let data = data, let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary?) else {
            return self
        }
        return CGImageFrameSource(data: data, imageSource: source, options: options)
    }
}

