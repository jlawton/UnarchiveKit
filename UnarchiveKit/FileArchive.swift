//
//  FileArchive.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

/// A protocol describing multi-file archives
public protocol FileArchive {

    func allFiles() throws -> [ArchivedFileInfo]

    func extractDataStream(fileInfo: ArchivedFileInfo) throws -> InputStream

    // This has a default implementation based on `allFiles()`
    func filesMatching(_ predicate: (fileInfo: ArchivedFileInfo) -> Bool) throws -> [ArchivedFileInfo]

    // This has a default implementation based on `filesMatching(_:)`
    func locateFile(_ predicate: (fileInfo: ArchivedFileInfo) -> Bool) throws -> ArchivedFileInfo?

    // This has a default implementation based on `locateFile(_:)`
    func locateFile(path: String) throws -> ArchivedFileInfo?

    // This has a default implementation based on `locateFile(_:)`
    func locateFile(named name: String) throws -> ArchivedFileInfo?

    // This has a default implementation based on `extractDataStream(fileInfo:)`
    func extractData(fileInfo: ArchivedFileInfo) throws -> Data

    // This has a default implementation based on `extractDataStream(fileInfo:)`
    func extractFile(fileInfo: ArchivedFileInfo, to url: URL) throws

    // This has a default implementation based on `extractFiles(toDirectory:matching:)`
    func extractAllFiles(toDirectory directory: URL) throws

    // This has a default implementation based on `filesMatching(_:)` and `extractFile(fileInfo:url:)`
    func extractFiles(toDirectory directory: URL, matching predicate: (fileInfo: ArchivedFileInfo) -> Bool) throws

}

// A protocol describing a single archived file
public protocol ArchivedFileInfo {
    var path: ArchivedFilePath { get }
}

public func openFileArchive(url: URL) throws -> FileArchive {
    guard let format = try guessFormatFromMagicBytes(url: url) else {
        throw FileArchiveError.UnknownArchiveFormat
    }

    switch format {
    case .TAR: return try TarArchive(url: url)
    case .ZIP: return try ZipArchive(url: url)
    default: throw FileArchiveError.UnknownArchiveFormat
    }
}

enum FileArchiveError: ErrorProtocol {
    case UnknownArchiveFormat
}
