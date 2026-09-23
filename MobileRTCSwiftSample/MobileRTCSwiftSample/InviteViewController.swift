//
//  InviteViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

final class InviteViewController: UIViewController {
    private let meetingURLLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Cancel", comment: ""),
            style: .plain,
            target: self,
            action: #selector(onCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Pause/Resume", comment: ""),
            style: .plain,
            target: self,
            action: #selector(onPauseResume)
        )
        title = MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber

        meetingURLLabel.numberOfLines = 0
        meetingURLLabel.textAlignment = .center
        meetingURLLabel.text = MobileRTCInviteHelper.sharedInstance().joinMeetingURL
        meetingURLLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(meetingURLLabel)
        NSLayoutConstraint.activate([
            meetingURLLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            meetingURLLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            meetingURLLabel.topAnchor.constraint(equalTo: view.topAnchor),
            meetingURLLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc private func onCancel() {
        dismiss(animated: true)
    }

    @objc private func onPauseResume() {
        guard let meetingService = MobileRTC.shared().getMeetingService() else { return }
        let isNoAudio = (meetingService.myAudioType() == .none)
        meetingService.connectMyAudio(isNoAudio)
    }
}
