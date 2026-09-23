//
//  AppDelegate.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright (c) Zoom Communications, Inc. All rights reserved.
//

import os
import UIKit
import MobileRTC

/**
* We recommend that, you can generate jwttoken on your own server instead of hardcoding in the code.
* We hardcode it here, just to run the demo.
*
* You can generate a jwttoken on the https://jwt.io/
* with this payload:
* {
*     "appKey": "string", // app key
*     "iat": long, // access token issue timestamp
*     "exp": long, // access token expire time
*     "tokenExp": long // token expire time
* }
*/
let kJwtToken: String =     ""
let kSDKDomain: String =    ""

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        Logger.info(paths.first?.path)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        MobileRTC.shared().appWillResignActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MobileRTC.shared().appDidEnterBackground()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MobileRTC.shared().appDidBecomeActive()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MobileRTC.shared().appWillTerminate()
    }


    func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        return topViewController(from: root)
    }

    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let nav = viewController as? UINavigationController, let top = nav.topViewController {
            return topViewController(from: top)
        }
        if let tab = viewController as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }
        return viewController
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

