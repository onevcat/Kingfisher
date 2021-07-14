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
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage {

    /// Represents a binder for `KFImage`. It takes responsibility as an `ObjectBinding` and performs
    /// image downloading and progress reporting based on `KingfisherManager`.
    class ImageBinder: ObservableObject {
        
        init() {}

        var downloadTask: DownloadTask?

        var loadingOrSucceeded: Bool {
            return downloadTask != nil || loadedImage != nil
        }

        @Published var loaded = false
        @Published var loadedImage: KFCrossPlatformImage? = nil
        @Published var progress: Progress = .init()

        func start<HoldingView: KFImageHoldingView>(context: Context<HoldingView>) {

            guard !loadingOrSucceeded else { return }

            guard let source = context.source else {
                CallbackQueue.mainCurrentOrAsync.execute {
                    context.onFailureDelegate.call(KingfisherError.imageSettingError(reason: .emptySource))
                }
                return
            }

            progress = .init()
            downloadTask = KingfisherManager.shared
                .retrieveImage(
                    with: source,
                    options: context.options,
                    progressBlock: { size, total in
                        self.updateProgress(downloaded: size, total: total)
                        context.onProgressDelegate.call((size, total))
                    },
                    completionHandler: { [weak self] result in

                        guard let self = self else { return }

                        self.downloadTask = nil
                        switch result {
                        case .success(let value):

                            CallbackQueue.mainCurrentOrAsync.execute {
                                self.loadedImage = value.image
                                let animation = context.fadeTransitionDuration(cacheType: value.cacheType)
                                    .map { duration in Animation.linear(duration: duration) }
                                withAnimation(animation) { self.loaded = true }
                            }

                            CallbackQueue.mainAsync.execute {
                                context.onSuccessDelegate.call(value)
                            }
                        case .failure(let error):
                            CallbackQueue.mainAsync.execute {
                                context.onFailureDelegate.call(error)
                            }
                        }
                })
        }
        
        private func updateProgress(downloaded: Int64, total: Int64) {
            progress.totalUnitCount = total
            progress.completedUnitCount = downloaded
            objectWillChange.send()
        }

        /// Cancels the download task if it is in progress.
        func cancel() {
            downloadTask?.cancel()
            downloadTask = nil
        }
    }
}
#endif
