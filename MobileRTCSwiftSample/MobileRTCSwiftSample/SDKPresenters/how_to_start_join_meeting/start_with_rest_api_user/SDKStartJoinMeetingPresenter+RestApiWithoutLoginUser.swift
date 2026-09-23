//
//  SDKStartJoinMeetingPresenter+RestApiWithoutLoginUser.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func startMeetingRestApiWithoutLoginUser(_ appShare: Bool) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let user = MobileRTCMeetingStartParam4WithoutLoginUser()
        user.userType = .apiUser
        user.meetingNumber = SampleMeetingConstants.sdkMeetNumber
        user.userName = SampleMeetingConstants.sdkUserName
        user.isAppShare = appShare
        user.zak = SampleMeetingConstants.zak
        let ret = ms.startMeeting(with: user)
        Logger.info("startMeeting (REST / no login) result: \(ret.rawValue)")
    }
}
