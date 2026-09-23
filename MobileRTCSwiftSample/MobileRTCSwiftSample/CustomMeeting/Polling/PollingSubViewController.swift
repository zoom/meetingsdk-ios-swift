//
//  PollingSubViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

enum PollingSubViewType {
    case questionItem
    case subQuestionItem
    case answerItem
    case answerResultItem

    var title: String {
        switch self {
        case .questionItem: return "QuestionItem"
        case .subQuestionItem: return "SubQuestionItem"
        case .answerItem: return "AnswerItem"
        case .answerResultItem: return "AnswerResultItem"
        }
    }
}

enum PollingSubItem {
    case question(MobileRTCPollingQuestionItem)
    case answer(MobileRTCPollingAnswerItem)
    case answerResult(MobileRTCPollingAnswerResultItem)

    var pollingID: String? {
        switch self {
        case .question(let item): return item.getPollingID()
        case .answer(let item): return item.getPollingID()
        case .answerResult(let item): return item.getPollingID()
        }
    }

    var questionID: String? {
        switch self {
        case .question(let item): return item.getPollingQuestionID()
        case .answer(let item): return item.getPollingQuestionID()
        case .answerResult(let item): return item.getPollingQuestionID()
        }
    }

    var questionItem: MobileRTCPollingQuestionItem? {
        guard case .question(let item) = self else { return nil }
        return item
    }

    var answerItem: MobileRTCPollingAnswerItem? {
        guard case .answer(let item) = self else { return nil }
        return item
    }
}

final class PollingSubViewController: UIViewController {

    var subViewType: PollingSubViewType = .questionItem
    var pollingID: String?
    var items: [PollingSubItem] = []

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var actions: [PollingAction] = []
    private var selectedIndex: Int = -1
    private let reuseID = "PollingSubCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = subViewType.title
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onDone))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Test", comment: ""), style: .plain, target: self, action: #selector(onTestClicked(_:)))

        buildActions()
        configureTableView()
    }

    private func buildActions() {
        var list: [PollingAction] = [
            .getPollingSubQuestionItemList, .getPollingAnswerItemList,
            .canGetRightAnswerItemList, .getPollingRightAnswerItemList,
            .canShowAnswerResultList, .getPollingAnswerResultItemList,
            .getPollingAnswerItemByID, .getPollingQuestionImagePath,
            .getQuestionCharactersMinLen, .getQuestionCharactersMaxLen,
            .isQuestionCaseSensitive
        ]
        if let ms = MobileRTC.shared().getMeetingService(),
           !ms.isMeetingHost(), !ms.isMeetingCoHost() {
            list.append(contentsOf: [
                .attendeeSetAnswerCheck, .attendeeSetAnswerContent,
                .attendeeCanSubmitPolling, .attendeeSubmitPolling
            ])
        }
        actions = list
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
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
        navigationController?.popViewController(animated: true)
    }

    @objc private func onTestClicked(_ sender: Any) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        guard selectedIndex >= 0, selectedIndex < items.count else {
            PollingAlert.show(title: "", message: "Select polling sub please!")
            return
        }
        guard let pollingID, !pollingID.isEmpty else {
            PollingAlert.show(title: "", message: "_pollingID is nil")
            return
        }

        let alert = UIAlertController(title: "Polling Test", message: nil, preferredStyle: .actionSheet)
        for action in actions {
            alert.addAction(UIAlertAction(title: action.displayName, style: .default) { [weak self] _ in
                self?.run(action: action, ms: ms, pollingID: pollingID)
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

    private func run(action: PollingAction, ms: MobileRTCMeetingService, pollingID: String) {
        let item = items[selectedIndex]
        switch action {
        case .getPollingSubQuestionItemList:
            guard let questionItem = item.questionItem else { return }
            let subList = questionItem.getPollingSubQuestionItemList() ?? []
            if !subList.isEmpty {
                let vc = PollingSubViewController()
                vc.pollingID = pollingID
                vc.items = subList.map(PollingSubItem.question)
                vc.subViewType = .subQuestionItem
                navigationController?.pushViewController(vc, animated: true)
            } else {
                PollingAlert.show(title: "", message: "has no sub question")
            }
        case .getPollingAnswerItemList:
            guard let questionItem = item.questionItem else { return }
            let answers = questionItem.getPollingAnswerList() ?? []
            if !answers.isEmpty {
                let vc = PollingSubViewController()
                vc.pollingID = pollingID
                vc.items = answers.map(PollingSubItem.answer)
                vc.subViewType = .answerItem
                navigationController?.pushViewController(vc, animated: true)
            } else {
                PollingAlert.show(title: "", message: "has no answer item")
            }
        case .canGetRightAnswerItemList:
            PollingAlert.show(title: action.displayName, message: ms.canGetRightAnswerItemList(pollingID) ? "1" : "0")
        case .getPollingRightAnswerItemList:
            let list = ms.getPollingRightAnswerItemList(pollingID) ?? []
            if !list.isEmpty {
                let vc = PollingSubViewController()
                vc.pollingID = pollingID
                vc.items = list.map(PollingSubItem.answer)
                vc.subViewType = .answerItem
                navigationController?.pushViewController(vc, animated: true)
            } else {
                PollingAlert.show(title: "", message: "has no right answer item")
            }
        case .canShowAnswerResultList:
            let id = item.pollingID ?? ""
            PollingAlert.show(title: action.displayName, message: ms.canShowAnswerResultList(id) ? "1" : "0")
        case .getPollingAnswerResultItemList:
            let list = ms.getPollingAnswerResultItemList(pollingID) ?? []
            if !list.isEmpty {
                let vc = PollingSubViewController()
                vc.pollingID = pollingID
                vc.items = list.map(PollingSubItem.answerResult)
                vc.subViewType = .answerResultItem
                navigationController?.pushViewController(vc, animated: true)
            } else {
                PollingAlert.show(title: "", message: "has no answer result item list")
            }
        case .getPollingItemByID:
            let id = item.pollingID ?? ""
            if let polling = ms.getPollingItem(byID: id) {
                PollingAlert.show(title: action.displayName, message: PollingFormatter.describe(polling))
            }
        case .getPollingQuestionImagePath:
            let id = item.pollingID ?? ""
            let qid = item.questionID ?? ""
            let path = ms.getPollingQuestionImagePath(id, questionID: qid)
            PollingAlert.show(title: action.displayName, message: path)
        case .getQuestionCharactersMinLen:
            let qid = item.questionID ?? ""
            let minLen = ms.getQuestionCharactersMinLen(pollingID, questionID: qid)
            PollingAlert.show(title: action.displayName, message: "\(minLen)")
        case .getQuestionCharactersMaxLen:
            let qid = item.questionID ?? ""
            let maxLen = ms.getQuestionCharactersMaxLen(pollingID, questionID: qid)
            PollingAlert.show(title: action.displayName, message: "\(maxLen)")
        case .isQuestionCaseSensitive:
            let id = item.pollingID ?? ""
            let qid = item.questionID ?? ""
            PollingAlert.show(title: action.displayName, message: ms.isQuestionCaseSensitive(id, questionID: qid) ? "1" : "0")
        case .attendeeSetAnswerCheck:
            guard let answerItem = item.answerItem else { return }
            _ = ms.setAnswerCheck(answerItem, check: true)
            PollingAlert.show(title: action.displayName, message: "submitted (see logs)")
        case .attendeeSetAnswerContent:
            guard let answerItem = item.answerItem else { return }
            _ = ms.setAnswerContent(answerItem, answerText: "Test answer text")
            PollingAlert.show(title: action.displayName, message: "submitted (see logs)")
        case .attendeeCanSubmitPolling:
            let id = item.pollingID ?? ""
            PollingAlert.show(title: action.displayName, message: ms.canSubmitPolling(id) ? "1" : "0")
        case .attendeeSubmitPolling:
            let id = item.pollingID ?? ""
            PollingAlert.show(title: action.displayName, message: ms.submitPolling(id) == .success ? "successed" : "failed")
        default:
            PollingAlert.show(title: "", message: "not support now")
        }
    }
}

extension PollingSubViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.textLabel?.font = .systemFont(ofSize: 12)
        cell.textLabel?.numberOfLines = 0
        let item = items[indexPath.row]
        switch item {
        case .question(let question):
            cell.textLabel?.text = PollingFormatter.describe(question)
        case .answer(let answer):
            cell.textLabel?.text = PollingFormatter.describe(answer)
        case .answerResult(let result):
            cell.textLabel?.text = PollingFormatter.describe(result)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
    }
}
