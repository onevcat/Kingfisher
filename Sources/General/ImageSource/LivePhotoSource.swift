//
//  LivePhotoSource.swift
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

import Foundation

/// A type represents a loadable resource for a Live Photo, which consists of a still image and a video.
/// 
/// Kingfisher expects a ``LivePhotoSource`` value to load a Live Photo with its high-level APIs. 
/// A ``LivePhotoSource`` is typically a collection of two ``LivePhotoResource`` values, one for the still image and 
/// one for the video.
public struct LivePhotoSource: Sendable {
    
    /// The resources of a Live Photo.
    public let resources: [LivePhotoResource]
    
    /// Creates a Live Photo source with given resources.
    /// - Parameter resources: The downloadable resource for a Live Photo. It should contain two resources, one for the
    /// still image and one for the video.
    public init(resources: [any Resource]) {
        let livePhotoResources = resources.map { LivePhotoResource(resource: $0) }
        self.init(livePhotoResources)
    }
    
    /// Creates a Live Photo source with given URLs.
    /// - Parameter urls: The URLs of the downloadable resources for a Live Photo. It should contain two URLs, one for
    /// the still image and one for the video.
    public init(urls: [URL]) {
        let resources = urls.map { KF.ImageResource(downloadURL: $0) }
        self.init(resources: resources)
    }
    
    /// Creates a Live Photo source with given resources.
    /// - Parameter resources: The resources for a Live Photo. It should contain two resources, one for the still image
    /// and one for the video.
    public init(_ resources: [LivePhotoResource]) {
        self.resources = resources
    }
}


/// A resource type representing a component of a Live Photo, which consists of a still image and a video.
///
/// ``LivePhotoResource`` encapsulates the necessary information to download and cache a single component of a Live
/// Photo: it is either a still image (typically in HEIF format with "heic" filename extension) or a video (typically in
/// QuickTime format with "mov" filename extension). Multiple ``LivePhotoResource`` values (typically two, one for the
/// image and one for the video) can form a ``LivePhotoSource``, which is expected by Kingfisher in its live photo
/// loading high level APIs.
///
/// The Live Photo data can be retrieved by `PHAssetResourceManager.requestData` method and uploaded to your server.
/// You should not modify the metadata or other information of the data, otherwise, it is possible that the
/// `PHLivePhoto` class cannot read and recognize it anymore. For more information, please refer to Apple's
/// documentation of Photos framework.
public struct LivePhotoResource: Sendable {
    
    /// The file type of a ``LivePhotoResource``.
    public enum FileType: Sendable, Equatable {
        /// File type HEIC. Usually it represents the still image in a Live Photo.
        case heic
        /// File type MOV. Usually it represents the video in a Live Photo.
        case mov
        /// Other file types with the file extension.
        case other(String)
        
        var fileExtension: String {
            switch self {
            case .heic: return "heic"
            case .mov: return "mov"
            case .other(let ext): return ext
            }
        }
    }
    
    /// The data source of a Live Photo resource.
    /// 
    /// This is a general ``Source`` type, which can be either a network resource (as ``Source/network(_:)``) or a
    /// provided resource as ``Source/provider(_:)``.
    public let dataSource: Source

    /// The file type of the resource.
    public let referenceFileType: FileType
    
    var cacheKey: String { dataSource.cacheKey }
    var downloadURL: URL? { dataSource.url }
        
    /// Creates a Live Photo resource with given download URL, cache key and file type.
    /// - Parameters:
    ///   - downloadURL: The URL to download the resource.
    ///   - cacheKey: The cache key for the resource. If `nil`, Kingfisher will use the `absoluteString` of the URL as
    ///     the cache key.
    ///   - fileType: The file type of the resource. If `nil`, Kingfisher will try to guess the file type from the URL.
    /// 
    /// The file type is important for Kingfisher to determine how to handle the downloaded data and store them
    /// in the cache. Photos framework requires the still image to be in HEIC extension and the video to be in MOV 
    /// extension. Otherwise, the `PHLivePhoto` class might not be able to recognize the data. If you are not sure about
    /// the file type, you can leave it as `nil` and Kingfisher will try to guess it from the URL and the downloaded 
    /// data.
    public init(downloadURL: URL, cacheKey: String? = nil, fileType: FileType? = nil) {
        let resource = KF.ImageResource(downloadURL: downloadURL, cacheKey: cacheKey)
        dataSource = .network(resource)
        referenceFileType = fileType ?? resource.guessedFileType
    }
    
    /// Creates a Live Photo resource with given resource and file type.
    /// - Parameters:
    ///   - resource: The resource to download the data.
    ///   - fileType: The file type of the resource. If `nil`, Kingfisher will try to guess the file type from the URL.
    /// 
    /// The file type is important for Kingfisher to determine how to handle the downloaded data and store them
    /// in the cache. Photos framework requires the still image to be in HEIC extension and the video to be in MOV 
    /// extension. Otherwise, the `PHLivePhoto` class might not be able to recognize the data. If you are not sure about
    /// the file type, you can leave it as `nil` and Kingfisher will try to guess it from the URL and the downloaded 
    /// data.
    public init(resource: any Resource, fileType: FileType? = nil) {
        self.dataSource = .network(resource)
        referenceFileType = fileType ?? resource.guessedFileType
    }
    
    /// Creates a Live Photo resource with given data source and file type.
    /// - Parameters:
    ///   - source: The data source of the resource. It can be either a network resource or a provided resource.
    ///   - fileType: The file type of the resource. If `nil`, Kingfisher will try to guess the file type from the URL.
    /// 
    /// The file type is important for Kingfisher to determine how to handle the downloaded data and store them
    /// in the cache. Photos framework requires the still image to be in HEIC extension and the video to be in MOV 
    /// extension. Otherwise, the `PHLivePhoto` class might not be able to recognize the data. If you are not sure about
    /// the file type, you can leave it as `nil` and Kingfisher will try to guess it from the URL and the downloaded 
    /// data.
    public init(source: Source, fileType: FileType? = nil) {
        self.dataSource = source
        referenceFileType = fileType ?? source.url?.guessedFileType ?? .other("")
    }
}

extension LivePhotoResource.FileType {
    func determinedFileExtension(_ data: Data) -> String? {
        switch self {
        case .mov: return "mov"
        case .heic: return "heic"
        case .other(let ext):
            if !ext.isEmpty {
                return ext
            }
            return Self.guessedFileExtension(from: data)
        }
    }
    
    static let fytpChunk: [UInt8] = [0x66, 0x74, 0x79, 0x70] // fytp (file type box)
    static let heicChunk: [UInt8] = [0x68, 0x65, 0x69, 0x63] // heic (HEIF)
    static let qtChunk: [UInt8] = [0x71, 0x74, 0x20, 0x20] // qt (QuickTime), .mov
    
    static func guessedFileExtension(from data: Data) -> String? {
        
        guard data.count >= 12 else { return nil }
        
        var buffer = [UInt8](repeating: 0, count: 12)
        data.copyBytes(to: &buffer, count: 12)
        
        guard Array(buffer[4..<8]) == fytpChunk else {
            return nil
        }
        
        let fileTypeChunk = Array(buffer[8..<12])
        if fileTypeChunk == heicChunk {
            return "heic"
        }
        if fileTypeChunk == qtChunk {
            return "mov"
        }
        return nil
    }
}

extension Resource {
    var guessedFileType: LivePhotoResource.FileType {
        let pathExtension = downloadURL.pathExtension.lowercased()
        switch pathExtension {
        case "mov": return .mov
        case "heic": return .heic
        default: return .other(pathExtension)
        }
    }
}
