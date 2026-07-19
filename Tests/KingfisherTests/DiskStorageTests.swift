//
//  DiskStorageTests.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/11/12.
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

import XCTest
@testable import Kingfisher

#if compiler(>=6)
extension String: @retroactive DataTransformable { }
#else
extension String: DataTransformable { }
#endif
extension String {
    public func toData() throws -> Data {
        return data(using: .utf8)!
    }
    public static func fromData(_ data: Data) throws -> String {
        return String(data: data, encoding: .utf8)!
    }
    public static var empty: String { return "" }
}

// Reports the given paths as existing regardless of the disk state, so tests can separate the
// "file exists but its metadata is unreadable" case from the "file is missing" one.
private final class FileExistsLyingFileManager: FileManager, @unchecked Sendable {
    private let lock = NSLock()
    private var lyingPaths = Set<String>()

    func lieAboutExistence(ofPath path: String) {
        lock.lock()
        lyingPaths.insert(path)
        lock.unlock()
    }

    override func fileExists(atPath path: String) -> Bool {
        lock.lock()
        let lying = lyingPaths.contains(path)
        lock.unlock()
        return lying || super.fileExists(atPath: path)
    }
}

private final class DelayedDirectoryScanFileManager: FileManager, @unchecked Sendable {
    private let scanStarted = DispatchSemaphore(value: 0)
    private let releaseScan = DispatchSemaphore(value: 0)
    private let lock = NSLock()

    private var shouldDelayNextScan = true
    private var delayedResult: [String] = []

    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        lock.lock()
        let shouldDelay = shouldDelayNextScan
        if shouldDelay {
            shouldDelayNextScan = false
        }
        lock.unlock()

        guard shouldDelay else {
            return try super.contentsOfDirectory(atPath: path)
        }

        scanStarted.signal()
        releaseScan.wait()

        lock.lock()
        let result = delayedResult
        lock.unlock()
        return result
    }

    func waitUntilScanStarts(timeout: TimeInterval = 2) -> Bool {
        scanStarted.wait(timeout: .now() + timeout) == .success
    }

    func finishDelayedScan(returning result: [String]) {
        lock.lock()
        delayedResult = result
        lock.unlock()
        releaseScan.signal()
    }
}

class DiskStorageTests: XCTestCase {

    var storage: DiskStorage.Backend<String>!

    override func setUp() {
        super.setUp()

        let uuid = UUID().uuidString
        let config = DiskStorage.Config(name: "test-\(uuid)", sizeLimit: 5)
        storage = try! DiskStorage.Backend<String>(config: config)
    }

    override func tearDown() {
        try! storage.removeAll(skipCreatingDirectory: true)
        super.tearDown()
    }

    func testStoreAndGet() {
        XCTAssertFalse(storage.isCached(forKey: "1"))
        try! storage.store(value: "1", forKey: "1")
        XCTAssertTrue(storage.isCached(forKey: "1"))
        let value = try! storage.value(forKey: "1")
        XCTAssertEqual(value, "1")
    }

    func testStoreAndGetWhenInitialCacheScanFinishesAfterStore() {
        let fileManager = DelayedDirectoryScanFileManager()
        let config = DiskStorage.Config(name: "test-\(UUID().uuidString)", sizeLimit: 5, fileManager: fileManager)
        let storage = try! DiskStorage.Backend<String>(config: config)
        defer { try? storage.removeAll(skipCreatingDirectory: true) }

        XCTAssertTrue(fileManager.waitUntilScanStarts())

        try! storage.store(value: "1", forKey: "1")
        fileManager.finishDelayedScan(returning: [])

        let deadline = Date().addingTimeInterval(2)
        var initialScanApplied = false
        repeat {
            initialScanApplied = storage.maybeCachedCheckingQueue.sync {
                storage.maybeCached != nil
            }
            if !initialScanApplied {
                Thread.sleep(forTimeInterval: 0.001)
            }
        } while !initialScanApplied && Date() < deadline

        XCTAssertTrue(initialScanApplied)
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertEqual(try! storage.value(forKey: "1"), "1")
    }

    func testRemove() {
        XCTAssertFalse(storage.isCached(forKey: "1"))
        try! storage.store(value: "1", forKey: "1")
        try! storage.remove(forKey: "1")
        XCTAssertFalse(storage.isCached(forKey: "1"))
    }

    func testRemoveAll() {
        try! storage.store(value: "1", forKey: "1")
        try! storage.store(value: "2", forKey: "2")
        try! storage.store(value: "3", forKey: "3")

        try! storage.removeAll()
        XCTAssertFalse(storage.isCached(forKey: "1"))
        XCTAssertFalse(storage.isCached(forKey: "2"))
        XCTAssertFalse(storage.isCached(forKey: "3"))
    }

    func testTotalSize() {
        var size = try! storage.totalSize()
        XCTAssertEqual(size, 0)

        try! storage.store(value: "1", forKey: "1")

        size = try! storage.totalSize()
        XCTAssertEqual(size, 1)
    }

    func testSetExpiration() {
        let now = Date()

        try! storage.store(value: "1", forKey: "1", expiration: .seconds(1))

        XCTAssertTrue(storage.isCached(forKey: "1", referenceDate: now))
        XCTAssertFalse(storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(5)))
    }

    func testConfigExpiration() {

        let now = Date()

        storage.config.expiration = .seconds(1)
        try! storage.store(value: "1", forKey: "1")
        XCTAssertTrue(storage.isCached(forKey: "1", referenceDate: now))
        XCTAssertFalse(storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(5)))
    }

    func testExtendExpirationByAccessing() {

        let exp = expectation(description: #function)
        let now = Date()
        try! storage.store(value: "1", forKey: "1", expiration: .seconds(2))
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertFalse(storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(5)))

        delay(1) {
            let v = try! self.storage.value(forKey: "1")
            XCTAssertNotNil(v)
            // The meta extending happens on its own queue.
            self.storage.metaChangingQueue.async {
                XCTAssertTrue(self.storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(3)))
                XCTAssertFalse(self.storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(10)))
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testNotExtendExpirationByAccessing() {

        let exp = expectation(description: #function)
        let now = Date()
        try! storage.store(value: "1", forKey: "1", expiration: .seconds(2))
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertFalse(storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(3)))

        delay(1) {
            let v = try! self.storage.value(forKey: "1", extendingExpiration: .none)
            XCTAssertNotNil(v)
            // The meta extending happens on its own queue.
            self.storage.metaChangingQueue.async {
                XCTAssertFalse(self.storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(3)))
                XCTAssertFalse(self.storage.isCached(forKey: "1", referenceDate: now.addingTimeInterval(10)))
                exp.fulfill()
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testRemoveExpired() {

        let expiration = StorageExpiration.seconds(1)
        try! storage.store(value: "1", forKey: "1", expiration: expiration)
        try! storage.store(value: "2", forKey: "2", expiration: expiration)
        try! storage.store(value: "3", forKey: "3")

        let urls = try! self.storage.removeExpiredValues(referenceDate: Date().addingTimeInterval(2))
        XCTAssertEqual(urls.count, 2)

        XCTAssertTrue(self.storage.isCached(forKey: "3"))
    }

    func testRemoveSizeExceeded() {
        let count = 10
        for i in 0..<count {
            let s = String(i)
            try! storage.store(value: s, forKey: s)
        }

        let urls = try! storage.removeSizeExceededValues()
        XCTAssertTrue(urls.count < count)
        XCTAssertTrue(urls.count > 0)
    }

    func testConfigUsesHashedFileName() {
        let key = "test"

        // hashed fileName
        storage.config.usesHashedFileName = true
        let hashedFileName = storage.cacheFileName(forKey: key)
        XCTAssertNotEqual(hashedFileName, key)
        // validation sha256 hash of the key
        XCTAssertEqual(hashedFileName, key.kf.sha256)

        // fileName without hash
        storage.config.usesHashedFileName = false
        let originalFileName = storage.cacheFileName(forKey: key)
        XCTAssertEqual(originalFileName, key)
    }

    func testConfigUsesHashedFileNameWithAutoExt() {
        let key = "test.gif"

        // hashed fileName
        storage.config.usesHashedFileName = true
        storage.config.autoExtAfterHashedFileName = true
        let hashedFileName = storage.cacheFileName(forKey: key)
        XCTAssertNotEqual(hashedFileName, key)
        // validation sha256 hash of the key
        XCTAssertEqual(hashedFileName, key.kf.sha256 + ".gif")

        // fileName without hash
        storage.config.usesHashedFileName = false
        let originalFileName = storage.cacheFileName(forKey: key)
        XCTAssertEqual(originalFileName, key)
    }
    
    func testConfigUsesHashedFileNameWithAutoExtAndProcessor() {
        // The key of an image with processor will be as this format.
        let key = "test.jpeg@com.onevcat.Kingfisher.DownsamplingImageProcessor"
        
        // hashed fileName
        storage.config.usesHashedFileName = true
        storage.config.autoExtAfterHashedFileName = true
        let hashedFileName = storage.cacheFileName(forKey: key)
        XCTAssertNotEqual(hashedFileName, key)
        // validation sha256 hash of the key
        XCTAssertEqual(hashedFileName, key.kf.sha256 + ".jpeg")

        // fileName without hash
        storage.config.usesHashedFileName = false
        let originalFileName = storage.cacheFileName(forKey: key)
        XCTAssertEqual(originalFileName, key)
    }

    // Regression test for https://github.com/onevcat/Kingfisher/issues/2301
    //
    // When the URL path itself contains `@`, the extracted "extension" used to contain a
    // path separator (`net/57373197`), producing a nonexistent sub-directory path as the
    // cache file name and silently breaking disk caching. Such keys should fall back to
    // an extension-less hashed file name.
    func testConfigUsesHashedFileNameWithAutoExtAndAtSignInPath() {
        let key = "https://t.furaffinity.net/57373197@300-1720981878.jpg"

        storage.config.usesHashedFileName = true
        storage.config.autoExtAfterHashedFileName = true
        let hashedFileName = storage.cacheFileName(forKey: key)
        XCTAssertEqual(hashedFileName, key.kf.sha256)
        XCTAssertFalse(hashedFileName.contains("/"))

        // The broken file name made every write fail, so pin the whole roundtrip too.
        try! storage.store(value: "1", forKey: key)
        XCTAssertTrue(storage.isCached(forKey: key))
        XCTAssertEqual(try! storage.value(forKey: key), "1")
    }

    // A query string makes the trailing part an implausible extension (`jpg?v=2`), so the
    // hashed file name should contain no extension instead of a raw query-carrying one.
    func testConfigUsesHashedFileNameWithAutoExtAndQueryString() {
        let key = "https://example.com/image.jpg?v=2"

        storage.config.usesHashedFileName = true
        storage.config.autoExtAfterHashedFileName = true
        let hashedFileName = storage.cacheFileName(forKey: key)
        XCTAssertEqual(hashedFileName, key.kf.sha256)
    }

    // The value lookup reads the file metadata directly and treats a missing file as a normal cache miss,
    // without a separate `fileExists` check. Removing the file behind the storage keeps its name in the
    // `maybeCached` shortcut, so the lookup must reach the metadata reading and observe the missing file there.
    func testValueForFileRemovedBehindStorageIsMiss() {
        try! storage.store(value: "1", forKey: "1")
        XCTAssertTrue(storage.isCached(forKey: "1"))

        let fileURL = storage.cacheFileURL(forKey: "1")
        try! FileManager.default.removeItem(at: fileURL)

        XCTAssertFalse(storage.isCached(forKey: "1"))
        XCTAssertNil(try! storage.value(forKey: "1"))
    }

    // When the metadata reading fails for a reason other than a missing file (here: no search permission on
    // the containing directory) and the file cannot be confirmed on disk either, the lookup reports a miss
    // instead of throwing.
    func testValueWithUnreadableDirectoryReportsMiss() throws {
        try XCTSkipIf(geteuid() == 0, "File permissions are not effective for root.")

        let config = DiskStorage.Config(name: "test-\(UUID().uuidString)", sizeLimit: 5)
        let storage = try DiskStorage.Backend<String>(config: config)
        try storage.store(value: "1", forKey: "1")

        let directoryPath = storage.directoryURL.path
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: directoryPath)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directoryPath)
            try? storage.removeAll(skipCreatingDirectory: true)
        }

        XCTAssertFalse(storage.isCached(forKey: "1"))
        XCTAssertNil(try storage.value(forKey: "1"))
    }

    // Once the initial directory scan is applied, a key that was never stored is answered from the
    // `maybeCached` shortcut without any disk touch. The scan bookkeeping is driven directly to keep the
    // shortcut state deterministic regardless of the background scan timing.
    func testMissForUnknownKeyAfterInitialScanApplied() {
        storage.maybeCachedCheckingQueue.sync {
            storage.maybeCached = []
            storage.maybeCachedSetupCompleted = true
        }

        XCTAssertFalse(storage.isCached(forKey: "never-stored"))
        XCTAssertNil(try! storage.value(forKey: "never-stored"))
    }

    // A file whose metadata is readable but whose content is not fails the actual loading, not the probe.
    func testValueWithUnreadableFileDataThrows() throws {
        try XCTSkipIf(geteuid() == 0, "File permissions are not effective for root.")

        try storage.store(value: "1", forKey: "1")
        let filePath = storage.cacheFileURL(forKey: "1").path
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: filePath)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: filePath)
        }

        // The existence probe reads only metadata, so it still reports a hit.
        XCTAssertTrue(storage.isCached(forKey: "1"))
        XCTAssertThrowsError(try storage.value(forKey: "1")) { error in
            guard case KingfisherError.cacheError(reason: .cannotLoadDataFromDisk) = error else {
                XCTFail("Expected cannotLoadDataFromDisk, but got \(error)")
                return
            }
        }
    }

    // A file that is confirmed on disk but whose metadata cannot be read keeps failing with
    // `invalidURLResource`, as it did when `fileExists` guarded the metadata reading.
    func testValueWithUnreadableMetadataOnExistingFileThrows() throws {
        try XCTSkipIf(geteuid() == 0, "File permissions are not effective for root.")

        let fileManager = FileExistsLyingFileManager()
        let config = DiskStorage.Config(
            name: "test-\(UUID().uuidString)", sizeLimit: 5, fileManager: fileManager
        )
        let storage = try DiskStorage.Backend<String>(config: config)
        try storage.store(value: "1", forKey: "1")
        fileManager.lieAboutExistence(ofPath: storage.cacheFileURL(forKey: "1").path)

        let directoryPath = storage.directoryURL.path
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: directoryPath)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directoryPath)
            try? storage.removeAll(skipCreatingDirectory: true)
        }

        XCTAssertThrowsError(try storage.value(forKey: "1")) { error in
            guard case KingfisherError.cacheError(reason: .invalidURLResource) = error else {
                XCTFail("Expected invalidURLResource, but got \(error)")
                return
            }
        }
    }

    func testValueOnNotReadyStorageThrows() {
        let fileManager = FileManager.default
        let fileBlockingDirectory = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent(UUID().uuidString)
        fileManager.createFile(atPath: fileBlockingDirectory.path, contents: Data())
        defer { try? fileManager.removeItem(at: fileBlockingDirectory) }

        // Creating the storage folder under a regular file fails, which marks the storage as not ready.
        let config = DiskStorage.Config(name: "test", sizeLimit: 5, directory: fileBlockingDirectory)
        let storage = DiskStorage.Backend<String>(noThrowConfig: config, creatingDirectory: true)

        XCTAssertFalse(storage.isCached(forKey: "1"))
        XCTAssertThrowsError(try storage.value(forKey: "1")) { error in
            guard case KingfisherError.cacheError(reason: .diskStorageIsNotReady) = error else {
                XCTFail("Expected diskStorageIsNotReady, but got \(error)")
                return
            }
        }
    }

    func testIsFileMissingError() {
        XCTAssertTrue((CocoaError(.fileReadNoSuchFile) as Error).isFileMissing)
        XCTAssertFalse((CocoaError(.fileReadNoPermission) as Error).isFileMissing)
        // The code alone is not enough: the domain has to match too.
        XCTAssertFalse(
            (NSError(domain: NSPOSIXErrorDomain, code: NSFileReadNoSuchFileError) as Error).isFileMissing
        )
    }

    func testFileMetaOrder() {
        let urls = [URL(string: "test1")!, URL(string: "test2")!, URL(string: "test3")!]

        let now = Date()

        let file1 = DiskStorage.FileMeta(
            fileURL: urls[0],
            lastAccessDate: now,
            estimatedExpirationDate: now.addingTimeInterval(1),
            isDirectory: false,
            fileSize: 1)
        let file2 = DiskStorage.FileMeta(
            fileURL: urls[1],
            lastAccessDate: now.addingTimeInterval(1),
            estimatedExpirationDate: now.addingTimeInterval(2),
            isDirectory: false,
            fileSize: 1)
        let file3 = DiskStorage.FileMeta(
            fileURL: urls[2],
            lastAccessDate: now.addingTimeInterval(2),
            estimatedExpirationDate: now.addingTimeInterval(3),
            isDirectory: false,
            fileSize: 1)

        let ordered = [file2, file1, file3].sorted(by: DiskStorage.FileMeta.lastAccessDate)
        XCTAssertTrue(ordered[0].lastAccessDate! > ordered[1].lastAccessDate!)
        XCTAssertTrue(ordered[1].lastAccessDate! > ordered[2].lastAccessDate!)
    }
}
