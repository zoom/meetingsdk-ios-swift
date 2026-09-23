//
//  MainViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os
import UIKit

// MARK: - Layout & style

private enum MainLayout {
    static let horizontalPadding: CGFloat = 20
    /// Two primary buttons share the row: `width = 2×btn + 3×padding` (leading, middle, trailing gaps).
    static let primaryButtonRowPaddingMultiplier: CGFloat = 3
    static let primaryButtonMaxWidth: CGFloat = 160
    static let primaryButtonHeight: CGFloat = 46
    static let toolbarIconLarge: CGFloat = 50
    static let toolbarIconSmall: CGFloat = 30
    /// Vertical spacing from safe edge to button row (`1.5 × horizontalPadding`).
    static let bottomBarVerticalSpacingMultiplier: CGFloat = 1.5
    static let zpnsTableGapAboveJoinButton: CGFloat = 50
}

private enum MainColors {
    static let primaryActionBlue = UIColor(red: 45 / 255, green: 140 / 255, blue: 255 / 255, alpha: 1)
}

private enum MainTypography {
    static let primaryButton: CGFloat = 18
}

private enum MainTiming {
    static let sdkInitDelay: TimeInterval = 0.5
    static let shareToolbarIconUpdateDelay: TimeInterval = 0.25
    static let networkQualityClockInterval: TimeInterval = 1
}

private enum ZPNSTableMetrics {
    static let rowHeight: CGFloat = 50
    static let actionButtonWidth: CGFloat = 120
    static let actionButtonHeight: CGFloat = 30
    static let actionButtonMinY: CGFloat = 10
    /// `tag` offset so companion buttons don’t collide with transfer row tags.
    static let companionTagBase: Int = 10_000
    static let actionTitleFontSize: CGFloat = 16
    /// Second column X: `width - companionLeadingOffset` (join companion).
    static let companionLeadingOffset: CGFloat = 260
}

final class MainViewController: UIViewController {

    var authPresenter: SDKAuthPresenter?

    private lazy var meetButton: UIButton = makeMeetButton()
    private lazy var joinButton: UIButton = makeJoinButton()
    private lazy var shareButton: UIButton = makeAssetIconButton(named: "icon_resume", action: #selector(onShareBtn))
    private lazy var expandButton: UIButton = makeAssetIconButton(named: "icon_share_app", action: #selector(onExpand))
    private lazy var settingButton: UIButton = makeAssetIconButton(named: "icon_setting", action: #selector(onSettings))

    private var presenter: SDKStartJoinMeetingPresenter?

    private var reminderControl: SDKReminderDemo?

    private var introVC: IntroViewController?
    private var splashVC: SplashViewController?
    private var webVC: WebViewController?

    private var zpnsDeviceListTableView: UITableView?

    var isSharingWebView = false

    private var clockTimer: Timer?
    private weak var jbhWaitingNavController: UINavigationController?

    deinit {
        MobileRTC.shared().getMeetingService()?.customizedUImeetingDelegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        addChildShellViews()

        view.addSubview(expandButton)
        expandButton.isHidden = true

        view.addSubview(shareButton)
        shareButton.isHidden = true

        view.addSubview(settingButton)

        view.addSubview(meetButton)
        view.addSubview(joinButton)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLoginResultNotification),
            name: Notification.Name("SDKOnLoginResult"),
            object: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + MainTiming.sdkInitDelay) { [weak self] in
            self?.doSDKInitAndAuth()
        }
    }

    override var prefersStatusBarHidden: Bool { false }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //for bug that there exist 20 pixels in the bottom while leaving meeting quickly
        setNeedsStatusBarAppearanceUpdate()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        onLoginResultNotification()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        authPresenter?.zpnsDeviceList = []
        zpnsDeviceListTableView?.removeFromSuperview()
        zpnsDeviceListTableView = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = view.bounds
        let padding = MainLayout.horizontalPadding
        let iconLarge = MainLayout.toolbarIconLarge
        let iconSmall = MainLayout.toolbarIconSmall

        let btnWidth = min(
            floor((bounds.size.width - MainLayout.primaryButtonRowPaddingMultiplier * padding) / 2),
            MainLayout.primaryButtonMaxWidth
        )
        let btnHeight = MainLayout.primaryButtonHeight

        let safe = view.safeAreaInsets
        let safeTop = safe.top
        let safeBottom = safe.bottom

        let bottomBarY = bounds.size.height
            - MainLayout.bottomBarVerticalSpacingMultiplier * padding
            - btnHeight
            - safeBottom

        meetButton.frame = CGRect(
            x: bounds.size.width / 2 - btnWidth - padding / 2,
            y: bottomBarY,
            width: btnWidth,
            height: btnHeight
        )
        joinButton.frame = CGRect(
            x: bounds.size.width / 2 + padding / 2,
            y: bottomBarY,
            width: btnWidth,
            height: btnHeight
        )

        expandButton.frame = CGRect(
            x: bounds.size.width - iconLarge - padding,
            y: bounds.size.height - iconLarge - padding - safeBottom,
            width: iconLarge,
            height: iconLarge
        )

        settingButton.frame = CGRect(
            x: bounds.size.width - iconSmall - padding,
            y: MainLayout.bottomBarVerticalSpacingMultiplier * padding + safeTop,
            width: iconSmall,
            height: iconSmall
        )

        if let table = zpnsDeviceListTableView, authPresenter?.zpnsDeviceList.isEmpty == false {
            let count = authPresenter?.zpnsDeviceList.count ?? 0
            table.frame = CGRect(
                x: 0,
                y: joinButton.frame.minY - MainLayout.zpnsTableGapAboveJoinButton,
                width: UIScreen.main.bounds.width,
                height: ZPNSTableMetrics.rowHeight * CGFloat(count)
            )
        }
    }

    private func meetingPresenter() -> SDKStartJoinMeetingPresenter {
        if let p = presenter { return p }
        let p = SDKStartJoinMeetingPresenter()
        p.mainVC = self
        presenter = p
        return p
    }

    private func addChildShellViews() {
        let intro = IntroViewController()
        introVC = intro
        addChild(intro)
        view.insertSubview(intro.view, at: 0)
        intro.didMove(toParent: self)
        intro.view.frame = view.bounds

        let splash = SplashViewController()
        splashVC = splash
        addChild(splash)
        view.insertSubview(splash.view, at: 0)
        splash.didMove(toParent: self)
        splash.view.frame = view.bounds

        let web = WebViewController()
        webVC = web
        addChild(web)
        view.insertSubview(web.view, at: 0)
        web.didMove(toParent: self)
        web.view.frame = view.bounds
    }

    private func makeMeetButton() -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(NSLocalizedString("Meet Now", comment: ""), for: .normal)
        b.setTitleColor(MainColors.primaryActionBlue, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: MainTypography.primaryButton, weight: .semibold)
        b.addTarget(self, action: #selector(onMeetNow), for: .touchUpInside)
        return b
    }

    private func makeJoinButton() -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(NSLocalizedString("Join a Meeting", comment: ""), for: .normal)
        b.setTitleColor(MainColors.primaryActionBlue, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: MainTypography.primaryButton, weight: .semibold)
        b.addTarget(self, action: #selector(onJoinMeetingTapped), for: .touchUpInside)
        return b
    }

    private func makeAssetIconButton(named name: String, action: Selector) -> UIButton {
        let b = UIButton(type: .custom)
        if let image = UIImage(named: name) {
            b.setImage(image, for: .normal)
        }
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func doSDKInitAndAuth() {
        let alert = UIAlertController(
            title: "Choose ZoomUI or CustomUI",
            message: "You need choose ZoomUI or CustomUI when MobileRTC initialize.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ZoomUI", style: .default) { [weak self] _ in
            self?.runInitFlow(isCustomUI: false)
        })
        alert.addAction(UIAlertAction(title: "CustomUI", style: .default) { [weak self] _ in
            self?.runInitFlow(isCustomUI: true)
        })
        present(alert, animated: true)
    }

    private func runInitFlow(isCustomUI: Bool) {
        guard !kJwtToken.isEmpty, !kSDKDomain.isEmpty else {
            let alert = UIAlertController(
                title: NSLocalizedString("SDK credentials required", comment: ""),
                message: NSLocalizedString(
                    "Set kJwtToken and kSDKDomain in AppDelegate.swift before initializing the Meeting SDK.",
                    comment: ""
                ),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            present(alert, animated: true)
            return
        }
        guard let scene = view.window?.windowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            Logger.info("No UIWindowScene for SDK init")
            return
        }
        SDKInitPresenter().SDKInit(scene: scene, isCustomUI: isCustomUI)
        let auth = SDKAuthPresenter()
        authPresenter = auth
        auth.SDKAuth(kJwtToken)
        let reminder = SDKReminderDemo()
        reminder.setReminderDelegate()
        reminderControl = reminder
    }

    @objc private func onMeetNow() {
        guard MobileRTC.shared().getMeetingService() != nil else { return }

        let alert = UIAlertController(
            title: NSLocalizedString("Select Meeting Type", comment: ""),
            message: nil,
            preferredStyle: .alert
        )

        if MobileRTC.shared().isEnabledCustomizeMeetingUI() {
            let raw = UserDefaults.standard.bool(forKey: SampleMeetingUserDefaultsKey.rawDataUIEnable)
            if !raw {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Custom Meeting", comment: ""), style: .default) { [weak self] _ in
                    self?.startMeeting(appShare: false)
                })
            } else {
                alert.addAction(UIAlertAction(title: "Rawdata UI", style: .default) { [weak self] _ in
                    self?.startMeeting(appShare: false)
                })
            }
        } else {
            alert.addAction(UIAlertAction(title: NSLocalizedString("App Share Meeting", comment: ""), style: .default) { [weak self] _ in
                self?.startMeeting(appShare: true)
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Zoom Meeting", comment: ""), style: .default) { [weak self] _ in
                self?.startMeeting(appShare: false)
            })
            #if !targetEnvironment(simulator)
            if MobileRTC.shared().getDirectShareService()?.canStartDirectShare() ?? false {
                alert.addAction(UIAlertAction(title: NSLocalizedString("Direct Share", comment: ""), style: .default) { [weak self] _ in
                    self?.startDirectShare()
                })
            }
            #endif
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    #if !targetEnvironment(simulator)
    private func startDirectShare() {
        guard let ds = MobileRTC.shared().getDirectShareService() else { return }
        ds.startDirectShare()
        ds.delegate = self
    }
    #endif

    @objc private func onJoinMeetingTapped() {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("Please input the meeting number", comment: ""),
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = "#########"; $0.keyboardType = .numberPad }
        alert.addTextField { $0.placeholder = NSLocalizedString("Password", comment: ""); $0.isSecureTextEntry = true }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self] _ in
            let num = alert.textFields?[0].text ?? ""
            let pwd = alert.textFields?[1].text ?? ""
            self?.joinMeeting(meetingNo: num, password: pwd)
        })
        present(alert, animated: true)
    }

    @objc private func onShareBtn() {
        isSharingWebView.toggle()
        guard let ms = MobileRTC.shared().getMeetingService(), let web = webVC, let intro = introVC, let splash = splashVC else { return }
        if isSharingWebView {
            if ms.isDirectAppShareMeeting() {
                web.loadViewIfNeeded()
                intro.loadViewIfNeeded()
                guard let webView = web.webView else { return }
                guard let introView = intro.view, let webContainer = web.view else { return }
                view.insertSubview(webContainer, aboveSubview: introView)
                ms.appShare(withView: webView)
            }
        } else {
            intro.loadViewIfNeeded()
            web.loadViewIfNeeded()
            splash.loadViewIfNeeded()
            guard let introView = intro.view, let webContainer = web.view, let splashView = splash.view else { return }
            view.insertSubview(introView, aboveSubview: webContainer)
            ms.appShare(withView: splashView)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + MainTiming.shareToolbarIconUpdateDelay) { [weak self] in
            guard let self else { return }
            let assetName = self.isSharingWebView ? "icon_pause" : "icon_resume"
            if let image = UIImage(named: assetName) {
                self.shareButton.setImage(image, for: .normal)
            }
        }
    }

    @objc private func onExpand() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        ms.showMobileRTCMeeting {
            ms.stopAppShare()
        }
    }

    @objc private func onSettings() {
        guard MobileRTC.shared().getMeetingSettings() != nil else { return }
        let settingsVC = SettingsViewController(style: .insetGrouped)
        settingsVC.authPresenter = authPresenter
        let nav = UINavigationController(rootViewController: settingsVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func startMeeting(appShare: Bool) {
        meetingPresenter().startMeeting(appShare, rootVC: self)
    }

    private func joinMeeting(meetingNo: String, password: String) {
        guard !meetingNo.isEmpty else { return }
        meetingPresenter().joinMeeting(meetingNo: meetingNo, password: password, rootVC: self)
    }

    func handZoomWebUrl(_ url: String?) {
        meetingPresenter().handZoomWebUrl(url, rootVC: self)
    }

    @objc private func onLoginResultNotification() {
        let loggedIn = MobileRTC.shared().getAuthService()?.isLoggedIn() == true
        guard loggedIn else { return }
        zpnsDeviceListTableView?.removeFromSuperview()
        zpnsDeviceListTableView = nil
        guard let auth = authPresenter, !auth.zpnsDeviceList.isEmpty else { return }
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.isScrollEnabled = false
        zpnsDeviceListTableView = table
        view.addSubview(table)
        view.setNeedsLayout()
    }

    @objc private func onTransfer(_ sender: UIButton) {
        guard let list = authPresenter?.zpnsDeviceList else { return }
        let row = sender.tag
        guard row < list.count else { return }
        let info = list[row]
        let ret = MobileRTC.shared().getAuthService()?.getNotificationServiceHelper()?.transferMeeting(info.meetingId, mode: .transfer)
        Logger.info("transferMeeting result: \(String(describing: ret))")
    }

    @objc private func onJoinCompanion(_ sender: UIButton) {
        guard let list = authPresenter?.zpnsDeviceList else { return }
        let row = sender.tag - ZPNSTableMetrics.companionTagBase
        guard row >= 0, row < list.count else { return }
        let info = list[row]
        let ret = MobileRTC.shared().getAuthService()?.getNotificationServiceHelper()?.transferMeeting(info.meetingId, mode: .companoin)
        Logger.info("joinCompanion transfer result: \(String(describing: ret))")
    }

    func startClockTimer() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: MainTiming.networkQualityClockInterval, repeats: true) { [weak self] _ in
            self?.handleClockTimer()
        }
    }

    private func handleClockTimer() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let vSend = ms.queryNetworkQuality(.VIDEO, withDataFlow: true)
        let vRecv = ms.queryNetworkQuality(.VIDEO, withDataFlow: false)
        Logger.debug("Network video send=\(vSend.rawValue) recv=\(vRecv.rawValue)")
    }
}

extension MainViewController {

    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }

        if state == .ended, let web = webVC?.view, let splash = splashVC?.view, let intro = introVC?.view {
            view.insertSubview(web, aboveSubview: splash)
            view.insertSubview(intro, aboveSubview: web)
            view.bringSubviewToFront(meetButton)
            view.bringSubviewToFront(joinButton)
            view.bringSubviewToFront(expandButton)
            view.bringSubviewToFront(shareButton)
            view.bringSubviewToFront(settingButton)
        }

        let inAppShare = (state == .inMeeting) && ms.isDirectAppShareMeeting()
        expandButton.isHidden = !inAppShare
        shareButton.isHidden = !inAppShare
        meetButton.isHidden = inAppShare
        joinButton.isHidden = inAppShare

        if state != .inMeeting {
            isSharingWebView = false
        }

        if state == .inMeeting {
            let helper = MobileRTCInviteHelper.sharedInstance()
            let meetingNumber = helper.ongoingMeetingNumber
            let sms = String(format: NSLocalizedString("Please join meeting with ID: %@", comment: ""), meetingNumber)
            helper.inviteSMS = sms
            let joinURL = helper.joinMeetingURL
            let copyMsg = String(format: NSLocalizedString("Meeting URL: %@", comment: ""), joinURL)
            helper.inviteCopyURL = copyMsg
        }
    }

    func onMeetingReady() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isDirectAppShareMeeting() {
            if ms.isStartingShare() || ms.isViewingShare() {
                ms.showMobileRTCMeeting {
                    ms.stopAppShare()
                }
                return
            }
            let ret = ms.startAppShare()
            Logger.info("startAppShare ret=\(ret)")
        }
    }

    func onAppShareSplash() {
        guard let ms = MobileRTC.shared().getMeetingService(), let splashView = splashVC?.view else { return }
        ms.appShare(withView: splashView)
        if let image = UIImage(named: "icon_resume") {
            shareButton.setImage(image, for: .normal)
        }
        isSharingWebView = false
    }

    func onClickedShareButton(_ parentVC: UIViewController, addShareActionItem array: NSMutableArray) -> Bool {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isDirectAppShareMeeting() else { return false }
        ms.hideMobileRTCMeeting {
            if !ms.isStartingShare() && !ms.isViewingShare() {
                ms.startAppShare()
            }
        }
        return true
    }

    func onClickedInviteButton(_ parentVC: UIViewController, addInviteActionItem array: NSMutableArray?) -> Bool {
        guard let array else { return false }
        let item = MobileRTCMeetingInviteActionItem.item(
            withTitle: "test",
            action: {
                let alert = UIAlertController(title: "", message: NSLocalizedString("add invite item test", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                parentVC.present(alert, animated: true)
            }
        )
        array.add(item)
        return false
    }

    func onClickedParticipantsButton(_ parentVC: UIViewController) -> Bool {
        let inviteVC = InviteViewController()
        let nav = UINavigationController(rootViewController: inviteVC)
        nav.modalPresentationStyle = .formSheet
        parentVC.present(nav, animated: true)
        return true
    }

    func onClickedEndButton(_ parentVC: UIViewController, endButton: UIButton) -> Bool {
        guard let ms = MobileRTC.shared().getMeetingService() else { return true }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Leave Meeting", style: .default) { _ in
            if let leaveCmd = LeaveMeetingCmd(rawValue: 0) {
                ms.leaveMeeting(with: leaveCmd)
            }
        })
        if ms.isMeetingHost() {
            alert.addAction(UIAlertAction(title: "End Meeting", style: .default) { _ in
                if let endCmd = LeaveMeetingCmd(rawValue: 1) {
                    ms.leaveMeeting(with: endCmd)
                }
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = endButton
            popover.sourceRect = endButton.bounds
            popover.permittedArrowDirections = .any
        }
        presentFromTop(alert)
        return true
    }

    func onClickedDialOut(_ parentVC: UIViewController, isCallMe me: Bool) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isDialOutInProgress() {
            Logger.info("There already exists an ongoing call")
            return
        }
        let callName = me ? nil : "Dialer"
        let ret = ms.dialOut("+866004", isCallMe: me, withName: callName)
        Logger.info("Dial out result: \(ret)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = UIAlertController(title: "Dial out", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "cancel dial out", style: .default) { _ in
                ms.cancelDialOut(false)
            })
            alert.addAction(UIAlertAction(title: "is Dial out inprogress", style: .default) { _ in
                Logger.info("isDialOutInProgress: \(ms.isDialOutInProgress())")
            })
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel))
            self.presentFromTop(alert)
        }
    }

    func onJBHWaiting(withCmd cmd: JBHCmd) {
        switch cmd {
        case .show:
            let waitingVC = UIViewController()
            waitingVC.title = MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber
            waitingVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Leave", comment: ""),
                style: .plain,
                target: self,
                action: #selector(onLeaveJBH)
            )
            let nav = UINavigationController(rootViewController: waitingVC)
            nav.modalPresentationStyle = .fullScreen
            jbhWaitingNavController = nav
            present(nav, animated: true)
        case .hide:
            jbhWaitingNavController?.dismiss(animated: true)
            jbhWaitingNavController = nil
        @unknown default:
            jbhWaitingNavController?.dismiss(animated: true)
            jbhWaitingNavController = nil
        }
    }

    @objc private func onLeaveJBH() {
        if let leaveCmd = LeaveMeetingCmd(rawValue: 0) {
            MobileRTC.shared().getMeetingService()?.leaveMeeting(with: leaveCmd)
        }
    }

    func onJoinMeetingInfoRequired(_ handler: MobileRTCJoinMeetingInfoHandler) {
        switch handler.info {
        case .needName:
            promptSingleField(title: NSLocalizedString("Please input display name", comment: ""), placeholder: "Display Name", secure: false) { name, _ in
                _ = handler.inputDisplayName(name, password: nil)
            } cancel: {
                handler.cancel()
            }
        case .needPassword:
            promptSingleField(title: NSLocalizedString("Please input password", comment: ""), placeholder: "Password", secure: true) { _, pwd in
                _ = handler.inputDisplayName(nil, password: pwd)
            } cancel: {
                handler.cancel()
            }
        case .wrongPassword:
            promptSingleField(
                title: NSLocalizedString("Password Wrong! Please input password", comment: ""),
                placeholder: "Password",
                secure: true
            ) { _, pwd in
                _ = handler.inputDisplayName(nil, password: pwd)
            } cancel: {
                handler.cancel()
            }
        case .needNameAndPwd:
            let alert = UIAlertController(
                title: NSLocalizedString("Please input display name and password", comment: ""),
                message: nil,
                preferredStyle: .alert
            )
            alert.addTextField { $0.placeholder = "Display Name" }
            alert.addTextField { $0.placeholder = "Password"; $0.isSecureTextEntry = true }
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
                let name = alert.textFields?[0].text
                let pwd = alert.textFields?[1].text
                _ = handler.inputDisplayName(name, password: pwd)
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                handler.cancel()
            })
            presentFromTop(alert)
        case .confirmPreview:
            let previewVC = PreviewViewController(handler: handler, displayName: nil)
            previewVC.modalPresentationStyle = .fullScreen
            presentFromTop(previewVC)
        @unknown default:
            handler.cancel()
        }
    }

    private func promptSingleField(
        title: String,
        placeholder: String,
        secure: Bool,
        completion: @escaping (String?, String?) -> Void,
        cancel: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = placeholder
            tf.isSecureTextEntry = secure
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { _ in
            let text = alert.textFields?.first?.text
            completion(text, nil)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
            cancel()
        })
        presentFromTop(alert)
    }

    private func presentFromTop(_ vc: UIViewController) {
        guard let app = UIApplication.shared.delegate as? AppDelegate, let top = app.topViewController() else {
            present(vc, animated: true)
            return
        }
        top.present(vc, animated: true)
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        authPresenter?.zpnsDeviceList.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { ZPNSTableMetrics.rowHeight }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "zpnsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: id)
        guard let info = authPresenter?.zpnsDeviceList[indexPath.row] else { return cell }
        cell.textLabel?.text = "\(info.deviceName ?? "") \(info.meetingNumber)"
        cell.detailTextLabel?.text = "\(info.meetingNumber)"
        cell.contentView.subviews.filter { $0 is UIButton }.forEach { $0.removeFromSuperview() }

        let transfer = UIButton(type: .system)
        transfer.tag = indexPath.row
        transfer.frame = CGRect(
            x: tableView.bounds.width - ZPNSTableMetrics.actionButtonWidth,
            y: ZPNSTableMetrics.actionButtonMinY,
            width: ZPNSTableMetrics.actionButtonWidth,
            height: ZPNSTableMetrics.actionButtonHeight
        )
        transfer.setTitle("Transfer", for: .normal)
        transfer.titleLabel?.font = .boldSystemFont(ofSize: ZPNSTableMetrics.actionTitleFontSize)
        transfer.addTarget(self, action: #selector(onTransfer), for: .touchUpInside)
        cell.contentView.addSubview(transfer)

        if info.isSupportCompanionMode {
            let companion = UIButton(type: .system)
            companion.tag = ZPNSTableMetrics.companionTagBase + indexPath.row
            companion.frame = CGRect(
                x: tableView.bounds.width - ZPNSTableMetrics.companionLeadingOffset,
                y: ZPNSTableMetrics.actionButtonMinY,
                width: ZPNSTableMetrics.actionButtonWidth,
                height: ZPNSTableMetrics.actionButtonHeight
            )
            companion.setTitle("JoinCompanion", for: .normal)
            companion.titleLabel?.font = .boldSystemFont(ofSize: ZPNSTableMetrics.actionTitleFontSize)
            companion.addTarget(self, action: #selector(onJoinCompanion), for: .touchUpInside)
            cell.contentView.addSubview(companion)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

#if !targetEnvironment(simulator)
extension MainViewController: MobileRTCDirectShareServiceDelegate {
    func onDirectShareStatusUpdate(_ status: MobileRTCDirectShareStatus, handler: MobileRTCDirectShareViaMeetingIDOrPairingCodeHandler?) {
        Logger.info("onDirectShareStatusUpdate status=\(status.rawValue)")
        switch status {
        case .unknown:
            break
        case .connecting, .in_Direct_Share_Mode:
            break
        case .ended:
            _ = MobileRTC.shared().getDirectShareService()?.stopDirectShare()
        case .need_MeetingID_Or_PairingCode:
            promptPairing(handler: handler, message: "Please input the meeting number or pairingCode", placeholder: "meeting number or pairingCode")
        case .netWork_Error, .other_Error:
            break
        case .wrongMeetingID_Or_SharingKey:
            break
        case .need_Input_New_ParingCode:
            promptPairing(
                handler: handler,
                message: "This step is required for users on a different network for additional security measures",
                placeholder: "new pairingCode"
            )
        case .directShare_Prepared:
            break
        @unknown default:
            break
        }
    }

    private func promptPairing(handler: MobileRTCDirectShareViaMeetingIDOrPairingCodeHandler?, message: String, placeholder: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default) { _ in
            _ = MobileRTC.shared().getDirectShareService()?.stopDirectShare()
        })
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            _ = handler?.try(withPairingCode: text)
        })
        present(alert, animated: true)
    }
}
#endif
