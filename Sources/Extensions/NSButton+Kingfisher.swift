//
//  NSButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Jie Zhang on 14/04/2016.
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


import AppKit

extension KingfisherClass where Base: NSButton {

    @discardableResult
    public func setImage(
        with source: Source?,
        placeholder: Image? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        guard let source = source else {
            base.image = placeholder
            taskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }

        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        if !options.keepCurrentImageWhileLoading {
            base.image = placeholder
        }

        taskIdentifier = source.identifier

        let task = KingfisherManager.shared.retrieveImage(
            with: source,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard source.identifier == self.taskIdentifier else { return }
                progressBlock?(receivedSize, totalSize)
        },
            completionHandler: { result in
                DispatchQueue.main.safeAsync {
                    guard source.identifier == self.taskIdentifier else {
                        let error = KingfisherError.imageSettingError(
                            reason: .notCurrentSource(result: result.value, error: result.error, source: source))
                        completionHandler?(.failure(error))
                        return
                    }

                    self.imageTask = nil

                    switch result {
                    case .success(let value):
                        self.base.image = value.image
                        completionHandler?(result)
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.image = image
                        }
                        completionHandler?(result)
                    }
                }
        })

        imageTask = task
        return task
    }

    /// Sets an image to the button with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `KingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with resource: Resource?,
        placeholder: Image? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        return setImage(
            with: resource.map { .network($0) },
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }
    
    /// Cancels the image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelImageDownloadTask() {
        imageTask?.cancel()
    }

    @discardableResult
    public func setAlternateImage(
        with source: Source?,
        placeholder: Image? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        guard let source = source else {
            base.alternateImage = placeholder
            alternateTaskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }

        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        if !options.keepCurrentImageWhileLoading {
            base.alternateImage = placeholder
        }

        alternateTaskIdentifier = source.identifier
        let task = KingfisherManager.shared.retrieveImage(
            with: source,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard self.alternateTaskIdentifier == source.identifier else { return }
                progressBlock?(receivedSize, totalSize)
            },
            completionHandler: { result in
                CallbackQueue.mainCurrentOrAsync.execute {
                    guard self.alternateTaskIdentifier == source.identifier else {
                        let error = KingfisherError.imageSettingError(
                            reason: .notCurrentSource(result: result.value, error: result.error, source: source))
                        completionHandler?(.failure(error))
                        return
                    }

                    self.alternateImageTask = nil

                    switch result {
                    case .success(let value):
                        self.base.alternateImage = value.image
                        completionHandler?(result)
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.alternateImage = image
                        }
                        completionHandler?(result)
                    }
                }
        })

        alternateImageTask = task
        return task
    }

    /// Sets an alternate image to the button with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `KingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setAlternateImage(
        with resource: Resource?,
        placeholder: Image? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        return setAlternateImage(
            with: resource.map { .network($0) },
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }
 
    /// Cancels the alternate image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelAlternateImageDownloadTask() {
        alternateImageTask?.cancel()
    }
}


// MARK: - Associated Object
private var taskIdentifierKey: Void?
private var imageTaskKey: Void?

private var alternateTaskIdentifierKey: Void?
private var alternateImageTaskKey: Void?

extension KingfisherClass where Base: NSButton {

    public private(set) var taskIdentifier: String? {
        get { return getAssociatedObject(base, &taskIdentifierKey) }
        set { setRetainedAssociatedObject(base, &taskIdentifierKey, newValue) }
    }
    
    private var imageTask: DownloadTask? {
        get { return getAssociatedObject(base, &imageTaskKey) }
        set { setRetainedAssociatedObject(base, &imageTaskKey, newValue)}
    }

    public private(set) var alternateTaskIdentifier: String? {
        get { return getAssociatedObject(base, &alternateTaskIdentifierKey) }
        set { setRetainedAssociatedObject(base, &alternateTaskIdentifierKey, newValue) }
    }

    private var alternateImageTask: DownloadTask? {
        get { return getAssociatedObject(base, &alternateImageTaskKey) }
        set { setRetainedAssociatedObject(base, &alternateImageTaskKey, newValue)}
    }
}

extension KingfisherClass where Base: NSButton {

    /// Gets the image URL binded to this button.
    @available(*, deprecated, message: "Use `taskIdentifier` instead.", renamed: "taskIdentifier")
    public private(set) var webURL: URL? {
        get { return taskIdentifier.flatMap { URL(string: $0) } }
        set { taskIdentifier = newValue?.absoluteString }
    }


    /// Gets the image URL binded to this button.
    @available(*, deprecated, message: "Use `alternateTaskIdentifier` instead.", renamed: "alternateTaskIdentifier")
    public private(set) var alternateWebURL: URL? {
        get { return alternateTaskIdentifier.flatMap { URL(string: $0) } }
        set { alternateTaskIdentifier = newValue?.absoluteString }
    }
}
