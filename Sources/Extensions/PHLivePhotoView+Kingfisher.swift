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

public struct RetrieveLivePhotoResult: @unchecked Sendable {
    public let loadingInfo: LivePhotoLoadingInfoResult
    public let livePhoto: PHLivePhoto?
    
    // According to "Result Handler Info Dictionary Keys", we can trust the `info` in handler is sendable.
    // https://developer.apple.com/documentation/photokit/phlivephoto/result_handler_info_dictionary_keys
    public let info: [AnyHashable : Any]?
}

@MainActor private var taskIdentifierKey: Void?
@MainActor private var targetSizeKey: Void?
@MainActor private var contentModeKey: Void?

@MainActor
extension KingfisherWrapper where Base: PHLivePhotoView {
    
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
    
    public var targetSize: CGSize {
        get { getAssociatedObject(base, &targetSizeKey) ?? .zero }
        set { setRetainedAssociatedObject(base, &targetSizeKey, newValue) }
    }
    
    public var contentMode: PHImageContentMode {
        get { getAssociatedObject(base, &contentModeKey) ?? .default }
        set { setRetainedAssociatedObject(base, &contentModeKey, newValue) }
    }
    
    @discardableResult
    public func setImage(
        with source: LivePhotoSource?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: (@MainActor @Sendable (Result<RetrieveLivePhotoResult, KingfisherError>) -> Void)? = nil
    ) -> Task<(), Never>? {
        var mutatingSelf = self
        guard let source = source else {
            PHLivePhoto.request(
                withResourceFileURLs: [],
                placeholderImage: placeholder,
                targetSize: .zero,
                contentMode: .default
            ) { photo, _ in
                base.livePhoto = photo
            }
            mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(KingfisherError.imageSettingError(reason: .emptySource)))
            return nil
        }
        
        let issuedIdentifier = Source.Identifier.next()
        mutatingSelf.taskIdentifier = issuedIdentifier
        
        let taskIdentifierChecking = { issuedIdentifier == self.taskIdentifier }

        let task = Task { @MainActor in
            do {
                let loadingInfo = try await KingfisherManager.shared.retrieveLivePhoto(
                    with: source,
                    options: options,
                    progressBlock: progressBlock,
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
                    placeholderImage: placeholder,
                    targetSize: targetSize,
                    contentMode: contentMode,
                    resultHandler: {
                        livePhoto,
                        info in
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
                        
                        if info.keys.contains(PHLivePhotoInfoCancelledKey) {
                            let cancelled = (info[PHLivePhotoInfoCancelledKey] as? NSNumber)?.boolValue ?? false
                            if cancelled {
                                completionHandler?(.failure(
                                    .requestError(reason: .livePhotoTaskCancelled(source: source)))
                                )
                                return
                            }
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
