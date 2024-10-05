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

public struct LivePhotoResource: Sendable {
    
    public enum FileType: Sendable {
        case heic
        case mov
        case other(String)
    }
    
    public let resource: any Resource
    public let referenceFileType: FileType
    
    var cacheKey: String { resource.cacheKey }
    var downloadURL: URL { resource.downloadURL }
    
    public init(downloadURL: URL, cacheKey: String? = nil, fileType: FileType? = nil) {
        resource = KF.ImageResource(downloadURL: downloadURL, cacheKey: cacheKey)
        referenceFileType = fileType ?? resource.guessedFileType
    }
    
    public init(resource: any Resource, fileType: FileType? = nil) {
        self.resource = resource
        referenceFileType = fileType ?? resource.guessedFileType
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
    
    static let fytpChunk: [UInt8] = [0x66, 0x74, 0x79, 0x70]
    static let heicChunk: [UInt8] = [0x68, 0x65, 0x69, 0x63]
    static let qtChunk: [UInt8] = [0x71, 0x74, 0x20, 0x20] // quicktime
    
    static func guessedFileExtension(from data: Data) -> String? {
        
        guard data.count > 12 else { return nil }
        
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
        return switch pathExtension {
        case "mov": .mov
        case "heic": .heic
        default: .other(pathExtension)
        }
    }
}

public struct LivePhotoSource: Sendable {
    
    public let resources: [LivePhotoResource]
    
    public init(resources: [any Resource]) {
        let livePhotoResources = resources.map { LivePhotoResource(resource: $0) }
        self.init(livePhotoResources)
    }
    
    public init(urls: [URL]) {
        let resources = urls.map { KF.ImageResource(downloadURL: $0) }
        self.init(resources: resources)
    }
    
    public init(_ resources: [LivePhotoResource]) {
        self.resources = resources
    }
}
