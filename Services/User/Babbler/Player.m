#import "Player.h"
#import <X11/Xlib.h>
#import <GNUstepGUI/GSDisplayServer.h>

@implementation Player

- (void) resizeVideo: (NSSize) size
{
  int delta_x, delta_y;
  delta_x = size.width-contentSize.width;
  delta_y = size.height-contentSize.height;
  NSSize c = [[self contentView] bounds].size;
  c.width += delta_x;
  c.height += delta_y;
  if (c.width < 200) {
    c.width = 200;
  }
  [self setContentSize: c];
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

- (void) backwardAction: (id) sender
{
  NSLog(@"Backward");
}

- (void) playAction: (id) sender
{
  if (isPlaying == NO) {
    NSLog(@"play");
    isPlaying = YES;
    [mmPlayer play: self];
    [playButton setImage: [NSImage imageNamed: @"pause.tiff"]];
  } else {
    NSLog(@"pause");
    isPlaying = NO;
    [mmPlayer pause: self];
    [playButton setImage: [NSImage imageNamed: @"play.tiff"]];
  }
}

- (void) forwardAction: (id) sender
{
  NSLog(@"Forward");
}

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
                    screen: (NSScreen*) aScreen
{
  self = [super initWithContentRect: contentRect
	        styleMask: aStyle
		backing: bufferingType
		defer: NO // Always NO to have x window created now
		screen: aScreen];

  [self setDelegate: self];

  /** NSWindow **/
  NSRect frame = contentRect;

  frame = NSMakeRect(5, 5, 70, 20);
  backwardButton = [[NSButton alloc] initWithFrame: frame];
  [backwardButton setImage: [NSImage imageNamed: @"seek_back.tiff"]];
  [backwardButton setAutoresizingMask: NSViewMaxXMargin|NSViewMaxYMargin];
  [backwardButton setTarget: self];
  [backwardButton setAction: @selector(backwardAction:)];
  [[self contentView] addSubview: backwardButton];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  playButton = [[NSButton alloc] initWithFrame: frame];
  [playButton setImage: [NSImage imageNamed: @"play.tiff"]];
  [playButton setAutoresizingMask: NSViewMaxXMargin|NSViewMaxYMargin];
  [playButton setTarget: self];
  [playButton setAction: @selector(playAction:)];
  [[self contentView] addSubview: playButton];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  forwardButton = [[NSButton alloc] initWithFrame: frame];
  [forwardButton setImage: [NSImage imageNamed: @"seek_fwd.tiff"]];
  [forwardButton setAutoresizingMask: NSViewMaxXMargin|NSViewMaxYMargin];
  [forwardButton setTarget: self];
  [forwardButton  setAction: @selector(forwardAction:)];
  [[self contentView] addSubview: forwardButton];

  /* Calculate frame for xwindow.
   * Note. In X window, origin is at top-left corner. */
  int x, y, w, h;
  x = 5;
  y = 5;
  w = contentRect.size.width-5*2;
  h = contentRect.size.height-NSMaxY(frame)-5*2;
  Window xwin = [self xwindow];
  contentView = XCreateSimpleWindow(dpy, xwin, x, y, w, h, 0, 0, 0);
  contentSize = NSMakeSize(w, h);
  XMapWindow(dpy, contentView);

  isPlaying = NO;

  return self;
}

- (void) setPlayer: (id <MMPlayer>) player
{
  ASSIGN(mmPlayer, player);
  [mmPlayer setXWindow: contentView];
  [self resizeVideo: [mmPlayer size]];
}

- (id <MMPlayer>) player
{
  return mmPlayer;
}

@end

