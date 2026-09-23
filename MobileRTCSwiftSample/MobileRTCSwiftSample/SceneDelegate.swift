//
//  SceneDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private weak var mainVC: MainViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let mainVC = MainViewController()
        let nav = BaseNavigationController(rootViewController: mainVC)
        nav.isNavigationBarHidden = true
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
        self.mainVC = mainVC

        for ctx in connectionOptions.urlContexts {
            handle(url: ctx.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for ctx in URLContexts {
            handle(url: ctx.url)
        }
    }

    private func handle(url: URL) {
        let urlString = url.absoluteString
        guard let mainVC else { return }
        if url.scheme == ssoURLScheme {
            _ = mainVC.authPresenter?.ssoLogin(webURIProtocol: urlString)
        } else {
            mainVC.handZoomWebUrl(urlString)
        }
    }
}
