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

    /// Member for animation transition when using `UIImageView`. Kingfisher will use the `ImageTransition` of
    /// this enum to animate the image in if it is downloaded from web. The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, set `.forceRefresh` as well.
    case transition(ImageTransition)
    
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
    
    /// If set, the disk storage loading will happen in the same calling queue. By default, disk storage file loading
    /// happens in its own queue with an asynchronous dispatch behavior. Although it provides better non-blocking disk
    /// loading performance, it also causes a flickering when you reload an image from disk, if the image view already
    /// has an image set.
    ///
    /// Set this options will stop that flickering by keeping all loading in the same queue (typically the UI queue
    /// if you are using Kingfisher's extension methods to set an image), with a tradeoff of loading performance.
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
    case (.transition, .transition): return true
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
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `targetCache` instead.")
    public var targetCache: ImageCache? {
        return KingfisherParsedOptionsInfo(Array(self)).targetCache
    }
    
    /// The original `ImageCache` which is used.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `originalCache` instead.")
    public var originalCache: ImageCache? {
        return KingfisherParsedOptionsInfo(Array(self)).originalCache
    }
    
    /// The `ImageDownloader` which is specified.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `downloader` instead.")
    public var downloader: ImageDownloader? {
        return KingfisherParsedOptionsInfo(Array(self)).downloader
    }

    /// Member for animation transition when using UIImageView.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `transition` instead.")
    public var transition: ImageTransition {
        return KingfisherParsedOptionsInfo(Array(self)).transition
    }
    
    /// A `Float` value set as the priority of image download task. The value for it should be
    /// between 0.0~1.0.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `downloadPriority` instead.")
    public var downloadPriority: Float {
        return KingfisherParsedOptionsInfo(Array(self)).downloadPriority
    }
    
    /// Whether an image will be always downloaded again or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `forceRefresh` instead.")
    public var forceRefresh: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).forceRefresh
    }

    /// Whether an image should be got only from memory cache or download.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `fromMemoryCacheOrRefresh` instead.")
    public var fromMemoryCacheOrRefresh: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).fromMemoryCacheOrRefresh
    }
    
    /// Whether the transition should always happen or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `forceTransition` instead.")
    public var forceTransition: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).forceTransition
    }
    
    /// Whether cache the image only in memory or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `cacheMemoryOnly` instead.")
    public var cacheMemoryOnly: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).cacheMemoryOnly
    }
    
    /// Whether the caching operation will be waited or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `waitForCache` instead.")
    public var waitForCache: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).waitForCache
    }
    
    /// Whether only load the images from cache or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `onlyFromCache` instead.")
    public var onlyFromCache: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).onlyFromCache
    }
    
    /// Whether the image should be decoded in background or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `backgroundDecode` instead.")
    public var backgroundDecode: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).backgroundDecode
    }

    /// Whether the image data should be all loaded at once if it is an animated image.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `preloadAllAnimationData` instead.")
    public var preloadAllAnimationData: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).preloadAllAnimationData
    }

    /// The `CallbackQueue` on which completion handler should be invoked.
    /// If not set in the options, `.mainCurrentOrAsync` will be used.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `callbackQueue` instead.")
    public var callbackQueue: CallbackQueue {
        return KingfisherParsedOptionsInfo(Array(self)).callbackQueue
    }
    
    /// The scale factor which should be used for the image.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `scaleFactor` instead.")
    public var scaleFactor: CGFloat {
        return KingfisherParsedOptionsInfo(Array(self)).scaleFactor
    }
    
    /// The `ImageDownloadRequestModifier` will be used before sending a download request.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `requestModifier` instead.")
    public var modifier: ImageDownloadRequestModifier {
        return KingfisherParsedOptionsInfo(Array(self)).requestModifier
    }
    
    /// `ImageProcessor` for processing when the downloading finishes.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `processor` instead.")
    public var processor: ImageProcessor {
        return KingfisherParsedOptionsInfo(Array(self)).processor
    }

    /// `ImageModifier` for modifying right before the image is displayed.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `imageModifier` instead.")
    public var imageModifier: ImageModifier {
        return KingfisherParsedOptionsInfo(Array(self)).imageModifier
    }
    
    /// `CacheSerializer` to convert image to data for storing in cache.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `cacheSerializer` instead.")
    public var cacheSerializer: CacheSerializer {
        return KingfisherParsedOptionsInfo(Array(self)).cacheSerializer
    }
    
    /// Keep the existing image while setting another image to an image view. 
    /// Or the placeholder will be used while downloading.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `keepCurrentImageWhileLoading` instead.")
    public var keepCurrentImageWhileLoading: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).keepCurrentImageWhileLoading
    }
    
    /// Whether the options contains `.onlyLoadFirstFrame`.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `onlyLoadFirstFrame` instead.")
    public var onlyLoadFirstFrame: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).onlyLoadFirstFrame
    }
    
    /// Whether the options contains `.cacheOriginalImage`.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `cacheOriginalImage` instead.")
    public var cacheOriginalImage: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).cacheOriginalImage
    }
    
    /// The image which should be used when download image request fails.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `onFailureImage` instead.")
    public var onFailureImage: Optional<Image?> {
        return KingfisherParsedOptionsInfo(Array(self)).onFailureImage
    }
    
    /// Whether the `ImagePrefetcher` should load images to memory in an aggressive way or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `alsoPrefetchToMemory` instead.")
    public var alsoPrefetchToMemory: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).alsoPrefetchToMemory
    }
    
    /// Whether the disk storage file loading should happen in a synchronous behavior or not.
    @available(*, deprecated,
    message: "Create a `KingfisherParsedOptionsInfo` from `self` and use `loadDiskFileSynchronously` instead.")
    public var loadDiskFileSynchronously: Bool {
        return KingfisherParsedOptionsInfo(Array(self)).loadDiskFileSynchronously
    }
}

// Improve performance by parsing the input `KingfisherOptionsInfo` (self) first.
// So we can prevent the iterating over the options array again and again.
public struct KingfisherParsedOptionsInfo {

    public var targetCache: ImageCache? = nil
    public var originalCache: ImageCache? = nil
    public var downloader: ImageDownloader? = nil
    public var transition: ImageTransition = .none
    public var downloadPriority: Float = URLSessionTask.defaultPriority
    public var forceRefresh = false
    public var fromMemoryCacheOrRefresh = false
    public var forceTransition = false
    public var cacheMemoryOnly = false
    public var waitForCache = false
    public var onlyFromCache = false
    public var backgroundDecode = false
    public var preloadAllAnimationData = false
    public var callbackQueue: CallbackQueue = .mainCurrentOrAsync
    public var scaleFactor: CGFloat = 1.0
    public var requestModifier: ImageDownloadRequestModifier = NoModifier.default
    public var processor: ImageProcessor = DefaultImageProcessor.default
    public var imageModifier: ImageModifier = DefaultImageModifier.default
    public var cacheSerializer: CacheSerializer = DefaultCacheSerializer.default
    public var keepCurrentImageWhileLoading = false
    public var onlyLoadFirstFrame = false
    public var cacheOriginalImage = false
    public var onFailureImage: Optional<Image?> = .none
    public var alsoPrefetchToMemory = false
    public var loadDiskFileSynchronously = false

    public init(_ info: KingfisherOptionsInfo) {
        for option in info {
            switch option {
            case .targetCache(let value): targetCache = value
            case .originalCache(let value): originalCache = value
            case .downloader(let value): downloader = value
            case .transition(let value): transition = value
            case .downloadPriority(let value): downloadPriority = value
            case .forceRefresh: forceRefresh = true
            case .fromMemoryCacheOrRefresh: fromMemoryCacheOrRefresh = true
            case .forceTransition: forceTransition = true
            case .cacheMemoryOnly: cacheMemoryOnly = true
            case .waitForCache: waitForCache = true
            case .onlyFromCache: onlyFromCache = true
            case .backgroundDecode: backgroundDecode = true
            case .preloadAllAnimationData: preloadAllAnimationData = true
            case .callbackQueue(let value): callbackQueue = value
            case .scaleFactor(let value): scaleFactor = value
            case .requestModifier(let value): requestModifier = value
            case .processor(let value): processor = value
            case .imageModifier(let value): imageModifier = value
            case .cacheSerializer(let value): cacheSerializer = value
            case .keepCurrentImageWhileLoading: keepCurrentImageWhileLoading = true
            case .onlyLoadFirstFrame: onlyLoadFirstFrame = true
            case .cacheOriginalImage: cacheOriginalImage = true
            case .onFailureImage(let value): onFailureImage = .some(value)
            case .alsoPrefetchToMemory: alsoPrefetchToMemory = true
            case .loadDiskFileSynchronously: loadDiskFileSynchronously = true
            case .callbackDispatchQueue(let value): callbackQueue = value.map { .dispatch($0) } ?? .mainCurrentOrAsync
            }
        }

        if originalCache == nil {
            originalCache = targetCache
        }
    }
}
