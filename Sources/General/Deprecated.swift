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

@available(*, deprecated, message: "Use `Result<ImageResult>` based callback instead")
public typealias CompletionHandler = ((_ image: Image?, _ error: NSError?, _ cacheType: CacheType, _ imageURL: URL?) -> Void)

extension RetrieveImageTask {
    @available(*, deprecated, message: "RetrieveImageTask.empty will be removed soon. Use `nil` to represnt a no task.")
    public static let empty = RetrieveImageTask()
}

extension KingfisherManager {
    /// Get an image with resource.
    /// If `.empty` is used as `options`, Kingfisher will seek the image in memory and disk first.
    /// If not found, it will download the image at `resource.downloadURL` and cache it with `resource.cacheKey`.
    /// These default behaviors could be adjusted by passing different options. See `KingfisherOptions` for more.
    ///
    /// - Parameters:
    ///   - resource: Resource object contains information such as `cacheKey` and `downloadURL`.
    ///   - options: A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time downloaded data changed. This could be used as a progress UI.
    ///   - completionHandler: Called when the whole retrieving process finished.
    /// - Returns: A `RetrieveImageTask` task object. You can use this object to cancel the task.
    @available(*, deprecated, message: "Use `Result` based callback instead.")
    @discardableResult
    public func retrieveImage(with resource: Resource,
                              options: KingfisherOptionsInfo?,
                              progressBlock: DownloadProgressBlock?,
                              completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return retrieveImage(with: resource, options: options, progressBlock: progressBlock) {
            result in
            switch result {
            case .success(let value): completionHandler?(value.image, nil, value.cacheType, value.imageURL)
            case .failure(let error): completionHandler?(nil, error as NSError, .none, nil)
            }
        }
    }
}
