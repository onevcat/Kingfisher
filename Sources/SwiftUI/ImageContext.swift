//
//  ImageContext.swift
//  Kingfisher
//
//  Created by JP20028 on 2021/05/08.
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
extension KFImage {
    public struct Context<HoldingView: KFImageHoldingView> {
        var binder: ImageBinder
        var configurations: [(HoldingView) -> HoldingView] = []
        var cancelOnDisappear: Bool = false
        var placeholder: AnyView? = nil

        init(binder: ImageBinder) {
            self.binder = binder
        }
    }
}

#if canImport(UIKit) && !os(watchOS)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFAnimatedImage {
    public typealias Context = KFImage.Context
    typealias ImageBinder = KFImage.ImageBinder
}
#endif

#endif
