//
//  ImageDownloader.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

/// Progress update block of downloader.
public typealias ImageDownloaderProgressBlock = DownloadProgressBlock

/// Completion block of downloader.
public typealias ImageDownloaderCompletionHandler = ((image: UIImage?, error: NSError?, imageURL: NSURL?, originalData: NSData?) -> ())

/// Download task.
public typealias RetrieveImageDownloadTask = NSURLSessionDataTask

private let defaultDownloaderName = "default"
private let downloaderBarrierName = "com.onevcat.Kingfisher.ImageDownloader.Barrier."
private let imageProcessQueueName = "com.onevcat.Kingfisher.ImageDownloader.Process."
private let instance = ImageDownloader(name: defaultDownloaderName)


/**
The error code.

- BadData: The downloaded data is not an image or the data is corrupted.
- NotModified: The remote server responsed a 304 code. No image data downloaded.
- InvalidURL: The URL is invalid.
*/
public enum KingfisherError: Int {
    case BadData = 10000
    case NotModified = 10001
    case InvalidURL = 20000
}

/// Protocol of `ImageDownloader`.
@objc public protocol ImageDownloaderDelegate {
    /**
    Called when the `ImageDownloader` object successfully downloaded an image from specified URL.
    
    - parameter downloader: The `ImageDownloader` object finishes the downloading.
    - parameter image:      Downloaded image.
    - parameter URL:        URL of the original request URL.
    - parameter response:   The response object of the downloading process.
    */
    optional func imageDownloader(downloader: ImageDownloader, didDownloadImage image: UIImage, forURL URL: NSURL, withResponse response: NSURLResponse)
}

/// `ImageDownloader` represents a downloading manager for requesting the image with a URL from server.
public class ImageDownloader: NSObject {
    
    class ImageFetchLoad {
        var callbacks = [CallbackPair]()
        var responseData = NSMutableData()
        var shouldDecode = false
        var scale = KingfisherManager.DefaultOptions.scale
    }
    
    // MARK: - Public property
    /// This closure will be applied to the image download request before it being sent. You can modify the request for some customizing purpose, like adding auth token to the header or do a url mapping.
    public var requestModifier: (NSMutableURLRequest -> Void)?

    /// The duration before the download is timeout. Default is 15 seconds.
    public var downloadTimeout: NSTimeInterval = 15.0
    
    /// A set of trusted hosts when receiving server trust challenges. A challenge with host name contained in this set will be ignored. You can use this set to specify the self-signed site.
    public var trustedHosts: Set<String>?
    
    /// Use this to set supply a configuration for the downloader. By default, NSURLSessionConfiguration.ephemeralSessionConfiguration() will be used. You could change the configuration before a downloaing task starts. A configuration without persistent storage for caches is requsted for downloader working correctly.
    public var sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
    
    /// Delegate of this `ImageDownloader` object. See `ImageDownloaderDelegate` protocol for more.
    public weak var delegate: ImageDownloaderDelegate?
    
    // MARK: - Internal property
    let barrierQueue: dispatch_queue_t
    let processQueue: dispatch_queue_t
    
    typealias CallbackPair = (progressBlock: ImageDownloaderProgressBlock?, completionHander: ImageDownloaderCompletionHandler?)
    
    var fetchLoads = [NSURL: ImageFetchLoad]()
    
    // MARK: - Public method
    /// The default downloader.
    public class var defaultDownloader: ImageDownloader {
        return instance
    }
    
    /**
    Init a downloader with name.
    
    - parameter name: The name for the downloader. It should not be empty.
    
    - returns: The downloader object.
    */
    public init(name: String) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the downloader. A downloader with empty name is not permitted.")
        }
        
        barrierQueue = dispatch_queue_create(downloaderBarrierName + name, DISPATCH_QUEUE_CONCURRENT)
        processQueue = dispatch_queue_create(imageProcessQueueName + name, DISPATCH_QUEUE_CONCURRENT)
    }
    
    func fetchLoadForKey(key: NSURL) -> ImageFetchLoad? {
        var fetchLoad: ImageFetchLoad?
        dispatch_sync(barrierQueue, { () -> Void in
            fetchLoad = self.fetchLoads[key]
        })
        return fetchLoad
    }
}

// MARK: - Download method
public extension ImageDownloader {
    /**
    Download an image with a URL.
    
    - parameter URL:               Target URL.
    - parameter progressBlock:     Called when the download progress updated.
    - parameter completionHandler: Called when the download progress finishes.
    */
    public func downloadImageWithURL(URL: NSURL,
                           progressBlock: ImageDownloaderProgressBlock?,
                       completionHandler: ImageDownloaderCompletionHandler?)
    {
        downloadImageWithURL(URL, options: KingfisherManager.DefaultOptions, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
    Download an image with a URL and option.
    
    - parameter URL:               Target URL.
    - parameter options:           The options could control download behavior. See `KingfisherManager.Options`
    - parameter progressBlock:     Called when the download progress updated.
    - parameter completionHandler: Called when the download progress finishes.
    */
    public func downloadImageWithURL(URL: NSURL,
                                 options: KingfisherManager.Options,
                           progressBlock: ImageDownloaderProgressBlock?,
                       completionHandler: ImageDownloaderCompletionHandler?)
    {
        downloadImageWithURL(URL,
            retrieveImageTask: nil,
                      options: options,
                progressBlock: progressBlock,
            completionHandler: completionHandler)
    }
    
    internal func downloadImageWithURL(URL: NSURL,
                       retrieveImageTask: RetrieveImageTask?,
                                 options: KingfisherManager.Options,
                           progressBlock: ImageDownloaderProgressBlock?,
                       completionHandler: ImageDownloaderCompletionHandler?)
    {
        if let retrieveImageTask = retrieveImageTask where retrieveImageTask.cancelled {
            return
        }
        
        let timeout = self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
        
        // We need to set the URL as the load key. So before setup progress, we need to ask the `requestModifier` for a final URL.
        let request = NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.HTTPShouldUsePipelining = true
        
        self.requestModifier?(request)
        
        // There is a possiblility that request modifier changed the url to `nil`
        if request.URL == nil {
            completionHandler?(image: nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.InvalidURL.rawValue, userInfo: nil), imageURL: nil, originalData: nil)
            return
        }
        
        setupProgressBlock(progressBlock, completionHandler: completionHandler, forURL: request.URL!) {(session, fetchLoad) -> Void in
            let task = session.dataTaskWithRequest(request)
            task.priority = options.lowPriority ? NSURLSessionTaskPriorityLow : NSURLSessionTaskPriorityDefault
            task.resume()
            
            fetchLoad.shouldDecode = options.shouldDecode
            fetchLoad.scale = options.scale
            
            retrieveImageTask?.downloadTask = task
        }
    }
    
    // A single key may have multiple callbacks. Only download once.
    internal func setupProgressBlock(progressBlock: ImageDownloaderProgressBlock?, completionHandler: ImageDownloaderCompletionHandler?, forURL URL: NSURL, started: ((NSURLSession, ImageFetchLoad) -> Void)) {

        dispatch_barrier_sync(barrierQueue, { () -> Void in

            var create = false
            var loadObjectForURL = self.fetchLoads[URL]
            if  loadObjectForURL == nil {
                create = true
                loadObjectForURL = ImageFetchLoad()
            }
            
            let callbackPair = (progressBlock: progressBlock, completionHander: completionHandler)
            loadObjectForURL!.callbacks.append(callbackPair)
            self.fetchLoads[URL] = loadObjectForURL!
            
            if create {
                let session = NSURLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
                started(session, loadObjectForURL!)
            }
        })
    }
    
    func cleanForURL(URL: NSURL) {
        dispatch_barrier_sync(barrierQueue, { () -> Void in
            self.fetchLoads.removeValueForKey(URL)
            return
        })
    }
}

// MARK: - NSURLSessionTaskDelegate
extension ImageDownloader: NSURLSessionDataDelegate {
    /**
    This method is exposed since the compiler requests. Do not call it.
    */
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    /**
    This method is exposed since the compiler requests. Do not call it.
    */
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {

        if let URL = dataTask.originalRequest?.URL, fetchLoad = fetchLoadForKey(URL) {
            fetchLoad.responseData.appendData(data)
            
            for callbackPair in fetchLoad.callbacks {
                callbackPair.progressBlock?(receivedSize: Int64(fetchLoad.responseData.length), totalSize: dataTask.response!.expectedContentLength)
            }
        }
    }
    
    private func callbackWithImage(image: UIImage?, error: NSError?, imageURL: NSURL, originalData: NSData?) {
        if let callbackPairs = fetchLoadForKey(imageURL)?.callbacks {
            
            self.cleanForURL(imageURL)
            
            for callbackPair in callbackPairs {
                callbackPair.completionHander?(image: image, error: error, imageURL: imageURL, originalData: originalData)
            }
        }
    }
    
    /**
    This method is exposed since the compiler requests. Do not call it.
    */
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let URL = task.originalRequest?.URL {
            if let error = error { // Error happened
                callbackWithImage(nil, error: error, imageURL: URL, originalData: nil)
            } else { //Download finished without error
                
                // We are on main queue when receiving this.
                dispatch_async(processQueue, { () -> Void in
                    
                    if let fetchLoad = self.fetchLoadForKey(URL) {
                        
                        if let image = UIImage.kf_imageWithData(fetchLoad.responseData, scale: fetchLoad.scale) {
                            
                            self.delegate?.imageDownloader?(self, didDownloadImage: image, forURL: URL, withResponse: task.response!)
                            
                            if fetchLoad.shouldDecode {
                                self.callbackWithImage(image.kf_decodedImage(scale: fetchLoad.scale), error: nil, imageURL: URL, originalData: fetchLoad.responseData)
                            } else {
                                self.callbackWithImage(image, error: nil, imageURL: URL, originalData: fetchLoad.responseData)
                            }
                            
                        } else {
                            // If server response is 304 (Not Modified), inform the callback handler with NotModified error.
                            // It should be handled to get an image from cache, which is response of a manager object.
                            if let res = task.response as? NSHTTPURLResponse where res.statusCode == 304 {
                                self.callbackWithImage(nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.NotModified.rawValue, userInfo: nil), imageURL: URL, originalData: nil)
                                return
                            }
                            
                            self.callbackWithImage(nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.BadData.rawValue, userInfo: nil), imageURL: URL, originalData: nil)
                        }
                    } else {
                        self.callbackWithImage(nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.BadData.rawValue, userInfo: nil), imageURL: URL, originalData: nil)
                    }
                })
            }
        }
    }

    /**
    This method is exposed since the compiler requests. Do not call it.
    */
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustedHosts = trustedHosts where trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
                completionHandler(.UseCredential, credential)
                return
            }
        }
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
}
