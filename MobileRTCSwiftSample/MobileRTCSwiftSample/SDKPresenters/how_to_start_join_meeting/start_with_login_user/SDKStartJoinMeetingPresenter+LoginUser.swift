//
//  SDKStartJoinMeetingPresenter+LoginUser.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func startMeetingEmailLoginUser(_ appShare: Bool) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let user = MobileRTCMeetingStartParam4LoginlUser()
        user.meetingNumber = SampleMeetingConstants.sdkMeetNumber
        user.isAppShare = appShare
        let ret = ms.startMeeting(with: user)
        Logger.info("startMeeting (logged in) result: \(ret.rawValue)")
    }
}
