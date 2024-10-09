//
//  KingfisherManager+LivePhoto.swift
//  Kingfisher
//
//  Created by onevcat on 2024/10/01.
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

#if !os(watchOS)
@preconcurrency import Photos

/// A structure that contains information about the result of loading a live photo.
public struct LivePhotoLoadingInfoResult: Sendable {
    
    /// Retrieves the live photo disk URLs from this result.
    public let fileURLs: [URL]

    /// Retrieves the cache source of the image, indicating from which cache layer it was retrieved.
    ///
    /// If the image was freshly downloaded from the network and not retrieved from any cache, `.none` will be returned.
    /// Otherwise, ``CacheType/disk`` will be returned for the live photo. ``CacheType/memory`` is not available for
    /// live photos since it may take too much memory. All cached live photos are loaded from disk only.
    public let cacheType: CacheType

    /// The ``LivePhotoSource`` to which this result is related. This indicates where the `livePhoto` referenced by
    /// `self` is located.
    public let source: LivePhotoSource

    /// The original ``LivePhotoSource`` from which the retrieval task begins. It may differ from the ``source`` property.
    /// When an alternative source loading occurs, the ``source`` will represent the replacement loading target, while the
    /// ``originalSource`` will retain the initial ``source`` that initiated the image loading process.
    public let originalSource: LivePhotoSource
    
    /// Retrieves the data associated with this result.
    ///
    /// When this result is obtained from a network download (when `cacheType == .none`), calling this method returns
    /// the downloaded data. If the result is from the cache, it serializes the image using the specified cache
    /// serializer from the loading options and returns the result.
    ///
    /// - Note: Retrieving this data can be a time-consuming operation, so it is advisable to store it if you need to
    /// use it multiple times and avoid frequent calls to this method.
    public let data: @Sendable () -> [Data]
}

extension KingfisherManager {

    /// Retrieves a live photo from the specified source.
    ///
    /// This method asynchronously loads a live photo from the given source, applying the specified options and
    /// reporting progress if a progress block is provided.
    ///
    /// - Parameters:
    ///   - source: The ``LivePhotoSource`` from which to retrieve the live photo.
    ///   - options: A dictionary of options to apply to the retrieval process. If `nil`, the default options will be
    ///   used.
    ///   - progressBlock: An optional closure to be called periodically during the download process.
    ///   - referenceTaskIdentifierChecker: An optional closure that returns a Boolean value indicating whether the task
    ///   should proceed.
    ///
    /// - Returns: A ``LivePhotoLoadingInfoResult`` containing information about the retrieved live photo.
    ///
    /// - Throws: An error if the retrieval process fails.
    ///
    /// - Note: This method uses `LivePhotoImageProcessor` by default. Custom processors are not supported for live photos.
    ///
    /// - Warning: Not all options are working for this method. And currently the `progressBlock` is not working. 
    /// It will be implemented in the future.
    public func retrieveLivePhoto(
        with source: LivePhotoSource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        referenceTaskIdentifierChecker: (() -> Bool)? = nil
    ) async throws -> LivePhotoLoadingInfoResult {
        let fullOptions = currentDefaultOptions + (options ?? .empty)
        var checkedOptions = KingfisherParsedOptionsInfo(fullOptions)
        
        if checkedOptions.processor == DefaultImageProcessor.default {
            // The default processor is a default behavior so we replace it silently.
            checkedOptions.processor = LivePhotoImageProcessor.default
        } else if checkedOptions.processor != LivePhotoImageProcessor.default {
            // Warn the framework user that the processor is not supported.
            assertionFailure("[Kingfisher] Using of custom processors during loading of live photo resource is not supported.")
            checkedOptions.processor = LivePhotoImageProcessor.default
        }
        
        if let checker = referenceTaskIdentifierChecker {
            checkedOptions.onDataReceived?.forEach {
                $0.onShouldApply = checker
            }
        }
        
        // TODO. We ignore the retry of live photo and the progress now to suppress the complexity.
        
        let missingResources = missingResources(source, options: checkedOptions)
        let resourcesResult = try await downloadAndCache(resources: missingResources, options: checkedOptions)
        
        let targetCache = checkedOptions.targetCache ?? cache
        var fileURLs = [URL]()
        for resource in source.resources {
            let url = targetCache.possibleCacheFileURLIfOnDisk(resource: resource, options: checkedOptions)
            guard let url else {
                // This should not happen normally if the previous `downloadAndCache` done without issue, but in case.
                throw KingfisherError.cacheError(reason: .missingLivePhotoResourceOnDisk(resource))
            }
            fileURLs.append(url)
        }
        
        return LivePhotoLoadingInfoResult(
            fileURLs: fileURLs,
            cacheType: missingResources.isEmpty ? .disk : .none,
            source: source,
            originalSource: source,
            data: {
                resourcesResult.map { $0.originalData }
            })
    }
    
    // Returns the missing resources for the given source and options. If the resource is not in the cache, it will be
    // returned as a missing resource.
    func missingResources(_ source: LivePhotoSource, options: KingfisherParsedOptionsInfo) -> [LivePhotoResource] {
        let missingResources: [LivePhotoResource]
        if options.forceRefresh {
            missingResources = source.resources
        } else {
            let targetCache = options.targetCache ?? cache
            missingResources = source.resources.reduce([], { r, resource in
                // Check if the resource is in the cache. It includes a guess of the file extension.
                let cachedFileURL = targetCache.possibleCacheFileURLIfOnDisk(resource: resource, options: options)
                if cachedFileURL == nil {
                    return r + [resource]
                } else {
                    return r
                }
            })
        }
        return missingResources
    }
    
    // Download the resources and store them to the cache.
    // If the resource does not specify a file extension (from either the URL extension or the explicit 
    // `referenceFileType`), we infer it from the file signature.
    func downloadAndCache(
        resources: [LivePhotoResource],
        options: KingfisherParsedOptionsInfo
    ) async throws -> [LivePhotoResourceDownloadingResult] {
        if resources.isEmpty {
            return []
        }
        let downloader = options.downloader ?? downloader
        let cache = options.targetCache ?? cache

        // Download all resources concurrently.
        return try await withThrowingTaskGroup(of: LivePhotoResourceDownloadingResult.self) { 
            group in
            
            for resource in resources {
                group.addTask {
                    
                    let downloadedResource: LivePhotoResourceDownloadingResult
                    
                    switch resource.dataSource {
                    case .network(let urlResource):
                        downloadedResource = try await downloader.downloadLivePhotoResource(
                            with: urlResource.downloadURL,
                            options: options
                        )
                    case .provider(let provider):
                        downloadedResource = try await LivePhotoResourceDownloadingResult(
                            originalData: provider.data(),
                            url: provider.contentURL
                        )
                    }
                     
                    // We need to specify the extension so the file is saved correctly. Live photo loading requires
                    // the file extension to be correct. Otherwise, a 3302 error will be thrown.
                    // https://developer.apple.com/documentation/photokit/phphotoserror/code/invalidresource
                    let fileExtension = resource.referenceFileType
                        .determinedFileExtension(downloadedResource.originalData)
                    try await cache.storeToDisk(
                        downloadedResource.originalData,
                        forKey: resource.cacheKey,
                        processorIdentifier: options.processor.identifier,
                        forcedExtension: fileExtension,
                        expiration: options.diskCacheExpiration
                    )
                    return downloadedResource
                }
            }
            
            var result: [LivePhotoResourceDownloadingResult] = []
            for try await resource in group {
                result.append(resource)
            }
            return result
        }
    }
}

extension ImageCache {
    
    func possibleCacheFileURLIfOnDisk(
        resource: LivePhotoResource,
        options: KingfisherParsedOptionsInfo
    ) -> URL? {
        possibleCacheFileURLIfOnDisk(
            forKey: resource.cacheKey,
            processorIdentifier: options.processor.identifier,
            referenceFileType: resource.referenceFileType
        )
    }
    
    // Returns the possible cache file URL for the given key and processor identifier. If the file is on disk, it will
    // return the URL. Otherwise, it will return `nil`.
    //
    // This method also tries to guess the file extension if it is not specified in the `referenceFileType`. 
    // `PHLivePhoto`'s `request` method requires the file extension to be correct on the disk, and we also stored the 
    // downloaded data with the correct extension (if it is not specified in the `referenceFileType`, we infer it from
    // the file signature. See `FileType.determinedFileExtension` for more).
    func possibleCacheFileURLIfOnDisk(
        forKey key: String,
        processorIdentifier identifier: String,
        referenceFileType: LivePhotoResource.FileType
    ) -> URL? {
        switch referenceFileType {
        case .heic, .mov:
            // The extension is specified and is what necessary to load a live photo, use it.
            return cacheFileURLIfOnDisk(
                forKey: key, processorIdentifier: identifier, forcedExtension: referenceFileType.fileExtension
            )
        case .other(let ext):
            if ext.isEmpty {
                // The extension is not specified. Guess from the default set of values.
                let possibleFileTypes: [LivePhotoResource.FileType] = [.heic, .mov]
                for fileType in possibleFileTypes {
                    let url = cacheFileURLIfOnDisk(
                        forKey: key, processorIdentifier: identifier, forcedExtension: fileType.fileExtension
                    )
                    if url != nil {
                        // Found, early return.
                        return url
                    }
                }
                return nil
            } else {
                // The extension is specified but maybe not valid for live photo. Trust the user and use it to find the
                // file.
                return cacheFileURLIfOnDisk(
                    forKey: key, processorIdentifier: identifier, forcedExtension: ext
                )
            }
        }
    }
}
#endif
