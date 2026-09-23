//
//  SDKSharePresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Foundation
import MobileRTC
import UIKit

/// Share actions (start/stop app share, attach share view) for the custom in-meeting UI.
final class SDKSharePresenter: NSObject {

    func startOrStopAppShare() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isStartingShare() {
            ms.stopAppShare()
        } else {
            ms.startAppShare()
        }
    }

    func appShare(withView view: UIView) {
        MobileRTC.shared().getMeetingService()?.appShare(withView: view)
    }
}
