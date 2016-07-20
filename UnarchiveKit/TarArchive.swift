//
//  TarArchive.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

final class TarArchive: FileArchive {

    private let source: TarSource

    init(data: Data) {
        source = TarDataSource(data: data)
    }

    init(url: URL) throws {
        source = try TarFileSource(url: url)
    }

    func allFiles() -> [ArchivedFileInfo] {
        var files: [ArchivedFileInfo] = []
        var i = 0
        while i < source.blockCount {
            guard let block = source.dataBlock(i) else { return files }
            guard let header = TarBlockHeader(data: block) else {
                i += 1
                continue
            }
            guard header.type == .Normal else {
                i += 1
                continue
            }

            let offset = (i + 1) * TarBlockSize
            if let f = TarFileInfo(path: ArchivedFilePath(header.fileName), offset: offset, fileSize: header.fileSize) {
                files.append(f)
            }
            i += 1 + Int(ceil(Double(header.fileSize) / Double(TarBlockSize)))
        }
        return files
    }

    // To support large files, we should stream properly
    func extractDataStream(fileInfo: ArchivedFileInfo) throws -> InputStream {
        let data = try extractData(fileInfo: fileInfo)
        return InputStream(data: data)
    }

    func extractData(fileInfo: ArchivedFileInfo) throws -> Data {
        guard let info = fileInfo as? TarFileInfo else {
            throw TarArchiveError.BadFileInfo
        }

        return source.fileData(fileInfo: info)
    }
}

struct TarFileInfo: ArchivedFileInfo {
    let path: ArchivedFilePath
    let offset: Int
    let fileSize: Int

    init?(path: ArchivedFilePath, offset: Int, fileSize: Int) {
        if offset < 0 || fileSize < 0 {
            return nil
        }

        self.path = path
        self.offset = offset
        self.fileSize = fileSize
    }
}

enum TarArchiveError: ErrorProtocol {
    case BadFileInfo
}
