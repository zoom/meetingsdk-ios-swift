//
//  TopBar.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

final class TopBar: UIView {

    static let topHeight: CGFloat = 70

    var endOnClickBlock: (() -> Void)?

    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let leaveButton = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.colors = [
            UIColor(white: 0, alpha: 0.6).cgColor,
            UIColor(white: 0, alpha: 0).cgColor
        ]
        layer.addSublayer(gradientLayer)

        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = UIFont(name: "Helvetica-Bold", size: 16)
        titleLabel.text = MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber
        addSubview(titleLabel)

        leaveButton.setTitle("LEAVE", for: .normal)
        leaveButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        leaveButton.setTitleColor(UIColor(red: 224/255, green: 40/255, blue: 40/255, alpha: 1), for: .normal)
        leaveButton.backgroundColor = UIColor(white: 0, alpha: 0.6)
        leaveButton.layer.cornerRadius = 16
        leaveButton.addTarget(self, action: #selector(onLeaveTapped(_:)), for: .touchUpInside)
        addSubview(leaveButton)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateFrame()
    }

    func updateFrame() {
        let screen = UIScreen.main.bounds
        let isLandscape = CustomMeetingLayout.isLandscape
        let topInset: CGFloat = CustomMeetingLayout.hasHomeIndicator ? CustomMeetingLayout.safeZoomInsets : 0
        let height = Self.topHeight + (isLandscape ? 0 : topInset)
        frame = CGRect(x: 0, y: 0, width: screen.size.width, height: height)
        leaveButton.frame = CGRect(x: screen.size.width - 16 - 90, y: 20 + (isLandscape ? 0 : topInset), width: 90, height: 32)
        titleLabel.frame = CGRect(x: (frame.size.width - 120) / 2, y: 20 + (isLandscape ? 0 : topInset), width: 120, height: 40)
        gradientLayer.frame = bounds
    }

    @objc private func onLeaveTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Leave Meeting", style: .default) { [weak self] _ in
            self?.endOnClickBlock?()
        })
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
