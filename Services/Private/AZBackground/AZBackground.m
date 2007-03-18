#import <XWindowServerKit/XWindow.h>
#import "AZBackground.h"
#import <X11/Xutil.h>

NSString *const FileUserDefaults = @"File";

static AZBackground *sharedInstance;

@implementation AZBackground

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
}

- (void) applicationDidFinishLaunching:(NSNotification *) not
{
  /* Setup drawable window */
  NSImage *image;
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

  if (image) {
    [self drawImage: image];
  }
}

+ (AZBackground  *) background 
{
  if (sharedInstance == nil)
    sharedInstance = [[AZBackground alloc] init];
  return sharedInstance;
}

@end

