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
public typealias PrefetchCompletionBlock = ((completedURLs: Int, skippedURLs: Int) -> ())


/// `ImagePrefetcher` represents a downloading manager for requesting many images via URLs and caching them.
public class ImagePrefetcher: NSObject {
    
    private var prefetchURLs: [NSURL]?
    private var skippedCount = 0
    private var requestedCount = 0
    private var finishedCount = 0
    
    private var downloader: ImageDownloader

    /// The maximum concurrent downloads to use when prefetching images. Default is 5.
    var maxConcurrentDownloads = 5
    
    public init(downloader: ImageDownloader) {
        self.downloader = downloader
        super.init()
    }
    
    /**
     Download the images from `urls` and cache them. This can be useful for background downloading
     of assets that are required for later use in an app. This code will not try and update any UI
     with the results of the process, but calls the handlers with the number cached etc. Failed
     images are just skipped.
     
     - parameter urls:              The list of URLs to prefetch
     - parameter progressBlock:     Block to be called when progress updates. Completed and total
                                    counts are provided. Completed does not imply success.
     - parameter completionHandler: Block to be called when prefetching is complete. Completed is all
                                    those made, and skipped is the number of failed ones.
     */
    public func prefetchURLs(urls: [NSURL], progressBlock: PrefetchProgressBlock?, completionHandler: PrefetchCompletionBlock?) {
        
        // Clear out any existing prefetch operation first
        cancelPrefetching()
        
        prefetchURLs = urls
        
        guard urls.count > 0 else {
            CompletionHandler?()
            return
        }
        
        for (var i = 0; i < maxConcurrentDownloads && requestedCount < urls.count; i++) {
            startPrefetching(i, progressBlock: progressBlock, completionHandler: completionHandler)
        }
    }
   
    internal func cancelPrefetching() {
        prefetchURLs = .None
        skippedCount = 0
        requestedCount = 0
        finishedCount = 0
    }

    internal func startPrefetching(index: Int, progressBlock: PrefetchProgressBlock?, completionHandler: PrefetchCompletionBlock?) {
        guard let urls = prefetchURLs where index < (urls.count ?? 0) else { return }
        
        requestedCount++
        
        let task = RetrieveImageTask()
        let resource = Resource(downloadURL: urls[index])
        KingfisherManager.sharedManager.downloadAndCacheImageWithURL(resource.downloadURL, forKey: resource.cacheKey, retrieveImageTask: task, progressBlock: nil, completionHandler: { image, error, cacheType, imageURL in
            self.finishedCount++
            
            if image == .None {
                self.skippedCount++
            }
            
            progressBlock?(completedURLs: self.finishedCount, allURLs: urls.count)
            
            if urls.count > self.requestedCount {
                self.startPrefetching(self.requestedCount, progressBlock: progressBlock, completionHandler: completionHandler)
            } else if self.finishedCount == self.requestedCount {
                completionHandler?(completedURLs: self.finishedCount, skippedURLs: self.skippedCount)
            }
        }, options: nil)
    }
}
