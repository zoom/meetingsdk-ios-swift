//
//  SDKActionPresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Foundation
import MobileRTC
import UIKit

/// Meeting-level actions (host/leave/lock) for the custom in-meeting UI.
final class SDKActionPresenter: NSObject {

    func isMeetingHost() -> Bool {
        MobileRTC.shared().getMeetingService()?.isMeetingHost() ?? false
    }

    func leaveMeeting() {
        MobileRTC.shared().getMeetingService()?.leaveMeeting(with: .leave)
    }

    func endMeeting() {
        MobileRTC.shared().getMeetingService()?.leaveMeeting(with: .end)
    }

    func presentParticipantsViewController() {
        guard
            let ms = MobileRTC.shared().getMeetingService(),
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let top = appDelegate.topViewController()
        else { return }
        ms.presentParticipantsViewController(top)
    }

    @discardableResult
    func toggleMeetingLock() -> Bool {
        guard let ms = MobileRTC.shared().getMeetingService() else { return false }
        return ms.lockMeeting(!ms.isMeetingLocked())
    }

    @discardableResult
    func toggleShareLock() -> Bool {
        guard let ms = MobileRTC.shared().getMeetingService() else { return false }
        let nextLocked = ms.getShareSettingType() != .lockShare
        let err = ms.setShareSettingType(nextLocked ? .lockShare : .anyoneGrab)
        return err == .success
    }
}
