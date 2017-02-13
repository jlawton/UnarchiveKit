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
        guard let filePaths = rar.unrarListFiles(withDirectories: false) else {
            throw RarArchiveError.ReadError
        }

        var files: [ArchivedFileInfo] = []
        for path in filePaths {
            if let path = path as? String,
               let f = RarFileInfo(path: path) {
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

    init?(path: String) {
        self.originalPath = path
        self.path = ArchivedFilePath(path)
    }
}

enum RarArchiveError: Error {
    case ReadError
    case BadFileInfo
}
