//
//  ArchivedFilePath.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

public struct ArchivedFilePath {
    private let path: String

    init(_ path: String) {
        self.path = path
    }

    // This may not give a true representation of a path, but at least it
    // shouldn't be possible to use this to write to arbitrary locations
    // (save for going through links)
    var safeRelativePath: String? {
        var output: [String] = []
        for c in self.path.components(separatedBy: "/") {
            switch c {
                // Remove initial '/' and empty components
                case "", ".": break
                // Go up, but never more than we've gone down
                case "..":
                    if output.count > 0 {
                        output.removeLast()
                    }
                // Go down
                default:
                    output.append(c)
            }
        }
        // If anything is left, we have a sanitized relative path
        if output.count > 0 {
            return output.joined(separator: "/")
        }
        // Otherwise, it's a dangerous path
        return nil
    }
}
