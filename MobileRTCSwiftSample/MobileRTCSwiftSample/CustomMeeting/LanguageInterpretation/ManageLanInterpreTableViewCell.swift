//
//  ManageLanInterpreTableViewCell.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import UIKit

protocol OnCellButtonClickedDelegate: AnyObject {
    func onCellButtonClicked(_ sender: UIButton, rowIndex: Int)
}

final class ManageLanInterpreTableViewCell: UITableViewCell {

    static let tagDelete = 20007
    static let tagName = 20008
    static let tagLan1 = 20009
    static let tagLan2 = 20010

    weak var delegate: OnCellButtonClickedDelegate?
    var rowIndex: Int = 0

    let indexLabel = UILabel()
    let deleteButton = UIButton(type: .custom)
    let nameButton = UIButton(type: .custom)
    let lan1Button = UIButton(type: .custom)
    let lan2Button = UIButton(type: .custom)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.backgroundColor = .white
        let width = UIScreen.main.bounds.size.width
        let halfWidth = (width - 30 - 5) / 2

        indexLabel.frame = CGRect(x: 15, y: 5, width: halfWidth, height: 40)
        indexLabel.font = .systemFont(ofSize: 13)
        indexLabel.textColor = UIColor(red: 0x23/255.0, green: 0x23/255.0, blue: 0x33/255.0, alpha: 1)
        contentView.addSubview(indexLabel)

        configureButton(deleteButton, tag: Self.tagDelete, title: "delete",
                        frame: CGRect(x: indexLabel.frame.maxX + 5, y: 5, width: (width - 30 - 10) / 2, height: 40))
        configureButton(nameButton, tag: Self.tagName, title: "",
                        frame: CGRect(x: 15, y: indexLabel.frame.maxY + 5, width: width - 30, height: 40))
        configureButton(lan1Button, tag: Self.tagLan1, title: "",
                        frame: CGRect(x: 15, y: nameButton.frame.maxY + 5, width: halfWidth, height: 40))
        configureButton(lan2Button, tag: Self.tagLan2, title: "",
                        frame: CGRect(x: lan1Button.frame.maxX + 5, y: nameButton.frame.maxY + 5, width: halfWidth, height: 40))
    }

    private func configureButton(_ button: UIButton, tag: Int, title: String, frame: CGRect) {
        button.tag = tag
        button.frame = frame
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(red: 0x23/255.0, green: 0x23/255.0, blue: 0x33/255.0, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(onCellButtonClicked(_:)), for: .touchUpInside)
        contentView.addSubview(button)
    }

    @objc private func onCellButtonClicked(_ sender: UIButton) {
        delegate?.onCellButtonClicked(sender, rowIndex: rowIndex)
    }
}
