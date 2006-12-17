#import <XWindowServerKit/XWindow.h>
#import "AZBackground.h"

static AZBackground *sharedInstance;

@interface AZView: NSView
{
  NSImage *image;
  NSAttributedString *string;
}

@end

@implementation AZView

- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  image = [NSImage imageNamed: @"GNUstep"];
  string = [[NSAttributedString alloc] initWithString: @"GNUstep"];
  return self;
}

- (void) dealloc
{
  DESTROY(string);
  [super dealloc];
}

- (void) drawRect: (NSRect) frame
{
  [self lockFocus];
  [[NSColor darkGrayColor] set];
  NSRectFill(frame);

  [image compositeToPoint: NSMakePoint(200, 200) 
                operation: NSCompositeSourceOver];
  [string drawAtPoint: NSMakePoint(200, 170)];
  [self unlockFocus];
}

@end

@implementation AZBackground

- (void) applicationWillFinishLaunching:(NSNotification *) not
{
  server = GSCurrentServer();
  dpy = (Display*)[server serverDevice];
  screen = [[NSScreen mainScreen] screenNumber];
  root_win = RootWindow(dpy, screen);
}

- (void) applicationDidFinishLaunching:(NSNotification *) not
{
  /* Setup drawable window */
  XWindow *win = [[XWindow alloc] initWithWindowRef: &root_win];
  AZView *view = [[AZView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  [win setContentView: view];

  [win skipTaskbarAndPager];
  [win makeKeyAndOrderFront: self];
  [win display]; /* Necessary to have content view draw */

}

+ (AZBackground  *) background 
{
  if (sharedInstance == nil)
    sharedInstance = [[AZBackground alloc] init];
  return sharedInstance;
}

@end

