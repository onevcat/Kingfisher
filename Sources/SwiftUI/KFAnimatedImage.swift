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
public struct KFAnimatedImage: KFImageProtocol {
    
    public typealias Context = KFImage.Context
    typealias ImageBinder = KFImage.ImageBinder
    
    public typealias HoldingView = KFAnimatedImageViewRepresenter
    
    public var context: Context<HoldingView>

    public init(context: KFImage.Context<HoldingView>) {
        self.context = context
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

    init(_ context: KFAnimatedImage.Context<Image>) {
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
public struct KFAnimatedImageViewRepresenter: UIViewRepresentable, KFImageHoldingView {
    public static func created(from image: KFCrossPlatformImage) -> KFAnimatedImageViewRepresenter {
        KFAnimatedImageViewRepresenter(image: image)
    }
    
    var image: KFCrossPlatformImage?
    
    public func makeUIView(context: Context) -> AnimatedImageView {
        let view = AnimatedImageView()
        view.image = image
        return view
    }
    
    public func updateUIView(_ uiView: AnimatedImageView, context: Context) {
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
                .padding()
        }
    }
}
#endif

#endif
