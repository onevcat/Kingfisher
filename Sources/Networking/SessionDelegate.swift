//
//  SessionDelegate.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/11/1.
//
//  Copyright (c) 2018年 Wei Wang <onevcat@gmail.com>
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

// Represents the delegate object of downloader session. It also behave like a task manager for downloading.
class SessionDelegate: NSObject {

    typealias SessionChallengeFunc = (
        URLSession,
        URLAuthenticationChallenge,
        (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )

    typealias SessionTaskChallengeFunc = (
        URLSession,
        URLSessionTask,
        URLAuthenticationChallenge,
        (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )

    private var tasks: [URL: SessionDataTask] = [:]
    private let lock = NSLock()

    let onValidStatusCode = Delegate<Int, Bool>()
    let onDownloadingFinished = Delegate<(URL, Result<URLResponse>), Void>()
    let onDidDownloadData = Delegate<SessionDataTask, Data?>()

    let onReceiveSessionChallenge = Delegate<SessionChallengeFunc, Void>()
    let onReceiveSessionTaskChallenge = Delegate<SessionTaskChallengeFunc, Void>()

    func add(
        _ dataTask: URLSessionDataTask,
        url: URL,
        callback: SessionDataTask.TaskCallback) -> DownloadTask
    {
        lock.lock()
        defer { lock.unlock() }

        if let task = tasks[url] {
            let token = task.addCallback(callback)
            return DownloadTask(sessionTask: task, cancelToken: token)
        } else {
            let task = SessionDataTask(task: dataTask)
            task.onTaskCancelled.delegate(on: self) { [unowned task] (self, value) in
                let (token, callback) = value

                let error = KingfisherError.requestError(reason: .taskCancelled(task: task, token: token))
                task.onTaskDone.call((.failure(error), [callback]))
                // No other callbacks waiting, we can clear the task now.
                if !task.containsCallbacks {
                    let dataTask = task.task
                    self.remove(dataTask, acquireLock: true)
                }
            }
            let token = task.addCallback(callback)
            tasks[url] = task
            return DownloadTask(sessionTask: task, cancelToken: token)
        }
    }

    func remove(_ task: URLSessionTask, acquireLock: Bool) {
        guard let url = task.originalRequest?.url else {
            return
        }
        if acquireLock {
            lock.lock()
            defer { lock.unlock() }
        }
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
        for task in tasks.values {
            task.forceCancel()
        }
    }

    func cancel(url: URL) {
        let task = tasks[url]
        task?.forceCancel()
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

        guard let sessionTask = self.task(for: task) else { return }

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
        // The lock should be already acquired in the session delege queue
        // by the caller `urlSession(_:task:didCompleteWithError:)`.
        remove(sessionTask.task, acquireLock: false)
        sessionTask.onTaskDone.call((result, Array(sessionTask.callbacks)))
    }
}
