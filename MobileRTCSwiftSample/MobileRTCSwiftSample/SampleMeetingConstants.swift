//
//  SampleMeetingConstants.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import Foundation
import MobileRTC
import UIKit

/// Optional meeting / REST fields for the demo (fill from your server in production).
enum SampleMeetingConstants {
    static let sdkUserName: String = ""
    static let sdkUserToken: String = ""
    static let sdkMeetNumber: String = ""
    static let zak: String = ""
    static let customerKey: String = ""
    static let webinarToken: String = ""
    static let onBehalfToken: String = ""
}

/// UserDefaults keys for optional meeting / raw-data UI toggles.
enum SampleMeetingUserDefaultsKey {
    static let rawDataUIEnable = "raw.data.ui.enable"
    static let rawDataSendEnable = "raw.data.send.enable"
}

/// URL scheme registered for SSO / deep links (must match Info.plist `CFBundleURLSchemes` if used).
let ssoURLScheme = "zoomus"

private final class NoopExternalVideoSource: NSObject, MobileRTCVideoSourceDelegate {}

final class RawDataVideoSourceManager {
    static let shared = RawDataVideoSourceManager()

    private var videoSource: (NSObject & MobileRTCVideoSourceDelegate)?

    private init() {}

    func setEnabled(_ enabled: Bool) {
        if enabled {
            if videoSource == nil {
                videoSource = NoopExternalVideoSource()
            }
            if let source = videoSource {
                _ = MobileRTC.shared().getVideoSourceHelper()?.setExternalVideoSource(source, videoDataFormat: .I420)
            }
        } else {
            _ = MobileRTC.shared().getVideoSourceHelper()?.setExternalVideoSource(nil, videoDataFormat: .I420)
            videoSource = nil
        }
        UserDefaults.standard.set(enabled, forKey: SampleMeetingUserDefaultsKey.rawDataSendEnable)
    }
}
