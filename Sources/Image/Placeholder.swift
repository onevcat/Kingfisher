//
//  Placeholder.swift
//  Kingfisher
//
//  Created by Tieme van Veen on 28/08/2017.
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

#if !os(watchOS)

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Represents a placeholder type that could be set during loading as well as when loading is finished without
/// getting an image.
public protocol Placeholder {
    
    /// Called when the placeholder needs to be added to a given image view.
    /// 
    /// To conform to ``Placeholder``, you implement this method and add your own placeholder view to the 
    /// given `imageView`.
    ///
    /// - Parameter imageView: The image view where the placeholder should be added to.
    @MainActor func add(to imageView: KFCrossPlatformImageView)
    
    /// Called when the placeholder needs to be removed from a given image view.
    ///
    /// To conform to ``Placeholder``, you implement this method and remove your own placeholder view from the
    /// given `imageView`.
    ///
    /// - Parameter imageView: The image view where the placeholder is already added to and now should be removed from.
    @MainActor func remove(from imageView: KFCrossPlatformImageView)
}

@MainActor
extension KFCrossPlatformImage: Placeholder {
    public func add(to imageView: KFCrossPlatformImageView) {
        imageView.image = self
    }
    
    public func remove(from imageView: KFCrossPlatformImageView) {
        imageView.image = nil
    }
    
    public func add(to base: any KingfisherHasImageComponent) {
        base.image = self
    }
    
    public func remove(from base: any KingfisherHasImageComponent) {
        base.image = nil
    }
}

/// Default implementation of an arbitrary view as a placeholder. The view will be
/// added as a subview when adding and removed from its superview when removing.
///
/// To use your customized View type as a placeholder, simply have it conform to
/// `Placeholder` using an extension: `extension MyView: Placeholder {}`.
@MainActor
extension Placeholder where Self: KFCrossPlatformView {
    
    public func add(to imageView: KFCrossPlatformImageView) {
        imageView.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        heightAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
    }

    public func remove(from imageView: KFCrossPlatformImageView) {
        removeFromSuperview()
    }
}

#endif
