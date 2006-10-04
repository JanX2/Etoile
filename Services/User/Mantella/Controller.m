#import "Controller.h"
#import "BrowserWindow.h"
#import <gdk/gdkx.h>

gboolean gs_event_func(gpointer data);

@interface GSDisplayServer (Private)
- (void) processEvent: (XEvent *) event;
@end

@implementation Controller

- (void) newWindowAction: (id) sender
{
  NSRect frame = NSMakeRect(100, 100, 600, 500);
  BrowserWindow *bwin = [[BrowserWindow alloc] initWithContentRect: frame
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask
      backing: NSBackingStoreRetained
      defer: NO];
  [bwin makeKeyAndOrderFront: self];
}

#if 0 // Modal doesn't work
- (void) openFileAction: (id) sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  int result = [panel runModalForTypes: [NSArray arrayWithObjects: @"html", nil]];
  if (result == NSOKButton) {
    [NSApp stopModal];
    NSArray *urls = [panel URLs];
    NSLog(@"%@", urls);
  }
}
#endif

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  gloop = g_main_loop_new(NULL, TRUE);
  gcontext = g_main_loop_get_context(gloop);
  g_timeout_add(100, gs_event_func, self); /* Call every 0.1 second */
  GDK_THREADS_LEAVE();

  gtk_moz_embed_set_profile_path(".", "mozembed");
  gtk_moz_embed_push_startup();

  /* Make menu */
  NSMenu *menu = [[NSMenu alloc] init];
  [menu addItemWithTitle: @"New Window"
	  action: @selector(newWindowAction:)
	  keyEquivalent: @"n"];
#if 0 // Modal doesn't work
  [menu addItemWithTitle: @"Open File..."
	  action: @selector(openFileAction:)
	  keyEquivalent: @"o"];
#endif
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
  NSRect frame = NSMakeRect(100, 100, 600, 500);
  BrowserWindow *bwin = [[BrowserWindow alloc] initWithContentRect: frame
      styleMask: NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask
      backing: NSBackingStoreRetained
      defer: NO];
  [bwin makeKeyAndOrderFront: self];
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

