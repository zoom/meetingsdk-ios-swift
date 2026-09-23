//
//  SDKStartJoinMeetingPresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os
import UIKit

// TODO: Add in-app UI for `SampleMeetingUserDefaultsKey` toggles (e.g. raw data send) and full raw-data / OpenGL custom meeting UI if required.

/// Coordinates start/join flows and forwards `MobileRTCMeetingServiceDelegate` callbacks to `MainViewController`.
final class SDKStartJoinMeetingPresenter: NSObject {

    weak var mainVC: MainViewController?
    weak var rootVC: UIViewController?
    var customMeetingViewController: SwiftCustomMeetingViewController?
    var openGLMeetingViewController: OpenGLViewController?

    func startMeeting(_ appShare: Bool, rootVC: UIViewController) {
        self.rootVC = rootVC
        initDelegate()
        checkMeetingSettingSendRawdataEnable()
        if MobileRTC.shared().getAuthService()?.isLoggedIn() == true {
            startMeetingEmailLoginUser(appShare)
        } else {
            startMeetingRestApiWithoutLoginUser(appShare)
        }
    }

    func joinMeeting(meetingNo: String, password: String?, rootVC: UIViewController) {
        guard !meetingNo.isEmpty else { return }
        self.rootVC = rootVC
        initDelegate()
        checkMeetingSettingSendRawdataEnable()
        joinMeetingWithParam(meetingNo: meetingNo, password: password ?? "")
    }

    func handZoomWebUrl(_ url: String?, rootVC: UIViewController) {
        self.rootVC = rootVC
        initDelegate()
        checkMeetingSettingSendRawdataEnable()
        guard let url else { return }
        MobileRTC.shared().getMeetingService()?.handZoomWebUrl(url)
    }

    private func initDelegate() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        ms.delegate = self
        ms.getSmartSummaryHelper().delegate = self
        if MobileRTC.shared().isEnabledCustomizeMeetingUI() {
            ms.customizedUImeetingDelegate = self
        }
    }

    private func checkMeetingSettingSendRawdataEnable() {
        let enable = UserDefaults.standard.bool(forKey: SampleMeetingUserDefaultsKey.rawDataSendEnable)
        if enable {
            Logger.info("raw.data.send.enable is true")
            RawDataVideoSourceManager.shared.setEnabled(true)
        }
    }

    deinit {
        MobileRTC.shared().getMeetingService()?.customizedUImeetingDelegate = nil
    }

    /// Forwards an SDK delegate callback into the active custom meeting controller on the main thread.
    /// The SDK does not guarantee every callback fires on main; forwarding here keeps UI work main-bound.
    func toCustomVC(_ block: @escaping (SwiftCustomMeetingViewController) -> Void) {
        let run = { [weak self] in
            guard let vc = self?.customMeetingViewController else { return }
            block(vc)
        }
        if Thread.isMainThread { run() } else { DispatchQueue.main.async(execute: run) }
    }

    /// Forwards an SDK delegate callback into the active OpenGL/raw-data meeting controller on the main thread.
    /// `customMeetingViewController` and `openGLMeetingViewController` are mutually exclusive at runtime,
    /// so call sites can forward to both — the inactive one no-ops.
    func toOpenGLVC(_ block: @escaping (OpenGLViewController) -> Void) {
        let run = { [weak self] in
            guard let vc = self?.openGLMeetingViewController else { return }
            block(vc)
        }
        if Thread.isMainThread { run() } else { DispatchQueue.main.async(execute: run) }
    }
}

extension SDKStartJoinMeetingPresenter: MobileRTCAICompanionSmartSummaryHelperDelegate {}
