#include "AZDockApp.h"
#include "AZDockView.h"
#include <XWindowServerKit/XFunctions.h>
#include <X11/Xutil.h>

@implementation AZDockApp 

- (void) mouseDown: (NSEvent *) event
{
  switch(type) {
    case AZDockGNUstepApplication:
      {
        [[NSWorkspace sharedWorkspace] launchApplication: wm_instance];
	    NSLog(@"GNUstep %@", wm_instance);
	    break;
      }
    case AZDockXWindowApplication:
      {
        /* Go through all windows and raise them */
        Display *dpy = (Display *)[GSCurrentServer() serverDevice];
        int i;
        Window w;
        for (i = 0; i < [xwindows count]; i++) {
          w = [[xwindows objectAtIndex: i] unsignedLongValue];
          unsigned long state = XWindowState(w);
          if (state == -1) {
          } else if (state == IconicState) {
            /* Iconified */
            XMapWindow(dpy, w);
          } else {
            XRaiseWindow(dpy, w);
	  }
        }
        /* Focus on the last one */
        XSetInputFocus(dpy, w, RevertToNone, CurrentTime);
      }
      break;
  }
}

- (id) initWithXWindow: (Window) w
{
  self = [super init];
  xwindows = [[NSMutableArray alloc] init];
  [xwindows addObject: [NSNumber numberWithUnsignedLong: w]];
  mainXWindow = w;

  NSRect rect = NSMakeRect(0, 0, 64, 64);
  view = [[AZDockView alloc] initWithFrame: rect];
  [view setDelegate: self];
  window = [[XWindow alloc] initWithContentRect: rect
                            styleMask: NSBorderlessWindowMask
			    backing: NSBackingStoreRetained
			    defer: NO];
  [window setDesktop: ALL_DESKTOP];
  [window skipTaskbarAndPager];
  [window setContentView: view];


  /* Get class and instance */
  if (XWindowClassHint(w, &wm_class, &wm_instance)) {
    RETAIN(wm_class);
    RETAIN(wm_instance);
  } 

  if ([wm_class isEqualToString: @"GNUstep"]) {
    type = AZDockGNUstepApplication;
  } else {
    type = AZDockXWindowApplication;
  }

  /* Try to get the icon */
  if (type == AZDockGNUstepApplication)
  {
	/* we try to get the application path */
	NSString* appPath = [[NSWorkspace sharedWorkspace]
		fullPathForApplication: wm_instance];
	if (appPath)
	{
		icon = [[NSWorkspace sharedWorkspace]
			iconForFile: appPath];
	}
  }
  else
  {
  	icon = XWindowIcon(w);
  }

  if (!icon)
  {
	/* use default icon */
	icon = [NSImage imageNamed: @"Unknown.tiff"];
  }
 if (icon)
    [view setImage: icon];


  [window orderFront: self];

  return self;
}

- (BOOL) acceptXWindow: (Window) win
{
  int i;
  unsigned long w;
  NSString *_class, *_instance;
  for (i = 0; i < [xwindows count]; i++)
  {
    w = [[xwindows objectAtIndex: i] unsignedLongValue];
    if (w == win)
      return YES;
  }
  if (XWindowClassHint(win, &_class, &_instance)) {
    if ([_class isEqualToString: wm_class] &&
	[_instance isEqualToString: wm_instance])
      {
        [xwindows addObject: [NSNumber numberWithUnsignedLong: win]];
	return YES;
      }
  }
  return NO;
}

- (BOOL) removeXWindow: (Window) win
{
  int i;
  unsigned long w;
  for (i = 0; i < [xwindows count]; i++)
  {
    w = [[xwindows objectAtIndex: i] unsignedLongValue];
    if (w == win) {
      [xwindows removeObjectAtIndex: i];
      return YES;
    }
  }
  return NO;
}

- (void) dealloc
{
  DESTROY(xwindows);
  DESTROY(wm_class);
  DESTROY(wm_instance);
  if (window) {
    [window close];
    DESTROY(window);
  }
  [self dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@", xwindows];
}

- (unsigned int) numberOfXWindows
{
  return [xwindows count];
}

- (XWindow *) window
{
  return window;
}

- (AZDockType) type
{
  return type;
}

@end
