//
//  SwiftCustomMeetingViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.

import MobileRTC
import UIKit
import os

/// Root container for the custom in-meeting UI when `enableCustomizeMeetingUI` is on.
/// Owns the top/bottom panels, participant gallery, and a swappable content area for
/// video / remote share / local share. Forwards `MobileRTCMeetingServiceDelegate`
/// callbacks (in the +MeetingDelegate extension) into the SDK.
final class SwiftCustomMeetingViewController: UIViewController {

    let baseView = UIView()
    var overlayView: UIView?

    let topPanelView = TopPanelView()
    let bottomPanelView = BottomPanelView()
    let thumbView = ThumbView()

    private(set) lazy var videoVC: VideoViewController = {
        let vc = VideoViewController()
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        vc.videoView.addGestureRecognizer(tap)
        return vc
    }()

    private(set) lazy var remoteShareVC: RemoteShareViewController = {
        let vc = RemoteShareViewController()
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        vc.shareView.addGestureRecognizer(tap)
        vc.onAnnotationStartedSuccessfully = { [weak self] in
            self?.showAnnotationView()
        }
        return vc
    }()

    private(set) lazy var localShareVC: LocalShareViewController = {
        let vc = LocalShareViewController()
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        tap.delegate = self
        vc.webView.addGestureRecognizer(tap)
        return vc
    }()

    private(set) lazy var annoFloatBarView: AnnoFloatBarView = {
        let bar = AnnoFloatBarView(frame: .zero)
        bar.isHidden = true
        bar.delegate = self
        return bar
    }()

    private var childContent: [UIViewController] = []
    var pinUserId: UInt = 0

    var isFullScreenMode: Bool = true
    var isShowTopBottomPanel: Bool = true
    var originalTransform: CGAffineTransform = .identity
    private var panGesture: UIPanGestureRecognizer?

    let actionPresenter = SDKActionPresenter()
    let sharePresenter = SDKSharePresenter()

    private let shrinkModeWidth: CGFloat = CustomMeetingLayout.isIPad ? 200 : 90
    private var shrinkModeHeight: CGFloat { shrinkModeWidth * 4 / 3 }

    // MARK: Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
        isFullScreenMode = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        isShowTopBottomPanel = true
        initSubviews()
        initPanGesture()
        disablePanGesture()

        if let ws = MobileRTC.shared().getWaitingRoomService() {
            ws.delegate = self
        }
        MobileRTC.shared().getAnnotationService()?.delegate = self

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleAppResignActive),
            name: UIApplication.willResignActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    private func initSubviews() {
        view.backgroundColor = .black
        baseView.frame = view.bounds
        baseView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(baseView)

        childContent = [videoVC, remoteShareVC, localShareVC]
        showVideoView()

        view.addSubview(thumbView)
        view.addSubview(topPanelView)
        view.addSubview(bottomPanelView)
        view.addSubview(annoFloatBarView)

        topPanelView.onShrinkTapped = { [weak self] in
            guard let self else { return }
            self.enablePanGesture()
            self.isFullScreenMode = false
            self.originalTransform = self.view.transform
            self.changeToPIPMode(self.view)
            self.initPanGesture()
        }
        thumbView.onPinUserTapped = { [weak self] userID in
            self?.pinUserId = userID
            self?.videoVC.showAttendeeVideo(userID: userID)
        }

        thumbView.isHidden = true
    }

    deinit {
        MobileRTC.shared().getAnnotationService()?.delegate = nil
        MobileRTC.shared().getWaitingRoomService()?.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        isShowTopBottomPanel = true
        thumbView.updateFrame()
        topPanelView.updateFrame()
        bottomPanelView.updateFrame()
        layoutShrinkViewFrame()
        layoutAnnoFloatBar()
    }

    private func layoutAnnoFloatBar() {
        let bottom = CustomMeetingLayout.bottomHeight
        let buttonHeight: CGFloat = 50
        let isLandscape = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.interfaceOrientation.isLandscape) ?? false
        let y: CGFloat
        if isLandscape {
            y = view.frame.height - bottom - 100
        } else {
            y = view.frame.height - bottom - view.frame.width / 4 - buttonHeight - 100
        }
        annoFloatBarView.frame = CGRect(x: 0, y: y, width: 320, height: 100)
    }

    // MARK: App state

    @objc private func handleAppResignActive() {
        if overlayView == nil {
            overlayView = UIView(frame: view.bounds)
            overlayView?.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        }
        if let overlay = overlayView {
            view.addSubview(overlay)
            view.bringSubviewToFront(overlay)
        }
    }

    @objc private func handleAppDidBecomeActive() {
        overlayView?.removeFromSuperview()
    }

    // MARK: Content switching

    @objc private func onViewTapped() {
        guard isFullScreenMode else {
            onShrinkTapped()
            return
        }
        if isShowTopBottomPanel {
            topPanelView.hideTopPanelView()
            bottomPanelView.hideBottomPanelView()
            thumbView.hideThumbView()
        } else {
            topPanelView.showTopPanelView()
            bottomPanelView.showBottomPanelView()
            thumbView.showThumbView()
        }
        isShowTopBottomPanel.toggle()
    }

    func updateVideoOrShare() {
        thumbView.updateThumbViewVideo()
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isWebinarAttendee() {
            if pinUserId != 0 {
                videoVC.showActiveVideo(userID: pinUserId)
            } else {
                videoVC.showActiveVideo(userID: ms.activeUserID())
            }
        } else {
            if pinUserId != 0 {
                videoVC.showAttendeeVideo(userID: pinUserId)
            } else {
                videoVC.showAttendeeVideo(userID: ms.myselfUserID())
            }
        }
    }

    func updateMyAudioStatus() { bottomPanelView.updateMyAudioStatus() }
    func updateMyVideoStatus() { bottomPanelView.updateMyVideoStatus() }
    func updateMyShareStatus() { bottomPanelView.updateMyShareStatus() }

    private func removeAllChildContent() {
        for vc in childContent {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
    }

    func showChildContent(_ child: UIViewController) {
        addChild(child)
        baseView.addSubview(child.view)
        child.didMove(toParent: self)
        child.view.frame = view.bounds
    }

    func showVideoView() {
        remoteShareVC.stopShareView()
        removeAllChildContent()
        showChildContent(videoVC)
    }

    func showRemoteShareView() {
        videoVC.stopActiveVideo()
        removeAllChildContent()
        showChildContent(remoteShareVC)
        showAnnotationView()
    }

    func showLocalShareView() {
        removeAllChildContent()
        showChildContent(localShareVC)
        sharePresenter.appShare(withView: localShareVC.view)
        showAnnotationView()
    }

    func showAnnotationView() {
        guard let ms = MobileRTC.shared().getMeetingService(),
              let asvc = MobileRTC.shared().getAnnotationService(),
              !ms.isAnnotationOff() else { return }
        let target: UIView = ms.isStartingShare() ? localShareVC.view : remoteShareVC.shareView
        if asvc.canDoAnnotation(target) {
            annoFloatBarView.isHidden = false
        }
    }

    func hideAnnotationView() {
        annoFloatBarView.isHidden = true
        annoFloatBarView.stopAnnotate()
    }

    // MARK: PIP / Shrink

    private func layoutShrinkViewFrame() {
        guard !isFullScreenMode,
              let gesture = panGesture,
              gesture.state == .possible else { return }
        view.frame = CGRect(
            x: CustomMeetingLayout.screenWidth - shrinkModeWidth - 10,
            y: 30,
            width: shrinkModeWidth,
            height: shrinkModeHeight
        )
    }

    private func initPanGesture() {
        guard panGesture == nil else { return }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onViewPan(_:)))
        panGesture = pan
        view.addGestureRecognizer(pan)
    }

    private func disablePanGesture() { panGesture?.isEnabled = false }
    private func enablePanGesture() { panGesture?.isEnabled = true }

    private func changeToPIPMode(_ view: UIView) {
        thumbView.isHidden = true
        bottomPanelView.isHidden = true
        topPanelView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            view.transform = view.transform.scaledBy(x: 0.2, y: 0.2)
            view.frame = CGRect(
                x: CustomMeetingLayout.screenWidth - self.shrinkModeWidth - 10,
                y: 30,
                width: self.shrinkModeWidth,
                height: self.shrinkModeHeight
            )
        }
    }

    private func changeToFullMode(_ view: UIView) {
        thumbView.isHidden = false
        bottomPanelView.isHidden = false
        topPanelView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            view.transform = self.originalTransform
            view.frame = CGRect(x: 0, y: 0, width: CustomMeetingLayout.screenWidth, height: CustomMeetingLayout.screenHeight)
        }, completion: { _ in
            view.setNeedsLayout()
        })
    }

    private func onShrinkTapped() {
        guard !isFullScreenMode else { return }
        isFullScreenMode = true
        changeToFullMode(view)
        disablePanGesture()
    }

    @objc private func onViewPan(_ recognizer: UIPanGestureRecognizer) {
        guard !isFullScreenMode else { return }
        onPanView(recognizer)
    }

    private func onPanView(_ pan: UIPanGestureRecognizer) {
        guard let parentView = parent?.view else { return }
        let center = pan.view?.center ?? .zero
        let translation = pan.translation(in: parentView)
        pan.view?.center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        pan.setTranslation(.zero, in: parentView)

        guard pan.state == .ended else { return }

        let velocity = pan.velocity(in: parentView)
        let magnitude = sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y))
        let slideMult = CGFloat(magnitude / 500)
        let slideFactor: CGFloat = 0.1 * slideMult
        var finalPoint = CGPoint(x: center.x + velocity.x * slideFactor, y: center.y + velocity.y * slideFactor)

        let halfW = shrinkModeWidth / 2
        let halfH = shrinkModeHeight / 2
        finalPoint.x = min(max(finalPoint.x, halfW), parentView.bounds.width - halfW)
        finalPoint.y = min(max(finalPoint.y, halfH), parentView.bounds.height - halfH)

        UIView.animate(withDuration: slideFactor * 2, delay: 0, options: .curveEaseOut, animations: {
            pan.view?.center = finalPoint
        })
    }
}

extension SwiftCustomMeetingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - MobileRTCWaitingRoomServiceDelegate

extension SwiftCustomMeetingViewController: MobileRTCWaitingRoomServiceDelegate {
    func onWaitingRoomUserJoin(_ userId: UInt) {
        guard let ws = MobileRTC.shared().getWaitingRoomService() else { return }
        _ = ws.admit(toMeeting: userId)
    }

    func onWaitingRoomUserLeft(_ userId: UInt) {
        Logger.info("Waiting room user left: \(userId)")
    }
}

// MARK: - MobileRTCAnnotationServiceDelegate

extension SwiftCustomMeetingViewController: MobileRTCAnnotationServiceDelegate {
    func onAnnotationToolChanged(_ tool: MobileRTCAnnoTool) {
        Logger.info("Annotation tool changed: \(tool.rawValue)")
    }

    func onAnnotationService(_ service: MobileRTCAnnotationService?,
                             supportStatusChanged support: Bool,
                             shareSouceID shareSourceID: UInt) {
        if support {
            showAnnotationView()
        } else {
            hideAnnotationView()
        }
    }
}

// MARK: - AnnoFloatBarViewDelegate

extension SwiftCustomMeetingViewController: AnnoFloatBarViewDelegate {
    func onClickStartAnnotate() -> Bool {
        guard let asvc = MobileRTC.shared().getAnnotationService() else { return false }
        let target: UIView? = remoteShareVC.parent != nil ? remoteShareVC.shareView : localShareVC.view
        return asvc.startAnnotation(withSharedView: target) == .successed
    }

    func onClickStopAnnotate() -> Bool {
        guard let asvc = MobileRTC.shared().getAnnotationService() else { return false }
        return asvc.stopAnnotation()
    }
}
