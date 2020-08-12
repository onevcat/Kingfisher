//
//  AVAssetImageDataProvider.swift
//  Kingfisher
//
//  Created by onevcat on 2020/08/09.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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

import Foundation
import AVKit

#if canImport(MobileCoreServices)
import MobileCoreServices
#else
import CoreServices
#endif

public struct AVAssetImageDataProvider: ImageDataProvider {

    public enum AVAssetImageDataProviderError: Error {
        case userCancelled
        case invalidImage(_ image: CGImage?)
    }

    public let assetImageGenerator: AVAssetImageGenerator
    public let time: CMTime

    private var internalKey: String {
        return (assetImageGenerator.asset as? AVURLAsset)?.url.absoluteString ?? UUID().uuidString
    }

    public var cacheKey: String {
        return "\(internalKey)_\(time.seconds)"
    }

    public init(assetImageGenerator: AVAssetImageGenerator, time: CMTime) {
        self.assetImageGenerator = assetImageGenerator
        self.time = time
    }

    public init(assetURL: URL, time: CMTime) {
        let asset = AVAsset(url: assetURL)
        let generator = AVAssetImageGenerator(asset: asset)
        self.init(assetImageGenerator: generator, time: time)
    }

    public init(assetURL: URL, seconds: TimeInterval) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        self.init(assetURL: assetURL, time: time)
    }

    public func data(handler: @escaping (Result<Data, Error>) -> Void) {
        assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) {
            (requestedTime, image, imageTime, result, error) in
            if let error = error {
                handler(.failure(error))
                return
            }

            if result == .cancelled {
                handler(.failure(AVAssetImageDataProviderError.userCancelled))
                return
            }

            guard let cgImage = image, let data = cgImage.jpegData else {
                handler(.failure(AVAssetImageDataProviderError.invalidImage(image)))
                return
            }

            handler(.success(data))
        }
    }
}

extension CGImage {
    var jpegData: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeJPEG, 1, nil)
        else {
            return nil
        }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

#endif
