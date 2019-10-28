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

        var loadingOrSuccessed: Bool = false

        let onFailureDelegate = Delegate<KingfisherError, Void>()
        let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        let onProgressDelegate = Delegate<(Int64, Int64), Void>()

        @Published var image: KFCrossPlatformImage?

        init(source: Source?, options: KingfisherOptionsInfo?) {
            self.source = source
            self.options = options
            self.image = nil
        }

        func start() {

            guard !loadingOrSuccessed else { return }

            loadingOrSuccessed = true

            guard let source = source else {
                DispatchQueue.main.async {
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
                            self.image = value.image
                            DispatchQueue.main.async {
                                self.onSuccessDelegate.call(value)
                            }
                        case .failure(let error):
                            self.loadingOrSuccessed = false
                            DispatchQueue.main.async {
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
            onFailureDelegate.delegate(on: self) { _, error in
                action?(error)
            }
        }

        func setOnSuccess(perform action: ((RetrieveImageResult) -> Void)?) {
            onSuccessDelegate.delegate(on: self) { _, result in
                action?(result)
            }
        }

        func setOnProgress(perform action: ((Int64, Int64) -> Void)?) {
            onProgressDelegate.delegate(on: self) { _, result in
                action?(result.0, result.1)
            }
        }
    }
}
#endif
