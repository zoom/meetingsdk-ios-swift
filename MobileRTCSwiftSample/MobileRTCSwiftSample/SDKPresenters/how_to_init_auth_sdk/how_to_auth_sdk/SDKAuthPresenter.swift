//
//  SDKAuthPresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import UIKit
import MobileRTC

final class SDKAuthPresenter: NSObject {
    var zpnsDeviceList: [MobileRTCInMeetingDeviceInfo] = []

    func SDKAuth(_ jwtToken: String) {
        guard let authService = MobileRTC.shared().getAuthService() else { return }
        authService.delegate = self
        authService.jwtToken = jwtToken
        authService.sdkAuth()
    }

    func presentOnTop(_ controller: UIViewController) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let top = appDelegate.topViewController() else { return }
        top.present(controller, animated: true)
    }
}
