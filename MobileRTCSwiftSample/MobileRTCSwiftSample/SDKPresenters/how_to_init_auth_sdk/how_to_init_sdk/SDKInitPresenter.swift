//
//  SDKInitPresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import os
import MobileRTC

class SDKInitPresenter {
    
    func SDKInit(scene: UIScene, isCustomUI: Bool)
    {
        //1. initSDK
        let context =  MobileRTCSDKInitContext()
        context.domain = kSDKDomain;
        context.enableLog = true;
        context.locale = MobileRTC_ZoomLocale.default;
        
        /**
         * if you need use screen share feature, Here are a few things to note:
         * <1> Create your own groupId on the Apple Developer Web site, and fill the group ID in here and in the SampleHandler.mm
         * <2> Create an "App Groups" Capability in the main project target and the replayKit project target, and select the groupId correctly.
         * <3> If you can't select groupId correctly in "App Groups" Capability, Please check MobileRTCSample.Entitlements and MobileRTCSampleScreenShare.entitlements this two files, here also need to configure the correct group id. etc:
         *   <key>com.apple.security.application-groups</key>
         <array>
         <string> your group id </string>
         </array
         *
         * For details, please refer: https://marketplace.zoom.us/docs/sdk/native-sdks/iOS/mastering-zoom-sdk/in-meeting-function/screen-share
         *
         * if you don't need screen share feature, appGroupId can fill an empty string, or delete the bottom line. And delete MobileRTCSampleScreenShare target.
         */
        context.enableCustomizeMeetingUI = isCustomUI;
        context.appGroupId = "" // set your App Group ID for screen share; see Zoom docs
        let initializeSuc = MobileRTC.shared().initialize(context)
        Logger.info("MobileRTC initialize======>\(initializeSuc ? "success" : "fail")")

        Logger.info("MobileRTC Version: \(MobileRTC.shared().mobileRTCVersion() ?? "")")
        
        //   // 2.This method is optional, MobileRTC will read Custom Localizable file from App’s main bundle first.
        //       MobileRTC.shared().setMobileRTCCustomLocalizableName("Custom");
        //   //3. Set Root UIScene
        //   //Note: This step is optional, If app’s rootViewController is not a UIScene, just ignore this step.
        MobileRTC.shared().setMobileRTCPresentationScene(scene)
    }
    
    //func isChinaLocale() -> Bool {
    //    let localeIdentifier = Locale.current.identifier
    //    guard !localeIdentifier.isEmpty else { return false }
    //    return localeIdentifier.hasSuffix("_CN") || localeIdentifier.contains("_CN_")
    //}
    
}
