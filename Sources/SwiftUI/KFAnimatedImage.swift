//
//  KFAnimatedImage.swift
//  Kingfisher
//
//  Created by wangxingbin on 2021/4/29.
//
//  Copyright (c) 2021 Wei Wang <onevcat@gmail.com>
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

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
internal extension KFAnimatedImage {
    typealias ImageBinder = KFImage.ImageBinder
    typealias Context = KFImage.Context
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFAnimatedImage: View {
    
    var context: Context

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
        KFAnimatedImageRender(context)
            .id(context.binder)
    }
    
    /// Starts the loading process of `self` immediately.
    ///
    /// By default, a `KFAnimatedImage` will not load its source until the `onAppear` is called. This is a lazily loading
    /// behavior and provides better performance. However, when you refresh the view, the lazy loading also causes a
    /// flickering since the loading does not happen immediately. Call this method if you want to start the load at once
    /// could help avoiding the flickering, with some performance trade-off.
    ///
    /// - Returns: The `Self` value with changes applied.
    public func loadImmediately(_ start: Bool = true) -> KFAnimatedImage {
        if start {
            context.binder.start()
        }
        return self
    }
    
}

// MARK: - Image compatibility.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFAnimatedImage {

    /// Configures current image with a `block`. This block will be lazily applied when creating the final `Image`.
    /// - Parameter block: The block applies to loaded image.
    /// - Returns: A `KFAnimatedImage` view that configures internal `Image` with `block`.
    public func configure(_ block: @escaping (Image) -> Image) -> KFAnimatedImage {
        var result = self
        result.context.configurations.append(block)
        return result
    }

    public func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch) -> KFAnimatedImage
    {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> KFAnimatedImage {
        configure { $0.renderingMode(renderingMode) }
    }

    public func interpolation(_ interpolation: Image.Interpolation) -> KFAnimatedImage {
        configure { $0.interpolation(interpolation) }
    }

    public func antialiased(_ isAntialiased: Bool) -> KFAnimatedImage {
        configure { $0.antialiased(isAntialiased) }
    }
}

/// A Kingfisher compatible SwiftUI `View` to load an image from a `Source`.
/// Declaring a `KFAnimatedImage` in a `View`'s body to trigger loading from the given `Source`.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFAnimatedImageRender: View {
    /// An image binder that manages loading and cancelling image related task.
    @ObservedObject var binder: KFAnimatedImage.ImageBinder

    // Acts as a placeholder when loading an image.
    var placeholder: AnyView?

    // Whether the download task should be cancelled when the view disappears.
    let cancelOnDisappear: Bool

    init(_ context: KFAnimatedImage.Context) {
        self.binder = context.binder
        self.placeholder = context.placeholder
        self.cancelOnDisappear = context.cancelOnDisappear
    }
    
    /// Declares the content and behavior of this view.
    @ViewBuilder
    var body: some View {
        if let image = binder.loadedImage {
            KFAnimatedImageViewRepresenter(image: image)
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
}

/// A wrapped `UIViewRepresentable` of `AnimatedImageView`
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFAnimatedImageViewRepresenter: UIViewRepresentable {
    
    var image: KFCrossPlatformImage?
    
    func makeUIView(context: Context) -> AnimatedImageView {
        let view = AnimatedImageView()
        view.image = image
        return view
    }
    
    func updateUIView(_ uiView: AnimatedImageView, context: Context) {
        uiView.image = image
    }
    
}

#if DEBUG
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFAnimatedImage_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            KFAnimatedImage(source: .network(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/1.gif")!))
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
