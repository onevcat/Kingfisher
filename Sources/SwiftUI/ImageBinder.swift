//
//  ImageBinder.swift
//  Kingfisher
//
//  Created by onevcat on 2019/06/27.
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

#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    /// Represents a binder for `KFImage`. It takes responsibility as an `ObjectBinding` and performs
    /// image downloading and progress reporting based on `KingfisherManager`.
    class ImageBinder {

        let source: Source?
        var options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions)

        var downloadTask: DownloadTask?

        var loadingOrSucceeded: Bool = false

        let onFailureDelegate = Delegate<KingfisherError, Void>()
        let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        let onProgressDelegate = Delegate<(Int64, Int64), Void>()

        var isLoaded: Binding<Bool>

        var loadedImage: KFCrossPlatformImage? = nil

        @available(*, deprecated, message: "The `options` version is deprecated And will be removed soon.")
        init(source: Source?, options: KingfisherOptionsInfo? = nil, isLoaded: Binding<Bool>) {
            self.source = source
            // The refreshing of `KFImage` would happen much more frequently then an `UIImageView`, even as a
            // "side-effect". To prevent unintended flickering, add `.loadDiskFileSynchronously` as a default.
            self.options = KingfisherParsedOptionsInfo(
                KingfisherManager.shared.defaultOptions +
                (options ?? []) +
                [.loadDiskFileSynchronously]
            )
            self.isLoaded = isLoaded
        }

        init(source: Source?, isLoaded: Binding<Bool>) {
            self.source = source
            // The refreshing of `KFImage` would happen much more frequently then an `UIImageView`, even as a
            // "side-effect". To prevent unintended flickering, add `.loadDiskFileSynchronously` as a default.
            self.options = KingfisherParsedOptionsInfo(
                KingfisherManager.shared.defaultOptions +
                [.loadDiskFileSynchronously]
            )
            self.isLoaded = isLoaded
        }

        func start(_ done: @escaping (Result<RetrieveImageResult, KingfisherError>) -> Void) {

            guard !loadingOrSucceeded else { return }

            loadingOrSucceeded = true

            guard let source = source else {
                CallbackQueue.mainCurrentOrAsync.execute {
                    self.onFailureDelegate.call(KingfisherError.imageSettingError(reason: .emptySource))
                }
                return
            }

            downloadTask = KingfisherManager.shared
                .retrieveImage(
                    with: source,
                    options: options,
                    progressBlock: { size, total in
                        self.onProgressDelegate.call((size, total))
                    },
                    completionHandler: { [weak self] result in

                        guard let self = self else { return }

                        self.downloadTask = nil
                        switch result {
                        case .success(let value):
                            self.loadedImage = value.image
                            let r = RetrieveImageResult(
                                image: value.image, cacheType: value.cacheType, source: value.source, originalSource: value.originalSource
                            )
                            CallbackQueue.mainCurrentOrAsync.execute {
                                done(.success(r))
                            }

                            CallbackQueue.mainAsync.execute {
                                self.isLoaded.wrappedValue = true
                                self.onSuccessDelegate.call(value)
                            }
                        case .failure(let error):
                            self.loadingOrSucceeded = false
                            CallbackQueue.mainCurrentOrAsync.execute {
                                done(.failure(error))
                            }
                            CallbackQueue.mainAsync.execute {
                                self.onFailureDelegate.call(error)
                            }
                        }
                })
        }

        /// Cancels the download task if it is in progress.
        func cancel() {
            downloadTask?.cancel()
        }
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage.ImageBinder: Hashable {
    static func == (lhs: KFImage.ImageBinder, rhs: KFImage.ImageBinder) -> Bool {
        lhs.source == rhs.source && lhs.options.processor.identifier == rhs.options.processor.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(options.processor.identifier)
    }
}
#endif
