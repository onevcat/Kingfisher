//
//  ImageDownloader.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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
public typealias ImageDownloaderCompletionHandler = ((_ image: Image?, _ error: NSError?, _ url: URL?, _ originalData: Data?) -> Void)

/// Download task.
public struct RetrieveImageDownloadTask {
    let internalTask: URLSessionDataTask
    
    /// Downloader by which this task is intialized.
    public private(set) weak var ownerDownloader: ImageDownloader?

    
    /// Cancel this download task. It will trigger the completion handler with an NSURLErrorCancelled error.
    /// If you want to cancel all downloading tasks, call `cancelAll()` of `ImageDownloader` instance.
    public func cancel() {
        ownerDownloader?.cancel(self)
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

///The code of errors which `ImageDownloader` might encountered.
public enum KingfisherError: Int {
    
    /// badData: The downloaded data is not an image or the data is corrupted.
    case badData = 10000
    
    /// notModified: The remote server responsed a 304 code. No image data downloaded.
    case notModified = 10001
    
    /// The HTTP status code in response is not valid. If an invalid
    /// code error received, you could check the value under `KingfisherErrorStatusCodeKey` 
    /// in `userInfo` to see the code.
    case invalidStatusCode = 10002
    
    /// notCached: The image rquested is not in cache but .onlyFromCache is activated.
    case notCached = 10003
    
    /// The URL is invalid.
    case invalidURL = 20000
    
    /// The downloading task is cancelled before started.
    case downloadCancelledBeforeStarting = 30000
}

/// Key will be used in the `userInfo` of `.invalidStatusCode`
public let KingfisherErrorStatusCodeKey = "statusCode"

/// Protocol of `ImageDownloader`.
public protocol ImageDownloaderDelegate: class {
    /**
    Called when the `ImageDownloader` object successfully downloaded an image from specified URL.
    
    - parameter downloader: The `ImageDownloader` object finishes the downloading.
    - parameter image:      Downloaded image.
    - parameter url:        URL of the original request URL.
    - parameter response:   The response object of the downloading process.
    */
    func imageDownloader(_ downloader: ImageDownloader, didDownload image: Image, for url: URL, with response: URLResponse?)
    
    /**
    Called when the `ImageDownloader` object starts to download an image from specified URL.
     
    - parameter downloader: The `ImageDownloader` object starts the downloading.
    - parameter url:        URL of the original request.
    - parameter response:   The request object of the downloading process.
    */
    func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?)
    
    /**
    Check if a received HTTP status code is valid or not. 
    By default, a status code between 200 to 400 (excluded) is considered as valid.
    If an invalid code is received, the downloader will raise an .invalidStatusCode error.
    It has a `userInfo` which includes this statusCode and localizedString error message.
     
    - parameter code: The received HTTP status code.
    - parameter downloader: The `ImageDownloader` object asking for validate status code.
     
    - returns: Whether this HTTP status code is valid or not.
     
    - Note: If the default 200 to 400 valid code does not suit your need, 
            you can implement this method to change that behavior.
    */
    func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool
    
    /**
     Called when the `ImageDownloader` object successfully downloaded image data from specified URL.
     
     - parameter downloader: The `ImageDownloader` object finishes data downloading.
     - parameter data:       Downloaded data.
     - parameter url:        URL of the original request URL.
     
     - returns: The data from which Kingfisher should use to create an image.
     
     - Note: This callback can be used to preprocess raw image data
             before creation of UIImage instance (i.e. decrypting or verification).
     */
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data?
}

extension ImageDownloaderDelegate {
    public func imageDownloader(_ downloader: ImageDownloader, didDownload image: Image, for url: URL, with response: URLResponse?) {}
    
    public func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?) {}
    public func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool {
        return (200..<400).contains(code)
    }
    public func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data? {
        return data
    }
}

/// Protocol indicates that an authentication challenge could be handled.
public protocol AuthenticationChallengeResponsable: class {
    /**
     Called when an session level authentication challenge is received.
     This method provide a chance to handle and response to the authentication challenge before downloading could start.
     
     - parameter downloader:        The downloader which receives this challenge.
     - parameter challenge:         An object that contains the request for authentication.
     - parameter completionHandler: A handler that your delegate method must call.
     
     - Note: This method is a forward from `URLSessionDelegate.urlSession(:didReceiveChallenge:completionHandler:)`. Please refer to the document of it in `URLSessionDelegate`.
     */
    func downloader(_ downloader: ImageDownloader, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    /**
     Called when an session level authentication challenge is received.
     This method provide a chance to handle and response to the authentication challenge before downloading could start.
     
     - parameter downloader:        The downloader which receives this challenge.
     - parameter task:              The task whose request requires authentication.
     - parameter challenge:         An object that contains the request for authentication.
     - parameter completionHandler: A handler that your delegate method must call.
     
     - Note: This method is a forward from `URLSessionTaskDelegate.urlSession(:task:didReceiveChallenge:completionHandler:)`. Please refer to the document of it in `URLSessionTaskDelegate`.
     */
    func downloader(_ downloader: ImageDownloader, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

extension AuthenticationChallengeResponsable {
    
    func downloader(_ downloader: ImageDownloader, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustedHosts = downloader.trustedHosts, trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func downloader(_ downloader: ImageDownloader, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }

}

/// `ImageDownloader` represents a downloading manager for requesting the image with a URL from server.
open class ImageDownloader {
    
    class ImageFetchLoad {
        var contents = [(callback: CallbackPair, options: KingfisherOptionsInfo)]()
        var responseData = NSMutableData()

        var downloadTaskCount = 0
        var downloadTask: RetrieveImageDownloadTask?
        var cancelSemaphore: DispatchSemaphore?
    }
    
    // MARK: - Public property
    /// The duration before the download is timeout. Default is 15 seconds.
    open var downloadTimeout: TimeInterval = 15.0
    
    /// A set of trusted hosts when receiving server trust challenges. A challenge with host name contained in this set will be ignored. 
    /// You can use this set to specify the self-signed site. It only will be used if you don't specify the `authenticationChallengeResponder`. 
    /// If `authenticationChallengeResponder` is set, this property will be ignored and the implemention of `authenticationChallengeResponder` will be used instead.
    open var trustedHosts: Set<String>?
    
    /// Use this to set supply a configuration for the downloader. By default, NSURLSessionConfiguration.ephemeralSessionConfiguration() will be used. 
    /// You could change the configuration before a downloaing task starts. A configuration without persistent storage for caches is requsted for downloader working correctly.
    open var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            session?.invalidateAndCancel()
            session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: OperationQueue.main)
        }
    }
    
    /// Whether the download requests should use pipeling or not. Default is false.
    open var requestsUsePipelining = false
    
    fileprivate let sessionHandler: ImageDownloaderSessionHandler
    fileprivate var session: URLSession?
    
    /// Delegate of this `ImageDownloader` object. See `ImageDownloaderDelegate` protocol for more.
    open weak var delegate: ImageDownloaderDelegate?
    
    /// A responder for authentication challenge. 
    /// Downloader will forward the received authentication challenge for the downloading session to this responder.
    open weak var authenticationChallengeResponder: AuthenticationChallengeResponsable?
    
    // MARK: - Internal property
    let barrierQueue: DispatchQueue
    let processQueue: DispatchQueue
    let cancelQueue: DispatchQueue
    
    typealias CallbackPair = (progressBlock: ImageDownloaderProgressBlock?, completionHandler: ImageDownloaderCompletionHandler?)
    
    var fetchLoads = [URL: ImageFetchLoad]()
    
    // MARK: - Public method
    /// The default downloader.
    public static let `default` = ImageDownloader(name: "default")
    
    /**
    Init a downloader with name.
    
    - parameter name: The name for the downloader. It should not be empty.
    
    - returns: The downloader object.
    */
    public init(name: String) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the downloader. A downloader with empty name is not permitted.")
        }
        
        barrierQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Barrier.\(name)", attributes: .concurrent)
        processQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process.\(name)", attributes: .concurrent)
        cancelQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Cancel.\(name)")
        
        sessionHandler = ImageDownloaderSessionHandler()

        // Provide a default implement for challenge responder.
        authenticationChallengeResponder = sessionHandler
        session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: .main)
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
    
    func fetchLoad(for url: URL) -> ImageFetchLoad? {
        var fetchLoad: ImageFetchLoad?
        barrierQueue.sync(flags: .barrier) { fetchLoad = fetchLoads[url] }
        return fetchLoad
    }
    
    /**
     Download an image with a URL and option.
     
     - parameter url:               Target URL.
     - parameter retrieveImageTask: The task to cooporate with cache. Pass `nil` if you are not trying to use downloader and cache.
     - parameter options:           The options could control download behavior. See `KingfisherOptionsInfo`.
     - parameter progressBlock:     Called when the download progress updated.
     - parameter completionHandler: Called when the download progress finishes.
     
     - returns: A downloading task. You could call `cancel` on it to stop the downloading process.
     */
    @discardableResult
    open func downloadImage(with url: URL,
                       retrieveImageTask: RetrieveImageTask? = nil,
                       options: KingfisherOptionsInfo? = nil,
                       progressBlock: ImageDownloaderProgressBlock? = nil,
                       completionHandler: ImageDownloaderCompletionHandler? = nil) -> RetrieveImageDownloadTask?
    {
        if let retrieveImageTask = retrieveImageTask, retrieveImageTask.cancelledBeforeDownloadStarting {
            completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.downloadCancelledBeforeStarting.rawValue, userInfo: nil), nil, nil)
            return nil
        }
        
        let timeout = self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
        
        // We need to set the URL as the load key. So before setup progress, we need to ask the `requestModifier` for a final URL.
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpShouldUsePipelining = requestsUsePipelining

        if let modifier = options?.modifier {
            guard let r = modifier.modified(for: request) else {
                completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.downloadCancelledBeforeStarting.rawValue, userInfo: nil), nil, nil)
                return nil
            }
            request = r
        }
        
        // There is a possiblility that request modifier changed the url to `nil` or empty.
        guard let url = request.url, !url.absoluteString.isEmpty else {
            completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.invalidURL.rawValue, userInfo: nil), nil, nil)
            return nil
        }
        
        var downloadTask: RetrieveImageDownloadTask?
        setup(progressBlock: progressBlock, with: completionHandler, for: url, options: options) {(session, fetchLoad) -> Void in
            if fetchLoad.downloadTask == nil {
                let dataTask = session.dataTask(with: request)
                
                fetchLoad.downloadTask = RetrieveImageDownloadTask(internalTask: dataTask, ownerDownloader: self)
                
                dataTask.priority = options?.downloadPriority ?? URLSessionTask.defaultPriority
                dataTask.resume()
                self.delegate?.imageDownloader(self, willDownloadImageForURL: url, with: request)
                
                // Hold self while the task is executing.
                self.sessionHandler.downloadHolder = self
            }
            
            fetchLoad.downloadTaskCount += 1
            downloadTask = fetchLoad.downloadTask
            
            retrieveImageTask?.downloadTask = downloadTask
        }
        return downloadTask
    }
    
}

// MARK: - Download method
extension ImageDownloader {
    
    // A single key may have multiple callbacks. Only download once.
    func setup(progressBlock: ImageDownloaderProgressBlock?, with completionHandler: ImageDownloaderCompletionHandler?, for url: URL, options: KingfisherOptionsInfo?, started: @escaping ((URLSession, ImageFetchLoad) -> Void)) {

        func prepareFetchLoad() {
            barrierQueue.sync(flags: .barrier) {
                let loadObjectForURL = fetchLoads[url] ?? ImageFetchLoad()
                let callbackPair = (progressBlock: progressBlock, completionHandler: completionHandler)
                
                loadObjectForURL.contents.append((callbackPair, options ?? KingfisherEmptyOptionsInfo))
                
                fetchLoads[url] = loadObjectForURL
                
                if let session = session {
                    started(session, loadObjectForURL)
                }
            }
        }
        
        if let fetchLoad = fetchLoad(for: url), fetchLoad.downloadTaskCount == 0 {
            if fetchLoad.cancelSemaphore == nil {
                fetchLoad.cancelSemaphore = DispatchSemaphore(value: 0)
            }
            cancelQueue.async {
                _ = fetchLoad.cancelSemaphore?.wait(timeout: .distantFuture)
                fetchLoad.cancelSemaphore = nil
                prepareFetchLoad()
            }
        } else {
            prepareFetchLoad()
        }
    }
    
    private func cancelTaskImpl(_ task: RetrieveImageDownloadTask, fetchLoad: ImageFetchLoad? = nil, ignoreTaskCount: Bool = false) {
        
        func getFetchLoad(from task: RetrieveImageDownloadTask) -> ImageFetchLoad? {
            guard let URL = task.internalTask.originalRequest?.url,
                  let imageFetchLoad = self.fetchLoads[URL] else
            {
                return nil
            }
            return imageFetchLoad
        }
        
        guard let imageFetchLoad = fetchLoad ?? getFetchLoad(from: task) else {
            return
        }

        imageFetchLoad.downloadTaskCount -= 1
        if ignoreTaskCount || imageFetchLoad.downloadTaskCount == 0 {
            task.internalTask.cancel()
        }
    }
    
    func cancel(_ task: RetrieveImageDownloadTask) {
        barrierQueue.sync(flags: .barrier) { cancelTaskImpl(task) }
    }
    
    /// Cancel all downloading tasks. It will trigger the completion handlers for all not-yet-finished
    /// downloading tasks with an NSURLErrorCancelled error.
    ///
    /// If you need to only cancel a certain task, call `cancel()` on the `RetrieveImageDownloadTask`
    /// returned by the downloading methods.
    public func cancelAll() {
        barrierQueue.sync(flags: .barrier) {
            fetchLoads.forEach { v in
                let fetchLoad = v.value
                guard let task = fetchLoad.downloadTask else { return }
                cancelTaskImpl(task, fetchLoad: fetchLoad, ignoreTaskCount: true)
            }
        }
    }
}

// MARK: - NSURLSessionDataDelegate

/// Delegate class for `NSURLSessionTaskDelegate`.
/// The session object will hold its delegate until it gets invalidated.
/// If we use `ImageDownloader` as the session delegate, it will not be released.
/// So we need an additional handler to break the retain cycle.
// See https://github.com/onevcat/Kingfisher/issues/235
final class ImageDownloaderSessionHandler: NSObject, URLSessionDataDelegate, AuthenticationChallengeResponsable {
    
    // The holder will keep downloader not released while a data task is being executed.
    // It will be set when the task started, and reset when the task finished.
    var downloadHolder: ImageDownloader?
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard let downloader = downloadHolder else {
            completionHandler(.cancel)
            return
        }
        
        if let statusCode = (response as? HTTPURLResponse)?.statusCode,
           let url = dataTask.originalRequest?.url,
            !(downloader.delegate ?? downloader).isValidStatusCode(statusCode, for: downloader)
        {
            let error = NSError(domain: KingfisherErrorDomain,
                                code: KingfisherError.invalidStatusCode.rawValue,
                                userInfo: [KingfisherErrorStatusCodeKey: statusCode, NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)])
            callCompletionHandlerFailure(error: error, url: url)
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        guard let downloader = downloadHolder else {
            return
        }

        if let url = dataTask.originalRequest?.url, let fetchLoad = downloader.fetchLoad(for: url) {
            fetchLoad.responseData.append(data)
            
            if let expectedLength = dataTask.response?.expectedContentLength {
                for content in fetchLoad.contents {
                    DispatchQueue.main.async {
                        content.callback.progressBlock?(Int64(fetchLoad.responseData.length), expectedLength)
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let url = task.originalRequest?.url else {
            return
        }
        
        guard error == nil else {
            callCompletionHandlerFailure(error: error!, url: url)
            return
        }
        
        processImage(for: task, url: url)
    }
    
    /**
    This method is exposed since the compiler requests. Do not call it.
    */
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let downloader = downloadHolder else {
            return
        }
        
        downloader.authenticationChallengeResponder?.downloader(downloader, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let downloader = downloadHolder else {
            return
        }
        
        downloader.authenticationChallengeResponder?.downloader(downloader, task: task, didReceive: challenge, completionHandler: completionHandler)
    }
    
    private func cleanFetchLoad(for url: URL) {
        guard let downloader = downloadHolder else {
            return
        }

        downloader.barrierQueue.sync(flags: .barrier) {
            downloader.fetchLoads.removeValue(forKey: url)
            if downloader.fetchLoads.isEmpty {
                downloadHolder = nil
            }
        }
    }
    
    private func callCompletionHandlerFailure(error: Error, url: URL) {
        guard let downloader = downloadHolder, let fetchLoad = downloader.fetchLoad(for: url) else {
            return
        }
        
        // We need to clean the fetch load first, before actually calling completion handler.
        cleanFetchLoad(for: url)
        
        var leftSignal: Int
        repeat {
            leftSignal = fetchLoad.cancelSemaphore?.signal() ?? 0
        } while leftSignal != 0
        
        for content in fetchLoad.contents {
            content.options.callbackDispatchQueue.safeAsync {
                content.callback.completionHandler?(nil, error as NSError, url, nil)
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
                return
            }
            
            self.cleanFetchLoad(for: url)
            
            let data: Data?
            let fetchedData = fetchLoad.responseData as Data
            
            if let delegate = downloader.delegate {
                data = delegate.imageDownloader(downloader, didDownload: fetchedData, for: url)
            } else {
                data = fetchedData
            }
            
            // Cache the processed images. So we do not need to re-process the image if using the same processor.
            // Key is the identifier of processor.
            var imageCache: [String: Image] = [:]
            for content in fetchLoad.contents {
                
                let options = content.options
                let completionHandler = content.callback.completionHandler
                let callbackQueue = options.callbackDispatchQueue
                
                let processor = options.processor
                var image = imageCache[processor.identifier]
                if let data = data, image == nil {
                    image = processor.process(item: .data(data), options: options)
                    // Add the processed image to cache. 
                    // If `image` is nil, nothing will happen (since the key is not existing before).
                    imageCache[processor.identifier] = image
                }
                
                if let image = image {

                    downloader.delegate?.imageDownloader(downloader, didDownload: image, for: url, with: task.response)

                    let imageModifier = options.imageModifier
                    let finalImage = imageModifier.modify(image)

                    if options.backgroundDecode {
                        let decodedImage = finalImage.kf.decoded
                        callbackQueue.safeAsync { completionHandler?(decodedImage, nil, url, data) }
                    } else {
                        callbackQueue.safeAsync { completionHandler?(finalImage, nil, url, data) }
                    }
                    
                } else {
                    if let res = task.response as? HTTPURLResponse , res.statusCode == 304 {
                        let notModified = NSError(domain: KingfisherErrorDomain, code: KingfisherError.notModified.rawValue, userInfo: nil)
                        completionHandler?(nil, notModified, url, nil)
                        continue
                    }
                    
                    let badData = NSError(domain: KingfisherErrorDomain, code: KingfisherError.badData.rawValue, userInfo: nil)
                    callbackQueue.safeAsync { completionHandler?(nil, badData, url, nil) }
                }
            }
        }
    }
}

// Placeholder. For retrieving extension methods of ImageDownloaderDelegate
extension ImageDownloader: ImageDownloaderDelegate {}

