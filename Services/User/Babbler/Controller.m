#import "Controller.h"
#import "Player.h"
#import <gdk/gdkx.h>

int gs_event_id;
gboolean gs_event_func(gpointer data);

@interface NSApplication (GMainLoop)
- (void) runOnce;
@end

@implementation Controller
/** Private **/
- (void) runGMainLoop: (id) sender
{
  g_main_loop_run(gloop);
}

- (void) newPlayer: (NSURL *) url
{
  NSRect frame = NSMakeRect(300, 500, 400, 100);
  Player *player = [[Player alloc] initWithContentRect: frame
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask
		            backing: NSBackingStoreRetained
			          defer: NO];
  [player setURL: url];
  [player makeKeyAndOrderFront: self];
}

/** End of Private **/

- (void) openAction: (id) sender
{
  /* Must quit the gloop before modal.
   * And must use timer to restart gloop after modal.
   */
  g_main_loop_quit(gloop);
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  int result = [panel runModalForTypes: nil];
  if (result == NSOKButton) {
    NSArray *urls = [panel URLs];
    [self newPlayer: [urls objectAtIndex: 0]];
  }
  [NSApp runOnce];
  [NSTimer scheduledTimerWithTimeInterval: 1
	  target: self
	  selector: @selector(runGMainLoop:)
	  userInfo: nil
	  repeats: NO];
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  GDK_THREADS_LEAVE();
  gloop = g_main_loop_new(NULL, TRUE);
  gcontext = g_main_loop_get_context(gloop);
  gs_event_id = g_timeout_add(100, gs_event_func, self); /* Call every 0.1 second */

  /* Make menu */
  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle: @"Open file..."
	  action: @selector(openAction:)
	  keyEquivalent: @"o"];
  [menu addItemWithTitle: @"Hide"
	  action: @selector(hide:)
	  keyEquivalent: @"h"];
  [menu addItemWithTitle: @"Quit"
	  action: @selector(terminate:)
	  keyEquivalent: @"q"];
  [NSApp setMainMenu: AUTORELEASE(menu)];
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  NSArray *args = [[NSProcessInfo processInfo] arguments];
  if ([args count] > 1) {
    NSURL *url = [NSURL URLWithString: [args objectAtIndex: 1]];
    [self newPlayer: url];
  }
  g_main_loop_run(gloop);
}

- (void) applicationWillTerminate: (NSNotification *) not
{
  GDK_THREADS_ENTER();
  gdk_flush();
}

@end

gboolean gs_event_func(gpointer data)
{
  [NSApp runOnce];
  return TRUE;
}

@implementation NSApplication (GMainLoop)

/* Better to call XFlush(dpy) before this */
- (void) runOnce
{
//  NSLog(@"runOnce");
  NSEvent *e = [NSApp nextEventMatchingMask: NSAnyEventMask
                                  untilDate: [NSDate distantPast]
                                     inMode: NSDefaultRunLoopMode
                                    dequeue: YES];

  /* FIXME: should also check null event (see [NSApplication -run]) */
  while(e)
  {
    [NSApp sendEvent: e];
    e = [NSApp nextEventMatchingMask: NSAnyEventMask
                           untilDate: [NSDate distantPast]
                              inMode: NSDefaultRunLoopMode
                             dequeue: YES];
  }
}

@end
