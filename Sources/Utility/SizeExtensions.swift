//
//  SizeExtensions.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/28.
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

import CoreGraphics

extension CGSize: KingfisherCompatibleValue {}
extension KingfisherWrapper where Base == CGSize {
    
    /// Returns a size by resizing the `base` size to a target size under a given content mode.
    ///
    /// - Parameters:
    ///   - size: The target size to resize to.
    ///   - contentMode: Content mode of the target size should be when resizing.
    /// - Returns: The resized size under the given `ContentMode`.
    public func resize(to size: CGSize, for contentMode: ContentMode) -> CGSize {
        switch contentMode {
        case .aspectFit:
            return constrained(size)
        case .aspectFill:
            return filling(size)
        case .none:
            return size
        }
    }
    
    /// Returns a size by resizing the `base` size by making it aspect fitting the given `size`.
    ///
    /// - Parameter size: The size in which the `base` should fit in.
    /// - Returns: The size fitted in by the input `size`, while keeps `base` aspect.
    public func constrained(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)
        
        return aspectWidth > size.width ?
            CGSize(width: size.width, height: aspectHeight) :
            CGSize(width: aspectWidth, height: size.height)
    }
    
    /// Returns a size by resizing the `base` size by making it aspect filling the given `size`.
    ///
    /// - Parameter size: The size in which the `base` should fill.
    /// - Returns: The size be filled by the input `size`, while keeps `base` aspect.
    public func filling(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)
        
        return aspectWidth < size.width ?
            CGSize(width: size.width, height: aspectHeight) :
            CGSize(width: aspectWidth, height: size.height)
    }
    
    /// Returns a `CGRect` for which the `base` size is constrained to an input `size` at a given `anchor` point.
    ///
    /// - Parameters:
    ///   - size: The size in which the `base` should be constrained to.
    ///   - anchor: An anchor point in which the size constraint should happen.
    /// - Returns: The result `CGRect` for the constraint operation.
    public func constrainedRect(for size: CGSize, anchor: CGPoint) -> CGRect {
        
        let unifiedAnchor = CGPoint(x: anchor.x.clamped(to: 0.0...1.0),
                                    y: anchor.y.clamped(to: 0.0...1.0))
        
        let x = unifiedAnchor.x * base.width - unifiedAnchor.x * size.width
        let y = unifiedAnchor.y * base.height - unifiedAnchor.y * size.height
        let r = CGRect(x: x, y: y, width: size.width, height: size.height)
        
        let ori = CGRect(origin: .zero, size: base)
        return ori.intersection(r)
    }
    
    private var aspectRatio: CGFloat {
        return base.height == 0.0 ? 1.0 : base.width / base.height
    }
}

extension CGRect {
    func scaled(_ scale: CGFloat) -> CGRect {
        return CGRect(x: origin.x * scale, y: origin.y * scale,
                      width: size.width * scale, height: size.height * scale)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
