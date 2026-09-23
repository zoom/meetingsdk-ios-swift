//
//  WebViewController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit
import WebKit

final class WebViewController: UIViewController, UIScrollViewDelegate {
    private(set) var webView: WKWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let wv = WKWebView(frame: view.bounds)
        wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wv.scrollView.delegate = self
        view.addSubview(wv)
        webView = wv
        if let url = URL(string: "https://zoom.us") {
            wv.load(URLRequest(url: url))
        }
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isStartingShare() else { return }
        _ = ms.suspendSharing(true)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isStartingShare() else { return }
        _ = ms.suspendSharing(false)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isStartingShare() else { return }
        _ = ms.suspendSharing(true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let ms = MobileRTC.shared().getMeetingService(), ms.isStartingShare() else { return }
        _ = ms.suspendSharing(false)
    }
}
