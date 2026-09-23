//
//  SendYUVShareAdapter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Darwin
import Foundation
import MobileRTC
import os

private let videoFps: Int = 30
private let videoUsecPerFps: useconds_t = useconds_t(1_000_000 / videoFps)
private let audioSampleRate: Int = 16000
private let audioBitDepth: Int = 16
private let audioChannelNum: Int = 2

final class SendYUVShareAdapter: NSObject, MobileRTCShareSourceDelegate, MobileRTCShareAudioSourceDelegate {

    var isSharing: Bool = false

    private var shareSender: MobileRTCShareSender?
    private var audioSender: MobileRTCShareAudioSender?
    private var videoThread: Thread?
    private var audioThread: Thread?
    private var width: Int = 640
    private var height: Int = 480

    deinit {
        stopVideo()
        stopAudio()
    }

    func onStartSend(_ sender: MobileRTCShareSender) {
        shareSender = sender
        width = 640
        height = 480
        beginPullVideo()
    }

    func onStopSend() {
        shareSender = nil
        stopVideo()
    }

    func onStartSendAudio(_ sender: MobileRTCShareAudioSender) {
        audioSender = sender
        beginPullAudio()
    }

    func onStopSendAudio() { stopAudio() }

    private func beginPullVideo() {
        isSharing = true
        guard videoThread == nil else { return }
        let thread = Thread(target: self, selector: #selector(pullVideoRunloop), object: nil)
        videoThread = thread
        thread.start()
    }

    @objc private func pullVideoRunloop() {
        guard let path = Bundle.main.path(forResource: "zoom_640X480", ofType: "yuv") else { return }
        let file = fopen(path, "rb")
        if file == nil { return }
        guard width > 0, height > 0 else { return }
        let frameSize = width * height * 3 / 2
        while !(Thread.current.isCancelled) {
            let frame = UnsafeMutablePointer<UInt8>.allocate(capacity: frameSize)
            let uAddress = width * height
            let vAddress = width * height * 5 / 4
            let s1 = fread(frame, 1, width * height, file)
            let s2 = fread(frame.advanced(by: uAddress), 1, width * height / 4, file)
            let s3 = fread(frame.advanced(by: vAddress), 1, width * height / 4, file)
            if s1 == 0 || s2 == 0 || s3 == 0 {
                frame.deallocate()
                rewind(file)
                continue
            }
            let w = width, h = height
            DispatchQueue.main.async { [weak self] in
                if let shareSender = self?.shareSender {
                    frame.withMemoryRebound(to: CChar.self, capacity: frameSize) { ptr in
                        shareSender.sendShareFrameBuffer(ptr, width: UInt(w), height: UInt(h), frameLength: UInt(frameSize), format: .I420)
                    }
                }
                frame.deallocate()
            }
            usleep(videoUsecPerFps)
        }
        fclose(file)
    }

    private func stopVideo() {
        isSharing = false
        videoThread?.cancel()
        videoThread = nil
    }

    private func beginPullAudio() {
        guard audioThread == nil else { return }
        let thread = Thread(target: self, selector: #selector(pullAudioRunloop), object: nil)
        audioThread = thread
        thread.start()
    }

    @objc private func pullAudioRunloop() {
        guard let path = Bundle.main.path(forResource: "16000_stereo", ofType: "wav") else { return }
        let file = fopen(path, "rb")
        if file == nil { return }
        let bytesPerSecond = audioBitDepth / 8 * audioSampleRate * audioChannelNum
        while !(Thread.current.isCancelled) {
            let frame = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerSecond)
            let size = fread(frame, audioBitDepth / 8, audioSampleRate * audioChannelNum, file)
            if size == 0 {
                frame.deallocate()
                rewind(file)
                continue
            }
            DispatchQueue.main.async { [weak self] in
                if let audioSender = self?.audioSender {
                    frame.withMemoryRebound(to: CChar.self, capacity: bytesPerSecond) { ptr in
                        _ = audioSender.sendShareAudio(ptr, dataLength: UInt(bytesPerSecond), sampleRate: UInt(audioSampleRate), audioChannel: .stereo)
                    }
                }
                frame.deallocate()
            }
            usleep(1_000_000)
        }
        fclose(file)
    }

    private func stopAudio() {
        audioThread?.cancel()
        audioThread = nil
    }
}
