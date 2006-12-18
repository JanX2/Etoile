#import <XWindowServerKit/XWindow.h>
#import "AZBackground.h"

static AZBackground *sharedInstance;

@interface AZView: NSView
{
  NSImage *image;
  NSAttributedString *string;
}

- (void) setImage: (NSImage *) image;

@end

@implementation AZView

- (void) setImage: (NSImage *) i
{
  ASSIGN(image, i);
}

- (id) initWithFrame: (NSRect) rect
{
  self = [super initWithFrame: rect];
  return self;
}

- (void) dealloc
{
  DESTROY(image);
  [super dealloc];
}

- (void) drawRect: (NSRect) frame
{
  [[NSColor darkGrayColor] set];
  NSRectFill(frame);

  if (image) {
    [image compositeToPoint: NSZeroPoint
                    operation: NSCompositeSourceOver];
  } 
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
  NSScreen *scr = [NSScreen mainScreen];
  XWindow *win = [[XWindow alloc] initWithWindowRef: &root_win];
  AZView *view = [[AZView alloc] initWithFrame: [scr frame]];
  [win setContentView: view];

  NSFileManager *fm = [NSFileManager defaultManager];
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  NSArray *args = [pi arguments];
  if ([args count] > 1) {
    NSString *path = [args objectAtIndex: 1];
    if ([fm fileExistsAtPath: [path stringByStandardizingPath]]) {
      NSImage *im = [[NSImage alloc] initWithContentsOfFile: path];
      [view setImage: AUTORELEASE(im)];
    }
  }

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

