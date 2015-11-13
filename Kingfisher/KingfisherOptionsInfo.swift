//
//  KingfisherOptionsInfo.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/23.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

/**
*	KingfisherOptionsInfo is a typealias for [KingfisherOptionsInfoItem]. You can use the enum of option item with value to control some behaviors of Kingfisher.
*/
public typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]

/**
Item could be added into KingfisherOptionsInfo

- Options:     Item for options. The value of this item should be a KingfisherOptions.
- TargetCache: Item for target cache. The value of this item should be an ImageCache object. Kingfisher will use this cache when handling the related operation, including trying to retrieve the cached images and store the downloaded image to it.
- Downloader:  Item for downloader to use. The value of this item should be an ImageDownloader object. Kingfisher will use this downloader to download the images.
- Transition:  Item for animation transition when using UIImageView. Kingfisher will use the `ImageTransition` of this enum to animate the image in if it is downloaded from web. The transition will not happen when the image is retrieved from either memory or disk cache.
*/
public enum KingfisherOptionsInfoItem {
    case Options(KingfisherOptions)
    case TargetCache(ImageCache)
    case Downloader(ImageDownloader)
    case Transition(ImageTransition)
}

func == (a: KingfisherOptionsInfoItem, b: KingfisherOptionsInfoItem) -> Bool {
    switch (a, b) {
    case (.Options(_), .Options(_)): return true
    case (.TargetCache(_), .TargetCache(_)): return true
    case (.Downloader(_), .Downloader(_)): return true
    case (.Transition(_), .Transition(_)): return true
    default: return false
    }
}

extension CollectionType where Generator.Element == KingfisherOptionsInfoItem {
    func kf_findFirstMatch(target: Generator.Element) -> Generator.Element? {
        
        let index = indexOf {
            e in
            return e == target
        }
        
        return (index != nil) ? self[index!] : nil
    }
}
