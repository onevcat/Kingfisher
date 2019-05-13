//
//  ImageFormat.swift
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

import Foundation

/// Represents image format.
///
/// - unknown: The format cannot be recognized or not supported yet.
/// - PNG: PNG image format.
/// - JPEG: JPEG image format.
/// - GIF: GIF image format.
public enum ImageFormat {
    /// The format cannot be recognized or not supported yet.
    case unknown
    /// PNG image format.
    case PNG
    /// JPEG image format.
    case JPEG
    /// GIF image format.
    case GIF
    
    struct HeaderData {
        static var PNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        static var JPEG_SOI: [UInt8] = [0xFF, 0xD8]
        static var JPEG_IF: [UInt8] = [0xFF]
        static var GIF: [UInt8] = [0x47, 0x49, 0x46]
    }
    
    /// https://en.wikipedia.org/wiki/JPEG
    public enum JPEGMarker {
        case SOF0           //baseline
        case SOF2           //progressive
        case DHT            //Huffman Table
        case DQT            //Quantization Table
        case DRI            //Restart Interval
        case SOS            //Start Of Scan
        case RSTn(UInt8)    //Restart
        case APPn           //Application-specific
        case COM            //Comment
        case EOI            //End Of Image
        
        var bytes: [UInt8] {
            switch self {
            case .SOF0:         return [0xFF, 0xC0]
            case .SOF2:         return [0xFF, 0xC2]
            case .DHT:          return [0xFF, 0xC4]
            case .DQT:          return [0xFF, 0xDB]
            case .DRI:          return [0xFF, 0xDD]
            case .SOS:          return [0xFF, 0xDA]
            case .RSTn(let n):  return [0xFF, 0xD0 + n]
            case .APPn:         return [0xFF, 0xE0]
            case .COM:          return [0xFF, 0xFE]
            case .EOI:          return [0xFF, 0xD9]
            }
        }
    }
}


extension Data: KingfisherCompatibleValue {}

// MARK: - Misc Helpers
extension KingfisherWrapper where Base == Data {
    /// Gets the image format corresponding to the data.
    public var imageFormat: ImageFormat {
        guard base.count > 8 else { return .unknown }
        
        var buffer = [UInt8](repeating: 0, count: 8)
        base.copyBytes(to: &buffer, count: 8)
        
        if buffer == ImageFormat.HeaderData.PNG {
            return .PNG
            
        } else if buffer[0] == ImageFormat.HeaderData.JPEG_SOI[0],
            buffer[1] == ImageFormat.HeaderData.JPEG_SOI[1],
            buffer[2] == ImageFormat.HeaderData.JPEG_IF[0]
        {
            return .JPEG
            
        } else if buffer[0] == ImageFormat.HeaderData.GIF[0],
            buffer[1] == ImageFormat.HeaderData.GIF[1],
            buffer[2] == ImageFormat.HeaderData.GIF[2]
        {
            return .GIF
        }
        
        return .unknown
    }
    
    public func contains(jpeg marker: ImageFormat.JPEGMarker) -> Bool {
        guard imageFormat == .JPEG else {
            return false
        }
        
        var buffer = [UInt8](repeating: 0, count: base.count)
        base.copyBytes(to: &buffer, count: base.count)
        for (index, item) in buffer.enumerated() {
            guard
                item == marker.bytes.first,
                buffer.count > index + 1,
                buffer[index + 1] == marker.bytes[1] else {
                continue
            }
            return true
        }
        return false
    }
}
