//
//  KingfisherOptionsInfo.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/23.
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
#else
import UIKit
#endif
    

/// KingfisherOptionsInfo is a typealias for [KingfisherOptionsInfoItem].
/// You can use the enum of option item with value to control some behaviors of Kingfisher.
public typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]

extension Array where Element == KingfisherOptionsInfoItem {
    
    static let empty: KingfisherOptionsInfo = []

    // A connivence property to generate an image creating option with current `KingfisherOptionsInfo`.
    var imageCreatingOptions: ImageCreatingOptions {
        return ImageCreatingOptions(
            scale: scaleFactor,
            duration: 0.0,
            preloadAll: preloadAllAnimationData,
            onlyFirstFrame: onlyLoadFirstFrame)
    }
}

/// Represents the available option items could be used in `KingfisherOptionsInfo`.
public enum KingfisherOptionsInfoItem {
    
    /// Kingfisher will use the associated `ImageCache` object when handling related operations,
    /// including trying to retrieve the cached images and store the downloaded image to it.
    case targetCache(ImageCache)
    
    /// The `ImageCache` for storing and retrieving original images. If `originalCache` is
    /// contained in the options, it will be preferred for storing and retrieving original images.
    /// If there is no `.originalCache` in the options, `.targetCache` will be used to store original images.
    ///
    /// When using KingfisherManager to download and store an image, if `cacheOriginalImage` is
    /// applied in the option, the original image will be stored to this `originalCache`. At the
    /// same time, if a requested final image (with processor applied) cannot be found in `targetCache`,
    /// Kingfisher will try to search the original image to check whether it is already there. If found,
    /// it will be used and applied with the given processor. It is an optimization for not downloading
    /// the same image for multiple times.
    case originalCache(ImageCache)
    
    /// Kingfisher will use the associated `ImageDownloader` object to download the requested images.
    case downloader(ImageDownloader)
    
    #if os(iOS) || os(tvOS)
    /// Member for animation transition when using `UIImageView`. Kingfisher will use the `ImageTransition` of
    /// this enum to animate the image in if it is downloaded from web. The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, set `.forceRefresh` as well.
    case transition(ImageTransition)
    #endif
    
    /// Associated `Float` value will be set as the priority of image download task. The value for it should be
    /// between 0.0~1.0. If this option not set, the default value (`URLSessionTask.defaultPriority`) will be used.
    case downloadPriority(Float)
    
    /// If set, Kingfisher will ignore the cache and try to fire a download task for the resource.
    case forceRefresh

    /// If set, Kingfisher will try to retrieve the image from memory cache first. If the image is not in memory
    /// cache, then it will ignore the disk cache but download the image again from network. This is useful when
    /// you want to display a changeable image behind the same url at the same app session, while avoiding download
    /// it for multiple times.
    case fromMemoryCacheOrRefresh
    
    /// If set, setting the image to an image view will happen with transition even when retrieved from cache.
    /// See `.transition` option for more.
    case forceTransition
    
    ///  If set, Kingfisher will only cache the value in memory but not in disk.
    case cacheMemoryOnly
    
    ///  If set, Kingfisher will wait for caching operation to be completed before calling the completion block.
    case waitForCache
    
    /// If set, Kingfisher will only try to retrieve the image from cache, but not from network. If the image is
    /// not in cache, the image retrieving will fail with an error.
    case onlyFromCache
    
    /// Decode the image in background thread before using. It will decode the downloaded image data and do a offscreen
    /// rendering to extract pixel information in background. This can speed up display, but will cost more time to
    /// prepare the image for using.
    case backgroundDecode
    
    /// The associated value of this member will be used as the target queue of dispatch callbacks when
    /// retrieving images from cache. If not set, Kingfisher will use main queue for callbacks.
    @available(*, deprecated, message: "Use `.callbackQueue(CallbackQueue)` instead.")
    case callbackDispatchQueue(DispatchQueue?)

    /// The associated value will be used as the target queue of dispatch callbacks when retrieving images from
    /// cache. If not set, Kingfisher will use `.mainCurrentOrAsync` for callbacks.
    case callbackQueue(CallbackQueue)
    
    /// The associated value will be used as the scale factor when converting retrieved data to an image.
    /// Specify the image scale, instead of your screen scale. You may need to set the correct scale when you dealing
    /// with 2x or 3x retina images. Otherwise, Kingfisher will convert the data to image object at `scale` 1.0.
    case scaleFactor(CGFloat)

    /// Whether all the animated image data should be preloaded. Default is `false`, which means only following frames
    /// will be loaded on need. If `true`, all the animated image data will be loaded and decoded into memory.
    ///
    /// This option is mainly used for back compatibility internally. You should not set it directly. Instead,
    /// you should choose the image view class to control the GIF data loading. There are two classes in Kingfisher
    /// support to display a GIF image. `AnimatedImageView` does not preload all data, it takes much less memory, but
    /// uses more CPU when display. While a normal image view (`UIImageView` or `NSImageView`) loads all data at once,
    /// which uses more memory but only decode image frames once.
    case preloadAllAnimationData
    
    /// The `ImageDownloadRequestModifier` contained will be used to change the request before it being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    /// The original request will be sent without any modification by default.
    case requestModifier(ImageDownloadRequestModifier)
    
    /// Processor for processing when the downloading finishes, a processor will convert the downloaded data to an image
    /// and/or apply some filter on it. If a cache is connected to the downloader (it happens when you are using
    /// KingfisherManager or any of the view extension methods), the converted image will also be sent to cache as well.
    /// If not set, the `DefaultImageProcessor.default` will be used.
    case processor(ImageProcessor)
    
    /// Supplies a `CacheSerializer` to convert some data to an image object for
    /// retrieving from disk cache or vice versa for storing to disk cache.
    /// If not set, the `DefaultCacheSerializer.default` will be used.
    case cacheSerializer(CacheSerializer)

    /// An `ImageModifier` is for modifying an image as needed right before it is used. If the image was fetched
    /// directly from the downloader, the modifier will run directly after the `ImageProcessor`. If the image is being
    /// fetched from a cache, the modifier will run after the `CacheSerializer`.
    ///
    /// Use `ImageModifier` when you need to set properties that do not persist when caching the image on a concrete
    /// type of `Image`, such as the `renderingMode` or the `alignmentInsets` of `UIImage`.
    case imageModifier(ImageModifier)
    
    /// Keep the existing image of image view while setting another image to it.
    /// By setting this option, the placeholder image parameter of image view extension method
    /// will be ignored and the current image will be kept while loading or downloading the new image.
    case keepCurrentImageWhileLoading
    
    /// If set, Kingfisher will only load the first frame from an animated image file as a single image.
    /// Loading an animated images may take too much memory. It will be useful when you want to display a
    /// static preview of the first frame from a animated image.
    ///
    /// This option will be ignored if the target image is not animated image data.
    case onlyLoadFirstFrame
    
    /// If set and an `ImageProcessor` is used, Kingfisher will try to cache both  the final result and original
    /// image. Kingfisher will have a chance to use the original image when another processor is applied to the same
    /// resource, instead of downloading it again. You can use `.originalCache` to specify a cache or the original
    /// images if neccessary.
    case cacheOriginalImage
    
    /// If set and a downloading error occurred Kingfisher will set provided image (or empty)
    /// in place of requested one. It's useful when you don't want to show placeholder
    /// during loading time but wants to use some default image when requests will be failed.
    case onFailureImage(Image?)
    
    /// If set and used in `ImagePrefetcher`, the prefetching operation will load the images into memory storage
    /// aggressively. By default this is not contained in the options, that means if the requested image is already
    /// in disk cache, Kingfisher will not try to load it to memory.
    case alsoPrefetchToMemory
    
    case loadDiskFileSynchronously
}

precedencegroup ItemComparisonPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

infix operator <== : ItemComparisonPrecedence

// This operator returns true if two `KingfisherOptionsInfoItem` enum is the same,
// without considering the associated values.
func <== (lhs: KingfisherOptionsInfoItem, rhs: KingfisherOptionsInfoItem) -> Bool {
    switch (lhs, rhs) {
    case (.targetCache, .targetCache): return true
    case (.originalCache, .originalCache): return true
    case (.downloader, .downloader): return true
    #if os(iOS) || os(tvOS)
    case (.transition, .transition): return true
    #endif
    case (.downloadPriority, .downloadPriority): return true
    case (.forceRefresh, .forceRefresh): return true
    case (.fromMemoryCacheOrRefresh, .fromMemoryCacheOrRefresh): return true
    case (.forceTransition, .forceTransition): return true
    case (.cacheMemoryOnly, .cacheMemoryOnly): return true
    case (.waitForCache, .waitForCache): return true
    case (.onlyFromCache, .onlyFromCache): return true
    case (.backgroundDecode, .backgroundDecode): return true
    case (.callbackDispatchQueue, .callbackDispatchQueue): return true
    case (.callbackQueue, .callbackQueue): return true
    case (.scaleFactor, .scaleFactor): return true
    case (.preloadAllAnimationData, .preloadAllAnimationData): return true
    case (.requestModifier, .requestModifier): return true
    case (.processor, .processor): return true
    case (.cacheSerializer, .cacheSerializer): return true
    case (.imageModifier, .imageModifier): return true
    case (.keepCurrentImageWhileLoading, .keepCurrentImageWhileLoading): return true
    case (.onlyLoadFirstFrame, .onlyLoadFirstFrame): return true
    case (.cacheOriginalImage, .cacheOriginalImage): return true
    case (.onFailureImage, .onFailureImage): return true
    case (.alsoPrefetchToMemory, .alsoPrefetchToMemory): return true
    case (.loadDiskFileSynchronously, .loadDiskFileSynchronously): return true
    default: return false
    }
}


extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    func lastMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
        return reversed().first { $0 <== target }
    }
    
    func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
        return filter { !($0 <== target) }
    }
}

public extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    /// The target `ImageCache` which is used.
    public var targetCache: ImageCache? {
        if let item = lastMatchIgnoringAssociatedValue(.targetCache(.default)),
            case .targetCache(let cache) = item
        {
            return cache
        }
        return nil
    }
    
    /// The original `ImageCache` which is used.
    public var originalCache: ImageCache? {
        if let item = lastMatchIgnoringAssociatedValue(.originalCache(.default)),
            case .originalCache(let cache) = item
        {
            return cache
        }
        return targetCache
    }
    
    /// The `ImageDownloader` which is specified.
    public var downloader: ImageDownloader? {
        if let item = lastMatchIgnoringAssociatedValue(.downloader(.default)),
            case .downloader(let downloader) = item
        {
            return downloader
        }
        return nil
    }
    
    #if os(iOS) || os(tvOS)
    /// Member for animation transition when using UIImageView.
    public var transition: ImageTransition {
        if let item = lastMatchIgnoringAssociatedValue(.transition(.none)),
            case .transition(let transition) = item
        {
            return transition
        }
        return ImageTransition.none
    }
    #endif
    
    /// A `Float` value set as the priority of image download task. The value for it should be
    /// between 0.0~1.0.
    public var downloadPriority: Float {
        if let item = lastMatchIgnoringAssociatedValue(.downloadPriority(0)),
            case .downloadPriority(let priority) = item
        {
            return priority
        }
        return URLSessionTask.defaultPriority
    }
    
    /// Whether an image will be always downloaded again or not.
    public var forceRefresh: Bool {
        return contains{ $0 <== .forceRefresh }
    }

    /// Whether an image should be got only from memory cache or download.
    public var fromMemoryCacheOrRefresh: Bool {
        return contains{ $0 <== .fromMemoryCacheOrRefresh }
    }
    
    /// Whether the transition should always happen or not.
    public var forceTransition: Bool {
        return contains{ $0 <== .forceTransition }
    }
    
    /// Whether cache the image only in memory or not.
    public var cacheMemoryOnly: Bool {
        return contains{ $0 <== .cacheMemoryOnly }
    }
    
    /// Whether the caching operation will be waited or not.
    public var waitForCache: Bool {
        return contains{ $0 <== .waitForCache }
    }
    
    /// Whether only load the images from cache or not.
    public var onlyFromCache: Bool {
        return contains{ $0 <== .onlyFromCache }
    }
    
    /// Whether the image should be decoded in background or not.
    public var backgroundDecode: Bool {
        return contains{ $0 <== .backgroundDecode }
    }

    /// Whether the image data should be all loaded at once if it is an animated image.
    public var preloadAllAnimationData: Bool {
        return contains { $0 <== .preloadAllAnimationData }
    }

    /// The `CallbackQueue` on which completion handler should be invoked.
    /// If not set in the options, `.mainCurrentOrAsync` will be used.
    public var callbackQueue: CallbackQueue {
        if let item = lastMatchIgnoringAssociatedValue(.callbackQueue(.untouch)),
            case .callbackQueue(let queue) = item
        {
            return queue
        }
        return .mainCurrentOrAsync
    }
    
    /// The scale factor which should be used for the image.
    public var scaleFactor: CGFloat {
        if let item = lastMatchIgnoringAssociatedValue(.scaleFactor(0)),
            case .scaleFactor(let scale) = item
        {
            return scale
        }
        return 1.0
    }
    
    /// The `ImageDownloadRequestModifier` will be used before sending a download request.
    public var modifier: ImageDownloadRequestModifier {
        if let item = lastMatchIgnoringAssociatedValue(.requestModifier(NoModifier.default)),
            case .requestModifier(let modifier) = item
        {
            return modifier
        }
        return NoModifier.default
    }
    
    /// `ImageProcessor` for processing when the downloading finishes.
    public var processor: ImageProcessor {
        if let item = lastMatchIgnoringAssociatedValue(.processor(DefaultImageProcessor.default)),
            case .processor(let processor) = item
        {
            return processor
        }
        return DefaultImageProcessor.default
    }

    /// `ImageModifier` for modifying right before the image is displayed.
    public var imageModifier: ImageModifier {
        if let item = lastMatchIgnoringAssociatedValue(.imageModifier(DefaultImageModifier.default)),
            case .imageModifier(let imageModifier) = item
        {
            return imageModifier
        }
        return DefaultImageModifier.default
    }
    
    /// `CacheSerializer` to convert image to data for storing in cache.
    public var cacheSerializer: CacheSerializer {
        if let item = lastMatchIgnoringAssociatedValue(.cacheSerializer(DefaultCacheSerializer.default)),
            case .cacheSerializer(let cacheSerializer) = item
        {
            return cacheSerializer
        }
        return DefaultCacheSerializer.default
    }
    
    /// Keep the existing image while setting another image to an image view. 
    /// Or the placeholder will be used while downloading.
    public var keepCurrentImageWhileLoading: Bool {
        return contains { $0 <== .keepCurrentImageWhileLoading }
    }
    
    /// Whether the options contains `.onlyLoadFirstFrame`.
    public var onlyLoadFirstFrame: Bool {
        return contains { $0 <== .onlyLoadFirstFrame }
    }
    
    /// Whether the options contains `.cacheOriginalImage`.
    public var cacheOriginalImage: Bool {
        return contains { $0 <== .cacheOriginalImage }
    }
    
    /// Use provided or empty image when download image request will failed.
    public var onFailureImage: Optional<Image?> {
        if let item = lastMatchIgnoringAssociatedValue(.onFailureImage(Image())),
            case .onFailureImage(let image) = item
        {
            return .some(image)
        }
        
        return .none
    }
    
    /// Whether the `ImagePrefetcher` should load images to memory in an aggressive way.
    public var alsoPrefetchToMemory: Bool {
        return contains { $0 <== .alsoPrefetchToMemory }
    }
    
    public var loadDiskFileSynchronously: Bool {
        return contains { $0 <== .loadDiskFileSynchronously }
    }
}
