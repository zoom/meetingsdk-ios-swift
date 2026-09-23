//
//  SDKStartJoinMeetingPresenter+LiveTranscription.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onSinkLiveTranscriptionStatus(_ status: MobileRTCLiveTranscriptionStatus) {
        Logger.info("Live transcription status=\(status.rawValue)")
    }

    func onLiveTranscriptionMsgInfoReceived(_ messageInfo: MobileRTCLiveTranscriptionMessageInfo?) {
        Logger.info("Live transcription message received (length=\(messageInfo?.messageContent?.count ?? 0))")
    }

    func onOriginalLanguageMsgReceived(_ messageInfo: MobileRTCLiveTranscriptionMessageInfo?) {
        Logger.info("Original language transcription message received (length=\(messageInfo?.messageContent?.count ?? 0))")
    }

    func onStartCaptionsRequestReceived(_ handler: MobileRTCCaptionsControlHandler?) {
        Logger.info("MobileRTC onStartCaptionsRequestReceived — auto-approve")
        if let off = handler as? MobileRTCCaptionsControlOffHandler {
            _ = off.approveStartCaptionsRequest(2)
        } else if let on = handler as? MobileRTCCaptionsControlOnHandler {
            _ = on.approveStartCaptionsRequest()
        }
    }
}
