//
//  ImageDownloader.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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

typealias DownloadResult = Result<ImageLoadingResult, KingfisherError>

/// Represents a successful result of an image downloading process.
public struct ImageLoadingResult: Sendable {

    /// The downloaded image.
    public let image: KFCrossPlatformImage

    /// The original URL of the image request.
    public let url: URL?

    /// The raw data received from the downloader.
    public let originalData: Data

    /// Creates an `ImageDownloadResult` object.
    ///
    /// - Parameters:
    ///   - image: The image of the download result.
    ///   - url: The URL from which the image was downloaded.
    ///   - originalData: The binary data of the image.
    public init(image: KFCrossPlatformImage, url: URL? = nil, originalData: Data) {
        self.image = image
        self.url = url
        self.originalData = originalData
    }
}

/// Represents a task in the image downloading process.
///
/// When a download starts in Kingfisher, the involved methods always return you an instance of ``DownloadTask``. If you
/// need to cancel the task during the download process, you can keep a reference to the instance and call ``cancel()``
/// on it.
public final class DownloadTask: @unchecked Sendable {
    
    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.DownloadTaskPropertyQueue")
    
    init(sessionTask: SessionDataTask, cancelToken: SessionDataTask.CancelToken) {
        _sessionTask = sessionTask
        _cancelToken = cancelToken
    }
    
    init() { }

    private var _sessionTask: SessionDataTask? = nil
    
    /// The ``SessionDataTask`` object associated with this download task. Multiple `DownloadTask`s could refer to the
    /// same `sessionTask`. This is an optimization in Kingfisher to prevent multiple downloading tasks for the same
    /// URL resource simultaneously.
    ///
    /// When you call ``DownloadTask/cancel()``, this ``SessionDataTask`` and its cancellation token will be passed
    /// along. You can use them to identify the cancelled task.
    public private(set) var sessionTask: SessionDataTask? {
        get { propertyQueue.sync { _sessionTask! } }
        set { propertyQueue.sync { _sessionTask = newValue } }
    }

    private var _cancelToken: SessionDataTask.CancelToken? = nil
    
    /// The cancellation token used to cancel the task.
    ///
    /// This is solely for identifying the task when it is cancelled. To cancel a ``DownloadTask``, call
    ///  ``DownloadTask/cancelToken``.
    public private(set) var cancelToken: SessionDataTask.CancelToken? {
        get { propertyQueue.sync { _cancelToken } }
        set { propertyQueue.sync { _cancelToken = newValue } }
    }

    /// Cancel this single download task if it is running.
    ///
    /// This method will do nothing if this task is not running.
    ///
    /// In Kingfisher, there is an optimization to prevent starting another download task if the target URL is currently
    /// being downloaded. However, even when internally no new session task is created, a ``DownloadTask`` will still
    /// be created and returned when you call related methods. It will share the session downloading task with a
    /// previous task.
    ///
    /// In this case, if multiple ``DownloadTask``s share a single session download task, calling this method
    /// does not cancel the actual download process, since there are other `DownloadTask`s need it. It only removes
    /// `self` from the download list.
    ///
    /// > Tip: If you need to cancel all on-going ``DownloadTask``s of a certain URL, use
    /// ``ImageDownloader/cancel(url:)``. If you need to cancel all downloading tasks of an ``ImageDownloader``, 
    /// use ``ImageDownloader/cancelAll()``.
    public func cancel() {
        guard let sessionTask, let cancelToken else { return }
        sessionTask.cancel(token: cancelToken)
    }
    
    public var isInitialized: Bool {
        propertyQueue.sync {
            _sessionTask != nil && _cancelToken != nil
        }
    }
    
    func linkToTask(_ task: DownloadTask) {
        self.sessionTask = task.sessionTask
        self.cancelToken = task.cancelToken
    }
}

actor CancellationDownloadTask {
    var task: DownloadTask?
    func setTask(_ task: DownloadTask?) {
        self.task = task
    }
}

extension DownloadTask {
    enum WrappedTask {
        case download(DownloadTask)
        case dataProviding

        func cancel() {
            switch self {
            case .download(let task): task.cancel()
            case .dataProviding: break
            }
        }

        var value: DownloadTask? {
            switch self {
            case .download(let task): return task
            case .dataProviding: return nil
            }
        }
    }
}

/// Represents a download manager for requesting an image with a URL from the server.
open class ImageDownloader: @unchecked Sendable {

    // MARK: Singleton
    
    /// The default downloader.
    public static let `default` = ImageDownloader(name: "default")

    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloaderPropertyQueue")
    
    // MARK: Public Properties
    
    private var _downloadTimeout: TimeInterval = 15.0
    
    /// The duration before the download times out.
    ///
    /// If the download does not complete before this duration, the URL session will raise a timeout error, which 
    /// Kingfisher wraps and forwards as a ``KingfisherError/ResponseErrorReason/URLSessionError(error:)``.
    ///
    /// The default timeout is set to 15 seconds.
    open var downloadTimeout: TimeInterval {
        get { propertyQueue.sync { _downloadTimeout } }
        set { propertyQueue.sync { _downloadTimeout = newValue } }
    }
    
    /// A set of trusted hosts when receiving server trust challenges.
    ///
    /// A challenge with host name contained in this set will be ignored. You can use this set to specify the
    /// self-signed site. It only will be used if you don't specify the
    ///  ``ImageDownloader/authenticationChallengeResponder``.
    ///
    /// > If ``ImageDownloader/authenticationChallengeResponder`` is set, this property will be ignored and the
    /// implementation of ``ImageDownloader/authenticationChallengeResponder`` will be used instead.
    open var trustedHosts: Set<String>?
    
    /// Use this to supply a configuration for the downloader. 
    ///
    /// By default, `URLSessionConfiguration.ephemeral` will be used.
    ///
    /// You can modify the configuration before a downloading task begins. A configuration without persistent storage 
    /// for caches is necessary for the downloader to function correctly.
    ///
    /// > Setting a new session delegate to the downloader will invalidate the existing session and create a new one 
    /// > with the new value and the ``sessionDelegate``.
    open var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            session.invalidateAndCancel()
            session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        }
    }
    
    /// The session delegate which is used to handle the session related tasks.
    ///
    /// > Setting a new session delegate to the downloader will invalidate the existing session and create a new one 
    /// > with the new value and the ``sessionConfiguration``.
    open var sessionDelegate: SessionDelegate {
        didSet {
            session.invalidateAndCancel()
            session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
            setupSessionHandler()
        }
    }
    
    /// Whether the download requests should use pipeline or not. 
    ///
    /// It sets the `httpShouldUsePipelining` of the `URLRequest` for the download task. Default is false.
    open var requestsUsePipelining = false

    /// The delegate of this `ImageDownloader` object.
    ///
    /// See the ``ImageDownloaderDelegate`` protocol for more information.
    open weak var delegate: (any ImageDownloaderDelegate)?

    /// A responder for authentication challenges.
    ///
    /// The downloader forwards the received authentication challenge for the downloading session to this responder.
    /// See ``AuthenticationChallengeResponsible`` for more.
    open weak var authenticationChallengeResponder: (any AuthenticationChallengeResponsible)?

    // The downloader name.
    private let name: String
    
    // The session bound to the downloader.
    private var session: URLSession

    // MARK: Initializers

    /// Creates a downloader with a given name.
    ///
    /// - Parameter name: The name for the downloader. It should not be empty.
    public init(name: String) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the downloader. "
                + "A downloader with empty name is not permitted.")
        }

        self.name = name

        sessionDelegate = SessionDelegate()
        session = URLSession(
            configuration: sessionConfiguration,
            delegate: sessionDelegate,
            delegateQueue: nil)

        authenticationChallengeResponder = self
        setupSessionHandler()
    }

    deinit { session.invalidateAndCancel() }

    private func setupSessionHandler() {
        sessionDelegate.onReceiveSessionChallenge.delegate(on: self) { (self, invoke) in
            await (self.authenticationChallengeResponder ?? self).downloader(self, didReceive: invoke.1)
        }
        sessionDelegate.onReceiveSessionTaskChallenge.delegate(on: self) { (self, invoke) in
            await (self.authenticationChallengeResponder ?? self).downloader(self, task: invoke.1, didReceive: invoke.2)
        }
        sessionDelegate.onValidStatusCode.delegate(on: self) { (self, code) in
            (self.delegate ?? self).isValidStatusCode(code, for: self)
        }
        sessionDelegate.onResponseReceived.delegate(on: self) { (self, response) in
            await (self.delegate ?? self).imageDownloader(self, didReceive: response)
        }
        sessionDelegate.onDownloadingFinished.delegate(on: self) { (self, value) in
            let (url, result) = value
            do {
                let value = try result.get()
                self.delegate?.imageDownloader(self, didFinishDownloadingImageForURL: url, with: value, error: nil)
            } catch {
                self.delegate?.imageDownloader(self, didFinishDownloadingImageForURL: url, with: nil, error: error)
            }
        }
        sessionDelegate.onDidDownloadData.delegate(on: self) { (self, task) in
            (self.delegate ?? self).imageDownloader(self, didDownload: task.mutableData, with: task)
        }
    }

    // Wraps `completionHandler` to `onCompleted` respectively.
    private func createCompletionCallBack(_ completionHandler: ((DownloadResult) -> Void)?) -> Delegate<DownloadResult, Void>? {
        completionHandler.map { block -> Delegate<DownloadResult, Void> in
            let delegate =  Delegate<Result<ImageLoadingResult, KingfisherError>, Void>()
            delegate.delegate(on: self) { (self, callback) in
                block(callback)
            }
            return delegate
        }
    }

    private func createTaskCallback(
        _ completionHandler: ((DownloadResult) -> Void)?,
        options: KingfisherParsedOptionsInfo
    ) -> SessionDataTask.TaskCallback
    {
        SessionDataTask.TaskCallback(
            onCompleted: createCompletionCallBack(completionHandler),
            options: options
        )
    }

    private func createDownloadContext(
        with url: URL,
        options: KingfisherParsedOptionsInfo,
        done: @escaping (@Sendable (Result<DownloadingContext, KingfisherError>) -> Void)
    )
    {
        @Sendable func checkRequestAndDone(r: URLRequest) {
            // There is a possibility that request modifier changed the url to `nil` or empty.
            // In this case, throw an error.
            guard let url = r.url, !url.absoluteString.isEmpty else {
                done(.failure(KingfisherError.requestError(reason: .invalidURL(request: r))))
                return
            }
            done(.success(DownloadingContext(url: url, request: r, options: options)))
        }

        // Creates default request.
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: downloadTimeout)
        request.httpShouldUsePipelining = requestsUsePipelining
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) , options.lowDataModeSource != nil {
            request.allowsConstrainedNetworkAccess = false
        }
        
        guard let requestModifier = options.requestModifier else {
            checkRequestAndDone(r: request)
            return
        }
        
        // Modifies request before sending.
        // FIXME: A temporary solution for keep the sync `ImageDownloadRequestModifier` behavior as before.
        // We should be able to combine two cases once the full async support can be introduced to Kingfisher.
        if let m = requestModifier as? any ImageDownloadRequestModifier {
            guard let result = m.modified(for: request) else {
                done(.failure(KingfisherError.requestError(reason: .emptyRequest)))
                return
            }
            checkRequestAndDone(r: result)
        } else  {
            Task { [request] in
                guard let result = await requestModifier.modified(for: request) else {
                    done(.failure(KingfisherError.requestError(reason: .emptyRequest)))
                    return
                }
                checkRequestAndDone(r: result)
            }
        }
    }

    private func addDownloadTask(
        context: DownloadingContext,
        callback: SessionDataTask.TaskCallback
    ) -> DownloadTask
    {
        // Ready to start download. Add it to session task manager (`sessionHandler`)
        let downloadTask: DownloadTask
        if let existingTask = sessionDelegate.task(for: context.url) {
            downloadTask = sessionDelegate.append(existingTask, callback: callback)
        } else {
            let sessionDataTask = session.dataTask(with: context.request)
            sessionDataTask.priority = context.options.downloadPriority
            downloadTask = sessionDelegate.add(sessionDataTask, url: context.url, callback: callback)
        }
        return downloadTask
    }

    private func reportWillDownloadImage(url: URL, request: URLRequest) {
        delegate?.imageDownloader(self, willDownloadImageForURL: url, with: request)
    }

    private func reportDidDownloadImageData(result: Result<(Data, URLResponse?), KingfisherError>, url: URL) {
        var response: URLResponse?
        var err: (any Error)?
        do {
            response = try result.get().1
        } catch {
            err = error
        }
        self.delegate?.imageDownloader(
            self,
            didFinishDownloadingImageForURL: url,
            with: response,
            error: err
        )
    }

    private func reportDidProcessImage(
        result: Result<KFCrossPlatformImage, KingfisherError>, url: URL, response: URLResponse?
    )
    {
        if let image = try? result.get() {
            self.delegate?.imageDownloader(self, didDownload: image, for: url, with: response)
        }
    }

    private func startDownloadTask(
        context: DownloadingContext,
        callback: SessionDataTask.TaskCallback
    ) -> DownloadTask
    {
        let downloadTask = addDownloadTask(context: context, callback: callback)

        guard let sessionTask = downloadTask.sessionTask, !sessionTask.started else {
            return downloadTask
        }

        sessionTask.onTaskDone.delegate(on: self) { (self, done) in
            // Underlying downloading finishes.
            // result: Result<(Data, URLResponse?)>, callbacks: [TaskCallback]
            let (result, callbacks) = done

            // Before processing the downloaded data.
            self.reportDidDownloadImageData(result: result, url: context.url)

            switch result {
            // Download finished. Now process the data to an image.
            case .success(let (data, response)):
                let processor = ImageDataProcessor(
                    data: data, callbacks: callbacks, processingQueue: context.options.processingQueue
                )
                processor.onImageProcessed.delegate(on: self) { (self, done) in
                    // `onImageProcessed` will be called for `callbacks.count` times, with each
                    // `SessionDataTask.TaskCallback` as the input parameter.
                    // result: Result<Image>, callback: SessionDataTask.TaskCallback
                    let (result, callback) = done

                    self.reportDidProcessImage(result: result, url: context.url, response: response)

                    let imageResult = result.map { ImageLoadingResult(image: $0, url: context.url, originalData: data) }
                    let queue = callback.options.callbackQueue
                    queue.execute { callback.onCompleted?.call(imageResult) }
                }
                processor.process()

            case .failure(let error):
                callbacks.forEach { callback in
                    let queue = callback.options.callbackQueue
                    queue.execute { callback.onCompleted?.call(.failure(error)) }
                }
            }
        }

        reportWillDownloadImage(url: context.url, request: context.request)
        sessionTask.resume()
        return downloadTask
    }

    // MARK: Downloading Task
    /// Downloads an image with a URL and options.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - options: The options that can control download behavior. See ``KingfisherOptionsInfo``.
    ///   - completionHandler: Called when the download progress finishes. This block will be called in the queue 
    ///   defined in ``KingfisherOptionsInfoItem/callbackQueue(_:)`` in the `options` parameter.
    ///
    /// - Returns: A downloading task. You can call ``DownloadTask/cancelToken`` on it to stop the download task.
    @discardableResult
    open func downloadImage(
        with url: URL,
        options: KingfisherParsedOptionsInfo,
        completionHandler: (@Sendable (Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil) -> DownloadTask
    {
        let downloadTask = DownloadTask()
        createDownloadContext(with: url, options: options) { result in
            switch result {
            case .success(let context):
                // `downloadTask` will be set if the downloading started immediately. This is the case when no request
                // modifier or a sync modifier (`ImageDownloadRequestModifier`) is used. Otherwise, when an
                // `AsyncImageDownloadRequestModifier` is used the returned `downloadTask` of this method will be `nil`
                // and the actual "delayed" task is given in `AsyncImageDownloadRequestModifier.onDownloadTaskStarted`
                // callback.
                let actualDownloadTask = self.startDownloadTask(
                    context: context,
                    callback: self.createTaskCallback(completionHandler, options: options)
                )
                downloadTask.linkToTask(actualDownloadTask)
                if let modifier = options.requestModifier {
                    modifier.onDownloadTaskStarted?(downloadTask)
                }
            case .failure(let error):
                options.callbackQueue.execute {
                    completionHandler?(.failure(error))
                }
            }
        }

        return downloadTask
    }

    /// Downloads an image with a URL and options.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - options: The options that can control download behavior. See ``KingfisherOptionsInfo``.
    ///   - progressBlock: Called when the download progress is updated. This block will always be called on the main 
    ///   queue.
    ///   - completionHandler: Called when the download progress finishes. This block will be called in the queue 
    ///   defined in ``KingfisherOptionsInfoItem/callbackQueue(_:)`` in the `options` parameter.
    ///
    /// - Returns: A downloading task. You can call ``DownloadTask/cancelToken`` on it to stop the download task.
    @discardableResult
    open func downloadImage(
        with url: URL,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@Sendable (Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil) -> DownloadTask
    {
        var info = KingfisherParsedOptionsInfo(options)
        if let block = progressBlock {
            info.onDataReceived = (info.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }
        return downloadImage(
            with: url,
            options: info,
            completionHandler: completionHandler)
    }

    /// Downloads an image with a URL and options.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - options: The options that can control download behavior. See ``KingfisherOptionsInfo``.
    ///   - completionHandler: Called when the download progress finishes. This block will be called in the queue
    ///   defined in ``KingfisherOptionsInfoItem/callbackQueue(_:)`` in the `options` parameter.
    ///
    /// - Returns: A downloading task. You can call ``DownloadTask/cancelToken`` on it to stop the download task.
    @discardableResult
    open func downloadImage(
        with url: URL,
        options: KingfisherOptionsInfo? = nil,
        completionHandler: (@Sendable (Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil) -> DownloadTask
    {
        downloadImage(
            with: url,
            options: KingfisherParsedOptionsInfo(options),
            completionHandler: completionHandler
        )
    }
}

// Concurrency
extension ImageDownloader {
    /// Downloads an image with a URL and option.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options that can control download behavior. See ``KingfisherOptionsInfo``.
    /// - Returns: The image loading result.
    ///
    /// > To cancel the download task initialized by this method, cancel the `Task` where this method is running in.
    public func downloadImage(
        with url: URL,
        options: KingfisherParsedOptionsInfo
    ) async throws -> ImageLoadingResult {
        let task = CancellationDownloadTask()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let downloadTask = downloadImage(with: url, options: options) { result in
                    continuation.resume(with: result)
                }
                if Task.isCancelled {
                    downloadTask.cancel()
                } else {
                    Task {
                        await task.setTask(downloadTask)
                    }
                }
            }
        } onCancel: {
            Task {
                await task.task?.cancel()
            }
        }
    }
    
    /// Downloads an image with a URL and option.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options that can control download behavior. See ``KingfisherOptionsInfo``.
    ///   - progressBlock: Called when the download progress updated. This block will be always be called in main queue.
    /// - Returns: The image loading result.
    ///
    /// > To cancel the download task initialized by this method, cancel the `Task` where this method is running in.
    public func downloadImage(
        with url: URL,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil
    ) async throws -> ImageLoadingResult
    {
        var info = KingfisherParsedOptionsInfo(options)
        if let block = progressBlock {
            info.onDataReceived = (info.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }
        return try await downloadImage(with: url, options: info)
    }
    
    /// Downloads an image with a URL and option.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options that can control download behavior. See ``KingfisherOptionsInfo``.
    /// - Returns: The image loading result.
    ///
    /// > To cancel the download task initialized by this method, cancel the `Task` where this method is running in.
    public func downloadImage(
        with url: URL,
        options: KingfisherOptionsInfo? = nil
    ) async throws -> ImageLoadingResult
    {
        try await downloadImage(with: url, options: KingfisherParsedOptionsInfo(options))
    }
}

// MARK: Cancelling Task
extension ImageDownloader {

    /// Cancel all downloading tasks for this ``ImageDownloader``.
    ///
    /// It will trigger the completion handlers for all not-yet-finished downloading tasks with a cancellation error.
    ///
    /// If you need to only cancel a certain task, call ``DownloadTask/cancel()`` on the task returned by the
    /// downloading methods. If you need to cancel all ``DownloadTask``s of a certain URL, use
    /// ``ImageDownloader/cancel(url:)``.
    public func cancelAll() {
        sessionDelegate.cancelAll()
    }

    /// Cancel all downloading tasks for a given URL.
    ///
    /// It will trigger the completion handlers for all not-yet-finished downloading tasks for the URL with a
    /// cancellation error.
    ///
    /// - Parameter url: The URL for which you want to cancel downloading.
    public func cancel(url: URL) {
        sessionDelegate.cancel(url: url)
    }
}

// Use the default implementation from extension of `AuthenticationChallengeResponsible`.
extension ImageDownloader: AuthenticationChallengeResponsible {}

// Use the default implementation from extension of `ImageDownloaderDelegate`.
extension ImageDownloader: ImageDownloaderDelegate {}

extension ImageDownloader {
    struct DownloadingContext {
        let url: URL
        let request: URLRequest
        let options: KingfisherParsedOptionsInfo
    }
}
