//
//  KingfisherTestHelper.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/10.
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

import Foundation
@testable import Kingfisher
import CoreGraphics

let testImageString =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAD8GlDQ1BJQ0MgUHJvZmlsZQAAOI2NVd1v21QUP4lvXKQWP6Cxjg4Vi69VU1u5GxqtxgZJk6XpQhq5zdgqpMl1bhpT1za2021V" +
    "n/YCbwz4A4CyBx6QeEIaDMT2su0BtElTQRXVJKQ9dNpAaJP2gqpwrq9Tu13GuJGvfznndz7v0TVAx1ea45hJGWDe8l01n5GPn5iWO1YhCc9BJ/RAp6Z7TrpcLgIuxoVH1sNfIcHeNwfa6/9z" +
    "dVappwMknkJsVz19HvFpgJSpO64PIN5G+fAp30Hc8TziHS4miFhheJbjLMMzHB8POFPqKGKWi6TXtSriJcT9MzH5bAzzHIK1I08t6hq6zHpRdu2aYdJYuk9Q/881bzZa8Xrx6fLmJo/iu4/V" +
    "XnfH1BB/rmu5ScQvI77m+BkmfxXxvcZcJY14L0DymZp7pML5yTcW61PvIN6JuGr4halQvmjNlCa4bXJ5zj6qhpxrujeKPYMXEd+q00KR5yNAlWZzrF+Ie+uNsdC/MO4tTOZafhbroyXuR3Df" +
    "08bLiHsQf+ja6gTPWVimZl7l/oUrjl8OcxDWLbNU5D6JRL2gxkDu16fGuC054OMhclsyXTOOFEL+kmMGs4i5kfNuQ62EnBuam8tzP+Q+tSqhz9SuqpZlvR1EfBiOJTSgYMMM7jpYsAEyqJCH" +
    "DL4dcFFTAwNMlFDUUpQYiadhDmXteeWAw3HEmA2s15k1RmnP4RHuhBybdBOF7MfnICmSQ2SYjIBM3iRvkcMki9IRcnDTthyLz2Ld2fTzPjTQK+Mdg8y5nkZfFO+se9LQr3/09xZr+5GcaSuf" +
    "eAfAww60mAPx+q8u/bAr8rFCLrx7s+vqEkw8qb+p26n11Aruq6m1iJH6PbWGv1VIY25mkNE8PkaQhxfLIF7DZXx80HD/A3l2jLclYs061xNpWCfoB6WHJTjbH0mV35Q/lRXlC+W8cndbl9t2" +
    "SfhU+Fb4UfhO+F74GWThknBZ+Em4InwjXIyd1ePnY/Psg3pb1TJNu15TMKWMtFt6ScpKL0ivSMXIn9QtDUlj0h7U7N48t3i8eC0GnMC91dX2sTivgloDTgUVeEGHLTizbf5Da9JLhkhh29QO" +
    "s1luMcScmBXTIIt7xRFxSBxnuJWfuAd1I7jntkyd/pgKaIwVr3MgmDo2q8x6IdB5QH162mcX7ajtnHGN2bov71OU1+U0fqqoXLD0wX5ZM005UHmySz3qLtDqILDvIL+iH6jB9y2x83ok898G" +
    "OPQX3lk3Itl0A+BrD6D7tUjWh3fis58BXDigN9yF8M5PJH4B8Gr79/F/XRm8m241mw/wvur4BGDj42bzn+Vmc+NL9L8GcMn8F1kAcXgSteGGAAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlU" +
    "WHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9" +
    "Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJo" +
    "dHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8" +
    "L3JkZjpSREY+CjwveDp4bXBtZXRhPgpMwidZAAAKZklEQVR4Ae2ax28VyxLGywYMJuecgwgSIILIgg1pQRRJQrBkxZr9/RNYAhJiA0gEIbIE6JEzIggQIKLJOefod351+fzmzps5njke3wV2" +
    "SeM+Mx2qvq+qq3t6XNS1a9fyHz9+WE2V4poMHqcX11TPC3ctAWKippa1EVBTPS/cNT4C6oqJf7MsKiqKVVdeXh5bVx0V/woBcYCDYNVGpcAG2+hZlmW1EgAYrl+/ftnPnz+NTdenT5/s8+fP" +
    "sRgaN25sDRo0sLp161pxcbFfkFBdRFQLAQIO6G/fvtmHDx8cwMCBA61Pnz7WqVMna9GihQG2fv36Tsj79+/t5cuXdu/ePbt165ZdunTJGjVqZKWlpVZSUuJEQGTWkjkBeA1D8fKXL1+sd+/e" +
    "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" +
    "DwAAAABJRU5ErkJggg=="

var testImage = KFCrossPlatformImage(data: testImageData)!
let testImageData = Data(base64Encoded: testImageString)!

let testImagePNGData = testImage.kf.pngRepresentation()!
let testImageJEPGData = testImage.kf.jpegRepresentation(compressionQuality: 1.0)!
let testImageGIFData = Data(fileName: "dancing-banana.gif")
let testImageSingleFrameGIFData = Data(fileName: "single-frame.gif")

let testKeys = [
    "http://stackoverflow.com/questions/11251340/convert-image-to-base64-string-in-ios-swift",
    "https://onevcat.com",
    "http://onevcat.com/content/images/2014/May/200.jpg",
    "http://onevcat.com/content/images/2014/May/200.jpg?fads#kj1asf"
]

let testURLs = testKeys.map { URL(string: $0)! }

func cleanDefaultCache() {
    let cache = KingfisherManager.shared.cache
    cache.clearMemoryCache()
    try? cache.diskStorage.removeAll()
}

func clearCaches(_ caches: [ImageCache]) {
    for c in caches {
        c.clearMemoryCache()
        try? c.diskStorage.removeAll(skipCreatingDirectory: true)
    }
}

func delay(_ time: Double, block: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + time) { block() }
}

extension KFCrossPlatformImage {
    func renderEqual(to image: KFCrossPlatformImage, withinTolerance tolerance: UInt8 = 3) -> Bool {
        
        guard size == image.size else { return false }
        guard let imageData1 = kf.pngRepresentation(),
              let imageData2 = image.kf.pngRepresentation() else
        {
            return false
        }
        guard let unifiedImage1 = KFCrossPlatformImage(data: imageData1),
              let unifiedImage2 = KFCrossPlatformImage(data: imageData2) else
        {
            return false
        }
        
        guard let rendered1 = unifiedImage1.rendered(),
              let rendered2 = unifiedImage2.rendered() else
        {
            return false
        }
        guard let data1 = rendered1.kf.cgImage?.dataProvider?.data,
              let data2 = rendered2.kf.cgImage?.dataProvider?.data else
        {
            return false
        }
        
        let length1 = CFDataGetLength(data1)
        let length2 = CFDataGetLength(data2)
        guard length1 == length2 else { return false }
        
        let dataPtr1: UnsafePointer<UInt8> = CFDataGetBytePtr(data1)
        let dataPtr2: UnsafePointer<UInt8> = CFDataGetBytePtr(data2)
        
        for index in 0..<length1 {
            let byte1 = dataPtr1[index]
            let byte2 = dataPtr2[index]
            let delta = UInt8(abs(Int(byte1) - Int(byte2)))
            
            guard delta <= tolerance else {
                return false
            }
        }
        
        return true
    }
    
    func rendered() -> KFCrossPlatformImage? {
        // Ignore non CG images
        guard let cgImage = kf.cgImage else {
            return nil
        }
        
        var bitmapInfo = cgImage.bitmapInfo
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let alpha = (bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
        
        let w = cgImage.width
        let h = cgImage.height
        
        let size = CGSize(width: w, height: h)
        
        if alpha == CGImageAlphaInfo.none.rawValue {
            bitmapInfo.remove(.alphaInfoMask)
            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        } else if !(alpha == CGImageAlphaInfo.noneSkipFirst.rawValue) ||
                  !(alpha == CGImageAlphaInfo.noneSkipLast.rawValue)
        {
            bitmapInfo.remove(.alphaInfoMask)
            bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        }
        
        // Render the image
        guard let context = CGContext(data: nil,
                                      width: w,
                                      height: h,
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else
        {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: size))
        
        #if os(macOS)
        return context.makeImage().flatMap { KFCrossPlatformImage(cgImage: $0, size: kf.size) }
        #else
        return context.makeImage().flatMap { KFCrossPlatformImage(cgImage: $0) }
        #endif
    }
}

#if os(iOS) || os(tvOS)
import UIKit
extension KFCrossPlatformImage {
    static func from(color: KFCrossPlatformColor, size: CGSize) -> KFCrossPlatformImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
#endif

extension Data {
    init(fileName: String) {
        let comp = fileName.components(separatedBy: ".")
        guard comp.count == 2 else { fatalError() }
        self.init(named: comp[0], type: comp[1])
    }
    
    init(named name: String, type: String) {
        guard let path = Bundle.test.path(forResource: name, ofType: type) else {
            fatalError()
        }
        try! self.init(contentsOf: URL(fileURLWithPath: path))
    }
}

extension Bundle {
    static let test: Bundle = Bundle(for: ImageExtensionTests.self)
}

// Make tests happier with old Result type
extension Result {
    var value: Success? {
        switch self {
        case .success(let success): return success
        case .failure: return nil
        }
    }

    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let failure): return failure
        }
    }
}
