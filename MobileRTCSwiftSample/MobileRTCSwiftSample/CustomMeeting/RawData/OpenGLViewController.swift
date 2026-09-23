//
//  OpenGLViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

final class OpenGLViewController: UIViewController {

    private var topBar: TopBar?
    private var controlBar: ControlBar?
    private var bottomView: BottomBarView?
    private var fullRender: MobileRTCRenderer?
    private var fullView: OpenglView?
    private var renderArray: [MobileRTCRenderer] = []
    private var localShareVC: LocalShareViewController?
    private var switchShareButton = UIButton(type: .custom)
    private var audioRawdataHelper: MobileRTCAudioRawDataHelper?
    private let audioSandboxHelper = AudioRawDataSaveSandboxHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0x23/255.0, green: 0x23/255.0, blue: 0x23/255.0, alpha: 1)
        UIApplication.shared.isIdleTimerDisabled = true

        let renderer = MobileRTCRenderer(delegate: self)
        fullRender = renderer
        let openglView = OpenglView(frame: view.bounds)
        fullView = openglView
        view.addSubview(openglView)
        renderer.subscribe(0, videoType: .videoData)
        renderArray.append(renderer)

        let bar = TopBar()
        topBar = bar
        bar.endOnClickBlock = { [weak self] in
            self?.leave()
        }
        view.addSubview(bar)

        configureSwitchShareButton()
        view.addSubview(switchShareButton)

        let bottom = BottomBarView(delegate: self)
        bottomView = bottom
        bottom.frame = CGRect(x: 0, y: CustomMeetingLayout.screenHeight - BottomBarView.tableHeight, width: CustomMeetingLayout.screenWidth, height: BottomBarView.tableHeight)
        view.addSubview(bottom)

        audioRawdataHelper = MobileRTCAudioRawDataHelper(delegate: self)
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        audioSandboxHelper.filePath = "\(docPath)/audio/\(timestamp).pcm"
    }

    deinit {
        audioRawdataHelper?.unSubscribe()
    }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fullView?.frame = view.bounds
        topBar?.setNeedsLayout()
        controlBar?.setNeedsLayout()
        bottomView?.setNeedsLayout()
        let isLandscape = CustomMeetingLayout.isLandscape
        let topInset: CGFloat = CustomMeetingLayout.hasHomeIndicator ? CustomMeetingLayout.safeZoomInsets : 0
        let orientation = view.window?.windowScene?.interfaceOrientation
        let xInset: CGFloat = (isLandscape && orientation == .landscapeRight && CustomMeetingLayout.hasHomeIndicator)
            ? CustomMeetingLayout.safeZoomInsets + 10
            : 8
        switchShareButton.frame = CGRect(x: xInset, y: TopBar.topHeight + (isLandscape ? 0 : topInset) + 5, width: 180, height: 35)
    }

    private func configureSwitchShareButton() {
        switchShareButton.setTitle("Switch to Share", for: .normal)
        switchShareButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        switchShareButton.setTitleColor(.white, for: .normal)
        switchShareButton.backgroundColor = UIColor(white: 0, alpha: 0.6)
        switchShareButton.clipsToBounds = true
        switchShareButton.layer.cornerRadius = 6
        switchShareButton.addTarget(self, action: #selector(switchToShareTapped(_:)), for: .touchUpInside)
        switchShareButton.isHidden = true
    }

    private func ensureControlBar() -> ControlBar {
        if let controlBar { return controlBar }
        let bar = ControlBar()
        controlBar = bar
        bar.onShareTap = { [weak self] tag in
            guard let self, tag == .share, let ms = MobileRTC.shared().getMeetingService() else { return }
            if ms.isStartingShare() {
                ms.stopAppShare()
                self.localShareVC?.removeFromParent()
                self.localShareVC?.view.removeFromSuperview()
                if self.fullRender?.videoType == .shareData {
                    self.noVideoFailback()
                }
            } else {
                let local = self.localShareVC ?? LocalShareViewController()
                self.localShareVC = local
                local.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addChild(local)
                self.view.addSubview(local.view)
                local.didMove(toParent: self)
                if let topBar = self.topBar {
                    self.view.insertSubview(local.view, belowSubview: topBar)
                }
                if let v = local.viewIfLoaded { ms.appShare(withView: v) }
            }
        }
        return bar
    }

    private func noVideoFailback() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        fullRender?.subscribe(ms.myselfUserID(), videoType: .videoData)
    }

    private func leave() {
        dismiss(animated: true)
        fullRender?.unSubscribe()
        fullRender = nil
        for render in renderArray { render.unSubscribe() }
        renderArray.removeAll()
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let cmd: LeaveMeetingCmd = ms.isMeetingHost() ? .end : .leave
        ms.leaveMeeting(with: cmd)
    }

    private func updateVideo(in openGLView: OpenglView?, userId: UInt) {
        guard let openGLView, let ms = MobileRTC.shared().getMeetingService() else { return }
        if !ms.isUserVideoSending(userId) {
            openGLView.clearFrame()
        }
    }

    private func bottomRenderView(for userId: UInt) -> OpenglView? {
        bottomView?.getThumberViewItems(userId: userId).first?.view as? OpenglView
    }

    private func addThumberViews() {
        guard let bottomView, let ms = MobileRTC.shared().getMeetingService() else { return }
        var existing: Set<UInt> = []
        for item in bottomView.viewArray { existing.insert(item.userId) }
        for num in ms.getInMeetingUserList() ?? [] {
            let userID = num.uintValue
            guard !existing.contains(userID) else { continue }
            let userInfo = ms.userInfo(byID: userID)
            let renderer = MobileRTCRenderer(delegate: self)
            renderer.subscribe(userID, videoType: .videoData)
            renderArray.append(renderer)
            let view = OpenglView(frame: .zero)
            let item = ViewItem()
            item.userId = userID
            item.view = view
            item.itemName = userInfo?.userName ?? ""
            item.renderer = renderer
            bottomView.addThumberViewItem(item)
        }
        let bar = ensureControlBar()
        view.insertSubview(bar, aboveSubview: bottomView)
    }

    @objc private func switchToShareTapped(_ sender: UIButton) {
        sender.isHidden = true
        let shareUserId = UInt(sender.tag)
        guard shareUserId != 0, let fullRender else { return }
        fullRender.setRawDataResolution(._720)
        fullRender.subscribe(shareUserId, videoType: .shareData)
        updateVideo(in: fullView, userId: shareUserId)
        for item in bottomView?.viewArray ?? [] where item.userId == shareUserId {
            viewItemSelected(item)
        }
    }

    private func viewItemSelected(_ item: ViewItem) {
        for it in bottomView?.viewArray ?? [] {
            it.view.layer.borderColor = UIColor(white: 1, alpha: 0.5).cgColor
        }
        item.view.layer.borderColor = UIColor.green.cgColor
    }
}

extension OpenGLViewController: MobileRTCMeetingServiceDelegate {
    func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        guard state == .inMeeting else { return }
        addThumberViews()
        MobileRTC.shared().getMeetingService()?.connectMyAudio(true)
        view.addSubview(ensureControlBar())
        audioRawdataHelper?.subscribe()
    }

    func onSinkMeetingUserJoin(_ userID: UInt) {
        addThumberViews()
    }

    func onSinkMeetingUserLeft(_ userID: UInt) {
        if fullRender?.userId == userID {
            noVideoFailback()
        }
        for render in renderArray where render.userId == userID {
            render.unSubscribe()
        }
        bottomView?.removeThumberViewItem(userId: userID)
    }

    func onSinkMeetingVideoStatusChange(_ userID: UInt) {
        if userID == fullRender?.userId {
            updateVideo(in: fullView, userId: userID)
        }
        updateVideo(in: bottomRenderView(for: userID), userId: userID)
    }

    func onMyVideoStateChange() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let myUserID = ms.myselfUserID()
        if myUserID == fullRender?.userId {
            updateVideo(in: fullView, userId: myUserID)
        }
        updateVideo(in: bottomRenderView(for: myUserID), userId: myUserID)
        controlBar?.updateMyVideoStatus()
    }

    func onMyAudioStateChange() {
        controlBar?.updateMyAudioStatus()
    }

    func onSinkSharingStatus(_ shareInfo: MobileRTCSSharingSourceInfo) {
        let userID = shareInfo.getUserID()
        switch shareInfo.getStatus() {
        case .self_Send_Begin:
            guard let ms = MobileRTC.shared().getMeetingService(), let bottomView else { return }
            let myUserID = ms.myselfUserID()
            let userInfo = ms.userInfo(byID: myUserID)
            let renderer = MobileRTCRenderer(delegate: self)
            renderer.subscribe(myUserID, videoType: .shareData)
            renderArray.append(renderer)
            let view = OpenglView(frame: .zero)
            let item = ViewItem()
            item.userId = myUserID
            item.view = view
            item.itemName = userInfo?.userName ?? ""
            item.renderer = renderer
            bottomView.addThumberViewItem(item)
        case .self_Send_End:
            guard let ms = MobileRTC.shared().getMeetingService(), let bottomView else { return }
            let myUserID = ms.myselfUserID()
            for item in bottomView.viewArray
            where item.userId == myUserID && item.renderer?.videoType == .shareData {
                item.renderer?.unSubscribe()
                bottomView.removeThumberViewItem(item)
            }
        case .other_Share_Begin:
            guard let ms = MobileRTC.shared().getMeetingService(), let bottomView else { return }
            let myID = ms.myselfUserID()
            guard userID != myID else { return }
            switchShareButton.tag = Int(userID)
            if let item = bottomView.getThumberViewItems(userId: userID).first {
                viewItemSelected(item)
            }
            fullRender?.subscribe(userID, videoType: .shareData)
            switchShareButton.isHidden = true
        case .other_Share_End:
            guard let ms = MobileRTC.shared().getMeetingService() else { return }
            let myID = ms.myselfUserID()
            switchShareButton.tag = 0
            fullRender?.subscribe(myID, videoType: .videoData)
            switchShareButton.isHidden = true
        default:
            break
        }
    }

}

extension OpenGLViewController: MobileRTCVideoRawDataDelegate {
    func onMobileRTCRender(_ renderer: MobileRTCRenderer, frameRawData rawData: MobileRTCVideoRawData) {
        rawData.addRef()
        DispatchQueue.main.async { [weak self] in
            defer { rawData.releaseRef() }
            guard let self else { return }
            if renderer === self.fullRender {
                self.fullView?.displayYUV(rawData, mode: .letterBox, mirror: true)
            }
            for item in self.bottomView?.getThumberViewItems(userId: renderer.userId) ?? [] where item.renderer === renderer {
                if let glView = item.view as? OpenglView {
                    glView.displayYUV(rawData, mode: .panAndScan, mirror: true)
                }
            }
        }
    }
}

extension OpenGLViewController: MobileRTCAudioRawDataDelegate {
    func onMobileRTCMixedAudioRawData(_ rawData: MobileRTCAudioRawData) {}
    func onMobileRTCOneWayAudioAudioRawData(_ rawData: MobileRTCAudioRawData, userId: UInt) {}
    func onShareAudioRawDataReceived(_ rawData: MobileRTCAudioRawData, userId: UInt) {}
}

extension OpenGLViewController: BottomBarViewDelegate {
    func pinThumberViewItem(_ item: ViewItem) {
        guard let renderer = item.renderer else { return }
        if let local = localShareVC?.view, view.subviews.contains(local) {
            local.removeFromSuperview()
        }
        if renderer.videoType == .videoData {
            fullRender?.subscribe(item.userId, videoType: .videoData)
        } else {
            fullRender?.subscribe(item.userId, videoType: .shareData)
        }
        fullRender?.setRawDataResolution(._180)
        viewItemSelected(item)
        onSinkMeetingVideoStatusChange(item.userId)
        if switchShareButton.tag != 0 { switchShareButton.isHidden = false }
    }

    func stopThumbViewVideo() {
        for item in bottomView?.viewArray ?? [] {
            item.renderer?.unSubscribe()
        }
    }

    func startThumbViewVideo() {
        guard let bottomView else { return }
        for cell in bottomView.thumbTableView.visibleCells {
            guard let indexPath = bottomView.thumbTableView.indexPath(for: cell) else { continue }
            let item = bottomView.viewArray[indexPath.row]
            item.renderer?.subscribe(item.userId, videoType: .videoData)
        }
    }
}
