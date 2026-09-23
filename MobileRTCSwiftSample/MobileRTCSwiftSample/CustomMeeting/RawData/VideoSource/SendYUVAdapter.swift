//
//  SendYUVAdapter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Darwin
import Foundation
import MobileRTC
import os

private let defaultFps: Int = 25
private let usecPerFps: useconds_t = useconds_t(1_000_000 / defaultFps)

final class SendYUVAdapter: NSObject, MobileRTCVideoSourceDelegate {

    private var videoSender: MobileRTCVideoSender?
    private var workThread: Thread?
    private var width: Int = 640
    private var height: Int = 480

    deinit { stop() }

    func onInitialize(_ rawDataSender: MobileRTCVideoSender,
                      supportCapabilityArray: [MobileRTCVideoCapabilityItem],
                      suggest suggestCapabilityItem: MobileRTCVideoCapabilityItem) {
        videoSender = rawDataSender
        width = 640
        height = 480
    }

    func onPropertyChange(_ supportCapabilityArray: [MobileRTCVideoCapabilityItem],
                          suggest suggestCapabilityItem: MobileRTCVideoCapabilityItem) {}

    func onStartSend() { beginPullVideo() }
    func onStopSend() { stop() }
    func onUninitialized() { videoSender = nil }

    private func beginPullVideo() {
        guard workThread == nil else { return }
        let thread = Thread(target: self, selector: #selector(pullRunloop), object: nil)
        workThread = thread
        thread.start()
    }

    @objc private func pullRunloop() {
        guard let path = Bundle.main.path(forResource: "zoom_640X480", ofType: "yuv") else {
            Logger.info("zoom_640X480.yuv missing")
            return
        }
        let yuvFile = fopen(path, "rb")
        if yuvFile == nil {
            Logger.info("open yuv failed")
            return
        }
        guard width > 0, height > 0 else { return }
        let frameSize = width * height * 3 / 2
        while !(Thread.current.isCancelled) {
            let yuvFrame = UnsafeMutablePointer<UInt8>.allocate(capacity: frameSize)
            let uAddress = width * height
            let vAddress = width * height * 5 / 4
            let s1 = fread(yuvFrame, 1, width * height, yuvFile)
            let s2 = fread(yuvFrame.advanced(by: uAddress), 1, width * height / 4, yuvFile)
            let s3 = fread(yuvFrame.advanced(by: vAddress), 1, width * height / 4, yuvFile)
            if s1 == 0 || s2 == 0 || s3 == 0 {
                yuvFrame.deallocate()
                rewind(yuvFile)
                continue
            }
            let w = width, h = height
            DispatchQueue.main.async { [weak self] in
                if let videoSender = self?.videoSender {
                    yuvFrame.withMemoryRebound(to: CChar.self, capacity: frameSize) { ptr in
                        videoSender.sendVideoFrame(ptr, width: UInt(w), height: UInt(h), dataLength: UInt(frameSize),
                                                   rotation: .rotationNone)
                    }
                }
                yuvFrame.deallocate()
            }
            usleep(usecPerFps)
        }
        fclose(yuvFile)
    }

    private func stop() {
        workThread?.cancel()
        workThread = nil
    }
}
