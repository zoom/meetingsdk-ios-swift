//
//  SplashViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

final class SplashViewController: UIViewController {

    private let logoImageView: UIImageView = {
        let v = UIImageView(frame: .zero)
        v.image = UIImage(named: "icon_meet")
        v.contentMode = .center
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(logoImageView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        view.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        logoImageView.frame = view.bounds
    }

    @objc private func onTap() {
        MobileRTC.shared().getMeetingService()?.showMeetingControlBar()
    }
}
