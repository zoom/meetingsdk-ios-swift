//
//  VideoViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

/// Renders the attendee/active speaker/preview video for the custom in-meeting UI.
final class VideoViewController: UIViewController {

    lazy var videoView: MobileRTCVideoView = {
        let v = MobileRTCVideoView(frame: view.bounds)
        v.setVideoAspect(MobileRTCVideoAspect_PanAndScan)
        return v
    }()

    lazy var activeVideoView: MobileRTCActiveVideoView = {
        let v = MobileRTCActiveVideoView(frame: view.bounds)
        v.setVideoAspect(MobileRTCVideoAspect_PanAndScan)
        return v
    }()

    lazy var preVideoView: MobileRTCPreviewVideoView = {
        MobileRTCPreviewVideoView(frame: view.bounds)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(activeVideoView)
        view.addSubview(videoView)
        activeVideoView.isHidden = true
        videoView.isHidden = true
        view.addSubview(preVideoView)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        videoView.addGestureRecognizer(pinch)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoView.frame = view.bounds
        activeVideoView.frame = view.bounds
        preVideoView.frame = view.bounds
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        let velocity = recognizer.velocity
        guard !velocity.isNaN else { return }
        MobileRTC.shared().getMeetingService()?.zoomCamera(velocity)
    }

    func showAttendeeVideo(userID: UInt) {
        activeVideoView.isHidden = true
        if videoView.superview == nil {
            view.addSubview(videoView)
        }
        videoView.isHidden = false
        view.bringSubviewToFront(videoView)
        videoView.showAttendeeVideo(withUserID: userID)
    }

    func showActiveVideo(userID: UInt) {
        videoView.isHidden = true
        activeVideoView.stopAttendeeVideo()
        if activeVideoView.superview == nil {
            view.addSubview(activeVideoView)
        }
        activeVideoView.isHidden = false
        view.bringSubviewToFront(activeVideoView)
        activeVideoView.showAttendeeVideo(withUserID: userID)
    }

    func stopActiveVideo() {
        activeVideoView.stopAttendeeVideo()
    }
}
