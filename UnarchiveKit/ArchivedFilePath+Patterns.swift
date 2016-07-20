//
//  ArchivedFilePath+Patterns.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/20/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

public extension ArchivedFilePath {

    func isProbablyMacOSJunk() -> Bool {
        guard let path = safeRelativePath?.components(separatedBy: "/") where path.count > 0 else {
            return false
        }

        if path.last! == ".DS_Store" {
            return true
        }
        if path.last!.hasPrefix("._") {
            return true
        }

        return false
    }

}
