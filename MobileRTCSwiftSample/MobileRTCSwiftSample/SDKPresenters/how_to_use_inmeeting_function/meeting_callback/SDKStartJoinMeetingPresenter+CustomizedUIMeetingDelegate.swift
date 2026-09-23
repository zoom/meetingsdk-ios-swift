//
//  SDKStartJoinMeetingPresenter+CustomizedUIMeetingDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter: MobileRTCCustomizedUIMeetingDelegate {
    func onInitMeetingView() {
        guard let rootVC else { return }
        let rawDataUI = UserDefaults.standard.bool(forKey: SampleMeetingUserDefaultsKey.rawDataUIEnable)
        if rawDataUI {
            let openGLVC = OpenGLViewController()
            openGLMeetingViewController = openGLVC
            rootVC.addChild(openGLVC)
            rootVC.view.addSubview(openGLVC.view)
            openGLVC.didMove(toParent: rootVC)
            openGLVC.view.frame = rootVC.view.bounds
            return
        }
        let vc = SwiftCustomMeetingViewController()
        customMeetingViewController = vc
        rootVC.addChild(vc)
        rootVC.view.addSubview(vc.view)
        vc.didMove(toParent: rootVC)
        vc.view.frame = rootVC.view.bounds
    }

    func onDestroyMeetingView() {
        if let openGLVC = openGLMeetingViewController {
            openGLVC.willMove(toParent: nil)
            openGLVC.view.removeFromSuperview()
            openGLVC.removeFromParent()
            openGLMeetingViewController = nil
            return
        }
        guard let vc = customMeetingViewController else { return }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        customMeetingViewController = nil
    }
}
