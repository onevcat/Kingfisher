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
#if os(macOS)
import AppKit
#else
import UIKit
#endif

private let sharedProcessingQueue: CallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process"))

/// Represents a progressive loading for images which supports this feature.
public struct ImageProgressive: Sendable {
    
    /// The updating strategy when an intermediate progressive image is generated and about to be set to the hosting view.
    public enum UpdatingStrategy {
        
        /// Use the progressive image as it is.
        ///
        /// > It is the standard behavior when handling the progressive image.
        case `default`
        
        /// Discard this progressive image and keep the current displayed one.
        case keepCurrent
        
        /// Replace the image to a new one. 
        ///
        /// If the progressive loading is initialized by a view extension in Kingfisher, the replacing image will be
        /// used to update the view.
        case replace(KFCrossPlatformImage?)
    }
    
    /// A default `ImageProgressive` could be used across. It blurs the progressive loading with the fastest
    /// scan enabled and scan interval as 0.
    @available(*, deprecated, message: "Getting a default `ImageProgressive` is deprecated due to its syntax semantic is not clear. Use `ImageProgressive.init` instead.", renamed: "init()")
    public static let `default` = ImageProgressive(
        isBlur: true,
        isFastestScan: true,
        scanInterval: 0
    )
    
    /// Indicates whether to enable blur effect processing.
    public var isBlur: Bool
    
    /// Indicates whether to enable the fastest scan.
    public var isFastestScan: Bool
    
    /// The minimum time interval for each scan.
    public var scanInterval: TimeInterval
    
    /// Called when an intermediate image is prepared and about to be set to the image view. 
    ///
    /// If implemented, you should return an ``UpdatingStrategy`` value from this delegate. This value will be used to
    /// update the hosting view, if any. Otherwise, if there is no hosting view (i.e., the image retrieval is not
    /// happening from a view extension method), the returned ``UpdatingStrategy`` is ignored.
    public let onImageUpdated = Delegate<KFCrossPlatformImage, UpdatingStrategy>()
    
    /// Creates an `ImageProgressive` value with default settings. 
    ///
    /// It enables progressive loading with the fastest scan enabled and a scan interval of 0, resulting in a blurred 
    /// effect.
    public init() {
        self.init(isBlur: true, isFastestScan: true, scanInterval: 0)
    }
    
    /// Creates an `ImageProgressive` value with the given values.
    ///
    /// - Parameters:
    ///     - isBlur: Indicates whether to enable blur effect processing.
    ///     - isFastestScan: Indicates whether to enable the fastest scan.
    ///     - scanInterval: The minimum time interval for each scan.
    public init(
        isBlur: Bool,
        isFastestScan: Bool,
        scanInterval: TimeInterval
    )
    {
        self.isBlur = isBlur
        self.isFastestScan = isFastestScan
        self.scanInterval = scanInterval
    }
}

// A data receiving provider to update the image. Working with an `ImageProgressive`, it helps to implement the image
// progressive effect.
final class ImageProgressiveProvider: DataReceivingSideEffect, @unchecked Sendable {
    
    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageProgressiveProviderPropertyQueue")
    
    private var _onShouldApply: () -> Bool = { return true }
    
    var onShouldApply: () -> Bool {
        get { propertyQueue.sync { _onShouldApply } }
        set { propertyQueue.sync { _onShouldApply = newValue } }
    }
    
    func onDataReceived(_ session: URLSession, task: SessionDataTask, data: Data) {

        DispatchQueue.main.async {
            guard self.onShouldApply() else { return }
            self.update(data: task.mutableData, with: task.callbacks)
        }
    }

    private let progressive: ImageProgressive
    private let refresh: (KFCrossPlatformImage) -> Void
    
    private let decoder: ImageProgressiveDecoder
    private let queue = ImageProgressiveSerialQueue()
    
    init?(
        options: KingfisherParsedOptionsInfo,
        refresh: @escaping (KFCrossPlatformImage) -> Void
    ) {
        guard let progressive = options.progressiveJPEG else { return nil }
        
        self.progressive = progressive
        self.refresh = refresh
        self.decoder = ImageProgressiveDecoder(
            progressive,
            processingQueue: options.processingQueue ?? sharedProcessingQueue,
            creatingOptions: options.imageCreatingOptions
        )
    }
    
    func update(data: Data, with callbacks: [SessionDataTask.TaskCallback]) {
        guard !data.isEmpty else { return }
        queue.add(minimum: progressive.scanInterval) { completion in

            @Sendable func decode(_ data: Data) {
                self.decoder.decode(data, with: callbacks) { image in
                    defer { completion() }
                    guard self.onShouldApply() else { return }
                    guard let image = image else { return }
                    self.refresh(image)
                }
            }
            
            Task { @MainActor in
                let applyFlag = self.onShouldApply()
                guard applyFlag else {
                    self.queue.clean()
                    completion()
                    return
                }

                if self.progressive.isFastestScan {
                    decode(self.decoder.scanning(data) ?? Data())
                } else {
                    self.decoder.scanning(data).forEach { decode($0) }
                }
            }
        }
    }
}

private final class ImageProgressiveDecoder: @unchecked Sendable {
    
    private let option: ImageProgressive
    private let processingQueue: CallbackQueue
    private let creatingOptions: ImageCreatingOptions
    private(set) var scannedCount = 0
    private(set) var scannedIndex = -1
    
    init(_ option: ImageProgressive,
         processingQueue: CallbackQueue,
         creatingOptions: ImageCreatingOptions) {
        self.option = option
        self.processingQueue = processingQueue
        self.creatingOptions = creatingOptions
    }
    
    func scanning(_ data: Data) -> [Data] {
        guard data.kf.contains(jpeg: .SOF2) else {
            return []
        }
        guard scannedIndex + 1 < data.count else {
            return []
        }
        
        var datas: [Data] = []
        var index = scannedIndex + 1
        var count = scannedCount
        
        while index < data.count - 1 {
            scannedIndex = index
            // 0xFF, 0xDA - Start Of Scan
            let SOS = ImageFormat.JPEGMarker.SOS.bytes
            if data[index] == SOS[0], data[index + 1] == SOS[1] {
                if count > 0 {
                    datas.append(data[0 ..< index])
                }
                count += 1
            }
            index += 1
        }
        
        // Found more scans this the previous time
        guard count > scannedCount else { return [] }
        scannedCount = count
        
        // `> 1` checks that we've received a first scan (SOS) and then received
        // and also received a second scan (SOS). This way we know that we have
        // at least one full scan available.
        guard count > 1 else { return [] }
        return datas
    }
    
    func scanning(_ data: Data) -> Data? {
        guard data.kf.contains(jpeg: .SOF2) else {
            return nil
        }
        guard scannedIndex + 1 < data.count else {
            return nil
        }
        
        var index = scannedIndex + 1
        var count = scannedCount
        var lastSOSIndex = 0
        
        while index < data.count - 1 {
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
                completion: @escaping @Sendable (KFCrossPlatformImage?) -> Void) {
        guard data.kf.contains(jpeg: .SOF2) else {
            CallbackQueue.mainCurrentOrAsync.execute { completion(nil) }
            return
        }
        
        @Sendable func processing(_ data: Data) {
            let processor = ImageDataProcessor(
                data: data,
                callbacks: callbacks,
                processingQueue: processingQueue
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
        
        if option.isBlur, count < 6 {
            processingQueue.execute {
                // Progressively reduce blur as we load more scans.
                let image = KingfisherWrapper<KFCrossPlatformImage>.image(
                    data: data,
                    options: self.creatingOptions
                )
                let radius = max(2, 14 - count * 4)
                let temp = image?.kf.blurred(withRadius: CGFloat(radius))
                processing(temp?.kf.data(format: .JPEG) ?? data)
            }
            
        } else {
            processing(data)
        }
    }
}

private final class ImageProgressiveSerialQueue: @unchecked Sendable {
    typealias ClosureCallback = @Sendable ((@escaping @Sendable () -> Void)) -> Void
    
    private let queue: DispatchQueue
    private var items: [DispatchWorkItem] = []
    private var notify: (() -> Void)?
    private var lastTime: TimeInterval?

    init() {
        self.queue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageProgressive.SerialQueue")
    }
    
    func add(minimum interval: TimeInterval, closure: @escaping ClosureCallback) {
        let completion = { @Sendable [weak self] in
            guard let self = self else { return }
            
            self.queue.async { [weak self] in
                guard let self = self else { return }
                guard !self.items.isEmpty else { return }
                
                self.items.removeFirst()
                
                if let next = self.items.first {
                    self.queue.asyncAfter(
                        deadline: .now() + interval,
                        execute: next
                    )
                    
                } else {
                    self.lastTime = Date().timeIntervalSince1970
                    self.notify?()
                    self.notify = nil
                }
            }
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let item = DispatchWorkItem {
                closure(completion)
            }
            if self.items.isEmpty {
                let difference = Date().timeIntervalSince1970 - (self.lastTime ?? 0)
                let delay = difference < interval ? interval - difference : 0
                self.queue.asyncAfter(deadline: .now() + delay, execute: item)
            }
            self.items.append(item)
        }
    }
    
    func clean() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.items.forEach { $0.cancel() }
            self.items.removeAll()
        }
    }
}
