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

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol KFImageProtocol: View {
    associatedtype HoldingView: KFImageHoldingView
    var context: KFImage.Context<HoldingView> { get }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
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
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol KFImageHoldingView: View {
    static func created(from image: KFCrossPlatformImage) -> Self
}

