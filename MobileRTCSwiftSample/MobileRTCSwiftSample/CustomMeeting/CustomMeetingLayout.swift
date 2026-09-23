//
//  CustomMeetingLayout.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import UIKit

/// Layout constants and helpers shared by the custom in-meeting UI views.
enum CustomMeetingLayout {
    static let thumbButtonHeight: CGFloat = 24
    static let safeZoomInsets: CGFloat = 34

    static var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private static var keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.compactMap { $0 as? UIWindowScene }.first
        return windowScene?.windows.first { $0.isKeyWindow } ?? windowScene?.windows.first
    }

    static var safeAreaTop: CGFloat { keyWindow?.safeAreaInsets.top ?? 0 }
    static var safeAreaBottom: CGFloat { keyWindow?.safeAreaInsets.bottom ?? 0 }

    static var hasHomeIndicator: Bool { safeAreaBottom > 0 }

    static var topHeight: CGFloat { safeAreaTop + 50 }
    static var bottomHeight: CGFloat { hasHomeIndicator ? 94 : 60 }
    static var bottomButtonHeight: CGFloat { hasHomeIndicator ? 60 : bottomHeight }

    static var screenWidth: CGFloat { UIScreen.main.bounds.size.width }
    static var screenHeight: CGFloat { UIScreen.main.bounds.size.height }

    static var isLandscape: Bool {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .interfaceOrientation
            .isLandscape ?? false
    }

    /// Thumb cell size (square): screen width / 4 (portrait) or height / 4 (landscape).
    static var thumbCellSize: CGFloat {
        let bounds = UIScreen.main.bounds
        return isLandscape ? bounds.size.height / 4 : bounds.size.width / 4
    }
}
