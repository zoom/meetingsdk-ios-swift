/**
 * @file MobileRTCAudioRawDataHelper.h
 * @brief Helper utilities for audio raw data processing and management.
 */

#import <Foundation/Foundation.h>
#import "MobileRTCConstants.h"

/**
 * @class MobileRTCAudioRawDataHelper
 * @brief A helper to subscribe or unsubscribe audio raw data.
 */
@interface MobileRTCAudioRawDataHelper : NSObject

/**
 * @brief Initializes MobileRTCAudioRawDataHelper.
 * @param delegate The delegate to receive the callback.
 * @return The MobileRTCAudioRawDataHelper object.
 */
- (instancetype _Nonnull)initWithDelegate:(id<MobileRTCAudioRawDataDelegate>_Nonnull) delegate;

/**
 * @brief Starts audio raw data for CurrentSession.
 * @return If the function succeeds, it will return MobileRTCRawDataError_Success. Otherwise return an error.
 */
-(MobileRTCRawDataError)subscribe;

/**
 * @brief Starts audio raw data from one source.
 * @param sources CurrentSession or MainSession (webinar backstage only).
 */
-(MobileRTCRawDataError)subscribe:(MobileRTCSessionSource)sources;

/**
 * @brief Stops CurrentSession audio raw data.
 * @return If the function succeeds, it will return MobileRTCRawDataError_Success. Otherwise return an error.
 */
- (MobileRTCRawDataError)unSubscribe;

/**
 * @brief Stop receiving raw audio data for one source.
 */
- (MobileRTCRawDataError)unSubscribe:(MobileRTCSessionSource)sources;

@end
