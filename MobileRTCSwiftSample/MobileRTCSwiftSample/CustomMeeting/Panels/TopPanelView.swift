//
//  TopPanelView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

/// Top panel with shrink (PiP), camera switch, meeting title, and leave button.
final class TopPanelView: UIView {

    private static let buttonLength: CGFloat = 40

    private let gradientLayer = CAGradientLayer()
    let shrinkButton = UIButton(type: .system)
    private let cameraSwitchButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let leaveButton = UIButton(type: .system)

    private let actionPresenter = SDKActionPresenter()
    private let videoPresenter = SDKVideoPresenter()

    var onShrinkTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configure() {
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.colors = [
            UIColor(white: 0, alpha: 0.6).cgColor,
            UIColor(white: 0, alpha: 0.0).cgColor
        ]
        layer.addSublayer(gradientLayer)

        shrinkButton.setImage(UIImage(named: "icon_shrink"), for: .normal)
        shrinkButton.addTarget(self, action: #selector(onShrinkPressed), for: .touchUpInside)

        cameraSwitchButton.setImage(UIImage(named: "icon_switchcam"), for: .normal)
        cameraSwitchButton.addTarget(self, action: #selector(onCameraSwitchPressed), for: .touchUpInside)

        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "Helvetica-Bold", size: 16)
        titleLabel.text = MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber

        leaveButton.setTitle("Leave", for: .normal)
        leaveButton.titleLabel?.font = .systemFont(ofSize: 16)
        leaveButton.setTitleColor(.red, for: .normal)
        leaveButton.addTarget(self, action: #selector(onLeavePressed(_:)), for: .touchUpInside)

        addSubview(shrinkButton)
        addSubview(cameraSwitchButton)
        addSubview(titleLabel)
        addSubview(leaveButton)
    }

    func showTopPanelView() {
        UIView.animate(withDuration: 0.25) {
            self.frame = CGRect(x: 0, y: 0, width: CustomMeetingLayout.screenWidth, height: CustomMeetingLayout.topHeight)
        }
    }

    func hideTopPanelView() {
        UIView.animate(withDuration: 0.25) {
            self.frame = CGRect(x: 0, y: -CustomMeetingLayout.topHeight, width: CustomMeetingLayout.screenWidth, height: CustomMeetingLayout.topHeight)
        }
    }

    func updateFrame() {
        let width = CustomMeetingLayout.screenWidth
        frame = CGRect(x: 0, y: 0, width: width, height: CustomMeetingLayout.topHeight)
        gradientLayer.frame = bounds

        let topGap = CustomMeetingLayout.safeAreaTop + 5
        let len = Self.buttonLength
        shrinkButton.frame = CGRect(x: 10, y: topGap, width: len, height: len)
        cameraSwitchButton.frame = CGRect(x: shrinkButton.frame.maxX + 10, y: topGap, width: len, height: len)
        leaveButton.frame = CGRect(x: width - 70, y: topGap, width: 60, height: len)
        titleLabel.frame = CGRect(x: (width - 120) / 2, y: topGap, width: 120, height: len)
    }

    @objc private func onShrinkPressed() {
        onShrinkTapped?()
    }

    @objc private func onCameraSwitchPressed() {
        videoPresenter.switchMyCamera()
    }

    @objc private func onLeavePressed(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Leave Meeting", style: .default) { [weak self] _ in
            self?.actionPresenter.leaveMeeting()
        })
        if actionPresenter.isMeetingHost() {
            alert.addAction(UIAlertAction(title: "End Meeting", style: .default) { [weak self] _ in
                self?.actionPresenter.endMeeting()
            })
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }
}
