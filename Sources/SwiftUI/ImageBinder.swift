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
#if !KingfisherCocoaPods
import Kingfisher
#endif

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    /// Represents a binder for `KFImage`. It takes responsibility as an `ObjectBinding` and performs
    /// image downloading and progress reporting based on `KingfisherManager`.
    public class ImageBinder: ObservableObject {

        let source: Source?
        let options: KingfisherOptionsInfo?

        var downloadTask: DownloadTask?

        var loadingOrSucceeded: Bool = false

        let onFailureDelegate = Delegate<KingfisherError, Void>()
        let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        let onProgressDelegate = Delegate<(Int64, Int64), Void>()

        var isLoaded: Binding<Bool>

        @Published var image: KFCrossPlatformImage?

        init(source: Source?, options: KingfisherOptionsInfo?, isLoaded: Binding<Bool>) {
            self.source = source
            // The refreshing of `KFImage` would happen much more frequently then an `UIImageView`, even as a
            // "side-effect". To prevent unintended flickering, add `.loadDiskFileSynchronously` as a default.
            self.options = (options ?? []) + [.loadDiskFileSynchronously]
            self.isLoaded = isLoaded
            self.image = nil
        }

        func start() {

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
                            // The normalized version of image is used to solve #1395
                            // It should be not necessary if SwiftUI.Image can handle resizing correctly when created
                            // by `Image.init(uiImage:)`. (The orientation information should be already contained in
                            // a `UIImage`)
                            // https://github.com/onevcat/Kingfisher/issues/1395
                            let image = value.image.kf.normalized
                            CallbackQueue.mainCurrentOrAsync.execute {
                                self.image = image
                            }
                            CallbackQueue.mainAsync.execute {
                                self.isLoaded.wrappedValue = true
                                self.onSuccessDelegate.call(value)
                            }
                        case .failure(let error):
                            self.loadingOrSucceeded = false
                            CallbackQueue.mainAsync.execute {
                                self.onFailureDelegate.call(error)
                            }
                        }
                })
        }

        /// Cancels the download task if it is in progress.
        public func cancel() {
            downloadTask?.cancel()
        }

        func setOnFailure(perform action: ((KingfisherError) -> Void)?) {
            onFailureDelegate.delegate(on: self) { (self, error) in
                action?(error)
            }
        }

        func setOnSuccess(perform action: ((RetrieveImageResult) -> Void)?) {
            onSuccessDelegate.delegate(on: self) { (self, result) in
                action?(result)
            }
        }

        func setOnProgress(perform action: ((Int64, Int64) -> Void)?) {
            onProgressDelegate.delegate(on: self) { (self, result) in
                action?(result.0, result.1)
            }
        }
    }
}
#endif
