//
//  PollingViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

extension Notification.Name {
    static let pollingDataUpdate = Notification.Name("kPOLLING_NOTIFICATION_DATA_UPDATE")
}

enum PollingAction: Int, CaseIterable {
    case canDoPolling = 100
    case getActivePollingID
    case getPollingQuestionItemList
    case getPollingSubQuestionItemList
    case getPollingAnswerItemList
    case canGetRightAnswerItemList
    case getPollingRightAnswerItemList
    case canShowAnswerResultList
    case getPollingAnswerResultItemList
    case getPollingItemByID
    case getPollingAnswerItemByID
    case getPollingQuestionImagePath
    case getQuestionCharactersMinLen
    case getQuestionCharactersMaxLen
    case isQuestionCaseSensitive

    case hostCanAddPolling
    case hostAddPolling
    case hostCanEditPolling
    case hostEditPolling
    case hostCanDeletePolling
    case hostDeletePolling
    case hostCanDuplicatePolling
    case hostDuplicatePolling
    case hostCanViewPollingResultFromBrowser
    case hostViewPollingResultFromBrowser
    case hostGetPollingItemList
    case hostCanStartPolling
    case hostStartPolling
    case hostStopPolling
    case hostCanRestartPolling
    case hostRestartPolling
    case hostCanSharePollingResult
    case hostStartSharePollingResult
    case hostStopSharePollingResult
    case hostEnableGetRightAnswerList
    case hostCanDownloadResult
    case hostDownloadResult

    case attendeeSetAnswerCheck
    case attendeeSetAnswerContent
    case attendeeCanSubmitPolling
    case attendeeSubmitPolling

    var displayName: String {
        switch self {
        case .canDoPolling: return "Polling_Common_canDoPolling"
        case .getActivePollingID: return "Polling_Common_getActivePollingID"
        case .getPollingQuestionItemList: return "Polling_Common_getPollingQuestionItemList"
        case .getPollingSubQuestionItemList: return "Polling_Common_getPollingSubQuestionItemList"
        case .getPollingAnswerItemList: return "Polling_Common_getPollingAnswerItemList"
        case .canGetRightAnswerItemList: return "Polling_Common_canGetRightAnswerItemList"
        case .getPollingRightAnswerItemList: return "Polling_Common_getPollingRightAnswerItemList"
        case .canShowAnswerResultList: return "Polling_Common_canShowAnswerResultList"
        case .getPollingAnswerResultItemList: return "Polling_Common_getPollingAnswerResultItemList"
        case .getPollingItemByID: return "Polling_Common_getPollingItemByID"
        case .getPollingAnswerItemByID: return "Polling_Common_getPollingAnswerItemByID"
        case .getPollingQuestionImagePath: return "Polling_Common_getPollingQuestionImagePath"
        case .getQuestionCharactersMinLen: return "Polling_Common_getQuestionCharactersMinLen"
        case .getQuestionCharactersMaxLen: return "Polling_Common_getQuestionCharactersMaxLen"
        case .isQuestionCaseSensitive: return "Polling_Common_isQuestionCaseSensitive"
        case .hostCanAddPolling: return "Polling_Host_canAddPolling"
        case .hostAddPolling: return "Polling_Host_addPolling"
        case .hostCanEditPolling: return "Polling_Host_canEditPolling"
        case .hostEditPolling: return "Polling_Host_editPolling"
        case .hostCanDeletePolling: return "Polling_Host_canDeletePolling"
        case .hostDeletePolling: return "Polling_Host_deletePolling"
        case .hostCanDuplicatePolling: return "Polling_Host_canDuplicatePolling"
        case .hostDuplicatePolling: return "Polling_Host_duplicatePolling"
        case .hostCanViewPollingResultFromBrowser: return "Polling_Host_canViewPollingResultFromBrowser"
        case .hostViewPollingResultFromBrowser: return "Polling_Host_viewPollingResultFromBrowser"
        case .hostGetPollingItemList: return "Polling_Host_getPollingItemList"
        case .hostCanStartPolling: return "Polling_Host_canStartPolling"
        case .hostStartPolling: return "Polling_Host_startPolling"
        case .hostStopPolling: return "Polling_Host_stopPolling"
        case .hostCanRestartPolling: return "Polling_Host_canRestartPolling"
        case .hostRestartPolling: return "Polling_Host_restartPolling"
        case .hostCanSharePollingResult: return "Polling_Host_canSharePollingResult"
        case .hostStartSharePollingResult: return "Polling_Host_startSharePollingResult"
        case .hostStopSharePollingResult: return "Polling_Host_stopSharePollingResult"
        case .hostEnableGetRightAnswerList: return "Polling_Host_enableGetRightAnswerList"
        case .hostCanDownloadResult: return "Polling_Host_canDownloadResult"
        case .hostDownloadResult: return "Polling_Host_downLoadResult"
        case .attendeeSetAnswerCheck: return "Polling_Attendee_setAnswerCheck"
        case .attendeeSetAnswerContent: return "Polling_Attendee_setAnswerContent"
        case .attendeeCanSubmitPolling: return "Polling_Attendee_canSubmitPolling"
        case .attendeeSubmitPolling: return "Polling_Attendee_submitPolling"
        }
    }
}

final class PollingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var dataSource: [MobileRTCPollingItem] = []
    private var actions: [PollingAction] = []
    private var selectedIndex: Int = -1
    private let reuseID = "PollingCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false
        title = "Polling"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Test", comment: ""), style: .plain, target: self, action: #selector(onTestClicked(_:)))

        NotificationCenter.default.addObserver(self, selector: #selector(updateTable), name: .pollingDataUpdate, object: nil)

        reloadDataSource()
        configureTableView()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    private func reloadDataSource() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        if ms.isMeetingHost() || ms.isMeetingCoHost() {
            dataSource = ms.getPollingItemList() ?? []
        } else {
            let activeID = ms.getActivePollingID() ?? ""
            if let item = ms.getPollingItem(byID: activeID) {
                dataSource = [item]
            } else {
                dataSource = []
            }
        }

        var list: [PollingAction] = [
            .canDoPolling, .getActivePollingID, .getPollingQuestionItemList,
            .getPollingSubQuestionItemList, .getPollingAnswerItemList,
            .canGetRightAnswerItemList, .getPollingRightAnswerItemList,
            .canShowAnswerResultList, .getPollingAnswerResultItemList,
            .getPollingItemByID, .getPollingAnswerItemByID,
            .getPollingQuestionImagePath, .getQuestionCharactersMinLen,
            .getQuestionCharactersMaxLen, .isQuestionCaseSensitive
        ]
        if ms.isMeetingHost() || ms.isMeetingCoHost() {
            list.append(contentsOf: [
                .hostCanAddPolling, .hostAddPolling, .hostCanEditPolling, .hostEditPolling,
                .hostCanDeletePolling, .hostDeletePolling, .hostCanDuplicatePolling,
                .hostDuplicatePolling, .hostCanViewPollingResultFromBrowser,
                .hostViewPollingResultFromBrowser, .hostGetPollingItemList,
                .hostCanStartPolling, .hostStartPolling, .hostStopPolling,
                .hostCanRestartPolling, .hostRestartPolling, .hostCanSharePollingResult,
                .hostStartSharePollingResult, .hostStopSharePollingResult,
                .hostEnableGetRightAnswerList, .hostCanDownloadResult, .hostDownloadResult
            ])
        } else {
            list.append(contentsOf: [
                .attendeeSetAnswerCheck, .attendeeSetAnswerContent,
                .attendeeCanSubmitPolling, .attendeeSubmitPolling
            ])
        }
        actions = list
    }

    @objc private func updateTable() {
        reloadDataSource()
        tableView.reloadData()
    }

    @objc private func onDone() {
        dismiss(animated: true)
    }

    @objc private func onTestClicked(_ sender: Any) {
        guard selectedIndex >= 0, selectedIndex < dataSource.count else {
            PollingAlert.show(title: "", message: "Select polling please!")
            return
        }
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let item = dataSource[selectedIndex]
        let pollingID = item.getPollingID() ?? ""

        let alert = UIAlertController(title: "Polling Test", message: nil, preferredStyle: .actionSheet)
        for action in actions {
            alert.addAction(UIAlertAction(title: action.displayName, style: .default) { [weak self] _ in
                self?.run(action: action, pollingID: pollingID, ms: ms)
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

    private func run(action: PollingAction, pollingID: String, ms: MobileRTCMeetingService) {
        switch action {
        case .canDoPolling:
            PollingAlert.show(title: action.displayName, message: "\(ms.canDoPolling())")
        case .getActivePollingID:
            PollingAlert.show(title: action.displayName, message: ms.getActivePollingID())
        case .getPollingQuestionItemList:
            let list = ms.getPollingQuestionItemList(pollingID) ?? []
            let vc = PollingSubViewController()
            vc.pollingID = pollingID
            vc.items = list.map(PollingSubItem.question)
            vc.subViewType = .questionItem
            navigationController?.pushViewController(vc, animated: true)
        case .getPollingItemByID:
            if let polling = ms.getPollingItem(byID: pollingID) {
                PollingAlert.show(title: action.displayName, message: PollingFormatter.describe(polling))
            }
        case .hostCanAddPolling:
            PollingAlert.show(title: action.displayName, message: ms.canAddPolling() ? "1" : "0")
        case .hostAddPolling:
            PollingAlert.show(title: action.displayName, message: ms.addPolling() == .success ? "successed" : "failed")
        case .hostCanEditPolling:
            PollingAlert.show(title: action.displayName, message: ms.canEditPolling(pollingID) ? "1" : "0")
        case .hostEditPolling:
            PollingAlert.show(title: action.displayName, message: ms.editPolling(pollingID) == .success ? "successed" : "failed")
        case .hostCanDeletePolling:
            PollingAlert.show(title: action.displayName, message: ms.canDeletePolling(pollingID) ? "1" : "0")
        case .hostDeletePolling:
            PollingAlert.show(title: action.displayName, message: ms.deletePolling(pollingID) == .success ? "successed" : "failed")
        case .hostCanDuplicatePolling:
            PollingAlert.show(title: action.displayName, message: ms.canDuplicatePolling(pollingID) ? "1" : "0")
        case .hostDuplicatePolling:
            PollingAlert.show(title: action.displayName, message: ms.duplicatePolling(pollingID) == .success ? "successed" : "failed")
        case .hostCanViewPollingResultFromBrowser:
            PollingAlert.show(title: action.displayName, message: ms.canViewPollingResult(fromBrowser: pollingID) ? "1" : "0")
        case .hostViewPollingResultFromBrowser:
            PollingAlert.show(title: action.displayName, message: ms.viewPollingResult(fromBrowser: pollingID) == .success ? "successed" : "failed")
        case .hostCanStartPolling:
            PollingAlert.show(title: action.displayName, message: ms.canStartPolling(pollingID) ? "1" : "0")
        case .hostStartPolling:
            PollingAlert.show(title: action.displayName, message: ms.startPolling(pollingID) == .success ? "successed" : "failed")
        case .hostStopPolling:
            PollingAlert.show(title: action.displayName, message: ms.stopPolling(pollingID) == .success ? "successed" : "failed")
        case .hostCanRestartPolling:
            PollingAlert.show(title: action.displayName, message: ms.canRestartPolling(pollingID) ? "1" : "0")
        case .hostRestartPolling:
            PollingAlert.show(title: action.displayName, message: ms.restartPolling(pollingID) == .success ? "successed" : "failed")
        case .hostCanSharePollingResult:
            PollingAlert.show(title: action.displayName, message: ms.canSharePollingResult(pollingID) ? "1" : "0")
        case .hostStartSharePollingResult:
            PollingAlert.show(title: action.displayName, message: ms.startSharePollingResult(pollingID) == .success ? "successed" : "failed")
        case .hostStopSharePollingResult:
            PollingAlert.show(title: action.displayName, message: ms.stopSharePollingResult(pollingID) == .success ? "successed" : "failed")
        case .hostEnableGetRightAnswerList:
            PollingAlert.show(title: action.displayName, message: ms.enableGetRightAnswerList(true) == .success ? "successed" : "failed")
        case .hostCanDownloadResult:
            PollingAlert.show(title: action.displayName, message: ms.canDownloadResult() ? "1" : "0")
        case .hostDownloadResult:
            PollingAlert.show(title: action.displayName, message: ms.downLoadResult() == .success ? "successed" : "failed")
        default:
            PollingAlert.show(title: "", message: "do sub polling view")
        }
    }
}

extension PollingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.textLabel?.font = .systemFont(ofSize: 12)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = PollingFormatter.describe(dataSource[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
    }
}

enum PollingAlert {
    static func show(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message ?? "empty", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }
}

enum PollingFormatter {
    static func describe(_ item: MobileRTCPollingItem) -> String {
        let name = item.getPollingName() ?? ""
        let typeRaw = item.getPollingType().rawValue
        let status = item.getPollingStatus().rawValue
        let questionCount = item.getPollingQuestionCount()
        let voted = item.getTotalVotedUserCount()
        let isLibrary = item.isLibraryPolling()
        let typeName: String
        switch typeRaw {
        case 1: typeName = "Poll"
        case 2: typeName = "Quiz"
        default: typeName = ""
        }
        return "PollingName:\(name) (\(typeName)),PollingStatus:\(status),PollingQuestionCount:\(questionCount),TotalVotedUserCount:\(voted),isLibraryPolling:\(isLibrary)"
    }

    static func describe(_ item: MobileRTCPollingQuestionItem) -> String {
        let name = item.getPollingQuestionName() ?? ""
        let answered = item.getAnsweredCount()
        let required = item.isRequired()
        return "QuestionName:\(name) (\(questionTypeName(rawType: item.getPollingQuestionType().rawValue))),answeredCount:\(answered),isRequired:\(required)"
    }

    static func describe(_ item: MobileRTCPollingAnswerItem) -> String {
        let name = item.getPollingAnswerName() ?? ""
        let content = item.getPollingAnsweredContent() ?? ""
        let isChecked = item.isChecked()
        return "AnswerName:\(name),answeredContent:\(content), isChecked:\(isChecked)"
    }

    static func describe(_ item: MobileRTCPollingAnswerResultItem) -> String {
        let name = item.getPollingAnswerName() ?? ""
        let count = item.getSelectedCount()
        return "AnswerName:\(name), selectedCount:\(count)"
    }

    static func questionTypeName(rawType: Int) -> String {
        switch rawType {
        case 1: return "Single"
        case 2: return "Multi"
        case 3: return "Matching"
        case 4: return "RankOrder"
        case 5: return "ShortAnswer"
        case 6: return "LongAnswer"
        case 7: return "FillBlank"
        case 8: return "RatingScale"
        case 9: return "Dropdown"
        default: return "Unknown"
        }
    }
}
