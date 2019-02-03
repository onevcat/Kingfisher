//
//  ImagePrefetcher.swift
//  Kingfisher
//
//  Created by Claire Knight <claire.knight@moggytech.co.uk> on 24/02/2016
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


#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Progress update block of prefetcher. 
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while
///                      downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherProgressBlock =
    ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> Void)

/// Completion block of prefetcher.
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while
///                      downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherCompletionHandler =
    ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> Void)

/// `ImagePrefetcher` represents a downloading manager for requesting many images via URLs, then caching them.
/// This is useful when you know a list of image resources and want to download them before showing. It also works with
/// some Cocoa prefetching mechanism like table view or collection view `prefetchDataSource`, to start image downloading
/// and caching before they display on screen.
public class ImagePrefetcher {
    
    /// The maximum concurrent downloads to use when prefetching images. Default is 5.
    public var maxConcurrentDownloads = 5
    
    // The dispatch queue to use for handling resource process, so downloading does not occur on the main thread
    // This prevents stuttering when preloading images in a collection view or table view.
    private var prefetchQueue: DispatchQueue
    
    private let prefetchResources: [Resource]
    private let optionsInfo: KingfisherParsedOptionsInfo

    private var progressBlock: PrefetcherProgressBlock?
    private var completionHandler: PrefetcherCompletionHandler?
    
    private var tasks = [URL: DownloadTask]()
    
    private var pendingResources: ArraySlice<Resource>
    private var skippedResources = [Resource]()
    private var completedResources = [Resource]()
    private var failedResources = [Resource]()
    
    private var stopped = false
    
    // A manager used for prefetching. We will use the helper methods in manager.
    private let manager: KingfisherManager
    
    private var finished: Bool {
        let totalFinished = failedResources.count + skippedResources.count + completedResources.count
        return totalFinished == prefetchResources.count && tasks.isEmpty
    }

    /// Creates an image prefetcher with an array of URLs.
    ///
    /// The prefetcher should be initiated with a list of prefetching targets. The URLs list is immutable.
    /// After you get a valid `ImagePrefetcher` object, you call `start()` on it to begin the prefetching process.
    /// The images which are already cached will be skipped without downloading again.
    ///
    /// - Parameters:
    ///   - urls: The URLs which should be prefetched.
    ///   - options: A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time an resource is downloaded, skipped or cancelled.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.

    public convenience init(urls: [URL],
                         options: KingfisherOptionsInfo? = nil,
                   progressBlock: PrefetcherProgressBlock? = nil,
               completionHandler: PrefetcherCompletionHandler? = nil)
    {
        let resources: [Resource] = urls.map { $0 }
        self.init(
            resources: resources,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    /// Creates an image prefetcher with an array of resources.
    ///
    /// - Parameters:
    ///   - resources: The resources which should be prefetched. See `Resource` type for more.
    ///   - options: A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time an resource is downloaded, skipped or cancelled.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public init(resources: [Resource],
                  options: KingfisherOptionsInfo? = nil,
            progressBlock: PrefetcherProgressBlock? = nil,
        completionHandler: PrefetcherCompletionHandler? = nil)
    {
        var options = KingfisherParsedOptionsInfo(options)
        prefetchResources = resources
        pendingResources = ArraySlice(resources)
        
        // Set up the dispatch queue that all our work should occur on.
        let prefetchQueueName = "com.onevcat.Kingfisher.PrefetchQueue"
        prefetchQueue = DispatchQueue(label: prefetchQueueName)
        
        // We want all callbacks from our prefetch queue, so we should ignore the callback queue in options.
        // Add our own callback dispatch queue to make sure all internal callbacks are
        // coming back in our expected queue.
        options.callbackQueue = .untouch
        optionsInfo = options
        
        let cache = optionsInfo.targetCache ?? .default
        let downloader = optionsInfo.downloader ?? .default
        manager = KingfisherManager(downloader: downloader, cache: cache)
        
        self.progressBlock = progressBlock
        self.completionHandler = completionHandler
    }

    /// Starts to download the resources and cache them. This can be useful for background downloading
    /// of assets that are required for later use in an app. This code will not try and update any UI
    /// with the results of the process.
    public func start()
    {
        // Since we want to handle the resources cancellation in the prefetch queue only.
        prefetchQueue.async {
            
            guard !self.stopped else {
                assertionFailure("You can not restart the same prefetcher. Try to create a new prefetcher.")
                self.handleComplete()
                return
            }
            
            guard self.maxConcurrentDownloads > 0 else {
                assertionFailure("There should be concurrent downloads value should be at least 1.")
                self.handleComplete()
                return
            }

            // Empty case.
            guard self.prefetchResources.count > 0 else {
                self.handleComplete()
                return
            }
            
            let initialConcurrentDownloads = min(self.prefetchResources.count, self.maxConcurrentDownloads)
            for _ in 0 ..< initialConcurrentDownloads {
                if let resource = self.pendingResources.popFirst() {
                    self.startPrefetching(resource)
                }
            }
        }
    }

    /// Stops current downloading progress, and cancel any future prefetching activity that might be occuring.
    public func stop() {
        prefetchQueue.async {
            if self.finished { return }
            self.stopped = true
            self.tasks.values.forEach { $0.cancel() }
        }
    }
    
    func downloadAndCache(_ resource: Resource) {

        let downloadTaskCompletionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { result in
            self.tasks.removeValue(forKey: resource.downloadURL)
            if let _ = result.error {
                self.failedResources.append(resource)
            } else {
                self.completedResources.append(resource)
            }
            
            self.reportProgress()
            if self.stopped {
                if self.tasks.isEmpty {
                    self.failedResources.append(contentsOf: self.pendingResources)
                    self.handleComplete()
                }
            } else {
                self.reportCompletionOrStartNext()
            }
        }

        let downloadTask = manager.loadAndCacheImage(
            source: .network(resource),
            options: optionsInfo,
            completionHandler: downloadTaskCompletionHandler)
        
        if let downloadTask = downloadTask {
            tasks[resource.downloadURL] = downloadTask
        }
    }
    
    func append(cached resource: Resource) {
        skippedResources.append(resource)
 
        reportProgress()
        reportCompletionOrStartNext()
    }
    
    func startPrefetching(_ resource: Resource)
    {
        if optionsInfo.forceRefresh {
            downloadAndCache(resource)
            return
        }
        
        let cacheType = manager.cache.imageCachedType(
            forKey: resource.cacheKey,
            processorIdentifier: optionsInfo.processor.identifier)
        switch cacheType {
        case .memory:
            append(cached: resource)
        case .disk:
            if optionsInfo.alsoPrefetchToMemory {
                _ = manager.retrieveImageFromCache(
                    source: .network(resource),
                    options: optionsInfo)
                {
                    _ in
                    self.append(cached: resource)
                }
            } else {
                append(cached: resource)
            }
        case .none:
            downloadAndCache(resource)
        }
    }
    
    func reportProgress() {
        progressBlock?(skippedResources, failedResources, completedResources)
    }
    
    func reportCompletionOrStartNext() {
        prefetchQueue.async {
            if let resource = self.pendingResources.popFirst() {
                self.startPrefetching(resource)
            } else {
                guard self.tasks.isEmpty else { return }
                self.handleComplete()
            }
        }
    }
    
    func handleComplete() {
        // The completion handler should be called on the main thread
        DispatchQueue.main.safeAsync {
            self.completionHandler?(self.skippedResources, self.failedResources, self.completedResources)
            self.completionHandler = nil
            self.progressBlock = nil
        }
    }
}
