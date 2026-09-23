//
//  AnnoFloatBarView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

protocol AnnoFloatBarViewDelegate: AnyObject {
    func onClickStartAnnotate() -> Bool
    func onClickStopAnnotate() -> Bool
}

/// Draggable annotation toolbar overlaid on the share view. Shows a single
/// "switch" button when collapsed; expands to a grid of tool controls when tapped.
final class AnnoFloatBarView: UIView {

    weak var delegate: AnnoFloatBarViewDelegate?

    private let switchButton = UIButton(type: .custom)
    private var oldPanPoint: CGPoint = .zero
    private var isAnnotating: Bool = false
    private var toolButtons: [UIButton] = []
    private weak var colorButton: UIButton?

    private var iconSize: CGSize {
        CustomMeetingLayout.isIPad ? CGSize(width: 51, height: 49) : CGSize(width: 51, height: 45)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let normalImage = UIImage(named: "icon_mainicon_normal")
        switchButton.frame = CGRect(
            x: 5,
            y: 0,
            width: normalImage?.size.width ?? 50,
            height: normalImage?.size.height ?? 50
        )
        switchButton.setBackgroundImage(normalImage, for: .normal)
        switchButton.setBackgroundImage(UIImage(named: "icon_mainicon_pressed"), for: .selected)
        switchButton.addTarget(self, action: #selector(onActionButtonClicked), for: .touchUpInside)
        switchButton.accessibilityLabel = NSLocalizedString("Annotation Bar", comment: "")
        addSubview(switchButton)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        addGestureRecognizer(pan)
    }

    func stopAnnotate() {
        isHidden = true
        guard isAnnotating else { return }
        isAnnotating = false
        hideActionView()
        _ = delegate?.onClickStopAnnotate()
    }

    // MARK: Expand / collapse

    private func showActionView() {
        backgroundColor = UIColor(white: 0, alpha: 0.4)
        toolButtons = []
        switchButton.isSelected = true

        let mainImage = UIImage(named: "icon_mainicon_normal")
        let size = iconSize
        let baseX = (mainImage?.size.width ?? 50) + 5

        let row1: [(String, Selector)] = [
            ("anno_icon_pen",       #selector(onPen)),
            ("anno_icon_highlight", #selector(onHighlight)),
            ("anno_icon_spotlight", #selector(onSpotlight))
        ]
        for (index, item) in row1.enumerated() {
            let frame = CGRect(x: baseX + CGFloat(index) * size.width, y: 5, width: size.width, height: size.height)
            addToolButton(image: item.0, title: row1Title(for: index), frame: frame, action: item.1)
        }

        // Color button: composite of a colored rounded circle on transparent background.
        let colorFrame = CGRect(x: baseX + 3 * size.width, y: 5, width: size.width, height: size.height)
        if let annoService = MobileRTC.shared().getAnnotationService() {
            let toolColor = annoService.getToolColor() ?? .white
            let composite = composedColorImage(toolColor)
            let cBtn = makeToolButton(image: nil, title: "Color", frame: colorFrame, action: #selector(onColor))
            cBtn.setImage(composite, for: .normal)
            cBtn.setImage(composite, for: .selected)
            addSubview(cBtn)
            toolButtons.append(cBtn)
            self.colorButton = cBtn
        }

        let changeFrame = CGRect(x: baseX + 4 * size.width, y: 5, width: size.width, height: size.height)
        addToolButton(image: "anno_icon_arrow", title: "Change", frame: changeFrame, action: #selector(onChange))

        let row2: [(String, String, Selector)] = [
            ("anno_icon_spotlight", "Width", #selector(onWidth)),
            ("anno_icon_undo",      "Undo",  #selector(onUndo)),
            ("anno_icon_redo",      "Redo",  #selector(onRedo)),
            ("anno_icon_clear",     "Clean", #selector(onClean(_:))),
            ("anno_icon_erase",     "Erase", #selector(onErase))
        ]
        for (index, item) in row2.enumerated() {
            let frame = CGRect(x: baseX + CGFloat(index) * size.width, y: 5 + size.height, width: size.width, height: size.height)
            addToolButton(image: item.0, title: item.1, frame: frame, action: item.2)
        }
    }

    private func row1Title(for index: Int) -> String {
        switch index {
        case 0: return "Pen"
        case 1: return "HighLight"
        default: return "SportLight"
        }
    }

    private func hideActionView() {
        backgroundColor = .clear
        switchButton.isSelected = false
        for btn in toolButtons {
            btn.removeFromSuperview()
        }
        toolButtons.removeAll()
    }

    @discardableResult
    private func addToolButton(image: String?,
                               title: String,
                               frame: CGRect,
                               action: Selector) -> UIButton {
        let btn = makeToolButton(
            image: image.flatMap { UIImage(named: $0) },
            title: title,
            frame: frame,
            action: action
        )
        if let imageName = image, let selected = UIImage(named: "\(imageName)_selected") {
            btn.setImage(selected, for: .selected)
        }
        addSubview(btn)
        toolButtons.append(btn)
        return btn
    }

    private func makeToolButton(image: UIImage?,
                                title: String,
                                frame: CGRect,
                                action: Selector) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.frame = frame
        var config = UIButton.Configuration.plain()
        config.image = image
        config.title = title
        config.imagePlacement = .top
        config.imagePadding = 2
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont(name: "HelveticaNeue-Light", size: 10)
            return out
        }
        btn.configuration = config
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    // MARK: Pan

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            oldPanPoint = gesture.location(in: gesture.view)
        case .ended:
            return
        default:
            let newPoint = gesture.location(in: gesture.view)
            let dx = newPoint.x - oldPanPoint.x
            let dy = newPoint.y - oldPanPoint.y
            center = CGPoint(x: center.x + dx, y: center.y + dy)
            setNeedsLayout()
        }
    }

    // MARK: Tool actions

    @objc private func onActionButtonClicked() {
        guard let delegate else { return }
        if !isAnnotating {
            if delegate.onClickStartAnnotate() {
                showActionView()
                isAnnotating.toggle()
            }
        } else {
            if delegate.onClickStopAnnotate() {
                hideActionView()
                isAnnotating.toggle()
            }
        }
    }

    @objc private func onPen() {
        _ = MobileRTC.shared().getAnnotationService()?.setToolType(.pen)
    }

    @objc private func onHighlight() {
        _ = MobileRTC.shared().getAnnotationService()?.setToolType(.highLighter)
    }

    @objc private func onSpotlight() {
        _ = MobileRTC.shared().getAnnotationService()?.setToolType(.spotLight)
    }

    @objc private func onColor() {
        guard let annoService = MobileRTC.shared().getAnnotationService() else { return }
        let random = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1
        )
        _ = annoService.setToolColor(random)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self,
                  let btn = self.colorButton,
                  let current = annoService.getToolColor() else { return }
            let composite = self.composedColorImage(current)
            btn.setImage(composite, for: .normal)
            btn.setImage(composite, for: .selected)
        }
    }

    @objc private func onChange() {
        guard let annoService = MobileRTC.shared().getAnnotationService() else { return }
        var type = annoService.getToolType()
        if type == .autoStampQm { type = .none }
        // Bump to next tool in the enum.
        let next = MobileRTCAnnoTool(rawValue: type.rawValue + 1) ?? .none
        _ = annoService.setToolType(next)
    }

    @objc private func onWidth() {
        guard let annoService = MobileRTC.shared().getAnnotationService() else { return }
        var width = annoService.getToolWidth()
        width += 8
        if width > 45 { width = 1 }
        _ = annoService.setToolWidth(width)
    }

    @objc private func onErase() {
        _ = MobileRTC.shared().getAnnotationService()?.setToolType(.ERASER)
    }

    @objc private func onClean(_ sender: UIButton) {
        guard MobileRTC.shared().getAnnotationService() != nil else { return }
        let alert = UIAlertController(title: "Clear", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Clear my", style: .default) { _ in
            _ = MobileRTC.shared().getAnnotationService()?.clear(.my)
        })
        alert.addAction(UIAlertAction(title: "Clear all", style: .default) { _ in
            _ = MobileRTC.shared().getAnnotationService()?.clear(.all)
        })
        alert.addAction(UIAlertAction(title: "Clear others", style: .default) { _ in
            _ = MobileRTC.shared().getAnnotationService()?.clear(.others)
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

    @objc private func onUndo() {
        _ = MobileRTC.shared().getAnnotationService()?.undo()
    }

    @objc private func onRedo() {
        _ = MobileRTC.shared().getAnnotationService()?.redo()
    }

    // MARK: Image composition for color button

    private func composedColorImage(_ color: UIColor) -> UIImage? {
        let back = solidImage(color: .clear, size: CGSize(width: 20, height: 20), roundedRadius: 0)
        let top = solidImage(color: color, size: CGSize(width: 20, height: 20), roundedRadius: 10)
        return merge(top: top, bottom: back)
    }

    private func solidImage(color: UIColor, size: CGSize, roundedRadius: CGFloat) -> UIImage? {
        let pxSize = CGSize(width: floor(size.width), height: floor(size.height))
        let rect = CGRect(origin: .zero, size: pxSize)
        UIGraphicsBeginImageContextWithOptions(pxSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        if roundedRadius > 0 {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: roundedRadius)
            color.setFill()
            path.fill()
        } else {
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            context.setFillColor(color.cgColor)
            context.fill(rect)
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func merge(top: UIImage?, bottom: UIImage?) -> UIImage? {
        guard let bottom else { return top }
        let bw = bottom.size.width
        let bh = bottom.size.height
        UIGraphicsBeginImageContextWithOptions(CGSize(width: bw, height: bh), false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        bottom.draw(in: CGRect(x: 0, y: 0, width: bw, height: bh))
        if let top {
            let xoff = (bw - top.size.width) / 2
            let yoff = (bh - top.size.height) / 2
            top.draw(in: CGRect(x: xoff, y: yoff, width: top.size.width, height: top.size.height),
                     blendMode: .multiply,
                     alpha: 1.0)
        }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
