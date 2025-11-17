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
        let descriptor = BitmapContextDescriptor(size: size, cgImage: cgImage)
        guard let context = descriptor.makeContext() else {
            assertionFailure("[Kingfisher] Image context cannot be created.")
            return nil
        }
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        graphicsContext.imageInterpolation = .high
        NSGraphicsContext.current = graphicsContext
        return graphicsContext.cgContext
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

#if os(macOS)
private struct BitmapContextDescriptor {
    let width: Int
    let height: Int
    let bitsPerComponent: Int
    let bytesPerRow: Int
    let colorSpace: CGColorSpace
    let bitmapInfo: CGBitmapInfo
    
    init(size: CGSize, cgImage: CGImage?) {
        width = max(Int(size.width.rounded(.down)), 1)
        height = max(Int(size.height.rounded(.down)), 1)
        colorSpace = BitmapContextDescriptor.resolveColorSpace(from: cgImage)
        bitsPerComponent = BitmapContextDescriptor.supportedBitsPerComponent(from: cgImage)
        let componentCount = colorSpace.numberOfComponents
        let hasAlpha = BitmapContextDescriptor.containsAlpha(from: cgImage)
        bitmapInfo = BitmapContextDescriptor.bitmapInfo(componentCount: componentCount, hasAlpha: hasAlpha)
        let channelsPerPixel = BitmapContextDescriptor.channelsPerPixel(componentCount: componentCount, hasAlpha: hasAlpha)
        let bitsPerPixel = channelsPerPixel * bitsPerComponent
        bytesPerRow = BitmapContextDescriptor.alignedBytesPerRow(bitsPerPixel: bitsPerPixel, width: width)
    }
    
    func makeContext() -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
    }
    
    private static func supportedBitsPerComponent(from cgImage: CGImage?) -> Int {
        guard let bits = cgImage?.bitsPerComponent, bits > 0 else { return 8 }
        if bits <= 8 { return 8 }
        return 16
    }
    
    private static func resolveColorSpace(from cgImage: CGImage?) -> CGColorSpace {
        guard let cgColorSpace = cgImage?.colorSpace else {
            return CGColorSpaceCreateDeviceRGB()
        }
        let components = cgColorSpace.numberOfComponents
        if components == 1 || components == 3 {
            return cgColorSpace
        }
        return CGColorSpaceCreateDeviceRGB()
    }
    
    private static func containsAlpha(from cgImage: CGImage?) -> Bool {
        guard let alphaInfo = cgImage?.alphaInfo else { return true }
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
        }
    }
    
    private static func bitmapInfo(componentCount: Int, hasAlpha: Bool) -> CGBitmapInfo {
        let alphaInfo: CGImageAlphaInfo
        if componentCount == 1 {
            alphaInfo = hasAlpha ? .premultipliedLast : .none
        } else {
            alphaInfo = hasAlpha ? .premultipliedLast : .noneSkipLast
        }
        return CGBitmapInfo(rawValue: alphaInfo.rawValue)
    }
    
    private static func channelsPerPixel(componentCount: Int, hasAlpha: Bool) -> Int {
        if componentCount == 1 {
            return hasAlpha ? 2 : 1
        }
        return hasAlpha ? componentCount + 1 : componentCount + 1
    }
    
    private static func alignedBytesPerRow(bitsPerPixel: Int, width: Int) -> Int {
        let rawBytes = (bitsPerPixel * width + 7) / 8
        return (rawBytes + 0x3F) & ~0x3F
    }
}
#endif
