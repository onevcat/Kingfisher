//
//  KingfisherHasImageComponent+Kingfisher.swift
//  Kingfisher
//
//  Created by JH on 2023/12/5.
//
//  Copyright (c) 2023 Wei Wang <onevcat@gmail.com>
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

public protocol KingfisherImageSettable: KingfisherCompatible {
    @MainActor func setImage(
        _ image: KFCrossPlatformImage?,
        options: KingfisherParsedOptionsInfo
    )
    @MainActor func getImage() -> KFCrossPlatformImage?
}

public protocol KingfisherHasImageComponent: KingfisherImageSettable {
    @MainActor var image: KFCrossPlatformImage? { set get }
}

extension KingfisherHasImageComponent {
    @MainActor 
    public func setImage(_ image: KFCrossPlatformImage?, options: KingfisherParsedOptionsInfo) {
        self.image = image
    }
    
    @MainActor
    public func getImage() -> KFCrossPlatformImage? {
        image
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
@available(macOS 13.0, *)
extension NSComboButton: KingfisherHasImageComponent {}
@available(macOS 13.0, *)
extension NSColorWell: KingfisherHasImageComponent {}
extension NSTableViewRowAction: KingfisherHasImageComponent {}
extension NSMenuItem: KingfisherHasImageComponent {}
extension NSPathControlItem: KingfisherHasImageComponent {}
extension NSToolbarItem: KingfisherHasImageComponent {}
extension NSTabViewItem: KingfisherHasImageComponent {}
extension NSStatusItem: KingfisherHasImageComponent {}
extension NSCell: KingfisherHasImageComponent {}
#endif

#if canImport(UIKit) && !os(watchOS)
import UIKit
@available(iOS 13.0, tvOS 13.0, *)
extension UIAction: KingfisherHasImageComponent {}
@available(iOS 13.0, tvOS 13.0, *)
extension UICommand: KingfisherHasImageComponent {}
extension UIBarItem: KingfisherHasImageComponent {}
#endif

#if canImport(WatchKit)
import WatchKit
extension WKInterfaceImage: KingfisherHasImageComponent {
    @MainActor public var image: KFCrossPlatformImage? {
        get { nil }
        set { setImage(newValue) }
    }
}
#endif

#if canImport(TVUIKit)
import TVUIKit
extension TVMonogramView: KingfisherHasImageComponent {}
#endif

struct ImagePropertyAccessor<ImageType>: Sendable {
    let setImage: @Sendable @MainActor (ImageType?, KingfisherParsedOptionsInfo) -> Void
    let getImage: @Sendable @MainActor () -> ImageType?
}

struct TaskPropertyAccessor: Sendable {
    let setTaskIdentifier: @Sendable @MainActor (Source.Identifier.Value?) -> Void
    let getTaskIdentifier: @Sendable @MainActor () -> Source.Identifier.Value?
    let setTask: @Sendable @MainActor (DownloadTask?) -> Void
}

@MainActor
extension KingfisherWrapper where Base: KingfisherImageSettable {

    // MARK: Setting Image

    /// Sets an image to the image view with a ``Source``.
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
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```swift
    /// // Set image from a network source.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: .network(url))
    ///
    /// // Or set image from a data provider.
    /// let provider = LocalFileImageDataProvider(fileURL: fileURL)
    /// imageView.kf.setImage(with: .provider(provider))
    /// ```
    ///
    /// For both ``Source/network(_:)`` and ``Source/provider(_:)`` sources, there are corresponding view extension
    /// methods. So the code above is equivalent to:
    ///
    /// ```swift
    /// imageView.kf.setImage(with: url)
    /// imageView.kf.setImage(with: provider)
    /// ```
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

    /// Sets an image to the image view with a ``Source``.
    ///
    /// - Parameters:
    ///   - source: The ``Source`` object that defines data information from the network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```swift
    /// // Set image from a network source.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: .network(url))
    ///
    /// // Or set image from a data provider.
    /// let provider = LocalFileImageDataProvider(fileURL: fileURL)
    /// imageView.kf.setImage(with: .provider(provider))
    /// ```
    ///
    /// For both ``Source/network(_:)`` and ``Source/provider(_:)`` sources, there are corresponding view extension
    /// methods. So the code above is equivalent to:
    ///
    /// ```swift
    /// imageView.kf.setImage(with: url)
    /// imageView.kf.setImage(with: provider)
    /// ```
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
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        return setImage(
            with: source,
            placeholder: placeholder,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler
        )
    }
    
    /// Sets an image to the image view with a requested ``Resource``.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - progressBlock: Called when the image downloading progress is updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```swift
    /// // Set image from a URL resource.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: url)
    /// ```
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
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the image view with a requested ``Resource``.
    ///
    /// - Parameters:
    ///   - resource: The ``Resource`` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```swift
    /// // Set image from a URL resource.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: url)
    /// ```
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
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        return setImage(
            with: resource,
            placeholder: placeholder,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the image view with a ``ImageDataProvider``.
    ///
    /// - Parameters:
    ///   - provider: The ``ImageDataProvider`` object that defines data information from the data provider.
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
        with provider: (any ImageDataProvider)?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        return setImage(
            with: provider.map { .provider($0) },
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the image view with a ``ImageDataProvider``.
    ///
    /// - Parameters:
    ///   - provider: The ``ImageDataProvider`` object that defines data information from the data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `source`.
    ///   - options: A set of options to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - completionHandler: Called when the image retrieval and setting are finished.
    /// - Returns: A task that represents the image downloading.
    ///
    /// Internally, this method will use ``KingfisherManager`` to get the source. Since this method will perform UI
    ///  changes, it is your responsibility to call it from the main thread.
    ///
    /// > Both `progressBlock` and `completionHandler` will also be executed in the main thread.
    @discardableResult
    public func setImage(
        with provider: (any ImageDataProvider)?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        return setImage(
            with: provider,
            placeholder: placeholder,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler
        )
    }
    
    func setImage(
        with source: Source?,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask? {
        return setImage(
            with: source, 
            imageAccessor: ImagePropertyAccessor(
                setImage: { base.setImage($0, options: $1) },
                getImage: { base.getImage() }
            ),
            taskAccessor: TaskPropertyAccessor(
                setTaskIdentifier: {
                    var mutatingSelf = self
                    mutatingSelf.taskIdentifier = $0
                },
                getTaskIdentifier: { self.taskIdentifier },
                setTask: { task in
                    var mutatingSelf = self
                    mutatingSelf.imageTask = task
                }
            ),
            placeholder: placeholder,
            parsedOptions: parsedOptions,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }
}

@MainActor
extension KingfisherWrapper {
    func setImage(
        with source: Source?,
        imageAccessor: ImagePropertyAccessor<KFCrossPlatformImage>,
        taskAccessor: TaskPropertyAccessor,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: KingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) -> DownloadTask?
    {
        guard let source = source else {
            imageAccessor.setImage(placeholder, parsedOptions)
            taskAccessor.setTaskIdentifier(nil)
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }

        var options = parsedOptions

        // Always set placeholder while there is no image/placeholder yet.
#if os(watchOS)
        let usePlaceholderDuringLoading = !options.keepCurrentImageWhileLoading
#else
        let usePlaceholderDuringLoading = !options.keepCurrentImageWhileLoading || imageAccessor.getImage() == nil
#endif
        if usePlaceholderDuringLoading {
            imageAccessor.setImage(placeholder, options)
        }

        let issuedIdentifier = Source.Identifier.next()
        taskAccessor.setTaskIdentifier(issuedIdentifier)

        if let block = progressBlock {
            options.onDataReceived = (options.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }

        let task = KingfisherManager.shared.retrieveImage(
            with: source,
            options: options,
            downloadTaskUpdated: { task in
                Task { @MainActor in taskAccessor.setTask(task) }
            },
            progressiveImageSetter: { imageAccessor.setImage($0, options) },
            referenceTaskIdentifierChecker: { issuedIdentifier == taskAccessor.getTaskIdentifier() },
            completionHandler: { result in
                CallbackQueueMain.currentOrAsync {
                    guard issuedIdentifier == taskAccessor.getTaskIdentifier() else {
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

                    taskAccessor.setTask(nil)
                    taskAccessor.setTaskIdentifier(nil)

                    switch result {
                    case .success(let value):
                        imageAccessor.setImage(value.image, options)
                    case .failure:
                        if let image = options.onFailureImage {
                            imageAccessor.setImage(image, options)
                        }
                    }
                    completionHandler?(result)
                }
            }
        )
        taskAccessor.setTask(task)
        return task
    }
}

// MARK: - Associated Object
@MainActor private var taskIdentifierKey: Void?
@MainActor private var imageTaskKey: Void?

@MainActor
extension KingfisherWrapper where Base: KingfisherImageSettable {

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
    
    /// Cancels the image download task of the image view if it is running.
    ///
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}
