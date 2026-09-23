//
//  SendPictureAdapter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

final class SendPictureAdapter: NSObject, MobileRTCVideoSourceDelegate {

    private var videoSender: MobileRTCVideoSender?
    private var sendBuff1: UnsafeMutablePointer<UInt8>?
    private var sendBuff2: UnsafeMutablePointer<UInt8>?
    private var timer: Timer?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
        timer = nil
        sendBuff1?.deallocate()
        sendBuff2?.deallocate()
    }

    @objc private func onWillResignActive() { timer?.fireDate = .distantFuture }
    @objc private func onDidBecomeActive() { timer?.fireDate = Date() }

    func onInitialize(_ rawDataSender: MobileRTCVideoSender,
                      supportCapabilityArray: [MobileRTCVideoCapabilityItem],
                      suggest suggestCapabilityItem: MobileRTCVideoCapabilityItem) {
        videoSender = rawDataSender
        createCaptureSession()
    }

    func onPropertyChange(_ supportCapabilityArray: [MobileRTCVideoCapabilityItem],
                          suggest suggestCapabilityItem: MobileRTCVideoCapabilityItem) {}

    func onStartSend() { timer?.fireDate = Date() }
    func onStopSend() { timer?.fireDate = .distantFuture }
    func onUninitialized() {
        timer?.invalidate()
        timer = nil
        videoSender = nil
    }

    private func createCaptureSession() {
        guard let pic1 = UIImage(named: "frame_one.jpg"),
              let pic2 = UIImage(named: "frame_two.jpg") else { return }
        sendBuff1 = PreProcessHelper.imageToi420(pic1)
        sendBuff2 = PreProcessHelper.imageToi420(pic2)
        var index = 0
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let videoSender = self.videoSender else { return }
            let buffer = (index % 2 == 0) ? self.sendBuff1 : self.sendBuff2
            guard let buffer else { return }
            buffer.withMemoryRebound(to: CChar.self, capacity: 640 * 480 * 3 / 2) { ptr in
                videoSender.sendVideoFrame(ptr, width: 640, height: 480, dataLength: UInt(640 * 480 * 3 / 2),
                                           rotation: .rotationNone)
            }
            index += 1
        }
        timer.fire()
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
    }
}
