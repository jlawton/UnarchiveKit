//
//  ArchiveFormats.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

enum ArchiveFormat {
    case ZIP
    case RAR
    case _7Z
    case TAR
}

// ------------------------------------------------------ Common file extensions

private let commonArchiveExtensions: [String: ArchiveFormat] = [
    "zip": .ZIP, "cbz": .ZIP, "jar": .ZIP, "epub": .ZIP,
    "rar": .RAR, "cbr": .RAR,
    "7z": ._7Z, "cb7": ._7Z,
    "tar": .TAR,
]

func guessFormatFromName(url: URL) -> ArchiveFormat? {
    let ext = url.pathExtension.lowercased()
    return commonArchiveExtensions[ext]
}

// ----------------------------------------------------------------- Magic bytes

private let magicBytes: [([UInt8], ArchiveFormat)] = [
    ([0x50, 0x4B, 0x03, 0x04], .ZIP),
    ([0x50, 0x4B, 0x05, 0x06], .ZIP),
    ([0x50, 0x4B, 0x07, 0x08], .ZIP),
    ([0x52, 0x61, 0x72, 0x21], .RAR),
    ([0x37, 0x7A, 0xBC, 0xAF], ._7Z),
    ([0x75, 0x73, 0x74, 0x61], .TAR),
    ([0x50, 0x61, 0x78, 0x48], .TAR),
]

func guessFormatFromMagicBytes(url: URL) throws -> ArchiveFormat? {
    let f = try FileHandle(forReadingFrom: url)
    // This should be long enough to encompass all of the magic bytes
    let data = f.readData(ofLength: 16)
    f.closeFile()

    return guessFormatFromMagicBytes(data: data)
}

func guessFormatFromMagicBytes(data: Data) -> ArchiveFormat? {
    var bytes = [UInt8](repeating: 0, count: 4)
    data.copyBytes(to: &bytes, count: 4 * MemoryLayout<UInt8>.size)

    for (magic, format) in magicBytes {
        assert(magic.count == 4)
        if magic == bytes {
            return format
        }
    }
    return nil
}
