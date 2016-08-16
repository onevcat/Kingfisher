//
//  ImageDownloader.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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

/// Progress update block of downloader.
public typealias ImageDownloaderProgressBlock = DownloadProgressBlock

/// Completion block of downloader.
public typealias ImageDownloaderCompletionHandler = ((_ image: Image?, _ error: NSError?, _ url: URL?, _ originalData: Data?) -> ())

/// Download task.
public struct RetrieveImageDownloadTask {
    let internalTask: URLSessionDataTask
    
    /// Downloader by which this task is intialized.
    public private(set) weak var ownerDownloader: ImageDownloader?

    /**
     Cancel this download task. It will trigger the completion handler with an NSURLErrorCancelled error.
     */
    public func cancel() {
        ownerDownloader?.cancelDownloadingTask(self)
    }
    
    /// The original request URL of this download task.
    public var url: URL? {
        return internalTask.originalRequest?.url
    }
    
    /// The relative priority of this download task. 
    /// It represents the `priority` property of the internal `NSURLSessionTask` of this download task.
    /// The value for it is between 0.0~1.0. Default priority is value of 0.5.
    /// See documentation on `priority` of `NSURLSessionTask` for more about it.
    public var priority: Float {
        get {
            return internalTask.priority
        }
        set {
            internalTask.priority = newValue
        }
    }
}

private let defaultDownloaderName = "default"
private let downloaderBarrierName = "com.onevcat.Kingfisher.ImageDownloader.Barrier."
private let imageProcessQueueName = "com.onevcat.Kingfisher.ImageDownloader.Process."
private let instance = ImageDownloader(name: defaultDownloaderName)


/**
The error code.

- badData: The downloaded data is not an image or the data is corrupted.
- notModified: The remote server responsed a 304 code. No image data downloaded.
- invalidStatusCode: The HTTP status code in response is not valid. 
- notCached: The image rquested is not in cache but .onlyFromCache is activated.
- invalidURL: The URL is invalid.
*/
public enum KingfisherError: Int {
    case badData = 10000
    case notModified = 10001
    case invalidStatusCode = 10002
    case notCached = 10003
    case invalidURL = 20000
}

public let KingfisherErrorStatusCodeKey = "statusCode"

/// Protocol of `ImageDownloader`.
@objc public protocol ImageDownloaderDelegate {
    /**
    Called when the `ImageDownloader` object successfully downloaded an image from specified URL.
    
    - parameter downloader: The `ImageDownloader` object finishes the downloading.
    - parameter image:      Downloaded image.
    - parameter URL:        URL of the original request URL.
    - parameter response:   The response object of the downloading process.
    */
    @objc optional func imageDownloader(_ downloader: ImageDownloader, didDownload image: Image, for url: URL, with response: URLResponse?)
    
    
    /**
    Check if a received HTTP status code is valid or not. 
    By default, a status code between 200 to 400 (not included) is considered as valid.
    If an invalid code is received, the downloader will raise an .invalidStatusCode error.
    It has a `userInfo` which includes this statusCode and localizedString error message.
     
    - parameter code: The received HTTP status code.
    
    - returns: Whether this HTTP status code is valid or not.
     
    - Note: If the default 200 to 400 valid code does not suit your need, 
            you can implement this method to change that behavior.
    */
    @objc optional func isValidStatusCode(_ code: Int) -> Bool
}

/// Protocol indicates that an authentication challenge could be handled.
public protocol AuthenticationChallengeResponable: class {
    /**
     Called when an session level authentication challenge is received.
     This method provide a chance to handle and response to the authentication challenge before downloading could start.
     
     - parameter downloader:        The downloader which receives this challenge.
     - parameter challenge:         An object that contains the request for authentication.
     - parameter completionHandler: A handler that your delegate method must call.
     
     - Note: This method is a forward from `URLSession(:didReceiveChallenge:completionHandler:)`. Please refer to the document of it in `NSURLSessionDelegate`.
     */
    func downloader(_ downloader: ImageDownloader, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

extension AuthenticationChallengeResponable {
    
    func downloader(_ downloader: ImageDownloader, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustedHosts = downloader.trustedHosts, trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
}

/// `ImageDownloader` represents a downloading manager for requesting the image with a URL from server.
public class ImageDownloader: NSObject {
    
    class ImageFetchLoad {
        var callbacks = [CallbackPair]()
        var responseData = NSMutableData()

        var options: KingfisherOptionsInfo?
        
        var downloadTaskCount = 0
        var downloadTask: RetrieveImageDownloadTask?
    }
    
    // MARK: - Public property
    /// This closure will be applied to the image download request before it being sent. 
    /// You can modify the request for some customizing purpose, like adding auth token to the header, do basic HTTP auth or something like url mapping.
    public var requestModifier: ((inout URLRequest) -> Void)?

    /// The duration before the download is timeout. Default is 15 seconds.
    public var downloadTimeout: TimeInterval = 15.0
    
    /// A set of trusted hosts when receiving server trust challenges. A challenge with host name contained in this set will be ignored. 
    /// You can use this set to specify the self-signed site. It only will be used if you don't specify the `authenticationChallengeResponder`. 
    /// If `authenticationChallengeResponder` is set, this property will be ignored and the implemention of `authenticationChallengeResponder` will be used instead.
    public var trustedHosts: Set<String>?
    
    /// Use this to set supply a configuration for the downloader. By default, NSURLSessionConfiguration.ephemeralSessionConfiguration() will be used. 
    /// You could change the configuration before a downloaing task starts. A configuration without persistent storage for caches is requsted for downloader working correctly.
    public var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: OperationQueue.main)
        }
    }
    
    /// Whether the download requests should use pipeling or not. Default is false.
    public var requestsUsePipeling = false
    
    fileprivate let sessionHandler: ImageDownloaderSessionHandler
    fileprivate var session: URLSession?
    
    /// Delegate of this `ImageDownloader` object. See `ImageDownloaderDelegate` protocol for more.
    public weak var delegate: ImageDownloaderDelegate?
    
    /// A responder for authentication challenge. 
    /// Downloader will forward the received authentication challenge for the downloading session to this responder.
    public weak var authenticationChallengeResponder: AuthenticationChallengeResponable?
    
    // MARK: - Internal property
    let barrierQueue: DispatchQueue
    let processQueue: DispatchQueue
    
    typealias CallbackPair = (progressBlock: ImageDownloaderProgressBlock?, completionHander: ImageDownloaderCompletionHandler?)
    
    var fetchLoads = [URL: ImageFetchLoad]()
    
    // MARK: - Public method
    /// The default downloader.
    public class var `default`: ImageDownloader {
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
        
        barrierQueue = DispatchQueue(label: downloaderBarrierName + name, attributes: .concurrent)
        processQueue = DispatchQueue(label: imageProcessQueueName + name, attributes: .concurrent)
        
        sessionHandler = ImageDownloaderSessionHandler()
        
        super.init()
        
        // Provide a default implement for challenge responder.
        authenticationChallengeResponder = sessionHandler
        session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: .main)
    }
    
    func fetchLoad(for url: URL) -> ImageFetchLoad? {
        var fetchLoad: ImageFetchLoad?
        barrierQueue.sync { fetchLoad = fetchLoads[url] }
        return fetchLoad
    }
}

// MARK: - Download method
extension ImageDownloader {
    /**
    Download an image with a URL.
    
    - parameter url:               Target URL.
    - parameter progressBlock:     Called when the download progress updated.
    - parameter completionHandler: Called when the download progress finishes.
    
    - returns: A downloading task. You could call `cancel` on it to stop the downloading process.
    */
    @discardableResult
    public func downloadImage(with url: URL,
                           progressBlock: ImageDownloaderProgressBlock?,
                       completionHandler: ImageDownloaderCompletionHandler?) -> RetrieveImageDownloadTask?
    {
        return downloadImage(with: url, options: nil, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
    Download an image with a URL and option.
    
    - parameter url:               Target URL.
    - parameter options:           The options could control download behavior. See `KingfisherOptionsInfo`.
    - parameter progressBlock:     Called when the download progress updated.
    - parameter completionHandler: Called when the download progress finishes.

    - returns: A downloading task. You could call `cancel` on it to stop the downloading process.
    */
    @discardableResult
    public func downloadImage(with url: URL,
                                 options: KingfisherOptionsInfo?,
                           progressBlock: ImageDownloaderProgressBlock?,
                       completionHandler: ImageDownloaderCompletionHandler?) -> RetrieveImageDownloadTask?
    {
        return downloadImage(with: url,
                retrieveImageTask: nil,
                          options: options,
                    progressBlock: progressBlock,
                completionHandler: completionHandler)
    }
    
    func downloadImage(with url: URL,
              retrieveImageTask: RetrieveImageTask?,
                        options: KingfisherOptionsInfo?,
                  progressBlock: ImageDownloaderProgressBlock?,
              completionHandler: ImageDownloaderCompletionHandler?) -> RetrieveImageDownloadTask?
    {
        if let retrieveImageTask = retrieveImageTask, retrieveImageTask.cancelledBeforeDownloadStarting {
            return nil
        }
        
        let timeout = self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
        
        // We need to set the URL as the load key. So before setup progress, we need to ask the `requestModifier` for a final URL.
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpShouldUsePipelining = requestsUsePipeling
        
        self.requestModifier?(&request)
        
        // There is a possiblility that request modifier changed the url to `nil` or empty.
        guard let url = request.url, !url.absoluteString.isEmpty else {
            completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.invalidURL.rawValue, userInfo: nil), nil, nil)
            return nil
        }
        
        var downloadTask: RetrieveImageDownloadTask?
        setup(progressBlock: progressBlock, with: completionHandler, for: url) {(session, fetchLoad) -> Void in
            if fetchLoad.downloadTask == nil {
                let dataTask = session.dataTask(with: request)
                
                fetchLoad.downloadTask = RetrieveImageDownloadTask(internalTask: dataTask, ownerDownloader: self)
                fetchLoad.options = options
                
                dataTask.priority = options?.downloadPriority ?? URLSessionTask.defaultPriority
                dataTask.resume()
                
                // Hold self while the task is executing.
                self.sessionHandler.downloadHolder = self
            }
            
            fetchLoad.downloadTaskCount += 1
            downloadTask = fetchLoad.downloadTask
            
            retrieveImageTask?.downloadTask = downloadTask
        }
        return downloadTask
    }
    
    // A single key may have multiple callbacks. Only download once.
    func setup(progressBlock: ImageDownloaderProgressBlock?, with completionHandler: ImageDownloaderCompletionHandler?, for url: URL, started: ((URLSession, ImageFetchLoad) -> Void)) {

        barrierQueue.sync(flags: .barrier) {
            let loadObjectForURL = fetchLoads[url] ?? ImageFetchLoad()
            let callbackPair = (progressBlock: progressBlock, completionHander: completionHandler)
            
            loadObjectForURL.callbacks.append(callbackPair)
            fetchLoads[url] = loadObjectForURL
            
            if let session = session {
                started(session, loadObjectForURL)
            }
        }
    }
    
    func cancelDownloadingTask(_ task: RetrieveImageDownloadTask) {
        barrierQueue.sync {
            if let URL = task.internalTask.originalRequest?.url, let imageFetchLoad = self.fetchLoads[URL] {
                imageFetchLoad.downloadTaskCount -= 1
                if imageFetchLoad.downloadTaskCount == 0 {
                    task.internalTask.cancel()
                }
            }
        }
    }
    
    func clean(for url: URL) {
        barrierQueue.sync(flags: .barrier) {
            fetchLoads.removeValue(forKey: url)
            return
        }
    }
}

// MARK: - NSURLSessionDataDelegate

/// Delegate class for `NSURLSessionTaskDelegate`.
/// The session object will hold its delegate until it gets invalidated.
/// If we use `ImageDownloader` as the session delegate, it will not be released.
/// So we need an additional handler to break the retain cycle.
// See https://github.com/onevcat/Kingfisher/issues/235
class ImageDownloaderSessionHandler: NSObject, URLSessionDataDelegate, AuthenticationChallengeResponable {
    
    // The holder will keep downloader not released while a data task is being executed.
    // It will be set when the task started, and reset when the task finished.
    var downloadHolder: ImageDownloader?
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  let url = dataTask.originalRequest?.url, !isValidStatusCode(code: statusCode)
        {
            callback(with: nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.invalidStatusCode.rawValue, userInfo: [KingfisherErrorStatusCodeKey: statusCode, NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)]), url: url, originalData: nil)
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        guard let downloader = downloadHolder else {
            return
        }
        
        if let url = dataTask.originalRequest?.url, let fetchLoad = downloader.fetchLoad(for: url) {
            fetchLoad.responseData.append(data)
            
            for callbackPair in fetchLoad.callbacks {
                DispatchQueue.main.async(execute: { () -> Void in
                    callbackPair.progressBlock?(Int64(fetchLoad.responseData.length), dataTask.response!.expectedContentLength)
                })
            }
        }
    }
    
    
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let url = task.originalRequest?.url {
            if let error = error { // Error happened
                callback(with: nil, error: error as NSError, url: url, originalData: nil)
            } else { //Download finished without error
                processImage(for: task, url: url)
            }
        }
    }
    
    /**
    This method is exposed since the compiler requests. Do not call it.
    */
    internal func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let downloader = downloadHolder else {
            return
        }
        
        downloader.authenticationChallengeResponder?.downloader(downloader, didReceive: challenge, completionHandler: completionHandler)
    }
    
    private func callback(with image: Image?, error: NSError?, url: URL, originalData: Data?) {
        
        guard let downloader = downloadHolder else {
            return
        }
        
        if let callbackPairs = downloader.fetchLoad(for: url)?.callbacks {
            let options = downloader.fetchLoad(for: url)?.options ?? KingfisherEmptyOptionsInfo
            
            downloader.clean(for: url)
            
            for callbackPair in callbackPairs {
                options.callbackDispatchQueue.safeAsync {
                    callbackPair.completionHander?(image, error, url, originalData)
                }
            }
            
            if downloader.fetchLoads.isEmpty {
                downloadHolder = nil
            }
        }
    }
    
    private func processImage(for task: URLSessionTask, url: URL) {

        guard let downloader = downloadHolder else {
            return
        }
        
        // We are on main queue when receiving this.
        downloader.processQueue.async {
            
            guard let fetchLoad = downloader.fetchLoad(for: url) else {
                self.callback(with: nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.badData.rawValue, userInfo: nil), url: url, originalData: nil)
                return
            }

            let options = fetchLoad.options ?? KingfisherEmptyOptionsInfo
            let data = fetchLoad.responseData as Data
            if let image = Image.kf_image(data: data, scale: options.scaleFactor, preloadAllGIFData: options.preloadAllGIFData) {
                
                downloader.delegate?.imageDownloader?(downloader, didDownload: image, for: url, with: task.response)
                
                if options.backgroundDecode {
                    self.callback(with: image.kf_decoded(scale: options.scaleFactor), error: nil, url: url, originalData: data)
                } else {
                    self.callback(with: image, error: nil, url: url, originalData: data)
                }
                
            } else {
                // If server response is 304 (Not Modified), inform the callback handler with NotModified error.
                // It should be handled to get an image from cache, which is response of a manager object.
                if let res = task.response as? HTTPURLResponse , res.statusCode == 304 {
                    self.callback(with: nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.notModified.rawValue, userInfo: nil), url: url, originalData: nil)
                    return
                }
                
                self.callback(with: nil, error: NSError(domain: KingfisherErrorDomain, code: KingfisherError.badData.rawValue, userInfo: nil), url: url, originalData: nil)
            }
        }
    }
    
    private func isValidStatusCode(code: Int) -> Bool {
        let inDefaultValidRange = (200..<400).contains(code)
        if let delegate = downloadHolder?.delegate {
            return delegate.isValidStatusCode?(code) ?? inDefaultValidRange
        } else {
            return inDefaultValidRange
        }
    }
}
