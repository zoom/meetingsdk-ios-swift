//
//  SDKVideoPresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Foundation
import MobileRTC

/// Video actions (mute/start, camera switch, pin) for the custom in-meeting UI.
final class SDKVideoPresenter: NSObject {

    func muteMyVideo() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let ms = MobileRTC.shared().getMeetingService(), ms.canUnmuteMyVideo() else { return }
            _ = ms.muteMyVideo(ms.isSendingMyVideo())
        }
    }

    func switchMyCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            MobileRTC.shared().getMeetingService()?.switchMyCamera()
        }
    }

    @discardableResult
    func pinVideo(_ on: Bool, userID: UInt) -> Bool {
        MobileRTC.shared().getMeetingService()?.pinVideo(on, withUser: userID) ?? false
    }

    @discardableResult
    func stopUserVideo(_ userID: UInt) -> Bool {
        MobileRTC.shared().getMeetingService()?.stopUserVideo(userID) ?? false
    }

    @discardableResult
    func askUserStartVideo(_ userID: UInt) -> Bool {
        MobileRTC.shared().getMeetingService()?.askUserStartVideo(userID) ?? false
    }
}
