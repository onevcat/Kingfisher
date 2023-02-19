//
//  NSTextAttachment+Kingfisher.swift
//  Kingfisher
//
//  Created by Benjamin Briggs on 22/07/2019.
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

#if !os(watchOS)

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension KingfisherWrapper where Base: NSTextAttachment {

    // MARK: Setting Image

    /// Sets an image to the text attachment with a source.
    ///
    /// - Parameters:
    ///   - source: The `Source` object defines data information from network or a data provider.
    ///   - attributedView: The owner of the attributed string which this `NSTextAttachment` is added.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    ///
    /// Internally, this method will use `KingfisherManager` to get the requested source
    /// Since this method will perform UI changes, you must call it from the main thread.
    ///
    /// The retrieved image will be set to `NSTextAttachment.image` property. Because it is not an image view based
    /// rendering, options related to view, such as `.transition`, are not supported.
    ///
    /// Kingfisher will call `setNeedsDisplay` on the `attributedView` when the image task done. It gives the view a
    /// chance to render the attributed string again for displaying the downloaded image. For example, if you set an
    /// attributed with this `NSTextAttachment` to a `UILabel` object, pass it as the `attributedView` parameter.
    ///
    /// Here is a typical use case:
    ///
    /// ```swift
    /// let attributedText = NSMutableAttributedString(string: "Hello World")
    /// let textAttachment = NSTextAttachment()
    ///
    /// textAttachment.kf.setImage(
    ///     with: URL(string: "https://onevcat.com/assets/images/avatar.jpg")!,
    ///     attributedView: label,
    ///     options: [
    ///        .processor(
    ///            ResizingImageProcessor(referenceSize: .init(width: 30, height: 30))
    ///            |> RoundCornerImageProcessor(cornerRadius: 15))
    ///     ]
    /// )
    /// attributedText.replaceCharacters(in: NSRange(), with: NSAttributedString(attachment: textAttachment))
    /// label.attributedText = attributedText
    /// ```
    ///
    @discardableResult
    public func setImage(
        with source: Source?,
        attributedView: @autoclosure @escaping () -> KFCrossPlatformView,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        return setImage(
            with: source,
            attributedView: attributedView,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the text attachment with a source.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the resource.
    ///   - attributedView: The owner of the attributed string which this `NSTextAttachment` is added.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    ///
    /// Internally, this method will use `KingfisherManager` to get the requested source
    /// Since this method will perform UI changes, you must call it from the main thread.
    ///
    /// The retrieved image will be set to `NSTextAttachment.image` property. Because it is not an image view based
    /// rendering, options related to view, such as `.transition`, are not supported.
    ///
    /// Kingfisher will call `setNeedsDisplay` on the `attributedView` when the image task done. It gives the view a
    /// chance to render the attributed string again for displaying the downloaded image. For example, if you set an
    /// attributed with this `NSTextAttachment` to a `UILabel` object, pass it as the `attributedView` parameter.
    ///
    /// Here is a typical use case:
    ///
    /// ```swift
    /// let attributedText = NSMutableAttributedString(string: "Hello World")
    /// let textAttachment = NSTextAttachment()
    ///
    /// textAttachment.kf.setImage(
    ///     with: URL(string: "https://onevcat.com/assets/images/avatar.jpg")!,
    ///     attributedView: label,
    ///     options: [
    ///        .processor(
    ///            ResizingImageProcessor(referenceSize: .init(width: 30, height: 30))
    ///            |> RoundCornerImageProcessor(cornerRadius: 15))
    ///     ]
    /// )
    /// attributedText.replaceCharacters(in: NSRange(), with: NSAttributedString(attachment: textAttachment))
    /// label.attributedText = attributedText
    /// ```
    ///
    @discardableResult
    public func setImage(
        with resource: Resource?,
        attributedView: @autoclosure @escaping () -> KFCrossPlatformView,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? .empty))
        return setImage(
            with: resource.map { .network($0) },
            attributedView: attributedView,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    func setImage(
        with source: Source?,
        attributedView: @escaping () -> KFCrossPlatformView,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        var mutatingSelf = self
        guard let source = source else {
            base.image = placeholder
            mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }

        var options = parsedOptions
        if !options.keepCurrentImageWhileLoading {
            base.image = placeholder
        }

        let issuedIdentifier = Source.Identifier.next()
        mutatingSelf.taskIdentifier = issuedIdentifier

        if let block = progressBlock {
            options.onDataReceived = (options.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }

        let task = KingfisherManager.shared.retrieveImage(
            with: source,
            options: options,
            progressiveImageSetter: { self.base.image = $0 },
            referenceTaskIdentifierChecker: { issuedIdentifier == self.taskIdentifier },
            completionHandler: { result in
                CallbackQueue.mainCurrentOrAsync.execute {
                    guard issuedIdentifier == self.taskIdentifier else {
                        let reason: KingfisherError.ImageSettingErrorReason
                        do {
                            let value = try result.get()
                            reason = .notCurrentSourceTask(result: value, error: nil, source: source)
                        } catch {
                            reason = .notCurrentSourceTask(result: nil, error: error, source: source)
                        }
                        let error = KingfisherError.imageSettingError(reason: reason)
                        completionHandler?(.failure(error))
                        return
                    }

                    mutatingSelf.imageTask = nil
                    mutatingSelf.taskIdentifier = nil

                    switch result {
                    case .success(let value):
                        self.base.image = value.image
                        let view = attributedView()
                        #if canImport(UIKit)
                        view.setNeedsDisplay()
                        #else
                        view.setNeedsDisplay(view.bounds)
                        #endif
                    case .failure:
                        if let image = options.onFailureImage {
                            self.base.image = image
                        }
                    }
                    completionHandler?(result)
                }
        }
        )

        mutatingSelf.imageTask = task
        return task
    }

    // MARK: Cancelling Image

    /// Cancel the image download task bounded to the text attachment if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

private var taskIdentifierKey: Void?
private var imageTaskKey: Void?

// MARK: Properties
extension KingfisherWrapper where Base: NSTextAttachment {

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
}

#endif
