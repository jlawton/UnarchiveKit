# UnarchiveKit

An iOS framework, written in Swift, to provide a common interface for reading
files from archives.

Currently supports Zip and Tar files.

## Installation

Clone the repository, add the UnarchiveKit Xcode project to your workspace and
embed `UnarchiveKit.framework` in your target.

Or, use [Carthage](https://github.com/Carthage/Carthage), adding the following
to your `Cartfile`.

```
github "jlawton/UnarchiveKit"
```

## Usage

```swift
import UnarchiveKit
```

```swift
func extractFiles(from archiveURL: URL, to directoryURL: URL) throws {
    let archive: FileArchive = try openFileArchive(url: archiveURL)

    try archive.extractFiles(toDirectory: directoryURL) { f in
        !f.path.isProbablyMacOSJunk()
    }
}
```

```swift
func extractFileToMemory(from archiveURL: URL, filePath: String) throws -> Data? {
    let archive: FileArchive = try openFileArchive(url: archiveURL)

    if let file: ArchivedFileInfo = try archive.locateFile(path: filePath) {
        return try archive.extractData(fileInfo: file)
    }
    return nil
}
```

## Limitations

By design, `FileArchive` is only intended to deal with extracting normal files,
and will generally not preserve file permissions or other metadata when
extracting. Also, empty directories, links or other special files will not be
extracted.

The `tar` implementation is very basic, and doesn't parse POSIX.1-2001/pax
headers at the moment. The major consequence is that certain tar archives
containing files with non-ASCII paths, or paths longer than 100 ASCII characters,
may be extracted with incorrect or truncated file names.
