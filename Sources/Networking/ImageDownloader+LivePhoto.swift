//
//  ImageDownloader+LivePhoto.swift
//  Kingfisher
//
//  Created by onevcat on 2024/10/01.
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct LivePhotoResourceDownloadingResult: Sendable {
    
    /// The original URL of the image request.
    public let url: URL?

    /// The raw data received from the downloader.
    public let originalData: Data

    /// Creates an `ImageDownloadResult` object.
    ///
    /// - Parameters:
    ///   - url: The URL from which the image was downloaded.
    ///   - originalData: The binary data of the image.
    public init(originalData: Data, url: URL? = nil) {
        self.url = url
        self.originalData = originalData
    }
}

extension ImageDownloader {
    
    public func downloadLivePhotoResource(
        with url: URL,
        options: KingfisherParsedOptionsInfo
    ) async throws -> LivePhotoResourceDownloadingResult {
        let task = CancellationDownloadTask()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let downloadTask = downloadLivePhotoResource(with: url, options: options) { result in
                    continuation.resume(with: result)
                }
                if Task.isCancelled {
                    downloadTask.cancel()
                } else {
                    Task {
                        await task.setTask(downloadTask)
                    }
                }
            }
        } onCancel: {
            Task {
                await task.task?.cancel()
            }
        }
    }
    
    @discardableResult
    public func downloadLivePhotoResource(
        with url: URL,
        options: KingfisherParsedOptionsInfo,
        completionHandler: (@Sendable (Result<LivePhotoResourceDownloadingResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask {
        var checkedOptions = options
        if options.processor == DefaultImageProcessor.default {
            // The default processor is a default behavior so we replace it silently.
            checkedOptions.processor = LivePhotoImageProcessor.default
        } else if options.processor != LivePhotoImageProcessor.default {
            assertionFailure("[Kingfisher] Using of custom processors during loading of live photo resource is not supported.")
            checkedOptions.processor = LivePhotoImageProcessor.default
        }
        return downloadImage(with: url, options: checkedOptions) { result in
            guard let completionHandler else {
                return
            }
            let newResult = result.map { LivePhotoResourceDownloadingResult(originalData: $0.originalData, url: $0.url) }
            completionHandler(newResult)
        }
    }
}
