//
//  Placeholder.swift
//  Kingfisher
//
//  Created by Tieme van Veen on 28/08/2017.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif


/// Represent a placeholder type which could be set while loading as well as
/// loading finished without getting an image.
public protocol Placeholder {
    
    /// How the placeholder should be added to a given image view.
    func add(to imageView: ImageView)
    
    /// How the placeholder should be removed from a given image view.
    func remove(from imageView: ImageView)
}

/// Default implementation of an image placeholder. The image will be set or 
/// reset directly for `image` property of the image view.
extension Placeholder where Self: Image {
    
    /// How the placeholder should be added to a given image view.
    public func add(to imageView: ImageView) { imageView.image = self }
    
    /// How the placeholder should be removed from a given image view.
    public func remove(from imageView: ImageView) { imageView.image = nil }
}

extension Image: Placeholder {}

/// Default implementation of an arbitrary view as placeholder. The view will be 
/// added as a subview when adding and be removed from its super view when removing.
///
/// To use your customize View type as placeholder, simply let it conforming to 
/// `Placeholder` by `extension MyView: Placeholder {}`.
extension Placeholder where Self: View {
    
    /// How the placeholder should be added to a given image view.
    public func add(to imageView: ImageView) {
        imageView.addSubview(self)

        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: 1, constant: 0)
            ])
    }

    /// How the placeholder should be removed from a given image view.
    public func remove(from imageView: ImageView) {
        self.removeFromSuperview()
    }
}
