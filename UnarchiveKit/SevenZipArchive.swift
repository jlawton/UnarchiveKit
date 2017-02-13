//
//  SevenZipArchive.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/24/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import SevenZip

class SevenZipArchive: FileArchive {
    let archiveURL: URL
    private let archive: OpaquePointer?
    private var cache = SevenZipExtractCache_Init()

    deinit {
        resetCache()
        SevenZipFileArchive_Free(archive)
    }

    init(url: URL) throws {
        SevenZipInit()
        archiveURL = url
        guard url.isFileURL else {
            throw SevenZipArchiveError.ReadError
        }

        archive = SevenZipFileArchive_Open(url.path)
        guard archive != nil else {
            throw SevenZipArchiveError.ReadError
        }
    }

    func allFiles() throws -> [ArchivedFileInfo] {
        let N = SevenZipFileArchive_GetFileCount(archive)

        var files: [ArchivedFileInfo] = []
        var meta = SevenZipFileMetadata_Init()
        defer {
            SevenZipFileMetadata_Free(&meta)
        }

        for fileIndex in 0..<N {
            let err = SevenZipFileArchive_GetFileMetadata(archive, fileIndex, &meta)
            guard err == SZ_OK else {
                continue
            }
            guard let path = filePath(bytes: meta.nameUTF16LE, count: Int(meta.nameBytesCount)) else {
                continue
            }
            guard meta.isDirectory == 0 else {
                continue
            }
            if let f = SevenZipFileInfo(path: ArchivedFilePath(path), fileSize: meta.fileSize, fileIndex: fileIndex) {
                files.append(f)
            }
        }

        return files
    }

    // To support large files, we should stream properly
    func extractDataStream(fileInfo: ArchivedFileInfo) throws -> InputStream {
        let data = try extractData(fileInfo: fileInfo)
        return InputStream(data: data)
    }

    func extractData(fileInfo: ArchivedFileInfo) throws -> Data {
        guard let info = fileInfo as? SevenZipFileInfo else {
            throw SevenZipArchiveError.BadFileInfo
        }

        var extracted = SevenZipExtractedBlock()
        guard SevenZipFileArchive_Extract(archive, info.fileIndex, &cache, &extracted) == SZ_OK else {
            throw SevenZipArchiveError.ReadError
        }

        let data = Data(bytes: extracted.block, count: extracted.count)
        return data
    }

    private func filePath(bytes: UnsafeMutablePointer<UInt8>, count: Int) -> String? {
        let data = Data(bytesNoCopy: bytes, count: count, deallocator: .none)
        let decoded = String(data: data, encoding: String.Encoding.utf16LittleEndian)
        return decoded?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }

    private func resetCache() {
        SevenZipExtractCache_Free(&cache)
    }

}

struct SevenZipFileInfo: ArchivedFileInfo {
    let path: ArchivedFilePath
    let fileSize: Int
    let fileIndex: UInt32

    init?(path: ArchivedFilePath, fileSize: Int, fileIndex: UInt32) {
        if fileSize < 0 {
            return nil
        }

        self.path = path
        self.fileSize = fileSize
        self.fileIndex = fileIndex
    }
}

enum SevenZipArchiveError: Error {
    case ReadError
    case BadFileInfo
}
