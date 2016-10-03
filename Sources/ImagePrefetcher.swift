//
//  ImagePrefetcher.swift
//  Kingfisher
//
//  Created by Claire Knight <claire.knight@moggytech.co.uk> on 24/02/2016
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherProgressBlock = ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> ())

/// Completion block of prefetcher.
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherCompletionHandler = ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> ())

/// `ImagePrefetcher` represents a downloading manager for requesting many images via URLs, then caching them.
/// This is useful when you know a list of image resources and want to download them before showing.
public class ImagePrefetcher {
    
    /// The maximum concurrent downloads to use when prefetching images. Default is 5.
    public var maxConcurrentDownloads = 5
    
    private let prefetchResources: [Resource]
    private let optionsInfo: KingfisherOptionsInfo
    private var progressBlock: PrefetcherProgressBlock?
    private var completionHandler: PrefetcherCompletionHandler?
    
    private var tasks = [URL: RetrieveImageDownloadTask]()
    
    private var pendingResources: ArraySlice<Resource>
    private var skippedResources = [Resource]()
    private var completedResources = [Resource]()
    private var failedResources = [Resource]()
    
    private var stopped = false
    
    // The created manager used for prefetch. We will use the helper method in manager.
    private let manager: KingfisherManager
    
    private var finished: Bool {
        return failedResources.count + skippedResources.count + completedResources.count == prefetchResources.count && self.tasks.isEmpty
    }
    
    /**
     Init an image prefetcher with an array of URLs.
     
     The prefetcher should be initiated with a list of prefetching targets. The URLs list is immutable. 
     After you get a valid `ImagePrefetcher` object, you could call `start()` on it to begin the prefetching process.
     The images already cached will be skipped without downloading again.
     
     - parameter urls:              The URLs which should be prefetched.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called every time an resource is downloaded, skipped or cancelled.
     - parameter completionHandler: Called when the whole prefetching process finished.
     
     - returns: An `ImagePrefetcher` object.
     
     - Note: By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as 
     the downloader and cache target respectively. You can specify another downloader or cache by using a customized `KingfisherOptionsInfo`.
     Both the progress and completion block will be invoked in main thread. The `CallbackDispatchQueue` in `optionsInfo` will be ignored in this method.
     */
    public convenience init(urls: [URL],
                         options: KingfisherOptionsInfo? = nil,
                   progressBlock: PrefetcherProgressBlock? = nil,
               completionHandler: PrefetcherCompletionHandler? = nil)
    {
        let resources: [Resource] = urls.map { $0 }
        self.init(resources: resources, options: options, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Init an image prefetcher with an array of resources.
     
     The prefetcher should be initiated with a list of prefetching targets. The resources list is immutable.
     After you get a valid `ImagePrefetcher` object, you could call `start()` on it to begin the prefetching process.
     The images already cached will be skipped without downloading again.
     
     - parameter resources:         The resources which should be prefetched. See `Resource` type for more.
     - parameter options:           A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called every time an resource is downloaded, skipped or cancelled.
     - parameter completionHandler: Called when the whole prefetching process finished.
     
     - returns: An `ImagePrefetcher` object.
     
     - Note: By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
     the downloader and cache target respectively. You can specify another downloader or cache by using a customized `KingfisherOptionsInfo`.
     Both the progress and completion block will be invoked in main thread. The `CallbackDispatchQueue` in `optionsInfo` will be ignored in this method.
     */
    public init(resources: [Resource],
                  options: KingfisherOptionsInfo? = nil,
            progressBlock: PrefetcherProgressBlock? = nil,
        completionHandler: PrefetcherCompletionHandler? = nil)
    {
        prefetchResources = resources
        pendingResources = ArraySlice(resources)
        
        // We want all callbacks from main queue, so we ignore the call back queue in options
        let optionsInfoWithoutQueue = options?.removeAllMatchesIgnoringAssociatedValue(.callbackDispatchQueue(nil))
        self.optionsInfo = optionsInfoWithoutQueue ?? KingfisherEmptyOptionsInfo
        
        let cache = self.optionsInfo.targetCache
        let downloader = self.optionsInfo.downloader
        manager = KingfisherManager(downloader: downloader, cache: cache)
        
        self.progressBlock = progressBlock
        self.completionHandler = completionHandler
    }
    
    /**
     Start to download the resources and cache them. This can be useful for background downloading
     of assets that are required for later use in an app. This code will not try and update any UI
     with the results of the process.
     */
    public func start()
    {
        // Since we want to handle the resources cancellation in main thread only.
        DispatchQueue.main.safeAsync {
            
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
            
            guard self.prefetchResources.count > 0 else {
                self.handleComplete()
                return
            }
            
            let initialConcurentDownloads = min(self.prefetchResources.count, self.maxConcurrentDownloads)
            for _ in 0 ..< initialConcurentDownloads {
                if let resource = self.pendingResources.popFirst() {
                    self.startPrefetching(resource)
                }
            }
        }
    }

   
    /**
     Stop current downloading progress, and cancel any future prefetching activity that might be occuring.
     */
    public func stop() {
        DispatchQueue.main.safeAsync {
            
            if self.finished { return }
            
            self.stopped = true
            self.tasks.forEach { (_, task) -> () in
                task.cancel()
            }
        }
    }
    
    func downloadAndCache(_ resource: Resource) {

        let downloadTaskCompletionHandler: CompletionHandler = { (image, error, _, _) -> () in
            self.tasks.removeValue(forKey: resource.downloadURL)
            if let _ = error {
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
        
        let downloadTask = manager.downloadAndCacheImage(
            with: resource.downloadURL,
            forKey: resource.cacheKey,
            retrieveImageTask: RetrieveImageTask(),
            progressBlock: nil,
            completionHandler: downloadTaskCompletionHandler,
            options: optionsInfo)
        
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
        } else {
            let alreadyInCache = manager.cache.isImageCached(forKey: resource.cacheKey).cached
            if alreadyInCache {
                append(cached: resource)
            } else {
                downloadAndCache(resource)
            }
        }
    }
    
    func reportProgress() {
        progressBlock?(skippedResources, failedResources, completedResources)
    }
    
    func reportCompletionOrStartNext() {
        if let resource = pendingResources.popFirst() {
            startPrefetching(resource)
        } else {
            guard tasks.isEmpty else { return }
            handleComplete()
        }
    }
    
    func handleComplete() {
        completionHandler?(skippedResources, failedResources, completedResources)
        completionHandler = nil
        progressBlock = nil
    }
}
