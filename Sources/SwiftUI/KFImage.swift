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

import SwiftUI
import Combine
#if !KingfisherCocoaPods
import Kingfisher
#endif

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension Image {
    // Creates an SwiftUI.Image with either UIImage or NSImage.
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

    /// An image binder that manages loading and cancelling image related task.
    @ObservedObject public private(set) var binder: ImageBinder

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
    public init(source: Source?, options: KingfisherOptionsInfo? = nil) {
        binder = ImageBinder(source: source, options: options)
        configurations = []
        binder.start()
    }

    /// Creates a Kingfisher compatible image view to load image from the given `Source`.
    /// - Parameter url: The image URL from where to load the target image.
    /// - Parameter options: The options should be applied when loading the image.
    ///                      Some UIKit related options (such as `ImageTransition.flip`) are not supported.
    public init(_ url: URL?, options: KingfisherOptionsInfo? = nil) {
        let source = url.map { Source.network($0) }
        self.init(source: source, options: options)
    }

    /// Declares the content and behavior of this view.
    public var body: some View {
        Group {
            if binder.image != nil {
                configurations
                    .reduce(Image(crossPlatformImage: binder.image!)) {
                        current, config in config(current)
                    }
                    .animation(binder.fadeTransitionAnimation)
            } else {
                Group {
                    if placeholder != nil {
                        placeholder
                    } else {
                        Image(crossPlatformImage: .init())
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .onDisappear { [unowned binder = self.binder] in
                    if self.cancelOnDisappear { binder.cancel() }
                }
            }
        }.onAppear { [unowned binder] in
            if !binder.loadingOrSuccessed {
                binder.start()
            }
        }
    }
}

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

    /// Sets a placeholder `View` which shows when loading the image.
    /// - Parameter content: A view that describes the placeholder.
    /// - Returns: A `KFImage` view that contains `content` as its placeholder.
    public func placeholder<Content: View>(@ViewBuilder _ content: () -> Content) -> KFImage {
        let v = content()
        var result = self
        result.placeholder = AnyView(v)
        return result
    }

    /// Sets cancelling the download task bound to `self` when the view disappearing.
    /// - Parameter flag: Whether cancel the task or not.
    /// - Returns: A `KFImage` view that cancels downloading task when disappears.
    public func cancelOnDisappear(_ flag: Bool) -> KFImage {
        var result = self
        result.cancelOnDisappear = flag
        return result
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    /// Sets the action to perform when the image setting fails.
    /// - Parameter action: The action to perform. If `action` is `nil`, the
    ///   call has no effect.
    /// - Returns: A `KFImage` view that triggers `action` when setting image fails.
    public func onFailure(perform action: ((KingfisherError) -> Void)?) -> KFImage {
        binder.setOnFailure(perform: action)
        return self
    }

    /// Sets the action to perform when the image setting successes.
    /// - Parameter action: The action to perform. If `action` is `nil`, the
    ///   call has no effect.
    /// - Returns: A `KFImage` view that triggers `action` when setting image successes.
    public func onSuccess(perform action: ((RetrieveImageResult) -> Void)?) -> KFImage {
        binder.setOnSuccess(perform: action)
        return self
    }

    /// Sets the action to perform when the image downloading progress receiving new data.
    /// - Parameter action: The action to perform. If `action` is `nil`, the
    ///   call has no effect.
    /// - Returns: A `KFImage` view that triggers `action` when new data arrives when downloading.
    public func onProgress(perform action: ((Int64, Int64) -> Void)?) -> KFImage {
        binder.setOnProgress(perform: action)
        return self
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
