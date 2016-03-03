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


#if os(OSX)
    import AppKit
#else
    import UIKit
#endif


/// Progress update block of prefetcher.
public typealias PrefetchProgressBlock = ((completedURLs: Int, allURLs: Int) -> ())

/// Completion block of prefetcher.
public typealias PrefetchCompletionBlock = ((cancelled: Bool, completedURLs: Int, skippedURLs: Int) -> ())

private let defaultPrefetcherInstance = ImagePrefetcher()

/// `ImagePrefetcher` represents a downloading manager for requesting many images via URLs and caching them.
public class ImagePrefetcher: NSObject {
    
    private var prefetchURLs: [NSURL]?
    private var skippedCount = 0
    private var requestedCount = 0
    private var finishedCount = 0
    
    private var cancelCompletionHandlerCalled = false
    
    /// The default manager to use for downloads.
    public lazy var manager: KingfisherManager = KingfisherManager.sharedManager

    /// The default prefetcher.
    public class var defaultPrefetcher: ImagePrefetcher {
        return defaultPrefetcherInstance
    }

    /// The maximum concurrent downloads to use when prefetching images. Default is 5.
    public var maxConcurrentDownloads = 5
    
    /**
     Download the images from `urls` and cache them. This can be useful for background downloading
     of assets that are required for later use in an app. This code will not try and update any UI
     with the results of the process, but calls the handlers with the number cached etc. Failed
     images are just skipped.
     
     Warning: This will cancel any existing prefetch operation in progress! Use `isPrefetching() to
     control this in your own code as you see fit.
     
     - parameter urls:              The list of URLs to prefetch
     - parameter progressBlock:     Block to be called when progress updates. Completed and total
                                    counts are provided. Completed does not imply success.
     - parameter completionHandler: Block to be called when prefetching is complete. Completed is all
                                    those made, and skipped is the number of failed ones.
     */
    public func prefetchURLs(urls: [NSURL], progressBlock: PrefetchProgressBlock?, completionHandler: PrefetchCompletionBlock?) {
        
        // Clear out any existing prefetch operation first
        cancelPrefetching()
        
        cancelCompletionHandlerCalled = false
        
        prefetchURLs = urls
        
        guard urls.count > 0 else {
            CompletionHandler?()
            return
        }
        
        for i in (0..<urls.count) where i < maxConcurrentDownloads && requestedCount < urls.count {
            startPrefetching(i, progressBlock: progressBlock, completionHandler: completionHandler)
        }
    }
   
    /**
     This cancels any existing prefetching activity that might be occuring. It does not stop any currently
     running cache operation, but prevents any further ones being started and terminates the looping. For
     surety, be sure that the completion block on the prefetch is called after calling this if you expect
     an operation to be running.
     */
    func cancelPrefetching() {
        prefetchURLs = .None
        skippedCount = 0
        requestedCount = 0
        finishedCount = 0
    }

    /**
     Checks to see if this prefetcher is already prefetching any images.
     
     - returns: True if there are images still to be prefetched, false otherwise.
     */
    func isPrefetching() -> Bool {
        guard let urls = prefetchURLs else { return false }
        return urls.count > 0
    }
    
    internal func startPrefetching(index: Int, progressBlock: PrefetchProgressBlock?, completionHandler: PrefetchCompletionBlock?) {
        guard let urls = prefetchURLs where index < (urls.count ?? 0) else { return }
        
        requestedCount++
        
        let task = RetrieveImageTask()
        let resource = Resource(downloadURL: urls[index])
        let total = urls.count
        
        manager.downloadAndCacheImageWithURL(resource.downloadURL, forKey: resource.cacheKey, retrieveImageTask: task, progressBlock: nil, completionHandler: { image, error, cacheType, imageURL in
            self.finishedCount++
            
            if image == .None {
                self.skippedCount++
            }
            
            progressBlock?(completedURLs: self.finishedCount, allURLs: total)
            
            // Reference the prefetchURLs rather than urls in case the request has been cancelled
            if (self.prefetchURLs?.count ?? 0) > self.requestedCount {
                self.startPrefetching(self.requestedCount, progressBlock: progressBlock, completionHandler: completionHandler)
            } else if self.finishedCount == self.requestedCount {
                self.prefetchURLs?.removeAll()
                completionHandler?(cancelled: false, completedURLs: self.finishedCount, skippedURLs: self.skippedCount)
            } else if (self.prefetchURLs == nil || self.prefetchURLs!.count == 0) && !self.cancelCompletionHandlerCalled {
                self.cancelCompletionHandlerCalled = true
                completionHandler?(cancelled: true, completedURLs: self.finishedCount, skippedURLs: self.skippedCount)
            }
            
        }, options: nil)
    }
}
