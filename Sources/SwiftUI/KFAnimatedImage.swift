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

#if canImport(SwiftUI) && canImport(Combine) && canImport(UIKit) && !os(watchOS)
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFAnimatedImage: KFImageProtocol {
    public typealias HoldingView = KFAnimatedImageViewRepresenter
    public var context: Context<HoldingView>
    public init(context: KFImage.Context<HoldingView>) {
        self.context = context
    }
}

/// A wrapped `UIViewRepresentable` of `AnimatedImageView`
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFAnimatedImageViewRepresenter: UIViewRepresentable, KFImageHoldingView {
    public static func created(from image: KFCrossPlatformImage) -> KFAnimatedImageViewRepresenter {
        KFAnimatedImageViewRepresenter(image: image)
    }
    
    var image: KFCrossPlatformImage?
    
    public func makeUIView(context: Context) -> AnimatedImageView {
        let view = AnimatedImageView()
        view.image = image
        
        // Allow SwiftUI scale (fit/fill) working fine.
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }
    
    public func updateUIView(_ uiView: AnimatedImageView, context: Context) {
        uiView.image = image
    }
    
}

#if DEBUG
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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
