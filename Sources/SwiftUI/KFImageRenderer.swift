//
//  KFImageRenderer.swift
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

/// A Kingfisher compatible SwiftUI `View` to load an image from a `Source`.
/// Declaring a `KFImage` in a `View`'s body to trigger loading from the given `Source`.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFImageRenderer<HoldingView> : View where HoldingView: KFImageHoldingView {
    
    /// An image binder that manages loading and cancelling image related task.
    @ObservedObject var binder: KFImage.ImageBinder

    // Acts as a placeholder when loading an image.
    var placeholder: AnyView?

    // Whether the download task should be cancelled when the view disappears.
    let cancelOnDisappear: Bool

    // Configurations should be performed on the image.
    let configurations: [(HoldingView) -> HoldingView]

    init(_ context: KFImage.Context<HoldingView>) {
        self.binder = context.binder
        self.configurations = context.configurations
        self.placeholder = context.placeholder
        self.cancelOnDisappear = context.cancelOnDisappear
    }

    /// Declares the content and behavior of this view.
    @ViewBuilder
    var body: some View {
        if let image = binder.loadedImage {
            configurations
                .reduce(HoldingView.created(from: image)) {
                    current, config in config(current)
                }
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Image {
    // Creates an Image with either UIImage or NSImage.
    init(crossPlatformImage: KFCrossPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: crossPlatformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: crossPlatformImage)
        #endif
    }
}

#if canImport(UIKit)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension UIImage.Orientation {
    func toSwiftUI() -> Image.Orientation {
        switch self {
        case .down: return .down
        case .up: return .up
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
#endif
#endif
