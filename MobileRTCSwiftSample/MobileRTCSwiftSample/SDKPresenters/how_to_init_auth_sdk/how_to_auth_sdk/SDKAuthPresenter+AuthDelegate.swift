//
//  SDKAuthPresenter+AuthDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import os
import UIKit
import MobileRTC

extension SDKAuthPresenter: MobileRTCAuthDelegate, MobileRTCNotificationServiceHelperDelegate, MobileRTCPresenceHelperDelegate {

    func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        let ok = returnValue == .success
        Logger.info("MobileRTC onMobileRTCAuthReturn \(ok ? "Success" : "\(returnValue.rawValue)")")

        if returnValue != .success {
            let message = String(
                format: NSLocalizedString("SDK authentication failed, error code: %zd", comment: ""),
                returnValue.rawValue
            )
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: ""), style: .default) { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.SDKAuth(kJwtToken)
                }
            })
            presentOnTop(alert)
        } else {
            guard let authService = MobileRTC.shared().getAuthService() else { return }
            authService.enableAutoRegisterNotificationService(forLogin: true)
            guard let notifS = authService.getNotificationServiceHelper() else { return }
            notifS.delegate = self
            notifS.getPresenceHelper()?.delegate = self
        }
    }

    func onMobileRTCLoginResult(_ resultValue: MobileRTCLoginFailReason) {
        let ok = resultValue == .success
        Logger.info("MobileRTC onMobileRTCLoginResult result: \(ok ? "Success" : "\(resultValue.rawValue)")")
        if ok {
            NotificationCenter.default.post(name: Notification.Name("SDKOnLoginResult"), object: nil)
            if let auth = MobileRTC.shared().getAuthService(),
                auth.getAccountInfo() != nil {
                let userType = auth.getUserType()
                Logger.debug("accountInfo received, User Type: \(userType.rawValue)")
            }
        }
    }

    func onMobileRTCLogoutReturn(_ returnValue: Int) {
        Logger.info("MobileRTC onMobileRTCLogoutReturn result=\(returnValue)")
    }

    func onMeetingDeviceListChanged(_ deviceList: [MobileRTCInMeetingDeviceInfo]?) {
        guard let deviceList else { return }
        Logger.debug("MobileRTCInMeetingDeviceInfo count=\(deviceList.count)")
        zpnsDeviceList = deviceList
        NotificationCenter.default.post(name: Notification.Name("SDKOnLoginResult"), object: nil)
    }

    func onTransferMeetingStatus(_ bSuccess: Bool) {
        Logger.info("onTransferMeetingStatus \(bSuccess)")
    }

    func onTransferMeetingResult(_ handler: MobileRTCTransferMeetingHandler?) {
        guard let handler, handler.isSuccess else { return }
        let alertController = UIAlertController(
            title: "CompanionModeMeetingHandler",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
            handler.leaveCompanionToJoinMeeting()
        })
        alertController.addAction(UIAlertAction(title: "Declined", style: .cancel))
        presentOnTop(alertController)
    }

    func onRequestStarContact(_ contactIDList: [String]?) {
        Logger.debug("onRequestStarContact count: \(contactIDList?.count ?? 0)")
        guard
            let helper = MobileRTC.shared().getAuthService()?.getNotificationServiceHelper()?.getPresenceHelper(),
            let contactIDList
        else { return }
        _ = helper.subscribeContactPresence(contactIDList)
    }

    func onRequestContactDetailInfo(_ contactList: [MobileRTCContactInfo]?) {
        Logger.info("onRequestContactDetailInfo count: \(contactList?.count ?? 0)")
        contactList?.forEach { info in
            Logger.debug("info status: \(info.presenceStatus.rawValue)")
        }
    }

    func onUserPresenceChanged(_ contactID: String?, presenceStatus: MobileRTCPresenceStatus) {
        Logger.debug("onUserPresenceChanged status: \(presenceStatus.rawValue)")
    }

    func onStarContactListChanged(_ contactIDList: [String]?, isAdd: Bool) {
        Logger.debug("onStarContactListChanged count: \(contactIDList?.count ?? 0) add: \(isAdd)")
    }

    func onReceiveInvitation(toMeeting handler: MobileRTCInvitationMeetingHandler?) {
        guard let handler else { return }
        let message = String(
            format: "senderName:%@  meetingNumber:%lld  isChannelInvitation:%@  channelName:%@ channelMemberCount:%u",
            handler.senderName ?? "",
            handler.meetingNumber,
            handler.isChannelInvitation ? "true" : "false",
            handler.channelName ?? "",
            handler.channelMemberCount
        )
        let alertController = UIAlertController(
            title: "MobileRTCInvitationMeetingHandler",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "accept", style: .default) { _ in
            handler.accept()
        })
        alertController.addAction(UIAlertAction(title: "decline", style: .default) { _ in
            handler.decline()
        })
        presentOnTop(alertController)
    }

    func onMeetingInvitationCanceled(_ meetingNumber: Int64) {
        Logger.info("onMeetingInvitationCanceled \(meetingNumber)")
    }

    func onMeetingAccepted(byOtherDevice meetingNumber: Int64) {
        Logger.info("onMeetingAcceptedByOtherDevice \(meetingNumber)")
    }

    func onMeetingInvitationDeclined(_ contactID: String?) {
        Logger.info("onMeetingInvitationDeclined")
    }

    func onMeetingDeclined(byOtherDevice meetingNumber: Int64) {
        Logger.info("onMeetingDeclinedByOtherDevice \(meetingNumber)")
    }
}
