//
//  VBViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

final class VBViewController: UIViewController {

    private lazy var addButton = makeButton(title: NSLocalizedString("Add", comment: ""), action: #selector(onAdd))
    private lazy var removeButton = makeButton(title: NSLocalizedString("Remove", comment: ""), action: #selector(onRemove))
    private lazy var closeButton = makeButton(title: NSLocalizedString("Close", comment: ""), action: #selector(onCloseVB))
    private lazy var useButton = makeButton(title: NSLocalizedString("Use", comment: ""), action: #selector(onUse))
    private lazy var nextButton = makeButton(title: NSLocalizedString("Next", comment: ""), action: #selector(onNext))

    private lazy var greenSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(onSwitchToggled), for: .valueChanged)
        if #available(iOS 14.0, *) {
            toggle.preferredStyle = .checkbox
        }
        return toggle
    }()

    private var vbIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.navigationBar.isTranslucent = false
        title = "Virtual Background"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))

        guard let ms = MobileRTC.shared().getMeetingService(), ms.isSupportVirtualBG() else {
            Logger.info("[VB Test] isSupportVirtualBG : false")
            return
        }
        let ok = ms.startPreview(withFrame: view.frame)
        Logger.info("[VB Test] startPreviewWithFrame ok=\(ok)")
        guard ok else { return }
        if let preview = ms.previewView {
            view.addSubview(preview)
        }
        greenSwitch.isOn = ms.isUsingGreenVB()
        initSubViews()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutButtons()
        if CustomMeetingLayout.isIPad {
            greenSwitch.frame = CGRect(x: 100, y: 100, width: 200, height: 200)
        }
    }

    private func layoutButtons() {
        let buttons = [addButton, removeButton, closeButton, useButton, nextButton]
        let count = CGFloat(buttons.count)
        let marginLeft: CGFloat = 12
        let marginRight: CGFloat = 12
        let intervalX: CGFloat = 3
        let totalWidth = view.frame.width - marginLeft - marginRight
        let buttonW = (totalWidth - intervalX * (count - 1)) / count
        let buttonH: CGFloat = 50
        let startY = view.frame.height - 150
        for (i, button) in buttons.enumerated() {
            let idx = CGFloat(i)
            button.frame = CGRect(x: marginLeft + idx * (buttonW + intervalX), y: startY, width: buttonW, height: buttonH)
        }
    }

    private func initSubViews() {
        if CustomMeetingLayout.isIPad {
            view.addSubview(greenSwitch)
        }
        view.addSubview(addButton)
        view.addSubview(removeButton)
        view.addSubview(closeButton)
        view.addSubview(nextButton)
        view.addSubview(useButton)
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor(red: 0x66 / 255, green: 0x66 / 255, blue: 0x66 / 255, alpha: 1)
        button.setTitleColor(UIColor(red: 45 / 255, green: 140 / 255, blue: 255 / 255, alpha: 1), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func onDone() {
        MobileRTC.shared().getMeetingService()?.stopPreview()
        dismiss(animated: true)
    }

    @objc private func onAdd() {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isDeviceSupportSmartVirtualBG() else { return }
        for name in ["zoom_intro1", "zoom_intro2", "zoom_intro3", "zoom_intro4"] {
            guard let image = UIImage(named: name) else { continue }
            let err = ms.addBGImage(image)
            Logger.info("[VB Test] addBGImage \(name) => \(err.rawValue)")
        }
    }

    @objc private func onRemove() {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isDeviceSupportSmartVirtualBG() else { return }
        let images = ms.getBGImageList() ?? []
        guard let last = images.last else { return }
        let err = ms.removeBGImage(last)
        Logger.info("[VB Test] removeBGImage => \(err.rawValue)")
    }

    @objc private func onCloseVB() {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isDeviceSupportSmartVirtualBG() else { return }
        let err = ms.useBGImage(nil)
        Logger.info("[VB Test] useBGImage(nil) => \(err.rawValue)")
    }

    @objc private func onSwitchToggled() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let err = ms.enableGreenVB(greenSwitch.isOn)
        Logger.info("[VB Test] enableGreenVB => \(err.rawValue)")
    }

    @objc private func onUse() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if greenSwitch.isOn {
            guard let preview = ms.previewView else { return }
            let err = ms.selectGreenVBPoint(CGPoint(x: preview.bounds.width / 2, y: preview.bounds.height / 2))
            Logger.info("[VB Test] selectGreenVBPoint => \(err.rawValue)")
            return
        }
        guard ms.isDeviceSupportSmartVirtualBG() else { return }
        let images = ms.getBGImageList() ?? []
        for image in images {
            if image.vbType != .none, !image.isSelect {
                let err = ms.useBGImage(image)
                Logger.info("[VB Test] useBGImage => \(err.rawValue)")
                return
            }
        }
        Logger.info("[VB Test] onUse: no available background image")
    }

    @objc private func onNext() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let images = ms.getBGImageList() ?? []
        guard !images.isEmpty else { return }
        vbIndex = vbIndex % images.count
        let err = ms.useBGImage(images[vbIndex])
        Logger.info("[VB Test] useBGImage => \(err.rawValue)")
        vbIndex += 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard greenSwitch.isOn,
              let ms = MobileRTC.shared().getMeetingService(),
              let touch = touches.first,
              let preview = ms.previewView else { return }
        let point = touch.location(in: preview)
        let err = ms.selectGreenVBPoint(point)
        Logger.info("[VB Test] selectGreenVBPoint => \(err.rawValue)")
    }
}
