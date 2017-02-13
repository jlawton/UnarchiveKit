//
//  InputStream+Data.swift
//  UnarchiveKit
//
//  Created by James Lawton on 7/19/16.
//  Copyright © 2016 James Lawton. All rights reserved.
//

import Foundation

enum DataStreamError: Error {
    case ReadError(Error?)
    case WriteError(Error?)
}

enum DataStreamResult {
    case Success(Data)
    case Failure(DataStreamError)
}

extension InputStream {

    func synchronouslyGetData() throws -> Data {
        let outputStream = OutputStream.init(toMemory: ())

        try synchronouslyWrite(to: outputStream, bufferSize: 4096)

        let data = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? Data
        return data ?? Data()
    }

    func synchronouslyWrite(url: URL, append: Bool = false) throws {
        if let outputStream = OutputStream(url: url, append: append) {
            try synchronouslyWrite(to: outputStream)
        } else {
            throw DataStreamError.WriteError(nil)
        }
    }

    func asynchronouslyGetData(in runLoop: RunLoop, complete: @escaping (DataStreamResult) -> Void) {
        let delegate = StreamDataDelegate(self, complete: complete)
        delegate.schedule(in: runLoop)
    }

    // Closes both input and output streams before completion
    // iOS uses 8K blocks for user file storage, so going with that by default
    private func synchronouslyWrite(to outputStream: OutputStream, bufferSize: Int = 8192) throws {
        open()
        defer {
            close()
        }

        outputStream.open()
        defer {
            outputStream.close()
        }

        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while true {
            let readBytes = self.read(&buffer, maxLength: buffer.count)
            if readBytes > 0 {
                if outputStream.write(&buffer, maxLength: readBytes) != readBytes {
                    throw DataStreamError.WriteError(outputStream.streamError)
                }
            } else if readBytes == 0 {
                break
            } else {
                throw DataStreamError.ReadError(streamError)
            }
        }
    }

}

// -------------------------------------------------- Private StreamDataDelegate

private class StreamDataDelegate: NSObject, StreamDelegate {
    private let inputStream: InputStream
    private let complete: (DataStreamResult) -> Void
    private var isComplete: Bool = false
    private let outputStream = OutputStream.init(toMemory: ())

    init(_ inputStream: InputStream, complete: @escaping (DataStreamResult) -> Void) {
        self.inputStream = inputStream
        self.complete = complete
    }

    func schedule(in runloop: RunLoop) {
        inputStream.delegate = self
        inputStream.schedule(in: runloop, forMode: RunLoopMode.defaultRunLoopMode)
        inputStream.open()
    }

    // StreamDelegate

    func stream(_ aStream: Stream, handle event: Stream.Event) {
        switch event {
        case Stream.Event.hasBytesAvailable:
            var buffer = [UInt8](repeating: 0, count: 4096)
            let readBytes = inputStream.read(&buffer, maxLength: buffer.count)
            if readBytes > 0 {
                if outputStream.write(&buffer, maxLength: readBytes) != readBytes {
                    doComplete(.Failure(DataStreamError.WriteError(outputStream.streamError)))
                }
            }

        case Stream.Event.endEncountered:
            let data = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? Data
            doComplete(.Success(data ?? Data()))

        case Stream.Event.errorOccurred:
            doComplete(.Failure(.ReadError(inputStream.streamError)))

        case Stream.Event.openCompleted: break
        case Stream.Event.hasSpaceAvailable: break
        default: break
        }
    }

    // Private

    private func doComplete(_ result: DataStreamResult) {
        if !isComplete {
            isComplete = true
            inputStream.delegate = nil
            inputStream.close()
            inputStream.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
            outputStream.close()
            complete(result)
        }
    }
}
