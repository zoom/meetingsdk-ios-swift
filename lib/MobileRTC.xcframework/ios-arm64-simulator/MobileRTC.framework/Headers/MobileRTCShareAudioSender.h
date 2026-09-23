/**
 * @file MobileRTCShareAudioSender.h
 * @brief Audio sharing sender for screen share with audio.
 */

#import <Foundation/Foundation.h>
#import <MobileRTC/MobileRTCConstants.h>


/**
 * @class MobileRTCShareAudioSender
 * @brief Sends share audio raw data.
 */
@interface MobileRTCShareAudioSender : NSObject

/**
 * @brief Sends share audio raw data.
 * @param data The audio data address.
 * @param length The audio data length, in even numbers.
 * @param rate The audio data sampling rate.
 * @param channel The channel type. The default is MobileRTCAudioChannel_Mono.
 * @return If the function succeeds, it will return MobileRTCRawDataError_Success. Otherwise return an error.
 * @warning Supported sample rates: Mono: 8000/11025/16000/32000/44100/48000/50000/50400/96000/192000. Stereo: 8000/16000/32000/44100/48000/50000/50400/96000/192000. Channels: mono and stereo. Resolution: little-endian, 16-bit.
 * @note
 * 1. The size of a single input must not exceed the number of bytes corresponding to 100 ms of audio. Exceeding this limit returns MobileRTCRawData_Send_Too_Much_Data_In_Single_Time.
 * 2. Variable-length input is supported; it is recommended to send audio data in 10 ms, 20 ms, or 30 ms chunks (not exceeding 100 ms).
 * 3. If MobileRTCRawData_Send_Too_Frequently is returned, this is not a genuine error; please wait briefly before retrying—for example, sleep for 10 ms before attempting to send the data again.
 */
- (MobileRTCRawDataError)sendShareAudio:(char *)data dataLength:(NSUInteger)length sampleRate:(NSUInteger)rate audioChannel:(MobileRTCAudioChannel)channel;

@end


