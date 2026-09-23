//
//  SettingsViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

final class SettingsViewController: UITableViewController {
    enum Item: CaseIterable {
        case meeting
        case language
        case switchDomain
        case customizedInvitationDomain
        case custom3DAvatar
        case login

        var title: String {
            switch self {
            case .meeting: return NSLocalizedString("Meeting Settings", comment: "")
            case .language: return NSLocalizedString("Select Language", comment: "")
            case .switchDomain: return NSLocalizedString("Switch Domain and Auth Again", comment: "")
            case .customizedInvitationDomain: return NSLocalizedString("Customized Invitation Domain", comment: "")
            case .custom3DAvatar: return "Custom 3D Avatar Settings"
            case .login:
                let loggedIn = MobileRTC.shared().getAuthService()?.isLoggedIn() == true
                return loggedIn ? NSLocalizedString("Sign Out", comment: "") : NSLocalizedString("Sign In", comment: "")
            }
        }
    }

    weak var authPresenter: SDKAuthPresenter?
    private var sections: [[Item]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(onDone)
        )
        sections = Item.allCases.map { [$0] }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLoginResultNotification),
            name: Notification.Name("SDKOnLoginResult"),
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @objc private func onLoginResultNotification() {
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == sections.count - 1 else { return nil }
        return "Version: \(MobileRTC.shared().mobileRTCVersion() ?? "")"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "setting-item")
            ?? UITableViewCell(style: .default, reuseIdentifier: "setting-item")
        let item = sections[indexPath.section][indexPath.row]
        cell.selectionStyle = .none
        cell.textLabel?.text = item.title
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .label
        if item == .login {
            let loggedIn = MobileRTC.shared().getAuthService()?.isLoggedIn() == true
            cell.textLabel?.textColor = loggedIn ? .systemRed : .systemBlue
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section][indexPath.row] {
        case .meeting:
            navigationController?.pushViewController(MeetingSettingsViewController(style: .insetGrouped), animated: true)
        case .language:
            navigationController?.pushViewController(LanguaguePickerViewController(style: .insetGrouped), animated: true)
        case .switchDomain:
            switchDomainAndAuthAgain()
        case .customizedInvitationDomain:
            customizedInvitationDomain()
        case .custom3DAvatar:
            navigationController?.pushViewController(Custom3DAvatarSettingsViewController(style: .plain), animated: true)
        case .login:
            handleLoginAction()
        }
    }

    @objc private func onDone() {
        dismiss(animated: true)
    }

    private func handleLoginAction() {
        let authService = MobileRTC.shared().getAuthService()
        if authService?.isLoggedIn() == true {
            navigationController?.dismiss(animated: true) {
                _ = authService?.logoutRTC()
            }
            return
        }

        let alert = UIAlertController(title: NSLocalizedString("Select Login Type", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Login with SSO", comment: ""), style: .default) { [weak self] _ in
            self?.selectSSOAction()
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    private func switchDomainAndAuthAgain() {
        let alert = UIAlertController(title: NSLocalizedString("Switch domain and auth again", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = NSLocalizedString("New Domain", comment: "")
        }
        alert.addTextField {
            $0.placeholder = NSLocalizedString("New JWT Token", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak self, weak alert] _ in
            let domain = alert?.textFields?.first?.text ?? ""
            let token = alert?.textFields?.last?.text ?? ""
            _ = MobileRTC.shared().switchDomain(domain, force: true)
            self?.authPresenter?.SDKAuth(token)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    private func customizedInvitationDomain() {
        let alert = UIAlertController(title: NSLocalizedString("Customized Invitation Domain", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = NSLocalizedString("Invitation Domain", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { [weak alert] _ in
            let domain = alert?.textFields?.first?.text ?? ""
            _ = MobileRTC.shared().getMeetingService()?.setCustomizedInvitationDomain(domain)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    private func selectSSOAction() {
        let alert = UIAlertController(title: NSLocalizedString("SSO Login Action", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Generate SSO URL", comment: ""), style: .default) { [weak self] _ in
            self?.generateSSOURL()
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Auth with protocol", comment: ""), style: .default) { [weak self] _ in
            self?.authWithProtocol()
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    private func generateSSOURL() {
        let alert = UIAlertController(title: NSLocalizedString("SSO Login Action", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = NSLocalizedString("SSO Vanity URL", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Generate", comment: ""), style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let vanity = alert?.textFields?.first?.text ?? ""
            let ssoURL = self.authPresenter?.getSSODomain(vanityURL: vanity) ?? ""
            if !ssoURL.isEmpty {
                self.showSSOURLAlert(ssoURL: ssoURL)
            }
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    private func showSSOURLAlert(ssoURL: String) {
        let alert = UIAlertController(title: NSLocalizedString("SSO Login URL", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.text = ssoURL
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Copy", comment: ""), style: .default) { _ in
            UIPasteboard.general.string = ssoURL
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Open in Safari", comment: ""), style: .default) { _ in
            guard let url = URL(string: ssoURL) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }

    private func authWithProtocol() {
        let alert = UIAlertController(title: NSLocalizedString("SSO Login Action", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = NSLocalizedString("SSO auth protocol", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Auth", comment: ""), style: .default) { [weak self, weak alert] _ in
            let value = alert?.textFields?.first?.text ?? ""
            _ = self?.authPresenter?.ssoLogin(webURIProtocol: value)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }
}
