//
//  BottomBarView.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

final class ViewItem: Equatable {
    var itemName: String = ""
    var view: UIView = UIView()
    var userId: UInt = 0
    var isActive: Bool = false
    var renderer: MobileRTCRenderer?

    static func == (lhs: ViewItem, rhs: ViewItem) -> Bool {
        lhs.userId == rhs.userId && lhs.view === rhs.view
    }
}

final class LeftLabel: UILabel {
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 25)))
    }
}

protocol BottomBarViewDelegate: AnyObject {
    func pinThumberViewItem(_ item: ViewItem)
    func stopThumbViewVideo()
    func startThumbViewVideo()
}

final class BottomBarView: UIView {

    static var cellWidth: CGFloat {
        let w = (UIScreen.main.bounds.size.width - 10.0) / 3.0
        return w > 135 ? 135 : w
    }
    static var cellHeight: CGFloat { cellWidth }
    static var tableHeight: CGFloat { cellHeight + 20 }

    private static let nameTag = 11001

    private weak var handle: BottomBarViewDelegate?
    private let gradientLayer = CAGradientLayer()
    private(set) var viewArray: [ViewItem] = []
    let thumbTableView = HorizontalTableView(frame: .zero, style: .plain)

    init(delegate: BottomBarViewDelegate) {
        self.handle = delegate
        super.init(frame: .zero)
        layer.addSublayer(gradientLayer)
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.colors = [
            UIColor(white: 0, alpha: 0).cgColor,
            UIColor(white: 0, alpha: 0.75).cgColor
        ]
        thumbTableView.backgroundColor = .clear
        thumbTableView.separatorColor = .clear
        thumbTableView.isPagingEnabled = false
        thumbTableView.delegate = self
        thumbTableView.dataSource = self
        thumbTableView.showsVerticalScrollIndicator = false
        addSubview(thumbTableView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
        gradientLayer.frame = bounds
        let screen = UIScreen.main.bounds
        frame = CGRect(x: 0, y: screen.size.height - Self.tableHeight, width: screen.size.width, height: Self.tableHeight)

        let xInset: CGFloat = (Self.isLandscapeRight && CustomMeetingLayout.hasHomeIndicator)
            ? CustomMeetingLayout.safeZoomInsets + 10
            : 0
        thumbTableView.frame = CGRect(x: xInset, y: 0, width: screen.size.width, height: Self.tableHeight)
        updateLayout()
    }

    private static var isLandscapeRight: Bool {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation == .landscapeRight
    }

    func addThumberViewItem(_ item: ViewItem) {
        guard !viewArray.contains(item) else { return }
        let nameLabel = LeftLabel()
        nameLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)
        nameLabel.text = item.itemName
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.tag = Self.nameTag
        item.view.addSubview(nameLabel)

        item.view.layer.cornerRadius = 10
        item.view.layer.borderColor = UIColor(white: 1, alpha: 0.5).cgColor
        item.view.layer.borderWidth = 1
        item.view.clipsToBounds = true
        item.view.transform = CGAffineTransform(rotationAngle: .pi / 2)
        viewArray.append(item)
        updateLayout()
    }

    func removeThumberViewItem(_ item: ViewItem) {
        viewArray.removeAll { $0 == item }
        updateLayout()
    }

    func removeThumberViewItem(userId: UInt) {
        viewArray.removeAll { $0.userId == userId }
        updateLayout()
    }

    func getThumberViewItems(userId: UInt) -> [ViewItem] {
        viewArray.filter { $0.userId == userId }
    }

    private func updateLayout() {
        thumbTableView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        thumbTableView.reloadData()
    }
}

extension BottomBarView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewArray.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { Self.cellHeight }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        let item = viewArray[indexPath.row]
        item.view.frame = CGRect(x: 15, y: 10, width: Self.tableHeight - 30, height: Self.cellHeight - 10)
        for view in item.view.subviews where view.tag == Self.nameTag {
            view.frame = CGRect(x: 0, y: Self.tableHeight - 30 - 24, width: Self.cellHeight - 10, height: 24)
            item.view.bringSubviewToFront(view)
        }
        cell.contentView.addSubview(item.view)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        handle?.pinThumberViewItem(viewArray[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if CustomMeetingLayout.isIPad || CustomMeetingLayout.isLandscape { return 0.1 }
        let margin = UIScreen.main.bounds.size.width - CGFloat(viewArray.count) * Self.cellHeight
        return margin > 0 ? (margin * 0.5 - 5) : 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let height = self.tableView(tableView, heightForHeaderInSection: section)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: Self.cellHeight, height: height))
        header.backgroundColor = .clear
        return header
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { handle?.stopThumbViewVideo() }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handle?.startThumbViewVideo()
        scrollToRowPosition()
        thumbTableView.reloadData()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handle?.startThumbViewVideo()
            scrollToRowPosition()
            thumbTableView.reloadData()
        }
    }

    private func scrollToRowPosition() {
        let rowHeight = Self.cellHeight
        guard rowHeight > 0 else { return }
        let offsetY = thumbTableView.contentOffset.y
        let baseRow = Int(offsetY / rowHeight)
        let remainder = offsetY.truncatingRemainder(dividingBy: rowHeight)
        let snapped = (remainder >= rowHeight / 2) ? baseRow + 1 : baseRow
        let clamped = min(max(snapped, 0), max(viewArray.count - 1, 0))
        guard clamped < viewArray.count else { return }
        let indexPath = IndexPath(row: clamped, section: 0)
        thumbTableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}
