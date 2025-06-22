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
import Combine


/// Represents a view that is compatible with Kingfisher in SwiftUI.
///
/// As a framework user, you do not need to know the details of this protocol. As the public types, ``KFImage`` and
/// ``KFAnimatedImage`` conform this type and should be used in your app to represent an image view with network and
/// cache support in SwiftUI.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@MainActor
public protocol KFImageProtocol: View, KFOptionSetter {
    associatedtype HoldingView: KFImageHoldingView & Sendable
    var context: KFImage.Context<HoldingView> { get set }
    init(context: KFImage.Context<HoldingView>)
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImageProtocol {
    @MainActor
    public var body: some View {
        ZStack {
            KFImageRenderer<HoldingView>(
                context: context
            ).id(context)
        }
    }
    
    /// Creates an image view compatible with Kingfisher for loading an image from the provided `Source`.
    ///
    /// - Parameters:
    ///   - source: The `Source` of the image that specifies where to load the target image.
    public init(source: Source?) {
        let context = KFImage.Context<HoldingView>(source: source)
        self.init(context: context)
    }

    /// Creates an image view compatible with Kingfisher for loading an image from the provided `URL`.
    ///
    /// - Parameters:
    ///   - url: The `URL` defining the location from which to load the target image.
    public init(_ url: URL?) {
        self.init(source: url?.convertToSource())
    }
    
    /// Configures the current image with a `block` and returns another `Image` to use as the final content.
    ///
    /// This block will be lazily applied when creating the final `Image`.
    ///
    /// If multiple `configure` modifiers are added to the image, they will be evaluated in order.
    ///
    /// - Parameter block: The block that applies to the loaded image. The block should return an `Image` that is
    ///  configured.
    /// - Returns: A ``KFImage`` or ``KFAnimatedImage`` view that configures the internal `Image` with the provided
    /// `block`.
    ///
    /// > If you want to configure the input image (which is usually an `Image` value) and use a non-`Image` value as
    /// > the configured result, use ``KFImageProtocol/contentConfigure(_:)`` instead.
    public func configure(_ block: @escaping (HoldingView) -> HoldingView) -> Self {
        context.configurations.append(block)
        return self
    }

    /// Configures the current image with a `block` and returns a `View` to use as the final content.
    ///
    /// This block will be lazily applied when creating the final `Image`.
    ///
    /// If multiple `contentConfigure` modifiers are added to the image, only the last one will be stored and used.
    ///
    /// - Parameter block: The block applies to the loaded image. The block should return a `View` that is configured.
    /// - Returns: A ``KFImage`` or ``KFAnimatedImage`` view that configures the internal `Image` with the provided
    /// `block`.
    public func contentConfigure<V: View>(_ block: @escaping (HoldingView) -> V) -> Self {
        context.contentConfiguration = { AnyView(block($0)) }
        return self
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@MainActor
public protocol KFImageHoldingView: View {
    associatedtype RenderingView
    static func created(from image: KFCrossPlatformImage?, context: KFImage.Context<Self>) -> Self
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImageProtocol {
    public var options: KingfisherParsedOptionsInfo {
        get { context.options }
        nonmutating set { context.options = newValue }
    }

    public var onFailureDelegate: Delegate<KingfisherError, Void> { context.onFailureDelegate }
    public var onSuccessDelegate: Delegate<RetrieveImageResult, Void> { context.onSuccessDelegate }
    public var onProgressDelegate: Delegate<(Int64, Int64), Void> { context.onProgressDelegate }

    public var delegateObserver: AnyObject { context }
}


#endif
