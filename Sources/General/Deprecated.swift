//
//  Deprecated.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/28.
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

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension KingfisherClass where Base: Image {
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
}
