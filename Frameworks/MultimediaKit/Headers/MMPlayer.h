#import <AppKit/AppKit.h>
#import <X11/Xlib.h>

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

@end
