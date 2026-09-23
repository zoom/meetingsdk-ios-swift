//
//  SDKStartJoinMeetingPresenter+UserServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onMyHandStateChange() {
        Logger.info("onMyHandStateChange")
    }

    func onSinkMeetingUserJoin(_ userID: UInt) {
        Logger.info("onSinkMeetingUserJoin=\(userID)")
        toCustomVC { $0.handleSinkMeetingUserJoin(userID) }
        toOpenGLVC { $0.onSinkMeetingUserJoin(userID) }
    }

    func onSinkMeetingUserLeft(_ userID: UInt) {
        Logger.info("onSinkMeetingUserLeft=\(userID)")
        toCustomVC { $0.handleSinkMeetingUserLeft(userID) }
        toOpenGLVC { $0.onSinkMeetingUserLeft(userID) }
    }

    func onInMeetingUserUpdated() {
        let users = MobileRTC.shared().getMeetingService()?.getInMeetingUserList() ?? []
        Logger.info("onInMeetingUserUpdated=\(users)")
    }

    func onInMeetingUserAvatarPathUpdated(_ userID: UInt) {
        let userInfo = MobileRTC.shared().getMeetingService()?.userInfo(byID: userID)
        Logger.info("onInMeetingUserAvatarPathUpdated=\(userID) hasAvatarPath=\(userInfo?.avatarPath != nil)")
    }

    func onChatMessageNotification(_ chatInfo: MobileRTCMeetingChat?) {
        // Do not log `chatInfo.content`: chat messages are L4 customer content.
        Logger.info("onChatMessageNotification hasContent=\(chatInfo?.content != nil)")
    }

    func onChatMsgDeleteNotification(_ msgID: String, deleteBy: MobileRTCChatMessageDeleteType) {
        Logger.info("onChatMsgDeleteNotification id=\(msgID) deleteBy=\(deleteBy.rawValue)")
    }

    func onChatMessageEditNotification(_ chatInfo: MobileRTCMeetingChat?) {
        // Do not log `chatInfo.content`: chat messages are L4 customer content.
        Logger.info("onChatMessageEditNotification hasContent=\(chatInfo?.content != nil)")
    }

    func onSinkUserNameChanged(_ userNameChangedArr: [NSNumber]?) {
        Logger.info("onSinkUserNameChanged=\(String(describing: userNameChangedArr))")
    }

    func onSinkMeetingUserRaiseHand(_ userID: UInt) {
        Logger.info("onSinkMeetingUserRaiseHand=\(userID)")
    }

    func onSinkMeetingUserLowerHand(_ userID: UInt) {
        Logger.info("onSinkMeetingUserLowerHand=\(userID)")
    }

    func onMeetingHostChange(_ hostId: UInt) {
        Logger.info("onMeetingHostChange=\(hostId)")
    }

    func onMeetingCoHostChange(_ userID: UInt, isCoHost: Bool) {
        Logger.info("onMeetingCoHostChange userID=\(userID) isCoHost=\(isCoHost)")
    }

    func onClaimHostResult(_ error: MobileRTCClaimHostError) {
        Logger.info("onClaimHostResult=\(error.rawValue)")
    }
}
