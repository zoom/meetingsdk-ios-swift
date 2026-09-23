/**
 * @file MobileRTCAudioSender.h
 * @brief Audio sender functionality for custom audio input.
 */

#import <Foundation/Foundation.h>

/**
 * @class MobileRTCAudioSender
 * @brief Sends external raw audio data to the Zoom meeting.
 */
@interface MobileRTCAudioSender : NSObject

/**
 * @brief Sends audio raw data. Channel number must be mono, and sampling bits must be 16.
 * @param data The address of audio data.
 * @param length The length of audio data (it must be an even number).
 * @param rate The sample rate of audio data (8000/11025/32000/44100/48000/50000/50400/96000/192000/2822400).
 * @return If the function succeeds, it will return MobileRTCRawDataError_Success. Otherwise return an error.
 * @note
 * 1. The size of a single input must not exceed the number of bytes corresponding to 100 ms of audio. Exceeding this limit returns MobileRTCRawData_Send_Too_Much_Data_In_Single_Time.
 * 2. Variable-length input is supported; it is recommended to send audio data in 10 ms, 20 ms, or 30 ms chunks (not exceeding 100 ms).
 * 3. If MobileRTCRawData_Send_Too_Frequently is returned, this is not a genuine error; please wait briefly before retrying—for example, sleep for 10 ms before attempting to send the data again.
 */
- (MobileRTCRawDataError)send:(char*)data dataLength:(unsigned int)length sampleRate:(int)rate;

@end

