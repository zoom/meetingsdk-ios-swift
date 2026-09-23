//
//  SDKStartJoinMeetingPresenter+WebinarServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onSinkAllowAttendeeChatNotification(_ currentPrivilege: MobileRTCChatAllowAttendeeChat) {
        Logger.info("onSinkAllowAttendeeChatNotification \(currentPrivilege.rawValue)")
    }

    func onSinkQAAllowAskQuestionAnonymouslyNotification(_ beAllowed: Bool) {
        Logger.info("onSinkQAAllowAskQuestionAnonymouslyNotification \(beAllowed)")
    }

    func onSinkQAAllowAttendeeViewAllQuestionNotification(_ beAllowed: Bool) {
        Logger.info("onSinkQAAllowAttendeeViewAllQuestionNotification \(beAllowed)")
    }

    func onSinkQAAllowAttendeeUpVoteQuestionNotification(_ beAllowed: Bool) {
        Logger.info("onSinkQAAllowAttendeeUpVoteQuestionNotification \(beAllowed)")
    }

    func onSinkQAAllowAttendeeAnswerQuestionNotification(_ beAllowed: Bool) {
        Logger.info("onSinkQAAllowAttendeeAnswerQuestionNotification \(beAllowed)")
    }

    func onSinkQAConnectStarted() {
        let enabled = MobileRTC.shared().getMeetingService()?.isQAEnabled() ?? false
        Logger.info("Webinar Q&A onSinkQAConnectStarted QA Enable=\(enabled)")
    }

    func onSinkQAConnected(_ connected: Bool) {
        let enabled = MobileRTC.shared().getMeetingService()?.isQAEnabled() ?? false
        Logger.info("Webinar Q&A onSinkQAConnected connected=\(connected) QA Enable=\(enabled)")
    }

    func onSinkQAOpenQuestionChanged(_ count: Int) {
        Logger.info("Webinar Q&A onSinkQAOpenQuestionChanged count=\(count)")
    }
}
