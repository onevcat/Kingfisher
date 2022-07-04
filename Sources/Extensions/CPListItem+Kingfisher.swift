
//
//  CPListItem+Kingfisher.swift
//  Kingfisher
//
//  Created by Wayne Hartman on 2021-08-29.
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

#if canImport(CarPlay) && !targetEnvironment(macCatalyst)
import CarPlay

@available(iOS 14.0, *)
extension KingfisherWrapper where Base: CPListItem {
    
    // MARK: Setting Image
    
    /// Sets an image to the image view with a source.
    ///
    /// - Parameters:
    ///   - source: The `Source` object contains information about the image.
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
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with source: Source?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        let options = KingfisherParsedOptionsInfo(KingfisherManager.shared.defaultOptions + (options ?? []))
        return setImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }
    
    /// Sets an image to the image view with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `Resource` object contains information about the image.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    ///
    /// Internally, this method will use `KingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with resource: Resource?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
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
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask?
    {
        var mutatingSelf = self
        guard let source = source else {
            /**
             * In iOS SDK 14.0-14.4 the image param was non-`nil`. The SDK changed in 14.5
             * to allow `nil`. The compiler version 5.4 was introduced in this same SDK,
             * which allows >=14.5 SDK to set a `nil` image. This compile check allows
             * newer SDK users to set the image to `nil`, while still allowing older SDK
             * users to compile the framework.
             */
            #if compiler(>=5.4)
            self.base.setImage(placeholder)
            #else
            if let placeholder = placeholder {
                self.base.setImage(placeholder)
            }
            #endif

            mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }
        
        var options = parsedOptions
        if !options.keepCurrentImageWhileLoading {
            /**
             * In iOS SDK 14.0-14.4 the image param was non-`nil`. The SDK changed in 14.5
             * to allow `nil`. The compiler version 5.4 was introduced in this same SDK,
             * which allows >=14.5 SDK to set a `nil` image. This compile check allows
             * newer SDK users to set the image to `nil`, while still allowing older SDK
             * users to compile the framework.
             */
            #if compiler(>=5.4)
            self.base.setImage(placeholder)
            #else // Let older SDK users deal with the older behavior.
            if let placeholder = placeholder {
                self.base.setImage(placeholder)
            }
            #endif
        }
        
        let issuedIdentifier = Source.Identifier.next()
        mutatingSelf.taskIdentifier = issuedIdentifier
        
        if let block = progressBlock {
            options.onDataReceived = (options.onDataReceived ?? []) + [ImageLoadingProgressSideEffect(block)]
        }
        
        let task = KingfisherManager.shared.retrieveImage(
            with: source,
            options: options,
            downloadTaskUpdated: { mutatingSelf.imageTask = $0 },
            progressiveImageSetter: { self.base.setImage($0) },
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
                            self.base.setImage(value.image)
                            completionHandler?(result)
                            
                        case .failure:
                            if let image = options.onFailureImage {
                                /**
                                 * In iOS SDK 14.0-14.4 the image param was non-`nil`. The SDK changed in 14.5
                                 * to allow `nil`. The compiler version 5.4 was introduced in this same SDK,
                                 * which allows >=14.5 SDK to set a `nil` image. This compile check allows
                                 * newer SDK users to set the image to `nil`, while still allowing older SDK
                                 * users to compile the framework.
                                 */
                                #if compiler(>=5.4)
                                self.base.setImage(image)
                                #else // Let older SDK users deal with the older behavior.
                                if let unwrapped = image {
                                    self.base.setImage(unwrapped)
                                }
                                #endif
                                
                            } else {
                                #if compiler(>=5.4)
                                self.base.setImage(nil)
                                #endif
                            }
                            completionHandler?(result)
                    }
                }
            }
        )
        
        mutatingSelf.imageTask = task
        return task
    }
    
    // MARK: Cancelling Image
    
    /// Cancel the image download task bounded to the image view if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

private var taskIdentifierKey: Void?
private var imageTaskKey: Void?

// MARK: Properties
extension KingfisherWrapper where Base: CPListItem {

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
