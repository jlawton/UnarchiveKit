//
//  FileArchive+Defaults.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

public extension FileArchive {

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
        try FileManager.default().createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

        for file in allFiles() {
            if let relativePath = file.path.safeRelativePath {
                let outputPath = try directory.appendingPathComponent(relativePath)

                if let outputDirectory = try? outputPath.deletingLastPathComponent() {
                    try FileManager.default().createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
                }

                try extractFile(fileInfo: file, to: outputPath)
            }
        }
    }
    
}
