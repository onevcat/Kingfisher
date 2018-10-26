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

public struct ImageDownloadResult {
    public let image: Image
    public let url: URL
    public let originalData: Data
}

public struct DownloadTask {
    let sessionTask: SessionDataTask
    let cancelToken: SessionDataTask.CancelToken

    public func cancel() {
        sessionTask.cancel(token: cancelToken)
    }
}

/// `ImageDownloader` represents a downloading manager for requesting the image with a URL from server.
open class ImageDownloader {

    /// The default downloader.
    public static let `default` = ImageDownloader(name: "default")

    // MARK: - Public property
    /// The duration before the download is timeout. Default is 15 seconds.
    open var downloadTimeout: TimeInterval = 15.0
    
    /// A set of trusted hosts when receiving server trust challenges. A challenge with host name contained in this
    /// set will be ignored. You can use this set to specify the self-signed site. It only will be used if you don't
    /// specify the `authenticationChallengeResponder`.
    ///
    /// If `authenticationChallengeResponder` is set, this property will be ignored and the implementation of
    /// `authenticationChallengeResponder` will be used instead.
    open var trustedHosts: Set<String>?
    
    /// Use this to set supply a configuration for the downloader. By default,
    /// NSURLSessionConfiguration.ephemeralSessionConfiguration() will be used.
    ///
    /// You could change the configuration before a downloading task starts.
    /// A configuration without persistent storage for caches is requested for downloader working correctly.
    open var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            session.invalidateAndCancel()
            session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: nil)
        }
    }
    
    /// Whether the download requests should use pipline or not. Default is false.
    open var requestsUsePipelining = false

    /// Delegate of this `ImageDownloader` object. See `ImageDownloaderDelegate` protocol for more.
    open weak var delegate: ImageDownloaderDelegate?
    
    /// A responder for authentication challenge. 
    /// Downloader will forward the received authentication challenge for the downloading session to this responder.
    open weak var authenticationChallengeResponder: AuthenticationChallengeResponsable?

    let processQueue: DispatchQueue
    private let sessionHandler: SessionDelegate
    private var session: URLSession

    /// Creates a downloader with name.
    ///
    /// - Parameter name: The name for the downloader. It should not be empty.
    public init(name: String) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the downloader. "
                + "A downloader with empty name is not permitted.")
        }
        
        processQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process.\(name)")
        sessionHandler = SessionDelegate()
        session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: nil)
        authenticationChallengeResponder = self
        setupSessionHandler()
    }

    deinit { session.invalidateAndCancel() }

    private func setupSessionHandler() {
        sessionHandler.onReceiveSessionChallenge.delegate(on: self) { (self, invoke) in
            self.authenticationChallengeResponder?.downloader(self, didReceive: invoke.1, completionHandler: invoke.2)
        }
        sessionHandler.onReceiveSessionTaskChallenge.delegate(on: self) { (self, invoke) in
            self.authenticationChallengeResponder?.downloader(
                self, task: invoke.1, didReceive: invoke.2, completionHandler: invoke.3)
        }
        sessionHandler.onValidStatusCode.delegate(on: self) { (self, code) in
            return (self.delegate ?? self).isValidStatusCode(code, for: self)
        }
        sessionHandler.onDownloadingFinished.delegate(on: self) { (self, value) in
            let (url, result) = value
            self.delegate?.imageDownloader(
                self, didFinishDownloadingImageForURL: url, with: result.value, error: result.error)
        }
        sessionHandler.onDidDownloadData.delegate(on: self) { (self, task) in
            guard let url = task.task.originalRequest?.url else {
                return task.mutableData
            }
            guard let delegate = self.delegate else {
                return task.mutableData
            }
            return delegate.imageDownloader(self, didDownload: task.mutableData, for: url)
        }
    }

    /// Download an image with a URL and option.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options could control download behavior. See `KingfisherOptionsInfo`.
    ///   - progressBlock: Called when the download progress updated.
    ///   - completionHandler: Called when the download progress finishes.
    /// - Returns: A downloading task. You could call `cancel` on it to stop the downloading process.
    @discardableResult
    open func downloadImage(with url: URL,
                            options: KingfisherOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                            completionHandler: ((Result<ImageDownloadResult>) -> Void)? = nil) -> DownloadTask?
    {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: downloadTimeout)
        request.httpShouldUsePipelining = requestsUsePipelining

        let options = options ?? .empty

        guard let r = options.modifier.modified(for: request) else {
            completionHandler?(.failure(KingfisherError.requestError(reason: .emptyRequest)))
            return nil
        }
        request = r
        
        // There is a possibility that request modifier changed the url to `nil` or empty.
        guard let url = request.url, !url.absoluteString.isEmpty else {
            completionHandler?(.failure(KingfisherError.requestError(reason: .invalidURL(request: request))))
            return nil
        }

        let onProgress = Delegate<(Int64, Int64), Void>()
        onProgress.delegate(on: self) { (_, progress) in
            let (downloaded, total) = progress
            progressBlock?(downloaded, total)
        }

        let onCompleted = Delegate<Result<ImageDownloadResult>, Void>()
        onCompleted.delegate(on: self) { (_, result) in
            completionHandler?(result)
        }

        let callback = SessionDataTask.TaskCallback(
            onProgress: onProgress, onCompleted: onCompleted, options: options)

        let downloadTask = sessionHandler.add(
            request, in: session,
            priority: options.downloadPriority,
            callback: callback)
        let task = downloadTask.sessionTask
        task.onTaskDone.delegate(on: self) { (self, done) in
            let (result, callbacks) = done
            self.delegate?.imageDownloader(
                self,
                didFinishDownloadingImageForURL: url,
                with: result.value?.1,
                error: result.error)

            switch result {
            case .success(let (data, response)):
                let prosessor = ImageDataProcessor(data: data, callbacks: callbacks)
                prosessor.onImageProcessed.delegate(on: self) { (self, result) in

                    let (result, callback) = result

                    if let image = result.value {
                        self.delegate?.imageDownloader(self, didDownload: image, for: url, with: response)
                    }

                    let imageResult = result.map { ImageDownloadResult(image: $0, url: url, originalData: data) }
                    let queue = callback.options.callbackQueue
                    queue.execute { callback.onCompleted?.call(imageResult) }
                }
                self.processQueue.async { prosessor.process() }

            case .failure(let error):
                callbacks.forEach { callback in
                    let queue = callback.options.callbackQueue
                    queue.execute { callback.onCompleted?.call(.failure(error)) }
                }
            }
        }

        if !task.started {
            delegate?.imageDownloader(self, willDownloadImageForURL: url, with: request)
            task.resume()
        }
        return downloadTask
    }
}

// MARK: - Download method
extension ImageDownloader {

    /// Cancel all downloading tasks. It will trigger the completion handlers for all not-yet-finished
    /// downloading tasks with an NSURLErrorCancelled error.
    ///
    /// If you need to only cancel a certain task, call `cancel()` on the `RetrieveImageDownloadTask`
    /// returned by the downloading methods.
    public func cancelAll() {
        sessionHandler.cancelAll()
    }
}

extension ImageDownloader: AuthenticationChallengeResponsable {}

// Placeholder. For retrieving extension methods of ImageDownloaderDelegate
extension ImageDownloader: ImageDownloaderDelegate {}

class SessionDelegate: NSObject {

    private var tasks: [URL: SessionDataTask] = [:]
    private let lock = NSLock()

    let onValidStatusCode = Delegate<Int, Bool>()
    let onDownloadingFinished = Delegate<(URL, Result<URLResponse>), Void>()
    let onDidDownloadData = Delegate<SessionDataTask, Data?>()

    let onReceiveSessionChallenge = Delegate<(
            URLSession,
            URLAuthenticationChallenge,
            (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ),
        Void>()

    let onReceiveSessionTaskChallenge = Delegate<(
            URLSession,
            URLSessionTask,
            URLAuthenticationChallenge,
            (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ),
        Void>()

    func add(
        _ requst: URLRequest,
        in session: URLSession,
        priority: Float,
        callback: SessionDataTask.TaskCallback) -> DownloadTask
    {

        lock.lock()
        defer { lock.unlock() }

        let url = requst.url!
        if let task = tasks[url] {
            let token = task.addCallback(callback)
            return DownloadTask(sessionTask: task, cancelToken: token)
        } else {
            let task = SessionDataTask(session: session, request: requst, priority: priority)
            task.onTaskCancelled.delegate(on: self) { [unowned task] (self, value) in
                let (token, callback) = value
                let error = KingfisherError.requestError(reason: .taskCancelled(task: task, token: token))
                task.onTaskDone.call((.failure(error), [callback]))
                if !task.containsCallbacks {
                    self.tasks[url] = nil
                }
            }
            let token = task.addCallback(callback)
            tasks[url] = task
            return DownloadTask(sessionTask: task, cancelToken: token)
        }
    }
    
    func remove(_ task: URLSessionTask) {
        guard let url = task.originalRequest?.url else {
            return
        }
        lock.lock()
        defer { lock.unlock() }
        tasks[url] = nil
    }
    
    func task(for task: URLSessionTask) -> SessionDataTask? {
        guard let url = task.originalRequest?.url else {
            return nil
        }
        guard let sessionTask = tasks[url] else {
            return nil
        }
        guard sessionTask.task.taskIdentifier == task.taskIdentifier else {
            return nil
        }
        return sessionTask
    }

    func cancelAll() {
        lock.lock()
        defer { lock.unlock() }
        for task in tasks.values {
            task.forceCancel()
        }
    }
}

extension SessionDelegate: URLSessionDataDelegate {

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        lock.lock()
        defer { lock.unlock() }

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = KingfisherError.responseError(reason: .invalidURLResponse(response: response))
            onCompleted(task: dataTask, result: .failure(error))
            completionHandler(.cancel)
            return
        }

        let httpStatusCode = httpResponse.statusCode
        guard onValidStatusCode.call(httpStatusCode) == true else {
            let error = KingfisherError.responseError(reason: .invalidHTTPStatusCode(response: httpResponse))
            onCompleted(task: dataTask, result: .failure(error))
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        defer { lock.unlock() }

        guard let task = self.task(for: dataTask) else {
            return
        }
        task.didReceiveData(data)

        if let expectedContentLength = dataTask.response?.expectedContentLength, expectedContentLength != -1 {
            DispatchQueue.main.async {
                task.callbacks.forEach { callback in
                    callback.onProgress?.call((Int64(task.mutableData.count), expectedContentLength))
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        defer { lock.unlock() }

        guard let sessionTask = self.task(for: task) else {
            return
        }

        if let url = task.originalRequest?.url {
            let result: Result<(URLResponse)>
            if let error = error {
                result = .failure(KingfisherError.responseError(reason: .URLSessionError(error: error)))
            } else if let response = task.response {
                result = .success(response)
            } else {
                result = .failure(KingfisherError.responseError(reason: .noURLResponse))
            }
            onDownloadingFinished.call((url, result))
        }

        let result: Result<(Data, URLResponse?)>
        if let error = error {
            result = .failure(KingfisherError.responseError(reason: .URLSessionError(error: error)))
        } else {
            if let data = onDidDownloadData.call(sessionTask), let finalData = data {
                result = .success((finalData, task.response))
            } else {
                result = .failure(KingfisherError.responseError(reason: .dataModifyingFailed(task: sessionTask)))
            }
        }
        onCompleted(task: task, result: result)
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        onReceiveSessionChallenge.call((session, challenge, completionHandler))
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        onReceiveSessionTaskChallenge.call((session, task, challenge, completionHandler))
    }

    private func onCompleted(task: URLSessionTask, result: Result<(Data, URLResponse?)>) {
        guard let sessionTask = self.task(for: task) else {
            return
        }
        onCompleted(sessionTask: sessionTask, result: result)
    }

    private func onCompleted(sessionTask: SessionDataTask, result: Result<(Data, URLResponse?)>) {
        guard let url = sessionTask.task.originalRequest?.url else {
            return
        }
        tasks[url] = nil
        sessionTask.onTaskDone.call((result, Array(sessionTask.callbacks)))
    }
}

public class SessionDataTask {

    public typealias CancelToken = Int

    struct TaskCallback {
        let onProgress: Delegate<(Int64, Int64), Void>?
        let onCompleted: Delegate<Result<ImageDownloadResult>, Void>?
        let options: KingfisherOptionsInfo
    }
    
    public private(set) var mutableData: Data
    public let task: URLSessionDataTask
    
    private var callbacksStore = [CancelToken: TaskCallback]()

    var callbacks: Dictionary<SessionDataTask.CancelToken, SessionDataTask.TaskCallback>.Values {
        return callbacksStore.values
    }

    var currentToken = 0

    private let lock = NSLock()

    let onTaskDone = Delegate<(Result<(Data, URLResponse?)>, [TaskCallback]), Void>()
    let onTaskCancelled = Delegate<(CancelToken, TaskCallback), Void>()

    var started = false
    var containsCallbacks: Bool {
        // We should be able to use `task.state != .running` to check it.
        // However, in some rare cases, cancelling the task does not change
        // task state to `.cancelling`, but still in `.running`. So we need
        // to check callbacks count to for sure that it is safe to remove the
        // task in delegate.
        return !callbacks.isEmpty
    }
    
    init(session: URLSession, request: URLRequest, priority: Float) {
        task = session.dataTask(with: request)
        task.priority = priority
        mutableData = Data()
    }

    func addCallback(_ callback: TaskCallback) -> CancelToken {
        lock.lock()
        defer { lock.unlock() }
        callbacksStore[currentToken] = callback
        defer { currentToken += 1 }
        return currentToken
    }

    func removeCallback(_ token: CancelToken) -> TaskCallback? {
        lock.lock()
        defer { lock.unlock() }
        if let callback = callbacksStore[token] {
            callbacksStore[token] = nil
            return callback
        }
        return nil
    }
    
    func resume() {
        started = true
        task.resume()
    }

    func cancel(token: CancelToken) {
        let result = removeCallback(token)
        if let callback = result {

            if callbacksStore.count == 0 {
                task.cancel()
            }

            onTaskCancelled.call((token, callback))
        }
    }

    func forceCancel() {
        for token in callbacksStore.keys {
            cancel(token: token)
        }
    }
    
    func didReceiveData(_ data: Data) {
        mutableData.append(data)
    }
}
