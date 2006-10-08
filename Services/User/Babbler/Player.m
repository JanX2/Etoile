#import "Player.h"
#import <X11/Xlib.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <gst/interfaces/xoverlay.h>

@interface Player (Private)
- (BOOL) busCallBack: (GstMessage *) msg;
- (GstBusSyncReply) busSyncCallBack: (GstMessage *) msg;
@end

static gboolean bus_call (GstBus *bus, GstMessage *msg, gpointer data)
{
  return [(Player *)data busCallBack: msg];
}

static GstBusSyncReply
bus_sync_call (GstBus * bus, GstMessage * message, gpointer data)
{
  return [(Player *)data busSyncCallBack: message];
}

@implementation Player

/** Private **/
- (GstBusSyncReply) busSyncCallBack: (GstMessage *) message
{
  // ignore anything but 'prepare-xwindow-id' element messages
  if (GST_MESSAGE_TYPE (message) != GST_MESSAGE_ELEMENT)
    return GST_BUS_PASS;
      
  if (!gst_structure_has_name (message->structure, "prepare-xwindow-id"))
    return GST_BUS_PASS;
        
  Window gst_win = XCreateSimpleWindow (dpy, [self xwindow], 0, 30, 320, 240, 0, 0, 0);
         
  XSetWindowBackgroundPixmap (dpy, gst_win, None);
           
  XMapRaised (dpy, gst_win);
                
  XSync (dpy, FALSE);
                 
  gst_x_overlay_set_xwindow_id (GST_X_OVERLAY (GST_MESSAGE_SRC (message)),
                   gst_win);
                    
  return GST_BUS_DROP;
}

- (BOOL) busCallBack: (GstMessage *) msg
{
  switch (GST_MESSAGE_TYPE (msg)) {
    case GST_MESSAGE_STATE_CHANGED:
//      g_print("State changed\n");
      break;
    case GST_MESSAGE_EOS:
      // NSLog("End of %@\n", url);
      gst_element_set_state(play, GST_STATE_READY);
      isPlaying = NO;
      [playButton setTitle: @"Play"];
      break;
    case GST_MESSAGE_ERROR: 
    {
      gchar *debug;
      GError *err;

      gst_message_parse_error (msg, &err, &debug);
      g_free (debug);

      g_print ("Error: %s\n", err->message);
      g_error_free (err);

//      g_main_loop_quit (loop);
      break;
    }
    default:
      break;
  }
  return YES;
}

- (NSString *) uriForGStreamer: (NSURL *) u
{
  if ([url isFileURL]) {
    return [@"file://" stringByAppendingString: [url path]];
  } else {
    return [url absoluteString];
  }
}

- (void) windowWillClose: (NSNotification *) not
{
  if (play) {
    gst_element_set_state(play, GST_STATE_NULL);
    gst_object_unref(GST_OBJECT(play));
  }
}

- (void) windowDidBecomeKey: (NSNotification*) not
{
//  NSLog(@"become key");
}

- (void) windowDidBecomeMain: (NSNotification*) not
{
//  NSLog(@"become main");
}

- (void) reverseAction: (id) sender
{
  NSLog(@"Reverse");
}

- (void) playAction: (id) sender
{
  if (play == NULL) {
    play = gst_element_factory_make("playbin", "play");
    g_object_set(G_OBJECT(play), "uri", [[self uriForGStreamer: url] UTF8String], NULL);
    bus = gst_pipeline_get_bus(GST_PIPELINE(play));
    gst_bus_add_watch(bus, bus_call, self);
    gst_bus_set_sync_handler(bus, (GstBusSyncHandler)bus_sync_call, self);
    gst_object_unref(bus);
  }
  if (isPlaying == NO) {
    gst_element_set_state(play, GST_STATE_PLAYING);
    isPlaying = YES;
    [playButton setTitle: @"Stop"];
  } else {
    gst_element_set_state(play, GST_STATE_PAUSED);
    isPlaying = NO;
    [playButton setTitle: @"Play"];
  }
}

- (void) forwardAction: (id) sender
{
  NSLog(@"Forward");
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

  frame = NSMakeRect(5, frame.size.height-20-5, 70, 20);
#if 0
  reverseButton = [[NSButton alloc] initWithFrame: frame];
  [reverseButton setTitle: @"Reverse"];
  [reverseButton setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [reverseButton setTarget: self];
  [reverseButton setAction: @selector(reverseAction:)];
  [[self contentView] addSubview: reverseButton];
#endif

//  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  playButton = [[NSButton alloc] initWithFrame: frame];
  [playButton setTitle: @"Play"];
  [playButton setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [playButton setTarget: self];
  [playButton setAction: @selector(playAction:)];
  [[self contentView] addSubview: playButton];

#if 0
  frame = NSMakeRect(NSMaxX(frame)+5, NSMinY(frame), 70, 20);
  forwardButton = [[NSButton alloc] initWithFrame: frame];
  [forwardButton setTitle: @"Forward"];
  [forwardButton setAutoresizingMask: NSViewMaxXMargin|NSViewMinYMargin];
  [forwardButton setTarget: self];
  [forwardButton  setAction: @selector(forwardAction:)];
  [[self contentView] addSubview: forwardButton];
#endif

  isPlaying = NO;

  return self;
}

- (void) setURL: (NSURL *) u
{
  ASSIGNCOPY(url, u);
  [self setTitle: [self uriForGStreamer: url]];
}

- (NSURL*) url
{
  return url;
}

@end

