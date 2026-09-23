//
//  SelectLanguageViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

final class SelectLanguageViewController: UIViewController {

    var currentLanID: Int = -1

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var languages: [MobileRTCInterpretationLanguage] = []
    private let reuseID = "selectLanCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false
        title = "Language Interpretation"
        view.backgroundColor = .white

        languages = MobileRTC.shared().getMeetingService()?.getAvailableLanguageList() ?? []
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedRowHeight = 0
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
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

    @objc private func toggleMuteOriginal() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isMajorAudioTurnOff() {
            ms.turnOnMajorAudio()
        } else {
            ms.turnOffMajorAudio()
        }
    }

    private func makeMuteOriginalCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.text = NSLocalizedString("Mute Original Audio", comment: "")
        let sw = UISwitch()
        let isMuteOriginal = MobileRTC.shared().getMeetingService()?.isMajorAudioTurnOff() ?? false
        sw.setOn(isMuteOriginal, animated: false)
        sw.addTarget(self, action: #selector(toggleMuteOriginal), for: .valueChanged)
        cell.accessoryView = sw
        return cell
    }
}

extension SelectLanguageViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentLanID == -1 ? languages.count + 1 : languages.count + 2
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.text = "Original Audio"
            cell.accessoryType = (currentLanID == -1) ? .checkmark : .none
            return cell
        }
        if currentLanID != -1, indexPath.row == languages.count + 1 {
            return makeMuteOriginalCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.selectionStyle = .gray
        let lan = languages[indexPath.row - 1]
        cell.textLabel?.text = lan.getName()
        cell.accessoryType = (currentLanID == lan.getID()) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if indexPath.row == 0 {
            currentLanID = -1
            ms.joinLanguageChannel(-1)
        } else {
            if currentLanID != -1, indexPath.row == languages.count + 1 { return }
            let lan = languages[indexPath.row - 1]
            ms.joinLanguageChannel(lan.getID())
            currentLanID = lan.getID()
        }
        tableView.reloadData()
    }
}
