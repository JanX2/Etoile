#import <AppKit/AppKit.h>
#import <gst/gst.h>
#import <XWindowServerKit/XWindow.h>

@interface Player: XWindow
{
  NSURL *url;
  NSButton *reverseButton;
  NSButton *forwardButton;
  NSButton *playButton;
  BOOL isPlaying;

  GstElement *play;
  GstBus *bus;
}

- (void) setURL: (NSURL *) url;
- (NSURL*) url;

@end
