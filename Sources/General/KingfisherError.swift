//
//  KingfisherError.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/26.
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

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Never {}

/// Represents all the errors that can occur in the Kingfisher framework.
///
/// Kingfisher-related methods always throw a ``KingfisherError`` or invoke the callback with ``KingfisherError``
/// as its error type. To handle errors from Kingfisher, you switch over the error to get a reason catalog,
/// then switch over the reason to understand the error details.
///
public enum KingfisherError: Error {

    // MARK: Error Reason Types

    /// Represents the error reasons during the networking request phase.
    public enum RequestErrorReason: Sendable {
        
        /// The request is empty.
        ///
        /// Error Code: 1001
        case emptyRequest
        
        /// The URL of the request is invalid.
        ///
        /// - Parameter request: The request is intended to be sent, but its URL is invalid.
        ///
        /// Error Code: 1002
        case invalidURL(request: URLRequest)

        /// The downloading task is canceled by the user.
        ///
        /// - Parameters:
        ///   - task: The session data task which is canceled.
        ///   - token: The cancel token which is used for canceling the task.
        ///
        /// Error Code: 1003
        case taskCancelled(task: SessionDataTask, token: SessionDataTask.CancelToken)

        /// The live photo downloading task is canceled by the user.
        ///
        /// - Parameters:
        ///   - source: The live phot source.
        ///
        /// Error Code: 1004
        case livePhotoTaskCancelled(source: LivePhotoSource)
        
        case asyncTaskContextCancelled
    }
    
    /// Represents the error reason during networking response phase.
    public enum ResponseErrorReason: Sendable {
        
        /// The response is not a valid URL response.
        ///
        /// - Parameters:
        ///   - response: The received invalid URL response.
        ///               The response is expected to be an HTTP response, but it is not.
        ///
        /// Error Code: 2001
        case invalidURLResponse(response: URLResponse)
        
        /// The response contains an invalid HTTP status code.
        ///
        /// - Parameters:
        ///   - response: The received response.
        ///
        /// Error Code: 2002
        ///
        /// - Note: By default, status code 200..<400 is recognized as valid. You can override
        ///   this behavior by conforming to the `ImageDownloaderDelegate`.
        case invalidHTTPStatusCode(response: HTTPURLResponse)
        
        /// An error happens in the system URL session.
        ///
        /// - Parameters:
        ///   - error: The underlying URLSession error object.
        ///
        /// Error Code: 2003
        case URLSessionError(error: any Error)
        
        /// Data modifying fails on returning a valid data.
        ///
        /// - Parameters:
        ///   - task: The failed task.
        ///
        ///   Error Code: 2004
        case dataModifyingFailed(task: SessionDataTask)
        
        /// The task is done but no URL response found.
        ///
        /// - Parameters:
        ///   - task: The failed task.
        ///
        /// Error Code: 2005
        case noURLResponse(task: SessionDataTask)

        /// The task is cancelled by ``ImageDownloaderDelegate`` due to the `.cancel` response disposition is
        /// specified by the delegate method.
        ///
        /// - Parameters:
        ///   - task: The cancelled task.
        ///
        /// Error Code: 2006
        case cancelledByDelegate(response: URLResponse)
    }
    
    /// Represents the error reason during Kingfisher caching.
    public enum CacheErrorReason: @unchecked Sendable {
        
        /// Cannot create a file enumerator for a certain disk URL.
        ///
        /// - Parameters:
        ///   - url: The target disk URL from which the file enumerator should be created.
        ///
        /// Error Code: 3001
        case fileEnumeratorCreationFailed(url: URL)
        
        /// Cannot get correct file contents from a file enumerator.
        ///
        /// - Parameters:
        ///   - url: The target disk URL from which the content of a file enumerator should be obtained.
        ///
        /// Error Code: 3002
        case invalidFileEnumeratorContent(url: URL)
        
        /// The file at the target URL exists, but its URL resource is unavailable.
        ///
        /// - Parameters:
        ///   - error: The underlying error thrown by the file manager.
        ///   - key: The key used to retrieve the resource from cache.
        ///   - url: The disk URL where the target cached file exists.
        ///
        /// Error Code: 3003
        case invalidURLResource(error: any Error, key: String, url: URL)
        
        /// The file at the target URL exists, but the data cannot be loaded from it.
        ///
        /// - Parameters:
        ///   - url: The disk URL where the target cached file exists.
        ///   - error: The underlying error that describes why this error occurs.
        ///
        /// Error Code: 3004
        case cannotLoadDataFromDisk(url: URL, error: any Error)
        
        /// Cannot create a folder at a given path.
        ///
        /// - Parameters:
        ///   - path: The disk path where the directory creation operation fails.
        ///   - error: The underlying error that describes why this error occurs.
        ///
        /// Error Code: 3005
        case cannotCreateDirectory(path: String, error: any Error)
        
        /// The requested image does not exist in the cache.
        ///
        /// - Parameters:
        ///   - key: The key of the requested image in the cache.
        ///
        /// Error Code: 3006
        case imageNotExisting(key: String)
        
        /// Unable to convert an object to data for storage.
        ///
        /// - Parameters:
        ///   - object: The object that needs to be converted to data.
        ///
        /// Error Code: 3007
        case cannotConvertToData(object: Any, error: any Error)
        
        /// Unable to serialize an image to data for storage.
        ///
        /// - Parameters:
        ///   - image: The input image that needs to be serialized to cache.
        ///   - original: The original image data, if it exists.
        ///   - serializer: The ``CacheSerializer`` used for the image serialization.
        ///
        /// Error Code: 3008
        case cannotSerializeImage(image: KFCrossPlatformImage?, original: Data?, serializer: any CacheSerializer)

        /// Unable to create the cache file at a specified `fileURL` under a given `key`.
        ///
        /// - Parameters:
        ///   - fileURL: The URL where the cache file should be created.
        ///   - key: The cache key used for the cache. When caching a file through ``KingfisherManager`` and Kingfisher's
        ///          extension method, it is the resolved cache key based on your input ``Source`` and the image
        ///          processors.
        ///   - data: The data to be cached.
        ///   - error: The underlying error originally thrown by Foundation when attempting to write the `data` to the disk file at
        ///            `fileURL`.
        ///
        /// Error Code: 3009
        case cannotCreateCacheFile(fileURL: URL, key: String, data: Data, error: any Error)

        /// Unable to set file attributes for a cached file.
        ///
        /// - Parameters:
        ///   - filePath: The path of the target cache file.
        ///   - attributes: The file attributes to be set for the target file.
        ///   - error: The underlying error originally thrown by the Foundation framework when attempting to set the specified
        ///            `attributes` for the disk file at `filePath`.
        ///
        /// Error Code: 3010
        case cannotSetCacheFileAttribute(filePath: String, attributes: [FileAttributeKey : Any], error: any Error)

        
        /// The disk storage for caching is not ready.
        ///
        /// - Parameters:
        ///   - cacheURL: The intended URL that should be the storage folder.
        ///
        /// This issue typically arises due to an extreme lack of space on the disk storage. Kingfisher fails to create 
        /// the cache folder under these circumstances, rendering the disk storage unusable. In such cases, it is
        /// recommended to prompt the user to free up storage space and restart the app to restore functionality.
        ///
        /// Error Code: 3011
        case diskStorageIsNotReady(cacheURL: URL)
        
        /// The resource is expected on the disk, but now missing for some reason.
        ///
        /// This happens when the expected resource is not on the disk for some reason during loading a live photo.
        ///
        /// Error Code: 3012
        case missingLivePhotoResourceOnDisk(_ resource: LivePhotoResource)
    }
    
    /// Represents the error reason during image processing phase.
    public enum ProcessorErrorReason: Sendable {
        /// Image processing has failed, and there is no valid output image generated by the processor.
        ///
        /// - Parameters:
        ///   - processor: The `ImageProcessor` responsible for processing the image or its data in `item`.
        ///   - item: The image or its data content.
        ///
        /// Error Code: 4001
        case processingFailed(processor: any ImageProcessor, item: ImageProcessItem)
    }

    /// Represents the error reason during image setting in a view related class.
    public enum ImageSettingErrorReason: Sendable {
        
        /// The input resource is empty or `nil`.
        ///
        /// Error Code: 5001
        case emptySource
        
        /// The resource task is completed, but it is not the one that was expected. This typically occurs when you set 
        /// another resource on the view without canceling the current ongoing task. The previous task will fail with the
        /// `.notCurrentSourceTask` error when a result is obtained, regardless of whether it was successful or not for
        /// that task.
        ///
        /// - Parameters:
        ///   - result: The `RetrieveImageResult` if the source task is completed without any issues. `nil` if an error occurred.
        ///   - error: The `Error` if there was a problem during the image setting task. `nil` if the task completed successfully.
        ///   - source: The original source value of the task.
        ///
        /// Error Code: 5002
        case notCurrentSourceTask(result: RetrieveImageResult?, error: (any Error)?, source: Source)

        /// An error occurs while retrieving data from an `ImageDataProvider`.
        ///
        /// - Parameters:
        ///   - provider: The ``ImageDataProvider`` that encountered the error.
        ///   - error: The underlying error that describes why this error occurred.
        ///
        /// Error Code: 5003
        case dataProviderError(provider: any ImageDataProvider, error: any Error)

        /// No more alternative ``Source`` can be used in current loading process. It means that the
        /// ``KingfisherOptionsInfoItem/alternativeSources(_:)`` are set and Kingfisher tried to recovery from the original error, but still
        /// fails for all the given alternative sources. The associated value holds all the errors encountered during
        /// the load process, including the original source loading error and all the alternative sources errors.
        /// Code 5004.
        
        /// No more alternative `Source` can be used in the current loading process. 
        ///
        /// - Parameters:
        ///   - error : A ``PropagationError`` contains more information about the source and error.
        ///
        /// This means that the ``KingfisherOptionsInfoItem/alternativeSources(_:)`` option is set, and Kingfisher attempted to recover from the original error,
        /// but still failed for all the provided alternative sources. The associated value holds all the errors encountered during
        /// the loading process, including the original source loading error and all the alternative sources errors.
        ///
        /// Error Code: 5004
        case alternativeSourcesExhausted([PropagationError])
        
        /// The resource task is completed, but it is not the one that was expected. This typically occurs when you set
        /// another resource on the view without canceling the current ongoing task. The previous task will fail with the
        /// `.notCurrentLivePhotoSourceTask` error when a result is obtained, regardless of whether it was successful or
        /// not for that task.
        ///
        /// This error is the live photo version of the `.notCurrentSourceTask` error (error 5002).
        ///
        /// - Parameters:
        ///   - result: The `RetrieveImageResult` if the source task is completed without any issues. `nil` if an error occurred.
        ///   - error: The `Error` if there was a problem during the image setting task. `nil` if the task completed successfully.
        ///   - source: The original source value of the task.
        ///
        /// Error Code: 5005
        case notCurrentLivePhotoSourceTask(
            result: RetrieveLivePhotoResult?, error: (any Error)?, source: LivePhotoSource
        )
        
        /// The error happens during processing the live photo.
        ///
        /// When creating the final `PHLivePhoto` object from the downloaded image files, the internal Photos framework
        /// method `PHLivePhoto.request(withResourceFileURLs:placeholderImage:targetSize:contentMode:resultHandler:)`
        /// invokes its `resultHandler`. If the `info` dictionary in `resultHandler` contains `PHLivePhotoInfoErrorKey`,
        /// Kingfisher raises this error reason to pass the information to outside.
        ///
        /// If the processing fails due to any error that is not a `KingfisherError` case, Kingfisher also reports it
        /// with this reason.
        ///
        /// - Parameters:
        ///   - result: The `RetrieveLivePhotoResult` if the source task is completed and a result is already existing.
        ///   - error: The `NSError` if `PHLivePhotoInfoErrorKey` is contained in the `resultHandler` info dictionary.
        ///   - source: The original source value of the task.
        ///
        /// - Note: It is possible that both `result` and `error` are non-nil value. Check the
        /// ``RetrieveLivePhotoResult/info`` property for the raw values that are from the Photos framework.
        ///
        /// Error Code: 5006
        case livePhotoResultError(result: RetrieveLivePhotoResult?, error: (any Error)?, source: LivePhotoSource)
    }

    // MARK: Member Cases
    
    /// Represents the error reasons that can occur during the networking request phase.
    case requestError(reason: RequestErrorReason)
    /// Represents the error reason that can occur during networking response phase.
    case responseError(reason: ResponseErrorReason)
    /// Represents the error reason that can occur during Kingfisher caching phase.
    case cacheError(reason: CacheErrorReason)
    /// Represents the error reason that can occur during image processing phase.
    case processorError(reason: ProcessorErrorReason)
    /// Represents the error reason that can occur during image setting in a view related class.
    case imageSettingError(reason: ImageSettingErrorReason)

    // MARK: Helper Properties & Methods

    /// A helper property to determine if this error is of type `RequestErrorReason.taskCancelled`.
    public var isTaskCancelled: Bool {
        if case .requestError(reason: .taskCancelled) = self {
            return true
        }
        return false
    }

    /// Helper method to check whether this error is a ``ResponseErrorReason/invalidHTTPStatusCode(response:)``
    /// and the associated value is a given status code.
    ///
    /// - Parameter code: The given status code.
    /// - Returns: If `self` is a `ResponseErrorReason.invalidHTTPStatusCode` error
    ///            and its status code equals to `code`, `true` is returned. Otherwise, `false`.
    ///
    
    
    /// A helper method for checking HTTP status code.
    ///
    /// Use this helper method to determine whether this error corresponds to a
    /// ``ResponseErrorReason/invalidHTTPStatusCode(response:)`` with a specific status code.
    ///
    /// - Parameter code: The desired HTTP status code for comparison.
    /// - Returns: `true` if the error is of type ``ResponseErrorReason/invalidHTTPStatusCode(response:)`` and its
    /// status code matches the provided `code`, otherwise `false`.
    public func isInvalidResponseStatusCode(_ code: Int) -> Bool {
        if case .responseError(reason: .invalidHTTPStatusCode(let response)) = self {
            return response.statusCode == code
        }
        return false
    }

    
    /// A helper method for checking the error is type of ``ResponseErrorReason/invalidHTTPStatusCode(response:)``.
    public var isInvalidResponseStatusCode: Bool {
        if case .responseError(reason: .invalidHTTPStatusCode) = self {
            return true
        }
        return false
    }

    /// A helper property that indicates whether this error is of type
    /// ``ImageSettingErrorReason/notCurrentSourceTask(result:error:source:)`` or not.
    ///
    /// This property is used to check if a new image setting task starts while the old one is still running.
    /// In such a scenario, the identifier of the new task will overwrite the identifier of the old task.
    ///
    /// When the old task finishes, a ``ImageSettingErrorReason/notCurrentSourceTask(result:error:source:)`` error will
    ///  be raised to notify you that the setting process has completed with a certain result, but the image view or 
    ///  button has not been updated.
    ///
    /// - Returns: `true` if the error is of type ``ImageSettingErrorReason/notCurrentSourceTask(result:error:source:)``,
    ///  `false` otherwise.
    public var isNotCurrentTask: Bool {
        if case .imageSettingError(reason: .notCurrentSourceTask(_, _, _)) = self {
            return true
        }
        return false
    }

    var isLowDataModeConstrained: Bool {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *),
           case .responseError(reason: .URLSessionError(let sessionError)) = self,
           let urlError = sessionError as? URLError,
           urlError.networkUnavailableReason == .constrained
        {
            return true
        }
        return false
    }

}

// MARK: - LocalizedError Conforming
extension KingfisherError: LocalizedError {
    
    /// Provides a localized message describing the error that occurred.
    ///
    /// Use this property to obtain a human-readable description of the error for display to the user.
    public var errorDescription: String? {
        switch self {
        case .requestError(let reason): return reason.errorDescription
        case .responseError(let reason): return reason.errorDescription
        case .cacheError(let reason): return reason.errorDescription
        case .processorError(let reason): return reason.errorDescription
        case .imageSettingError(let reason): return reason.errorDescription
        }
    }
}


// MARK: - CustomNSError Conforming
extension KingfisherError: CustomNSError {

    /// The error domain for ``KingfisherError``. All errors generated by Kingfisher are categorized under this domain.
    ///
    /// When handling errors from the Kingfisher library, you can use this domain to identify and distinguish them
    /// from other types of errors in your application.
    ///
    /// - Note: The error domain is a string identifier associated with each error.
    public static let domain = "com.onevcat.Kingfisher.Error"

    /// Represents the error code within the specified error domain.
    ///
    /// Use this property to retrieve the specific error code associated with a ``KingfisherError``. The error code
    /// provides additional context and information about the error, allowing you to handle and respond to different
    ///  error scenarios.
    ///
    /// - Note: Error codes are numerical values associated with each error within a domain. Check the error code in the
    /// API reference of each error reason for the detail.
    ///
    /// - Returns: The error code as an integer.
    public var errorCode: Int {
        switch self {
        case .requestError(let reason): return reason.errorCode
        case .responseError(let reason): return reason.errorCode
        case .cacheError(let reason): return reason.errorCode
        case .processorError(let reason): return reason.errorCode
        case .imageSettingError(let reason): return reason.errorCode
        }
    }
}

extension KingfisherError.RequestErrorReason {
    var errorDescription: String? {
        switch self {
        case .emptyRequest:
            return "The request is empty or `nil`."
        case .invalidURL(let request):
            return "The request contains an invalid or empty URL. Request: \(request)."
        case .taskCancelled(let task, let token):
            return "The session task was cancelled. Task: \(task), cancel token: \(token)."
        case .livePhotoTaskCancelled(let source):
            return "The live photo download task was cancelled. Source: \(source)"
        case .asyncTaskContextCancelled:
            return "The async task context was cancelled. This usually happens when the task is cancelled before it starts."
        }
    }
    
    var errorCode: Int {
        switch self {
        case .emptyRequest: return 1001
        case .invalidURL: return 1002
        case .taskCancelled: return 1003
        case .livePhotoTaskCancelled: return 1004
        case .asyncTaskContextCancelled: return 1005
        }
    }
}

extension KingfisherError.ResponseErrorReason {
    var errorDescription: String? {
        switch self {
        case .invalidURLResponse(let response):
            return "The URL response is invalid: \(response)"
        case .invalidHTTPStatusCode(let response):
            return "The HTTP status code in response is invalid. Code: \(response.statusCode), response: \(response)."
        case .URLSessionError(let error):
            return "A URL session error happened. The underlying error: \(error)"
        case .dataModifyingFailed(let task):
            return "The data modifying delegate returned `nil` for the downloaded data. Task: \(task)."
        case .noURLResponse(let task):
            return "No URL response received. Task: \(task)."
        case .cancelledByDelegate(let response):
            return "The downloading task is cancelled by the downloader delegate. Response: \(response)."

        }
    }
    
    var errorCode: Int {
        switch self {
        case .invalidURLResponse: return 2001
        case .invalidHTTPStatusCode: return 2002
        case .URLSessionError: return 2003
        case .dataModifyingFailed: return 2004
        case .noURLResponse: return 2005
        case .cancelledByDelegate: return 2006
        }
    }
}

extension KingfisherError.CacheErrorReason {
    var errorDescription: String? {
        switch self {
        case .fileEnumeratorCreationFailed(let url):
            return "Cannot create file enumerator for URL: \(url)."
        case .invalidFileEnumeratorContent(let url):
            return "Cannot get contents from the file enumerator at URL: \(url)."
        case .invalidURLResource(let error, let key, let url):
            return "Cannot get URL resource values or data for the given URL: \(url). " +
                   "Cache key: \(key). Underlying error: \(error)"
        case .cannotLoadDataFromDisk(let url, let error):
            return "Cannot load data from disk at URL: \(url). Underlying error: \(error)"
        case .cannotCreateDirectory(let path, let error):
            return "Cannot create directory at given path: Path: \(path). Underlying error: \(error)"
        case .imageNotExisting(let key):
            return "The image is not in cache, but you requires it should only be " +
                   "from cache by enabling the `.onlyFromCache` option. Key: \(key)."
        case .cannotConvertToData(let object, let error):
            return "Cannot convert the input object to a `Data` object when storing it to disk cache. " +
                   "Object: \(object). Underlying error: \(error)"
        case .cannotSerializeImage(let image, let originalData, let serializer):
            return "Cannot serialize an image due to the cache serializer returning `nil`. " +
                   "Image: \(String(describing:image)), original data: \(String(describing: originalData)), " +
                   "serializer: \(serializer)."
        case .cannotCreateCacheFile(let fileURL, let key, let data, let error):
            return "Cannot create cache file at url: \(fileURL), key: \(key), data length: \(data.count). " +
                   "Underlying foundation error: \(error)."
        case .cannotSetCacheFileAttribute(let filePath, let attributes, let error):
            return "Cannot set file attribute for the cache file at path: \(filePath), attributes: \(attributes)." +
                   "Underlying foundation error: \(error)."
        case .diskStorageIsNotReady(let cacheURL):
            return "The disk storage is not ready to use yet at URL: '\(cacheURL)'. " +
                "This is usually caused by extremely lack of disk space. Ask users to free up some space and restart the app."
        case .missingLivePhotoResourceOnDisk(let resource):
            return "The live photo resource '\(resource)' is missing in the cache. Usually a re-download" +
            " can fix this issue."
        }
    }
    
    var errorCode: Int {
        switch self {
        case .fileEnumeratorCreationFailed: return 3001
        case .invalidFileEnumeratorContent: return 3002
        case .invalidURLResource: return 3003
        case .cannotLoadDataFromDisk: return 3004
        case .cannotCreateDirectory: return 3005
        case .imageNotExisting: return 3006
        case .cannotConvertToData: return 3007
        case .cannotSerializeImage: return 3008
        case .cannotCreateCacheFile: return 3009
        case .cannotSetCacheFileAttribute: return 3010
        case .diskStorageIsNotReady: return 3011
        case .missingLivePhotoResourceOnDisk: return 3012
        }
    }
}

extension KingfisherError.ProcessorErrorReason {
    var errorDescription: String? {
        switch self {
        case .processingFailed(let processor, let item):
            return "Processing image failed. Processor: \(processor). Processing item: \(item)."
        }
    }
    
    var errorCode: Int {
        switch self {
        case .processingFailed: return 4001
        }
    }
}

extension KingfisherError.ImageSettingErrorReason {
    var errorDescription: String? {
        switch self {
        case .emptySource:
            return "The input resource is empty."
        case .notCurrentSourceTask(let result, let error, let resource):
            if let result = result {
                return "Retrieving resource succeeded, but this source is " +
                       "not the one currently expected. Result: \(result). Resource: \(resource)."
            } else if let error = error {
                return "Retrieving resource failed, and this resource is " +
                       "not the one currently expected. Error: \(error). Resource: \(resource)."
            } else {
                return nil
            }
        case .dataProviderError(let provider, let error):
            return "Image data provider fails to provide data. Provider: \(provider), error: \(error)"
        case .alternativeSourcesExhausted(let errors):
            return "Image setting from alternative sources failed: \(errors)"
        case .notCurrentLivePhotoSourceTask(let result, let error, let source):
            if let result = result {
                return "Retrieving live photo resource succeeded, but this source is " +
                "not the one currently expected. Result: \(result). Resource: \(source)."
            } else if let error = error {
                return "Retrieving live photo resource failed, and this resource is " +
                "not the one currently expected. Error: \(error). Resource: \(source)."
            } else {
                return nil
            }
        case .livePhotoResultError(let result, let error, let source):
            return "An error occurred while processing live photo. Source: \(source). " +
                   "Result: \(String(describing: result)). Error: \(String(describing: error))"
        }
    }
    
    var errorCode: Int {
        switch self {
        case .emptySource: return 5001
        case .notCurrentSourceTask: return 5002
        case .dataProviderError: return 5003
        case .alternativeSourcesExhausted: return 5004
        case .notCurrentLivePhotoSourceTask: return 5005
        case .livePhotoResultError: return 5006
        }
    }
}
