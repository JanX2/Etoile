#import <XWindowServerKit/XWindow.h>
#import <XWindowServerKit/XFunctions.h>
#import <GNUstepGUI/GSServicesManager.h>
#import "AZBackground.h"
#import <X11/Xutil.h>
#import <X11/Xatom.h>

NSString *const FileUserDefaults = @"File";
static NSString *AZPerformServiceNotification = @"AZPerformServiceNotification";
static NSString *AZServiceItem = @"AZServiceItem";

static AZBackground *sharedInstance;

@interface GSDisplayServer (AZPrivate)
 - (void) processEvent: (XEvent *) event;
@end

@implementation AZBackground
/** Private **/
- (NSImage *) defaultImage
{
  /* Check for bundled images */
  NSString *path = nil;
  NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType: @"jpg"
                                                      inDirectory: nil];
  /* Let pick the right ratio */
  NSRect frame = [[NSScreen mainScreen] frame];
  float screenRatio = frame.size.width/frame.size.height;
  NSEnumerator *e = [paths objectEnumerator];
  while ((path = [e nextObject]))
  {
    /* The default images is name as "'width'x'height'.jpg".
       We do not want to load them in NSImage only for checking size.
       It is a waste of memory */
    NSArray *a = [[[path lastPathComponent] stringByDeletingPathExtension] 
                                            componentsSeparatedByString: @"x"];

    if ([a count] != 2) /* Wrong format */
      continue;

    int w = [[a objectAtIndex: 0] intValue];
    int h = [[a objectAtIndex: 1] intValue];
    float ratio = ((float)w)/h;

    if ((w == 0) || (h == 0)) /* Wrong format */
      continue;

    /* Tolerate 1% error */
    if ((screenRatio < ratio + 0.01) && (screenRatio > ratio - 0.01))
    {
      break;
    }
  }

  return AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
} 

/* We need to find out which window has the selection.
   First, XGetSelectionOwner is not reliable for no reason.
   _NET_ACTIVE_WINDOW seems to be always on service menu,
   which disappers after clicking, resulting BadWindow error.
 */
- (Window) activeXWindow
{
#if 0
  /* Let's see which window is on the top */ 
  unsigned long num;
  unsigned long *data = NULL;
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, root_win, X_NET_CLIENT_LIST_STACKING,
                                  0, 0x7FFFFFFF, False, XA_WINDOW,
                                  &type_ret, &format_ret, &num,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Error: cannot get client list stacking.");
    if (data != NULL) {
      XFree(data);
    }
    return None;
  }
  NSLog(@"number of windows %d", num);
  return data[num-1];
#endif
#if 1
  /* Let's see which window is the active by _NET_ACTIVE_WINDOW */
  unsigned long num;
  unsigned long *data = NULL;
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, root_win, X_NET_ACTIVE_WINDOW,
                                  0, 0x7FFFFFFF, False, XA_WINDOW,
                                  &type_ret, &format_ret, &num,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Error: cannot get active window.");
    if (data != NULL) {
      XFree(data);
    }
    return None;
  }
  return data[0];
#endif
}

- (void) performServiceRequested: (NSNotification *) not
{
  ASSIGN(serviceItem, [[not userInfo] objectForKey: AZServiceItem]);
  Window activeXWindow = [self activeXWindow];

  if (activeXWindow != None)
  {
    NSString *wm_class = nil, *wm_instance = nil;
    if (XWindowClassHint(activeXWindow, &wm_class, &wm_instance))
    {
      if ([wm_class isEqualToString: @"GNUstep"])
      {
        NSLog(@"This is a GNUstep application (%@.%@).", wm_instance, wm_class);
        id proxy = [NSConnection rootProxyForConnectionWithRegisteredName: wm_instance host: @""];
        if (proxy)
        {
	  NSLog(@"Got proxy");
          [proxy application: nil serviceRequested: serviceItem];
        }
	[proxy invalidate];
	return;
      }
    }
    else
    {
      NSLog(@"Cannot get class and instance");
      return;
    }
  }

  /* This is only work for XWindow and string type for now */
  XConvertSelection(dpy, XA_PRIMARY, XA_STRING, X_PROPERTY_NAME, window, CurrentTime);
  XSync(dpy, False);
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
    switch (event.type) {
      case SelectionNotify:
      {
        if (event.xselection.selection != XA_PRIMARY) 
	{
	  /* Not from PRIMARY buffer. */
	  break;
	}
	if (event.xselection.property == None) 
	{
	  NSLog(@"Conversion fails.");
	  break;
	} 
	else 
	{
	  unsigned long num;
	  unsigned char *data = NULL;
	  Atom type_ret;
	  int format_ret;
	  unsigned long after_ret;
	  int result = XGetWindowProperty(dpy, window, X_PROPERTY_NAME,
                                  0, 0x7FFFFFFF, False, (Atom)AnyPropertyType,
                                  &type_ret, &format_ret, &num,
                                  &after_ret, &data);
	  if ((result != Success)) {
	    NSLog(@"Error: cannot get string from primary buffer.");
	    if (data != NULL) {
	      XFree(data);
	    }
	    break;
	  }

	  NSString *string = [NSString stringWithCString: (char *)data];
	  XFree(data);
          NSPasteboard *pb = [NSPasteboard pasteboardWithUniqueName];
          NSArray *types = [NSArray arrayWithObject:NSStringPboardType];
	  [pb declareTypes: types owner: nil];
	  NSLog(@"###%@###", serviceItem);
	  if ([pb setString: string forType: NSStringPboardType] == NO)
	  {
	    NSLog(@"Fail to write to pasteboard");
	    break;
	  }
	  if (NSPerformService(serviceItem, pb) == NO)
	  {
            NSLog(@"Perform service fails.");
	  }
#if 0 // Should we clean up the selection ?
        XDeleteProperty (dpy, window, X_PROPERTY_NAME);
#endif
        }
      }

      default:
        if (event.xany.window != window)
        {
          [server processEvent: &event];
        }
    }
  }
}

/** Private **/

/* We cannot scale image with NSImage and EtoileUI use a hack which does not 
   work on all backends. So we put up the whole image even it is bigger
   than screen. User should make sure their images fit the screen.
   For bundled images, even only top-left part of it is shown,
   it still looks good. */
- (void) drawImage: (NSImage *) image
{
  NSImageRep *rep = [image bestRepresentationForDevice: nil];
  if ([rep isKindOfClass: [NSBitmapImageRep class]] == NO)
  {
    NSLog(@"Not a bitmap");
    return;
  }

  NSSize size = [image size];
  int bitsPerPixel = [(NSBitmapImageRep *)rep bitsPerPixel];
  int i, j, k = 0;
  unsigned char *ptr;
  //NSLog(@"Sizde %@", NSStringFromSize(size));
  //NSLog(@"Bits per pixel %d", bitsPerPixel);

  /* For record, visual can also be DefaultVisual(dpy, DefaultScreen(dpy)) */
  unsigned int depth = 24;
  XImage *ximage = XCreateImage(dpy, DefaultVisual(dpy, screen), 
				depth, ZPixmap, 0, NULL, 
				size.width, size.height, 8, 0);
  if (ximage) 
  {
    ximage->data = malloc(ximage->height * ximage->bytes_per_line);
    ptr = [(NSBitmapImageRep *)rep bitmapData];
    switch(bitsPerPixel)
    {
      case 32:
	for (i = 0; i < size.height; i++)
	{
	  for (j = 0; j < size.width; j++)
	  {
#if GS_WORDS_BIGENDIAN
	    ximage->data[k++] = ptr[3];
	    ximage->data[k++] = ptr[0];
	    ximage->data[k++] = ptr[1];
	    ximage->data[k++] = ptr[2];
#else
	    ximage->data[k++] = ptr[2];
	    ximage->data[k++] = ptr[1];
	    ximage->data[k++] = ptr[0];
	    ximage->data[k++] = ptr[3];
#endif
	    ptr += 4;
	  }
        }
        break;
      case 24:
	for (i = 0; i < size.height; i++)
	{
	  for (j = 0; j < size.width; j++)
	  {
#if GS_WORDS_BIGENDIAN
	    ximage->data[k++] = 0;
	    ximage->data[k++] = ptr[0];
	    ximage->data[k++] = ptr[1];
	    ximage->data[k++] = ptr[2];
#else
	    ximage->data[k++] = ptr[2];
	    ximage->data[k++] = ptr[1];
	    ximage->data[k++] = ptr[0];
	    ximage->data[k++] = 0;
#endif
	    ptr += 3;
	  }
        }
        break;
      default:
        NSLog(@"Not ARGA or RGA image");
        return;
    }
    Pixmap pixmap = XCreatePixmap(dpy, root_win, 
				  size.width, size.height, depth);

    GC gc = XDefaultGC(dpy, screen);
    XPutImage(dpy, pixmap, gc, ximage, 0, 0, 
	      0, 0, size.width, size.height);
    XSetWindowBackgroundPixmap(dpy, root_win, pixmap);
    XClearWindow(dpy, root_win);
    XSync(dpy, False);
    /* Is it safe to destroy ximage ? Seems to be.
     * NOTE: XDestroyImage will also free ximage->data. */
    XDestroyImage(ximage); 
    XFreePixmap(dpy, pixmap);

    /* Based on some old information, we should put pixmap onto root window
       '_XROOTPMAP_ID' (type XA_PIXMAP). And if there is an old one,
       we need to release it (XKillClient() ?). It seems to be a 
       way to notify other clients that the desktop image is changed 
       because fake transpareny need to copy the background image. */
 
  } 
  else 
  {
    NSLog(@"Cannot create XImage");
  }
}

- (void) applicationWillFinishLaunching:(NSNotification *) not
{
  server = GSCurrentServer();
  dpy = (Display*)[server serverDevice];
  screen = [[NSScreen mainScreen] screenNumber];
  root_win = RootWindow(dpy, screen);

  /* Listen event */
  NSRunLoop *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(dpy);

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
                        type: ET_RDESC
                     watcher: (id<RunLoopEvents>)self
                     forMode: NSDefaultRunLoopMode];

  /* window to receive X notify */
  window = XCreateSimpleWindow (dpy, root_win, 0, 0, 1, 1, 0, 0, 0);
  XSelectInput(dpy, window, PropertyChangeMask);

  /* We listen to request of perform service, probably from service menulet */
  [[[NSWorkspace sharedWorkspace] notificationCenter]
	addObserver: self
	   selector: @selector(performServiceRequested:)
	       name: AZPerformServiceNotification
	     object: nil];

  X_PROPERTY_NAME = XInternAtom(dpy, "X_PROPERTY_NAME", False);
  X_NET_ACTIVE_WINDOW = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);
  X_NET_CLIENT_LIST_STACKING = XInternAtom(dpy, "_NET_CLIENT_LIST_STACKING", False);

#if 0 // Not ncessary
  GSServicesManager *gManager = [GSServicesManager newWithApplication: NSApp];
  [gManager rebuildServices];
  [gManager rebuildServicesMenu];
#endif
#if 0 // Not necessary
  /* We need to setup menu in order to have service work */
  NSMenu *menu = [[NSMenu alloc] initWithTitle: @"AZBackground"];
  NSMenu *services = [[NSMenu alloc] initWithTitle: @"Services"];
  id <NSMenuItem> item = [menu addItemWithTitle: @"Services"
                                action: NULL
                        keyEquivalent: @""];
  [menu setSubmenu: services forItem: item];
  [menu addItemWithTitle: @"Quit"
                        action: @selector(terminate:)
                        keyEquivalent: @"q"];
//  [NSApp setServicesMenu: services];
//  [NSApp setMainMenu: menu];
  DESTROY(services);
  DESTROY(menu);
#endif
}

- (void) applicationDidFinishLaunching:(NSNotification *) not
{
  /* Setup drawable window */
  NSImage *image = nil;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSProcessInfo *pi = [NSProcessInfo processInfo];
  NSArray *args = [pi arguments];
  NSString *path = nil;

  if ([args count] > 1) 
  {
    /* Check command line */
    path = [args objectAtIndex: 1];
  } 
  else 
  {
    /* Check user defaults */
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    path = [defaults stringForKey: FileUserDefaults];
  }

  if (path) 
  {
    if ([fm fileExistsAtPath: [path stringByStandardizingPath]]) 
    {
      image = AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
    }
  }

  if (image == nil)
  {
    image = [self defaultImage];
  }

  if (image) 
  {
    [self drawImage: image];
  }
  else
  {
    NSLog(@"Cannot find an image. Do nothing");
  }
}

+ (AZBackground  *) background 
{
  if (sharedInstance == nil)
    sharedInstance = [[AZBackground alloc] init];
  return sharedInstance;
}

@end

