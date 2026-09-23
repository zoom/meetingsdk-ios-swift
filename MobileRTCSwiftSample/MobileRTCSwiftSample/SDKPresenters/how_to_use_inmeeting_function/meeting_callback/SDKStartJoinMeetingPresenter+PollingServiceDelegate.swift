//
//  SDKStartJoinMeetingPresenter+PollingServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onPollingStatusChanged(_ pollingID: String?, status: MobileRTCPollingStatus) {
        Logger.info("Polling onPollingStatusChanged pollingID=\(pollingID ?? "") status=\(status.rawValue)")
    }

    func onPollingResultUpdated(_ pollingID: String?) {
        Logger.info("Polling onPollingResultUpdated pollingID=\(pollingID ?? "")")
    }

    func onPollingListUpdated() {
        Logger.info("Polling onPollingListUpdated")
        NotificationCenter.default.post(name: .pollingDataUpdate, object: nil)
    }

    func onPollingActionResult(_ actionType: MobileRTCPollingActionType, pollingID: String?, bSuccess: Bool, errorMsg: String?) {
        Logger.info("Polling onPollingActionResult action=\(actionType.rawValue) pollingID=\(pollingID ?? "") success=\(bSuccess) error=\(errorMsg ?? "")")
    }

    func onPollingQuestionImageDownloaded(_ questionID: String?, path: String?) {
        Logger.info("Polling onPollingQuestionImageDownloaded questionID=\(questionID ?? "") path=\(path ?? "")")
    }

    func onPollingElapsedTime(_ pollingID: String?, uElapsedtime: Int32) {
        Logger.info("Polling onPollingElapsedTime pollingID=\(pollingID ?? "") elapsed=\(uElapsedtime)")
    }

    func onGetRightAnswerListPrivilege(_ bCan: Bool) {
        Logger.info("Polling onGetRightAnswerListPrivilege bCan=\(bCan)")
    }

    func onPollingInactive() {
        Logger.info("Polling onPollingInactive")
    }
}
