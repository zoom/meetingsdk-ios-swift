//
//  BottomPanelView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

/// Bottom toolbar with Audio / Video / Share / Chat (Participants) / More.
/// More-menu items are populated by `MoreMenuBuilder`; features ported in later tiers
/// extend that builder.
final class BottomPanelView: UIView {

    private let gradientLayer = CAGradientLayer()

    private let audioButton = UIButton(type: .system)
    private let videoButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let chatButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)

    let audioPresenter = SDKAudioPresenter()
    let videoPresenter = SDKVideoPresenter()
    let sharePresenter = SDKSharePresenter()
    let actionPresenter = SDKActionPresenter()

    var isRaiseHand: Bool = false
    var firstSendChat: Bool = true

    let videoSourceHelper = MobileRTCVideoSourceHelper()
    let shareSourceHelper = MobileRTCShareSourceHelper()
    let audioSourceHelper = MobileRTCAudioSourceHelper()

    var cameraAdapter: CameraCaptureAdapter?
    var picAdapter: SendPictureAdapter?
    var yuvAdapter: SendYUVAdapter?
    var yuvShareAdapter: SendYUVShareAdapter?
    var pcmAudioAdapter: SendPCMAdapter?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure() {
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.colors = [
            UIColor(white: 0, alpha: 0.8).cgColor,
            UIColor(white: 0, alpha: 0.2).cgColor
        ]
        layer.addSublayer(gradientLayer)

        styleButton(audioButton, title: "Mute", image: "icon_meeting_audio", action: #selector(onAudioPressed))
        styleButton(videoButton, title: "Stop Video", image: "icon_meeting_video", action: #selector(onVideoPressed))
        styleButton(shareButton, title: "Start Share", image: "icon_meeting_share", action: #selector(onSharePressed))
        styleButton(chatButton, title: "Participants", image: "icon_meeting_attendee", action: #selector(onChatPressed))
        styleButton(moreButton, title: "More", image: "icon_meeting_more", action: #selector(onMorePressed(_:)))

        addSubview(audioButton)
        addSubview(videoButton)
        addSubview(shareButton)
        addSubview(chatButton)
        addSubview(moreButton)
    }

    private func styleButton(_ button: UIButton, title: String, image: String, action: Selector) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: image)
        config.title = title
        config.imagePlacement = .top
        config.imagePadding = 2
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = .systemFont(ofSize: 11)
            return out
        }
        button.configuration = config
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    func showBottomPanelView() {
        UIView.animate(withDuration: 0.25) {
            self.frame = CGRect(
                x: 0,
                y: CustomMeetingLayout.screenHeight - CustomMeetingLayout.bottomHeight,
                width: CustomMeetingLayout.screenWidth,
                height: CustomMeetingLayout.bottomHeight
            )
        }
    }

    func hideBottomPanelView() {
        UIView.animate(withDuration: 0.25) {
            self.frame = CGRect(
                x: 0,
                y: CustomMeetingLayout.screenHeight,
                width: CustomMeetingLayout.screenWidth,
                height: CustomMeetingLayout.bottomHeight
            )
        }
    }

    func updateFrame() {
        let width = CustomMeetingLayout.screenWidth
        frame = CGRect(x: 0, y: CustomMeetingLayout.screenHeight - CustomMeetingLayout.bottomHeight, width: width, height: CustomMeetingLayout.bottomHeight)
        gradientLayer.frame = bounds

        let h = CustomMeetingLayout.bottomButtonHeight
        let buttonWidth = width / 5
        let buttons: [UIButton] = [audioButton, videoButton, shareButton, chatButton, moreButton]
        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(x: CGFloat(index) * buttonWidth, y: 0, width: buttonWidth, height: h)
        }
    }

    private func updateButtonContent(_ button: UIButton, image: String, title: String) {
        var config = button.configuration ?? UIButton.Configuration.plain()
        config.image = UIImage(named: image)
        config.title = title
        button.configuration = config
    }

    // MARK: Button actions

    @objc private func onAudioPressed() { audioPresenter.muteMyAudio() }
    @objc private func onVideoPressed() { videoPresenter.muteMyVideo() }
    @objc private func onSharePressed() { sharePresenter.startOrStopAppShare() }
    @objc private func onChatPressed() { actionPresenter.presentParticipantsViewController() }

    @objc private func onMorePressed(_ sender: UIButton) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let alert = UIAlertController(title: meetingTypeTitle(ms), message: nil, preferredStyle: .actionSheet)
        MoreMenuBuilder.populate(alert, ms: ms, panel: self, sender: sender)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }

    private func meetingTypeTitle(_ ms: MobileRTCMeetingService) -> String {
        switch ms.getMeetingType() {
        case .none: return "MeetingType:None"
        case .normal: return "MeetingType:Normal"
        case .breakoutRoom: return "MeetingType:BreakoutRoom"
        case .webinar: return "MeetingType:Webinar"
        @unknown default: return "MeetingType:None"
        }
    }

    // MARK: Status updates

    func updateMyAudioStatus() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let audioType = ms.myAudioType()
        if audioType == .none {
            updateButtonContent(audioButton, image: "icon_meeting_noaudio", title: "Join Audio")
        } else if ms.isMyAudioMuted() {
            updateButtonContent(audioButton, image: "icon_meeting_audio_mute", title: "Unmute")
        } else {
            let icon = (audioType == .telephony) ? "icon_meeting_audio_phone" : "icon_meeting_audio"
            updateButtonContent(audioButton, image: icon, title: "Mute")
        }
    }

    func updateMyVideoStatus() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isSendingMyVideo() {
            updateButtonContent(videoButton, image: "icon_meeting_video", title: "Stop Video")
        } else {
            updateButtonContent(videoButton, image: "icon_meeting_video_mute", title: "Start Video")
        }
    }

    func updateMyShareStatus() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isStartingShare() {
            updateButtonContent(shareButton, image: "icon_meeting_stopshare", title: "Stop Share")
        } else {
            updateButtonContent(shareButton, image: "icon_meeting_share", title: "Start Share")
        }
    }
}
