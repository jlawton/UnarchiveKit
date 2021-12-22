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

    /// Get information about all files available in the archive.
    func allFiles() throws -> [ArchivedFileInfo]

    /// Get a stream which provides the contents of the given archived file.
    ///
    /// - Parameter fileInfo: Must have been retrieved from this archive.
    func extractDataStream(fileInfo: ArchivedFileInfo) throws -> InputStream

    // This has a default implementation based on `allFiles()`
    /// Get information about all files matching the given predicate
    /// in the archive.
    func filesMatching(_ predicate: (ArchivedFileInfo) -> Bool) throws -> [ArchivedFileInfo]

    // This has a default implementation based on `filesMatching(_:)`
    /// Get the information of the first file matching the given predicate
    /// in the archive.
    func locateFile(_ predicate: (ArchivedFileInfo) -> Bool) throws -> ArchivedFileInfo?

    // This has a default implementation based on `locateFile(_:)`
    /// Get the information of the file at the given path
    /// in the archive.
    ///
    /// - Parameter path: The path of the file as stored in the archive.
    func locateFile(path: String) throws -> ArchivedFileInfo?

    // This has a default implementation based on `locateFile(_:)`
    /// Get the information of the first file with the given file name
    /// in the archive.
    ///
    /// - Parameter name: The last path component of the archived file.
    func locateFile(named name: String) throws -> ArchivedFileInfo?

    // This has a default implementation based on `extractDataStream(fileInfo:)`
    /// The contents of a file as data.
    ///
    /// - Parameter fileInfo: Must have been retrieved from this archive.
    func extractData(fileInfo: ArchivedFileInfo) throws -> Data

    // This has a default implementation based on `extractDataStream(fileInfo:)`
    /// Extract the contents of a file to disk.
    ///
    /// - Parameters:
    ///   - fileInfo: Must have been retrieved from this archive.
    ///   - url: A local file URL.
    func extractFile(fileInfo: ArchivedFileInfo, to url: URL) throws

    // This has a default implementation based on `extractFiles(toDirectory:matching:)`
    /// Extract the contents of all files in the archive to disk.
    ///
    /// - Parameters:
    ///   - directory: A local directory URL.
    func extractAllFiles(toDirectory directory: URL) throws

    // This has a default implementation based on `filesMatching(_:)` and `extractFile(fileInfo:url:)`
    /// Extract to disk the contents of all files in the archive which match
    /// the given predicate.
    ///
    /// - Parameters:
    ///   - directory: A local directory URL.
    ///   - predicate: Returns `true` iff the file matches.
    func extractFiles(toDirectory directory: URL, matching predicate: (ArchivedFileInfo) -> Bool) throws

    // This has a default implementation based on `ArchiveSubdirectory`
    /// An archive representing just the files within a subdirectory
    /// of this archive.
    ///
    /// - Parameter path: The path of a directory that exists in the archive.
    func subdirectory(_ path: String) throws -> FileArchive
}

// A protocol describing a single archived file
public protocol ArchivedFileInfo {
    var path: ArchivedFilePath { get }
}

/// Open a file archive, after attempting to discover its format automatically.
///
/// - Parameter url: The local URL of the archive.
public func openFileArchive(url: URL) throws -> FileArchive {
    if FileManager.default.isDirectory(url: url) {
        return try DirectoryArchive(url: url)
    }

    guard let format = try guessFormatFromMagicBytes(url: url) else {
        throw FileArchiveError.UnknownArchiveFormat
    }

    switch format {
    case .TAR: return try TarArchive(url: url)
    case .ZIP: return try ZipArchive(url: url)
    case .RAR: return try RarArchive(url: url)
    case ._7Z: return try SevenZipArchive(url: url)
//    default: throw FileArchiveError.UnknownArchiveFormat
    }
}

enum FileArchiveError: Error {
    case UnknownArchiveFormat
}
