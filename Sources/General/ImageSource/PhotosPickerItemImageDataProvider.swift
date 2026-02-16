//
//  PhotosPickerItemImageDataProvider.swift
//  Kingfisher
//
//  Created by nuomi1 on 2026/1/7.
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
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
import SwiftUI

/// A data provider to provide image data from a given `PhotosPickerItem`.
@available(iOS 16.0, macOS 13.0, *)
public struct PhotosPickerItemImageDataProvider: ImageDataProvider {

    internal static func _cacheKey(
        providedCacheKey: String?,
        itemIdentifier: String?,
        uuidString: () -> String
    ) -> String {
        if let providedCacheKey {
            return providedCacheKey
        }
        if let itemIdentifier {
            return itemIdentifier
        }
        return uuidString()
    }

    /// The possible error might be caused by the `PhotosPickerItemImageDataProvider`.
    /// - invalidImage: The retrieved image is invalid.
    public enum PhotosPickerItemImageDataProviderError: Error {
        /// An error happens during picking up image through the item provider of `PhotosPickerItem`.
        case pickerProviderError(any Error)
        /// The retrieved image is invalid.
        case invalidImage
    }

    /// The picker item bound to `self`.
    public let pickerItem: PhotosPickerItem

    /// The key used in cache.
    ///
    /// If you pass a custom key when creating the provider, it will be used.
    /// Otherwise, if the picker item provides a stable identifier, it will be used.
    /// If no stable identifier is available, a random UUID will be generated and used for this provider instance.
    public let cacheKey: String

    /// Creates an image data provider from a given `PhotosPickerItem`.
    /// - Parameters:
    ///  - pickerItem: The picker item to provide image data.
    ///  - cacheKey: Optional cache key to use. If set, it will be used as `self.cacheKey` directly.
    public init(pickerItem: PhotosPickerItem, cacheKey: String? = nil) {
        self.pickerItem = pickerItem

        if cacheKey == nil && pickerItem.itemIdentifier == nil {
            assertionFailure("[Kingfisher] Should use `PHPhotoLibrary.shared()` to pick image.")
        }

        self.cacheKey = Self._cacheKey(
            providedCacheKey: cacheKey,
            itemIdentifier: pickerItem.itemIdentifier,
            uuidString: { UUID().uuidString }
        )
    }

    public func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        pickerItem.loadTransferable(type: Data.self, completionHandler: { result in
            switch result {
            case let .success(data):
                if let data {
                    handler(.success(data))
                } else {
                    handler(.failure(PhotosPickerItemImageDataProviderError.invalidImage))
                }
            case let .failure(error):
                handler(.failure(PhotosPickerItemImageDataProviderError.pickerProviderError(error)))
            }
        })
    }
}

#endif
