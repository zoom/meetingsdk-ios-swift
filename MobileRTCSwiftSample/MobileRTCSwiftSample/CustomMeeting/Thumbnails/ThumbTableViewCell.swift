//
//  ThumbTableViewCell.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

/// One participant's video thumbnail inside the gallery strip.
final class ThumbTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ThumbTableViewCell"
    static let borderWidth: CGFloat = 1

    lazy var thumbView: MobileRTCVideoView = {
        let v = MobileRTCVideoView(frame: thumbFrame())
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.backgroundColor = .black
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        addSubview(thumbView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbView.frame = thumbFrame()
    }

    private func thumbFrame() -> CGRect {
        let cellSize = ceil(CustomMeetingLayout.thumbCellSize)
        let inset = Self.borderWidth
        return CGRect(x: inset, y: inset, width: cellSize - inset * 2, height: cellSize - inset * 2)
    }

    func stopThumbVideo() {
        thumbView.stopAttendeeVideo()
    }
}
