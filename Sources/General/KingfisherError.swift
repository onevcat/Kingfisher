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

extension Never {}

/// Represents all the errors which can happen in Kingfisher framework.
/// Kingfisher related methods always throw a `KingfisherError` or invoke the callback with `KingfisherError`
/// as its error type. To handle errors from Kingfisher, you switch over the error to get a reason catalog,
/// then switch over the reason to know error detail.
public enum KingfisherError: Error {

    // MARK: Error Reason Types

    /// Represents the error reason during networking request phase.
    ///
    /// - emptyRequest: The request is empty. Code 1001.
    /// - invalidURL: The URL of request is invalid. Code 1002.
    /// - taskCancelled: The downloading task is cancelled by user. Code 1003.
    public enum RequestErrorReason {
        
        /// The request is empty. Code 1001.
        case emptyRequest
        
        /// The URL of request is invalid. Code 1002.
        /// - request: The request is tend to be sent but its URL is invalid.
        case invalidURL(request: URLRequest)
        
        /// The downloading task is cancelled by user. Code 1003.
        /// - task: The session data task which is cancelled.
        /// - token: The cancel token which is used for cancelling the task.
        case taskCancelled(task: SessionDataTask, token: SessionDataTask.CancelToken)
    }
    
    /// Represents the error reason during networking response phase.
    ///
    /// - invalidURLResponse: The response is not a valid URL response. Code 2001.
    /// - invalidHTTPStatusCode: The response contains an invalid HTTP status code. Code 2002.
    /// - URLSessionError: An error happens in the system URL session. Code 2003.
    /// - dataModifyingFailed: Data modifying fails on returning a valid data. Code 2004.
    /// - noURLResponse: The task is done but no URL response found. Code 2005.
    public enum ResponseErrorReason {
        
        /// The response is not a valid URL response. Code 2001.
        /// - response: The received invalid URL response.
        ///             The response is expected to be an HTTP response, but it is not.
        case invalidURLResponse(response: URLResponse)
        
        /// The response contains an invalid HTTP status code. Code 2002.
        /// - Note:
        ///   By default, status code 200..<400 is recognized as valid. You can override
        ///   this behavior by conforming to the `ImageDownloaderDelegate`.
        /// - response: The received response.
        case invalidHTTPStatusCode(response: HTTPURLResponse)
        
        /// An error happens in the system URL session. Code 2003.
        /// - error: The underlying URLSession error object.
        case URLSessionError(error: Error)
        
        /// Data modifying fails on returning a valid data. Code 2004.
        /// - task: The failed task.
        case dataModifyingFailed(task: SessionDataTask)
        
        /// The task is done but no URL response found. Code 2005.
        /// - task: The failed task.
        case noURLResponse(task: SessionDataTask)

        /// The task is cancelled by `ImageDownloaderDelegate` due to the `.cancel` response disposition is
        /// specified by the delegate method. Code 2006.
        case cancelledByDelegate(response: URLResponse)
    }
    
    /// Represents the error reason during Kingfisher caching system.
    ///
    /// - fileEnumeratorCreationFailed: Cannot create a file enumerator for a certain disk URL. Code 3001.
    /// - invalidFileEnumeratorContent: Cannot get correct file contents from a file enumerator. Code 3002.
    /// - invalidURLResource: The file at target URL exists, but its URL resource is unavailable. Code 3003.
    /// - cannotLoadDataFromDisk: The file at target URL exists, but the data cannot be loaded from it. Code 3004.
    /// - cannotCreateDirectory: Cannot create a folder at a given path. Code 3005.
    /// - imageNotExisting: The requested image does not exist in cache. Code 3006.
    /// - cannotConvertToData: Cannot convert an object to data for storing. Code 3007.
    /// - cannotSerializeImage: Cannot serialize an image to data for storing. Code 3008.
    /// - cannotCreateCacheFile: Cannot create the cache file at a certain fileURL under a key. Code 3009.
    /// - cannotSetCacheFileAttribute: Cannot set file attributes to a cached file. Code 3010.
    public enum CacheErrorReason {
        
        /// Cannot create a file enumerator for a certain disk URL. Code 3001.
        /// - url: The target disk URL from which the file enumerator should be created.
        case fileEnumeratorCreationFailed(url: URL)
        
        /// Cannot get correct file contents from a file enumerator. Code 3002.
        /// - url: The target disk URL from which the content of a file enumerator should be got.
        case invalidFileEnumeratorContent(url: URL)
        
        /// The file at target URL exists, but its URL resource is unavailable. Code 3003.
        /// - error: The underlying error thrown by file manager.
        /// - key: The key used to getting the resource from cache.
        /// - url: The disk URL where the target cached file exists.
        case invalidURLResource(error: Error, key: String, url: URL)
        
        /// The file at target URL exists, but the data cannot be loaded from it. Code 3004.
        /// - url: The disk URL where the target cached file exists.
        /// - error: The underlying error which describes why this error happens.
        case cannotLoadDataFromDisk(url: URL, error: Error)
        
        /// Cannot create a folder at a given path. Code 3005.
        /// - path: The disk path where the directory creating operation fails.
        /// - error: The underlying error which describes why this error happens.
        case cannotCreateDirectory(path: String, error: Error)
        
        /// The requested image does not exist in cache. Code 3006.
        /// - key: Key of the requested image in cache.
        case imageNotExisting(key: String)
        
        /// Cannot convert an object to data for storing. Code 3007.
        /// - object: The object which needs be convert to data.
        case cannotConvertToData(object: Any, error: Error)
        
        /// Cannot serialize an image to data for storing. Code 3008.
        /// - image: The input image needs to be serialized to cache.
        /// - original: The original image data, if exists.
        /// - serializer: The `CacheSerializer` used for the image serializing.
        case cannotSerializeImage(image: KFCrossPlatformImage?, original: Data?, serializer: CacheSerializer)

        /// Cannot create the cache file at a certain fileURL under a key. Code 3009.
        /// - fileURL: The url where the cache file should be created.
        /// - key: The cache key used for the cache. When caching a file through `KingfisherManager` and Kingfisher's
        ///        extension method, it is the resolved cache key based on your input `Source` and the image processors.
        /// - data: The data to be cached.
        /// - error: The underlying error originally thrown by Foundation when writing the `data` to the disk file at
        ///          `fileURL`.
        case cannotCreateCacheFile(fileURL: URL, key: String, data: Data, error: Error)

        /// Cannot set file attributes to a cached file. Code 3010.
        /// - filePath: The path of target cache file.
        /// - attributes: The file attribute to be set to the target file.
        /// - error: The underlying error originally thrown by Foundation when setting the `attributes` to the disk
        ///          file at `filePath`.
        case cannotSetCacheFileAttribute(filePath: String, attributes: [FileAttributeKey : Any], error: Error)

        /// The disk storage of cache is not ready. Code 3011.
        ///
        /// This is usually due to extremely lack of space on disk storage, and
        /// Kingfisher failed even when creating the cache folder. The disk storage will be in unusable state. Normally,
        /// ask user to free some spaces and restart the app to make the disk storage work again.
        /// - cacheURL: The intended URL which should be the storage folder.
        case diskStorageIsNotReady(cacheURL: URL)
    }
    
    
    /// Represents the error reason during image processing phase.
    ///
    /// - processingFailed: Image processing fails. There is no valid output image from the processor. Code 4001.
    public enum ProcessorErrorReason {
        /// Image processing fails. There is no valid output image from the processor. Code 4001.
        /// - processor: The `ImageProcessor` used to process the image or its data in `item`.
        /// - item: The image or its data content.
        case processingFailed(processor: ImageProcessor, item: ImageProcessItem)
    }

    /// Represents the error reason during image setting in a view related class.
    ///
    /// - emptySource: The input resource is empty or `nil`. Code 5001.
    /// - notCurrentSourceTask: The source task is finished, but it is not the one expected now. Code 5002.
    /// - dataProviderError: An error happens during getting data from an `ImageDataProvider`. Code 5003.
    public enum ImageSettingErrorReason {
        
        /// The input resource is empty or `nil`. Code 5001.
        case emptySource
        
        /// The resource task is finished, but it is not the one expected now. This usually happens when you set another
        /// resource on the view without cancelling the current on-going one. The previous setting task will fail with
        /// this `.notCurrentSourceTask` error when a result got, regardless of it being successful or not for that task.
        /// The result of this original task is contained in the associated value.
        /// Code 5002.
        /// - result: The `RetrieveImageResult` if the source task is finished without problem. `nil` if an error
        ///           happens.
        /// - error: The `Error` if an issue happens during image setting task. `nil` if the task finishes without
        ///          problem.
        /// - source: The original source value of the task.
        case notCurrentSourceTask(result: RetrieveImageResult?, error: Error?, source: Source)

        /// An error happens during getting data from an `ImageDataProvider`. Code 5003.
        case dataProviderError(provider: ImageDataProvider, error: Error)

        /// No more alternative `Source` can be used in current loading process. It means that the
        /// `.alternativeSources` are used and Kingfisher tried to recovery from the original error, but still
        /// fails for all the given alternative sources. The associated value holds all the errors encountered during
        /// the load process, including the original source loading error and all the alternative sources errors.
        /// Code 5004.
        case alternativeSourcesExhausted([PropagationError])
    }

    // MARK: Member Cases
    
    /// Represents the error reason during networking request phase.
    case requestError(reason: RequestErrorReason)
    /// Represents the error reason during networking response phase.
    case responseError(reason: ResponseErrorReason)
    /// Represents the error reason during Kingfisher caching system.
    case cacheError(reason: CacheErrorReason)
    /// Represents the error reason during image processing phase.
    case processorError(reason: ProcessorErrorReason)
    /// Represents the error reason during image setting in a view related class.
    case imageSettingError(reason: ImageSettingErrorReason)

    // MARK: Helper Properties & Methods

    /// Helper property to check whether this error is a `RequestErrorReason.taskCancelled` or not.
    public var isTaskCancelled: Bool {
        if case .requestError(reason: .taskCancelled) = self {
            return true
        }
        return false
    }

    /// Helper method to check whether this error is a `ResponseErrorReason.invalidHTTPStatusCode` and the
    /// associated value is a given status code.
    ///
    /// - Parameter code: The given status code.
    /// - Returns: If `self` is a `ResponseErrorReason.invalidHTTPStatusCode` error
    ///            and its status code equals to `code`, `true` is returned. Otherwise, `false`.
    public func isInvalidResponseStatusCode(_ code: Int) -> Bool {
        if case .responseError(reason: .invalidHTTPStatusCode(let response)) = self {
            return response.statusCode == code
        }
        return false
    }

    public var isInvalidResponseStatusCode: Bool {
        if case .responseError(reason: .invalidHTTPStatusCode) = self {
            return true
        }
        return false
    }

    /// Helper property to check whether this error is a `ImageSettingErrorReason.notCurrentSourceTask` or not.
    /// When a new image setting task starts while the old one is still running, the new task identifier will be
    /// set and the old one is overwritten. A `.notCurrentSourceTask` error will be raised when the old task finishes
    /// to let you know the setting process finishes with a certain result, but the image view or button is not set.
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
    
    /// A localized message describing what error occurred.
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

    /// The error domain of `KingfisherError`. All errors from Kingfisher is under this domain.
    public static let domain = "com.onevcat.Kingfisher.Error"

    /// The error code within the given domain.
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
        }
    }
    
    var errorCode: Int {
        switch self {
        case .emptyRequest: return 1001
        case .invalidURL: return 1002
        case .taskCancelled: return 1003
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
            return "Image setting from alternaive sources failed: \(errors)"
        }
    }
    
    var errorCode: Int {
        switch self {
        case .emptySource: return 5001
        case .notCurrentSourceTask: return 5002
        case .dataProviderError: return 5003
        case .alternativeSourcesExhausted: return 5004
        }
    }
}
