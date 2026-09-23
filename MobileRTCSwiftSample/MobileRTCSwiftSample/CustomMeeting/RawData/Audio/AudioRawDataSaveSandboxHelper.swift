//
//  AudioRawDataSaveSandboxHelper.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Foundation
import MobileRTC

final class AudioRawDataSaveSandboxHelper {

    /// File to append raw PCM frames into. Setting a new value (or `nil`) closes
    /// the previously opened handle.
    var filePath: String? {
        didSet {
            if filePath != oldValue { closeHandle() }
        }
    }

    private var handle: FileHandle?

    deinit { closeHandle() }

    /// Closes the underlying file handle. Safe to call from `stop`/`onUninitialize`
    /// paths or to force a flush mid-recording.
    func close() { closeHandle() }

    func saveAudioRawdata(_ rawData: MobileRTCAudioRawData) {
        guard let path = filePath, let buffer = rawData.buffer else { return }
        guard let handle = openHandle(at: path) else { return }
        let data = Data(bytes: buffer, count: Int(rawData.bufferLen))
        do {
            try handle.write(contentsOf: data)
        } catch {
            // Best-effort: drop the frame and tear down so the next call retries open.
            closeHandle()
        }
    }

    private func openHandle(at path: String) -> FileHandle? {
        if let handle { return handle }
        let fm = FileManager.default
        if !fm.fileExists(atPath: path) {
            let dir = (path as NSString).deletingLastPathComponent
            try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
            guard fm.createFile(atPath: path, contents: nil) else { return nil }
        }
        guard let opened = FileHandle(forWritingAtPath: path) else { return nil }
        _ = try? opened.seekToEnd()
        handle = opened
        return opened
    }

    private func closeHandle() {
        try? handle?.synchronize()
        try? handle?.close()
        handle = nil
    }
}
