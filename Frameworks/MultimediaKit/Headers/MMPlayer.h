#import <AppKit/AppKit.h>
#import <X11/Xlib.h>

extern NSString *const MMPlayerStartPlayingNotification;
extern NSString *const MMPlayerPausedNotification;
extern NSString *const MMPlayerStopNotification;
extern NSString *const MMPlayerInformationAvailableNotification;

@protocol MMPlayer <NSObject>

/* Play and pause. Applications are responsible to keep tracking
 * the status of play or pause.
 * Different implementation may have different behaviors
 * if played or paused twice. */
- (void) play: (id) sender;
- (void) pause: (id) sender;

/* This may block runloop until it completely stops.
 * After that, applications are safe to terminate */
- (void) stop: (id) sender; 

- (void) setURL: (NSURL *) url;
- (NSURL *) url;

/* For some implementation , suppy the xwindow to play video on it */
- (void) setXWindow: (Window) win;

/* Size of video. 
 * Some implementation does not support it during playback.
 */
- (NSSize) size;

/* Volume.
 * This is the software volume, not the hardward volume.
 * It ranges from 0 - 100, or in percentage.
 * Each backend has to convert this range into what in its system.
 */
- (void) setVolumeInPercentage: (unsigned int) volume;
- (unsigned int) volumeInPercentage;

@end
