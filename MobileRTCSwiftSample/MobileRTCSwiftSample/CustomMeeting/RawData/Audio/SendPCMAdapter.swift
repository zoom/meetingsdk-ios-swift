//
//  SendPCMAdapter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Darwin
import Foundation
import MobileRTC
import os

private let pcmSampleRate: Int = 44100
private let pcmBitDepth: Int = 16

final class SendPCMAdapter: NSObject, MobileRTCAudioSourceDelegate {

    private var audioSender: MobileRTCAudioSender?
    private var workThread: Thread?

    deinit { stop() }

    func onDeviceInitialize(_ rawdataSender: MobileRTCAudioSender) {
        audioSender = rawdataSender
    }

    func onStartSendData() { beginPullAudio() }

    func onStopSendData() { stop() }

    func onDeviceUninitialize() { audioSender = nil }

    private func beginPullAudio() {
        guard workThread == nil else { return }
        let thread = Thread(target: self, selector: #selector(pullRunloop), object: nil)
        workThread = thread
        thread.start()
    }

    @objc private func pullRunloop() {
        guard let path = Bundle.main.path(forResource: "test_16bit_44100", ofType: "wav") else { return }
        let file = fopen(path, "rb")
        if file == nil { return }
        let bytesPerSecond = pcmBitDepth / 8 * pcmSampleRate
        while !(Thread.current.isCancelled) {
            let frame = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerSecond)
            let size = fread(frame, pcmBitDepth / 8, pcmSampleRate, file)
            if size == 0 {
                frame.deallocate()
                rewind(file)
                continue
            }
            DispatchQueue.main.async { [weak self] in
                if let audioSender = self?.audioSender {
                    frame.withMemoryRebound(to: CChar.self, capacity: bytesPerSecond) { ptr in
                        _ = audioSender.send(ptr, dataLength: UInt32(bytesPerSecond), sampleRate: Int32(pcmSampleRate))
                    }
                }
                frame.deallocate()
            }
            usleep(1_000_000)
        }
        fclose(file)
    }

    private func stop() {
        workThread?.cancel()
        workThread = nil
    }
}
