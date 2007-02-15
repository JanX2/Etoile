#import <AppKit/AppKit.h>
#import <X11/Xlib.h>

extern NSString *const MMPlayerStartPlayingNotification;
extern NSString *const MMPlayerPausedNotification;
extern NSString *const MMPlayerStopNotification;
extern NSString *const MMPlayerInformationAvailableNotification;

@protocol MMPlayer <NSObject>

// -------------------------------------------------------------
//    player status
// -------------------------------------------------------------

/**
 * Starts the playback at the current position. Applications are
 * responsible to track the status of play and pause themselves.
 * The behaviour when calling play: twice is undefined.
 *
 * See -pause:
 */
- (void) play: (id) sender;

/**
 * Pauses the playback at the current position. Applications are
 * responsible to track the status of play and pause themselves.
 * The behaviour when calling pause: twice is undefined.
 *
 * See -play:
 */
- (void) pause: (id) sender;

/**
 * Stops the playback. This method blocks until playback is
 * completely stopped. Call this method before terminating the
 * application.
 */
- (void) stop: (id) sender; 


// -------------------------------------------------------------
//    media source accessor methods
// -------------------------------------------------------------

- (void) setURL: (NSURL *) url;
- (NSURL *) url;

/**
 * Sets the X11 window to be used for video display.
 */
- (void) setXWindow: (Window) win;



// -------------------------------------------------------------
//    static playback properties
// -------------------------------------------------------------

/**
 * Returns the size of the video file being played. If no video file
 * is loaded or the backend doesn't support video output, a size of
 * 0x0 is returned.
 */
- (NSSize) size;

// -------------------------------------------------------------
//    dynamic playback properties
// -------------------------------------------------------------

/**
 * Returns the player's position in the media file. The return
 * value is given as a float number in seconds.
 */
- (float) position;

/**
 * Sets the player's position in the media file. The position
 * is a float value in seconds.
 */
- (void) setPosition: (float) aPosition;


// -------------------------------------------------------------
//    volume accessor methods
// -------------------------------------------------------------

/**
 * Accessor methods for the volume. The volume is represented
 * as an unsigned integer value between 0 (no sound) and 100 (loudest).
 */
- (void) setVolumeInPercentage: (unsigned int) volume;
- (unsigned int) volumeInPercentage;

@end

