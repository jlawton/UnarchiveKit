//
//  FileManager+UnarchiveKit.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/20/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

extension FileManager {

    func isDirectory(url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return url.isFileURL
            && fileExists(atPath: url.path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    func createParentDirectory(url: URL) throws {
        let parent = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
    }

}
