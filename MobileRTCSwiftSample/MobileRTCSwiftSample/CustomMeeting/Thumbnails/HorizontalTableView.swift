//
//  HorizontalTableView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import UIKit

/// `UITableView` subclass that displays rows horizontally by rotating its layout 90°.
/// Frame translations compensate for the rotation transform so callers can set frames in the parent's coordinate space.
final class HorizontalTableView: UITableView {

    var isDraggingRow: Bool = false

    override var frame: CGRect {
        get {
            guard !transform.isIdentity else { return super.frame }
            let r = super.frame
            return CGRect(
                x: r.origin.x + (r.size.width - r.size.height) / 2,
                y: r.origin.y + (r.size.height - r.size.width) / 2,
                width: r.size.height,
                height: r.size.width
            )
        }
        set {
            guard !newValue.isEmpty else { return }
            if transform.isIdentity {
                super.frame = newValue
                return
            }
            let saved = transform
            transform = .identity
            estimatedRowHeight = 0
            estimatedSectionHeaderHeight = 0
            estimatedSectionFooterHeight = 0
            contentInsetAdjustmentBehavior = .never
            let newRect = CGRect(
                x: newValue.origin.x + (newValue.size.width - newValue.size.height) / 2,
                y: newValue.origin.y + (newValue.size.height - newValue.size.width) / 2,
                width: newValue.size.height,
                height: newValue.size.width
            )
            super.frame = newRect
            transform = saved
        }
    }
}
