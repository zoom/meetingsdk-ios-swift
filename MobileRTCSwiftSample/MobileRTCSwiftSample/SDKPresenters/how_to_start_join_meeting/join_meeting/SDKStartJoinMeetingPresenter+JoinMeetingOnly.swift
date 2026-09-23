//
//  SDKStartJoinMeetingPresenter+JoinMeetingOnly.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os
import UIKit

extension SDKStartJoinMeetingPresenter {
    func joinMeetingWithParam(meetingNo: String, password: String) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let joinParam = MobileRTCMeetingJoinParam()
        joinParam.userName = UIDevice.current.name
        joinParam.meetingNumber = meetingNo
        joinParam.password = password
        joinParam.onBehalfToken = SampleMeetingConstants.onBehalfToken

        let ret = ms.joinMeeting(with: joinParam)
        let ok = (ret == .success)
        Logger.info("joinMeeting result: \(ok ? "success" : "\(ret.rawValue)")")
    }
}
