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
import Combine

// MARK: - KFImage creating.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImageProtocol {

    /// Creates a Kingfisher-compatible image view with a given ``Source``.
    ///
    /// - Parameters:
    ///   - source: The ``Source`` object that defines data information from the network or a data provider.
    /// - Returns: A Kingfisher-compatible image view for future configuration or embedding into another `SwiftUI.View`.
    public static func source(
        _ source: Source?
    ) -> Self
    {
        Self.init(source: source)
    }

    /// Creates a Kingfisher-compatible image view with a given ``Resource``.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object that defines data information such as a key or URL.
    /// - Returns: A Kingfisher-compatible image view for future configuration or embedding into another `SwiftUI.View`.
    public static func resource(
        _ resource: (any Resource)?
    ) -> Self
    {
        source(resource?.convertToSource())
    }

    /// Creates a Kingfisher-compatible image view with a given `URL`.
    ///
    /// - Parameters:
    ///   - url: The `URL` from which the image should be downloaded.
    ///   - cacheKey: The key used to store the downloaded image in the cache. If `nil`, the `absoluteString` of `url`
    ///   is used as the cache key.
    /// - Returns: A Kingfisher-compatible image view for future configuration or embedding into another `SwiftUI.View`.
    public static func url(
        _ url: URL?, cacheKey: String? = nil
    ) -> Self
    {
        source(url?.convertToSource(overrideCacheKey: cacheKey))
    }

    /// Creates a Kingfisher-compatible image view with a given ``ImageDataProvider``.
    ///
    /// - Parameters:
    ///   - provider: The ``ImageDataProvider`` object that contains information about the data.
    /// - Returns: A Kingfisher-compatible image view for future configuration or embedding into another `SwiftUI.View`.

    public static func dataProvider(
        _ provider: (any ImageDataProvider)?
    ) -> Self
    {
        source(provider?.convertToSource())
    }

    /// Creates a builder for the provided raw data and a cache key.
    ///
    /// - Parameters:
    ///   - data: The data object from which the image should be created.
    ///   - cacheKey: The key used to store the downloaded image in the cache.
    /// - Returns: A Kingfisher-compatible image view for future configuration or embedding into another `SwiftUI.View`.
    public static func data(
        _ data: Data?, cacheKey: String
    ) -> Self
    {
        if let data = data {
            return dataProvider(RawImageDataProvider(data: data, cacheKey: cacheKey))
        } else {
            return dataProvider(nil)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImageProtocol {
    
    /// Sets a placeholder `View` that is displayed during the image loading, with a progress parameter as input.
    ///
    /// - Parameter content: A view that represents the placeholder.
    /// - Returns: A Kingfisher-compatible image view that includes the provided `content` as its placeholder.
    public func placeholder<P: View>(@ViewBuilder _ content: @escaping (Progress) -> P) -> Self {
        context.placeholder = { progress in
            return AnyView(content(progress))
        }
        return self
    }
    
    /// Sets a placeholder `View` that is displayed during the image loading.
    ///
    /// - Parameter content: A view that represents the placeholder.
    /// - Returns: A Kingfisher-compatible image view that includes the provided `content` as its placeholder.
    public func placeholder<P: View>(@ViewBuilder _ content: @escaping () -> P) -> Self {
        placeholder { _ in content() }
    }

    /// Sets a failure `View` that is displayed when the image fails to load.
    ///
    /// Use this modifier to provide a custom view when image loading fails. This offers more flexibility than
    /// `onFailureImage` by allowing any SwiftUI view as the failure placeholder.
    ///
    /// Example:
    /// ```swift
    /// KFImage(url)
    ///     .onFailureView {
    ///         VStack {
    ///             Image(systemName: "exclamationmark.triangle")
    ///                 .foregroundColor(.red)
    ///             Text("Failed to load image")
    ///                 .font(.caption)
    ///             Button("Retry") {
    ///                 // Retry logic
    ///             }
    ///         }
    ///     }
    /// ```
    ///
    /// - Note: If both `onFailureImage` and `onFailureView` are set, `onFailureView` takes precedence.
    /// 
    /// - Parameter content: A view builder that creates the failure view.
    /// - Returns: A Kingfisher-compatible image view that displays the provided `content` when image loading fails.
    public func onFailureView<F: View>(@ViewBuilder _ content: @escaping () -> F) -> Self {
        context.failureView = { AnyView(content()) }
        return self
    }

    /// Enables canceling the download task associated with `self` when the view disappears.
    ///
    /// - Parameter flag: A boolean value indicating whether to cancel the task.
    /// - Returns: A Kingfisher-compatible image view that cancels the download task when it disappears.
    public func cancelOnDisappear(_ flag: Bool) -> Self {
        context.cancelOnDisappear = flag
        return self
    }
    
    /// Sets reduce priority  of the download task to low,  bound to `self` when the view disappearing.
    /// - Parameter flag: Whether reduce the priority task or not.
    /// - Returns: A `KFImage` view that reduces downloading task priority when disappears.
    public func reducePriorityOnDisappear(_ flag: Bool) -> Self {
        context.reducePriorityOnDisappear = flag
        return self
    }


    /// Sets a fade transition for the image task.
    ///
    /// - Parameter duration: The duration of the fade transition.
    /// - Returns: A Kingfisher-compatible image view with the applied changes.
    ///
    /// Kingfisher will use the fade transition to animate the image if it is downloaded from the web. The transition 
    /// will not occur when the image is retrieved from either memory or disk cache by default. If you need the
    /// transition to occur even when the image is retrieved from the cache, also call
    /// ``KFOptionSetter/forceRefresh(_:)`` on the returned view.
    public func fade(duration: TimeInterval) -> Self {
        context.options.transition = .fade(duration)
        return self
    }
    
    /// Sets whether to start the image loading before the view actually appears.
    ///
    /// - Parameter flag: A boolean value indicating whether the image loading should happen before the view appears. The default is `true`.
    /// - Returns: A Kingfisher-compatible image view with the applied changes.
    ///
    /// By default, Kingfisher performs lazy loading for `KFImage`. The image loading won't start until the view's
    /// `onAppear` is called. However, sometimes you may want to trigger aggressive loading for the view. By enabling
    /// this, the `KFImage` will attempt to load the view when its `body` is evaluated if the image loading has not
    /// yet started or if a previous loading attempt failed.
    ///
    /// > Important: This was a temporary workaround for an issue that arose in iOS 16, where the SwiftUI view's
    /// > `onAppear` was not called when it was deeply embedded inside a `List` or `ForEach`. This is no longer necessary
    /// > if built with Xcode 14.3 and deployed to iOS 16.4 or later. So, it is not needed anymore.
    /// >
    /// > Enabling this may cause performance regression, especially if you have a lot of images to load in the view.
    /// > Use it at your own risk.
    /// >
    /// > Please refer to [#1988](https://github.com/onevcat/Kingfisher/issues/1988) for more information.
    public func startLoadingBeforeViewAppear(_ flag: Bool = true) -> Self {
        context.startLoadingBeforeViewAppear = flag
        return self
    }
}
#endif
