//
//  KingfisherError.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/26.
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

import Foundation

extension Never: Error {}

/// Represents all the errors which can happen in Kingfisher framework.
public enum KingfisherError: Error {
    
    /// The error domain of Kingfisher.
    public static let domain = "com.onevcat.Kingfisher.Error"
    
    public enum RequestErrorReason {
        case emptyRequest
        case invalidURL(request: URLRequest)
        case taskCancelled(task: SessionDataTask, token: SessionDataTask.CancelToken)
    }
    
    public enum ResponseErrorReason {
        case invalidURLResponse(response: URLResponse)
        case invalidHTTPStatusCode(response: HTTPURLResponse)
        case URLSessionError(error: Error)
        case dataModifyingFailed(task: SessionDataTask)
        case noURLResponse(task: SessionDataTask)
    }
    
    public enum CacheErrorReason {
        case fileEnumeratorCreationFailed(url: URL)
        case invalidFileEnumeratorContent(url: URL)
        case invalidURLResource(error: Error, key: String, url: URL, resourceKeys: Set<URLResourceKey>)
        case cannotLoadDataFromDisk(url: URL, error: Error)
        case cannotCreateDirectory(error: Error, path: String)
        case imageNotExisting(key: String)
        case cannotConvertToData(object: Any, error: Error)
        case cannotSerializeImage(image: Image, original: Data?, serializer: CacheSerializer)
    }
    
    public enum ProcessorErrorReason {
        case processingFailed(processor: ImageProcessor, item: ImageProcessItem)
    }

    public enum ImageSettingErrorReason {
        case emptyResource
        case notCurrentResource(result: RetrieveImageResult?, error: Error?, resource: Resource)
    }
    
    case requestError(reason: RequestErrorReason)
    case responseError(reason: ResponseErrorReason)
    case cacheError(reason: CacheErrorReason)
    case processorError(reason: ProcessorErrorReason)
    case imageSettingError(reason: ImageSettingErrorReason)
    
    public var isTaskCancelled: Bool {
        if case .requestError(reason: .taskCancelled) = self {
            return true
        }
        return false
    }

    public func isInvalidResponseStatusCode(_ code: Int) -> Bool {
        if case .responseError(reason: .invalidHTTPStatusCode(let response)) = self {
            return response.statusCode == code
        }
        return false
    }
}

extension KingfisherError: LocalizedError {
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

extension KingfisherError: CustomNSError {
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
            return "The session task was canncelled. Task: \(task), cancel token: \(token)."
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
            return "No URL response received. Task: \(task),"
        }
    }
    
    var errorCode: Int {
        switch self {
        case .invalidURLResponse: return 2001
        case .invalidHTTPStatusCode: return 2002
        case .URLSessionError: return 2003
        case .dataModifyingFailed: return 2004
        case .noURLResponse: return 2005
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
        case .invalidURLResource(let error, let key, let url, let resourceKeys):
            return "Cannot get URL resource values or data for the given URL: \(url). " +
                   "Cache key: \(key). Requested resource keys: \(resourceKeys). Underlying error: \(error)"
        case .cannotLoadDataFromDisk(let url, let error):
            return "Cannot load data from disk at URL: \(url). Underlying error: \(error)"
        case .cannotCreateDirectory(let error, let path):
            return "Cannot create directory at given path: Path: \(path). Underlying error: \(error)"
        case .imageNotExisting(let key):
            return "The image is not in cache, but you requires it should only be " +
                   "from cache by enabling the `.onlyFromCache` option. Key: \(key)."
        case .cannotConvertToData(let object, let error):
            return "Cannot convert the input object to a `Data` object when storing it to disk cache. " +
                   "Object: \(object). Underlying error: \(error)"
        case .cannotSerializeImage(let image, let originalData, let serializer):
            return "Cannot serialize an image due to the cache serializer returning `nil`. " +
                   "Image: \(image), original data: \(String(describing: originalData)), serializer: \(serializer)."
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
        case .emptyResource:
            return "The input resource is empty."
        case .notCurrentResource(let result, let error, let resource):
            if let result = result {
                return "Retrieving resource succeeded, but this resource is " +
                       "not the one currently expected. Result: \(result). Resource: \(resource)."
            } else if let error = error {
                return "Retrieving resource failed, and this resource is " +
                       "not the one currently expected. Error: \(error). Resource: \(resource)."
            } else {
                return nil
            }
        }
    }
    
    var errorCode: Int {
        switch self {
        case .emptyResource: return 5001
        case .notCurrentResource: return 5002
        }
    }
}
