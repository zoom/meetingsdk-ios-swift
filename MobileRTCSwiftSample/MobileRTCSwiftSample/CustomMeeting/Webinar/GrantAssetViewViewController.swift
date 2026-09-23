//
//  GrantAssetViewViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

final class GrantAssetViewViewController: UIViewController {

    let userId: UInt

    private let canBeCoOwnerLabel = UILabel()
    private let asset1TextField = UITextField()
    private let asset2TextField = UITextField()
    private let switch1 = UISwitch()
    private let switch2 = UISwitch()
    private var assetInfos: [MobileRTCGrantCoOwnerAssetsInfo] = []

    init(userId: UInt) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Grant Asset View"

        let closeItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        closeItem.tintColor = UIColor(red: 0x2D/255.0, green: 0x8C/255.0, blue: 0xFF/255.0, alpha: 1)
        navigationItem.leftBarButtonItem = closeItem

        setupLayout()
        switch1.addTarget(self, action: #selector(setAssetInfo1Grant(_:)), for: .valueChanged)
        switch2.addTarget(self, action: #selector(setAssetInfo2Grant(_:)), for: .valueChanged)
    }

    private func setupLayout() {
        canBeCoOwnerLabel.font = .systemFont(ofSize: 16)
        canBeCoOwnerLabel.textColor = .black

        for tf in [asset1TextField, asset2TextField] {
            tf.borderStyle = .roundedRect
            tf.font = .systemFont(ofSize: 14)
            tf.isUserInteractionEnabled = false
        }

        let asset1Row = UIStackView(arrangedSubviews: [asset1TextField, switch1])
        asset1Row.axis = .horizontal
        asset1Row.spacing = 12
        asset1Row.alignment = .center

        let asset2Row = UIStackView(arrangedSubviews: [asset2TextField, switch2])
        asset2Row.axis = .horizontal
        asset2Row.spacing = 12
        asset2Row.alignment = .center

        let assignCohostButton = makeButton(title: "assignCohost", action: #selector(assignCohostTapped))
        let makeHostButton = makeButton(title: "makeHost", action: #selector(makeHostTapped))
        let revokeCoHostButton = makeButton(title: "revokeCoHost", action: #selector(revokeCoHostTapped))
        let reclaimHostButton = makeButton(title: "reclaimHost", action: #selector(reclaimHostTapped))

        let stack = UIStackView(arrangedSubviews: [
            canBeCoOwnerLabel, asset1Row, asset2Row,
            assignCohostButton, makeHostButton, revokeCoHostButton, reclaimHostButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1)
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let isCan = ms.canBeCoOwner(userId)
        canBeCoOwnerLabel.text = "canBeCoOwner: \(isCan)"
        guard isCan, let userInfo = ms.userInfo(byID: userId) else { return }
        let infos = userInfo.getGrantCoOwnerAssetsInfo() ?? []
        assetInfos = infos
        if infos.count == 2 {
            asset1TextField.text = infos[0].description
            switch1.isOn = infos[0].isGranted
            asset2TextField.text = infos[1].description
            switch2.isOn = infos[1].isGranted
        }
    }

    @objc private func onDone() { dismiss(animated: true) }

    @objc private func setAssetInfo1Grant(_ sender: UISwitch) {
        guard assetInfos.count >= 1 else { return }
        assetInfos[0].isGranted = sender.isOn
        Logger.info("Switch ---- \(sender.isOn ? "ON" : "OFF")")
    }

    @objc private func setAssetInfo2Grant(_ sender: UISwitch) {
        guard assetInfos.count >= 2 else { return }
        assetInfos[1].isGranted = sender.isOn
        Logger.info("Switch ---- \(sender.isOn ? "ON" : "OFF")")
    }

    @objc private func assignCohostTapped() {
        let ret = MobileRTC.shared().getMeetingService()?.assignCohost(userId, withAssetsPrivilege: assetInfos)
        Logger.info("assignCohost err: \(ret.map { String($0.rawValue) } ?? "nil")")
    }

    @objc private func makeHostTapped() {
        let ret = MobileRTC.shared().getMeetingService()?.makeHost(userId, withAssetsPrivilege: assetInfos)
        Logger.info("makeHost err: \(ret.map { String($0.rawValue) } ?? "nil")")
    }

    @objc private func revokeCoHostTapped() {
        let ret = MobileRTC.shared().getMeetingService()?.revokeCoHost(userId) ?? false
        Logger.info("revokeCoHost ret: \(ret)")
    }

    @objc private func reclaimHostTapped() {
        let ret = MobileRTC.shared().getMeetingService()?.reclaimHost() ?? false
        Logger.info("reclaimHost ret: \(ret)")
    }
}
