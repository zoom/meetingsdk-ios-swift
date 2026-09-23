//
//  WebinarAttendeesListViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

final class WebinarAttendeesListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var dataSource: [NSNumber] = []
    private let reuseID = "attendeeCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Webinar Atteedees list"
        view.backgroundColor = .white

        let closeItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        closeItem.tintColor = UIColor(red: 0x2D/255.0, green: 0x8C/255.0, blue: 0xFF/255.0, alpha: 1)
        navigationItem.leftBarButtonItem = closeItem

        dataSource = MobileRTC.shared().getMeetingService()?.getWebinarAttendeeList() ?? []

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 50
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
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

    @objc private func onDone() { dismiss(animated: true) }
}

extension WebinarAttendeesListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        let userID = dataSource[indexPath.row].uintValue
        let info = MobileRTC.shared().getMeetingService()?.attendeeInfo(byID: userID)
        cell.textLabel?.text = info?.userName ?? ""
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let ms = MobileRTC.shared().getMeetingService(),
              let cell = tableView.cellForRow(at: indexPath) else { return }
        let userID = dataSource[indexPath.row].uintValue

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Grant Asset View", style: .default) { _ in
            let vc = GrantAssetViewViewController(userId: userID)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            (UIApplication.shared.delegate as? AppDelegate)?
                .topViewController()?
                .present(nav, animated: true)
        })

        if ms.hasPromptAndDePromptPrivilege() {
            alert.addAction(UIAlertAction(title: "Prompt the attendee to panelist", style: .default) { [weak self] _ in
                ms.promptAttendee2Panelist(userID)
                self?.dataSource = ms.getWebinarAttendeeList() ?? []
                self?.tableView.reloadData()
            })
        }
        let allowTalkTitle = ms.isAllowAttendeeTalk(userID) ? "Disable talking" : "Allow to talk"
        alert.addAction(UIAlertAction(title: allowTalkTitle, style: .default) { _ in
            ms.allowAttenddeTalk(userID, allow: !ms.isAllowAttendeeTalk(userID))
        })
        if ms.isMeetingHost() || ms.isMeetingCoHost() {
            alert.addAction(UIAlertAction(title: "Remove webinar attendee", style: .default) { _ in
                ms.removeUser(userID)
            })
        }
        alert.addAction(UIAlertAction(title: "Send a private chat message", style: .default) { _ in
            let msg = MobileRTCMeetingChat()
            msg.receiverId = "\(userID)"
            msg.content = "This is a private chat message"
            let err = ms.sendChatMsg(msg)
            Logger.info("SendChat:sendChatToUser ---> \(err.rawValue)")
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
