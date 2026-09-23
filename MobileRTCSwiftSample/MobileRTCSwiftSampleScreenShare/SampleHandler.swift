//
//  SampleHandler.swift
//  MobileRTCSwiftSampleScreenShare
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import ReplayKit

class SampleHandler: RPBroadcastSampleHandler, MobileRTCScreenShareServiceDelegate {
    private let screenShareService = MobileRTCScreenShareService()
    
    override init() {
        super.init()
        /**
        * if you need use screen share feature, Here are a few things to note:
        * <1> Create your own groupid on the Apple Developer Web site, and fill the group ID in here and in the AppDelegate.m
        * <2> Create an "App Groups" Capability in the main project target and the replayKit project target, and select the groupId correctly.
        * <3> If you can't select groupId correctly in "App Groups" Capability, Please check MobileRTCSample.Entitlements and MobileRTCSampleScreenShare.entitlements this two files, here also need to configure the correct group id.
        *   <key>com.apple.security.application-groups</key>
        <array>
            <string> your group id </string>
        </array
        *
        * For details, please refer: https://marketplace.zoom.us/docs/sdk/native-sdks/iOS/mastering-zoom-sdk/in-meeting-function/screen-share
        *
        * if you don't need screen share, please delete MobileRTCSwiftSampleScreenShare target.
        *
        */
        self.screenShareService.appGroup = "group.us.zoom.MobileRTCSwiftSample";
        self.screenShareService.delegate = self;
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        screenShareService.broadcastStarted(withSetupInfo: setupInfo ?? [:])
    }

    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        screenShareService.broadcastPaused()
    }

    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        screenShareService.broadcastResumed()
    }

    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        screenShareService.broadcastFinished()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        screenShareService.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }

    func mobileRTCScreenShareServiceFinishBroadcastWithError(_ error: Error!) {
        finishBroadcastWithError(error)
    }
}
