//
//  BOMeetingViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

extension Notification.Name {
    static let boDataUpdate = Notification.Name("kBO_NOTIFICATION_DATA_UPDATE")
    static let boHelpReceived = Notification.Name("kBO_NOTIFICATION_HELP_RECEIVED")
    static let boBroadcastReceived = Notification.Name("kBO_NOTIFICATION_BRODCASET_RECEIVED")
}

let kBOHelpRequesterIDsKey = "bo.help.requester.id_list"

enum BOAction: Int {
    // Creator
    case creatorCreateBreakoutRoom = 100
    case creatorCreateBOInBatch
    case creatorUpdateBO
    case creatorRemoveBO
    case creatorAssignUserToBO
    case creatorRemoveUser
    case creatorSetBOOption
    case creatorGetBOOption
    case creatorIsWebPreAssignBOEnabled
    case creatorRequestAndUseWebPreAssignBOList
    case creatorGetWebPreAssignBODataStatus

    // Admin
    case adminStartBO
    case adminStopBO
    case adminAssignNewUserToBO
    case adminSwitchUser
    case adminCanStartBO
    case adminBroadcastMessage
    case adminBroadcastVoice
    case adminHandleHelpRequest
    case creatorInviteBOUserReturnToMainSession

    // Assistant
    case assistantJoinBO
    case assistantLeaveBO

    // Attendee
    case attendeeJoinBO
    case attendeeLeaveBO
    case attendeeGetBOName
    case attendeeRequestForHelp
    case attendeeIsHostInThisBO

    // BOData
    case dataHelperUnsignedUserList
    case dataHelperBOMeetingIDList
    case dataHelperGetBOUser
    case dataHelperGetBOMeeting
    case dataHelperGetMyBOName
    case dataHelperIsBOUserMyself

    // BOService
    case serviceGetBOStatus

    var displayName: String {
        switch self {
        case .creatorCreateBreakoutRoom: return "BOCreator_CreateBreakoutRoom"
        case .creatorCreateBOInBatch: return "BOCreator_CreateBOInBatch"
        case .creatorUpdateBO: return "BOCreator_UpdateBO"
        case .creatorRemoveBO: return "BOCreator_RemoveBO"
        case .creatorAssignUserToBO: return "BOCreator_AssignUserToBO"
        case .creatorRemoveUser: return "BOCreator_RemoveUser"
        case .creatorSetBOOption: return "BOCreator_SetBOOption"
        case .creatorGetBOOption: return "BOCreator_GetBOOption"
        case .creatorIsWebPreAssignBOEnabled: return "BOCreator_IsWebPreAssignBOEnabled"
        case .creatorRequestAndUseWebPreAssignBOList: return "BOCreator_RequestAndUseWebPreAssignBOList"
        case .creatorGetWebPreAssignBODataStatus: return "BOCreator_GetWebPreAssignBODataStatus"
        case .adminStartBO: return "BOAdmin_StartBO"
        case .adminStopBO: return "BOAdmin_StopBO"
        case .adminAssignNewUserToBO: return "BOAdmin_AssignNewUserToBO"
        case .adminSwitchUser: return "BOAdmin_SwitchUser"
        case .adminCanStartBO: return "BOAdmin_CanStartBO"
        case .adminBroadcastMessage: return "BOAdmin_BroadcastMessage"
        case .adminBroadcastVoice:
            if MobileRTC.shared().getMeetingService()?.isBroadcastingVoiceToBO() == true {
                return "Stop BOAdmin_BroadcastVoice"
            }
            return "Start BOAdmin_BroadcastVoice"
        case .adminHandleHelpRequest:
            let arr = UserDefaults.standard.array(forKey: kBOHelpRequesterIDsKey) as? [String]
            if let arr {
                return "BOAdmin_HandleHelpRequest(\(arr.count))"
            }
            return "BOAdmin_HandleHelpRequest"
        case .creatorInviteBOUserReturnToMainSession: return "BOCreator_InviteBOUserReturnToMainSession"
        case .assistantJoinBO: return "BOAssistant_JoinBO"
        case .assistantLeaveBO: return "BOAssistant_LeaveBO"
        case .attendeeJoinBO: return "BOAttendee_JoinBO"
        case .attendeeLeaveBO: return "BOAttendee_LeaveBO"
        case .attendeeGetBOName: return "BOAttendee_GetBOName"
        case .attendeeRequestForHelp: return "BOAttendee_RequestForHelp"
        case .attendeeIsHostInThisBO: return "BOAttendee_IsHostInThisBO"
        case .dataHelperUnsignedUserList: return "BODataHelper_UnsignedUserList"
        case .dataHelperBOMeetingIDList: return "BODataHelper_BOMeetingIDList"
        case .dataHelperGetBOUser: return "BODataHelper_GetBOUser"
        case .dataHelperGetBOMeeting: return "BODataHelper_GetBOMeeting"
        case .dataHelperGetMyBOName: return "BODataHelper_GetMyBOName"
        case .dataHelperIsBOUserMyself: return "BODataHelper_IsBOUserMyself"
        case .serviceGetBOStatus: return "BOService_GetBOStatus"
        }
    }
}

final class BOMeetingViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var actions: [BOAction] = []
    private let reuseID = "BOCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false
        title = "BO Meeting"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))

        rebuildActions()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateTable), name: .boDataUpdate, object: nil)
        nc.addObserver(self, selector: #selector(updateTable), name: .boHelpReceived, object: nil)
        nc.addObserver(self, selector: #selector(onBroadcastMessageNoti(_:)), name: .boBroadcastReceived, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    private func rebuildActions() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        var list: [BOAction] = []
        if ms.getCreatorHelper() != nil {
            list.append(contentsOf: [
                .creatorCreateBreakoutRoom, .creatorCreateBOInBatch,
                .creatorUpdateBO, .creatorRemoveBO, .creatorAssignUserToBO,
                .creatorRemoveUser, .creatorSetBOOption, .creatorGetBOOption,
                .creatorIsWebPreAssignBOEnabled, .creatorRequestAndUseWebPreAssignBOList,
                .creatorGetWebPreAssignBODataStatus
            ])
        }
        if ms.getDataHelper() != nil {
            list.append(contentsOf: [
                .dataHelperUnsignedUserList, .dataHelperBOMeetingIDList,
                .dataHelperGetBOUser, .dataHelperGetBOMeeting,
                .dataHelperGetMyBOName, .dataHelperIsBOUserMyself
            ])
        }
        if ms.getAdminHelper() != nil {
            list.append(contentsOf: [
                .adminStartBO, .adminStopBO, .adminAssignNewUserToBO,
                .adminSwitchUser, .adminCanStartBO, .adminBroadcastMessage,
                .adminBroadcastVoice, .adminHandleHelpRequest,
                .creatorInviteBOUserReturnToMainSession
            ])
        }
        if ms.getAssistantHelper() != nil {
            list.append(contentsOf: [.assistantJoinBO, .assistantLeaveBO])
        }
        if ms.getAttedeeHelper() != nil {
            list.append(contentsOf: [
                .attendeeJoinBO, .attendeeLeaveBO, .attendeeGetBOName,
                .attendeeRequestForHelp, .attendeeIsHostInThisBO
            ])
        }
        list.append(.serviceGetBOStatus)
        actions = list
    }

    @objc private func updateTable() {
        rebuildActions()
        tableView.reloadData()
    }

    @objc private func onDone() {
        NotificationCenter.default.removeObserver(self)
        dismiss(animated: true)
    }

    @objc private func onBroadcastMessageNoti(_ note: Notification) {
        guard let msg = note.object as? String else { return }
        let alert = UIAlertController(title: "BO Boradcast", message: "Broadcast Msg:\(msg)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }
}

extension BOMeetingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { actions.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        cell.textLabel?.text = actions[indexPath.row].displayName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let action = actions[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        BOActionRunner.run(action: action, sourceCell: cell, presenter: self)
    }
}

// MARK: - Action runner

enum BOActionRunner {

    static func run(action: BOAction, sourceCell: UIView?, presenter: UIViewController) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let creator = ms.getCreatorHelper()
        let dataHelper = ms.getDataHelper()
        let admin = ms.getAdminHelper()
        let assistant = ms.getAssistantHelper()
        let attendee = ms.getAttedeeHelper()

        let alert: UIAlertController?
        switch action {
        case .creatorCreateBreakoutRoom:
            guard let creator else { Logger.info("no object"); return }
            let boName = "new BO\(Date().timeIntervalSince1970)"
            _ = creator.createBreakoutRoom(boName)
            alert = simpleAlert(title: "Create new BO Name", message: boName)
        case .creatorCreateBOInBatch:
            guard let creator else { Logger.info("no object"); return }
            let boNames = (0..<10).map { String(format: "Batch_BO_%02d", $0 + 1) }
            _ = creator.createGroupBO(boNames)
            alert = simpleAlert(title: "Create BO Names", message: boNames.joined(separator: "\n"))
        case .creatorUpdateBO:
            guard let creator, let dataHelper else { Logger.info("no object"); return }
            let boId = (dataHelper.getBOMeetingIDList() as? [String])?.first ?? ""
            let boName = "BO\(Date().timeIntervalSince1970)"
            _ = creator.updateBO(boId, name: boName)
            alert = simpleAlert(title: "Update BO Name", message: "Update Bo Name to:\(boName), Bo ID:\(boId)")
        case .creatorRemoveBO:
            guard let creator, let dataHelper else { Logger.info("no object"); return }
            let ids = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let sheet = UIAlertController(title: "Remove BO", message: nil, preferredStyle: .actionSheet)
            for boId in ids {
                guard let meeting = dataHelper.getBOMeeting(byID:boId) else { continue }
                sheet.addAction(UIAlertAction(title: meeting.getName(), style: .default) { _ in
                    _ = creator.removeBO(boId)
                })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .default))
            alert = sheet
        case .creatorAssignUserToBO:
            guard let creator, let dataHelper else { Logger.info("no object"); return }
            let unsigned = (dataHelper.getUnassignedUserList() as? [String]) ?? []
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let sheet = UIAlertController(title: "Assign all unsigned user to BO", message: nil, preferredStyle: .actionSheet)
            for boId in meetingIDs {
                guard let meeting = dataHelper.getBOMeeting(byID:boId) else { continue }
                sheet.addAction(UIAlertAction(title: meeting.getName(), style: .default) { _ in
                    for userId in unsigned { _ = creator.assignUser(userId, toBO: boId) }
                })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .default))
            alert = sheet
        case .creatorRemoveUser:
            guard let creator, let dataHelper else { Logger.info("no object"); return }
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let sheet = UIAlertController(title: "Remove all user in one BO", message: nil, preferredStyle: .actionSheet)
            for boId in meetingIDs {
                guard let meeting = dataHelper.getBOMeeting(byID:boId) else { continue }
                sheet.addAction(UIAlertAction(title: meeting.getName(), style: .default) { _ in
                    let users = meeting.getUserList() ?? []
                    for userId in users { _ = creator.removeUser(userId, fromBO: boId) }
                })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .default))
            alert = sheet
        case .creatorSetBOOption:
            guard let creator else { Logger.info("no object"); return }
            let option = MobileRTCBOOption()
            option.countdownSeconds = .seconds_30
            option.isParticipantCanChooseBO = false
            option.isParticipantCanReturnToMainSessionAtAnyTime = false
            option.isAutoMoveAllAssignedParticipantsEnabled = false
            option.isBOTimerEnabled = true
            option.isTimerAutoStopBOEnabled = true
            option.timerDurationMinutes = 2
            _ = creator.setBOOption(option)
            let msg = """
            count_down_second:30 s
            isParticipantCanChooseBO:\(option.isParticipantCanChooseBO ? "Y" : "N")
            isParticipantCanReturnToMainSessionAtAnyTime:\(option.isParticipantCanReturnToMainSessionAtAnyTime ? "Y" : "N")
            isAutoMoveAllAssignedParticipantsEnabled:\(option.isAutoMoveAllAssignedParticipantsEnabled ? "Y" : "N")
            isBOTimerEnabled:\(option.isBOTimerEnabled ? "Y" : "N")
            isTimerAutoStopBOEnabled:\(option.isTimerAutoStopBOEnabled ? "Y" : "N")
            timerDuration:\(option.timerDurationMinutes)s
            """
            alert = simpleAlert(title: "creator setBOOption", message: msg)
        case .creatorGetBOOption:
            guard let creator else { Logger.info("no object"); return }
            let opt = creator.getBOOption()
            let msg = """
            count_down_second:\(opt?.countdownSeconds.rawValue ?? 0)
            isParticipantCanChooseBO:\(opt?.isParticipantCanChooseBO == true ? "Y" : "N")
            isParticipantCanReturnToMainSessionAtAnyTime:\(opt?.isParticipantCanReturnToMainSessionAtAnyTime == true ? "Y" : "N")
            isAutoMoveAllAssignedParticipantsEnabled:\(opt?.isAutoMoveAllAssignedParticipantsEnabled == true ? "Y" : "N")
            isBOTimerEnabled:\(opt?.isBOTimerEnabled == true ? "Y" : "N")
            isTimerAutoStopBOEnabled:\(opt?.isTimerAutoStopBOEnabled == true ? "Y" : "N")
            timerDurationMinutes:\(opt?.timerDurationMinutes ?? 0)min
            """
            alert = simpleAlert(title: "creator getBOOption", message: msg)
        case .creatorIsWebPreAssignBOEnabled:
            guard let creator else { Logger.info("no object"); return }
            let enabled = creator.isWebPreAssignBOEnabled()
            alert = simpleAlert(title: "creator isWebPreAssignBOEnabled", message: enabled ? "Enabled" : "Disabled")
        case .creatorRequestAndUseWebPreAssignBOList:
            guard let creator else { Logger.info("no object"); return }
            let ret = creator.requestAndUseWebPreAssignBOList()
            alert = simpleAlert(title: "creator requestAndUseWebPreAssignBOList", message: ret == .success ? "Success" : "Failed")
        case .creatorGetWebPreAssignBODataStatus:
            guard let creator else { Logger.info("no object"); return }
            let status = creator.getWebPreAssignBODataStatus()
            alert = simpleAlert(title: "creator getWebPreAssignBODataStatus", message: "\(status.rawValue)")

        case .adminStartBO:
            guard let admin else { Logger.info("no object"); return }
            let ret = admin.startBO()
            alert = simpleAlert(title: "Start BO", message: ret ? "Success" : "Fail")
        case .adminStopBO:
            guard let admin else { Logger.info("no object"); return }
            let ret = admin.stopBO()
            alert = simpleAlert(title: "Stop BO", message: ret ? "Success" : "Fail")
        case .adminAssignNewUserToBO:
            guard let admin, let dataHelper else { Logger.info("no object"); return }
            let unsigned = (dataHelper.getUnassignedUserList() as? [String]) ?? []
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let sheet = UIAlertController(title: "Assign all unsigned user to BO", message: nil, preferredStyle: .actionSheet)
            for boId in meetingIDs {
                guard let meeting = dataHelper.getBOMeeting(byID:boId) else { continue }
                sheet.addAction(UIAlertAction(title: meeting.getName(), style: .default) { _ in
                    for userId in unsigned { _ = admin.assignNewUser(userId, toRunningBO: boId) }
                })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .default))
            alert = sheet
        case .adminSwitchUser:
            guard let admin, let dataHelper else { Logger.info("no object"); return }
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            guard meetingIDs.count >= 2,
                  let fromID = meetingIDs.first, let toID = meetingIDs.last,
                  let fromBO = dataHelper.getBOMeeting(byID:fromID),
                  let toBO = dataHelper.getBOMeeting(byID:toID),
                  let fromUserID = fromBO.getUserList()?.first else {
                alert = simpleAlert(title: "SwitchUser", message: "only one bo")
                break
            }
            let user = dataHelper.getBOUser(byUserID: fromUserID)
            let ret = admin.switchUser(fromUserID, toRunningBO: toBO.getId() ?? "")
            alert = simpleAlert(title: "SwitchUser", message: "switch \(user?.getName() ?? "") from \(fromBO.getName() ?? "") to \(toBO.getName() ?? ""): \(ret ? "Success" : "Fail")")
        case .adminCanStartBO:
            guard let admin else { return }
            alert = simpleAlert(title: "Can start BO by Admin?", message: admin.canStartBO() ? "Yes, You can" : "No, you can't")
        case .adminBroadcastMessage:
            guard let admin else { return }
            let msg = "BO_MSG_\(Date().timeIntervalSince1970)"
            let ret = admin.broadcastMessage(msg)
            alert = simpleAlert(title: "BOAdmin_BroadcastMessage", message: ret ? "Success" : "Failed")
        case .adminBroadcastVoice:
            guard let admin else { return }
            let isBroadcasting = ms.isBroadcastingVoiceToBO()
            let ret = admin.broadcastVoice(toBO: !isBroadcasting)
            alert = simpleAlert(title: isBroadcasting ? "Stop BOAdmin_BroadcastVoice" : "Start BOAdmin_BroadcastVoice", message: ret ? "Success" : "Failed")
        case .adminHandleHelpRequest:
            handleBOHelpInOrder(presenter: presenter)
            return
        case .creatorInviteBOUserReturnToMainSession:
            guard let admin, let dataHelper else { Logger.info("no object"); return }
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let sheet = UIAlertController(title: "Invite all user return to main session", message: nil, preferredStyle: .actionSheet)
            for boId in meetingIDs {
                guard let meeting = dataHelper.getBOMeeting(byID:boId) else { continue }
                sheet.addAction(UIAlertAction(title: meeting.getName(), style: .default) { _ in
                    let users = meeting.getUserList() ?? []
                    for userId in users { _ = admin.inviteBOUserReturn(toMainSession: userId) }
                })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .default))
            alert = sheet

        case .assistantJoinBO:
            guard let assistant, let dataHelper else { Logger.info("no object"); return }
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let sheet = UIAlertController(title: "BOAssistant_JoinBO", message: nil, preferredStyle: .actionSheet)
            for boId in meetingIDs {
                guard let meeting = dataHelper.getBOMeeting(byID:boId) else { continue }
                sheet.addAction(UIAlertAction(title: meeting.getName(), style: .default) { _ in
                    _ = assistant.joinBO(boId)
                })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .default))
            alert = sheet
        case .assistantLeaveBO:
            guard let assistant else { Logger.info("no object"); return }
            let ret = assistant.leaveBO()
            alert = simpleAlert(title: "BOAssistant_LeaveBO", message: ret ? "Success" : "Fail")

        case .attendeeJoinBO:
            guard let attendee else { Logger.info("no object"); return }
            let ret = attendee.joinBO()
            alert = simpleAlert(title: "BOAttendee_JoinBO", message: ret ? "Success" : "Fail")
        case .attendeeLeaveBO:
            guard let attendee else { Logger.info("no object"); return }
            let ret = attendee.leaveBO()
            alert = simpleAlert(title: "BOAttendee_LeaveBO", message: ret ? "Success" : "Fail")
        case .attendeeGetBOName:
            guard let attendee else { Logger.info("no object"); return }
            alert = simpleAlert(title: "BOAttendee_GetBOName", message: attendee.getBOName())
        case .attendeeRequestForHelp:
            guard let attendee else { Logger.info("no object"); return }
            let ret = attendee.requestForHelp()
            alert = simpleAlert(title: "BOAttendee_RequestForHelp", message: ret ? "succeed" : "failed")
        case .attendeeIsHostInThisBO:
            guard let attendee else { Logger.info("no object"); return }
            let inBO = attendee.isHostInThisBO()
            alert = simpleAlert(title: "BOAttendee_RequestForHelp", message: "host now is \(inBO ? "in" : "not in") current BO meeting")

        case .dataHelperUnsignedUserList:
            guard let dataHelper else { Logger.info("no object"); return }
            let list = (dataHelper.getUnassignedUserList() as? [String]) ?? []
            alert = simpleAlert(title: "BODataHelper_UnsignedUserList", message: "\(list)")
        case .dataHelperBOMeetingIDList:
            guard let dataHelper else { Logger.info("no object"); return }
            let ids = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let info = ids.compactMap { id -> String? in
                guard let m = dataHelper.getBOMeeting(byID:id) else { return nil }
                return "ID:\(m.getId() ?? ""), Name:\(m.getName() ?? "")"
            }.joined(separator: "\n")
            alert = simpleAlert(title: "BODataHelper_BOMeetingIDList", message: info, closeTitle: "OK")
        case .dataHelperGetBOUser:
            guard let dataHelper else { Logger.info("no object"); return }
            let unsigned = (dataHelper.getUnassignedUserList() as? [String]) ?? []
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let firstMeeting = meetingIDs.first.flatMap { dataHelper.getBOMeeting(byID:$0) }
            let firstInBOUserID = (firstMeeting?.getUserList() as? [String])?.first
            let unassignedUser = unsigned.first.flatMap { dataHelper.getBOUser(byUserID: $0) }
            let inBOUser = firstInBOUserID.flatMap { dataHelper.getBOUser(byUserID: $0) }
            alert = simpleAlert(title: "BODataHelper_GetBOUser", message: "unassignboUser:\(String(describing: unassignedUser)),inBOUser:\(String(describing: inBOUser))")
        case .dataHelperGetBOMeeting:
            guard let dataHelper else { Logger.info("no object"); return }
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            let meeting = meetingIDs.first.flatMap { dataHelper.getBOMeeting(byID:$0) }
            alert = simpleAlert(title: "BODataHelper_GetBOMeeting", message: String(describing: meeting))
        case .dataHelperGetMyBOName:
            guard let dataHelper else { Logger.info("no object"); return }
            alert = simpleAlert(title: "BODataHelper_GetMyBOName", message: dataHelper.getCurrentBOName())
        case .dataHelperIsBOUserMyself:
            guard let dataHelper else { Logger.info("no object"); return }
            let unsigned = (dataHelper.getUnassignedUserList() as? [String]) ?? []
            let meetingIDs = (dataHelper.getBOMeetingIDList() as? [String]) ?? []
            var text = ""
            for uid in unsigned {
                text += "\(uid)-\(dataHelper.isBOUserMyself(uid) ? "YES" : "NO")\n"
            }
            for mid in meetingIDs {
                let users = (dataHelper.getBOMeeting(byID:mid)?.getUserList() as? [String]) ?? []
                for uid in users {
                    text += "\(uid)-\(dataHelper.isBOUserMyself(uid) ? "YES" : "NO")\n"
                }
            }
            alert = simpleAlert(title: "BODataHelper_IsBOUserMyself", message: text)
        case .serviceGetBOStatus:
            alert = simpleAlert(title: "BOService_GetBOStatus", message: "BOService_GetBOStatus = \(ms.getBOStatus().rawValue)")
        }

        guard let alert else { return }
        if let popover = alert.popoverPresentationController, let sourceCell {
            popover.sourceView = sourceCell
            popover.sourceRect = sourceCell.bounds
            popover.permittedArrowDirections = .any
        }
        (UIApplication.shared.delegate as? AppDelegate)?
            .topViewController()?
            .present(alert, animated: true)
    }

    private static func simpleAlert(title: String, message: String?, closeTitle: String = "Cancel") -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: closeTitle, style: .cancel))
        return alert
    }

    private static func handleBOHelpInOrder(presenter: UIViewController) {
        let userId = popHelpRequester()
        NotificationCenter.default.post(name: .boDataUpdate, object: nil)
        let msg = userId.map { "Request User:\($0)" } ?? "No requested user found"
        let alert = UIAlertController(title: "Join BO for Help", message: msg, preferredStyle: .alert)
        if let userId {
            alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
                MobileRTC.shared().getMeetingService()?.getAdminHelper()?.joinBO(byUserRequest: userId)
            })
            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel) { _ in
                MobileRTC.shared().getMeetingService()?.getAdminHelper()?.ignoreUserHelpRequest(userId)
            })
        } else {
            alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        }
        presenter.present(alert, animated: true)
    }

    private static func popHelpRequester() -> String? {
        let defaults = UserDefaults.standard
        guard var list = defaults.array(forKey: kBOHelpRequesterIDsKey) as? [String], !list.isEmpty else {
            defaults.removeObject(forKey: kBOHelpRequesterIDsKey)
            defaults.set([String](), forKey: kBOHelpRequesterIDsKey)
            return nil
        }
        let first = list.removeFirst()
        defaults.set(list, forKey: kBOHelpRequesterIDsKey)
        return first
    }
}
