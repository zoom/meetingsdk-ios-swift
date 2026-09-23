//
//  LocalShareViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import UIKit
import WebKit

/// Hosts a `WKWebView` whose content is broadcast to other participants as a local share.
final class LocalShareViewController: UIViewController {

    private static let textFieldHeight: CGFloat = 50
    private static let topOffset: CGFloat = 80
    private static let bottomOffset: CGFloat = 60

    lazy var webView: WKWebView = {
        let web = WKWebView(frame: .zero)
        web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        web.navigationDelegate = self
        return web
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField(frame: .zero)
        tf.backgroundColor = .gray
        tf.clearButtonMode = .whileEditing
        tf.keyboardType = .URL
        tf.delegate = self
        return tf
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        view.addSubview(textField)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load(urlString: "https://zoom.us")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = view.bounds.width
        let height = view.bounds.height
        textField.frame = CGRect(x: 0, y: Self.topOffset, width: width, height: Self.textFieldHeight)
        webView.frame = CGRect(
            x: 0,
            y: Self.topOffset + Self.textFieldHeight,
            width: width,
            height: max(0, height - Self.textFieldHeight - Self.topOffset - Self.bottomOffset)
        )
    }

    private func load(urlString: String) {
        var resolved = urlString
        if URL(string: resolved)?.scheme?.isEmpty != false {
            resolved = "https://" + urlString
        }
        guard let url = URL(string: resolved),
              url.scheme?.lowercased() == "https" else {
            return
        }
        textField.text = urlString
        webView.load(URLRequest(url: url))
    }
}

extension LocalShareViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url,
              url.scheme?.lowercased() == "https" else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

extension LocalShareViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        load(urlString: trimmed)
        view.endEditing(true)
        return true
    }
}
