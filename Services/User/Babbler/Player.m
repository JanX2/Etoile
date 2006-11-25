#import "Player.h"
#import <X11/Xlib.h>
#import <GNUstepGUI/GSDisplayServer.h>

@implementation Player

- (void) resizeVideo: (NSSize) size
{
  int delta_x, delta_y;
  delta_x = size.width-contentSize.width;
  delta_y = size.height-contentSize.height;
  NSSize c = [[window contentView] bounds].size;
  c.width += delta_x;
  c.height += delta_y;
  if (c.width < 350) {
    c.width = 350;
  }
  [window setContentSize: c];
  if (size.height > 0) {
    XResizeWindow(dpy, contentView, size.width, size.height);
  } else {
    /* XWindow cannot be smaller than 1x1 */
    XResizeWindow(dpy, contentView, 1, 1);
  }
}

- (void) windowWillClose: (NSNotification *) not
{
  if (isPlaying == YES) {
    [mmPlayer stop: self];
  }
}

- (void) volume: (id) sender
{
  [mmPlayer setVolumeInPercentage: [volumeSlider intValue]];
}

- (void) backwardAction: (id) sender
{
  NSLog(@"Backward");
}

- (void) play: (id) sender
{
  if (isPlaying == NO) {
//    NSLog(@"play");
    isPlaying = YES;
    [mmPlayer play: self];
    [playButton setImage: [NSImage imageNamed: @"pause.tiff"]];
  } else {
//    NSLog(@"pause");
    isPlaying = NO;
    [mmPlayer pause: self];
    [playButton setImage: [NSImage imageNamed: @"play.tiff"]];
  }
}

- (void) forwardAction: (id) sender
{
  NSLog(@"Forward");
}

- (id) init
{
  self = [super init];
  if ([NSBundle loadNibNamed: @"Player" owner: self] == NO) {
    [self dealloc];
    return nil;
  }
  return self;
}

- (void) awakeFromNib
{
  dpy = [GSCurrentServer() serverDevice];

  /* Calculate frame for xwindow.
   * Note. In X window, origin is at top-left corner. */
  int x, y, w, h;
  x = 5;
  y = 5;
  w = [[window contentView] bounds].size.width-10;
  h = 1;
  Window xwin = [window xwindow];
  contentView = XCreateSimpleWindow(dpy, xwin, x, y, w, h, 0, 0, 0);
  contentSize = NSMakeSize(w, h);
  XMapWindow(dpy, contentView);

  isPlaying = NO;

  [playButton setImage: [NSImage imageNamed: @"play.tiff"]];
  [volumeSlider setMaxValue: 100];
  [volumeSlider setMinValue: 0];

  [window makeKeyAndOrderFront: self];
}

- (void) setPlayer: (id <MMPlayer>) player
{
  ASSIGN(mmPlayer, player);
  [mmPlayer setXWindow: contentView];
  [self resizeVideo: [mmPlayer size]];
  [volumeSlider setIntValue: [mmPlayer volumeInPercentage]];

  [[NSNotificationCenter defaultCenter]
                addObserver: self
                selector: @selector(informationAvailable:)
                name: MMPlayerInformationAvailableNotification
                object: mmPlayer];
}

- (id <MMPlayer>) player
{
  return mmPlayer;
}

- (XWindow *) window
{
  return window;
}

/* Notification */
- (void) informationAvailable: (NSNotification *) not
{
  [self resizeVideo: [mmPlayer size]];
}

@end

