#import "AZApplication.h"
#import "openbox.h"
#import "AZMainLoop.h"

#include <X11/cursorfont.h>
#if USE_XCURSOR
#include <X11/Xcursor/Xcursor.h>
#endif

static KeyCode   keys[OB_NUM_KEYS];

static Cursor cursors[OB_NUM_CURSORS];
static Cursor load_cursor(const char *name, unsigned int fontval);

static AZApplication *sharedInstance;

@implementation AZApplication

- (void)receivedEvent:(void *)data
                 type:(RunLoopEventType)type
	        extra:(void *)extra
	      forMode:(NSString *)mode
{
  [mainLoop mainLoopRun];
  if ([mainLoop run] == NO)
  {
    [NSApp stop: self];
    return;
  }
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
#ifdef ALTERNATIVE_RUN_LOOP
  /* Listen event */
  NSRunLoop     *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(ob_display);

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
            type: ET_RDESC
         watcher: (id<RunLoopEvents>)self
         forMode: NSDefaultRunLoopMode];

  mainLoop = [AZMainLoop mainLoop];
#endif
}

+ (AZApplication *) sharedApplication
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZApplication alloc] init];
  }
  return sharedInstance;
}

- (void) createAvailableCursors
{
	cursors[OB_CURSOR_NONE] = None;
	cursors[OB_CURSOR_POINTER] = load_cursor("left_ptr", XC_left_ptr);
	cursors[OB_CURSOR_BUSY] = load_cursor("left_ptr_watch", XC_watch);
	cursors[OB_CURSOR_MOVE] = load_cursor("fleur", XC_fleur);
	cursors[OB_CURSOR_NORTH] = load_cursor("top_side", XC_top_side);
	cursors[OB_CURSOR_NORTHEAST] = load_cursor("top_right_corner",
		XC_top_right_corner);
	cursors[OB_CURSOR_EAST] = load_cursor("right_side", XC_right_side);
	cursors[OB_CURSOR_SOUTHEAST] = load_cursor("bottom_right_corner",
		XC_bottom_right_corner);
	cursors[OB_CURSOR_SOUTH] = load_cursor("bottom_side", XC_bottom_side);
	cursors[OB_CURSOR_SOUTHWEST] = load_cursor("bottom_left_corner",
		XC_bottom_left_corner);
	cursors[OB_CURSOR_WEST] = load_cursor("left_side", XC_left_side);
	cursors[OB_CURSOR_NORTHWEST] = load_cursor("top_left_corner",
		XC_top_left_corner);
}

- (void) createAvailableKeycodes
{
	keys[OB_KEY_RETURN] =
		XKeysymToKeycode(ob_display, XStringToKeysym("Return"));
	keys[OB_KEY_ESCAPE] =
		XKeysymToKeycode(ob_display, XStringToKeysym("Escape"));
	keys[OB_KEY_LEFT] =
		XKeysymToKeycode(ob_display, XStringToKeysym("Left"));
	keys[OB_KEY_RIGHT] =
		XKeysymToKeycode(ob_display, XStringToKeysym("Right"));
	keys[OB_KEY_UP] =
		XKeysymToKeycode(ob_display, XStringToKeysym("Up"));
	keys[OB_KEY_DOWN] =
		XKeysymToKeycode(ob_display, XStringToKeysym("Down"));
}

@end

/* OpenBox cursor, keycode API */

static Cursor load_cursor(const char *name, unsigned int fontval)
{
	Cursor c = None;
	
#if USE_XCURSOR
	c = XcursorLibraryLoadCursor(ob_display, name);
#endif
	if (c == None)
		c = XCreateFontCursor(ob_display, fontval);

	return c;
}

// FIXME: This function isn't used here but in AZScreen and AZFrame, move it 
// elsewhere or rework the Azalea cursor (or AZApplication) API.
Cursor ob_cursor(ObCursor cursor)
{
	if (cursor >= OB_NUM_CURSORS)
	{
		NSLog(@"Warning: cursor out of range");
		return OB_CURSOR_POINTER;
	}
	
	return cursors[cursor];
}

// FIXME: This function isn't used here but in AZKeyboardHandler and 
// AZMoveResizeHandler, move it elsewhere or rework the API.
KeyCode ob_keycode(ObKey key)
{
	// FIXME: We should return a default key or something like none key rather 
	// than accessing the keys array beyond bounds after logging this warnings.
	if (key >= OB_NUM_KEYS)
		NSLog(@"Warning: key out of range");

	return keys[key];
}
