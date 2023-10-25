//
//  KFImage.swift
//  Kingfisher
//
//  Created by onevcat on 2019/06/26.
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

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

/// Represents an image view in SwiftUI that manages its content using Kingfisher.
///
/// This view asynchronously loads the content. You can set a ``Source`` to load for the ``KFImage`` through
/// its ``KFImage/init(source:)`` or ``KFImage/init(_:)`` initializers or other relevant methods in ``KF`` Builder type.
///  Kingfisher will first look for the required image in the cache. If it is not found, it will load it via the
///  ``Source`` and provide the result for display, following sending the result to cache and for the future use.
///
/// When using a `URL` valve as the ``Source``, it is similar to SwiftUI's `AsyncImage` but with additional support
/// for caching.
///
/// Here is a basic example of using ``KFImage``:
///
/// ```swift
/// var body: some View {
///   KFImage(URL(string: "https://example.com/image.png")!)
/// }
/// ```
///
/// Usually, you can also use the value by calling additional modifiers defined on it, to configure the view:
///
/// ```swift
/// var body: some View {
///     KFImage.url(url)
///       .placeholder(placeholderImage)
///       .setProcessor(processor)
///       .loadDiskFileSynchronously()
///       .cacheMemoryOnly()
///       .onSuccess { result in  }
/// }
/// ```
/// Here only very few are listed as demonstration. To check other available modifiers, see ``KFOptionSetter`` and its
/// extension methods.
///
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct KFImage: KFImageProtocol {
    
    /// Represent the wrapping context of the image view.
    ///
    /// Inside ``KFImage`` it is using the `SwiftUI.Image` to render the image.
    public var context: Context<Image>
    
    /// Initializes the ``KFImage`` with a context.
    ///
    /// This should be only used internally in Kingfisher. Do not use this initializer yourself. Instead, use
    ///  ``KFImage/init(source:)`` or ``KFImage/init(_:)`` initializers or other relevant methods in ``KF`` Builder
    ///  type.
    /// - Parameter context: The context value that the image view should wrap.
    public init(context: Context<Image>) {
        self.context = context
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension Image: KFImageHoldingView {
    public typealias RenderingView = Image
    public static func created(from image: KFCrossPlatformImage?, context: KFImage.Context<Self>) -> Image {
        Image(crossPlatformImage: image)
    }
}

// MARK: - Image compatibility.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage {

    public func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch) -> KFImage
    {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> KFImage {
        configure { $0.renderingMode(renderingMode) }
    }

    public func interpolation(_ interpolation: Image.Interpolation) -> KFImage {
        configure { $0.interpolation(interpolation) }
    }

    public func antialiased(_ isAntialiased: Bool) -> KFImage {
        configure { $0.antialiased(isAntialiased) }
    }
    
    /// Starts the loading process of `self` immediately.
    ///
    /// By default, a `KFImage` will not load its source until the `onAppear` is called. This is a lazily loading
    /// behavior and provides better performance. However, when you refresh the view, the lazy loading also causes a
    /// flickering since the loading does not happen immediately. Call this method if you want to start the load at once
    /// could help avoiding the flickering, with some performance trade-off.
    ///
    /// - Deprecated: This is not necessary anymore since `@StateObject` is used for holding the image data.
    /// It does nothing now and please just remove it.
    ///
    /// - Returns: The `Self` value with changes applied.
    @available(*, deprecated, message: "This is not necessary anymore since `@StateObject` is used. It does nothing now and please just remove it.")
    public func loadImmediately(_ start: Bool = true) -> KFImage {
        return self
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct KFImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KFImage.url(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!)
                .onSuccess { r in
                    print(r)
                }
                .placeholder { p in
                    ProgressView(p)
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
        }
    }
}
#endif
#endif
