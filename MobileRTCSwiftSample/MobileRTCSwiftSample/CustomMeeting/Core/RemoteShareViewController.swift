//
//  RemoteShareViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

/// Renders incoming shared content. Either subscribes to a `MobileRTCShareAction`
/// (used in BO / main-session bridging) or falls back to a plain `MobileRTCActiveShareView`
/// driven by `activeShareID`.
final class RemoteShareViewController: UIViewController {

    var activeShareID: UInt = 0
    var shareAction: MobileRTCShareAction?
    var onAnnotationStartedSuccessfully: (() -> Void)?

    lazy var shareView: MobileRTCActiveShareView = {
        MobileRTCActiveShareView(frame: view.bounds)
    }()

    private lazy var remoteControl = CustomRemoteControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(shareView)
        remoteControl.setupRemoteControl(shareView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let action = shareAction, let active = action.getActiveShareView() {
            view.addSubview(active)
            active.frame = CGRect(
                x: 50,
                y: 100,
                width: view.bounds.width / 2,
                height: view.bounds.height / 2
            )
            action.setShareActionDelegate(self)
        } else {
            if shareView.superview == nil {
                view.addSubview(shareView)
                remoteControl.setupRemoteControl(shareView)
            }
        }
        updateShareView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let action = shareAction {
            _ = action.unsubscribe()
            action.getActiveShareView()?.removeFromSuperview()
        } else {
            shareView.stopActiveShare()
        }
    }

    func updateShareView() {
        if let action = shareAction {
            Logger.info("RemoteShare shareAction subscribe shareID=\(action.getShareID())")
            _ = action.subscribe()
            return
        }

        if activeShareID != 0 {
            shareView.showActiveShare(withShareSourceID: activeShareID)
            if let annoService = MobileRTC.shared().getAnnotationService(),
               annoService.startAnnotation(withSharedView: shareView) == .successed {
                onAnnotationStartedSuccessfully?()
            }
        } else {
            shareView.stopActiveShare()
        }
    }

    func stopShareView() {
        shareView.stopActiveShare()
    }
}

extension RemoteShareViewController: MobileRTCShareActionDelegate {
    func onSharingContentStartReceiving() {
        Logger.info("RemoteShare onSharingContentStartReceiving shareID=\(shareAction?.getShareID() ?? 0)")
    }

    func onAction(beforeDestroyed sharingID: UInt) {
        Logger.info("RemoteShare onActionBeforeDestroyed sharingID=\(sharingID)")
    }
}
