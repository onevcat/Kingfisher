//
//  ImageDataProcessor.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/11.
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

import Foundation

private let sharedProcessingQueue: CallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process"))

// Handles image processing work on an own process queue.
final class ImageDataProcessor: Sendable {
    let data: Data
    let callbacks: [SessionDataTask.TaskCallback]
    let queue: CallbackQueue

    // Note: We have an optimization choice there, to reduce queue dispatch by checking callback
    // queue settings in each option...
    let onImageProcessed = Delegate<(Result<KFCrossPlatformImage, KingfisherError>, SessionDataTask.TaskCallback), Void>()

    init(data: Data, callbacks: [SessionDataTask.TaskCallback], processingQueue: CallbackQueue?) {
        self.data = data
        self.callbacks = callbacks
        self.queue = processingQueue ?? sharedProcessingQueue
    }

    func process() {
        queue.execute {
            self.doProcess()
        }
    }

    private func doProcess() {
        var processedImages = [String: KFCrossPlatformImage]()
        for callback in callbacks {
            let processor = callback.options.processor
            var image = processedImages[processor.identifier]
            if image == nil {
                image = processor.process(item: .data(data), options: callback.options)
                processedImages[processor.identifier] = image
            }

            let result: Result<KFCrossPlatformImage, KingfisherError>
            if let image = image {
                let finalImage = callback.options.backgroundDecode ? image.kf.decoded : image
                result = .success(finalImage)
            } else {
                let error = KingfisherError.processorError(
                    reason: .processingFailed(processor: processor, item: .data(data)))
                result = .failure(error)
            }
            onImageProcessed.call((result, callback))
        }
    }
}
