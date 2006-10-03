#import "Controller.h"
#import "BrowserWindow.h"
#import <gdk/gdkx.h>

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

- (void) startGMainLoopThread
{
  while (g_main_loop_is_running(gloop))
  {
    while (g_main_context_pending(g_main_loop_get_context(gloop))) 
    {
      g_main_context_iteration(g_main_loop_get_context(gloop), TRUE);

    }
    {
      NSEvent *e = [NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: [NSDate distantPast]
		                inMode: NSDefaultRunLoopMode
		               dequeue: YES];

      if (e != nil /*&&  e != null_event*/)
      {
         NSEventType   type = [e type];

         [NSApp sendEvent: e];
      }
    }
  }
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  gloop = g_main_loop_new(NULL, TRUE);
  GDK_THREADS_LEAVE();
  server = GSCurrentServer();
  dpy = (Display *)[server serverDevice];

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
  [self startGMainLoopThread];
}

- (void) applicationWillTerminate: (NSNotification *) not
{
  GDK_THREADS_ENTER();
  gdk_flush();
}

@end

