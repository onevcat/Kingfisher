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

#if canImport(SwiftUI) && canImport(Combine) && !os(watchOS)
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct KFAnimatedImage: KFImageProtocol {
    public typealias HoldingView = KFAnimatedImageViewRepresenter
    public var context: Context<HoldingView>
    public init(context: KFImage.Context<HoldingView>) {
        self.context = context
    }
    
    /// Configures current rendering view with a `block`. This block will be applied when the under-hood
    /// `AnimatedImageView` is created in `UIViewRepresentable.makeUIView(context:)`
    ///
    /// - Parameter block: The block applies to the animated image view.
    /// - Returns: A `KFAnimatedImage` view that being configured by the `block`.
    public func configure(_ block: @escaping (HoldingView.RenderingView) -> Void) -> Self {
        context.renderConfigurations.append(block)
        return self
    }
}

#if os(macOS)
@available(macOS 11.0, *)
typealias KFCrossPlatformViewRepresentable = NSViewRepresentable
#else
@available(iOS 14.0, tvOS 14.0, watchOS 7.0, *)
typealias KFCrossPlatformViewRepresentable = UIViewRepresentable
#endif

/// A wrapped `UIViewRepresentable` of `AnimatedImageView`
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct KFAnimatedImageViewRepresenter: KFCrossPlatformViewRepresentable, KFImageHoldingView {
    public typealias RenderingView = AnimatedImageView
    public static func created(from image: KFCrossPlatformImage?, context: KFImage.Context<Self>) -> KFAnimatedImageViewRepresenter {
        KFAnimatedImageViewRepresenter(image: image, context: context)
    }
    
    var image: KFCrossPlatformImage?
    let context: KFImage.Context<KFAnimatedImageViewRepresenter>
    
    #if os(macOS)
    public func makeNSView(context: Context) -> AnimatedImageView {
        return makeImageView()
    }
    
    public func updateNSView(_ nsView: AnimatedImageView, context: Context) {
        updateImageView(nsView)
    }
    #else
    public func makeUIView(context: Context) -> AnimatedImageView {
        return makeImageView()
    }
    
    public func updateUIView(_ uiView: AnimatedImageView, context: Context) {
        updateImageView(uiView)
    }
    #endif
    
    private func makeImageView() -> AnimatedImageView {
        let view = AnimatedImageView()
        
        self.context.renderConfigurations.forEach { $0(view) }
        
        view.image = image
        
        // Allow SwiftUI scale (fit/fill) working fine.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }
    
    private func updateImageView(_ imageView: AnimatedImageView) {
        imageView.image = image
    }
}

#if DEBUG
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct KFAnimatedImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KFAnimatedImage(source: .network(URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/1.gif")!))
                .onSuccess { r in
                    print(r)
                }
                .placeholder {
                    ProgressView()
                }
                .padding()
        }
    }
}
#endif
#endif
