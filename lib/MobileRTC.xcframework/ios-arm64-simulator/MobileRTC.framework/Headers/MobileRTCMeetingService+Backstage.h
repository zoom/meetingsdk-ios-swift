/**
 * @file MobileRTCMeetingService+Backstage.h
 * @brief Meeting+Backstage service functionality and management.
 */

#import <MobileRTC/MobileRTC.h>

/**
 * @brief Interface for webinar backstage.
 */
@interface MobileRTCMeetingService (Backstage)

/**
 * @brief Determines if the backstage feature is enabled for the current webinar.
 * @return YES if the backstage feature is enabled. Otherwise NO.
 */
- (BOOL)isBackstageEnabled;

/**
 * @brief Determines if the local user can enter the backstage.
 * @return YES if the local user can enter the backstage. Otherwise NO.
 * @note Returns NO when the local user is a panelist and the host does not allow
 * panelists to switch between the main session and the backstage on their own.
 */
- (BOOL)canJoinBackstage;

/**
 * @brief Makes the local user enter the backstage.
 * @return If the function succeeds, the return value is MobileRTCSDKError_Success. Otherwise, this function returns an error.
 * @note If the function succeeds, the user will receive the
 * onMeetingStateChange callback event with MobileRTCMeetingState_JoinBackstage.
 */
- (MobileRTCSDKError)joinBackstage;

/**
 * @brief Determines if the local user can leave the backstage.
 * @return YES if the local user can leave the backstage. Otherwise NO.
 */
- (BOOL)canLeaveBackstage;

/**
 * @brief Makes the local user leave the backstage and return to the main session.
 * @return If the function succeeds, the return value is MobileRTCSDKError_Success. Otherwise, this function returns an error.
 * @note If the function succeeds, the user will receive the
 * onMeetingStateChange callback event with MobileRTCMeetingState_LeaveBackstage. The switch
 * takes effect immediately; the SDK does not apply the countdown used by the Zoom client.
 */
- (MobileRTCSDKError)leaveBackstage;

/**
 * @brief Determines if the specified user can be moved into the backstage.
 * @param userID Specify the user ID to check.
 * @return YES if the user can be moved into the backstage. Otherwise NO.
 * @warning Only meeting host or co-host can run the function.
 */
- (BOOL)canMoveUserToBackstage:(NSUInteger)userID;

/**
 * @brief Moves the specified users into the backstage.
 * @param userIDs Specify the array of user IDs to move. Each element should be an NSNumber containing NSUInteger.
 * @return If the function succeeds, the return value is MobileRTCSDKError_Success. Otherwise, this function returns an error.
 * @warning Only meeting host or co-host can run the function.
 * @note The return value only indicates that the request was sent. Track the per-user
 * outcome through onSinkMeetingUserJoin and onSinkMeetingUserLeft.
 */
- (MobileRTCSDKError)moveUsersToBackstage:(NSArray<NSNumber *> *)userIDs;

/**
 * @brief Determines if the specified user can be moved back to the main session.
 * @param userID Specify the user ID to check.
 * @return YES if the user can be moved back to the main session. Otherwise NO.
 * @warning Only meeting host or co-host can run the function.
 * @note Valid whether or not the local user is currently in the backstage.
 */
- (BOOL)canMoveUserToMainSession:(NSUInteger)userID;

/**
 * @brief Moves the specified users from the backstage back to the main session.
 * @param userIDs Specify the array of user IDs to move. Each element should be an NSNumber containing NSUInteger.
 * @return If the function succeeds, the return value is MobileRTCSDKError_Success. Otherwise, this function returns an error.
 * @warning Only meeting host or co-host can run the function.
 */
- (MobileRTCSDKError)moveUsersToMainSession:(NSArray<NSNumber *> *)userIDs;

/**
 * @brief Determines whether the local user can unmute the local playback of the main session audio.
 * @return YES if the local user can unmute the main session audio. Otherwise, NO.
 */
- (BOOL)canUnMuteMainSessionAudio;

/**
 * @brief Mutes the local playback of the main session audio while in the backstage.
 * @return If the function succeeds, it returns MobileRTCSDKError_Success. Otherwise, this function returns an error.
 */
- (MobileRTCSDKError)muteMainSessionAudio;

/**
 * @brief Unmutes the local playback of the main session audio while in the backstage.
 * @return If the function succeeds, it returns MobileRTCSDKError_Success. Otherwise, this function returns an error.
 */
- (MobileRTCSDKError)unMuteMainSessionAudio;

/**
 * @brief Determines whether the local playback of the main session audio is muted.
 * @return YES if the main session audio is muted. Otherwise, NO.
 */
- (BOOL)isMainSessionAudioMuted;

@end
