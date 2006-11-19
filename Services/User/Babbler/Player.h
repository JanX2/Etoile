#import <AppKit/AppKit.h>
#import <XWindowServerKit/XWindow.h>
#import <MultimediaKit/MMPlayer.h>

@interface Player: XWindow
{
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

/* Toggle play/pause */
- (void) playAction: (id) sender;


@end
