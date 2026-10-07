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

extension KFImage {

    /// Represents a binder for `KFImage`. It takes responsibility as an `ObjectBinding` and performs
    /// image downloading and progress reporting based on `KingfisherManager`.
    @MainActor
    class ImageBinder: ObservableObject {
        
        init() {}

        /// Takes the image from the memory cache, if it can be shown at once. Only the first call does something.
        ///
        /// Call it in the body of the view, before the body reads the binder. Then the first render pass shows the
        /// image instead of the placeholder, and the layout does not change when the view appears.
        ///
        /// SwiftUI creates the view value again in each update of the parent, but keeps the binder of the first value.
        /// Thus, the memory cache is not used in the initializer. Otherwise each update would apply the image modifier
        /// again and extend the expiration of the cached image, for a binder that SwiftUI discards.
        func loadFromMemoryCacheIfNeeded<HoldingView: KFImageHoldingView>(
            context: Context<HoldingView>
        ) where HoldingView: Sendable {
            guard !memoryCacheChecked else { return }
            memoryCacheChecked = true
            guard context.loadMemoryCacheSynchronously,
                  !loadingOrSucceeded,
                  let source = context.source,
                  // A transition forced for a cached image needs the normal flow to animate the image in.
                  !context.shouldApplyFade(cacheType: .memory),
                  let result = KingfisherManager.shared.retrieveImageInMemoryCacheSynchronously(
                    with: source, options: context.options
                  )
            else {
                return
            }
            // Set the storage directly. SwiftUI does not allow a change event while it updates the view, and the body
            // reads the new values after this call. `usesFailureImage` keeps `false`, which is correct for a retrieved
            // image.
            _loadedImage = result.image
            loaded = true
            pendingMemoryCacheResult = result
        }

        var downloadTask: DownloadTask?
        private var loading = false

        var loadingOrSucceeded: Bool {
            return loading || loadedImage != nil
        }

        // Not `@Published`: `markLoaded(sendChangeEvent:)` decides whether a change of this value sends a change
        // event, and `loadFromMemoryCacheIfNeeded(context:)` sets it while SwiftUI updates the view.
        private(set) var loaded = false

        private(set) var animating = false

        private var _loadedImage: KFCrossPlatformImage? = nil
        private(set) var loadedImage: KFCrossPlatformImage? {
            get { _loadedImage }
            set {
                objectWillChange.send()
                _loadedImage = newValue
            }
        }
        var failureView: (() -> AnyView)? = nil { willSet { objectWillChange.send() } }
        var progress: Progress = .init()

        /// Whether `loadFromMemoryCacheIfNeeded(context:)` was called.
        private var memoryCacheChecked = false

        /// The result of the memory cache hit in `loadFromMemoryCacheIfNeeded(context:)`, which is not reported to
        /// `onSuccess` yet.
        private var pendingMemoryCacheResult: RetrieveImageResult?

        /// Whether the current `loadedImage` is the fallback supplied by the deprecated `onFailureImage`, instead of
        /// an image retrieved from the cache or the network.
        private(set) var usesFailureImage = false

        /// Sets `loadedImage` together with where that image came from.
        ///
        /// A cancelled request can still deliver its failure after a restarted load has begun, so the two values have
        /// to change as a pair. Otherwise the provenance outlives the image it described, and a retrieved image ends
        /// up reported as a fallback. Except for the memory cache hit in `loadFromMemoryCacheIfNeeded(context:)`, going
        /// through here is the only way to set the image, so no assignment site can leave the two out of step. It also
        /// covers the change event, since `loadedImage` sends it.
        func setLoadedImage(_ image: KFCrossPlatformImage?, isFailureImage: Bool = false) {
            usesFailureImage = isFailureImage
            loadedImage = image
        }

        /// Reports the result of the memory cache hit in `loadFromMemoryCacheIfNeeded(context:)` to `onSuccess`, if it
        /// is not reported yet.
        ///
        /// The placeholder is not shown for this result, so its `onAppear` does not start a loading that reports it.
        func reportPendingMemoryCacheResult<HoldingView: KFImageHoldingView>(
            context: Context<HoldingView>
        ) where HoldingView: Sendable {
            guard let result = pendingMemoryCacheResult else { return }
            pendingMemoryCacheResult = nil
            CallbackQueueMain.async {
                context.onSuccessDelegate.call(result)
            }
        }

        func markLoading() {
            loading = true
        }

        func markLoaded(sendChangeEvent: Bool) {
            loaded = true
            if sendChangeEvent {
                objectWillChange.send()
            }
        }

        func start<HoldingView: KFImageHoldingView>(context: Context<HoldingView>) where HoldingView: Sendable {
            guard let source = context.source else {
                CallbackQueueMain.currentOrAsync {
                    context.onFailureDelegate.call(KingfisherError.imageSettingError(reason: .emptySource))
                    if let view = context.failureView {
                        self.failureView = view
                    } else if let image = context.options.onFailureImage {
                        self.setLoadedImage(image, isFailureImage: true)
                    }
                    self.loading = false
                    self.markLoaded(sendChangeEvent: false)
                }
                return
            }

            loading = true
            
            progress = .init()
            downloadTask = KingfisherManager.shared
                .retrieveImage(
                    with: source,
                    options: context.options,
                    progressBlock: { [weak self] size, total in
                        guard let self else { return }
                        self.updateProgress(downloaded: size, total: total)
                        context.onProgressDelegate.call((size, total))
                    },
                    progressiveImageSetter: { [weak self] image in
                        CallbackQueueMain.currentOrAsync { [weak self] in
                            guard let self else { return }
                            self.markLoaded(sendChangeEvent: true)
                            self.setLoadedImage(image)
                        }
                    },
                    completionHandler: { [weak self] result in
                        guard let self else {
                            CallbackQueueMain.async {
                                switch result {
                                case .success(let value):
                                    context.onSuccessDelegate.call(value)
                                case .failure(let error):
                                    context.onFailureDelegate.call(error)
                                }
                            }
                            return
                        }

                        CallbackQueueMain.currentOrAsync {
                            self.downloadTask = nil
                            self.loading = false
                        }
                        
                        switch result {
                        case .success(let value):
                            CallbackQueueMain.currentOrAsync {
                                if context.swiftUITransition != nil,
                                   context.shouldApplyFade(cacheType: value.cacheType) {
                                    // Apply SwiftUI loadTransition with custom animation (higher priority than fade)
                                    self.animating = true
                                    self.setLoadedImage(value.image)

                                    let animation = context.swiftUIAnimation ?? .default
                                    CallbackQueueMain.async {
                                        withAnimation(animation) {
                                            self.markLoaded(sendChangeEvent: true)
                                        }
                                        self.animating = false
                                        context.onSuccessDelegate.call(value)
                                    }
                                } else if let fadeDuration = context.fadeTransitionDuration(cacheType: value.cacheType) {
                                    self.animating = true
                                    self.setLoadedImage(value.image)

                                    let animation = Animation.linear(duration: fadeDuration)
                                    CallbackQueueMain.async {
                                        withAnimation(animation) {
                                            // Trigger the view render to apply the animation.
                                            self.markLoaded(sendChangeEvent: true)
                                        }
                                        self.animating = false
                                        context.onSuccessDelegate.call(value)
                                    }
                                } else {
                                    self.markLoaded(sendChangeEvent: false)
                                    self.setLoadedImage(value.image)

                                    CallbackQueueMain.async {
                                        context.onSuccessDelegate.call(value)
                                    }
                                }
                            }
                        case .failure(let error):
                            CallbackQueueMain.currentOrAsync {
                                if let view = context.failureView {
                                    self.failureView = view
                                } else if let image = context.options.onFailureImage {
                                    self.setLoadedImage(image, isFailureImage: true)
                                }
                                self.markLoaded(sendChangeEvent: false)
                            }
                            
                            CallbackQueueMain.async {
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
            loading = false
        }
        
        /// Restores the original download task priority if it is in progress.
        func restorePriorityOnAppear() {
            guard let downloadTask = downloadTask, loading == true else { return }
            downloadTask.resetPriority()
        }
        
        /// Reduce the download task priority if it is in progress.
        func reducePriorityOnDisappear() {
            guard let downloadTask = downloadTask, loading == true else { return }
            downloadTask.setPriority(URLSessionTask.lowPriority)
        }
    }
}
#endif
