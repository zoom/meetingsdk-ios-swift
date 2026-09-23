//
//  SDKStartJoinMeetingPresenter+ShareServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onSinkSharingStatus(_ shareInfo: MobileRTCSSharingSourceInfo) {
        Logger.info("MobileRTC onSinkSharingStatus status=\(shareInfo.getStatus().rawValue) userID=\(shareInfo.getUserID())")
        toCustomVC { $0.handleSinkSharingStatus(shareInfo) }
        toOpenGLVC { $0.onSinkSharingStatus(shareInfo) }
    }

    func onShareContentChanged(_ shareInfo: MobileRTCSSharingSourceInfo) {
        Logger.info("MobileRTC onShareContentChanged contentType=\(shareInfo.getContentType().rawValue)")
    }

    func onSinkShareSizeChange(_ userID: UInt) {
        Logger.info("MobileRTC onSinkShareSizeChange userID=\(userID)")
        toCustomVC { $0.handleSinkShareSizeChange(userID) }
    }

    func onShareFromMainSession(_ sharingID: UInt,
                                shareStatus status: MobileRTCSharingStatus,
                                shareAction: MobileRTCShareAction?) {
        Logger.info("MobileRTC onShareFromMainSession status=\(status.rawValue) sharingID=\(sharingID)")
        toCustomVC { $0.handleShareFromMainSession(sharingID, status: status, shareAction: shareAction) }
    }

    func onAppShareSplash() {
        Logger.info("MobileRTC onAppShareSplash")
        mainVC?.onAppShareSplash()
    }
}
