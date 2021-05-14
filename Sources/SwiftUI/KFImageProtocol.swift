//
//  KFImageProtocol.swift
//  Kingfisher
//
//  Created by onevcat on 2021/05/08.
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol KFImageProtocol: View, KFOptionSetter {
    associatedtype HoldingView: KFImageHoldingView
    var context: KFImage.Context<HoldingView> { get set }
    init(context: KFImage.Context<HoldingView>)
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImageProtocol {
    public var body: some View {
        KFImageRenderer<HoldingView>(context)
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
    public func loadImmediately(_ start: Bool = true) -> Self {
        if start {
            context.binder.start()
        }
        return self
    }
    
    /// Creates a Kingfisher compatible image view to load image from the given `Source`.
    /// - Parameters:
    ///   - source: The image `Source` defining where to load the target image.
    ///   - isLoaded: Whether the image is loaded or not. This provides a way to inspect the internal loading
    ///               state. `true` if the image is loaded successfully. Otherwise, `false`. Do not set the
    ///               wrapped value from outside.
    public init(source: Source?, isLoaded: Binding<Bool> = .constant(false)) {
        let binder = KFImage.ImageBinder(source: source, isLoaded: isLoaded)
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

    init(binder: KFImage.ImageBinder) {
        self.init(context: KFImage.Context<HoldingView>(binder: binder))
    }
    
    /// Configures current image with a `block`. This block will be lazily applied when creating the final `Image`.
    /// - Parameter block: The block applies to loaded image.
    /// - Returns: A `KFImage` view that configures internal `Image` with `block`.
    public func configure(_ block: @escaping (HoldingView) -> HoldingView) -> Self {
        var result = self
        result.context.configurations.append(block)
        return result
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol KFImageHoldingView: View {
    static func created(from image: KFCrossPlatformImage) -> Self
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImageProtocol {
    public var options: KingfisherParsedOptionsInfo {
        get { context.binder.options }
        nonmutating set { context.binder.options = newValue }
    }

    public var onFailureDelegate: Delegate<KingfisherError, Void> { context.binder.onFailureDelegate }
    public var onSuccessDelegate: Delegate<RetrieveImageResult, Void> { context.binder.onSuccessDelegate }
    public var onProgressDelegate: Delegate<(Int64, Int64), Void> { context.binder.onProgressDelegate }

    public var delegateObserver: AnyObject { context.binder }
}


#endif
