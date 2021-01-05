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
import Combine
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Image {
    // Creates an Image with either UIImage or NSImage.
    init(crossPlatformImage: KFCrossPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: crossPlatformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: crossPlatformImage)
        #endif
    }
}

/// A Kingfisher compatible SwiftUI `View` to load an image from a `Source`.
/// Declaring a `KFImage` in a `View`'s body to trigger loading from the given `Source`.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFImage: View {

    // TODO: Replace `@ObservedObject` with `@StateObject` once we do not need to support iOS 13.
    /// An image binder that manages loading and cancelling image related task.
    @ObservedObject private(set) var binder: ImageBinder

    // Acts as a placeholder when loading an image.
    var placeholder: AnyView?

    // Whether the download task should be cancelled when the view disappears.
    var cancelOnDisappear: Bool = false

    // Configurations should be performed on the image.
    var configurations: [(Image) -> Image]

    /// Creates a Kingfisher compatible image view to load image from the given `Source`.
    /// - Parameter source: The image `Source` defining where to load the target image.
    /// - Parameter options: The options should be applied when loading the image.
    ///                      Some UIKit related options (such as `ImageTransition.flip`) are not supported.
    /// - Parameter isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///                       state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///                       wrapped value from outside.
    /// - Deprecated: Some options are not available in SwiftUI yet. Use `KFImage(source:isLoaded:)` to create a
    ///               `KFImage` and configure the options through modifier instead. See methods of `KFOptionSetter`
    ///               for more.
    @available(*, deprecated, message: "Some options are not available in SwiftUI yet. Use `KFImage(source:isLoaded:)` to create a `KFImage` and configure the options through modifier instead.")
    public init(source: Source?, options: KingfisherOptionsInfo? = nil, isLoaded: Binding<Bool> = .constant(false)) {
        let binder = ImageBinder(source: source, options: options, isLoaded: isLoaded)
        self.binder = binder
        configurations = []
        binder.start()
    }

    /// Creates a Kingfisher compatible image view to load image from the given `URL`.
    /// - Parameter url: The image URL from where to load the target image.
    /// - Parameter options: The options should be applied when loading the image.
    ///                      Some UIKit related options (such as `ImageTransition.flip`) are not supported.
    /// - Parameter isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///                       state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///                       wrapped value from outside.
    /// - Deprecated: Some options are not available in SwiftUI yet. Use `KFImage(_:isLoaded:)` to create a
    ///               `KFImage` and configure the options through modifier instead. See methods of `KFOptionSetter`
    ///               for more.
    @available(*, deprecated, message: "Some options are not available in SwiftUI yet. Use `KFImage(_:isLoaded:)` to create a `KFImage` and configure the options through modifier instead.")
    public init(_ url: URL?, options: KingfisherOptionsInfo? = nil, isLoaded: Binding<Bool> = .constant(false)) {
        self.init(source: url?.convertToSource(), options: options, isLoaded: isLoaded)
    }

    /// Creates a Kingfisher compatible image view to load image from the given `Source`.
    /// - Parameters:
    ///   - source: The image `Source` defining where to load the target image.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    public init(source: Source?, isLoaded: Binding<Bool> = .constant(false)) {
        let binder = ImageBinder(source: source, isLoaded: isLoaded)
        self.binder = binder
        configurations = []
        // Give the `binder` a chance to accept other configurations.
        DispatchQueue.main.async { binder.start() }
    }

    /// Creates a Kingfisher compatible image view to load image from the given `URL`.
    /// - Parameters:
    ///   - source: The image `Source` defining where to load the target image.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    public init(_ url: URL?, isLoaded: Binding<Bool> = .constant(false)) {
        self.init(source: url?.convertToSource(), isLoaded: isLoaded)
    }

    /// Declares the content and behavior of this view.
    public var body: some View {
        Group {
            if binder.image != nil {
                configurations
                    .reduce(Image(crossPlatformImage: binder.image!)) {
                        current, config in config(current)
                    }
            } else {
                Group {
                    if placeholder != nil {
                        placeholder
                    } else {
                        Image(crossPlatformImage: .init())
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .onAppear { [weak binder = self.binder] in
                    guard let binder = binder else {
                        return
                    }
                    if !binder.loadingOrSucceeded {
                        binder.start()
                    }
                }
                .onDisappear { [weak binder = self.binder] in
                    guard let binder = binder else {
                        return
                    }
                    if self.cancelOnDisappear {
                        binder.cancel()
                    }
                }
            }
        }
    }
}

// MARK: - Image compatibility.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    /// Configures current image with a `block`. This block will be lazily applied when creating the final `Image`.
    /// - Parameter block: The block applies to loaded image.
    /// - Returns: A `KFImage` view that configures internal `Image` with `block`.
    public func configure(_ block: @escaping (Image) -> Image) -> KFImage {
        var result = self
        result.configurations.append(block)
        return result
    }

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
}

#if DEBUG
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFImage_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            KFImage(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!)
                .onSuccess { r in
                    print(r)
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
        }
    }
}
#endif
#endif
