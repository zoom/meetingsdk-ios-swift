//
//  ManageLanInterpreViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit

final class SampleInterpreter {
    var userID: Int
    var languageID1: Int
    var languageID2: Int
    var isAvailable: Bool

    init(userID: Int = 0, languageID1: Int = 0, languageID2: Int = 0, isAvailable: Bool = false) {
        self.userID = userID
        self.languageID1 = languageID1
        self.languageID2 = languageID2
        self.isAvailable = isAvailable
    }
}

final class ManageLanInterpreViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var dataSource: [SampleInterpreter] = []
    private var changeList: [SampleInterpreter] = []
    private var addList: [SampleInterpreter] = []
    private var deleteList: [SampleInterpreter] = []

    private let startEndButton = UIButton(type: .custom)
    private let reuseID = "lanCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false
        title = "Language Interpretation"
        view.backgroundColor = .white

        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        for item in ms.getInterpreterList() ?? [] {
            let s = SampleInterpreter(
                userID: item.getUserID(),
                languageID1: item.getLanguageID1(),
                languageID2: item.getLanguageID2(),
                isAvailable: item.isAvailable()
            )
            dataSource.append(s)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))

        configureTableView()
        configureBottomButtons()
        startEndButton.setTitle(ms.isInterpretationStarted() ? "End" : "Start", for: .normal)
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 140
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedRowHeight = 0
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.register(ManageLanInterpreTableViewCell.self, forCellReuseIdentifier: reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }

    private func configureBottomButtons() {
        let width = UIScreen.main.bounds.size.width
        let buttonWidth = (width - 30 - 20) / 3
        let y = UIScreen.main.bounds.size.height - 110

        let update = UIButton(type: .custom)
        styleBottomButton(update, title: "update", frame: CGRect(x: 15, y: y, width: buttonWidth, height: 40), action: #selector(updateClicked))
        let add = UIButton(type: .custom)
        styleBottomButton(add, title: "Add", frame: CGRect(x: update.frame.maxX + 10, y: y, width: buttonWidth, height: 40), action: #selector(addClicked))
        styleBottomButton(startEndButton, title: "End", frame: CGRect(x: add.frame.maxX + 10, y: y, width: buttonWidth, height: 40), action: #selector(startEndClicked))
    }

    private func styleBottomButton(_ button: UIButton, title: String, frame: CGRect, action: Selector) {
        button.frame = frame
        button.setTitle(title, for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func onDone() { dismiss(animated: true) }

    @objc private func updateClicked() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        for s in addList {
            ms.addInterpreter(UInt(s.userID), lan1: s.languageID1, andLan2: s.languageID2)
        }
        addList.removeAll()
        for s in changeList {
            ms.modifyInterpreter(UInt(s.userID), lan1: s.languageID1, andLan2: s.languageID2)
        }
        changeList.removeAll()
        for s in deleteList {
            ms.removeInterpreter(UInt(s.userID))
        }
        deleteList.removeAll()
    }

    @objc private func addClicked() {
        guard let ms = MobileRTC.shared().getMeetingService(),
              let all = ms.getAllLanguageList(), all.count >= 2 else { return }
        let lan1 = all[all.count - 1]
        let lan2 = all[all.count - 2]
        let s = SampleInterpreter(
            userID: Int(ms.myselfUserID()),
            languageID1: lan1.getID(),
            languageID2: lan2.getID(),
            isAvailable: true
        )
        dataSource.append(s)
        addList.append(s)
        tableView.reloadData()
    }

    @objc private func startEndClicked() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isInterpretationStarted() {
            if ms.stopInterpretation() {
                startEndButton.setTitle("Start", for: .normal)
            }
        } else {
            if ms.startInterpretation() {
                startEndButton.setTitle("End", for: .normal)
            }
        }
    }

    private func languageName(for languageID: Int) -> String {
        guard let ms = MobileRTC.shared().getMeetingService(),
              let list = ms.getAllLanguageList() else { return "" }
        for lan in list where lan.getID() == languageID {
            return lan.getName() ?? ""
        }
        return ""
    }

    private func presentLanguagePicker(for interpreter: SampleInterpreter, isLan1: Bool, sender: UIButton) {
        guard let ms = MobileRTC.shared().getMeetingService(),
              let list = ms.getAllLanguageList() else { return }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for lan in list {
            alert.addAction(UIAlertAction(title: lan.getName(), style: .default) { [weak self] _ in
                if isLan1 {
                    interpreter.languageID1 = lan.getID()
                } else {
                    interpreter.languageID2 = lan.getID()
                }
                self?.changeList.append(interpreter)
                self?.tableView.reloadData()
            })
        }
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
}

extension ManageLanInterpreViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath) as! ManageLanInterpreTableViewCell
        let interpreter = dataSource[indexPath.row]
        let userInfo = MobileRTC.shared().getMeetingService()?.userInfo(byID: UInt(interpreter.userID))
        cell.indexLabel.text = "Interpreter \(indexPath.row + 1)"
        cell.nameButton.setTitle(interpreter.isAvailable ? (userInfo?.userName ?? "") : "not join", for: .normal)
        cell.lan1Button.setTitle(languageName(for: interpreter.languageID1), for: .normal)
        cell.lan2Button.setTitle(languageName(for: interpreter.languageID2), for: .normal)
        cell.rowIndex = indexPath.row
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ManageLanInterpreViewController: OnCellButtonClickedDelegate {
    func onCellButtonClicked(_ sender: UIButton, rowIndex: Int) {
        guard rowIndex < dataSource.count else { return }
        let interpreter = dataSource[rowIndex]
        switch sender.tag {
        case ManageLanInterpreTableViewCell.tagDelete:
            deleteList.append(interpreter)
            dataSource.remove(at: rowIndex)
            tableView.reloadData()
        case ManageLanInterpreTableViewCell.tagLan1:
            presentLanguagePicker(for: interpreter, isLan1: true, sender: sender)
        case ManageLanInterpreTableViewCell.tagLan2:
            presentLanguagePicker(for: interpreter, isLan1: false, sender: sender)
        default:
            break
        }
    }
}
