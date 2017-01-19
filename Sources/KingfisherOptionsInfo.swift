//
//  KingfisherOptionsInfo.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/23.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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
    

/**
*	KingfisherOptionsInfo is a typealias for [KingfisherOptionsInfoItem]. You can use the enum of option item with value to control some behaviors of Kingfisher.
*/
public typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]
let KingfisherEmptyOptionsInfo = [KingfisherOptionsInfoItem]()

/**
Items could be added into KingfisherOptionsInfo.
*/
public enum KingfisherOptionsInfoItem {
    /// The associated value of this member should be an ImageCache object. Kingfisher will use the specified
    /// cache object when handling related operations, including trying to retrieve the cached images and store
    /// the downloaded image to it.
    case targetCache(ImageCache)
    
    /// The associated value of this member should be an ImageDownloader object. Kingfisher will use this
    /// downloader to download the images.
    case downloader(ImageDownloader)
    
    /// Member for animation transition when using UIImageView. Kingfisher will use the `ImageTransition` of
    /// this enum to animate the image in if it is downloaded from web. The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, set `ForceTransition` as well.
    case transition(ImageTransition)
    
    /// Associated `Float` value will be set as the priority of image download task. The value for it should be
    /// between 0.0~1.0. If this option not set, the default value (`NSURLSessionTaskPriorityDefault`) will be used.
    case downloadPriority(Float)
    
    /// If set, `Kingfisher` will ignore the cache and try to fire a download task for the resource.
    case forceRefresh
    
    /// If set, setting the image to an image view will happen with transition even when retrieved from cache.
    /// See `Transition` option for more.
    case forceTransition
    
    ///  If set, `Kingfisher` will only cache the value in memory but not in disk.
    case cacheMemoryOnly
    
    /// If set, `Kingfisher` will only try to retrieve the image from cache not from network.
    case onlyFromCache
    
    /// Decode the image in background thread before using.
    case backgroundDecode
    
    /// The associated value of this member will be used as the target queue of dispatch callbacks when
    /// retrieving images from cache. If not set, `Kingfisher` will use main quese for callbacks.
    case callbackDispatchQueue(DispatchQueue?)
    
    /// The associated value of this member will be used as the scale factor when converting retrieved data to an image.
    /// It is the image scale, instead of your screen scale. You may need to specify the correct scale when you dealing 
    /// with 2x or 3x retina images.
    case scaleFactor(CGFloat)
    
    /// Whether all the GIF data should be preloaded. Default it false, which means following frames will be
    /// loaded on need. If true, all the GIF data will be loaded and decoded into memory. This option is mainly
    /// used for back compatibility internally. You should not set it directly. `AnimatedImageView` will not preload
    /// all data, while a normal image view (`UIImageView` or `NSImageView`) will load all data. Choose to use
    /// corresponding image view type instead of setting this option.
    case preloadAllGIFData
    
    /// The `ImageDownloadRequestModifier` contained will be used to change the request before it being sent.
    /// This is the last chance you can modify the request. You can modify the request for some customizing purpose,
    /// such as adding auth token to the header, do basic HTTP auth or something like url mapping. The original request
    /// will be sent without any modification by default.
    case requestModifier(ImageDownloadRequestModifier)
    
    /// Processor for processing when the downloading finishes, a processor will convert the downloaded data to an image
    /// and/or apply some filter on it. If a cache is connected to the downloader (it happenes when you are using
    /// KingfisherManager or the image extension methods), the converted image will also be sent to cache as well as the
    /// image view. `DefaultImageProcessor.default` will be used by default.
    case processor(ImageProcessor)
    
    /// Supply an `CacheSerializer` to convert some data to an image object for
    /// retrieving from disk cache or vice versa for storing to disk cache.
    /// `DefaultCacheSerializer.default` will be used by default.
    case cacheSerializer(CacheSerializer)
    
    /// Keep the existing image while setting another image to an image view.
    /// By setting this option, the placeholder image parameter of imageview extension method
    /// will be ignored and the current image will be kept while loading or downloading the new image.
    case keepCurrentImageWhileLoading
}

precedencegroup ItemComparisonPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

infix operator <== : ItemComparisonPrecedence

// This operator returns true if two `KingfisherOptionsInfoItem` enum is the same, without considering the associated values.
func <== (lhs: KingfisherOptionsInfoItem, rhs: KingfisherOptionsInfoItem) -> Bool {
    switch (lhs, rhs) {
    case (.targetCache(_), .targetCache(_)): return true
    case (.downloader(_), .downloader(_)): return true
    case (.transition(_), .transition(_)): return true
    case (.downloadPriority(_), .downloadPriority(_)): return true
    case (.forceRefresh, .forceRefresh): return true
    case (.forceTransition, .forceTransition): return true
    case (.cacheMemoryOnly, .cacheMemoryOnly): return true
    case (.onlyFromCache, .onlyFromCache): return true
    case (.backgroundDecode, .backgroundDecode): return true
    case (.callbackDispatchQueue(_), .callbackDispatchQueue(_)): return true
    case (.scaleFactor(_), .scaleFactor(_)): return true
    case (.preloadAllGIFData, .preloadAllGIFData): return true
    case (.requestModifier(_), .requestModifier(_)): return true
    case (.processor(_), .processor(_)): return true
    case (.cacheSerializer(_), .cacheSerializer(_)): return true
    case (.keepCurrentImageWhileLoading, .keepCurrentImageWhileLoading): return true
    default: return false
    }
}

extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    func firstMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
        return index { $0 <== target }.flatMap { self[$0] }
    }
    
    func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
        return self.filter { !($0 <== target) }
    }
}

public extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    /// The target `ImageCache` which is used.
    public var targetCache: ImageCache {
        if let item = firstMatchIgnoringAssociatedValue(.targetCache(.default)),
            case .targetCache(let cache) = item
        {
            return cache
        }
        return ImageCache.default
    }
    
    /// The `ImageDownloader` which is specified.
    public var downloader: ImageDownloader {
        if let item = firstMatchIgnoringAssociatedValue(.downloader(.default)),
            case .downloader(let downloader) = item
        {
            return downloader
        }
        return ImageDownloader.default
    }
    
    /// Member for animation transition when using UIImageView.
    public var transition: ImageTransition {
        if let item = firstMatchIgnoringAssociatedValue(.transition(.none)),
            case .transition(let transition) = item
        {
            return transition
        }
        return ImageTransition.none
    }
    
    /// A `Float` value set as the priority of image download task. The value for it should be
    /// between 0.0~1.0.
    public var downloadPriority: Float {
        if let item = firstMatchIgnoringAssociatedValue(.downloadPriority(0)),
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
    
    /// Whether the transition should always happen or not.
    public var forceTransition: Bool {
        return contains{ $0 <== .forceTransition }
    }
    
    /// Whether cache the image only in memory or not.
    public var cacheMemoryOnly: Bool {
        return contains{ $0 <== .cacheMemoryOnly }
    }
    
    /// Whether only load the images from cache or not.
    public var onlyFromCache: Bool {
        return contains{ $0 <== .onlyFromCache }
    }
    
    /// Whether the image should be decoded in background or not.
    public var backgroundDecode: Bool {
        return contains{ $0 <== .backgroundDecode }
    }
    
    /// Whether the image data should be all loaded at once if it is a GIF.
    public var preloadAllGIFData: Bool {
        return contains { $0 <== .preloadAllGIFData }
    }
    
    /// The queue of callbacks should happen from Kingfisher.
    public var callbackDispatchQueue: DispatchQueue {
        if let item = firstMatchIgnoringAssociatedValue(.callbackDispatchQueue(nil)),
            case .callbackDispatchQueue(let queue) = item
        {
            return queue ?? DispatchQueue.main
        }
        return DispatchQueue.main
    }
    
    /// The scale factor which should be used for the image.
    public var scaleFactor: CGFloat {
        if let item = firstMatchIgnoringAssociatedValue(.scaleFactor(0)),
            case .scaleFactor(let scale) = item
        {
            return scale
        }
        return 1.0
    }
    
    /// The `ImageDownloadRequestModifier` will be used before sending a download request.
    public var modifier: ImageDownloadRequestModifier {
        if let item = firstMatchIgnoringAssociatedValue(.requestModifier(NoModifier.default)),
            case .requestModifier(let modifier) = item
        {
            return modifier
        }
        return NoModifier.default
    }
    
    /// `ImageProcessor` for processing when the downloading finishes.
    public var processor: ImageProcessor {
        if let item = firstMatchIgnoringAssociatedValue(.processor(DefaultImageProcessor.default)),
            case .processor(let processor) = item
        {
            return processor
        }
        return DefaultImageProcessor.default
    }
    
    /// `CacheSerializer` to convert image to data for storing in cache.
    public var cacheSerializer: CacheSerializer {
        if let item = firstMatchIgnoringAssociatedValue(.cacheSerializer(DefaultCacheSerializer.default)),
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
}
