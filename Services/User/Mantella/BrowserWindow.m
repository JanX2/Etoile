#import "BrowserWindow.h"
#import <gdk/gdkx.h>
#import <XWindowServerKit/XWindow.h>

/* GTK callback */
static gboolean mozembed_title_callback(GtkMozEmbed *embed, gpointer data)
{
  [(BrowserWindow *)data titleCallback];
  return TRUE;
}

static gboolean mozembed_location_callback(GtkMozEmbed *embed, gpointer data)
{
  [(BrowserWindow *)data locationCallback];
  return TRUE;
}

static gboolean mozembed_js_status_callback(GtkMozEmbed *embed, gpointer data)
{
  [(BrowserWindow *)data JavaScriptStatusCallback];
  return TRUE;
}

static gboolean mozembed_link_message_callback(GtkMozEmbed *embed, gpointer data)
{
  [(BrowserWindow *)data linkMessageCallback];
  return TRUE;
}

@implementation NSApplication (GMainLoop)

- (void) runOnce
{
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

@implementation BrowserWindow

/* Callback from GtkMozEmbed */
- (void) titleCallback
{
  char *s = gtk_moz_embed_get_title(GTK_MOZ_EMBED(mozembed));
  [self setTitle: [NSString stringWithUTF8String: s]]; 
}

- (void) locationCallback
{
  char *s = gtk_moz_embed_get_location(GTK_MOZ_EMBED(mozembed));
  [urlLocation setStringValue: [NSString stringWithUTF8String: s]];
}

- (void) JavaScriptStatusCallback
{
#if 0
  char *s = gtk_moz_embed_get_js_status(GTK_MOZ_EMBED(mozembed));
  NSLog(@"js_status %s", s);
#endif
}

- (void) linkMessageCallback
{
  char *s = gtk_moz_embed_get_link_message(GTK_MOZ_EMBED(mozembed));
  if (s) {
    [statusBar setStringValue: [NSString stringWithUTF8String: s]];
  }
}

/** private **/
/* Better to call XFlush(dpy) before this */
- (void) resizeEmbed
{
  NSRect frame = [[self contentView] bounds];
  gtk_window_resize(GTK_WINDOW(gtk_window), frame.size.width, frame.size.height-max_y-min_y);
//  gtk_widget_set_size_request(mozembed, frame.size.width, frame.size.height);
  XMoveWindow(dpy, gtkwin, 0, max_y);
}

/** end of private **/

- (void) windowDidResize: (NSNotification *) not
{
  [self resizeEmbed];
}

- (void) windowWillClose: (NSNotification *) not
{
  gtk_widget_destroy(GTK_WIDGET(gtk_window));
}

- (void) windowDidBecomeKey: (NSNotification*) not
{
//  NSLog(@"become key");
}

- (void) windowDidBecomeMain: (NSNotification*) not
{
//  NSLog(@"become main");
}

- (void) back: (id) sender
{
  if (gtk_moz_embed_can_go_back(GTK_MOZ_EMBED(mozembed))) {
    gtk_moz_embed_go_back(GTK_MOZ_EMBED(mozembed));
  }
}

- (void) forward: (id) sender
{
  if (gtk_moz_embed_can_go_forward(GTK_MOZ_EMBED(mozembed))) {
    gtk_moz_embed_go_forward(GTK_MOZ_EMBED(mozembed));
  }
}

- (void) stop: (id) sender
{
  gtk_moz_embed_stop_load(GTK_MOZ_EMBED(mozembed));
}

- (void) reload: (id) sender
{
  gtk_moz_embed_reload(GTK_MOZ_EMBED(mozembed), GTK_MOZ_EMBED_FLAG_RELOADNORMAL);
}

- (void) go: (id) sender
{
  NSString *url = [urlLocation stringValue];
  gtk_moz_embed_load_url(GTK_MOZ_EMBED(mozembed), [url cString]);
}

// top margin between title and mozilla
- (void) setMaxYMargin: (int) height
{
  max_y = height;
}

// bottom margin between title and mozilla
- (void) setMinYMargin: (int) height 
{
  min_y = height;
}

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
                    screen: (NSScreen*) aScreen
{
  max_y = 30;
  min_y = 20;

  self = [super initWithContentRect: contentRect
	        styleMask: aStyle
		backing: bufferingType
		defer: NO // Always NO to have x window created now
		screen: aScreen];
  [self setDelegate: self];

  /** NSWindow **/
  NSRect frame = contentRect;

  frame = NSMakeRect(5, frame.size.height-20-5, 70, 20);
  back = [[NSButton alloc] initWithFrame: frame];
  [back setTitle: @"Back"];
  [back setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [back setTarget: self];
  [back setAction: @selector(back:)];
  [[self contentView] addSubview: back];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  forward = [[NSButton alloc] initWithFrame: frame];
  [forward setTitle: @"Forward"];
  [forward setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [forward setTarget: self];
  [forward setAction: @selector(forward:)];
  [[self contentView] addSubview: forward];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  reload = [[NSButton alloc] initWithFrame: frame];
  [reload setTitle: @"Reload"];
  [reload setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [reload setTarget: self];
  [reload setAction: @selector(reload:)];
  [[self contentView] addSubview: reload];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  stop = [[NSButton alloc] initWithFrame: frame];
  [stop setTitle: @"Stop"];
  [stop setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [stop setTarget: self];
  [stop setAction: @selector(stop:)];
  [[self contentView] addSubview: stop];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 150, 20);
  urlLocation = [[NSTextField alloc] initWithFrame: frame];
  [urlLocation  setAutoresizingMask: NSViewWidthSizable|NSViewMinYMargin];
  [urlLocation setTarget: self];
  [urlLocation setAction: @selector(go:)];
  [[self contentView] addSubview: urlLocation];

  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  go = [[NSButton alloc] initWithFrame: frame];
  [go setTitle: @"Go"];
  [go setAutoresizingMask: NSViewMinXMargin|NSViewMinYMargin];
  [go setTarget: self];
  [go setAction: @selector(go:)];
  [[self contentView] addSubview: go];

  frame = NSMakeRect(0, 0, contentRect.size.width, min_y);
  statusBar = [[NSTextField alloc] initWithFrame: frame];
  [statusBar setAutoresizingMask: NSViewWidthSizable|NSViewMaxYMargin];
  [statusBar setEditable: NO];
  [statusBar setSelectable: NO];
  [statusBar setBezeled: NO];
  [statusBar setBordered: NO];
  [statusBar setDrawsBackground: NO];
  [statusBar setStringValue: @"Status"];
  [[self contentView] addSubview: statusBar];

  gdk_flush();
  /** GtkMozEmbed **/
  gtk_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  if (gtk_window == NULL) {
    NSLog(@"window is null");
    [self dealloc];
    return nil;
  }
  gtk_window_set_decorated(GTK_WINDOW(gtk_window), FALSE);
  /* Start small so the scrollbar will display correctly */
  gtk_widget_set_size_request(gtk_window, 200, 200);

  mozembed = gtk_moz_embed_new();
  if (mozembed == NULL) {
    NSLog(@"mozembed is null");
    [self dealloc];
    return nil;
  }

  g_signal_connect(G_OBJECT(mozembed),
		   "title",
		   G_CALLBACK(mozembed_title_callback),
		   self);

  g_signal_connect(G_OBJECT(mozembed),
		   "location",
		   G_CALLBACK(mozembed_location_callback),
		   self);

  g_signal_connect(G_OBJECT(mozembed),
		   "js_status",
		   G_CALLBACK(mozembed_js_status_callback),
		   self);

  g_signal_connect(G_OBJECT(mozembed),
		   "link_message",
		   G_CALLBACK(mozembed_link_message_callback),
		   self);

  gtk_moz_embed_load_url(GTK_MOZ_EMBED(mozembed), "http://www.google.com");

  gtk_container_add(GTK_CONTAINER(gtk_window), mozembed);
  gtk_widget_show(mozembed);
  gtk_widget_show(gtk_window);


  XFlush(dpy);
  gtkwin = GDK_WINDOW_XWINDOW(GTK_WIDGET(gtk_window)->window);
  Window nswin = [self xwindow];
//  NSLog(@"nswin %d, gtkwin %d", nswin, gtkwin);
  XReparentWindow(dpy, gtkwin, nswin, 0, max_y);
  XFlush(dpy); // We need to flush it to have reparent correctly

  [self resizeEmbed];

  return self;
}

- (NSTextField *) urlLocation
{
  return urlLocation;
}

@end

