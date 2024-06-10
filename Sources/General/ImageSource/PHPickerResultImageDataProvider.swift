//
//  PHPickerResultImageDataProvider.swift
//  Kingfisher
//
//  Created by nuomi1 on 2024-04-17.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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

#if os(iOS) || os(macOS) || os(visionOS)

import PhotosUI

/// A data provider to provide image data from a given `PHPickerResult`.
@available(iOS 14.0, macOS 13.0, *)
public struct PHPickerResultImageDataProvider: ImageDataProvider {

    /// The possible error might be caused by the `PHPickerResultImageDataProvider`.
    /// - invalidImage: The retrieved image is invalid.
    public enum PHPickerResultImageDataProviderError: Error {
        /// The retrieved image is invalid.
        case invalidImage
    }

    /// The picker result bound to `self`.
    public let pickerResult: PHPickerResult

    /// The content type of the image.
    public let contentType: UTType

    private var internalKey: String {
        pickerResult.assetIdentifier ?? UUID().uuidString
    }

    public var cacheKey: String {
        "\(internalKey)_\(contentType.identifier)"
    }

    /// Creates an image data provider from a given `PHPickerResult`.
    /// - Parameters:
    ///  - pickerResult: The picker result to provide image data.
    ///  - contentType: The content type of the image. Default is `UTType.image`.
    public init(pickerResult: PHPickerResult, contentType: UTType = UTType.image) {
        self.pickerResult = pickerResult
        self.contentType = contentType
    }

    public func data(handler: @escaping (Result<Data, Error>) -> Void) {
        pickerResult.itemProvider.loadDataRepresentation(forTypeIdentifier: contentType.identifier) { data, error in
            if let error {
                handler(.failure(error))
                return
            }

            guard let data else {
                handler(.failure(PHPickerResultImageDataProviderError.invalidImage))
                return
            }

            handler(.success(data))
        }
    }
}

#endif
