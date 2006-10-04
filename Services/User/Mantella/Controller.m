#import "Controller.h"
#import "BrowserWindow.h"
#import <gdk/gdkx.h>

@interface GSDisplayServer (Private)
- (void) processEvent: (XEvent *) event;
@end

@interface Controller (Private)
- (void) runOnce;
@end

gboolean gs_event_func(gpointer data)
{
  [(Controller *)data runOnce];
  return TRUE;
}

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

- (void) runOnce
{
  NSEvent *e = [NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: [NSDate distantPast]
		                inMode: NSDefaultRunLoopMode
		               dequeue: YES];

  while(e) 
  {
    [NSApp sendEvent: e];
    e = [NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: [NSDate distantPast]
		                inMode: NSDefaultRunLoopMode
		               dequeue: YES];
  }
}

- (void) startGMainLoopThread
{
  g_main_loop_run(gloop);
  return;

  while (g_main_loop_is_running(gloop))
  {
//    if (g_main_context_pending(gcontext)) 
    {
      g_main_context_iteration(gcontext, TRUE);
    }
#if 0
    {
      NSEvent *e = [NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: [NSDate distantPast]
		                inMode: NSDefaultRunLoopMode
		               dequeue: YES];

      if (e != nil /*&&  e != null_event*/)
      {
         [NSApp sendEvent: e];
      }
    }
#endif
  }
}

- (void)receivedEvent:(void *)data
                 type:(RunLoopEventType)type
                extra:(void *)extra
              forMode:(NSString *)mode
{
  XEvent event;

  while (XPending(dpy))
  {
    XNextEvent (dpy, &event);
    [server processEvent: &event];
  }
}


- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  gloop = g_main_loop_new(NULL, TRUE);
  gcontext = g_main_loop_get_context(gloop);
//  g_idle_add(gs_event_func, self); /* Called when gmainloop idle */
  g_timeout_add(100, gs_event_func, self); /* Called when gmainloop idle */
  GDK_THREADS_LEAVE();
  server = GSCurrentServer();
  dpy = (Display *)[server serverDevice];

  /* Listen event */
  NSRunLoop *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(dpy);

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
            type: ET_RDESC
         watcher: (id<RunLoopEvents>)self
         forMode: NSDefaultRunLoopMode];

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

