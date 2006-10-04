#import "BrowserWindow.h"
#import <gdk/gdkx.h>
#import <XWindowServerKit/XWindow.h>

@implementation BrowserWindow

/** private **/
- (void) resizeEmbed
{
  NSRect frame = [[self contentView] bounds];
  gtk_window_resize(GTK_WINDOW(gtk_window), frame.size.width, frame.size.height-max_y-min_y);
//  gtk_widget_set_size_request(mozembed, frame.size.width, frame.size.height);
  XMoveWindow(dpy, gtkwin, 0, max_y);
//  XFlush(dpy);
}

/** end of private **/

- (void) windowDidResize: (NSNotification *) not
{
  [self resizeEmbed];
}

- (void) windowWillClose: (NSNotification *) not
{
//  NSLog(@"close");
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
  self = [super initWithContentRect: contentRect
	        styleMask: aStyle
		backing: bufferingType
		defer: NO // Always NO to have x window created now
		screen: aScreen];
  [self setDelegate: self];

  /** NSWindow **/
  NSRect frame = contentRect;
  Window nswin = [self xwindow];
//  [self makeKeyAndOrderFront: self];

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

  /** GtkMozEmbed **/

  gtk_window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  if (gtk_window == NULL) {
    NSLog(@"window is null");
    [self dealloc];
    return nil;
  }
  /* Start small so the scrollbar will display correctly */
  gtk_widget_set_size_request(gtk_window, 200, 200);

  mozembed = gtk_moz_embed_new();
  if (mozembed == NULL) {
    NSLog(@"mozembed is null");
    [self dealloc];
    return nil;
  }

  gtk_moz_embed_load_url(GTK_MOZ_EMBED(mozembed), "http://www.google.com");

  gtk_container_add(GTK_CONTAINER(gtk_window), mozembed);
  gtk_widget_show(mozembed);
  gtk_widget_show(gtk_window);

  max_y = 30;
  min_y = 20;

  gtkwin = GDK_WINDOW_XWINDOW(GTK_WIDGET(gtk_window)->window);
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

