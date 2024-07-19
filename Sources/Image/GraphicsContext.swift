//
//  GraphicsContext.swift
//  Kingfisher
//
//  Created by taras on 19/04/2021.
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

#if os(macOS) || os(watchOS)

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

enum GraphicsContext {
    static func begin(size: CGSize, scale: CGFloat) {
        #if os(macOS)
        NSGraphicsContext.saveGraphicsState()
        #elseif os(watchOS)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        #else
        assertionFailure("This method is deprecated on the current platform and should not be used.")
        #endif
    }
    
    static func current(size: CGSize, scale: CGFloat, inverting: Bool, cgImage: CGImage?) -> CGContext? {
        #if os(macOS)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: cgImage?.bitsPerComponent ?? 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0) else
        {
            assertionFailure("[Kingfisher] Image representation cannot be created.")
            return nil
        }
        rep.size = size
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            assertionFailure("[Kingfisher] Image context cannot be created.")
            return nil
        }
        
        NSGraphicsContext.current = context
        return context.cgContext
        #elseif os(watchOS)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        if inverting { // If drawing a CGImage, we need to make context flipped.
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0, y: -size.height)
        }
        return context
        #else
        assertionFailure("This method is deprecated on the current platform and should not be used.")
        return nil
        #endif
    }
    
    static func end() {
        #if os(macOS)
        NSGraphicsContext.restoreGraphicsState()
        #elseif os(watchOS)
        UIGraphicsEndImageContext()
        #else
        assertionFailure("This method is deprecated on the current platform and should not be used.")
        #endif
    }
}

#endif
