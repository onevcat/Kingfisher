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

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFImage: View {

    var context: Context

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
        let binder = KFImage.ImageBinder(source: source, options: options, isLoaded: isLoaded)
        self.init(binder: binder)
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
    init(_ url: URL?, options: KingfisherOptionsInfo? = nil, isLoaded: Binding<Bool> = .constant(false)) {
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
        self.init(binder: binder)
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

    init(binder: ImageBinder) {
        self.context = Context(binder: binder)
    }

    public var body: some View {
        KFImageRenderer(context)
            .id(context.binder)
    }

    /// Starts the loading process of `self` immediately.
    ///
    /// By default, a `KFImage` will not load its source until the `onAppear` is called. This is a lazily loading
    /// behavior and provides better performance. However, when you refresh the view, the lazy loading also causes a
    /// flickering since the loading does not happen immediately. Call this method if you want to start the load at once
    /// could help avoiding the flickering, with some performance trade-off.
    ///
    /// - Returns: The `Self` value with changes applied.
    public func loadImmediately(_ start: Bool = true) -> KFImage {
        if start {
            context.binder.start()
        }
        return self
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {
    struct Context {
        var binder: ImageBinder
        var configurations: [(Image) -> Image] = []
        var cancelOnDisappear: Bool = false
        var placeholder: AnyView? = nil

        init(binder: ImageBinder) {
            self.binder = binder
        }
    }
}

/// A Kingfisher compatible SwiftUI `View` to load an image from a `Source`.
/// Declaring a `KFImage` in a `View`'s body to trigger loading from the given `Source`.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFImageRenderer: View {

    /// An image binder that manages loading and cancelling image related task.
    @ObservedObject var binder: KFImage.ImageBinder

    // Acts as a placeholder when loading an image.
    var placeholder: AnyView?

    // Whether the download task should be cancelled when the view disappears.
    let cancelOnDisappear: Bool

    // Configurations should be performed on the image.
    let configurations: [(Image) -> Image]

    init(_ context: KFImage.Context) {
        self.binder = context.binder
        self.configurations = context.configurations
        self.placeholder = context.placeholder
        self.cancelOnDisappear = context.cancelOnDisappear
    }

    /// Declares the content and behavior of this view.
    var body: some View {
        if let image = binder.loadedImage {
            configurations
                .reduce(imageFromResult(image)) {
                    current, config in config(current)
                }
                .opacity(binder.loaded ? 1.0 : 0.0)
        } else {
            Group {
                if placeholder != nil {
                    placeholder
                } else {
                    Color.clear
                }
            }
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

    private func imageFromResult(_ resultImage: KFCrossPlatformImage) -> Image {
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            return Image(crossPlatformImage: resultImage)
        } else {
            #if canImport(UIKit)
            // The CG image is used to solve #1395
            // It should be not necessary if SwiftUI.Image can handle resizing correctly when created
            // by `Image.init(uiImage:)`. (The orientation information should be already contained in
            // a `UIImage`)
            // https://github.com/onevcat/Kingfisher/issues/1395
            //
            // This issue happens on iOS 13 and was fixed by Apple from iOS 14.
            if let cgImage = resultImage.cgImage {
                return Image(decorative: cgImage, scale: resultImage.scale, orientation: resultImage.imageOrientation.toSwiftUI())
            } else {
                return Image(crossPlatformImage: resultImage)
            }
            #else
            return Image(crossPlatformImage: resultImage)
            #endif

        }
    }
}

#if canImport(UIKit)
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension UIImage.Orientation {
    func toSwiftUI() -> Image.Orientation {
        switch self {
        case .down: return .down
        case .up: return .up
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
#endif

// MARK: - Image compatibility.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    /// Configures current image with a `block`. This block will be lazily applied when creating the final `Image`.
    /// - Parameter block: The block applies to loaded image.
    /// - Returns: A `KFImage` view that configures internal `Image` with `block`.
    public func configure(_ block: @escaping (Image) -> Image) -> KFImage {
        var result = self
        result.context.configurations.append(block)
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
            KFImage(source: .network(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!))
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
