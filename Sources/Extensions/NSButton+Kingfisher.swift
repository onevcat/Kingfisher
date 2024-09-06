//
//  NSButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Jie Zhang on 14/04/2016.
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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

@MainActor
extension KingfisherWrapper where Base: NSButton {

    // MARK: Setting Image

    /// Sets an image to the button with a ``Source``.
    ///
    /// - Parameters:
    ///   - source: The ``Source`` object that defines data information from the network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - progressBlock: Called when the image downloading progress is updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// Internally, this method will use ``KingfisherManager`` to get the source. Since this method will perform UI
    ///  changes, it is your responsibility to call it from the main thread.
    ///
    /// > Both `progressBlock` and `completionHandler` will also be executed in the main thread.
    @discardableResult
    public func setImage(
        with source: Source?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        return setImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the button with a ``Resource``.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object that defines data information from the network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - progressBlock: Called when the image downloading progress is updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// Internally, this method will use ``KingfisherManager`` to get the source. Since this method will perform UI
    ///  changes, it is your responsibility to call it from the main thread.
    ///
    /// > Both `progressBlock` and `completionHandler` will also be executed in the main thread.
    @discardableResult
    public func setImage(
        with resource: (any Resource)?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        return setImage(
            with: resource?.convertToSource(),
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    func setImage(
        with source: Source?,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        var mutatingSelf = self
        return setImage(
            with: source,
            imageAccessor: ImagePropertyAccessor(
                setImage: { image, _ in
                    base.image = image
                }, getImage: {
                    base.image
                }),
            taskAccessor: TaskPropertyAccessor(
                setTaskIdentifier: { mutatingSelf.taskIdentifier = $0 },
                getTaskIdentifier: { mutatingSelf.taskIdentifier }, 
                setTask: { mutatingSelf.imageTask = $0 }),
            placeholder: placeholder,
            parsedOptions: parsedOptions,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    // MARK: Cancelling Downloading Task

    /// Cancels the image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelImageDownloadTask() {
        imageTask?.cancel()
    }

    // MARK: Setting Alternate Image

    @discardableResult
    public func setAlternateImage(
        with source: Source?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        return setAlternateImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an alternate image to the button with a ``Resource``.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object that defines data information from the network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - progressBlock: Called when the image downloading progress is updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// Internally, this method will use ``KingfisherManager`` to get the source. Since this method will perform UI
    ///  changes, it is your responsibility to call it from the main thread.
    ///
    /// > Both `progressBlock` and `completionHandler` will also be executed in the main thread.
    @discardableResult
    public func setAlternateImage(
        with resource: (any Resource)?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        return setAlternateImage(
            with: resource?.convertToSource(),
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    func setAlternateImage(
        with source: Source?,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        var mutatingSelf = self
        return setImage(
            with: source,
            imageAccessor: ImagePropertyAccessor(
                setImage: { image, _ in
                    base.alternateImage = image
                }, getImage: {
                    base.alternateImage
                }),
            taskAccessor: TaskPropertyAccessor(
                setTaskIdentifier: { mutatingSelf.alternateTaskIdentifier = $0 },
                getTaskIdentifier: { mutatingSelf.alternateTaskIdentifier },
                setTask: { mutatingSelf.alternateImageTask = $0 }
            ),
            placeholder: placeholder,
            parsedOptions: parsedOptions,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    // MARK: Cancelling Alternate Image Downloading Task

    /// Cancels the image download task of the image view if it is running.
    ///
    /// Nothing will happen if the downloading has already finished.
    public func cancelAlternateImageDownloadTask() {
        alternateImageTask?.cancel()
    }
}


// MARK: - Associated Object
@MainActor private var taskIdentifierKey: Void?
@MainActor private var imageTaskKey: Void?

@MainActor private var alternateTaskIdentifierKey: Void?
@MainActor private var alternateImageTaskKey: Void?

@MainActor
extension KingfisherWrapper where Base: NSButton {

    // MARK: Properties
    
    public private(set) var taskIdentifier: Source.Identifier.Value? {
        get {
            let box: Box<Source.Identifier.Value>? = getAssociatedObject(base, &taskIdentifierKey)
            return box?.value
        }
        set {
            let box = newValue.map { Box($0) }
            setRetainedAssociatedObject(base, &taskIdentifierKey, box)
        }
    }
    
    private var imageTask: DownloadTask? {
        get { return getAssociatedObject(base, &imageTaskKey) }
        set { setRetainedAssociatedObject(base, &imageTaskKey, newValue)}
    }

    public private(set) var alternateTaskIdentifier: Source.Identifier.Value? {
        get {
            let box: Box<Source.Identifier.Value>? = getAssociatedObject(base, &alternateTaskIdentifierKey)
            return box?.value
        }
        set {
            let box = newValue.map { Box($0) }
            setRetainedAssociatedObject(base, &alternateTaskIdentifierKey, box)
        }
    }

    private var alternateImageTask: DownloadTask? {
        get { return getAssociatedObject(base, &alternateImageTaskKey) }
        set { setRetainedAssociatedObject(base, &alternateImageTaskKey, newValue)}
    }
}
#endif
