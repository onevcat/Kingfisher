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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFImage: KFImageProtocol {
    public var context: Context<Image>
    public init(context: Context<Image>) {
        self.context = context
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Image: KFImageHoldingView {
    public static func created(from image: KFCrossPlatformImage) -> Image {
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            return Image(crossPlatformImage: image)
        } else {
            #if canImport(UIKit)
            // The CG image is used to solve #1395
            // It should be not necessary if SwiftUI.Image can handle resizing correctly when created
            // by `Image.init(uiImage:)`. (The orientation information should be already contained in
            // a `UIImage`)
            // https://github.com/onevcat/Kingfisher/issues/1395
            //
            // This issue happens on iOS 13 and was fixed by Apple from iOS 14.
            if let cgImage = image.cgImage {
                return Image(decorative: cgImage, scale: image.scale, orientation: image.imageOrientation.toSwiftUI())
            } else {
                return Image(crossPlatformImage: image)
            }
            #else
            return Image(crossPlatformImage: image)
            #endif

        }
    }
}

// MARK: - Image compatibility.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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
}

// MARK: - Deprecated
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {
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
}

#if DEBUG
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFImage_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            KFImage.url(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!)
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
