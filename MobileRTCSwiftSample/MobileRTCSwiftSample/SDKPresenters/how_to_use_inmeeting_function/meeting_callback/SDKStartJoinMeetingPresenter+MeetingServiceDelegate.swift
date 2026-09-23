//
//  SDKStartJoinMeetingPresenter+MeetingServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os
import UIKit

extension SDKStartJoinMeetingPresenter: MobileRTCMeetingServiceDelegate {
    func onMeetingError(_ error: MobileRTCMeetError, message: String?) {
        Logger.info("MobileRTC onMeetingError code=\(error.rawValue)")
        guard error != MobileRTCMeetError.success else { return }
        let title = String(format: NSLocalizedString("Error Code:%zd", comment: ""), error.rawValue)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel))
        if let top = (UIApplication.shared.delegate as? AppDelegate)?.topViewController() {
            top.present(alert, animated: true)
        }
    }

    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        Logger.info("MobileRTC onMeetingStateChange state=\(state.rawValue)")
        mainVC?.onMeetingStateChange(state)
        toCustomVC { $0.handleMeetingStateChange(state) }
        toOpenGLVC { $0.onMeetingStateChange(state) }
        if state == .webinarPromote || state == .webinarDePromote {
            NotificationCenter.default.post(name: .qaWebinarRoleTransition, object: nil)
        }
    }

    // MARK: - Webinar Q&A

    func onSinkQAAddQuestion(_ questionID: String, success: Bool) {
        Logger.info("Webinar Q&A onSinkQAAddQuestion id=\(questionID) success=\(success)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkQAAddAnswer(_ answerID: String, success: Bool) {
        Logger.info("Webinar Q&A onSinkQAAddAnswer id=\(answerID) success=\(success)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkQuestionMarked(asDismissed questionID: String) {
        Logger.info("Webinar Q&A onSinkQuestionMarkedAsDismissed id=\(questionID)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkReopenQuestion(_ questionID: String) {
        Logger.info("Webinar Q&A onSinkReopenQuestion id=\(questionID)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkReceiveQuestion(_ questionID: String) {
        Logger.info("Webinar Q&A onSinkReceiveQuestion id=\(questionID)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkReceiveAnswer(_ answerID: String) {
        Logger.info("Webinar Q&A onSinkReceiveAnswer id=\(answerID)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkUserLivingReply(_ questionID: String) {
        Logger.info("Webinar Q&A onSinkUserLivingReply id=\(questionID)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkUserEndLiving(_ questionID: String) {
        Logger.info("Webinar Q&A onSinkUserEndLiving id=\(questionID)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkVoteupQuestion(_ questionID: String, orderChanged: Bool) {
        Logger.info("Webinar Q&A onSinkVoteupQuestion id=\(questionID) orderChanged=\(orderChanged)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkRevokeVoteupQuestion(_ questionID: String, orderChanged: Bool) {
        Logger.info("Webinar Q&A onSinkRevokeVoteupQuestion id=\(questionID) orderChanged=\(orderChanged)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkDeleteQuestion(_ questionIDArray: [String]) {
        Logger.info("Webinar Q&A onSinkDeleteQuestion count=\(questionIDArray.count)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }
    func onSinkDeleteAnswer(_ answerIDArray: [String]) {
        Logger.info("Webinar Q&A onSinkDeleteAnswer count=\(answerIDArray.count)")
        NotificationCenter.default.post(name: .qaDataUpdate, object: nil)
    }

    // MARK: - Indicator / signal panel / production studio

    func onIndicatorItemReceived(_ handler: MobileRTCIndicatorHandler?) {
        guard let handler else { return }
        toCustomVC { $0.handleIndicatorItemReceived(handler) }
    }

    func onIndicatorItemRemoved(_ handler: MobileRTCIndicatorHandler?) {
        guard let handler else { return }
        toCustomVC { $0.handleIndicatorItemRemoved(handler) }
    }

    func onAppSignalPanelUpdated(_ handler: MobileRTCAppSignalPanelHandler?) {
        guard let handler else { return }
        toCustomVC { $0.handleAppSignalPanelUpdated(handler) }
    }

    func onPSUserStatusChanged(_ userId: UInt, isStart: Bool) {
        toCustomVC { $0.handlePSUserStatusChanged(userId, isStart: isStart) }
    }

    func onWaitingRoomStatusChange(_ needWaiting: Bool) {
        toCustomVC { $0.handleWaitingRoomStatusChange(needWaiting) }
    }

    func onUserConfirm(toStartArchive handler: MobileRTCArchiveConfrimHandle?) {
        guard let handler else { return }
        Logger.info("MobileRTC onUserConfirmToStartArchive content=\(handler.getArchiveConfirmContent() ?? "")")
        _ = handler.join(withArchive: true)
    }

    func onUserConfirmRecoverMeeting(_ handler: MobileRTCRecoverMeetingHandle?) {
        guard let handler else { return }
        Logger.info("MobileRTC onUserConfirmRecoverMeeting content=\(handler.getRecoverMeetingContent() ?? "")")
        _ = handler.recoverMeeting(true)
    }

    func onFileReceived(_ receiver: MobileRTCFileReceiver?) {
        guard let receiver else { return }
        let fileName = receiver.transferInfo?.fileName ?? "received_file"
        Logger.info("FT onFileReceived senderID=\(receiver.getSenderUserId()) fileName=\(fileName)")
        _ = receiver.startReceive("\(NSTemporaryDirectory())/\(fileName)")
    }

    func onUVCCameraStatusChange(_ status: MobileRTCUVCCameraStatus) {
        Logger.info("MobileRTC onUVCCameraStatusChange status=\(status.rawValue)")
        guard status == .detached else { return }
        _ = MobileRTC.shared().getMeetingService()?.muteMyVideo(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            _ = MobileRTC.shared().getMeetingService()?.muteMyVideo(false)
        }
    }

    func onRecordingStatus(_ status: MobileRTCRecordingStatus) {
        Logger.info("MobileRTC onRecordingStatus=\(status.rawValue)")
        guard
            let ms = MobileRTC.shared().getMeetingService(),
            ms.isMeetingChatLegalNoticeAvailable(),
            status == .start,
            MobileRTC.shared().isEnabledCustomizeMeetingUI()
        else { return }
        presentSimpleAlert(title: "Recording", message: "Recording start")
    }

    func onRequestLocalRecordingPrivilegeReceived(_ handler: MobileRTCRequestLocalRecordingPrivilegeHandler?) {
        guard let handler else { return }
        let alert = UIAlertController(title: nil, message: "Receive the local recording request", preferredStyle: .alert)
        Logger.info("LocalRecording request id=\(handler.getRequestId() ?? "") requester=\(handler.getRequesterId()) name=\(handler.getRequesterName() ?? "")")
        alert.addAction(UIAlertAction(title: "Agree", style: .default) { _ in _ = handler.grantLocalRecordingPrivilege() })
        alert.addAction(UIAlertAction(title: NSLocalizedString("disagree", comment: ""), style: .cancel) { _ in _ = handler.denyLocalRecordingPrivilege() })
        presentOnTop(alert)
    }

    func onStartCloudRecordingRequested(_ handler: MobileRTCRequestStartCloudRecordingPrivilegeHandler?) {
        guard let handler else { return }
        let alert = UIAlertController(
            title: "MobileRTCRequestStartCloudRecordingPrivilegeHandler",
            message: "RequesterId:\(handler.getRequesterId()) RequesterName:\(handler.getRequesterName() ?? "")",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Grant", style: .default) { _ in _ = handler.grant() })
        alert.addAction(UIAlertAction(title: "Deny", style: .cancel) { _ in _ = handler.deny(false) })
        alert.addAction(UIAlertAction(title: "Deny all", style: .default) { _ in _ = handler.deny(true) })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default))
        presentOnTop(alert)
    }

    func onAICompanionFeatureTurnOff(byParticipant handler: MobileRTCAICompanionTurnOnAgainHandler?) {
        guard let handler else { return }
        let alert = UIAlertController(title: nil, message: "MobileRTCAICompanionTurnOnAgainHandler", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "turnOnAgain", style: .default) { _ in _ = handler.turnOnAgain() })
        alert.addAction(UIAlertAction(title: NSLocalizedString("agreeTurnOff", comment: ""), style: .cancel) { _ in _ = handler.agreeTurnOff() })
        presentOnTop(alert)
    }

    func onAICompanionFeatureSwitchRequested(_ handler: MobileRTCAICompanionSwitchHandler?) {
        guard let handler else { return }
        let alert = UIAlertController(
            title: nil,
            message: "MobileRTCAICompanionSwitchHandler \(handler.getRequestUserID()) isTurnOn:\(handler.isTurnOn())",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Agree YES", style: .default) { _ in _ = handler.agree(true) })
        alert.addAction(UIAlertAction(title: "Agree NO", style: .default) { _ in _ = handler.agree(false) })
        alert.addAction(UIAlertAction(title: NSLocalizedString("decline", comment: ""), style: .cancel) { _ in _ = handler.decline() })
        presentOnTop(alert)
    }

    private func presentSimpleAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
        presentOnTop(alert)
    }

    private func presentOnTop(_ alert: UIAlertController) {
        guard let top = (UIApplication.shared.delegate as? AppDelegate)?.topViewController() else { return }
        top.present(alert, animated: true)
    }

    func onMeetingParameterNotification(_ meetingParam: MobileRTCMeetingParameter?) {
        guard meetingParam != nil else { return }
        Logger.info("MobileRTC onMeetingParameterNotification (details omitted)")
    }

    func onMeetingReady() {
        Logger.info("MobileRTC onMeetingReady")
        mainVC?.onMeetingReady()
    }

    func onJoinMeetingConfirmed() {
        let meetingNo = MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber
        Logger.info("MobileRTC onJoinMeetingConfirmed meetingNumber present: \(!meetingNo.isEmpty)")
    }

    func onJoinMeetingInfoRequired(_ handler: MobileRTCJoinMeetingInfoHandler) {
        mainVC?.onJoinMeetingInfoRequired(handler)
    }

    func onClickedShareButton(_ parentVC: UIViewController, addShareActionItem array: NSMutableArray) -> Bool {
        mainVC?.onClickedShareButton(parentVC, addShareActionItem: array) ?? false
    }

    #if true
    func onClickedInviteButton(_ parentVC: UIViewController, addInviteActionItem array: NSMutableArray?) -> Bool {
        mainVC?.onClickedInviteButton(parentVC, addInviteActionItem: array) ?? false
    }
    #endif

    #if false
    func onClickedParticipantsButton(_ parentVC: UIViewController) -> Bool {
        mainVC?.onClickedParticipantsButton(parentVC) ?? false
    }

    func onClickedEndButton(_ parentVC: UIViewController, end endButton: UIButton) -> Bool {
        mainVC?.onClickedEndButton(parentVC, endButton: endButton) ?? false
    }

    func onClickedDialOut(_ parentVC: UIViewController, isCallMe me: Bool) {
        mainVC?.onClickedDialOut(parentVC, isCallMe: me)
    }

    func onJBHWaiting(with cmd: JBHCmd) {
        mainVC?.onJBHWaiting(withCmd: cmd)
    }
    #endif
}
