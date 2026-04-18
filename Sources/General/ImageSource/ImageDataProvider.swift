//
//  ImageDataProvider.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/13.
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
import ImageIO

/// Represents a data provider to provide image data to Kingfisher when setting with
/// ``Source/provider(_:)`` source. Compared to ``Source/network(_:)`` member, it gives a chance
/// to load some image data in your own way, as long as you can provide the data
/// representation for the image.
public protocol ImageDataProvider: Sendable {

    /// The key used in cache.
    var cacheKey: String { get }

    /// Asynchronously provides the data which represents the image.
    ///
    /// Kingfisher calls this method inside a `Task` that it owns. When the corresponding
    /// ``DownloadTask`` is cancelled by the caller (e.g. via
    /// ``DownloadTask/cancel()`` or `imageView.kf.cancelDownloadTask()`), the owning `Task`
    /// is cancelled as well. Implementations are expected to cooperate with Swift
    /// concurrency cancellation:
    ///
    /// - Use cancellation-aware APIs (such as `URLSession.data(for:)`) whose underlying
    ///   work is interrupted when the surrounding task is cancelled.
    /// - Insert `try Task.checkCancellation()` at sensible checkpoints in long-running
    ///   logic.
    /// - Use `withTaskCancellationHandler(operation:onCancel:)` to bridge into
    ///   non-async resources that expose their own cancellation hook.
    ///
    /// When the task is cancelled, implementations should throw (typically by letting
    /// `CancellationError` propagate). Kingfisher will translate this into a
    /// ``KingfisherError/RequestErrorReason/dataProviderCancelled(provider:)`` for the
    /// completion handler, matching the semantics of a cancelled network source.
    ///
    /// - Returns: The image data.
    /// - Throws: Any error produced while loading the data, including `CancellationError`
    ///           when the loading was cancelled.
    ///
    /// > A default implementation is provided that bridges to ``data(handler:)`` via
    /// > `withCheckedThrowingContinuation`. That bridge cannot interrupt callback-based
    /// > work: such providers will still complete in the background after cancel, and
    /// > Kingfisher will discard their result. Override this method to participate in
    /// > cooperative cancellation.
    func data() async throws -> Data

    /// Provides the data which represents the image via a completion handler.
    ///
    /// - Parameter handler: The handler to call when the data is prepared. Pass
    ///                      `.success(data)` on success, or `.failure(error)` on failure.
    ///
    /// - Note: If the `handler` is called with a `.failure` with error,
    /// a ``KingfisherError/ImageSettingErrorReason/dataProviderError(provider:error:)`` will be finally thrown out to
    /// you as the ``KingfisherError`` from the framework.
    ///
    /// > A default implementation is provided that bridges to ``data()`` by spinning up
    /// > a `Task`. Implement at least one of ``data()`` or ``data(handler:)``; implementing
    /// > neither results in mutual recursion at runtime.
    func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void)

    /// The content URL represents this provider, if exists.
    var contentURL: URL? { get }
}

public extension ImageDataProvider {

    /// Default asynchronous entry point. Bridges to the legacy ``data(handler:)``
    /// requirement via `withCheckedThrowingContinuation`.
    ///
    /// > Important: Bridging a callback-based implementation through this default does
    /// > **not** propagate `Task` cancellation into the callback. To participate in
    /// > cooperative cancellation, override this method with an implementation that
    /// > honors `Task.isCancelled` / `try Task.checkCancellation()` or uses
    /// > cancellation-aware async APIs.
    func data() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            data(handler: { continuation.resume(with: $0) })
        }
    }

    /// Default callback-based entry point. Bridges to ``data()`` by spawning a `Task`.
    ///
    /// > Note: The `Task` opened here is unstructured and does **not** inherit
    /// > cancellation from any surrounding `Task` on the caller side. If a caller
    /// > outside Kingfisher invokes this default bridge from within a cancelled
    /// > parent task, the parent's cancellation will not automatically propagate
    /// > into the provider's `data()` call. For Kingfisher's own provider loads
    /// > this is not a concern because the framework drives providers through
    /// > ``ImageDataProvider/data()`` directly, with the owning `Task` cancelled
    /// > by ``DownloadTask/cancel()``.
    func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        Task {
            do {
                let data = try await data()
                handler(.success(data))
            } catch {
                handler(.failure(error))
            }
        }
    }

    var contentURL: URL? { return nil }
    func convertToSource() -> Source {
        .provider(self)
    }
}

/// Represents an image data provider for loading from a local file URL on disk.
/// Uses this type for adding a disk image to Kingfisher. Compared to loading it
/// directly, you can get benefit of using Kingfisher's extension methods, as well
/// as applying ``ImageProcessor``s and storing the image to ``ImageCache`` of Kingfisher.
public struct LocalFileImageDataProvider: ImageDataProvider {

    // MARK: Public Properties

    /// The file URL from which the image be loaded.
    public let fileURL: URL
    private let loadingQueue: ExecutionQueue

    // MARK: Initializers

    /// Creates an image data provider by supplying the target local file URL.
    ///
    /// - Parameters:
    ///   - fileURL: The file URL from which the image be loaded.
    ///   - cacheKey: The key is used for caching the image data. By default,
    ///               the `absoluteString` of ``LocalFileImageDataProvider/fileURL`` is used.
    ///   - loadingQueue: The queue where the file loading should happen. By default, the dispatch queue of
    ///                   `.global(qos: .userInitiated)` will be used.
    public init(
        fileURL: URL,
        cacheKey: String? = nil,
        loadingQueue: ExecutionQueue = .dispatch(DispatchQueue.global(qos: .userInitiated))
    ) {
        self.fileURL = fileURL
        self.cacheKey = cacheKey ?? fileURL.localFileCacheKey
        self.loadingQueue = loadingQueue
    }

    // MARK: Protocol Conforming

    /// The key used in cache.
    public var cacheKey: String

    public func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        loadingQueue.execute {
            handler(Result(catching: { try Data(contentsOf: fileURL) }))
        }
    }
    
    public var data: Data {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                loadingQueue.execute {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        continuation.resume(returning: data)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /// The URL of the local file on the disk.
    public var contentURL: URL? {
        return fileURL
    }
}

/// Represents an image data provider for loading image from a given Base64 encoded string.
public struct Base64ImageDataProvider: ImageDataProvider {

    // MARK: Public Properties
    /// The encoded Base64 string for the image.
    public let base64String: String

    // MARK: Initializers

    /// Creates an image data provider by supplying the Base64 encoded string.
    ///
    /// - Parameters:
    ///   - base64String: The Base64 encoded string for an image.
    ///   - cacheKey: The key is used for caching the image data. You need a different key for any different image.
    public init(base64String: String, cacheKey: String) {
        self.base64String = base64String
        self.cacheKey = cacheKey
    }

    // MARK: Protocol Conforming

    /// The key used in cache.
    public var cacheKey: String

    public func data(handler: (Result<Data, any Error>) -> Void) {
        let data = Data(base64Encoded: base64String)!
        handler(.success(data))
    }
}

/// Represents an image data provider for a raw data object.
public struct RawImageDataProvider: ImageDataProvider {

    // MARK: Public Properties

    /// The raw data object to provide to Kingfisher image loader.
    public let data: Data

    // MARK: Initializers

    /// Creates an image data provider by the given raw `data` value and a `cacheKey` be used in Kingfisher cache.
    ///
    /// - Parameters:
    ///   - data: The raw data represents an image.
    ///   - cacheKey: The key is used for caching the image data. You need a different key for any different image.
    public init(data: Data, cacheKey: String) {
        self.data = data
        self.cacheKey = cacheKey
    }

    // MARK: Protocol Conforming
    
    /// The key used in cache.
    public var cacheKey: String

    public func data(handler: @escaping (Result<Data, any Error>) -> Void) {
        handler(.success(data))
    }
}

/// A data provider that creates a thumbnail from a URL using Core Graphics.
public struct ThumbnailImageDataProvider: ImageDataProvider {
    
    public enum ThumbnailImageDataProviderError: Error {
        case invalidImageSource
        case invalidThumbnail
        case writeDataError
        case finalizeDataError
    }
    
    /// The URL from which to load the image
    public let url: URL
    
    /// The maximum size of the thumbnail in pixels
    public var maxPixelSize: CGFloat
    
    /// Whether to always create a thumbnail even if the image is smaller than maxPixelSize
    public var alwaysCreateThumbnail: Bool
    
    /// The cache key for this provider
    public var cacheKey: String
    
    /// Creates a new thumbnail data provider
    /// - Parameters:
    ///   - url: The URL from which to load the image
    ///   - maxPixelSize: The maximum size of the thumbnail in pixels
    ///   - alwaysCreateThumbnail: Whether to always create a thumbnail even if the image is smaller than maxPixelSize
    public init(
        url: URL,
        maxPixelSize: CGFloat,
        alwaysCreateThumbnail: Bool = true,
        cacheKey: String? = nil
    ) {
        self.url = url
        self.maxPixelSize = maxPixelSize
        self.alwaysCreateThumbnail = alwaysCreateThumbnail
        self.cacheKey = cacheKey ?? "\(url.absoluteString)_thumb_\(maxPixelSize)_\(alwaysCreateThumbnail)"
    }
    
    public func data(handler: @escaping @Sendable (Result<Data, any Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let url = URL(string: url.absoluteString) else {
                    throw KingfisherError.imageSettingError(reason: .emptySource)
                        
                }
                
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                    throw ThumbnailImageDataProviderError.invalidImageSource
                }
                
                let options = [
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                    kCGImageSourceCreateThumbnailFromImageAlways: alwaysCreateThumbnail,
                    kCGImageSourceCreateThumbnailWithTransform: true
                ]
                
                guard let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                    throw ThumbnailImageDataProviderError.invalidThumbnail
                }
                
                let data = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(
                    data, CGImageSourceGetType(imageSource)!, 1, nil
                ) else {
                    throw ThumbnailImageDataProviderError.writeDataError
                }
                
                CGImageDestinationAddImage(destination, thumbnailRef, nil)
                if CGImageDestinationFinalize(destination) {
                    handler(.success(data as Data))
                } else {
                    throw ThumbnailImageDataProviderError.finalizeDataError
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
}
