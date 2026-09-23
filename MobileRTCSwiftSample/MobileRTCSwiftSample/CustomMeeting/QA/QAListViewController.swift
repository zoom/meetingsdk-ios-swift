//
//  QAListViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

extension Notification.Name {
    static let qaDataUpdate = Notification.Name("kQA_NOTIFICATION_DATA_UPDATE")
    static let qaWebinarRoleTransition = Notification.Name("kQA_NOTIFICATION_WEBINAR_ROLE_TRANSITION")
}

private enum QAListType {
    case all, my, open, answered, dismissed
}

final class QAListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var dataSource: [MobileRTCQAItem] = []
    private var type: QAListType = .open
    private let reuseID = "QAListCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.navigationBar.isTranslucent = false
        title = "QA List"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAdd(_:)))

        configureTableView()

        if let ms = MobileRTC.shared().getMeetingService() {
            if ms.isWebinarAttendee() {
                type = .all
            } else {
                type = .open
            }
        }
        updateData()

        NotificationCenter.default.addObserver(
            self, selector: #selector(onQADataUpdate),
            name: .qaDataUpdate, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(onWebinarRoleTransition),
            name: .qaWebinarRoleTransition, object: nil
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
    }

    @objc private func onQADataUpdate() {
        if Thread.isMainThread { updateData() }
        else { DispatchQueue.main.async { [weak self] in self?.updateData() } }
    }

    @objc private func onWebinarRoleTransition() {
        if Thread.isMainThread {
            dismiss(animated: true)
        } else {
            DispatchQueue.main.async { [weak self] in self?.dismiss(animated: true) }
        }
    }

    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 230
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedRowHeight = 0
        tableView.register(QAListTableViewCell.self, forCellReuseIdentifier: reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func updateData() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let list: [MobileRTCQAItem]
        switch type {
        case .all: list = ms.getAllQuestionList() ?? []
        case .my: list = ms.getMyQuestionList() ?? []
        case .open: list = ms.getOpenQuestionList() ?? []
        case .answered: list = ms.getAnsweredQuestionList() ?? []
        case .dismissed: list = ms.getDismissedQuestionList() ?? []
        }
        dataSource = list
        tableView.reloadData()
    }

    @objc private func onDone() {
        dismiss(animated: true)
    }

    @objc private func onAdd(_ sender: Any) {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if ms.isWebinarAttendee() {
            alert.addAction(UIAlertAction(title: "Add Question", style: .default) { _ in
                _ = ms.addQuestion("Test-Add-Qestion", anonymous: false)
            })
            alert.addAction(UIAlertAction(title: "All Questions(\(ms.getALLQuestionCount()))", style: .default) { [weak self] _ in
                self?.type = .all
                self?.updateData()
            })
            alert.addAction(UIAlertAction(title: "My Questions(\(ms.getMyQuestionCount()))", style: .default) { [weak self] _ in
                self?.type = .my
                self?.updateData()
            })
        } else {
            alert.addAction(UIAlertAction(title: "Open Questions(\(ms.getOpenQuestionCount()))", style: .default) { [weak self] _ in
                self?.type = .open
                self?.updateData()
            })
            alert.addAction(UIAlertAction(title: "Answered Questions(\(ms.getAnsweredQuestionCount()))", style: .default) { [weak self] _ in
                self?.type = .answered
                self?.updateData()
            })
            alert.addAction(UIAlertAction(title: "Dismissed Questions(\(ms.getDismissedQuestionCount()))", style: .default) { [weak self] _ in
                self?.type = .dismissed
                self?.updateData()
            })
        }

        if ms.isMeetingHost() || ms.isMeetingCoHost() {
            let anonAllowed = ms.isAllowAskQuestionAnonymously()
            alert.addAction(UIAlertAction(title: anonAllowed ? "Disallow ask question anonymously" : "Allow ask question anonymously", style: .default) { _ in
                _ = ms.allowAskQuestionAnonymously(!anonAllowed)
            })
            let viewAllAllowed = ms.isAllowAttendeeViewAllQuestion()
            alert.addAction(UIAlertAction(title: viewAllAllowed ? "Disallow attendee view all question" : "Allow attendee view all question", style: .default) { _ in
                _ = ms.allowAttendeeViewAllQuestion(!viewAllAllowed)
            })
            if viewAllAllowed {
                let upVoteAllowed = ms.isAllowAttendeeUpVoteQuestion()
                alert.addAction(UIAlertAction(title: upVoteAllowed ? "Disallow attendee up vote question" : "Allow attendee up vote question", style: .default) { _ in
                    _ = ms.allowAttendeeUpVoteQuestion(!upVoteAllowed)
                })
                let commentAllowed = ms.isAllowCommentQuestion()
                alert.addAction(UIAlertAction(title: commentAllowed ? "Disallow comment question" : "Allow comment question", style: .default) { _ in
                    _ = ms.allowCommentQuestion(!commentAllowed)
                })
            }
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        if let popover = alert.popoverPresentationController, let bar = navigationItem.rightBarButtonItem {
            popover.barButtonItem = bar
            popover.permittedArrowDirections = .any
        }
        if alert.actions.count > 1 {
            (UIApplication.shared.delegate as? AppDelegate)?
                .topViewController()?
                .present(alert, animated: true)
        }
    }
}

extension QAListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.01 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.01 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        guard let qaCell = cell as? QAListTableViewCell else { return cell }
        let item = dataSource[indexPath.row]
        let answerList = item.getAnswerlist() ?? []
        let answerString = answerList.enumerated().map { idx, ans in
            (idx > 0 ? ", " : "") + (ans.getText() ?? "")
        }.joined()
        qaCell.contentLabel.text = """
        QuestionId:\(item.getQuestionId() ?? "")  \nText:\(item.getText() ?? "") \nTime:\(item.getTime() ?? Date())  \nSenderName:\(item.getSenderName() ?? "")  \nisAnonymous:\(item.isAnonymous())  \nisMarkedAsAnswered:\(item.isMarkedAsAnswered())  \nisMarkedAsDismissed:\(item.isMarkedAsDismissed()) \ngetUpvoteNumber:\(item.getUpvoteNumber()) \ngetHasLiveAnswers:\(item.getHasLiveAnswers()) \ngetHasTextAnswers:\(item.getHasTextAnswers()) \nisMySelfUpvoted:\(item.isMySelfUpvoted()) \namILiveAnswering:\(item.amILiveAnswering()) \nisLiveAnswering:\(item.isLiveAnswering()) \ngetLiveAnswerName:\(item.getLiveAnswerName() ?? "") \nAnswer:\(answerString)
        """
        return qaCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        let item = dataSource[indexPath.row]
        let questionID = item.getQuestionId() ?? ""

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if ms.isMeetingHost() || ms.isMeetingCoHost() || ms.isWebinarPanelist() {
            if !item.isMarkedAsDismissed() {
                alert.addAction(UIAlertAction(title: "Add Answer public", style: .default) { _ in
                    let ret = ms.answerQuestionPublic(questionID, answerContent: "QA-Answer-Question-Test")
                    Logger.info("Answer Question public => \(ret)")
                })
                alert.addAction(UIAlertAction(title: "Add Answer private", style: .default) { _ in
                    let ret = ms.answerQuestionPrivate(questionID, answerContent: "QA-Answer-Question-Test")
                    Logger.info("Answer Question private => \(ret)")
                })
                alert.addAction(UIAlertAction(title: "Dismiss Question", style: .default) { _ in
                    let ret = ms.dismissQuestion(questionID)
                    Logger.info("Dismiss Question => \(ret)")
                })
            }
            if item.isMarkedAsDismissed() {
                alert.addAction(UIAlertAction(title: "Reopen Question", style: .default) { _ in
                    let ret = ms.reopenQuestion(questionID)
                    Logger.info("Reopen Question => \(ret)")
                })
            }
            if !item.amILiveAnswering(), !item.isMarkedAsDismissed(), !item.isMarkedAsAnswered() {
                alert.addAction(UIAlertAction(title: "Start Living", style: .default) { _ in
                    let ret = ms.startLiving(questionID)
                    Logger.info("Start Living => \(ret)")
                })
            }
            if item.amILiveAnswering(), !item.isMarkedAsDismissed(), !item.isMarkedAsAnswered() {
                alert.addAction(UIAlertAction(title: "End Living", style: .default) { _ in
                    let ret = ms.endLiving(questionID)
                    Logger.info("End Living => \(ret)")
                })
            }
            alert.addAction(UIAlertAction(title: "Delete Question", style: .default) { _ in
                let ret = ms.deleteQuestion(questionID)
                Logger.info("Delete Question => \(ret)")
            })
            let answers = item.getAnswerlist() ?? []
            if let firstAnswer = answers.first {
                alert.addAction(UIAlertAction(title: "Delete Answer", style: .default) { _ in
                    let ret = ms.deleteAnswer(firstAnswer.getAnswerID() ?? "")
                    Logger.info("Delete Answer => \(ret)")
                })
            }
        } else {
            if ms.isAllowCommentQuestion(), !item.isMarkedAsDismissed() {
                alert.addAction(UIAlertAction(title: "Attendee Comment Answer", style: .default) { _ in
                    let ret = ms.commentQuestion(questionID, commentContent: "QA-Attendee-comment-Question-Test")
                    Logger.info("Comment => \(ret)")
                })
            }
        }

        if ms.isAllowAttendeeUpVoteQuestion(), !item.isMarkedAsDismissed() {
            if !item.isMySelfUpvoted() {
                alert.addAction(UIAlertAction(title: "Vote Up", style: .default) { _ in
                    let ret = ms.voteupQuestion(questionID, voteup: true)
                    Logger.info("Vote Up => \(ret)")
                })
            } else {
                alert.addAction(UIAlertAction(title: "Unvote Up", style: .default) { _ in
                    let ret = ms.voteupQuestion(questionID, voteup: false)
                    Logger.info("Unvote Up => \(ret)")
                })
            }
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))

        if let popover = alert.popoverPresentationController,
           let cell = tableView.cellForRow(at: indexPath) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            popover.permittedArrowDirections = .any
        }
        if alert.actions.count > 1 {
            (UIApplication.shared.delegate as? AppDelegate)?
                .topViewController()?
                .present(alert, animated: true)
        }
    }
}
