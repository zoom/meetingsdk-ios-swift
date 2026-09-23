//
//  SDKStartJoinMeetingPresenter+AudioServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onSinkMeetingAudioStatusChange(_ userID: UInt) {
        Logger.info("MobileRTC onSinkMeetingAudioStatusChange userID=\(userID)")
        toCustomVC { $0.handleSinkMeetingAudioStatusChange(userID) }
    }

    func onSinkMeetingAudioStatusChange(_ userID: UInt, audioStatus: MobileRTC_AudioStatus) {
        Logger.info("MobileRTC onSinkMeetingAudioStatusChange userID=\(userID) audioStatus=\(audioStatus.rawValue)")
    }

    func onSinkMeetingMyAudioTypeChange() {
        Logger.info("MobileRTC onSinkMeetingMyAudioTypeChange")
        toCustomVC { $0.handleSinkMeetingMyAudioTypeChange() }
    }

    func onSinkMeetingAudioTypeChange(_ userID: UInt) {
        Logger.info("MobileRTC onSinkMeetingAudioTypeChange userID=\(userID)")
    }

    func onMyAudioStateChange() {
        Logger.info("MobileRTC onMyAudioStateChange")
        toOpenGLVC { $0.onMyAudioStateChange() }
    }

    func onAudioOutputChange() {
        Logger.info("MobileRTC onAudioOutputChange")
    }
}
