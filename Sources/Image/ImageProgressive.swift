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

import Foundation
import CoreGraphics

private let sharedProcessingQueue: CallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process"))

public struct ImageProgressive {
    
    /// A default `ImageProgressive` could be used across.
    public static let `default` = ImageProgressive(
        isBlur: true,
        isWait: false,
        isFastestScan: true,
        scanInterval: 0
    )
    
    /// Whether to enable blur effect processing
    let isBlur: Bool
    /// Whether to wait for the scan to complete
    let isWait: Bool
    /// Whether to enable the fastest scan
    let isFastestScan: Bool
    /// Minimum time interval for each scan
    let scanInterval: TimeInterval
    
    public init(isBlur: Bool,
                isWait: Bool,
                isFastestScan: Bool,
                scanInterval: TimeInterval) {
        self.isBlur = isBlur
        self.isWait = isWait
        self.isFastestScan = isFastestScan
        self.scanInterval = scanInterval
    }
}

final class ImageProgressiveProvider {
    
    private let options: KingfisherParsedOptionsInfo
    private let refreshClosure: (Image) -> Void
    private let isContinueClosure: () -> Bool
    private let isFinishedClosure: () -> Bool
    private let isWait: Bool
    
    private let decoder: ImageProgressiveDecoder
    private let queue = ImageProgressiveSerialQueue(.main)
    
    init(_ options: KingfisherParsedOptionsInfo,
         isContinue: @escaping () -> Bool,
         isFinished: @escaping () -> Bool,
         refreshImage: @escaping (Image) -> Void) {
        self.options = options
        self.refreshClosure = refreshImage
        self.isContinueClosure = isContinue
        self.isFinishedClosure = isFinished
        self.decoder = ImageProgressiveDecoder(options)
        self.isWait = options.progressiveJPEG?.isWait ?? false
    }
    
    func update(data: Data, with callbacks: [SessionDataTask.TaskCallback]) {
        let interval = options.progressiveJPEG?.scanInterval ?? 0
        let isFastest = options.progressiveJPEG?.isFastestScan ?? true
        
        func add(decoder data: Data) {
            queue.add(minimum: interval) { (completion) in
                guard self.isContinueClosure() else {
                    completion()
                    return
                }
                
                self.decoder.decode(data, with: callbacks) { (image) in
                    defer { completion() }
                    guard self.isContinueClosure() else { return }
                    guard self.isWait || !self.isFinishedClosure() else { return }
                    guard let image = image else { return }
                    
                    self.refreshClosure(image)
                }
            }
        }
        
        if isFastest {
            guard let data = decoder.scanning(data) else { return }
            
            add(decoder: data)
            
        } else {
            for data in decoder.scanning(data) {
                add(decoder: data)
            }
        }
    }
    
    func finished(_ closure: @escaping () -> Void) {
        if queue.count > 0, isWait {
            queue.notify(closure)
            
        } else {
            queue.clean()
            closure()
        }
    }
    
    deinit {
        print("deinit ImageProgressiveProvider")
    }
}

final class ImageProgressiveDecoder {
    
    private let options: KingfisherParsedOptionsInfo
    private(set) var scannedCount: Int = 0
    private var scannedIndex = -1
    
    init(_ options: KingfisherParsedOptionsInfo) {
        self.options = options
    }
    
    func scanning(_ data: Data) -> [Data] {
        guard let _ = options.progressiveJPEG, data.kf.contains(jpeg: .SOF2) else {
            return []
        }
        guard (scannedIndex + 1) < data.count else {
            return []
        }
        
        var datas: [Data] = []
        var index = scannedIndex + 1
        var count = scannedCount
        
        while index < (data.count - 1) {
            scannedIndex = index
            // 0xFF, 0xDA - Start Of Scan
            let SOS = ImageFormat.JPEGMarker.SOS.bytes
            if data[index] == SOS[0], data[index + 1] == SOS[1] {
                datas.append(data[0 ..< index])
                count += 1
            }
            index += 1
        }
        
        // Found more scans this the previous time
        guard count > scannedCount else { return [] }
        scannedCount = count
        return datas
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
        var lastSOSIndex = 0
        
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
    
    func decode(_ data: Data,
                with callbacks: [SessionDataTask.TaskCallback],
                completion: @escaping (Image?) -> Void) {
        guard data.kf.contains(jpeg: .SOF2) else {
            CallbackQueue.mainCurrentOrAsync.execute { completion(nil) }
            return
        }
        
        func processing(_ data: Data) {
            let processor = ImageDataProcessor(
                data: data,
                callbacks: callbacks,
                processingQueue: options.processingQueue
            )
            processor.onImageProcessed.delegate(on: self) { (self, result) in
                guard let image = try? result.0.get() else {
                    CallbackQueue.mainCurrentOrAsync.execute { completion(nil) }
                    return
                }
                
                CallbackQueue.mainCurrentOrAsync.execute { completion(image) }
            }
            processor.process()
        }
        
        // Blur partial images.
        let count = scannedCount
        let isBlur = options.progressiveJPEG?.isBlur ?? false
        
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

final class ImageProgressiveSerialQueue {
    typealias ClosureCallback = ((@escaping () -> Void)) -> Void
    private let queue: DispatchQueue
    private var items: [DispatchWorkItem] = []
    private var notify: (() -> Void)?
    var count: Int {
        return items.count
    }
    
    init(_ queue: DispatchQueue) {
        self.queue = queue
    }
    
    func add(minimum interval: TimeInterval, closure: @escaping ClosureCallback) {
        let completion = {
            self.queue.async {
                guard !self.items.isEmpty else { return }
                
                self.items.removeFirst()
                
                if let next = self.items.first {
                    self.queue.asyncAfter(deadline: .now() + interval, execute: next)
                    
                } else {
                    self.notify?()
                    self.notify = nil
                }
            }
        }
        let item = DispatchWorkItem {
            closure(completion)
        }
        if items.isEmpty {
            queue.asyncAfter(deadline: .now(), execute: item)
        }
        items.append(item)
    }
    
    func notify(_ closure: @escaping () -> Void) {
        self.notify = closure
    }
    
    func clean() {
        items.forEach { $0.cancel() }
        items.removeAll()
    }
}
