//
//  SwiftCustomMeetingViewController+MeetingDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

/// Meeting state, audio/video, share, and waiting-room callback handling for the custom UI.
/// `SDKStartJoinMeetingPresenter` forwards relevant events here when a custom UI is active.
extension SwiftCustomMeetingViewController {

    func handleMeetingStateChange(_ state: MobileRTCMeetingState) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        switch state {
        case .inMeeting:
            videoVC.preVideoView.removeFromSuperview()
            ms.showWhiteboard(byParentViewCtroller: self)
            ms.showDoc(byParentViewCtroller: self)
            thumbView.isHidden = ms.isWebinarAttendee()
            updateVideoOrShare()
            MobileRTC.shared().getMeetingSettings()?.enableZoomDocs(true)
        case .leaveBO:
            remoteShareVC.shareAction = nil
        default:
            break
        }
    }

    func handleSinkMeetingActiveVideo(_ userID: UInt) {
        pinUserId = userID
        updateVideoOrShare()
    }

    func handleSinkMeetingAudioStatusChange(_ userID: UInt) {
        updateMyAudioStatus()
        updateVideoOrShare()
    }

    func handleSinkMeetingMyAudioTypeChange() {
        updateMyAudioStatus()
    }

    func handleSinkMeetingVideoStatusChange(_ userID: UInt) {
        updateMyVideoStatus()
        updateVideoOrShare()
    }

    func handleMyVideoStateChange() {
        updateMyVideoStatus()
        updateVideoOrShare()
    }

    func handleSinkMeetingUserJoin(_ userID: UInt) {
        updateVideoOrShare()
    }

    func handleIndicatorItemReceived(_ handler: MobileRTCIndicatorHandler) {
        _ = handler.showIndicatorPane(view, originPoint: CGPoint(x: 80, y: 100))
    }

    func handleIndicatorItemRemoved(_ handler: MobileRTCIndicatorHandler) {
        _ = handler.hideIndicatorPanel()
    }

    func handleAppSignalPanelUpdated(_ handler: MobileRTCAppSignalPanelHandler) {
        _ = handler.showAppSignal(in: view, originPoint: CGPoint(x: 0, y: 100))
    }

    func handlePSUserStatusChanged(_ userId: UInt, isStart: Bool) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if isStart {
            pinUserId = userId
            updateVideoOrShare()
            return
        }
        let userIDs = ms.getInMeetingUserList() ?? []
        for id in userIDs where ms.isHostUser(id.uintValue) {
            pinUserId = id.uintValue
            updateVideoOrShare()
            return
        }
    }

    func handleSinkMeetingUserLeft(_ userID: UInt) {
        pinUserId = 0
        updateVideoOrShare()
    }

    func handleWaitingRoomStatusChange(_ needWaiting: Bool) {
        if needWaiting {
            let vc = UIViewController()
            vc.title = "Need wait for host Approve"
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Leave", comment: ""),
                style: .plain,
                target: self,
                action: #selector(onWaitingLeaveTapped)
            )
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func onWaitingLeaveTapped() {
        actionPresenter.leaveMeeting()
        dismiss(animated: true)
    }

    // MARK: Share

    func handleSinkSharingStatus(_ shareInfo: MobileRTCSSharingSourceInfo) {
        let status = shareInfo.getStatus()
        let userID = shareInfo.getUserID()
        let shareSourceID = shareInfo.getShareSourceID()

        guard let ms = MobileRTC.shared().getMeetingService() else { return }

        if status == .self_Send_Begin, ms.isMeetingChatLegalNoticeAvailable() {
            let title = ms.getChatLegalNoticesPrompt()
            let body = ms.getChatLegalNoticesExplained()
            let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            (UIApplication.shared.delegate as? AppDelegate)?
                .topViewController()?
                .present(alert, animated: true)
        }

        updateMyShareStatus()

        switch status {
        case .self_Send_Begin:
            if ms.isMyself(userID), ms.isDeviceSharing() {
                return
            }
            showLocalShareView()
        case .other_Share_Begin:
            remoteShareVC.activeShareID = shareSourceID
            showRemoteShareView()
        case .self_Send_End, .other_Share_End:
            hideAnnotationView()
            showVideoView()
        default:
            break
        }
    }

    func handleShareFromMainSession(_ sharingID: UInt,
                                    status: MobileRTCSharingStatus,
                                    shareAction: MobileRTCShareAction?) {
        switch status {
        case .other_Share_Begin:
            remoteShareVC.shareAction = shareAction
            showRemoteShareView()
        case .other_Share_End:
            hideAnnotationView()
            showVideoView()
            remoteShareVC.shareAction = nil
        default:
            break
        }
    }

    func handleSinkShareSizeChange(_ userID: UInt) {
        guard remoteShareVC.parent != nil else { return }
        remoteShareVC.shareView.changeShareScale(withShareSourceID: userID)
    }

    func handleSinkMeetingShareReceiving(_ userID: UInt) {
        guard remoteShareVC.parent != nil else { return }
        remoteShareVC.shareView.changeShareScale(withShareSourceID: userID)
    }
}
