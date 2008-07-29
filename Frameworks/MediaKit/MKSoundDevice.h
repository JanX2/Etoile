#import <Foundation/NSObject.h>

@protocol MKSoundDevice <NSObject>
/**
 * Initialises a device for input (i.e. as a microphone / line in).
 */
- (id) initForInput;
/**
 * Initialises a device for output (i.e. as a speaker / headphone).
 */
- (id) initForOutput;
/**
 * Records a sample from an input device.  Returns true if the read succeeded.
 */
- (BOOL) recordSample:(void*)bytes count:(int)count;
/**
 * Plays a sample in an output device.
 */
- (BOOL) playSample:(void*)bytes count:(int)count;
/**
 * Sets the current sample format.  See the OSS documentation for valid formats.
 *
 * Note that this should be called before any calls setting the number of
 * channels or the sample rate.
 */
- (int) setFormat:(int) format;
/**
 * Sets the number of channels to use on this device.
 *
 * Note that this must be called before any calls setting the sampling rate and
 * after any setting the sample format.
 */
- (int) setChannels:(int) channels;
/**
 * Sets the sampling rate in Hertz.
 */
- (int) setRate:(int)rate;
/**
 * Sets the volume for the left and right channels.  Valid values are from 0 to
 * 100.  Behaviour on other values is undefined.
 */
- (BOOL) setVolumeLeft:(int)left right:(int)right;
/**
 * Returns be volume of the left channel.
 */
- (int) leftVolume;
/**
 * Returns the volume of the right channel.
 */
- (int) rightVolume;
/**
 * Returns the current format.
 */
- (int) format;
/**
 * Synchronises this thread with device state.   Blocks until all data sent to
 * the device has really been played.
 */
- (void) sync;
/**
 * Resets the device.  The sample format, rate, and number of channels will
 * return to their defaults and can once again be set.
 */
- (void) reset;
@end

@interface SoundService : NSObject
/**
 * Returns the default sound device for this platform.
 */
+ (Class) defaultAudioDevice;
@end
