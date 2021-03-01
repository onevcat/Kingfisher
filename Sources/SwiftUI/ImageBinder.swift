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
    class ImageBinder: ObservableObject {

        @Published var loadedImage: Image?
        let source: Source?
        var options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions)

        var downloadTask: DownloadTask?

        var loadingOrSucceeded: Bool = false

        let onFailureDelegate = Delegate<KingfisherError, Void>()
        let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        let onProgressDelegate = Delegate<(Int64, Int64), Void>()

        @available(*, deprecated, message: "The `options` version is deprecated And will be removed soon.")
        init(source: Source?, options: KingfisherOptionsInfo? = nil) {
            self.source = source
            // The refreshing of `KFImage` would happen much more frequently then an `UIImageView`, even as a
            // "side-effect". To prevent unintended flickering, add `.loadDiskFileSynchronously` as a default.
            self.options = KingfisherParsedOptionsInfo(
                KingfisherManager.shared.defaultOptions +
                    (options ?? []) +
                    [.loadDiskFileSynchronously]
            )
        }

        init(source: Source?) {
            self.source = source
            // The refreshing of `KFImage` would happen much more frequently then an `UIImageView`, even as a
            // "side-effect". To prevent unintended flickering, add `.loadDiskFileSynchronously` as a default.
            self.options = KingfisherParsedOptionsInfo(
                KingfisherManager.shared.defaultOptions +
                    [.loadDiskFileSynchronously]
            )
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

                            let image = self.imageFromResult(value.image)

                            CallbackQueue.mainCurrentOrAsync.execute {
                                let animation = self.fadeTransitionDuration(cacheType: value.cacheType)
                                    .map { duration in Animation.linear(duration: duration) }
                                withAnimation(animation) {
                                    self.loadedImage = image
                                    self.onSuccessDelegate.call(value)
                                }
                            }
                        case .failure(let error):
                            self.loadingOrSucceeded = false
                            CallbackQueue.mainCurrentOrAsync.execute {
                                self.loadedImage = nil
                            }
                            CallbackQueue.mainCurrentOrAsync.execute {
                                self.onFailureDelegate.call(error)
                            }
                        }
                    })
        }

        /// Cancels the download task if it is in progress.
        func cancel() {
            downloadTask?.cancel()
        }

        private func shouldApplyFade(cacheType: CacheType) -> Bool {
            options.forceTransition || cacheType == .none
        }

        private func fadeTransitionDuration(cacheType: CacheType) -> TimeInterval? {
            shouldApplyFade(cacheType: cacheType)
                ? options.transition.fadeDuration
                : nil
        }

        private func imageFromResult(_ resultImage: KFCrossPlatformImage) -> Image {
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
                return Image(crossPlatformImage: resultImage)
            } else {
                #if canImport(UIKit)
                // The CG image is used to solve #1395
                // It should be not necessary if SwiftUI.Image can handle resizing correctly when created
                // by `Image.init(uiImage:)`. (The orientation information should be already contained in
                // a `UIImage`)
                // https://github.com/onevcat/Kingfisher/issues/1395
                //
                // This issue happens on iOS 13 and was fixed by Apple from iOS 14.
                if let cgImage = resultImage.cgImage {
                    return Image(decorative: cgImage, scale: resultImage.scale, orientation: resultImage.imageOrientation.toSwiftUI())
                } else {
                    return Image(crossPlatformImage: resultImage)
                }
                #else
                return Image(crossPlatformImage: resultImage)
                #endif

            }
        }
    }

}

extension ImageTransition {
    // Only for fade effect in SwiftUI.
    fileprivate var fadeDuration: TimeInterval? {
        switch self {
        case .fade(let duration):
            return duration
        default:
            return nil
        }
    }
    
}

#if canImport(UIKit)
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension UIImage.Orientation {
    func toSwiftUI() -> Image.Orientation {
        switch self {
        case .down: return .down
        case .up: return .up
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
#endif

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage.ImageBinder: Hashable {
    static func == (lhs: KFImage.ImageBinder, rhs: KFImage.ImageBinder) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(options.processor.identifier)
    }
}
#endif
