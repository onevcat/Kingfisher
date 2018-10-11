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
            fatalError("[Kingfisher] You should specify a name for the downloader. A downloader with empty name is not permitted.")
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
                            completionHandler: ((Result<ImageDownloadResult>) -> Void)? = nil) -> SessionDataTask?
    {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: downloadTimeout)
        request.httpShouldUsePipelining = requestsUsePipelining

        let options = options ?? .empty

        guard let r = options.modifier.modified(for: request) else {
            completionHandler?(.failure(KingfisherPlaceholderError()))
            return nil
        }
        request = r
        
        // There is a possibility that request modifier changed the url to `nil` or empty.
        guard let url = request.url, !url.absoluteString.isEmpty else {
            completionHandler?(.failure(KingfisherPlaceholderError()))
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

        let task = sessionHandler.add(request, in: session, callback: callback)

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
                    let queue = callback.options.callbackDispatchQueue
                    queue.async { callback.onCompleted?.call(imageResult) }
                }
                self.processQueue.async { prosessor.process() }

            case .failure(let error):
                callbacks.forEach { callback in
                    let queue = callback.options.callbackDispatchQueue
                    queue.async { callback.onCompleted?.call(.failure(error)) }
                }
            }
        }

        if !task.downloadStarted {
            delegate?.imageDownloader(self, willDownloadImageForURL: url, with: request)
            task.resume()
        }
        task.increseDownloadCount()
        return task
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
    let onDownloadingFinished = Delegate<Result<(URL, URLResponse)>, Void>()
    let onDidDownloadData = Delegate<Data, Data>()

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
        callback: SessionDataTask.TaskCallback) -> SessionDataTask
    {

        lock.lock()
        defer { lock.unlock() }

        let url = requst.url!
        if let task = tasks[url] {
            task.callbacks.append(callback)
            return task
        } else {
            let task = SessionDataTask(session: session, request: requst)
            task.onTaskCancelled.delegate(on: self) { [unowned task] (self, _) in
                self.onCompleted(sessionTask: task, result: .failure(KingfisherPlaceholderError()))
            }
            task.callbacks.append(callback)
            tasks[url] = task
            return task
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
        return tasks[url]
    }

    func cancelAll() {
        lock.lock()
        defer { lock.unlock() }
        for task in tasks.values {
            task.cancel(force: true)
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

        guard let response = response as? HTTPURLResponse else {
            onCompleted(task: dataTask, result: .failure(KingfisherPlaceholderError()))
            completionHandler(.cancel)
            return
        }

        let httpStatusCode = response.statusCode
        guard onValidStatusCode.call(httpStatusCode) == true else {
            onCompleted(task: dataTask, result: .failure(KingfisherPlaceholderError()))
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

        let result: Result<(Data, URLResponse?)>
        if let error = error {
            result = .failure(error)
        } else {
            let finalData = onDidDownloadData.call(sessionTask.mutableData) ?? sessionTask.mutableData
            result = .success((finalData, task.response))
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
        sessionTask.onTaskDone.call((result, sessionTask.callbacks))
    }
}

public class SessionDataTask {
    
    struct TaskCallback {
        let onProgress: Delegate<(Int64, Int64), Void>?
        let onCompleted: Delegate<Result<ImageDownloadResult>, Void>?
        let options: KingfisherOptionsInfo
    }
    
    var mutableData: Data
    let task: URLSessionDataTask

    var callbacks = [TaskCallback]()

    let onTaskDone = Delegate<(Result<(Data, URLResponse?)>, [TaskCallback]), Void>()
    let onTaskCancelled = Delegate<(), Void>()

    var downloadStarted: Bool { return downloadTaskCount > 0 }
    private var downloadTaskCount = 0
    
    init(session: URLSession, request: URLRequest) {
        task = session.dataTask(with: request)
        mutableData = Data()
    }
    
    func resume() {
        task.resume()
    }

    func increseDownloadCount() {
        downloadTaskCount += 1
    }
    
    func cancel(force: Bool = false) {
        if force {
            task.cancel()
        } else {
            downloadTaskCount -= 1
            if downloadTaskCount == 0 {
                task.cancel()
                onTaskCancelled.call()
            }
        }
    }
    
    func didReceiveData(_ data: Data) {
        mutableData.append(data)
    }
}
