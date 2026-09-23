//
//  QAListTableViewCell.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import UIKit

final class QAListTableViewCell: UITableViewCell {

    let contentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .natural
        label.font = .systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.textColor = UIColor(red: 0x23 / 255, green: 0x23 / 255, blue: 0x33 / 255, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .white
        contentView.addSubview(contentLabel)
        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
