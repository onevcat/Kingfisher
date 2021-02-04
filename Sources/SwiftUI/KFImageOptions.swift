//
//  KFImageOptions.swift
//  Kingfisher
//
//  Created by onevcat on 2020/12/20.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI

// MARK: - KFImage creating.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    /// Creates a `KFImage` for a given `Source`.
    /// - Parameters:
    ///   - source: The `Source` object defines data information from network or a data provider.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    /// - Returns: A `KFImage` for future configuration or embedding to a `SwiftUI.View`.
    public static func source(
        _ source: Source?, isLoaded: Binding<Bool> = .constant(false)
    ) -> KFImage
    {
        KFImage(source: source, isLoaded: isLoaded)
    }

    /// Creates a `KFImage` for a given `Resource`.
    /// - Parameters:
    ///   - source: The `Resource` object defines data information like key or URL.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    /// - Returns: A `KFImage` for future configuration or embedding to a `SwiftUI.View`.
    public static func resource(
        _ resource: Resource?, isLoaded: Binding<Bool> = .constant(false)
    ) -> KFImage
    {
        source(resource?.convertToSource(), isLoaded: isLoaded)
    }

    /// Creates a `KFImage` for a given `URL`.
    /// - Parameters:
    ///   - url: The URL where the image should be downloaded.
    ///   - cacheKey: The key used to store the downloaded image in cache.
    ///               If `nil`, the `absoluteString` of `url` is used as the cache key.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    /// - Returns: A `KFImage` for future configuration or embedding to a `SwiftUI.View`.
    public static func url(
        _ url: URL?, cacheKey: String? = nil, isLoaded: Binding<Bool> = .constant(false)
    ) -> KFImage
    {
        source(url?.convertToSource(overrideCacheKey: cacheKey), isLoaded: isLoaded)
    }

    /// Creates a `KFImage` for a given `ImageDataProvider`.
    /// - Parameters:
    ///   - provider: The `ImageDataProvider` object contains information about the data.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    /// - Returns: A `KFImage` for future configuration or embedding to a `SwiftUI.View`.
    public static func dataProvider(
        _ provider: ImageDataProvider?, isLoaded: Binding<Bool> = .constant(false)
    ) -> KFImage
    {
        source(provider?.convertToSource(), isLoaded: isLoaded)
    }

    /// Creates a builder for some given raw data and a cache key.
    /// - Parameters:
    ///   - data: The data object from which the image should be created.
    ///   - cacheKey: The key used to store the downloaded image in cache.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    /// - Returns: A `KFImage` for future configuration or embedding to a `SwiftUI.View`.
    public static func data(
        _ data: Data?, cacheKey: String, isLoaded: Binding<Bool> = .constant(false)
    ) -> KFImage
    {
        if let data = data {
            return dataProvider(RawImageDataProvider(data: data, cacheKey: cacheKey), isLoaded: isLoaded)
        } else {
            return dataProvider(nil, isLoaded: isLoaded)
        }
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {
    /// Sets a placeholder `View` which shows when loading the image.
    /// - Parameter content: A view that describes the placeholder.
    /// - Returns: A `KFImage` view that contains `content` as its placeholder.
    public func placeholder<Content: View>(@ViewBuilder _ content: () -> Content) -> KFImage {
        let v = content()
        var result = self
        result.context.placeholder = AnyView(v)
        return result
    }

    /// Sets cancelling the download task bound to `self` when the view disappearing.
    /// - Parameter flag: Whether cancel the task or not.
    /// - Returns: A `KFImage` view that cancels downloading task when disappears.
    public func cancelOnDisappear(_ flag: Bool) -> KFImage {
        var result = self
        result.context.cancelOnDisappear = flag
        return result
    }

    /// Sets a fade transition for the image task.
    /// - Parameter duration: The duration of the fade transition.
    /// - Returns: A `KFImage` with changes applied.
    ///
    /// Kingfisher will use the fade transition to animate the image in if it is downloaded from web.
    /// The transition will not happen when the
    /// image is retrieved from either memory or disk cache by default. If you need to do the transition even when
    /// the image being retrieved from cache, also call `forceRefresh()` on the returned `KFImage`.
    public func fade(duration: TimeInterval) -> KFImage {
        context.binder.options.transition = .fade(duration)
        return self
    }
}
#endif
