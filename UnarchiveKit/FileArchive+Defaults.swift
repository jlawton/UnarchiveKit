//
//  FileArchive+Defaults.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

public extension FileArchive {

    func filesMatching(_ predicate: (ArchivedFileInfo) -> Bool) throws -> [ArchivedFileInfo] {
        return try allFiles().filter(predicate)
    }

    func locateFile(_ predicate: (ArchivedFileInfo) -> Bool) throws -> ArchivedFileInfo? {
        return try filesMatching(predicate).first
    }

    func locateFile(path: String) throws -> ArchivedFileInfo? {
        return try locateFile { fileInfo in
            fileInfo.path.path == path
        }
    }

    func locateFile(named name: String) throws -> ArchivedFileInfo? {
        return try locateFile { fileInfo in
            fileInfo.path.fileName == name
        }
    }

    func extractData(fileInfo: ArchivedFileInfo) throws -> Data {
        let stream = try extractDataStream(fileInfo: fileInfo)
        let data = try stream.synchronouslyGetData()
        return data
    }

    func extractFile(fileInfo: ArchivedFileInfo, to url: URL) throws {
        let stream = try extractDataStream(fileInfo: fileInfo)
        try stream.synchronouslyWrite(url: url)
    }

    func extractAllFiles(toDirectory directory: URL) throws {
        return try extractFiles(toDirectory: directory) { _ in return true }
    }

    func extractFiles(toDirectory directory: URL, matching predicate: (ArchivedFileInfo) -> Bool) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

        for file in try filesMatching(predicate) {
            if let relativePath = file.path.safeRelativePath {
                let outputPath = directory.appendingPathComponent(relativePath)
                try FileManager.default.createParentDirectory(url: outputPath)
                try autoreleasepool { try extractFile(fileInfo: file, to: outputPath) }
            }
        }
    }

    func subdirectory(_ path: String) throws -> FileArchive {
        let disallowed = ["", ".", "..", "/", "./", "../"]
        if disallowed.contains(path) {
            throw ArchiveSubdirectoryError.InvalidPath
        }
        return ArchiveSubdirectory(self, directory: path)
    }

}
