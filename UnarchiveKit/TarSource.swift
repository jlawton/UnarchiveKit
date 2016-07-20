//
//  TarSource.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

protocol TarSource {
    func dataBlock(_ i: Int) -> Data?
    var blockCount: Int { get }
    func fileData(fileInfo: TarFileInfo) -> Data
}

struct TarDataSource: TarSource {
    let data: Data

    func dataBlock(_ i: Int) -> Data? {
        assert(i >= 0)

        let offset = i * TarBlockSize
        if offset < data.count {
            return data.subdata(in: offset..<(offset + TarBlockSize))
        }
        return nil
    }

    var blockCount: Int {
        return data.count / TarBlockSize
    }

    func fileData(fileInfo: TarFileInfo) -> Data {
        return data.subdata(in: fileInfo.offset..<(fileInfo.offset + fileInfo.fileSize))
    }
}

final class TarFileSource: TarSource {
    private let handle: FileHandle
    private let fileSize: UInt64

    init(url: URL) throws {
        handle = try FileHandle(forReadingFrom: url)
        handle.seekToEndOfFile()
        fileSize = handle.offsetInFile
    }

    func dataBlock(_ i: Int) -> Data? {
        assert(i >= 0)

        let offset = UInt64(i * TarBlockSize)
        if offset < fileSize {
            handle.seek(toFileOffset: offset)
            return handle.readData(ofLength: TarBlockSize)
        }
        return nil
    }

    var blockCount: Int {
        return Int(fileSize / UInt64(TarBlockSize))
    }

    func fileData(fileInfo: TarFileInfo) -> Data {
        if fileInfo.fileSize == 0 {
            return Data()
        }

        handle.seek(toFileOffset: UInt64(fileInfo.offset))
        return handle.readData(ofLength: fileInfo.fileSize)
    }
}
