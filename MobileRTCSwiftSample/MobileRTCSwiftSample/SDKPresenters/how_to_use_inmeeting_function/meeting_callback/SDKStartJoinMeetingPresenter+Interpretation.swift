//
//  SDKStartJoinMeetingPresenter+Interpretation.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onInterpretationStart() {
        Logger.info("Interpretation started")
    }

    func onInterpretationStop() {
        Logger.info("Interpretation stopped")
    }
}
