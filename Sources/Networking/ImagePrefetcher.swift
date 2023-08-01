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

/// Progress update block of prefetcher when initialized with a list of resources.
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while
///                      downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherProgressBlock =
    ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> Void)

/// Progress update block of prefetcher when initialized with a list of resources.
///
/// - `skippedSources`: An array of sources that are already cached before the prefetching starting.
/// - `failedSources`: An array of sources that fail to be fetched.
/// - `completedResources`: An array of sources that are fetched and cached successfully.
public typealias PrefetcherSourceProgressBlock =
    ((_ skippedSources: [Source], _ failedSources: [Source], _ completedSources: [Source]) -> Void)

/// Completion block of prefetcher when initialized with a list of sources.
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while
///                      downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherCompletionHandler =
    ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> Void)

/// Completion block of prefetcher when initialized with a list of sources.
///
/// - `skippedSources`: An array of sources that are already cached before the prefetching starting.
/// - `failedSources`: An array of sources that fail to be fetched.
/// - `completedSources`: An array of sources that are fetched and cached successfully.
public typealias PrefetcherSourceCompletionHandler =
    ((_ skippedSources: [Source], _ failedSources: [Source], _ completedSources: [Source]) -> Void)

/// `ImagePrefetcher` represents a downloading manager for requesting many images via URLs, then caching them.
/// This is useful when you know a list of image resources and want to download them before showing. It also works with
/// some Cocoa prefetching mechanism like table view or collection view `prefetchDataSource`, to start image downloading
/// and caching before they display on screen.
public class ImagePrefetcher: CustomStringConvertible {

    public var description: String {
        return "\(Unmanaged.passUnretained(self).toOpaque())"
    }
    
    /// The maximum concurrent downloads to use when prefetching images. Default is 5.
    public var maxConcurrentDownloads = 5

    private let prefetchSources: [Source]
    private let optionsInfo: KingfisherParsedOptionsInfo

    private var progressBlock: PrefetcherProgressBlock?
    private var completionHandler: PrefetcherCompletionHandler?

    private var progressSourceBlock: PrefetcherSourceProgressBlock?
    private var completionSourceHandler: PrefetcherSourceCompletionHandler?
    
    private var tasks = [String: DownloadTask.WrappedTask]()
    
    private var pendingSources: ArraySlice<Source>
    private var skippedSources = [Source]()
    private var completedSources = [Source]()
    private var failedSources = [Source]()
    
    private var stopped = false
    
    // A manager used for prefetching. We will use the helper methods in manager.
    private let manager: KingfisherManager

    private let prefetchQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImagePrefetcher.prefetchQueue")
    private static let requestingQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImagePrefetcher.requestingQueue")

    private var finished: Bool {
        let totalFinished: Int = failedSources.count + skippedSources.count + completedSources.count
        return totalFinished == prefetchSources.count && tasks.isEmpty
    }

    /// Creates an image prefetcher with an array of URLs.
    ///
    /// The prefetcher should be initiated with a list of prefetching targets. The URLs list is immutable.
    /// After you get a valid `ImagePrefetcher` object, you call `start()` on it to begin the prefetching process.
    /// The images which are already cached will be skipped without downloading again.
    ///
    /// - Parameters:
    ///   - urls: The URLs which should be prefetched.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time an resource is downloaded, skipped or cancelled.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public convenience init(
        urls: [URL],
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

    /// Creates an image prefetcher with an array of URLs.
    ///
    /// The prefetcher should be initiated with a list of prefetching targets. The URLs list is immutable.
    /// After you get a valid `ImagePrefetcher` object, you call `start()` on it to begin the prefetching process.
    /// The images which are already cached will be skipped without downloading again.
    ///
    /// - Parameters:
    ///   - urls: The URLs which should be prefetched.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public convenience init(
        urls: [URL],
        options: KingfisherOptionsInfo? = nil,
        completionHandler: PrefetcherCompletionHandler? = nil)
    {
        let resources: [Resource] = urls.map { $0 }
        self.init(
            resources: resources,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler)
    }

    /// Creates an image prefetcher with an array of resources.
    ///
    /// - Parameters:
    ///   - resources: The resources which should be prefetched. See `Resource` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time an resource is downloaded, skipped or cancelled.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public convenience init(
        resources: [Resource],
        options: KingfisherOptionsInfo? = nil,
        progressBlock: PrefetcherProgressBlock? = nil,
        completionHandler: PrefetcherCompletionHandler? = nil)
    {
        self.init(sources: resources.map { $0.convertToSource() }, options: options)
        self.progressBlock = progressBlock
        self.completionHandler = completionHandler
    }

    /// Creates an image prefetcher with an array of resources.
    ///
    /// - Parameters:
    ///   - resources: The resources which should be prefetched. See `Resource` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public convenience init(
        resources: [Resource],
        options: KingfisherOptionsInfo? = nil,
        completionHandler: PrefetcherCompletionHandler? = nil)
    {
        self.init(sources: resources.map { $0.convertToSource() }, options: options)
        self.completionHandler = completionHandler
    }

    /// Creates an image prefetcher with an array of sources.
    ///
    /// - Parameters:
    ///   - sources: The sources which should be prefetched. See `Source` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called every time an source fetching successes, fails, is skipped.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public convenience init(sources: [Source],
        options: KingfisherOptionsInfo? = nil,
        progressBlock: PrefetcherSourceProgressBlock? = nil,
        completionHandler: PrefetcherSourceCompletionHandler? = nil)
    {
        self.init(sources: sources, options: options)
        self.progressSourceBlock = progressBlock
        self.completionSourceHandler = completionHandler
    }

    /// Creates an image prefetcher with an array of sources.
    ///
    /// - Parameters:
    ///   - sources: The sources which should be prefetched. See `Source` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - completionHandler: Called when the whole prefetching process finished.
    ///
    /// - Note:
    /// By default, the `ImageDownloader.defaultDownloader` and `ImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `optionsInfo` will be ignored in this method.
    public convenience init(sources: [Source],
        options: KingfisherOptionsInfo? = nil,
        completionHandler: PrefetcherSourceCompletionHandler? = nil)
    {
        self.init(sources: sources, options: options)
        self.completionSourceHandler = completionHandler
    }

    init(sources: [Source], options: KingfisherOptionsInfo?) {
        var options = KingfisherParsedOptionsInfo(options)
        prefetchSources = sources
        pendingSources = ArraySlice(sources)

        // We want all callbacks from our prefetch queue, so we should ignore the callback queue in options.
        // Add our own callback dispatch queue to make sure all internal callbacks are
        // coming back in our expected queue.
        options.callbackQueue = .dispatch(prefetchQueue)
        optionsInfo = options

        let cache = optionsInfo.targetCache ?? .default
        let downloader = optionsInfo.downloader ?? .default
        manager = KingfisherManager(downloader: downloader, cache: cache)
    }

    /// Starts to download the resources and cache them. This can be useful for background downloading
    /// of assets that are required for later use in an app. This code will not try and update any UI
    /// with the results of the process.
    public func start() {
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
            guard self.prefetchSources.count > 0 else {
                self.handleComplete()
                return
            }

            let initialConcurrentDownloads = min(self.prefetchSources.count, self.maxConcurrentDownloads)
            for _ in 0 ..< initialConcurrentDownloads {
                if let resource = self.pendingSources.popFirst() {
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
    
    private func downloadAndCache(_ source: Source) {

        let downloadTaskCompletionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void) = { result in
            self.tasks.removeValue(forKey: source.cacheKey)
            do {
                let _ = try result.get()
                self.completedSources.append(source)
            } catch {
                self.failedSources.append(source)
            }
            
            self.reportProgress()
            if self.stopped {
                if self.tasks.isEmpty {
                    self.failedSources.append(contentsOf: self.pendingSources)
                    self.handleComplete()
                }
            } else {
                self.reportCompletionOrStartNext()
            }
        }

        var downloadTask: DownloadTask.WrappedTask?
        ImagePrefetcher.requestingQueue.sync {
            let context = RetrievingContext(
                options: optionsInfo, originalSource: source
            )
            downloadTask = manager.loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: downloadTaskCompletionHandler)
        }

        if let downloadTask = downloadTask {
            tasks[source.cacheKey] = downloadTask
        }
    }
    
    private func append(cached source: Source) {
        skippedSources.append(source)
 
        reportProgress()
        reportCompletionOrStartNext()
    }
    
    private func startPrefetching(_ source: Source)
    {
        if optionsInfo.forceRefresh {
            downloadAndCache(source)
            return
        }
        
        let cacheType = manager.cache.imageCachedType(
            forKey: source.cacheKey,
            processorIdentifier: optionsInfo.processor.identifier)
        switch cacheType {
        case .memory:
            append(cached: source)
        case .disk:
            if optionsInfo.alsoPrefetchToMemory {
                let context = RetrievingContext(options: optionsInfo, originalSource: source)
                _ = manager.retrieveImageFromCache(
                    source: source,
                    context: context)
                {
                    _ in
                    self.append(cached: source)
                }
            } else {
                append(cached: source)
            }
        case .none:
            downloadAndCache(source)
        }
    }
    
    private func reportProgress() {

        if progressBlock == nil && progressSourceBlock == nil {
            return
        }

        let skipped = self.skippedSources
        let failed = self.failedSources
        let completed = self.completedSources
        CallbackQueue.mainCurrentOrAsync.execute {
            self.progressSourceBlock?(skipped, failed, completed)
            self.progressBlock?(
                skipped.compactMap { $0.asResource },
                failed.compactMap { $0.asResource },
                completed.compactMap { $0.asResource }
            )
        }
    }
    
    private func reportCompletionOrStartNext() {
        if let resource = self.pendingSources.popFirst() {
            // Loose call stack for huge ammount of sources.
            prefetchQueue.async { self.startPrefetching(resource) }
        } else {
            guard allFinished else { return }
            self.handleComplete()
        }
    }

    var allFinished: Bool {
        return skippedSources.count + failedSources.count + completedSources.count == prefetchSources.count
    }
    
    private func handleComplete() {

        if completionHandler == nil && completionSourceHandler == nil {
            return
        }
        
        // The completion handler should be called on the main thread
        CallbackQueue.mainCurrentOrAsync.execute {
            self.completionSourceHandler?(self.skippedSources, self.failedSources, self.completedSources)
            self.completionHandler?(
                self.skippedSources.compactMap { $0.asResource },
                self.failedSources.compactMap { $0.asResource },
                self.completedSources.compactMap { $0.asResource }
            )
            self.completionHandler = nil
            self.progressBlock = nil
        }
    }
}
