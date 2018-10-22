//
//  DiskStorage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
//
//  Copyright (c) 2018年 Wei Wang <onevcat@gmail.com>
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

protocol ExtendingStorage: Storage {
    func extendExpriration(forKey key: KeyType, lastAccessDate: Date, nextExpiration: StorageExpiration) throws
}

public class DiskStorage<T: DataTransformable>: ExtendingStorage {

    public struct Config {
        let name: String
        let fileManager: FileManager
        let directory: URL?
        public var expiration: StorageExpiration

        var cachePathBlock: ((_ directory: URL, _ cacheName: String) -> URL)! = {
            (directory, cacheName) in
            return directory.appendingPathComponent(cacheName, isDirectory: true)
        }

        var pathExtension: String?
        var sizeLimit: Int

        init(
            name: String,
            fileManager: FileManager = .default,
            directory: URL? = nil,
            expiration: StorageExpiration = .days(7),
            pathExtension: String? = nil,
            sizeLimit: Int)
        {
            self.name = name
            self.fileManager = fileManager
            self.directory = directory
            self.expiration = expiration
            self.pathExtension = pathExtension
            self.sizeLimit = sizeLimit
        }
    }

    var config: Config
    let directoryURL: URL

    let onFileRemoved = Delegate<URL, Void>()
    let onCacheRemoved = Delegate<(), Void>()

    init(config: Config) throws {

        self.config = config

        let url: URL
        if let directory = config.directory {
            url = directory
        } else {
            url = try config.fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true)
        }

        let cacheName = "com.onevcat.Kingfisher.ImageCache.\(config.name)"
        directoryURL = config.cachePathBlock(url, cacheName)
        try prepareDirectory()
    }

    func prepareDirectory() throws {
        let fileManager = config.fileManager
        let path = directoryURL.path

        guard !config.fileManager.fileExists(atPath: path) else { return }

        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            throw KingfisherError.cacheError(reason: .cannotCreateDirectory(error: error, path: path))
        }
    }

    func store(
        value: T,
        forKey key: String,
        expiration: StorageExpiration? = nil) throws
    {
        let object = StorageObject(value, expiration: expiration ?? config.expiration)
        let data: Data
        do {
            data = try value.toData()
        } catch {
            throw KingfisherError.cacheError(reason: .cannotConvertToData(object: value, error: error))
        }

        let fileURL = cacheFileURL(forKey: key)

        let now = Date()
        let attributes: [FileAttributeKey : Any] = [
            .creationDate: now,
            .modificationDate: object.estimatedExpiration
        ]
        config.fileManager.createFile(atPath: fileURL.path, contents: data, attributes: attributes)
    }

    func value(forKey key: String) throws -> T? {
        return try value(forKey: key, actuallyLoad: true)
    }

    func value(forKey key: String, actuallyLoad: Bool) throws -> T? {
        let fileManager = config.fileManager
        let fileURL = cacheFileURL(forKey: key)
        let filePath = fileURL.path
        guard fileManager.fileExists(atPath: filePath) else {
            return nil
        }

        let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey]
        do {
            let meta = try fileURL.resourceValues(forKeys: resourceKeys)
            guard let expiration = meta.contentModificationDate else {
                throw KingfisherError.cacheError(reason: .invalidModificationDate(key: key, url: fileURL))
            }
            guard expiration.isFuture else {
                return nil
            }
            if actuallyLoad {
                let data = try Data(contentsOf: fileURL)
                return try T.fromData(data)
            } else {
                return T.empty
            }
        } catch {
            throw KingfisherError.cacheError(
                reason: .invalidURLResource(error: error, key: key, url: fileURL, resourceKeys: resourceKeys))
        }
    }

    func isCached(forKey key: String) -> Bool {
        do {
            guard let _ = try value(forKey: key, actuallyLoad: false) else { return false }
            return true
        } catch {
            return false
        }
    }

    func extendExpriration(forKey key: String, lastAccessDate: Date, nextExpiration: StorageExpiration) throws {
        let fileURL = cacheFileURL(forKey: key)
        let attributes: [FileAttributeKey : Any] = [
            .creationDate: lastAccessDate,
            .modificationDate: nextExpiration.dateSince(lastAccessDate)
        ]
        try config.fileManager.setAttributes(attributes, ofItemAtPath: fileURL.path)
    }

    func remove(forKey key: String) throws {
        let fileURL = cacheFileURL(forKey: key)
        try removeFile(at: fileURL)
    }

    func removeFile(at url: URL) throws {
        try config.fileManager.removeItem(at: url)
        onFileRemoved.call(url)
    }

    func removeAll() throws {
        try removeAll(skipCreatingDirectory: false)
    }

    func removeAll(skipCreatingDirectory: Bool) throws {
        try config.fileManager.removeItem(at: directoryURL)
        onCacheRemoved.call()
        if !skipCreatingDirectory {
            try prepareDirectory()
        }
    }

    func cacheFileURL(forKey key: String) -> URL {
        let fileName = cacheFileName(forKey: key)
        return directoryURL.appendingPathComponent(fileName)
    }

    func cacheFileName(forKey key: String) -> String {
        let hashedKey = key.kf.md5
        if let ext = config.pathExtension {
            return "\(hashedKey).\(ext)"
        }
        return hashedKey
    }

    func allFileURLs(for propertyKeys: [URLResourceKey]) throws -> [URL] {
        let fileManager = config.fileManager
        guard let directoryEnumerator = fileManager.enumerator(
            at: directoryURL, includingPropertiesForKeys: propertyKeys, options: .skipsHiddenFiles) else
        {
            throw KingfisherError.cacheError(reason: .fileEnumeratorCreationFailed(url: directoryURL))
        }

        guard let urls = directoryEnumerator.allObjects as? [URL] else {
            throw KingfisherError.cacheError(reason: .invalidFileEnumeratorContent(url: directoryURL))
        }
        return urls
    }

    func removeExpiredValues() throws -> [URL] {
        let propertyKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .contentModificationDateKey
        ]

        let urls = try allFileURLs(for: propertyKeys)
        let keys = Set(propertyKeys)
        let expiredFiles = urls.filter { fileURL in
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: keys)
                if resourceValues.isDirectory == true {
                    return false
                }
                if let modificationDate = resourceValues.contentModificationDate {
                    return modificationDate.isPast
                }
                return true
            } catch {
                return true
            }
        }
        try expiredFiles.forEach { url in
            try removeFile(at: url)
        }
        return expiredFiles
    }

    func removeSizeExceededValues() throws -> [URL] {

        if config.sizeLimit == 0 { return [] } // Back compatible. 0 means no limit.
        
        var size = try totalSize()
        if size < config.sizeLimit { return [] }

        let propertyKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .creationDateKey,
            .totalFileAllocatedSizeKey
        ]
        let keys = Set(propertyKeys)

        let urls = try allFileURLs(for: propertyKeys)
        var pendings: [(url: URL, meta: URLResourceValues)] = urls.compactMap { fileURL in
            guard let resourceValues = try? fileURL.resourceValues(forKeys: keys) else {
                return nil
            }
            return (url: fileURL, meta: resourceValues)
        }
        let distancePast = Date.distantPast
        pendings.sort {
            $0.meta.creationDate ?? distancePast > $1.meta.creationDate ?? distancePast
        }
        var removed: [URL] = []
        let target = config.sizeLimit / 2
        while size >= target, let item = pendings.popLast() {
            size -= UInt(item.meta.totalFileAllocatedSize ?? 0)
            try removeFile(at: item.url)
            removed.append(item.url)
        }
        return removed
    }

    func totalSize() throws -> UInt {
        let propertyKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .totalFileAllocatedSizeKey
        ]
        let urls = try allFileURLs(for: propertyKeys)
        let keys = Set(propertyKeys)
        let totalSize: UInt = urls.reduce(0) { size, fileURL in
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: keys)
                return size + UInt(resourceValues.totalFileAllocatedSize ?? 0)
            } catch {
                return size
            }
        }
        return totalSize
    }
}
