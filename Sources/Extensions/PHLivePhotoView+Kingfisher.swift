//
//  PHLivePhotoView+Kingfisher.swift
//  Kingfisher
//
//  Created by onevcat on 2024/10/04.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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

#if os(watchOS)
// Only a placeholder.
public struct RetrieveLivePhotoResult: @unchecked Sendable {
}
#else
@preconcurrency import PhotosUI

/// A result type that contains the information of a retrieved live photo.
///
/// This struct is used to encapsulate the result of a live photo retrieval operation, including the loading information,
/// the retrieved `PHLivePhoto` object, and any additional information provided by the result handler.
///
/// - Note: The `info` dictionary is considered sendable based on the documentation for "Result Handler Info Dictionary Keys".
///         See: [Result Handler Info Dictionary Keys](https://developer.apple.com/documentation/photokit/phlivephoto/result_handler_info_dictionary_keys)
public struct RetrieveLivePhotoResult: @unchecked Sendable {
    /// The loading information of the live photo.
    public let loadingInfo: LivePhotoLoadingInfoResult

    /// The retrieved live photo object which is given by the 
    /// `PHLivePhoto.request(withResourceFileURLs:placeholderImage:targetSize:contentMode:resultHandler:)` method from
    /// the result handler.
    public let livePhoto: PHLivePhoto?
    

    // According to "Result Handler Info Dictionary Keys", we can trust the `info` in handler is sendable.
    // https://developer.apple.com/documentation/photokit/phlivephoto/result_handler_info_dictionary_keys
    /// The additional information provided by the result handler when retrieving the live photo.
    public let info: [AnyHashable : Any]?
}

@MainActor private var taskIdentifierKey: Void?
@MainActor private var targetSizeKey: Void?
@MainActor private var contentModeKey: Void?

@MainActor
extension KingfisherWrapper where Base: PHLivePhotoView {
    /// Gets the task identifier associated with the image view for the live photo task.
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
    
    /// The target size of the live photo view. It is used in the 
    /// `PHLivePhoto.request(withResourceFileURLs:placeholderImage:targetSize:contentMode:resultHandler:)` method as 
    /// the `targetSize` argument when loading the live photo. 
    /// 
    /// If not set, `.zero` will be used.
    public var targetSize: CGSize {
        get { getAssociatedObject(base, &targetSizeKey) ?? .zero }
        set { setRetainedAssociatedObject(base, &targetSizeKey, newValue) }
    }
    
    /// The content mode of the live photo view. It is used in the
    /// `PHLivePhoto.request(withResourceFileURLs:placeholderImage:targetSize:contentMode:resultHandler:)` method as
    /// the `contentMode` argument when loading the live photo.
    /// 
    /// If not set, `.default` will be used.
    public var contentMode: PHImageContentMode {
        get { getAssociatedObject(base, &contentModeKey) ?? .default }
        set { setRetainedAssociatedObject(base, &contentModeKey, newValue) }
    }
    
    /// Sets a live photo to the view with an array of `URL`.
    ///
    /// - Parameters:
    ///   - urls: The `URL`s defining the live photo resource. It should contains two URLs, one for the still image and
    ///     one for the video.
    ///   - options: An options set to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - completionHandler: Called when the image setting process finishes.
    /// - Returns: A task represents the image downloading.
    ///            The return value will be `nil` if the image is set with a empty source.
    ///
    /// - Note: Not all options in ``KingfisherOptionsInfo`` are supported in this method, for example, the live photo
    /// does not support any custom processors. Different from the extension method for a normal image view on the
    /// platform, the `placeholder` and `progressBlock` are not supported yet, and will be implemented in the future.
    /// 
    /// - Note: To get refined control of the resources, use the ``setImage(with:options:completionHandler:)-1n4p2``
    /// method with a ``LivePhotoSource`` object.
    ///
    /// Example:
    /// 
    /// ```swift
    /// let urls = [
    ///   URL(string: "https://example.com/image.heic")!, // imageURL
    ///   URL(string: "https://example.com/video.mov")!   // videoURL
    /// ]
    /// let livePhotoView = PHLivePhotoView()
    /// livePhotoView.kf.setImage(with: urls) { result in
    ///   switch result {
    ///   case .success(let retrieveResult):
    ///     print("Live photo loaded: \(retrieveResult.livePhoto).")
    ///     print("Cache type: \(retrieveResult.loadingInfo.cacheType).")
    ///   case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    @discardableResult
    public func setImage(
        with urls: [URL],
        // placeholder: KFCrossPlatformImage? = nil, // Not supported yet
        options: KingfisherOptionsInfo? = nil,
        // progressBlock: DownloadProgressBlock? = nil, // Not supported yet
        completionHandler: (@MainActor @Sendable (Result<RetrieveLivePhotoResult, KingfisherError>) -> Void)? = nil
    ) -> Task<(), Never>? {
        setImage(
            with: LivePhotoSource(urls: urls),
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Sets a live photo to the view with a ``LivePhotoSource``.
    ///
    /// - Parameters:
    ///   - source: The ``LivePhotoSource`` object defining the live photo resource.
    ///   - options: An options set to define image setting behaviors. See ``KingfisherOptionsInfo`` for more.
    ///   - completionHandler: Called when the image setting process finishes.
    /// - Returns: A task represents the image downloading.
    ///            The return value will be `nil` if the image is set with a empty source.
    ///
    /// - Note: Not all options in ``KingfisherOptionsInfo`` are supported in this method, for example, the live photo
    /// does not support any custom processors. Different from the extension method for a normal image view on the
    /// platform, the `placeholder` and `progressBlock` are not supported yet, and will be implemented in the future.
    /// 
    /// Sample:
    /// ```swift
    /// let source = LivePhotoSource(urls: [
    ///   URL(string: "https://example.com/image.heic")!, // imageURL
    ///   URL(string: "https://example.com/video.mov")!   // videoURL
    /// ])
    /// let livePhotoView = PHLivePhotoView()
    /// livePhotoView.kf.setImage(with: source) { result in 
    ///   switch result {
    ///   case .success(let retrieveResult):
    ///     print("Live photo loaded: \(retrieveResult.livePhoto).")
    ///     print("Cache type: \(retrieveResult.loadingInfo.cacheType).")
    ///   case .failure(let error):
    ///     print("Error: \(error)")
    /// }
    /// ```
    @discardableResult
    public func setImage(
        with source: LivePhotoSource?,
        // placeholder: KFCrossPlatformImage? = nil, // Not supported yet
        options: KingfisherOptionsInfo? = nil,
        // progressBlock: DownloadProgressBlock? = nil, // Not supported yet
        completionHandler: (@MainActor @Sendable (Result<RetrieveLivePhotoResult, KingfisherError>) -> Void)? = nil
    ) -> Task<(), Never>? {
        var mutatingSelf = self

        // Empty source fails the loading early and clear the current task identifier.
        guard let source = source else {
            base.livePhoto = nil
            mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }
        
        let issuedIdentifier = Source.Identifier.next()
        mutatingSelf.taskIdentifier = issuedIdentifier
        
        let taskIdentifierChecking = { issuedIdentifier == self.taskIdentifier }

        // Copy these associated values to prevent issues from reentrance.
        let targetSize = targetSize
        let contentMode = contentMode
        
        let task = Task { @MainActor in
            do {
                let loadingInfo = try await KingfisherManager.shared.retrieveLivePhoto(
                    with: source,
                    options: options,
                    progressBlock: nil, // progressBlock, // Not supported yet
                    referenceTaskIdentifierChecker: taskIdentifierChecking
                )
                if let notCurrentTaskError = self.checkNotCurrentTask(
                    issuedIdentifier: issuedIdentifier,
                    result: .init(loadingInfo: loadingInfo, livePhoto: nil, info: nil),
                    error: nil,
                    source: source
                ) {
                    completionHandler?(.failure(notCurrentTaskError))
                    return
                }
                
                PHLivePhoto.request(
                    withResourceFileURLs: loadingInfo.fileURLs,
                    placeholderImage: nil,
                    targetSize: targetSize,
                    contentMode: contentMode,
                    resultHandler: { livePhoto, info in
                        let result = RetrieveLivePhotoResult(
                            loadingInfo: loadingInfo,
                            livePhoto: livePhoto,
                            info: info
                        )
                        
                        if let notCurrentTaskError = self.checkNotCurrentTask(
                            issuedIdentifier: issuedIdentifier,
                            result: result,
                            error: nil,
                            source: source
                        ) {
                            completionHandler?(.failure(notCurrentTaskError))
                            return
                        }
                        
                        base.livePhoto = livePhoto
                        
                        if let error = info[PHLivePhotoInfoErrorKey] as? NSError {
                            let failingReason: KingfisherError.ImageSettingErrorReason =
                                .livePhotoResultError(result: result, error: error, source: source)
                            completionHandler?(.failure(.imageSettingError(reason: failingReason)))
                            return
                        }
                        
                        // Since we are not returning the request ID, seems no way for user to cancel it if the 
                        // `request` method is called. However, we are sure the request method will always load the 
                        // image from disk, it should not be a problem. In case we still report the error in the 
                        // completion
                        if (info[PHLivePhotoInfoCancelledKey] as? NSNumber)?.boolValue ?? false {
                            completionHandler?(.failure(
                                .requestError(reason: .livePhotoTaskCancelled(source: source)))
                            )
                            return
                        }
                        
                        // If the PHLivePhotoInfoIsDegradedKey value in your result handler’s info dictionary is true,
                        // Photos will call your result handler again.
                        if (info[PHLivePhotoInfoIsDegradedKey] as? NSNumber)?.boolValue == true {
                            // This ensures `completionHandler` be only called once.
                            return
                        }
                        
                        completionHandler?(.success(result))
                    }
                )
            } catch {
                if let notCurrentTaskError = self.checkNotCurrentTask(
                    issuedIdentifier: issuedIdentifier,
                    result: nil,
                    error: error,
                    source: source
                ) {
                    completionHandler?(.failure(notCurrentTaskError))
                    return
                }
                
                if let kfError = error as? KingfisherError {
                    completionHandler?(.failure(kfError))
                } else if error is CancellationError {
                    completionHandler?(.failure(.requestError(reason: .livePhotoTaskCancelled(source: source))))
                } else {
                    completionHandler?(.failure(.imageSettingError(
                        reason: .livePhotoResultError(result: nil, error: error, source: source)))
                    )
                }
            }
        }
        
        return task
    }
    
    private func checkNotCurrentTask(
        issuedIdentifier: Source.Identifier.Value,
        result: RetrieveLivePhotoResult?,
        error: (any Error)?,
        source: LivePhotoSource
    ) -> KingfisherError? {
        if issuedIdentifier == self.taskIdentifier {
            return nil
        }
        return .imageSettingError(reason: .notCurrentLivePhotoSourceTask(result: result, error: error, source: source))
    }
}
#endif
