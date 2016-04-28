//
//  KingfisherOptionsInfo.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/23.
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

- TargetCache: The associated value of this member should be an ImageCache object. Kingfisher will use the specified cache object when handling related operations, including trying to retrieve the cached images and store the downloaded image to it.
- Downloader:  The associated value of this member should be an ImageDownloader object. Kingfisher will use this downloader to download the images.
- Transition:  Member for animation transition when using UIImageView. Kingfisher will use the `ImageTransition` of this enum to animate the image in if it is downloaded from web. The transition will not happen when the image is retrieved from either memory or disk cache.
- DownloadPriority: Associated `Float` value will be set as the priority of image download task. The value for it should be between 0.0~1.0. If this option not set, the default value (`NSURLSessionTaskPriorityDefault`) will be used.
- ForceRefresh: If set, `Kingfisher` will ignore the cache and try to fire a download task for the resource.
- CacheMemoryOnly: If set, `Kingfisher` will only cache the value in memory but not in disk.
- BackgroundDecode: Decode the image in background thread before using.
- CallbackDispatchQueue: The associated value of this member will be used as the target queue of dispatch callbacks when retrieving images from cache. If not set, `Kingfisher` will use main quese for callbacks.
- ScaleFactor: The associated value of this member will be used as the scale factor when converting retrieved data to an image.
- PreloadAllGIFData: Whether all the GIF data should be preloaded. Default it false, which means following frames will be loaded on need. If true, all the GIF data will be loaded and decoded into memory. This option is mainly used for back compatibility internally. You should not set it directly. `AnimatedImageView` will not preload all data, while a normal image view (`UIImageView` or `NSImageView`) will load all data. Choose to use corresponding image view type instead of setting this option.
*/
public enum KingfisherOptionsInfoItem {
    case TargetCache(ImageCache?)
    case Downloader(ImageDownloader?)
    case Transition(ImageTransition)
    case DownloadPriority(Float)
    case ForceRefresh
    case CacheMemoryOnly
    case BackgroundDecode
    case CallbackDispatchQueue(dispatch_queue_t?)
    case ScaleFactor(CGFloat)
    case PreloadAllGIFData
}

infix operator <== {
    associativity none
    precedence 160
}

// This operator returns true if two `KingfisherOptionsInfoItem` enum is the same, without considering the associated values.
func <== (lhs: KingfisherOptionsInfoItem, rhs: KingfisherOptionsInfoItem) -> Bool {
    switch (lhs, rhs) {
    case (.TargetCache(_), .TargetCache(_)): fallthrough
    case (.Downloader(_), .Downloader(_)): fallthrough
    case (.Transition(_), .Transition(_)): fallthrough
    case (.DownloadPriority(_), .DownloadPriority(_)): fallthrough
    case (.ForceRefresh, .ForceRefresh): fallthrough
    case (.CacheMemoryOnly, .CacheMemoryOnly): fallthrough
    case (.BackgroundDecode, .BackgroundDecode): fallthrough
    case (.CallbackDispatchQueue(_), .CallbackDispatchQueue(_)): fallthrough
    case (.ScaleFactor(_), .ScaleFactor(_)): fallthrough
    case (.PreloadAllGIFData, .PreloadAllGIFData): return true
        
    default: return false
    }
}

extension CollectionType where Generator.Element == KingfisherOptionsInfoItem {
    func kf_firstMatchIgnoringAssociatedValue(target: Generator.Element) -> Generator.Element? {
        return indexOf { $0 <== target }.flatMap { self[$0] }
    }
    
    func kf_removeAllMatchesIgnoringAssociatedValue(target: Generator.Element) -> [Generator.Element] {
        return self.filter { !($0 <== target) }
    }
}

extension CollectionType where Generator.Element == KingfisherOptionsInfoItem {
    var targetCache: ImageCache? {
        if let item = kf_firstMatchIgnoringAssociatedValue(.TargetCache(nil)),
            case .TargetCache(let cache) = item
        {
            return cache
        }
        return nil
    }
    
    var downloader: ImageDownloader? {
        if let item = kf_firstMatchIgnoringAssociatedValue(.Downloader(nil)),
            case .Downloader(let downloader) = item
        {
            return downloader
        }
        return nil
    }
    
    var transition: ImageTransition {
        if let item = kf_firstMatchIgnoringAssociatedValue(.Transition(.None)),
            case .Transition(let transition) = item
        {
            return transition
        }
        return ImageTransition.None
    }
    
    var downloadPriority: Float {
        if let item = kf_firstMatchIgnoringAssociatedValue(.DownloadPriority(0)),
            case .DownloadPriority(let priority) = item
        {
            return priority
        }
        return NSURLSessionTaskPriorityDefault
    }
    
    var forceRefresh: Bool {
        return contains{ $0 <== .ForceRefresh }
    }
    
    var cacheMemoryOnly: Bool {
        return contains{ $0 <== .CacheMemoryOnly }
    }
    
    var backgroundDecode: Bool {
        return contains{ $0 <== .BackgroundDecode }
    }
    
    var preloadAllGIFData: Bool {
        return contains { $0 <== .PreloadAllGIFData }
    }
    
    var callbackDispatchQueue: dispatch_queue_t {
        if let item = kf_firstMatchIgnoringAssociatedValue(.CallbackDispatchQueue(nil)),
            case .CallbackDispatchQueue(let queue) = item
        {
            return queue ?? dispatch_get_main_queue()
        }
        return dispatch_get_main_queue()
    }
    
    var scaleFactor: CGFloat {
        if let item = kf_firstMatchIgnoringAssociatedValue(.ScaleFactor(0)),
            case .ScaleFactor(let scale) = item
        {
            return scale
        }
        return 1.0
    }
}
