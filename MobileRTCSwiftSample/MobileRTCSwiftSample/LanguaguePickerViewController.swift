//
//  LanguaguePickerViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

final class LanguaguePickerViewController: UITableViewController {
    private var languageArray: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Select Language", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(onDone)
        )
        languageArray = MobileRTC.shared().supportedLanguages()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        languageArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "lang")
            ?? UITableViewCell(style: .default, reuseIdentifier: "lang")
        cell.textLabel?.text = languageArray[indexPath.row]
        cell.accessoryType = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MobileRTC.shared().setLanguage(languageArray[indexPath.row])
        onDone()
    }

    @objc private func onDone() {
        navigationController?.popViewController(animated: true)
    }
}
