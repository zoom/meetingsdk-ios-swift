//
//  ThumbView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

/// Participant gallery strip (horizontal in portrait, vertical in landscape).
/// Tap a thumb to pin it; long-press for the participant action sheet.
final class ThumbView: UIView {

    private static let cameraControlRange: Int = 50

    private(set) var pinUserID: UInt = 0
    private var thumbHidden: Bool = false
    private let videoPresenter = SDKVideoPresenter()

    var onPinUserTapped: ((UInt) -> Void)?

    private lazy var thumbTableView: HorizontalTableView = {
        let tv = HorizontalTableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorColor = .clear
        tv.isPagingEnabled = false
        tv.delegate = self
        tv.dataSource = self
        tv.showsVerticalScrollIndicator = false
        tv.register(ThumbTableViewCell.self, forCellReuseIdentifier: ThumbTableViewCell.reuseIdentifier)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 1.0
        longPress.delegate = self
        tv.addGestureRecognizer(longPress)
        return tv
    }()

    private lazy var thumbHideButton: UIButton = {
        let b = UIButton(type: .system)
        b.addTarget(self, action: #selector(onToggleHidden), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(thumbHideButton)
        addSubview(thumbTableView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Show / Hide / Frames

    func showThumbView() {
        guard !CustomMeetingLayout.isLandscape else { return }
        UIView.animate(withDuration: 0.25) {
            let cellSize = CustomMeetingLayout.thumbCellSize
            self.frame = CGRect(
                x: 0,
                y: CustomMeetingLayout.screenHeight - CustomMeetingLayout.bottomHeight - cellSize - CustomMeetingLayout.thumbButtonHeight,
                width: CustomMeetingLayout.screenWidth,
                height: cellSize + CustomMeetingLayout.thumbButtonHeight
            )
        }
    }

    func hideThumbView() {
        guard !CustomMeetingLayout.isLandscape else { return }
        UIView.animate(withDuration: 0.25) {
            let cellSize = CustomMeetingLayout.thumbCellSize
            let offset: CGFloat = CustomMeetingLayout.hasHomeIndicator ? CustomMeetingLayout.safeZoomInsets : 0
            self.frame = CGRect(
                x: 0,
                y: CustomMeetingLayout.screenHeight - cellSize - offset - CustomMeetingLayout.thumbButtonHeight,
                width: CustomMeetingLayout.screenWidth,
                height: cellSize + CustomMeetingLayout.thumbButtonHeight
            )
        }
    }

    func updateFrame() {
        let bounds = UIScreen.main.bounds
        let cellSize = CustomMeetingLayout.thumbCellSize
        let buttonH = CustomMeetingLayout.thumbButtonHeight

        if CustomMeetingLayout.isLandscape {
            let offset: CGFloat = CustomMeetingLayout.hasHomeIndicator ? CustomMeetingLayout.safeZoomInsets : 0
            frame = CGRect(x: bounds.width - cellSize - offset - buttonH, y: 0, width: cellSize + buttonH, height: bounds.height)
        } else {
            frame = CGRect(x: 0, y: bounds.height - CustomMeetingLayout.bottomHeight - cellSize - buttonH, width: bounds.width, height: cellSize + buttonH)
        }

        thumbHidden = false
        thumbTableView.isHidden = false

        if CustomMeetingLayout.isLandscape {
            thumbTableView.transform = .identity
            thumbTableView.frame = CGRect(x: buttonH, y: 0, width: cellSize, height: bounds.height)
            thumbHideButton.frame = CGRect(x: 0, y: 0, width: buttonH, height: self.frame.height)
            thumbHideButton.setImage(UIImage(named: "arrow_right_normal"), for: .normal)
        } else {
            thumbTableView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            thumbTableView.frame = CGRect(x: 0, y: buttonH, width: bounds.width, height: cellSize)
            thumbHideButton.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: buttonH)
            thumbHideButton.setImage(UIImage(named: "arrow_down_normal"), for: .normal)
        }

        thumbTableView.rowHeight = cellSize
        DispatchQueue.main.async { [weak self] in self?.thumbTableView.reloadData() }
    }

    func updateThumbViewVideo() {
        thumbTableView.reloadData()
    }

    func setPinUserID(_ userID: UInt) {
        pinUserID = userID
    }

    @objc private func onToggleHidden() {
        thumbHidden.toggle()
        thumbTableView.isHidden = thumbHidden

        let cellSize = CustomMeetingLayout.thumbCellSize
        let buttonH = CustomMeetingLayout.thumbButtonHeight

        if CustomMeetingLayout.isLandscape {
            thumbHideButton.frame = thumbHidden
                ? CGRect(x: cellSize, y: 0, width: buttonH, height: frame.height)
                : CGRect(x: 0, y: 0, width: buttonH, height: frame.height)
            thumbHideButton.setImage(UIImage(named: thumbHidden ? "arrow_left_normal" : "arrow_right_normal"), for: .normal)
        } else {
            thumbHideButton.frame = thumbHidden
                ? CGRect(x: 0, y: cellSize, width: frame.width, height: buttonH)
                : CGRect(x: 0, y: 0, width: frame.width, height: buttonH)
            thumbHideButton.setImage(UIImage(named: thumbHidden ? "arrow_up_normal" : "arrow_down_normal"), for: .normal)
        }
    }

    private func userIDs() -> [NSNumber] {
        MobileRTC.shared().getMeetingService()?.getInMeetingUserList() ?? []
    }

    private func showAttendeeVideo(_ thumb: MobileRTCVideoView, userID: UInt) {
        thumb.showAttendeeVideo(withUserID: userID)
        thumb.setVideoAspect(MobileRTCVideoAspect_PanAndScan)
    }

    private func stopThumbViewVideo() {
        for cell in thumbTableView.visibleCells {
            (cell as? ThumbTableViewCell)?.stopThumbVideo()
        }
    }

    private func scrollToRowPosition() {
        let rowHeight = thumbTableView.rowHeight
        let offsetY = Int(thumbTableView.contentOffset.y) % Int(rowHeight)
        let visibleCell = offsetY >= Int(rowHeight / 2)
        guard let initial = thumbTableView.indexPathForRow(at: CGPoint(x: thumbTableView.contentOffset.x, y: thumbTableView.contentOffset.y)) else { return }
        let target = visibleCell ? IndexPath(row: initial.row + 1, section: 0) : initial
        if target.row < userIDs().count {
            thumbTableView.scrollToRow(at: target, at: .top, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ThumbView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        userIDs().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThumbTableViewCell.reuseIdentifier, for: indexPath) as! ThumbTableViewCell
        cell.selectionStyle = .none
        cell.transform = CustomMeetingLayout.isLandscape ? .identity : CGAffineTransform(rotationAngle: .pi / 2)

        let ids = userIDs()
        guard !ids.isEmpty, indexPath.row < ids.count else { return cell }
        guard UIApplication.shared.applicationState == .active else { return cell }

        if tableView.isDecelerating {
            cell.stopThumbVideo()
            return cell
        }

        let userID = ids[indexPath.row].uintValue
        showAttendeeVideo(cell.thumbView, userID: userID)
        cell.backgroundColor = (userID == pinUserID) ? .green : UIColor(white: 0.5, alpha: 0.5)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ids = userIDs()
        guard !ids.isEmpty, indexPath.row < ids.count else { return }
        let userID = ids[indexPath.row].uintValue
        pinUserID = userID

        for visiblePath in tableView.indexPathsForVisibleRows ?? [] {
            tableView.cellForRow(at: visiblePath)?.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        }
        tableView.cellForRow(at: indexPath)?.backgroundColor = .green
        onPinUserTapped?(userID)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopThumbViewVideo()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateThumbViewVideo()
        scrollToRowPosition()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateThumbViewVideo()
            scrollToRowPosition()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ThumbView: UIGestureRecognizerDelegate {}

// MARK: - Long-press action sheet (participant actions)

extension ThumbView {

    @objc fileprivate func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let p = gesture.location(in: thumbTableView)
        guard let indexPath = thumbTableView.indexPathForRow(at: p) else { return }
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let ids = userIDs()
        guard indexPath.row < ids.count else { return }
        let userID = ids[indexPath.row].uintValue
        guard let userInfo = ms.userInfo(byID: userID) else { return }

        let roleString: String
        switch userInfo.userRole {
        case .none: roleString = "Role:None"
        case .host: roleString = "Role:Host"
        case .coHost: roleString = "Role:CoHost"
        case .attendee: roleString = "Role:Attendee"
        case .panelist: roleString = "Role:Webinar_Panelist"
        case .breakoutRoom_Moderator: roleString = "Role:BOMeeting_Moderator"
        @unknown default: roleString = "Role:None"
        }

        let alert = UIAlertController(title: roleString, message: nil, preferredStyle: .actionSheet)
        addUserActions(to: alert, userID: userID, userInfo: userInfo, ms: ms, indexPath: indexPath)

        if let popover = alert.popoverPresentationController,
           let cell = thumbTableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }

    private func addUserActions(
        to alert: UIAlertController,
        userID: UInt,
        userInfo: MobileRTCMeetingUserInfo,
        ms: MobileRTCMeetingService,
        indexPath: IndexPath
    ) {
        alert.addAction(UIAlertAction(title: "Show video Size", style: .default) { _ in
            let size = ms.getUserVideoSize(userID)
            let info = UIAlertController(title: "", message: "video size:w=\(size.width),h=\(size.height)", preferredStyle: .alert)
            info.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            (UIApplication.shared.delegate as? AppDelegate)?.topViewController()?.present(info, animated: true)
        })

        if ms.isMeetingHost() || ms.isMeetingCoHost() {
            if userInfo.audioStatus?.audioType != MobileRTCAudioType.none {
                let title = ms.isUserAudioMuted(userID) ? "Ask Unmute audio" : "Mute Audio"
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                    ms.muteUserAudio(!ms.isUserAudioMuted(userID), withUID: userID)
                })
            }
            let videoTitle = ms.isUserVideoSending(userID) ? "Stop video" : "Ask start video"
            alert.addAction(UIAlertAction(title: videoTitle, style: .default) { _ in
                if ms.isUserVideoSending(userID) { ms.stopUserVideo(userID) }
                else { ms.askUserStartVideo(userID) }
            })
            alert.addAction(UIAlertAction(title: "Change name to Test", style: .default) { _ in
                ms.changeName("Test:\(indexPath.row)", withUserID: userID)
            })
            if userInfo.handRaised {
                alert.addAction(UIAlertAction(title: "Lower the user hand", style: .default) { _ in
                    ms.lowerHand(userID)
                })
            }
            if !userInfo.isCohost {
                alert.addAction(UIAlertAction(title: "Remove the user", style: .default) { _ in
                    ms.removeUser(userID)
                })
            }
            if let ws = MobileRTC.shared().getWaitingRoomService(),
               ws.isSupportWaitingRoom(),
               ws.isWaitingRoomOnEntryFlagOn() {
                alert.addAction(UIAlertAction(title: "Put in waiting room", style: .default) { _ in
                    ws.put(inWaitingRoom: userID)
                })
            }
        }

        if !userInfo.isHost, ms.isMeetingHost() {
            alert.addAction(UIAlertAction(title: "Make host", style: .default) { _ in ms.makeHost(userID) })
        }
        if !userInfo.isHost, !userInfo.isCohost, ms.isMeetingHost(), ms.canBeCoHost(userID) {
            alert.addAction(UIAlertAction(title: "Make co-host", style: .default) { _ in ms.assignCohost(userID) })
        }
        if userInfo.isCohost, ms.isMeetingHost() {
            alert.addAction(UIAlertAction(title: "Revoke co-host", style: .default) { _ in ms.revokeCoHost(userID) })
        }

        if ms.isWebinarMeeting(),
           ms.isMeetingHost() || ms.isMeetingCoHost(),
           userInfo.userRole == .panelist {
            alert.addAction(UIAlertAction(title: "DePrompt the panelist to attendee", style: .default) { _ in
                ms.dePromptPanelist2Attendee(userID)
            })
        }

        if !ms.isPrivateChatDisabled() {
            alert.addAction(UIAlertAction(title: "Send a private chat message", style: .default) { _ in
                let msg = MobileRTCMeetingChat()
                msg.receiverId = "\(userID)"
                msg.content = "This is a private chat message"
                _ = ms.sendChatMsg(msg)
            })
        }

        if ms.isMeetingSupportCC(),
           ms.isLiveTranscriptionFeatureEnabled(),
           ms.canAssignOthersToSendCC(),
           ms.canBeAssigned(toSendCC: userID) {
            alert.addAction(UIAlertAction(title: "assign CC privilege", style: .default) { _ in
                _ = ms.assignCCPrivilege(userID)
            })
            alert.addAction(UIAlertAction(title: "withdraw CC privilege", style: .default) { _ in
                _ = ms.withdrawCCPrivilege(userID)
            })
        }

        addCameraControlActions(to: alert, userID: userID)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
    }

    private func addCameraControlActions(to alert: UIAlertController, userID: UInt) {
        guard let cameraControl = MobileRTC.shared().getCameraControlService(Int(userID)) else { return }
        cameraControl.delegate = self
        let canControl = cameraControl.canControlCamera()

        alert.addAction(UIAlertAction(title: "camera control: canControlCamera=\(canControl)", style: .default) { _ in
            _ = cameraControl.requestControlRemoteCamera()
        })

        guard canControl else { return }
        let range = Self.cameraControlRange

        alert.addAction(UIAlertAction(title: "camera control:requestControlRemoteCamera", style: .default) { _ in
            _ = cameraControl.requestControlRemoteCamera()
        })
        alert.addAction(UIAlertAction(title: "camera control:giveUpControlRemoteCamera", style: .default) { _ in
            _ = cameraControl.giveUpControlRemoteCamera()
        })
        alert.addAction(UIAlertAction(title: "camera control:turnLeft", style: .default) { _ in
            _ = cameraControl.turnLeft(range)
        })
        alert.addAction(UIAlertAction(title: "camera control:turnRight", style: .default) { _ in
            _ = cameraControl.turnRight(range)
        })
        alert.addAction(UIAlertAction(title: "camera control:turnUp", style: .default) { _ in
            _ = cameraControl.turnUp(range)
        })
        alert.addAction(UIAlertAction(title: "camera control:turnDown", style: .default) { _ in
            _ = cameraControl.turnDown(range)
        })
        alert.addAction(UIAlertAction(title: "camera control:zoomIn", style: .default) { _ in
            _ = cameraControl.zoom(in: range)
        })
        alert.addAction(UIAlertAction(title: "camera control:zoomOut", style: .default) { _ in
            _ = cameraControl.zoomOut(range)
        })
    }
}

// MARK: - MobileRTCCameraControlDelegate

extension ThumbView: MobileRTCCameraControlDelegate {
    func onCameraControlRequestResult(_ userId: UInt, isApproved: MobileRTCCameraControlRequestResult) {
        Logger.info("cameraControl:onCameraControlRequestResult userId=\(userId) isApproved=\(isApproved.rawValue)")
    }
}
