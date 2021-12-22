//
//  DirectoryArchive.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/20/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

struct DirectoryArchive: FileArchive {
    let directoryURL: URL

    init(url: URL) throws {
        guard FileManager.default.isDirectory(url: url) else {
            throw DirectoryArchiveError.DirectoryNotFound
        }
        directoryURL = url
    }

    func allFiles() throws -> [ArchivedFileInfo] {
        let subpaths = try FileManager.default.subpathsOfDirectory(atPath: directoryURL.path)

        var files: [ArchivedFileInfo] = []
        for p in subpaths {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: directoryURL.appendingPathComponent(p).path)
                if let type = (attrs[FileAttributeKey.type] as? FileAttributeType),
                    type == FileAttributeType.typeRegular
                {
                    let fileSize = (attrs[FileAttributeKey.size] as? Int) ?? 0
                    if let f = DirectoryFileInfo(path: ArchivedFilePath(p), fileSize: fileSize) {
                        files.append(f)
                    }
                }
            } catch {}
        }
        return files
    }

    func extractDataStream(fileInfo: ArchivedFileInfo) throws -> InputStream {
        guard let relativePath = fileInfo.path.safeRelativePath else {
            throw DirectoryArchiveError.ArchivedFileNotFound
        }
        let url = directoryURL.appendingPathComponent(relativePath, isDirectory: false)

        guard let stream = InputStream(url: url) else {
            throw DirectoryArchiveError.ArchivedFileNotFound
        }

        return stream
    }

    // This doesn't have quite the same semantics as the default implementation
    // when it comes to missing directories and non-canonical paths, but no
    // particular gurantees are provided in that regard.
    func subdirectory(_ path: String) throws -> DirectoryArchive {
        let withSlash = path.hasSuffix("/") ? path : path.appending("/")
        if withSlash.hasPrefix("/") ||
            withSlash.hasPrefix("../") ||
            withSlash.range(of: "/../") != nil
        {
            throw ArchiveSubdirectoryError.InvalidPath
        }
        let url = directoryURL.appendingPathComponent(path, isDirectory: true)
        return try DirectoryArchive(url: url)
    }

}

struct DirectoryFileInfo: ArchivedFileInfo {
    let path: ArchivedFilePath
    let fileSize: Int

    init?(path: ArchivedFilePath, fileSize: Int) {
        if fileSize < 0 {
            return nil
        }

        self.path = path
        self.fileSize = fileSize
    }
}

enum DirectoryArchiveError: Error {
    case DirectoryNotFound
    case DirectoryEnumerationError
    case ArchivedFileNotFound
}
