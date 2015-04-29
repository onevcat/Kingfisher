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

import Foundation

public typealias ImageDownloaderProgressBlock = DownloadProgressBlock
public typealias ImageDownloaderCompletionHandler = CompletionHandler

public typealias RetrieveImageDownloadTask = NSURLSessionDataTask

private let defaultDownloaderName = "default"
private let downloaderBarrierName = "com.onevcat.Kingfisher.ImageDownloader.Barrier."
private let imageProcessQueueName = "com.onevcat.Kingfisher.ImageDownloader.Process."
private let instance = ImageDownloader(name: defaultDownloaderName)

public class ImageDownloader: NSObject {
    
    class ImageFetchLoad {
        var callbacks = [CallbackPair]()
        var responseData = NSMutableData()
        var shouldDecode = false
    }
    
    // MARK: - Public property
    
    /// This closure will be applied to the image download request before it being sent. You can modify the request for some customizing purpose, like adding auth token to the header or do a url mapping.
    public var requestModifier: (NSMutableURLRequest -> Void)?

    /// The duration before the download is timeout. Default is 15 seconds.
    public var downloadTimeout: NSTimeInterval = 15.0
    
    /// A set of trusted hosts when receiving server trust challenges. A challenge with host name contained in this set will be ignored. You can use this set to specify the self-signed site.
    public var trustedHosts: Set<String>?
    
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
    
    :param: name The name for the downloader. It should not be empty.
    
    :returns: The downloader object.
    */
    public init(name: String) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the downloader. A downloader with empty name is not permitted.")
        }
        
        barrierQueue = dispatch_queue_create(downloaderBarrierName + name, DISPATCH_QUEUE_CONCURRENT)
        processQueue = dispatch_queue_create(imageProcessQueueName + name, DISPATCH_QUEUE_CONCURRENT)
    }
}

// MARK: - Download method
public extension ImageDownloader {
    /**
    Download an image with a URL.
    
    :param: URL               Target URL.
    :param: progressBlock     Called when the download progress updated.
    :param: completionHandler Called when the download progress finishes.
    */
    public func downloadImageWithURL(URL: NSURL,
                           progressBlock: ImageDownloaderProgressBlock?,
                       completionHandler: ImageDownloaderCompletionHandler?)
    {
        downloadImageWithURL(URL, options: KingfisherManager.OptionsNone, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
    Download an image with a URL and option.
    
    :param: URL               Target URL.
    :param: options           The options could control download behavior. See `KingfisherManager.Options`
    :param: progressBlock     Called when the download progress updated.
    :param: completionHandler Called when the download progress finishes.
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
        let timeout = self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
        
        // We need to set the URL as the load key. So before setup progress, we need to ask the `requestModifier` for a final URL.
        let request = NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.HTTPShouldUsePipelining = true
        
        self.requestModifier?(request)
        
        // There is a possiblility that request modifier changed the url to `nil`
        if request.URL == nil {
            completionHandler?(image: nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.InvalidURL.rawValue, userInfo: nil), cacheType: .None, imageURL: nil)
            return
        }
        
        setupProgressBlock(progressBlock, completionHandler: completionHandler, forURL: request.URL!) {(session, fetchLoad) -> Void in
            let task = session.dataTaskWithRequest(request)
            
            task.priority = options.lowPriority ? NSURLSessionTaskPriorityLow : NSURLSessionTaskPriorityDefault
            task.resume()
            
            fetchLoad.shouldDecode = options.shouldDecode
            
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
                let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration(), delegate: self, delegateQueue:NSOperationQueue.mainQueue())
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
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if let URL = dataTask.originalRequest.URL, callbackPairs = fetchLoads[URL]?.callbacks {
            for callbackPair in callbackPairs {
                callbackPair.progressBlock?(receivedSize: 0, totalSize: response.expectedContentLength)
            }
        }
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {

        if let URL = dataTask.originalRequest.URL, fetchLoad = fetchLoads[URL] {
            fetchLoad.responseData.appendData(data)
            for callbackPair in fetchLoad.callbacks {
                callbackPair.progressBlock?(receivedSize: Int64(fetchLoad.responseData.length), totalSize: dataTask.response!.expectedContentLength)
            }
        }
    }
    
    private func callbackWithImage(image: UIImage?, error: NSError?, imageURL: NSURL) {
        if let callbackPairs = self.fetchLoads[imageURL]?.callbacks {
            for callbackPair in callbackPairs {
                callbackPair.completionHander?(image: image, error: error, cacheType: .None, imageURL: imageURL)
            }
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let URL = task.originalRequest.URL {
            if let error = error { // Error happened
                callbackWithImage(nil, error: error, imageURL: URL)
            } else { //Download finished without error
                
                // We are on main queue when receiving this.
                dispatch_async(processQueue, { () -> Void in
                    
                    if let fetchLoad = self.fetchLoads[URL] {
                        if let image = UIImage(data: fetchLoad.responseData) {
                            if fetchLoad.shouldDecode {
                                self.callbackWithImage(image.kf_decodedImage(), error: nil, imageURL: URL)
                            } else {
                                self.callbackWithImage(image, error: nil, imageURL: URL)
                            }
                            
                        } else {
                            self.callbackWithImage(nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.BadData.rawValue, userInfo: nil), imageURL: URL)
                        }
                    } else {
                        self.callbackWithImage(nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.BadData.rawValue, userInfo: nil), imageURL: URL)
                    }
                    
                    self.cleanForURL(URL)
                })
            }
        }
    }

    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustedHosts = trustedHosts where trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust)
                completionHandler(.UseCredential, credential)
                return
            }
        }
        
        completionHandler(.PerformDefaultHandling, nil)
    }
    
}
