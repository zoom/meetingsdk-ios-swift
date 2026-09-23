//
//  MoreMenuBuilder.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

/// Builds the action sheet shown when the "More" button on `BottomPanelView` is tapped.
/// Each tier extends this builder with its own group of menu items.
enum MoreMenuBuilder {

    static func populate(_ alert: UIAlertController,
                         ms: MobileRTCMeetingService,
                         panel: BottomPanelView,
                         sender: UIButton) {
        addLanguageInterpretationActions(alert, ms: ms)
        addDashboardActions(alert, ms: ms)
        addUsersAction(alert, ms: ms, sender: sender)
        addAudioActions(alert, ms: ms, panel: panel)
        addLockingActions(alert, ms: ms, panel: panel)
        addWaitingRoomActions(alert, ms: ms)
        addChatPriviledgeAction(alert, ms: ms, sender: sender, panel: panel)
        addRawDataActions(alert, ms: ms, panel: panel)
        addAnnotationViewerToggle(alert)
        addAnnPanelActions(alert, ms: ms, panel: panel)
        addRecordingActions(alert, ms: ms)
        addRaiseHandActions(alert, ms: ms, panel: panel)
        addEmojiActions(alert, ms: ms)
        addGroupChatActions(alert, ms: ms, panel: panel)
        addHostControls(alert, ms: ms)
        addWebinarAttendeesAction(alert, ms: ms)
        addClaimHostAction(alert, ms: ms, sender: sender)
        addAllChatMessageAction(alert)
        addPollingAction(alert, ms: ms)
        addQAAction(alert, ms: ms)
        addBOMeetingAction(alert, ms: ms)
        addVirtualBackgroundAction(alert, ms: ms)
        addLiveStreamActions(alert, ms: ms)
        addLiveTranscriptionActions(alert, ms: ms)
        addShareSettingActions(alert, ms: ms)
    }

    // MARK: Language Interpretation

    private static func addLanguageInterpretationActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        if !ms.isMeetingHost(), !ms.isInterpreter(), ms.isInterpretationStarted() {
            alert.addAction(UIAlertAction(title: "Select Language", style: .default) { _ in
                let vc = SelectLanguageViewController()
                vc.currentLanID = ms.getJoinedLanguageID()
                presentFullScreen(vc)
            })
        }
        if ms.isMeetingHost() {
            alert.addAction(UIAlertAction(title: "Manage LanInterpre", style: .default) { _ in
                presentFullScreen(ManageLanInterpreViewController())
            })
        }
        if ms.isInterpreter(), ms.isInterpretationStarted() {
            alert.addAction(UIAlertAction(title: "Interpreter Language Select", style: .default) { _ in
                presentFullScreen(InterpreterLanguageSelectViewController())
            })
        }
    }

    // MARK: Webinar Attendees

    private static func addWebinarAttendeesAction(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isWebinarMeeting(), ms.isMeetingHost() || ms.isMeetingCoHost() else { return }
        alert.addAction(UIAlertAction(title: "Show Webinar Attendees List", style: .default) { _ in
            presentFullScreen(WebinarAttendeesListViewController())
        })
    }

    // MARK: Raw Data sources

    private static func addRawDataActions(_ alert: UIAlertController, ms: MobileRTCMeetingService, panel: BottomPanelView) {
        guard MobileRTC.shared().hasRawDataLicense() else { return }
        alert.addAction(UIAlertAction(title: "Send Rawdata - Camera Data", style: .default) { [weak panel] _ in
            guard let panel else { return }
            let adapter = CameraCaptureAdapter()
            panel.cameraAdapter = adapter
            _ = panel.videoSourceHelper.setExternalVideoSource(adapter, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Send Rawdata - Picture Data", style: .default) { [weak panel] _ in
            guard let panel else { return }
            let adapter = SendPictureAdapter()
            panel.picAdapter = adapter
            _ = panel.videoSourceHelper.setExternalVideoSource(adapter, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Send Rawdata - YUV Data", style: .default) { [weak panel] _ in
            guard let panel else { return }
            let adapter = SendYUVAdapter()
            panel.yuvAdapter = adapter
            _ = panel.videoSourceHelper.setExternalVideoSource(adapter, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Switch to internal video source", style: .default) { [weak panel] _ in
            _ = panel?.videoSourceHelper.setExternalVideoSource(nil, videoDataFormat: .I420)
        })
        alert.addAction(UIAlertAction(title: "Send Rawdata Share - YUV Data", style: .default) { [weak panel] _ in
            guard let panel else { return }
            let adapter = SendYUVShareAdapter()
            adapter.isSharing = true
            panel.yuvShareAdapter = adapter
            _ = panel.shareSourceHelper.setExternalShareSource(adapter, andAudioSource: nil)
        })
        alert.addAction(UIAlertAction(title: "Stop Rawdata Share - YUV Data", style: .default) { [weak panel] _ in
            panel?.yuvShareAdapter = nil
            _ = panel?.shareSourceHelper.setExternalShareSource(nil, andAudioSource: nil)
            if ms.isStartingShare() { ms.stopAppShare() }
        })
        alert.addAction(UIAlertAction(title: "Start Rawdata Audio", style: .default) { [weak panel] _ in
            guard let panel else { return }
            let adapter = SendPCMAdapter()
            panel.pcmAudioAdapter = adapter
            _ = panel.audioSourceHelper.setExternalAudioSource(adapter)
        })
        alert.addAction(UIAlertAction(title: "Stop Rawdata Audio", style: .default) { [weak panel] _ in
            panel?.pcmAudioAdapter = nil
            _ = panel?.audioSourceHelper.setExternalAudioSource(nil)
            if ms.isStartingShare() { ms.stopAppShare() }
        })
    }

    // MARK: Polling / QA / BO / Virtual Background

    private static func addPollingAction(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.canDoPolling() else { return }
        alert.addAction(UIAlertAction(title: "Polling", style: .default) { _ in
            presentFullScreen(PollingViewController())
        })
    }

    private static func addQAAction(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isWebinarMeeting(), ms.isQAEnabled() else { return }
        alert.addAction(UIAlertAction(title: "QA", style: .default) { _ in
            presentFullScreen(QAListViewController())
        })
    }

    private static func addBOMeetingAction(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isBOMeetingEnabled() else { return }
        alert.addAction(UIAlertAction(title: "BO Meeting", style: .default) { _ in
            presentFullScreen(BOMeetingViewController())
        })
    }

    private static func addVirtualBackgroundAction(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isSupportVirtualBG() else { return }
        alert.addAction(UIAlertAction(title: "Virtual Background", style: .default) { _ in
            presentFullScreen(VBViewController())
        })
    }

    private static func presentFullScreen(_ root: UIViewController) {
        let nav = UINavigationController(rootViewController: root)
        nav.modalPresentationStyle = .fullScreen
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(nav, animated: true)
    }

    // MARK: All chat messages

    private static func addAllChatMessageAction(_ alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Get All Chat Message", style: .default) { _ in
            let vc = AllChatMessageViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            (UIApplication.shared.delegate as? AppDelegate)?
                .topViewController()?
                .present(nav, animated: true)
        })
    }

    // MARK: Dashboard / Whiteboard / Docs

    private static func addDashboardActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        if ms.isSupportWhiteBoard() {
            alert.addAction(UIAlertAction(title: "showDashboardView", style: .default) { _ in
                ms.showDashboardView()
            })
        }
        if ms.isSupportDocs() {
            alert.addAction(UIAlertAction(title: "showDocDashboardView", style: .default) { _ in
                ms.showDocDashboardView()
            })
        }
    }

    // MARK: Users

    private static func addUsersAction(_ alert: UIAlertController, ms: MobileRTCMeetingService, sender: UIButton) {
        alert.addAction(UIAlertAction(title: "Users", style: .default) { _ in
            presentUsersList(ms: ms, sender: sender)
        })
    }

    private static func presentUsersList(ms: MobileRTCMeetingService, sender: UIButton) {
        let alert = UIAlertController(title: "Users", message: nil, preferredStyle: .actionSheet)
        for idNum in ms.getInMeetingUserList() ?? [] {
            guard let info = ms.userInfo(byID: idNum.uintValue) else { continue }
            alert.addAction(UIAlertAction(title: "\(info.userName ?? "")(\(idNum))", style: .default) { _ in
                let vc = GrantAssetViewViewController(userId: idNum.uintValue)
                presentFullScreen(vc)
            })
        }
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

    // MARK: Audio

    private static func addAudioActions(_ alert: UIAlertController, ms: MobileRTCMeetingService, panel: BottomPanelView) {
        alert.addAction(UIAlertAction(title: "Switch My Audio", style: .default) { _ in
            panel.audioPresenter.switchMyAudioSource()
        })
        alert.addAction(UIAlertAction(title: "Dialing Room", style: .default) { _ in
            dialRoomFunction(ms: ms)
        })
        if panel.audioPresenter.myAudioType() != .none {
            alert.addAction(UIAlertAction(title: "Disconnect Audio", style: .default) { _ in
                panel.audioPresenter.connectMyAudio(false)
            })
        }
    }

    private static func dialRoomFunction(ms: MobileRTCMeetingService) {
        let room = MobileRTCRoomDevice()
        _ = ms.call(room)
    }

    // MARK: Locking / Share settings

    private static func addLockingActions(_ alert: UIAlertController, ms: MobileRTCMeetingService, panel: BottomPanelView) {
        guard ms.isMeetingHost() || ms.isMeetingCoHost() else { return }
        let shareTitle: String
        switch ms.getShareSettingType() {
        case .none: shareTitle = "Type:MobileRTCShareSettingType_None"
        case .lockShare: shareTitle = "Type:MobileRTCShareSettingType_LockShare"
        case .hostGrab: shareTitle = "Type:MobileRTCShareSettingType_HostGrab"
        case .anyoneGrab: shareTitle = "Type:MobileRTCShareSettingType_AnyoneGrab"
        case .multiShare: shareTitle = "Type:MobileRTCShareSettingType_MultiShare"
        @unknown default: shareTitle = "ShareSettingType: NULL"
        }
        alert.addAction(UIAlertAction(title: shareTitle, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "MobileRTCShareSettingType_LockShare", style: .default) { _ in
            _ = ms.setShareSettingType(.lockShare)
        })
    }

    // MARK: Waiting Room

    private static func addWaitingRoomActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard let ws = MobileRTC.shared().getWaitingRoomService(),
              ws.isSupportWaitingRoom(),
              ms.isMeetingHost() || ms.isMeetingCoHost() else { return }
        let title = ws.isWaitingRoomOnEntryFlagOn() ? "Disable Waiting Room On Entry" : "Enable Waiting Room On Entry"
        alert.addAction(UIAlertAction(title: title, style: .default) { _ in
            ws.enableWaitingRoom(onEntry: !ws.isWaitingRoomOnEntryFlagOn())
        })
    }

    // MARK: Chat priviledge

    private static func addChatPriviledgeAction(_ alert: UIAlertController,
                                                ms: MobileRTCMeetingService,
                                                sender: UIButton,
                                                panel: BottomPanelView) {
        guard ms.isMeetingHost() || ms.isMeetingCoHost() else { return }
        alert.addAction(UIAlertAction(title: "Change Chat Priviledge", style: .default) { _ in
            ChatPriviledgePresenter.present(ms: ms, sender: sender)
        })
    }

    // MARK: Annotation toggle

    private static func addAnnotationViewerToggle(_ alert: UIAlertController) {
        guard let asvc = MobileRTC.shared().getAnnotationService(),
              asvc.canDisableViewerAnnotation() else { return }
        if asvc.isViewerAnnotationDisabled() {
            alert.addAction(UIAlertAction(title: "Allow Viewer Annotation", style: .default) { _ in
                _ = asvc.disableViewerAnnotation(false)
            })
        } else {
            alert.addAction(UIAlertAction(title: "Disable Viewer Annotation", style: .default) { _ in
                _ = asvc.disableViewerAnnotation(true)
            })
        }
    }

    // MARK: ANN / AIC panels

    private static func addAnnPanelActions(_ alert: UIAlertController, ms: MobileRTCMeetingService, panel: BottomPanelView) {
        alert.addAction(UIAlertAction(title: "Show ANN Pannel", style: .default) { _ in
            if let parent = panel.superview {
                ms.showAANPanel(in: parent)
            }
        })
        alert.addAction(UIAlertAction(title: "Show AIC Pannel", style: .default) { _ in
            if let parent = panel.superview {
                ms.showDynamicNotice(forAICompanionPanel: parent)
            }
        })
    }

    // MARK: Recording

    private static func addRecordingActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isMeetingHost(), ms.isCMREnabled() else { return }
        if !ms.isCMRInProgress() {
            alert.addAction(UIAlertAction(title: "Start Recording", style: .default) { _ in
                ms.turn(onCMR: true)
            })
        } else {
            alert.addAction(UIAlertAction(title: "Stop Recording", style: .default) { _ in
                ms.turn(onCMR: false)
            })
            alert.addAction(UIAlertAction(title: "Pause/Resume Recording", style: .default) { _ in
                ms.resumePauseCMR()
            })
        }
    }

    // MARK: Raise hand / Lower all

    private static func addRaiseHandActions(_ alert: UIAlertController, ms: MobileRTCMeetingService, panel: BottomPanelView) {
        let title = panel.isRaiseHand ? "Lower My Hand" : "Raise My Hand"
        alert.addAction(UIAlertAction(title: title, style: .default) { [weak panel] _ in
            guard let panel else { return }
            if panel.isRaiseHand {
                _ = ms.lowerHand(ms.myselfUserID())
            } else {
                _ = ms.raiseMyHand()
            }
            panel.isRaiseHand.toggle()
        })

        if ms.isMeetingHost() || ms.isMeetingCoHost() {
            alert.addAction(UIAlertAction(title: "Lower All Hand", style: .default) { _ in
                ms.lowerAllHand(ms.isWebinarAttendee())
            })
        }
    }

    // MARK: Emoji

    private static func addEmojiActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isEmojiReactionEnabled() else { return }
        alert.addAction(UIAlertAction(title: "Send reaction", style: .default) { _ in
            _ = ms.send(.clap)
        })
        alert.addAction(UIAlertAction(title: "Send emoji feedback", style: .default) { _ in
            _ = ms.send(.yes)
        })
        alert.addAction(UIAlertAction(title: "cancel emoji feedback", style: .default) { _ in
            _ = ms.cancelEmojiFeedback()
        })
    }

    // MARK: Group chat send

    private static func addGroupChatActions(_ alert: UIAlertController, ms: MobileRTCMeetingService, panel: BottomPanelView) {
        guard !ms.isChatDisabled() else { return }
        alert.addAction(UIAlertAction(title: "Send a group chat message to all", style: .default) { [weak panel] _ in
            let msg = MobileRTCMeetingChat()
            msg.chatMessageType = .to_All
            msg.content = "This is a private chat message"
            let err = ms.sendChatMsg(msg)
            if err == MobileRTCSendChatError.successed, panel?.firstSendChat == true, ms.isMeetingChatLegalNoticeAvailable() {
                panel?.firstSendChat = false
                let title = ms.getChatLegalNoticesPrompt()
                let body = ms.getChatLegalNoticesExplained()
                let info = UIAlertController(title: title, message: body, preferredStyle: .alert)
                info.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                (UIApplication.shared.delegate as? AppDelegate)?
                    .topViewController()?
                    .present(info, animated: true)
            }
        })
        if ms.isWebinarMeeting() {
            alert.addAction(UIAlertAction(title: "Send a group chat message to Panelists", style: .default) { _ in
                let msg = MobileRTCMeetingChat()
                msg.chatMessageType = .to_All_Panelist
                msg.content = "This is a private chat message"
                _ = ms.sendChatMsg(msg)
            })
        } else if ms.isMeetingHost() || ms.isMeetingCoHost() {
            alert.addAction(UIAlertAction(title: "Send a group chat message to Waiting Room", style: .default) { _ in
                let msg = MobileRTCMeetingChat()
                msg.chatMessageType = .to_WaitingRoomUsers
                msg.content = "This is a private chat message"
                _ = ms.sendChatMsg(msg)
            })
        }
    }

    // MARK: Host controls (mute on entry, mute all, play chime)

    private static func addHostControls(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isMeetingHost() || ms.isMeetingCoHost() else { return }
        let muteOnEntryTitle = ms.isMuteOnEntryOn() ? "UnMute Participants upon Entry" : "Mute Participants upon Entry"
        alert.addAction(UIAlertAction(title: muteOnEntryTitle, style: .default) { _ in
            _ = ms.enableMute(onEntry: !ms.isMuteOnEntryOn(), allowUnmuteBySelf: ms.isParticipantsUnmuteSelfAllowed())
        })
        alert.addAction(UIAlertAction(title: "Mute All", style: .default) { _ in
            _ = ms.muteAllUserAudio(true)
        })
        alert.addAction(UIAlertAction(title: "Ask All UnMute", style: .default) { _ in
            ms.askAllToUnmute()
        })
        let chimeTitle = ms.isPlayChimeOn() ? "Does not Play Sound When Someone Join/Leave" : "Play Sound When Someone Join/Leave"
        alert.addAction(UIAlertAction(title: chimeTitle, style: .default) { _ in
            ms.playChime(!ms.isPlayChimeOn())
        })
    }

    // MARK: Claim host

    private static func addClaimHostAction(_ alert: UIAlertController, ms: MobileRTCMeetingService, sender: UIButton) {
        if ms.canClaimhost() {
            alert.addAction(UIAlertAction(title: "Claim host", style: .default) { _ in
                ClaimHostPresenter.present()
            })
        }
    }

    // MARK: Live stream

    private static func addLiveStreamActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isMeetingHost() else { return }
        alert.addAction(UIAlertAction(title: "start live stream", style: .default) { _ in
            _ = ms.startLiveStream(withStreamingURL: "", streamingKey: "", broadcastURL: "")
        })
        alert.addAction(UIAlertAction(title: "stop live stream", style: .default) { _ in
            _ = ms.stopLiveStream()
        })
    }

    // MARK: Live transcription

    private static func addLiveTranscriptionActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        guard ms.isMeetingSupportCC(), ms.isLiveTranscriptionFeatureEnabled() else { return }
        let status = ms.getLiveTranscriptionStatus()
        if ms.isMeetingHost(), ms.canStartLiveTranscription() {
            if status == .liveTranscription_Status_Stop {
                alert.addAction(UIAlertAction(title: "start live transcription", style: .default) { _ in
                    _ = ms.startLiveTranscription()
                })
            } else if status == .liveTranscription_Status_Start {
                alert.addAction(UIAlertAction(title: "LiveTranscription: stop live transcription", style: .default) { _ in
                    _ = ms.stopLiveTranscription()
                })
            }
        }
        if ms.isMeetingHost() {
            let toggleTitle = ms.isRequestToStartLiveTranscriptionEnabled()
                ? "unenable Request to start live transcription"
                : "enable Request to start live transcription"
            alert.addAction(UIAlertAction(title: toggleTitle, style: .default) { _ in
                _ = ms.enableRequestLiveTranscription(!ms.isRequestToStartLiveTranscriptionEnabled())
            })
        }
        if !ms.isMeetingHost() {
            alert.addAction(UIAlertAction(title: "LiveTranscription: request to start live transcription", style: .default) { _ in
                _ = ms.request(toStartLiveTranscription: true)
            })
        }
        if !ms.canClaimhost() {
            alert.addAction(UIAlertAction(title: "Reclaim Host", style: .default) { _ in
                _ = ms.reclaimHost()
            })
        }
    }

    // MARK: Share settings (grab + canStartShare)

    private static func addShareSettingActions(_ alert: UIAlertController, ms: MobileRTCMeetingService) {
        alert.addAction(UIAlertAction(title: "Customized PollingUrl", style: .default) { _ in
            ms.setCustomizedPollingUrl("", bCreate: true)
        })
        alert.addAction(UIAlertAction(title: "enable GrabShareWithoutReminder", style: .default) { _ in
            MobileRTC.shared().getMeetingSettings()?.enableGrabShareWithoutReminder(true)
        })
        alert.addAction(UIAlertAction(title: "disable GrabShareWithoutReminder", style: .default) { _ in
            MobileRTC.shared().getMeetingSettings()?.enableGrabShareWithoutReminder(false)
        })
        alert.addAction(UIAlertAction(title: "canStartShare", style: .default) { _ in
            _ = ms.canStartShare()
        })
        alert.addAction(UIAlertAction(title: "canStartShareWhiteboard", style: .default) { _ in
            _ = ms.canStartShareWhiteboard()
        })
    }
}

// MARK: - Helpers

enum ClaimHostPresenter {
    static func present() {
        guard let top = (UIApplication.shared.delegate as? AppDelegate)?.topViewController() else { return }
        let alert = UIAlertController(title: "Claim Host Wit HostKey", message: "Input host key", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "host key" }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let hostKey = alert.textFields?.first?.text ?? ""
            guard !hostKey.isEmpty else { return }
            _ = MobileRTC.shared().getMeetingService()?.claimHost(withHostKey: hostKey)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        top.present(alert, animated: true)
    }
}

enum ChatPriviledgePresenter {

    static func present(ms: MobileRTCMeetingService, sender: UIButton) {
        if ms.isWebinarMeeting() {
            presentWebinarAlert(ms: ms, sender: sender)
        } else {
            presentMeetingAlert(ms: ms, sender: sender)
        }
    }

    private static func presentWebinarAlert(ms: MobileRTCMeetingService, sender: UIButton) {
        let alert = UIAlertController(title: "Allow attendees to chat with", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No one", style: .default) { _ in
            _ = ms.allowAttendeeChat(.chatWithNone)
        })
        alert.addAction(UIAlertAction(title: "Panelists", style: .default) { _ in
            _ = ms.allowAttendeeChat(.chatWithPanelist)
        })
        alert.addAction(UIAlertAction(title: "Panelists and Attendees", style: .default) { _ in
            _ = ms.allowAttendeeChat(.chatWithAll)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, sender: sender)
    }

    private static func presentMeetingAlert(ms: MobileRTCMeetingService, sender: UIButton) {
        let priv = ms.getAttendeeChatPriviledge()
        let title: String
        switch priv {
        case .no_One: title = "Allow Participants to Chat with: No one"
        case .host_Only: title = "Allow Participants to Chat with: Host Only"
        case .everyone_Publicly: title = "Allow Participants to Chat with: Everyone Publicly"
        case .everyone_Publicly_And_Privately: title = "Allow Participants to Chat with: Everyone Publicly And Privately"
        case .unknown: title = ""
        @unknown default: title = ""
        }
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No one", style: .default) { _ in
            _ = ms.changeAttendeeChatPriviledge(.no_One)
        })
        alert.addAction(UIAlertAction(title: "Host Only", style: .default) { _ in
            _ = ms.changeAttendeeChatPriviledge(.host_Only)
        })
        alert.addAction(UIAlertAction(title: "Everyone Publicly", style: .default) { _ in
            _ = ms.changeAttendeeChatPriviledge(.everyone_Publicly)
        })
        if !ms.isPrivateChatDisabled() {
            alert.addAction(UIAlertAction(title: "Everyone Publicly And Privately", style: .default) { _ in
                _ = ms.changeAttendeeChatPriviledge(.everyone_Publicly_And_Privately)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, sender: sender)
    }

    private static func present(_ alert: UIAlertController, sender: UIButton) {
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }
}
