//
//  SDKStartJoinMeetingPresenter+BOServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.

import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onHasCreatorRightsNotification(_ creator: MobileRTCBOCreator) {
        Logger.info("BO Own Creator")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onHasAdminRightsNotification(_ admin: MobileRTCBOAdmin) {
        Logger.info("BO Own Admin")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onHasAssistantRightsNotification(_ assistant: MobileRTCBOAssistant) {
        Logger.info("BO Own Assistant")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onHasAttendeeRightsNotification(_ attendee: MobileRTCBOAttendee) {
        Logger.info("BO Own Attendee")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onHasDataHelperRightsNotification(_ dataHelper: MobileRTCBOData) {
        Logger.info("BO Own Data Helper")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onLostCreatorRightsNotification() {
        Logger.info("BO Lost Creator")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onLostAdminRightsNotification() {
        Logger.info("BO Lost Admin")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onLostAssistantRightsNotification() {
        Logger.info("BO Lost Assistant")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onLostAttendeeRightsNotification() {
        Logger.info("BO Lost Attendee")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onLostDataHelperRightsNotification() {
        Logger.info("BO Lost DataHelper")
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
    }

    func onNewBroadcastMessageReceived(_ broadcastMsg: String?, senderID: UInt) {
        Logger.info("BO Broadcast Message Received \(broadcastMsg ?? "") from \(senderID)")
        NotificationCenter.default.post(name: .boBroadcastReceived, object: broadcastMsg)
    }

    func onHelpRequestReceived(_ strUserID: String?) {
        Logger.info("BO help request from \(strUserID ?? "")")
        guard let strUserID else { return }
        let defaults = UserDefaults.standard
        var list = defaults.array(forKey: kBOHelpRequesterIDsKey) as? [String] ?? []
        list.append(strUserID)
        defaults.set(list, forKey: kBOHelpRequesterIDsKey)
        NotificationCenter.default.post(name: .boHelpReceived, object: strUserID)
    }
}
