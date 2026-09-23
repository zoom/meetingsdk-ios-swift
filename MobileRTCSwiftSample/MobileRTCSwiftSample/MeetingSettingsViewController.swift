//
//  MeetingSettingsViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

private final class ToggleCell: UITableViewCell {
    let toggleSwitch = UISwitch(frame: .zero)
    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessoryView = toggleSwitch
        toggleSwitch.addTarget(self, action: #selector(onSwitchChanged), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onSwitchChanged() {
        onToggle?(toggleSwitch.isOn)
    }
}

final class MeetingSettingsViewController: UITableViewController {
    private enum WhiteboardSettingKey {
        static let hideShareButton = "whiteboard.hide.share.button"
        static let hideFeedbackButton = "whiteboard.hide.feedback.button"
        static let disableCloudWhiteboard = "whiteboard.disable.cloud"
    }

    private enum Row {
        case toggle(title: String, subtitle: String? = nil, get: () -> Bool, set: (Bool) -> Void)
        case action(title: String, detail: () -> String, onTap: () -> Void)
    }

    private var sections: [[Row]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Meeting Settings", comment: "")
        tableView.register(ToggleCell.self, forCellReuseIdentifier: "toggle-cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildSections()
        tableView.reloadData()
    }

    private func buildSections() {
        guard let settings = MobileRTC.shared().getMeetingSettings() else {
            sections = []
            return
        }
        let meetingService = MobileRTC.shared().getMeetingService()

        var result: [[Row]] = []

        var layoutSection: [Row] = []
        if MobileRTC.shared().isSupportedCustomizeMeetingUI() {
            if MobileRTC.shared().isEnabledCustomizeMeetingUI(), MobileRTC.shared().hasRawDataLicense() {
                layoutSection.append(.toggle(
                    title: "Rawdata UI",
                    get: { UserDefaults.standard.bool(forKey: SampleMeetingUserDefaultsKey.rawDataUIEnable) },
                    set: { UserDefaults.standard.set($0, forKey: SampleMeetingUserDefaultsKey.rawDataUIEnable) }
                ))
            } else {
                UserDefaults.standard.set(false, forKey: SampleMeetingUserDefaultsKey.rawDataUIEnable)
            }
        }
        layoutSection.append(.toggle(
            title: NSLocalizedString("Change Thumbnail In Sharing", comment: ""),
            get: { settings.thumbnailInShare },
            set: { settings.thumbnailInShare = $0 }
        ))
        result.append(layoutSection)

        result.append([
            .toggle(
                title: NSLocalizedString("Send Raw Data", comment: ""),
                get: { UserDefaults.standard.bool(forKey: SampleMeetingUserDefaultsKey.rawDataSendEnable) },
                set: { [weak self] in self?.setSendRawDataEnabled($0) }
            )
        ])

        result.append([
            .toggle(title: NSLocalizedString("Auto Connect Internet Audio", comment: ""), get: { settings.autoConnectInternetAudio() }, set: { settings.setAutoConnectInternetAudio($0) }),
            .toggle(title: NSLocalizedString("Always Mute My Microphone", comment: ""), get: { settings.muteAudioWhenJoinMeeting() }, set: { settings.setMuteAudioWhenJoinMeeting($0) }),
            .toggle(title: NSLocalizedString("Always Mute My Video", comment: ""), get: { settings.muteVideoWhenJoinMeeting() }, set: { settings.setMuteVideoWhenJoinMeeting($0) }),
        ])

        var disableSection: [Row] = [
            .toggle(title: NSLocalizedString("Disable Call in", comment: ""), get: { settings.callInDisabled() }, set: { settings.disableCall(in: $0) }),
            .toggle(title: NSLocalizedString("Disable Call Out", comment: ""), get: { settings.callOutDisabled() }, set: { settings.disableCallOut($0) }),
            .toggle(
                title: NSLocalizedString("Hide share in Cloud WB", comment: ""),
                get: { UserDefaults.standard.bool(forKey: WhiteboardSettingKey.hideShareButton) },
                set: {
                    UserDefaults.standard.set($0, forKey: WhiteboardSettingKey.hideShareButton)
                    meetingService?.hideShareButton(onCloudWhiteboard: $0)
                }
            ),
            .toggle(
                title: NSLocalizedString("Hide Feedback in Cloud WB", comment: ""),
                get: { UserDefaults.standard.bool(forKey: WhiteboardSettingKey.hideFeedbackButton) },
                set: {
                    UserDefaults.standard.set($0, forKey: WhiteboardSettingKey.hideFeedbackButton)
                    meetingService?.hideFeedbackButton(onCloudWhiteboard: $0)
                }
            ),
            .toggle(title: NSLocalizedString("Disable Minimize Meeting", comment: ""), get: { settings.minimizeMeetingDisabled() }, set: { settings.disableMinimizeMeeting($0) }),
        ]
        if UIDevice.current.userInterfaceIdiom == .phone {
            disableSection.append(.toggle(title: NSLocalizedString("Disable Driving Mode", comment: ""), get: { settings.driveModeDisabled() }, set: { settings.disableDriveMode($0) }))
        }
        disableSection.append(contentsOf: [
            .toggle(title: NSLocalizedString("Disable Gallery View", comment: ""), get: { settings.galleryViewDisabled() }, set: { settings.disableGalleryView($0) }),
            .toggle(
                title: NSLocalizedString("Disable cloud whiteboard", comment: ""),
                subtitle: NSLocalizedString("cell default is NO", comment: ""),
                get: { UserDefaults.standard.bool(forKey: WhiteboardSettingKey.disableCloudWhiteboard) },
                set: {
                    UserDefaults.standard.set($0, forKey: WhiteboardSettingKey.disableCloudWhiteboard)
                    meetingService?.disableCloudWhiteboard($0)
                }
            ),
            .toggle(
                title: NSLocalizedString("Disable Show Video Preview", comment: ""),
                get: { settings.showVideoPreviewWhenJoinMeetingDisabled() },
                set: { settings.disableShowVideoPreview(whenJoinMeeting: $0) }
            ),
            .toggle(title: NSLocalizedString("Disable Virtual Background", comment: ""), get: { settings.virtualBackgroundDisabled() }, set: { settings.disableVirtualBackground($0) }),
            .toggle(title: NSLocalizedString("Disable Copy Meeting Url", comment: ""), get: { settings.copyMeetingUrlDisabled() }, set: { settings.disableCopyMeetingUrl($0) }),
            .toggle(title: NSLocalizedString("Disable Proximity Monitoring", comment: ""), get: { settings.proximityMonitoringDisable }, set: { settings.proximityMonitoringDisable = $0 }),
            .toggle(title: NSLocalizedString("Disable Speaker When In Meeting", comment: ""), get: { settings.speakerOffWhenInMeeting() }, set: { settings.setSpeakerOffWhenInMeeting($0) }),
            .toggle(title: NSLocalizedString("Disable clean webkit cache", comment: ""), get: { settings.isDisabledClearWebKitCache() }, set: { settings.disableClearWebKitCache($0) }),
            .toggle(title: NSLocalizedString("Enable Share Content Flash Detection", comment: ""), get: { settings.isShareContentFlashDetectionEnabled() }, set: { settings.enableShareContentFlashDetection($0) }),
        ])
        result.append(disableSection)

        result.append([
            .toggle(title: NSLocalizedString("Face Beauty Enable", comment: ""), get: { settings.faceBeautyEnabled() }, set: { settings.setFaceBeautyEnabled($0) }),
            .toggle(title: NSLocalizedString("Video Mirror Enable", comment: ""), get: { settings.isMirrorEffectEnabled() }, set: { settings.enableMirrorEffect($0) }),
            .toggle(title: NSLocalizedString("Use Original Sound", comment: ""), get: { settings.micOriginalInputEnabled() }, set: { settings.enableMicOriginalInput($0) }),
            .action(
                title: NSLocalizedString("Change emoji reaction skin tone", comment: ""),
                detail: { Self.reactionToneName(settings.reactionSkinTone().rawValue) },
                onTap: { [weak self] in self?.cycleReactionSkinTone() }
            ),
        ])

        var hiddenSection: [Row] = [
            .toggle(title: NSLocalizedString("Hide Meeting Title", comment: ""), get: { settings.meetingTitleHidden }, set: { settings.meetingTitleHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Password", comment: ""), get: { settings.meetingPasswordHidden }, set: { settings.meetingPasswordHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Leave", comment: ""), get: { settings.meetingLeaveHidden }, set: { settings.meetingLeaveHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Audio", comment: ""), get: { settings.meetingAudioHidden }, set: { settings.meetingAudioHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Video", comment: ""), get: { settings.meetingVideoHidden }, set: { settings.meetingVideoHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Invite", comment: ""), get: { settings.meetingInviteHidden }, set: { settings.meetingInviteHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Invite Url", comment: ""), get: { settings.meetingInviteUrlHidden }, set: { settings.meetingInviteUrlHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Chat", comment: ""), get: { settings.meetingChatHidden }, set: { settings.meetingChatHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Participant", comment: ""), get: { settings.meetingParticipantHidden }, set: { settings.meetingParticipantHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting More", comment: ""), get: { settings.meetingMoreHidden }, set: { settings.meetingMoreHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Share", comment: ""), get: { settings.meetingShareHidden }, set: { settings.meetingShareHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting TopBar", comment: ""), get: { settings.topBarHidden }, set: { settings.topBarHidden = $0 }),
            .toggle(title: NSLocalizedString("Host Hide Leave Meeting", comment: ""), get: { settings.hostLeaveHidden }, set: { settings.hostLeaveHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Hint in Meeting", comment: ""), get: { settings.hintHidden }, set: { settings.hintHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Tips in Meeting", comment: ""), get: { settings.tipsHidden }, set: { settings.tipsHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide disconnect audio in more menu", comment: ""), get: { settings.disconnectAudioHidden }, set: { settings.disconnectAudioHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Waiting HUD", comment: ""), get: { settings.waitingHUDHidden }, set: { settings.waitingHUDHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting BottomBar", comment: ""), get: { settings.bottomBarHidden }, set: { settings.bottomBarHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Meeting Webinar Q&A", comment: ""), get: { settings.qaButtonHidden }, set: { settings.qaButtonHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Call In Room System", comment: ""), get: { settings.callinRoomSystemHidden }, set: { settings.callinRoomSystemHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Call Out Room System", comment: ""), get: { settings.calloutRoomSystemHidden }, set: { settings.calloutRoomSystemHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Claim Host With HostKey", comment: ""), get: { settings.claimHostWithHostKeyHidden }, set: { settings.claimHostWithHostKeyHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Close Caption", comment: ""), get: { settings.closeCaptionHidden }, set: { settings.closeCaptionHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Promote To Panelist", comment: ""), get: { settings.promoteToPanelistHidden }, set: { settings.promoteToPanelistHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Change To Attendee", comment: ""), get: { settings.changeToAttendeeHidden }, set: { settings.changeToAttendeeHidden = $0 }),
            .toggle(title: NSLocalizedString("Hide Reactions OnMeetingUI", comment: ""), get: { settings.reactionsOnMeetingUIHidden() }, set: { settings.hideReactions(onMeetingUI: $0) }),
            .toggle(title: NSLocalizedString("Hide Record Button", comment: ""), get: { settings.recordButtonHidden }, set: { settings.recordButtonHidden = $0 }),
            .toggle(title: NSLocalizedString("Show Non-Video Participants", comment: ""), get: { settings.isHideNoVideoUsersEnabled() }, set: { settings.setHideNoVideoUsersEnabled($0) }),
            .toggle(title: NSLocalizedString("Hide My View", comment: ""), get: { settings.isHideSelfViewEnabled() }, set: { settings.enableHideSelfView($0) }),
            .toggle(title: NSLocalizedString("Hide Webinar register dialog", comment: ""), get: { settings.hideRegisterWebinarInfoWindow() }, set: { settings.setHideRegisterWebinarInfoWindow($0) }),
            .toggle(title: NSLocalizedString("hide recover meeting", comment: ""), get: { settings.hideRecoverMeetingDialog }, set: { settings.hideRecoverMeetingDialog = $0 }),
            .toggle(title: NSLocalizedString("hide stop liveStream dialog", comment: ""), get: { settings.hideStopLiveStreamDialog }, set: { settings.hideStopLiveStreamDialog = $0 }),
        ]
        if settings.isCenterStageModeSupported() {
            hiddenSection.append(.toggle(title: NSLocalizedString("Enable CenterStage Mode", comment: ""), get: { settings.isEnabledCenterStageMode() }, set: { _ = settings.enableCenterStageMode($0) }))
        }
        result.append(hiddenSection)

        result.append([
            .toggle(title: NSLocalizedString("Show My Elapse Time", comment: ""), get: { settings.showMyMeetingElapseTime() }, set: { settings.enableShowMyMeetingElapseTime($0) })
        ])

        sections = result
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section][indexPath.row] {
        case let .toggle(title, subtitle, get, set):
            let cell = tableView.dequeueReusableCell(withIdentifier: "toggle-cell", for: indexPath) as! ToggleCell
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = subtitle
            cell.toggleSwitch.isOn = get()
            cell.onToggle = set
            return cell
        case let .action(title, detail, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: "action-cell")
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: "action-cell")
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detail()
            cell.selectionStyle = .default
            cell.accessoryType = .none
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if case let .action(_, _, onTap) = sections[indexPath.section][indexPath.row] {
            onTap()
        }
    }

    private func cycleReactionSkinTone() {
        guard let settings = MobileRTC.shared().getMeetingSettings() else { return }
        var nextRaw = (settings.reactionSkinTone().rawValue + 1) % 7
        if nextRaw == 0 { nextRaw = 1 }
        guard let nextTone = MobileRTCEmojiReactionSkinTone(rawValue: nextRaw) else { return }
        _ = settings.setReactionSkinTone(nextTone)
        let message = "Change skin tone to \(nextRaw)"
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel))
        present(alert, animated: true)
        tableView.reloadData()
    }

    private static func reactionToneName(_ raw: UInt) -> String {
        switch raw {
        case 1: return "SkinTone_Default"
        case 2: return "SkinTone_Light"
        case 3: return "SkinTone_MediumLight"
        case 4: return "SkinTone_Medium"
        case 5: return "SkinTone_MediumDark"
        case 6: return "SkinTone_Dark"
        default: return "SkinTone_Unknown"
        }
    }

    private func setSendRawDataEnabled(_ enabled: Bool) {
        RawDataVideoSourceManager.shared.setEnabled(enabled)
    }
}
