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

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol KFImageProtocol: View, KFOptionSetter {
    associatedtype HoldingView: KFImageHoldingView
    var context: KFImage.Context<HoldingView> { get set }
    init(context: KFImage.Context<HoldingView>)
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImageProtocol {
    public var body: some View {
        KFImageRenderer<HoldingView>(context: context)
            .id(context)
    }
    
    /// Creates a Kingfisher compatible image view to load image from the given `Source`.
    /// - Parameters:
    ///   - source: The image `Source` defining where to load the target image.
    public init(source: Source?) {
        let context = KFImage.Context<HoldingView>(source: source)
        self.init(context: context)
    }

    /// Creates a Kingfisher compatible image view to load image from the given `URL`.
    /// - Parameters:
    ///   - source: The image `Source` defining where to load the target image.
    public init(_ url: URL?) {
        self.init(source: url?.convertToSource())
    }
    
    /// Configures current image with a `block`. This block will be lazily applied when creating the final `Image`.
    /// - Parameter block: The block applies to loaded image.
    /// - Returns: A `KFImage` view that configures internal `Image` with `block`.
    public func configure(_ block: @escaping (HoldingView) -> HoldingView) -> Self {
        context.configurations.append(block)
        return self
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
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
