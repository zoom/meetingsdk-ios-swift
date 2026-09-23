//
//  AllChatMessageViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

/// Presents every chat message in the meeting and a "New Chat" action sheet
/// that exercises every formatting/styling builder on `MobileRTCMeetingChatBuilder`.
final class AllChatMessageViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var messageIDs: [String] = []
    private let reuseID = "AllChatMessageCell"

    // Sample content reused by every formatting builder.
    private static let sampleContent = "This is a , nice to meet you! \r new topic chat message"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "All Chat Message"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddMessage(_:)))

        if let ms = MobileRTC.shared().getMeetingService(),
           let ids = ms.getAllChatMessageID() {
            messageIDs = ids
        }

        configureTableView()
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedRowHeight = 0
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func onDone() {
        dismiss(animated: true)
    }

    @objc private func onAddMessage(_ sender: Any) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let alert = UIAlertController(title: "New Chat", message: nil, preferredStyle: .actionSheet)

        for (title, transform) in Self.formattingActions {
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                Self.sendBuilt(ms: ms, builder: transform)
            })
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        if let popover = alert.popoverPresentationController, let bar = navigationItem.rightBarButtonItem {
            popover.barButtonItem = bar
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }

    // MARK: Formatting actions

    /// Each action returns a configured builder ready to `.build()`. The base builder
    /// already has the sample content, receiver 0, an empty threadId, and `to_All` set.
    private static let formattingActions: [(String, (MobileRTCMeetingChatBuilder) -> MobileRTCMeetingChatBuilder?)] = [
        ("Quote",            { $0.setQuotePosition(4, end: 18) }),
        ("un Quote",         { $0.setQuotePosition(4, end: 18)?.unsetQuotePosition(4, end: 18) }),
        ("Italic",           { $0.setItalic(4, end: 18) }),
        ("un Italic",        { $0.setItalic(4, end: 18)?.unsetItalic(4, end: 18) }),
        ("Bold",             { $0.setBold(4, end: 18) }),
        ("un Bold",          { $0.setBold(4, end: 18)?.unsetBold(4, end: 18) }),
        ("Strikethrough",    { $0.setStrikethrough(4, end: 18) }),
        ("un Strikethrough", { $0.setStrikethrough(4, end: 18)?.unsetStrikethrough(4, end: 18) }),
        ("BulletedList",     { $0.setBulletedList(0, end: sampleContent.count) }),
        ("un BulletedList",  { $0.setBulletedList(0, end: sampleContent.count)?.unsetBulletedList(0, end: sampleContent.count) }),
        ("NumberedList",     { $0.setNumberedList(0, end: sampleContent.count) }),
        ("un NumberedList",  { $0.setNumberedList(0, end: sampleContent.count)?.unsetNumberedList(0, end: sampleContent.count) }),
        ("Underline",        { $0.setUnderline(4, end: 18) }),
        ("un Underline",     { $0.setUnderline(4, end: 18)?.unsetUnderline(4, end: 18) }),
        ("FontSize",         { builder in
            let attr = MobileRTCFontSizeAttrs()
            attr.fontSize = 12 // FontSize_Large
            return builder.setFontSize(attr, start: 4, end: 18)
        }),
        ("un FontSize",      { builder in
            let attr = MobileRTCFontSizeAttrs()
            attr.fontSize = 12
            return builder.setFontSize(attr, start: 4, end: 18)?.unsetFontSize(4, end: 18)
        }),
        ("InsertLink",       { builder in
            let attr = MobileRTCInsertLinkAttrs()
            attr.insertLinkUrl = "https://www.google.com"
            return builder.setInsertLink(attr, start: 4, end: 18)
        }),
        ("un InsertLink",    { builder in
            let attr = MobileRTCInsertLinkAttrs()
            attr.insertLinkUrl = "https://www.google.com"
            return builder.setInsertLink(attr, start: 4, end: 18)?.unsetInsertLink(4, end: 18)
        }),
        ("BackgroundColor",  { builder in
            let attr = MobileRTCBackgroundColorAttrs()
            attr.color = richTextColor(r: 235, g: 24, b: 7)
            return builder.setBackgroundColor(attr, start: 4, end: 18)
        }),
        ("un BackgroundColor", { builder in
            let attr = MobileRTCBackgroundColorAttrs()
            attr.color = richTextColor(r: 235, g: 24, b: 7)
            return builder.setBackgroundColor(attr, start: 4, end: 18)?.unsetBackgroundColor(4, end: 18)
        }),
        ("FontColor",        { builder in
            let attr = MobileRTCFontColorAttrs()
            attr.color = richTextColor(r: 235, g: 24, b: 7)
            return builder.setFontColor(attr, start: 4, end: 18)
        }),
        ("un FontColor",     { builder in
            let attr = MobileRTCFontColorAttrs()
            attr.color = richTextColor(r: 235, g: 24, b: 7)
            return builder.setFontColor(attr, start: 4, end: 18)?.unsetFontColor(4, end: 18)
        }),
        ("increaseIndent",   { builder in
            let attr = MobileRTCIndentAttrs()
            attr.indent = 3
            return builder.increaseIndent(attr, start: 4, end: 18)
        }),
        ("decreaseIndent",   { builder in
            let attr = MobileRTCIndentAttrs()
            attr.indent = 2
            return builder.increaseIndent(attr, start: 4, end: 18)?.decreaseIndent(attr, start: 4, end: 18)
        }),
        ("Paragraph",        { builder in
            let attr = MobileRTCParagraphAttrs()
            attr.strParagraph = "Paragraph_H1"
            return builder.setParagraph(attr, start: 4, end: 18)
        }),
        ("un Paragraph",     { builder in
            let attr = MobileRTCParagraphAttrs()
            attr.strParagraph = "Paragraph_H3"
            return builder.setParagraph(attr, start: 4, end: 18)?.unsetParagraph(4, end: 18)
        }),
    ]

    private static func richTextColor(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }

    private static func sendBuilt(ms: MobileRTCMeetingService,
                                  builder transform: (MobileRTCMeetingChatBuilder) -> MobileRTCMeetingChatBuilder?) {
        let base = MobileRTCMeetingChatBuilder()
        guard let configured = base
                .setContent(sampleContent)?
                .setReceiver(0)?
                .setThreadId("")?
                .setMessageType(.to_All) else { return }
        guard let chat = transform(configured)?.build() else { return }
        let ret = ms.sendChatMsg(chat)
        Logger.info("sendChatMsg => \(ret.rawValue)")
    }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension AllChatMessageViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messageIDs.count }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        let messageID = messageIDs[indexPath.row]
        let chatInfo = MobileRTC.shared().getMeetingService()?.meetingChat(byID: messageID)
        cell.textLabel?.text = chatInfo?.content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath),
              let ms = MobileRTC.shared().getMeetingService() else { return }
        let messageID = messageIDs[indexPath.row]
        let chatInfo = ms.meetingChat(byID: messageID)

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if ms.isChatMessageCanBeDeleted(messageID) {
            alert.addAction(UIAlertAction(title: "Delete this chat message", style: .default) { [weak self] _ in
                let ok = ms.deleteChatMessage(messageID)
                Logger.info("deleteChatMessage => \(ok)")
                guard let self, ok else { return }
                self.messageIDs.removeAll { $0 == messageID }
                self.tableView.reloadData()
            })
        }

        alert.addAction(UIAlertAction(title: "Comments this chat message", style: .default) { [weak self] _ in
            let builder = MobileRTCMeetingChatBuilder()
            let newChat = builder
                .setContent("12345\r6 This\r is a comments")?
                .setReceiver(0)?
                .setThreadId(chatInfo?.threadID ?? "")?
                .setMessageType(.to_All)?
                .setQuotePosition(2, end: 3)?
                .build()
            guard let newChat else { return }
            let ret = ms.sendChatMsg(newChat)
            Logger.info("sendChatMsg comment => \(ret.rawValue)")
            guard let self, ret == .successed else { return }
            if let ids = ms.getAllChatMessageID() {
                self.messageIDs = ids
                self.tableView.reloadData()
            }
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }
}
