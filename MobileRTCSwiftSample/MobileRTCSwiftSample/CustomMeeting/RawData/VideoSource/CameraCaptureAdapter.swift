//
//  CameraCaptureAdapter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import AVFoundation
import MobileRTC
import UIKit
import os

final class CameraCaptureAdapter: NSObject, MobileRTCVideoSourceDelegate {

    private var captureSession: AVCaptureSession?
    private var videoSender: MobileRTCVideoSender?
    private let queue = DispatchQueue(label: "CameraQueue")

    /// Latest device rotation, updated on the main thread; read from the capture queue.
    /// Atomic because `MobileRTCVideoRawDataRotation` is a 64-bit enum on arm64.
    private var currentRotation: MobileRTCVideoRawDataRotation = .rotation90

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async { [weak self] in
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            self?.recomputeRotation()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    @objc private func onWillResignActive() { onStopSend() }
    @objc private func onDidBecomeActive() { onStartSend() }

    @objc private func onOrientationChanged() { recomputeRotation() }

    /// Must be called on the main thread.
    private func recomputeRotation() {
        var orientation = UIDevice.current.orientation
        if orientation == .unknown || orientation == .faceUp || orientation == .faceDown {
            let interfaceOrientation = UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .interfaceOrientation ?? .portrait
            switch interfaceOrientation {
            case .landscapeLeft: orientation = .landscapeLeft
            case .landscapeRight: orientation = .landscapeRight
            case .portraitUpsideDown: orientation = .portraitUpsideDown
            default: orientation = .portrait
            }
        }
        let rotation: MobileRTCVideoRawDataRotation
        switch orientation {
        case .landscapeLeft: rotation = .rotationNone
        case .portraitUpsideDown: rotation = .rotation270
        case .landscapeRight: rotation = .rotation180
        case .portrait: rotation = .rotation90
        default: return
        }
        currentRotation = rotation
    }

    func onInitialize(_ rawDataSender: MobileRTCVideoSender,
                      supportCapabilityArray: [MobileRTCVideoCapabilityItem],
                      suggest suggestCapabilityItem: MobileRTCVideoCapabilityItem) {
        self.videoSender = rawDataSender
        createCaptureSession()
        Logger.info("send out camera data, onInitialize")
    }

    func onPropertyChange(_ supportCapabilityArray: [MobileRTCVideoCapabilityItem],
                          suggest suggestCapabilityItem: MobileRTCVideoCapabilityItem) {}

    func onStartSend() {
        queue.async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func onStopSend() {
        queue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    func onUninitialized() {
        captureSession = nil
    }

    private func createCaptureSession() {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]

        guard let device = frontCamera(), let input = try? AVCaptureDeviceInput(device: device) else { return }
        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)
        session.sessionPreset = .vga640x480
        captureSession = session
    }

    private func frontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first
    }
}

extension CameraCaptureAdapter: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoSender, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(imageBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, []) }

        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0),
              let uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1) else { return }

        let totalSize = width * height * 3 / 2
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: totalSize)
        defer { buffer.deallocate() }

        memcpy(buffer, yPlane, width * height)

        let uOffset = width * height
        let vOffset = width * height * 5 / 4
        let uvBytes = uvPlane.assumingMemoryBound(to: UInt8.self)
        for i in 0..<(width * height / 4) {
            buffer[uOffset + i] = uvBytes[2 * i]
            buffer[vOffset + i] = uvBytes[2 * i + 1]
        }

        let rotation = currentRotation

        buffer.withMemoryRebound(to: CChar.self, capacity: totalSize) { ptr in
            videoSender.sendVideoFrame(ptr, width: UInt(width), height: UInt(height), dataLength: UInt(totalSize), rotation: rotation)
        }
    }
}
