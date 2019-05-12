//
//  ImageProgressive.swift
//  Kingfisher
//
//  Created by lixiang on 2019/5/10.
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

import UIKit

private let sharedProcessingQueue: CallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process"))

final class ImageProgressive {
    
    private let options: KingfisherParsedOptionsInfo
    private(set) var scannedCount: Int = 0
    private var scannedIndex = -1
    private var lastSOSIndex = 0
    
    init(_ options: KingfisherParsedOptionsInfo) {
        self.options = options
    }
    
    func scanning(_ data: Data) -> Data? {
        guard let _ = options.progressiveJPEG, data.kf.contains(jpeg: .SOF2) else {
            return nil
        }
        guard (scannedIndex + 1) < data.count else {
            return nil
        }
        
        var index = scannedIndex + 1
        var count = scannedCount
        
        while index < (data.count - 1) {
            scannedIndex = index
            // 0xFF, 0xDA - Start Of Scan
            let SOS = ImageFormat.JPEGMarker.SOS.bytes
            if data[index] == SOS[0], data[index + 1] == SOS[1] {
                lastSOSIndex = index
                count += 1
            }
            index += 1
        }
        
        // Found more scans this the previous time
        guard count > scannedCount else { return nil }
        scannedCount = count
        
        // `> 1` checks that we've received a first scan (SOS) and then received
        // and also received a second scan (SOS). This way we know that we have
        // at least one full scan available.
        guard count > 1 && lastSOSIndex > 0 else { return nil }
        return data[0 ..< lastSOSIndex]
    }
    
    func decode(_ data: Data, with callbacks: [SessionDataTask.TaskCallback], completion: @escaping (Image) -> Void) {
        guard let isBlur = options.progressiveJPEG, data.kf.contains(jpeg: .SOF2) else {
            return
        }
        
        func processing(_ data: Data) {
            let processor = ImageDataProcessor(
                data: data,
                callbacks: callbacks,
                processingQueue: options.processingQueue
            )
            processor.onImageProcessed.delegate(on: self) { (self, result) in
                guard let image = try? result.0.get() else { return }
                
                CallbackQueue.mainCurrentOrAsync.execute { completion(image) }
            }
            processor.process()
        }
        
        // Blur partial images.
        let count = scannedCount
        if isBlur, count < 5 {
            let queue = options.processingQueue ?? sharedProcessingQueue
            queue.execute {
                // Progressively reduce blur as we load more scans.
                let radius = max(2, 14 - count * 4)
                let image = KingfisherWrapper<Image>.image(
                    data: data,
                    options: self.options.imageCreatingOptions
                )
                let temp = image?.kf.blurred(withRadius: CGFloat(radius))
                processing(temp?.kf.data(format: .JPEG) ?? data)
            }
            
        } else {
            processing(data)
        }
    }
}
