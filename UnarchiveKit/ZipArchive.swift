//
//  ZipArchive.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import minizip

final class ZipArchive: FileArchive {

    let zipURL: URL

    init(url: URL) throws {
        if url.path == nil || !FileManager.default().fileExists(atPath: url.path!) {
            throw ZipArchiveError.ReadError
        }
        zipURL = url
    }

    func allFiles() throws -> [ArchivedFileInfo] {
        guard let zip = unzOpen64(zipURL.path!) else {
            throw ZipArchiveError.ReadError
        }
        defer {
            unzClose(zip)
        }

        var files: [ArchivedFileInfo] = []
        try enumerateFiles(in: zip) { zip in
            if let f = try currentFileInfo(zip) {
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
        guard let info = fileInfo as? ZipFileInfo else {
            throw ZipArchiveError.BadFileInfo
        }

        guard let zip = unzOpen64(zipURL.path!) else {
            throw ZipArchiveError.ReadError
        }
        defer {
            unzClose(zip)
        }

        let status = unzLocateFile(zip, info.originalPath, nil)
        if status != UNZ_OK {
            throw ZipArchiveError.ArchivedFileNotFound
        }

        try openCurrentFile(zip)

        let data = try readCurrentFile(zip)

        if unzCloseCurrentFile(zip) == UNZ_CRCERROR {
            throw ZipArchiveError.ReadError
        }

        return data
    }

    // This should be faster than the default implementation
    // but has different semantics w.r.t. corrupted archives
    func extractFiles(toDirectory directory: URL, matching predicate: (fileInfo: ArchivedFileInfo) -> Bool) throws {
        try FileManager.default().createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

        guard let zip = unzOpen64(zipURL.path!) else {
            throw ZipArchiveError.ReadError
        }
        defer {
            unzClose(zip)
        }

        try enumerateFiles(in: zip) { zip in
            guard let fileInfo = try currentFileInfo(zip) else {
                return
            }
            guard predicate(fileInfo: fileInfo) else {
                return
            }
            guard let relativePath = fileInfo.path.safeRelativePath else {
                return
            }

            let outputPath = try directory.appendingPathComponent(relativePath)

            if let outputDirectory = try? outputPath.deletingLastPathComponent() {
                try FileManager.default().createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            }

            let data = try readCurrentFile(zip)
            try data.write(to: outputPath)
        }
    }

    // Private

    private func enumerateFiles(in zip: unzFile, block: @noescape (unzFile) throws -> Void) throws {
        if unzGoToFirstFile(zip) != UNZ_OK {
            throw ZipArchiveError.ReadError
        }

        while true {
            try openCurrentFile(zip)

            do {
                try block(zip)
            } catch {
                unzCloseCurrentFile(zip)
                throw error
            }

            if unzCloseCurrentFile(zip) == UNZ_CRCERROR {
                throw ZipArchiveError.ReadError
            }

            let status = unzGoToNextFile(zip)
            if status == UNZ_END_OF_LIST_OF_FILE {
                break
            }
            if status != UNZ_OK {
                throw ZipArchiveError.ReadError
            }
        }

    }

    private func openCurrentFile(_ zip: unzFile) throws {
        let status = unzOpenCurrentFile(zip)
        if status != UNZ_OK {
            throw ZipArchiveError.ReadError
        }
    }

}

private func currentFileInfo(_ zip: unzFile) throws -> ZipFileInfo? {
    var fileInfo = unz_file_info64()
    memset(&fileInfo, 0, sizeof(unz_file_info))

    // Get basic info
    let status = unzGetCurrentFileInfo64(zip, &fileInfo, nil, 0, nil, 0, nil, 0)
    if status != UNZ_OK {
        throw ZipArchiveError.ReadError
    }

    // Get the info again, this time with the file name buffer
    let fileNameSize = Int(fileInfo.size_filename) + 1
    var fileNameBuffer = [CChar](repeating: 0, count: fileNameSize)
    unzGetCurrentFileInfo64(zip, &fileInfo, &fileNameBuffer, UInt(fileNameSize), nil, 0, nil, 0)

    guard let fileName = String(validatingUTF8: fileNameBuffer)?.replacingOccurrences(of: "\\", with: "/") else {
        throw ZipArchiveError.ReadError
    }

    let isDirectory = fileName.hasSuffix("/")
    if isDirectory {
        return nil
    }

    return ZipFileInfo(path: fileName, fileSize: Int(fileInfo.uncompressed_size))
}

private func readCurrentFile(_ zip: unzFile) throws -> Data {
    let outputStream = NSOutputStream(toMemory: ())
    outputStream.open()

    var buffer = [UInt8](repeating: 0, count: 4096)

    while true {
        let readBytes = Int(unzReadCurrentFile(zip, &buffer, UInt32(buffer.count)))
        if readBytes > 0 {
            let written = outputStream.write(&buffer, maxLength: readBytes)
            if written != readBytes {
                throw DataStreamError.WriteError(outputStream.streamError)
            }
        } else if readBytes == 0 {
            break
        } else {
            throw ZipArchiveError.ReadError
        }
    }

    let data = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey.rawValue) as? Data
    outputStream.close()

    return data ?? Data()
}


struct ZipFileInfo: ArchivedFileInfo {
    let path: ArchivedFilePath
    let originalPath: String
    let fileSize: Int

    init?(path: String, fileSize: Int) {
        if fileSize < 0 {
            return nil
        }

        self.originalPath = path
        self.path = ArchivedFilePath(path)
        self.fileSize = fileSize
    }
}

enum ZipArchiveError: ErrorProtocol {
    case ReadError
    case BadFileInfo
    case ArchivedFileNotFound
}
