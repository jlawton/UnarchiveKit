//
//  RarArchive.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/20/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation
import UnrarFW4iOS

final class RarArchive: FileArchive {
    let rar = Unrar4iOS()

    init(url: URL) throws {
        guard url.isFileURL else {
            throw RarArchiveError.ReadError
        }
        if !rar.unrarOpenFile(url.path) {
            throw RarArchiveError.ReadError
        }
    }

    func allFiles() throws -> [ArchivedFileInfo] {
        var files: [ArchivedFileInfo] = []
        let ok = rar.enumerateFiles(withDirectories: false) { (path: String, size: UInt64) in
            if UIntMax(size) < UIntMax(Int.max),
                let f = RarFileInfo(path: path, fileSize: Int(size))
            {
                files.append(f)
            }
        }

        guard ok else {
            throw RarArchiveError.ReadError
        }

        return files
    }

    // To support large files, we should stream properly
    func extractDataStream(fileInfo: ArchivedFileInfo) throws -> InputStream {
        let data = try extractData(fileInfo: fileInfo)
        return InputStream(data: data)
    }

    func extractData(fileInfo: ArchivedFileInfo) throws -> Data {
        guard let info = fileInfo as? RarFileInfo else {
            throw RarArchiveError.BadFileInfo
        }
        guard let data = rar.extractStream(info.originalPath) else {
            throw RarArchiveError.ReadError
        }
        return data
    }
}

struct RarFileInfo: ArchivedFileInfo {
    let path: ArchivedFilePath
    let originalPath: String
    let fileSize: Int

    init?(path: String, fileSize: Int) {
        self.originalPath = path
        self.path = ArchivedFilePath(path)
        self.fileSize = fileSize
    }
}

enum RarArchiveError: Error {
    case ReadError
    case BadFileInfo
}
