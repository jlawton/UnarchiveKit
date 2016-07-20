//
//  TarBlockHeader.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

let TarBlockSize = 512

struct TarBlockHeader {
    enum BlockType { case Normal, Other, Zero }
    let type: BlockType
    let fileName: String
    let fileSize: Int

    init?(data: Data) {
        guard data.count == TarBlockSize else { return nil }

        var blockType: BlockType = .Other
        var name: String = ""
        var size: Int = 0
        data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) in
            // Check if this block is for a normal file or something else
            let type = bytes[156]
            if type == 0 {
                for x in 0..<TarBlockSize {
                    blockType = .Zero
                    if bytes[x] != 0 {
                        blockType = .Normal
                        break
                    }
                }
            } else if type == 0x30 || type == 0x37 {
                blockType = .Normal
            } else {
                blockType = .Other
            }

            // File size (octal)
            var sizeBytes = [Int8](repeating: 0, count: 13)
            memcpy(&sizeBytes, bytes + 124, 12)
            size = strtol(sizeBytes, nil, 8)

            // Name
            var nameBytes = [Int8](repeating: 0, count: 256)
            strncpy(&nameBytes, bytes + 345, 155)
            strncat(&nameBytes, bytes + 0, 100)

            if let nameString = String(validatingUTF8: nameBytes) {
                name = nameString
            }
        }

        type = blockType
        fileName = name
        fileSize = size
    }
}
