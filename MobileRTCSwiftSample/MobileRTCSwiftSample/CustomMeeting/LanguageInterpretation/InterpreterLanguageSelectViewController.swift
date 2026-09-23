//
//  InterpreterLanguageSelectViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

final class InterpreterLanguageSelectViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var languages: [MobileRTCInterpretationLanguage] = []
    private let reuseID = "interpreterLanCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false
        title = "Interpreter Language Select"
        view.backgroundColor = .white

        languages = MobileRTC.shared().getMeetingService()?.getInterpreterLans() ?? []

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Listening in", comment: ""), style: .plain, target: self, action: #selector(onListenInTapped(_:)))

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

    @objc private func onListenInTapped(_ sender: Any) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let alert = UIAlertController(title: "Listening in", message: nil, preferredStyle: .actionSheet)
        for lan in ms.getInterpreterAvailableLanguages() ?? [] {
            alert.addAction(UIAlertAction(title: lan.getName(), style: .default) { _ in
                let ret = ms.setInterpreterListenLan(lan.getID())
                Logger.info("setInterpreterListenLan ====> \(ret)")
            })
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        if let item = navigationItem.leftBarButtonItem, let popover = alert.popoverPresentationController {
            popover.barButtonItem = item
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }
}

extension InterpreterLanguageSelectViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { languages.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.selectionStyle = .none
        let lan = languages[indexPath.row]
        cell.textLabel?.text = lan.getName()
        let activeID = MobileRTC.shared().getMeetingService()?.getInterpreterActiveLan() ?? -1
        cell.accessoryType = (lan.getID() == activeID) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let lan = languages[indexPath.row]
        if ms.setInterpreterActiveLan(lan.getID()) {
            for cell in tableView.visibleCells {
                cell.accessoryType = .none
            }
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
    }
}
