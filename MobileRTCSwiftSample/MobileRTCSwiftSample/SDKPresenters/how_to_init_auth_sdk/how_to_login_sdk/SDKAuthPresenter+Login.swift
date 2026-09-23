//
//  SDKAuthPresenter+Login.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC

extension SDKAuthPresenter {
    func getSSODomain(vanityURL: String) -> String {
        MobileRTC.shared().getAuthService()?.generateSSOLoginWebURL(vanityURL) ?? ""
    }

    @discardableResult
    func ssoLogin(webURIProtocol: String) -> MobileRTCLoginFailReason {
        MobileRTC.shared().getAuthService()?.ssoLogin(withWebUriProtocol: webURIProtocol) ?? .otherIssue
    }
}
