//
//  Custom3DAvatarSettingsViewController.swift
//  MobileRTCSwiftSample
//
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import MobileRTC
import UIKit
import os

/// Lists the saved custom 3D avatars and lets the user select, create, edit,
/// duplicate, or delete them. Swift port of the Objective-C
/// `Custom3DAvatarSettingsViewController`.
final class Custom3DAvatarSettingsViewController: UITableViewController, MobileRTCMeetingSettingsDelegate {

    private var avatarList: [MobileRTC3DAvatarImageInfo] = []
    /// Avatar waiting for its model data to finish downloading before being applied.
    private var pendingAvatarToSet: MobileRTC3DAvatarImageInfo?
    private weak var downloadingAlert: UIAlertController?

    private var settings: MobileRTCMeetingSettings? {
        MobileRTC.shared().getMeetingSettings()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom 3D Avatar Settings"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(onAddButtonTapped)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AvatarCell")
        settings?.setDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings?.setDelegate(self)
        refreshAvatarList()
    }

    private func refreshAvatarList() {
        // Diagnostic: log every gate that affects Custom 3D Avatar availability so we
        // can tell which prerequisite is missing when the feature reports disabled.
        let ms = MobileRTC.shared().getMeetingService()
        Logger.info("""
        [3DAvatar] customUIMode=\(MobileRTC.shared().isEnabledCustomizeMeetingUI()) \
        loggedIn=\(MobileRTC.shared().getAuthService()?.isLoggedIn() == true) \
        meetingService=\(ms != nil) \
        is3DAvatarSupportedByDevice=\(ms?.is3DAvatarSupportedByDevice() ?? false) \
        is3DAvatarEnabled=\(ms?.is3DAvatarEnabled() ?? false) \
        isCustom3DAvatarEnabled=\(MobileRTC.shared().getMeetingSettings()?.isCustom3DAvatarEnabled() ?? false)
        """)

        guard let settings, settings.isCustom3DAvatarEnabled() else {
            avatarList = []
            tableView.reloadData()
            let alert = UIAlertController(title: "Error",
                                          message: "Custom 3D Avatar is not enabled",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
            return
        }
        avatarList = settings.getCustom3DAvatarImageList() ?? []
        tableView.reloadData()
    }

    @objc private func onAddButtonTapped() {
        let vc = Custom3DAvatarEditViewController(mode: .create)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        avatarList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AvatarCell", for: indexPath)
        let avatarInfo = avatarList[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = avatarInfo.imageName ?? "Avatar \(avatarInfo.index)"
        var detail = "Index: \(avatarInfo.index)"
        if avatarInfo.isLastUsed {
            detail += " • Last Used"
        }
        content.secondaryText = detail

        if let path = avatarInfo.imagePath, !path.isEmpty,
           let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .uncached),
           let image = UIImage(data: data) {
            content.image = image
            content.imageProperties.maximumSize = CGSize(width: 60, height: 60)
            content.imageProperties.cornerRadius = 5
        }
        cell.contentConfiguration = content
        cell.accessoryType = avatarInfo.isSelected ? .checkmark : .none
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let settings else { return }
        let avatarInfo = avatarList[indexPath.row]

        if settings.isCustom3DAvatarImageModelDataReady(avatarInfo) {
            let error = settings.setCustom3DAvatarImage(avatarInfo)
            if error == .success {
                refreshAvatarList()
            } else {
                showError("Failed to set avatar: \(error.rawValue)")
            }
        } else {
            // Model data not ready — download first, then apply on the delegate callback.
            pendingAvatarToSet = avatarInfo
            let error = settings.downloadCustom3DAvatarImageModelData(avatarInfo)
            if error != .success {
                pendingAvatarToSet = nil
                showError("Failed to start download: \(error.rawValue)")
            } else {
                let alert = UIAlertController(title: "Downloading",
                                              message: "Downloading avatar data, please wait...",
                                              preferredStyle: .alert)
                downloadingAlert = alert
                present(alert, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let avatarInfo = avatarList[indexPath.row]

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.deleteAvatar(avatarInfo)
            completion(true)
        }
        let duplicateAction = UIContextualAction(style: .normal, title: "Duplicate") { [weak self] _, _, completion in
            self?.duplicateAvatar(avatarInfo)
            completion(true)
        }
        duplicateAction.backgroundColor = .systemBlue
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.editAvatar(avatarInfo)
            completion(true)
        }
        editAction.backgroundColor = .systemGray

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, duplicateAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func deleteAvatar(_ avatarInfo: MobileRTC3DAvatarImageInfo) {
        let alert = UIAlertController(title: "Delete Avatar",
                                      message: "Are you sure you want to delete this avatar?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self, let settings = self.settings else { return }
            let error = settings.deleteCustom3DAvatarImage(avatarInfo)
            if error == .success {
                self.refreshAvatarList()
            } else {
                self.showError("Failed to delete avatar: \(error.rawValue)")
            }
        })
        present(alert, animated: true)
    }

    private func duplicateAvatar(_ avatarInfo: MobileRTC3DAvatarImageInfo) {
        let alert = UIAlertController(title: "Duplicate Avatar",
                                      message: "Are you sure you want to duplicate this avatar?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Duplicate", style: .default) { [weak self] _ in
            guard let self, let settings = self.settings else { return }
            let error = settings.duplicateCustom3DAvatarImage(avatarInfo)
            if error == .success {
                self.refreshAvatarList()
            } else {
                self.showError("Failed to duplicate avatar: \(error.rawValue)")
            }
        })
        present(alert, animated: true)
    }

    private func editAvatar(_ avatarInfo: MobileRTC3DAvatarImageInfo) {
        let vc = Custom3DAvatarEditViewController(mode: .edit, avatarInfo: avatarInfo)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - MobileRTCMeetingSettingsDelegate

    func onCustom3DAvatarImageModelDataDownloaded(_ success: Bool, imageInfo: MobileRTC3DAvatarImageInfo?) {
        Logger.info("onCustom3DAvatarImageModelDataDownloaded success=\(success)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.downloadingAlert?.dismiss(animated: true)
            self.downloadingAlert = nil

            guard success else {
                self.pendingAvatarToSet = nil
                self.showError("Failed to download avatar data")
                return
            }
            if let pending = self.pendingAvatarToSet, let settings = self.settings {
                let error = settings.setCustom3DAvatarImage(pending)
                if error == .success {
                    self.refreshAvatarList()
                } else {
                    self.showError("Failed to set avatar: \(error.rawValue)")
                }
            }
            self.pendingAvatarToSet = nil
        }
    }

    func onCustom3DAvatarDefaultImageModelDataDownloaded(_ success: Bool) {
        Logger.info("onCustom3DAvatarDefaultImageModelDataDownloaded success=\(success)")
    }
}
