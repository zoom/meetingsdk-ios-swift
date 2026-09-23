//
//  SDKStartJoinMeetingPresenter+VideoServiceDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onSinkMeetingActiveVideo(_ userID: UInt) {
        Logger.info("MobileRTC onSinkMeetingActiveVideo userID=\(userID)")
        toCustomVC { $0.handleSinkMeetingActiveVideo(userID) }
    }

    func onSinkMeetingPreviewStopped() {
        Logger.info("MobileRTC onSinkMeetingPreviewStopped")
    }

    func onSinkMeetingVideoStatusChange(_ userID: UInt) {
        Logger.info("MobileRTC onSinkMeetingVideoStatusChange userID=\(userID)")
        toCustomVC { $0.handleSinkMeetingVideoStatusChange(userID) }
        toOpenGLVC { $0.onSinkMeetingVideoStatusChange(userID) }
    }

    func onSinkMeetingVideoStatusChange(_ userID: UInt, videoStatus: MobileRTC_VideoStatus) {
        Logger.info("MobileRTC onSinkMeetingVideoStatusChange userID=\(userID) status=\(videoStatus.rawValue)")
    }

    func onMyVideoStateChange() {
        Logger.info("MobileRTC onMyVideoStateChange")
        toCustomVC { $0.handleMyVideoStateChange() }
        toOpenGLVC { $0.onMyVideoStateChange() }
    }

    func onSinkMeetingVideoQualityChanged(_ quality: MobileRTCNetworkQuality, userID: UInt) {
        Logger.info("MobileRTC onSinkMeetingVideoQualityChanged quality=\(quality.rawValue) userID=\(userID)")
    }

    func onSinkMeetingVideoRequestUnmuteByHost(_ completion: @escaping (Bool) -> MobileRTCSDKError) {
        Logger.info("MobileRTC onSinkMeetingVideoRequestUnmuteByHost — auto-accept")
        let err = completion(true)
        Logger.info("MobileRTC onSinkMeetingVideoRequestUnmuteByHost accept result=\(err.rawValue)")
    }
}
