//
//  BaseNavigationController.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import UIKit

final class BaseNavigationController: UINavigationController {

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        MobileRTC.shared().willTransition(to: newCollection, with: coordinator)
        super.willTransition(to: newCollection, with: coordinator)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        MobileRTC.shared().viewWillTransition(to: size, with: coordinator)
        super.viewWillTransition(to: size, with: coordinator)
    }
}
