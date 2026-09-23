//
//  SDKReminderDemo.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

/// Surfaces reminder dialogs from the SDK (`MobileRTCReminderDelegate`).
final class SDKReminderDemo: NSObject, MobileRTCReminderDelegate {

    func setReminderDelegate() {
        MobileRTC.shared().getReminderHelper()?.reminderDelegate = self
    }

    func onReminderNotify(_ content: MobileRTCReminderContent?, handle reminderHandler: MobileRTCReminderHandler?) {
        guard let content, let handler = reminderHandler else { return }
        let alert = UIAlertController(
            title: content.title,
            message: content.content,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
            handler.accept()
        })
        alert.addAction(UIAlertAction(title: "Declined", style: .cancel) { _ in
            handler.declined()
        })
        alert.addAction(UIAlertAction(title: "Ignore", style: .default) { _ in
            handler.ignore()
        })
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let top = appDelegate.topViewController()
        else { return }
        top.present(alert, animated: true)
    }
}
