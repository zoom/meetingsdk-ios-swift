//
//  ControlBar.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

enum ControlBarTag: Int {
    case switchCamera = 2000
    case audio = 2001
    case video = 2002
    case more = 2003
    case share = 2004
}

final class ControlBar: UIView {

    var onShareTap: ((ControlBarTag) -> Void)?

    private let switchBtn = UIButton(type: .custom)
    private let audioBtn = UIButton(type: .custom)
    private let videoBtn = UIButton(type: .custom)
    private let shareBtn = UIButton(type: .custom)
    private let moreBtn = UIButton(type: .custom)

    private let audioPresenter = SDKAudioPresenter()
    private let videoPresenter = SDKVideoPresenter()
    private let actionPresenter = SDKActionPresenter()

    private let videoSourceHelper = MobileRTCVideoSourceHelper()
    private let shareSourceHelper = MobileRTCShareSourceHelper()
    private let audioSourceHelper = MobileRTCAudioSourceHelper()

    private var cameraAdapter: CameraCaptureAdapter?
    private var picAdapter: SendPictureAdapter?
    private var yuvAdapter: SendYUVAdapter?
    private var yuvShareAdapter: SendYUVShareAdapter?
    private var pcmAudioAdapter: SendPCMAdapter?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton(switchBtn, tag: .switchCamera, image: "icon_switch")
        configureButton(audioBtn, tag: .audio, image: "icon_unmute", selectedImage: "icon_mute")
        configureButton(videoBtn, tag: .video, image: "icon_video_off", selectedImage: "icon_video_on")
        configureButton(shareBtn, tag: .share, image: "icon_video_share", selectedImage: "icon_video_share_stop")
        configureButton(moreBtn, tag: .more, image: "icon_video_more")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureButton(_ button: UIButton, tag: ControlBarTag, image: String, selectedImage: String? = nil) {
        button.tag = tag.rawValue
        if let img = UIImage(named: image) { button.setImage(img, for: .normal) }
        if let selectedImage, let img = UIImage(named: selectedImage) { button.setImage(img, for: .selected) }
        button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        addSubview(button)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let isLandscape = CustomMeetingLayout.isLandscape
        let buttonWidth: CGFloat = isLandscape ? (CustomMeetingLayout.isIPad ? 60 : 45) : 60
        let height = buttonWidth
        let buttons = [switchBtn, audioBtn, videoBtn, shareBtn, moreBtn]
        for (i, button) in buttons.enumerated() {
            button.frame = CGRect(x: 0, y: CGFloat(i) * height, width: buttonWidth, height: height)
        }
        let total = height * CGFloat(buttons.count)
        let screen = UIScreen.main.bounds
        let x = screen.size.width - buttonWidth - 12
        let y: CGFloat = isLandscape ? TopBar.topHeight : (screen.size.height - total) * 2 / 5
        frame = CGRect(x: x, y: y, width: buttonWidth, height: total)
    }

    @objc private func onTap(_ sender: UIButton) {
        guard let tag = ControlBarTag(rawValue: sender.tag) else { return }
        switch tag {
        case .switchCamera: videoPresenter.switchMyCamera()
        case .audio: audioPresenter.muteMyAudio()
        case .video: videoPresenter.muteMyVideo()
        case .share: onShareTap?(.share)
        case .more: presentMoreMenu(sender)
        }
    }

    private func presentMoreMenu(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Send Rawdata - Camera Data", style: .default) { [weak self] _ in
            guard let self else { return }
            let adapter = CameraCaptureAdapter()
            self.cameraAdapter = adapter
            _ = self.videoSourceHelper.setExternalVideoSource(adapter, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Send Rawdata - Picture Data", style: .default) { [weak self] _ in
            guard let self else { return }
            let adapter = SendPictureAdapter()
            self.picAdapter = adapter
            _ = self.videoSourceHelper.setExternalVideoSource(adapter, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Send Rawdata - YUV Data", style: .default) { [weak self] _ in
            guard let self else { return }
            let adapter = SendYUVAdapter()
            self.yuvAdapter = adapter
            _ = self.videoSourceHelper.setExternalVideoSource(adapter, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Switch to internal video source", style: .default) { [weak self] _ in
            _ = self?.videoSourceHelper.setExternalVideoSource(nil, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Send Rawdata Share - YUV with audio", style: .default) { [weak self] _ in
            guard let self else { return }
            let adapter = SendYUVShareAdapter()
            adapter.isSharing = true
            self.yuvShareAdapter = adapter
            _ = self.shareSourceHelper.setExternalShareSource(adapter, andAudioSource: adapter)
        })
        alert.addAction(UIAlertAction(title: "Stop Rawdata Share - YUV Data", style: .default) { [weak self] _ in
            self?.yuvShareAdapter = nil
            _ = self?.shareSourceHelper.setExternalShareSource(nil, andAudioSource: nil)
            if let ms = MobileRTC.shared().getMeetingService(), ms.isStartingShare() { ms.stopAppShare() }
        })
        alert.addAction(UIAlertAction(title: "Start Rawdata Audio", style: .default) { [weak self] _ in
            guard let self else { return }
            let adapter = SendPCMAdapter()
            self.pcmAudioAdapter = adapter
            _ = self.audioSourceHelper.setExternalAudioSource(adapter)
        })
        alert.addAction(UIAlertAction(title: "Stop Rawdata Audio", style: .default) { [weak self] _ in
            self?.pcmAudioAdapter = nil
            _ = self?.audioSourceHelper.setExternalAudioSource(nil)
            if let ms = MobileRTC.shared().getMeetingService(), ms.isStartingShare() { ms.stopAppShare() }
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = moreBtn
            popover.sourceRect = moreBtn.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }

    func updateMyAudioStatus() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let mute = ms.isMyAudioMuted()
        audioBtn.isSelected = ms.myAudioType() != .none && !mute
    }

    func updateMyVideoStatus() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        videoBtn.isSelected = ms.isSendingMyVideo()
    }
}
