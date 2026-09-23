//
//  SDKStartJoinMeetingPresenter+EmojieReaction.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.


import MobileRTC
import os

extension SDKStartJoinMeetingPresenter {
    func onEmojiReactionReceived(_ userId: UInt, reactionType type: MobileRTCEmojiReactionType, reactionSkinTone skinTone: MobileRTCEmojiReactionSkinTone) {
        Logger.info("onEmojiReactionReceived userID=\(userId) type=\(type.rawValue) skinTone=\(skinTone.rawValue)")
    }

    func onEmojiReactionReceivedInWebinar(_ type: MobileRTCEmojiReactionType) {
        Logger.info("onEmojiReactionReceivedInWebinar type=\(type.rawValue)")
    }

    func onEmojiFeedbackReceived(_ userId: UInt, feedbackType type: MobileRTCEmojiFeedbackType) {
        Logger.info("onEmojiFeedbackReceived userID=\(userId) type=\(type.rawValue)")
    }

    func onEmojiFeedbackCanceled(_ userId: UInt) {
        Logger.info("onEmojiFeedbackCanceled userID=\(userId)")
    }
}
