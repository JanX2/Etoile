#import <AppKit/AppKit.h>
#import <XWindowServerKit/XWindow.h>
#import <MultimediaKit/MMPlayer.h>

@interface Player: NSObject
{
  Display *dpy;
  XWindow *window;
  NSButton *backwardButton;
  NSButton *forwardButton;
  NSButton *playButton;
  NSSlider *volumeSlider;
  BOOL isPlaying;

  id <MMPlayer> mmPlayer;
  Window contentView;
  NSSize contentSize;
}

/* Retained */
- (void) setPlayer: (id <MMPlayer>) player;
- (id <MMPlayer>) player;
- (XWindow *) window;

/* Toggle play/pause */
- (void) play: (id) sender;
- (void) volume: (id) sender;


@end
