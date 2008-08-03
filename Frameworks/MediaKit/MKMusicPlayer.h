#import <Foundation/NSArray.h>
#import "MKSoundDevice.h"
#import <EtoileThread/NSObject+Threaded.h>

@class MKMediaFile;
/**
 * MKMusicPlayer maintains a queue of files to play.
 */
@interface MKMusicPlayer : NSObject <Idle> {
	id<MKSoundDevice> speaker;
	MKMediaFile *file;
	NSMutableArray *files;
	int16_t *buffer;
	size_t bufferSpace;
	BOOL playing;
}
/**
 * Initialise with the specified output device.
 */
- (id) initWithDevice:(id<MKSoundDevice>)device;
/**
 * Initialise with the default output device.
 */
- (id) initWithDefaultDevice;
/**
 * Begin playing the current file.
 */
- (void) play;
/**
 * Pause playback.
 */
- (void) pause;
/**
 * Stop playing and empty the queue.
 */
- (void) stop;
/**
 * Skip to the next file.  To get to the previous file, you must stop and
 * recreate the queue.
 */
- (void) next;
/**
 * Returns the position in the current file in milliseconds.
 */
- (int64_t) currentPosition;
/**
 * Seeks a specified number of milliseconds into the currently-playing file.
 */
- (void) seekTo:(int64_t)milliseconds;
/**
 * Returns the duration of the current file.
 */
- (int64_t) duration;
/**
 * Returns whether the file is playing.
 */
- (BOOL) isPlaying;
/**
 * Returns the currently-playing URL.
 */
- (NSURL*) currentURL;
/**
 * Add the specified file to the queue.
 */
- (void) addURL:(NSURL*)aURL;
/**
 * Replace the queue with the specified array of NSURLs.
 * Pass a NSArray, not a NSMutableArray.
 */
- (void) setQueue:(NSArray*)queue;
/**
 * Returns the current volume, in the range 0 to 100.
 */
- (int) volume;
/**
 * Sets the current volume to a value from 0 to 100.
 */
- (void) setVolume:(int)aVolume;
/**
 * Returns the number of songs currently in the queue.
 */
- (int) queueSize;
@end
