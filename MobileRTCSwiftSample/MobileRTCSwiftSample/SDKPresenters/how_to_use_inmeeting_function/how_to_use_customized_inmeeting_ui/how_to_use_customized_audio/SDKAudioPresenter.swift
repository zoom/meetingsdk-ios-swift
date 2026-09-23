//
//  SDKAudioPresenter.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 5/12/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import Foundation
import MobileRTC
import UIKit

/// Audio actions (mute/unmute, switch source, dial in) for the custom in-meeting UI.
final class SDKAudioPresenter: NSObject {

    func muteMyAudio() {
        guard let ms = MobileRTC.shared().getMeetingService() else { return }
        switch ms.myAudioType() {
        case .voIP, .telephony:
            guard ms.canUnmuteMyAudio() else { return }
            ms.muteMyAudio(!ms.isMyAudioMuted())
        case .none:
            guard ms.isSupportedVOIP() else { return }
            presentJoinAudioAlert(ms)
        @unknown default:
            break
        }
    }

    private func presentJoinAudioAlert(_ ms: MobileRTCMeetingService) {
        let alert = UIAlertController(
            title: NSLocalizedString("To hear others\n please join audio", comment: ""),
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Call via Internet", comment: ""), style: .default) { _ in
            MobileRTC.shared().getMeetingService()?.connectMyAudio(true)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Dial in", comment: ""), style: .default) { [weak self] _ in
            self?.dialIn()
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert)
    }

    func dialIn() {
        guard
            let ms = MobileRTC.shared().getMeetingService(),
            let currentCountry = ms.getDialInCurrentCountryCode(),
            let codes = ms.getDialInCallCodes(withCountryId: currentCountry.countryId),
            !codes.isEmpty
        else { return }

        let alert = UIAlertController(title: currentCountry.countryName, message: nil, preferredStyle: .alert)
        for code in codes {
            let suffix = code.tollFree ? " (\(NSLocalizedString("Toll Free", comment: "")))" : ""
            let title = "\(code.countryNumber ?? "")\(suffix)"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                MobileRTC.shared().getMeetingService()?.dial(inCall: code.countryNumber ?? "")
            })
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert)
    }

    @discardableResult
    func switchMyAudioSource() -> MobileRTCAudioError? {
        MobileRTC.shared().getMeetingService()?.switchMyAudioSource()
    }

    func myAudioType() -> MobileRTCAudioType {
        MobileRTC.shared().getMeetingService()?.myAudioType() ?? .none
    }

    @discardableResult
    func connectMyAudio(_ on: Bool) -> Bool {
        MobileRTC.shared().getMeetingService()?.connectMyAudio(on) ?? false
    }

    @discardableResult
    func muteUserAudio(_ mute: Bool, userID: UInt) -> Bool {
        MobileRTC.shared().getMeetingService()?.muteUserAudio(mute, withUID: userID) ?? false
    }

    @discardableResult
    func muteAllUserAudio(allowSelfUnmute: Bool) -> Bool {
        MobileRTC.shared().getMeetingService()?.muteAllUserAudio(allowSelfUnmute) ?? false
    }

    private func present(_ alert: UIAlertController) {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let top = appDelegate.topViewController()
        else { return }
        top.present(alert, animated: true)
    }
}
