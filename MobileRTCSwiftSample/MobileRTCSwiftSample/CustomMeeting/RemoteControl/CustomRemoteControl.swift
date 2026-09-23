//
//  CustomRemoteControl.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

protocol RemoteControlBarDelegate: AnyObject {
    func onClickGrap()
    func onClickInput()
}

final class RemoteControlBar: UIView {

    let actionButton = UIButton(type: .custom)
    private let inputButton = UIButton(type: .custom)
    weak var delegate: RemoteControlBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        backgroundColor = UIColor(white: 0, alpha: 0.2)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        actionButton.setTitle("grap", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.setTitleColor(.gray, for: .disabled)
        actionButton.frame = CGRect(x: 5, y: 5, width: 80, height: 40)
        actionButton.backgroundColor = UIColor(white: 0, alpha: 0.5)
        actionButton.addTarget(self, action: #selector(onActionButton), for: .touchUpInside)
        addSubview(actionButton)

        inputButton.setTitle("input", for: .normal)
        inputButton.tintColor = .white
        inputButton.frame = CGRect(x: 90, y: 5, width: 80, height: 40)
        inputButton.backgroundColor = UIColor(white: 0, alpha: 0.5)
        inputButton.addTarget(self, action: #selector(onInputButton), for: .touchUpInside)
        addSubview(inputButton)
    }

    @objc private func onActionButton() { delegate?.onClickGrap() }
    @objc private func onInputButton() { delegate?.onClickInput() }
}

private enum DragMode {
    case unknown, start, drag, end
}

final class CustomRemoteControl: NSObject {

    private weak var remoteShareView: MobileRTCActiveShareView?
    private let bar = RemoteControlBar(frame: CGRect(x: 50, y: UIScreen.main.bounds.size.height - 400, width: 175, height: 50))
    private let mouseButton = UIButton(type: .custom)
    private let keyboardView = UITextView()
    private var coverView: UIView?
    private var scrollView: UIScrollView?
    private var inputText: String?
    private var prevMouseDragTime: TimeInterval = 0
    private var dragStatus: DragMode = .unknown

    func setupRemoteControl(_ remoteShareView: MobileRTCActiveShareView) {
        self.remoteShareView = remoteShareView
        initSubviews()
        MobileRTC.shared().getRemoteControlService()?.delegate = self
    }

    private func initSubviews() {
        guard let remoteShareView else { return }
        bar.delegate = self
        bar.isHidden = true
        remoteShareView.addSubview(bar)

        let screen = UIScreen.main.bounds
        mouseButton.frame = CGRect(x: (screen.size.width - 60) / 2, y: (screen.size.height - 30) / 2, width: 60, height: 30)
        mouseButton.setTitle("mouse", for: .normal)
        mouseButton.backgroundColor = UIColor(white: 0, alpha: 0.4)
        mouseButton.addTarget(self, action: #selector(onMouseButtonDrag(_:event:)), for: .touchDragInside)
        mouseButton.addTarget(self, action: #selector(onMouseButtonUp(_:event:)), for: .touchUpInside)
        mouseButton.addTarget(self, action: #selector(onMouseButtonDrag(_:event:)), for: .touchDragOutside)
        mouseButton.addTarget(self, action: #selector(onMouseButtonUp(_:event:)), for: .touchUpOutside)
        mouseButton.isHidden = true
        remoteShareView.addSubview(mouseButton)

        keyboardView.delegate = self
        remoteShareView.addSubview(keyboardView)
    }

    private func initGesture() {
        let mousePress = UILongPressGestureRecognizer(target: self, action: #selector(handleMousePress(_:)))
        mousePress.minimumPressDuration = 1
        mousePress.numberOfTouchesRequired = 1
        mousePress.cancelsTouchesInView = false
        mouseButton.addGestureRecognizer(mousePress)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        coverView?.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        singleTap.require(toFail: doubleTap)
        coverView?.addGestureRecognizer(singleTap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 1
        longPress.numberOfTouchesRequired = 1
        coverView?.addGestureRecognizer(longPress)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 2
        pan.minimumNumberOfTouches = 2
        scrollView?.addGestureRecognizer(pan)
    }

    private func bringCoverViewToFront() {
        guard let remoteShareView, let scrollView else { return }
        remoteShareView.bringSubviewToFront(scrollView)
        remoteShareView.bringSubviewToFront(bar)
        remoteShareView.bringSubviewToFront(mouseButton)
    }

    private func removeCoverView() {
        scrollView?.removeFromSuperview()
        scrollView = nil
        coverView?.removeFromSuperview()
        coverView = nil
    }

    private func ensureOverlayViews() {
        guard let remoteShareView else { return }
        if scrollView == nil {
            let sv = UIScrollView(frame: remoteShareView.bounds)
            sv.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            scrollView = sv
        }
        if coverView == nil {
            let cv = UIView(frame: remoteShareView.bounds)
            cv.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            coverView = cv
        }
    }

    @objc private func onMouseButtonDrag(_ button: UIButton, event: UIEvent) {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              let touch = event.touches(for: button)?.first,
              let superview = button.superview else { return }

        let previousLocation = touch.previousLocation(in: button)
        let location = touch.location(in: button)
        let deltaX = location.x - previousLocation.x
        let deltaY = location.y - previousLocation.y

        let btnPoint = CGPoint(x: mouseButton.center.x + deltaX, y: mouseButton.center.y + deltaY)
        var mousePoint = CGPoint(x: btnPoint.x, y: btnPoint.y - 40)
        mouseButton.center = btnPoint
        mousePoint = superview.convert(mousePoint, to: remoteShareView)
        if (touch.timestamp - prevMouseDragTime) * 1000 > 50 {
            ms.remoteControlSingleMove(mousePoint)
            prevMouseDragTime = touch.timestamp
        }

        switch dragStatus {
        case .start:
            dragStatus = .drag
            ms.remoteControlMouseLeftDown(mousePoint)
        case .drag:
            ms.remoteControlMouseLeftDrag(mousePoint)
        case .end:
            dragStatus = .unknown
            ms.remoteControlMouseLeftUp(mousePoint)
        default:
            break
        }
    }

    @objc private func onMouseButtonUp(_ button: UIButton, event: UIEvent) {
        prevMouseDragTime = 0
        dragStatus = .end
        onMouseButtonDrag(button, event: event)
    }

    @objc private func handleDoubleTap(_ recognizer: UIGestureRecognizer) {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView),
              let view = recognizer.view else { return }
        ms.remoteControlDoubleTap(recognizer.location(in: view))
    }

    @objc private func handleMousePress(_ recognizer: UIGestureRecognizer) {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView) else { return }
        switch recognizer.state {
        case .began: dragStatus = .start
        case .ended, .failed, .cancelled: dragStatus = .unknown
        default: break
        }
    }

    @objc private func handleSingleTap(_ recognizer: UIGestureRecognizer) {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView),
              let view = recognizer.view else { return }
        let point = recognizer.location(in: view)
        mouseButton.center = point
        ms.remoteControlSingleTap(point)
    }

    @objc private func handleLongPress(_ recognizer: UIGestureRecognizer) {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView),
              recognizer.state == .began,
              let view = recognizer.view else { return }
        ms.remoteControlLongPress(recognizer.location(in: view))
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView),
              let view = recognizer.view else { return }
        let velocity = recognizer.velocity(in: view)
        if abs(velocity.y) > abs(velocity.x) {
            ms.remoteControlDoubleScroll(CGPoint(x: 0, y: velocity.y > 0 ? 1 : -1))
        }
    }
}

extension CustomRemoteControl: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let ms = MobileRTC.shared().getRemoteControlService() else { return true }
        if range.length > 0, text.isEmpty {
            ms.remoteControlKeyInput(MobileRTCRemoteControl_Del)
        } else if text == "\n" {
            ms.remoteControlKeyInput(MobileRTCRemoteControl_Return)
        } else {
            if range.length > 0 {
                inputText = nil
            } else {
                inputText = text.isEmpty ? nil : text
            }
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        if let markedRange = textView.markedTextRange {
            inputText = textView.text(in: markedRange)
        }
        if textView.markedTextRange == nil, let inputText {
            MobileRTC.shared().getRemoteControlService()?.remoteControlCharInput(inputText)
            self.inputText = nil
        }
    }
}

extension CustomRemoteControl: RemoteControlBarDelegate {
    func onClickGrap() {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView) else { return }
        let ret = ms.grabRemoteControlView(remoteShareView)
        Logger.info("grabRemoteControlView: \(ret.rawValue)")
    }

    func onClickInput() {
        guard let remoteShareView,
              let ms = MobileRTC.shared().getRemoteControlService(),
              ms.isHaveRemoteControlRight(remoteShareView) else { return }
        if keyboardView.isFirstResponder {
            if keyboardView.canResignFirstResponder {
                keyboardView.resignFirstResponder()
            }
        } else if keyboardView.canBecomeFirstResponder {
            keyboardView.becomeFirstResponder()
        }
    }
}

extension CustomRemoteControl: MobileRTCRemoteControlDelegate {
    func onRemoteControlPrivilegeChanged(_ isMyControl: Bool) {
        Logger.info("onRemoteControlPrivilegeChanged: \(isMyControl)")
        if !isMyControl {
            removeCoverView()
        }
        bar.actionButton.isEnabled = isMyControl
        bar.isHidden = !isMyControl
    }

    func startRemoteControlCallBack(_ resultValue: MobileRTCRemoteControlError) {
        Logger.info("startRemoteControlCallBack: \(resultValue.rawValue)")
    }

    func onEnterOrLeaveRemoteControllingStatus(_ isEnter: Bool) {
        Logger.info("onEnterOrLeaveRemoteControllingStatus: \(isEnter)")
        guard let remoteShareView else { return }
        if isEnter {
            bar.actionButton.isEnabled = false
            mouseButton.isHidden = false
            ensureOverlayViews()
            if let scrollView, let coverView {
                remoteShareView.addSubview(scrollView)
                scrollView.addSubview(coverView)
            }
            initGesture()
            bringCoverViewToFront()
        } else {
            bar.actionButton.isEnabled = true
            mouseButton.isHidden = true
            removeCoverView()
        }
    }
}
