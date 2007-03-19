#import <XWindowServerKit/XWindow.h>
#import "AZBackground.h"
#import <X11/Xutil.h>

NSString *const FileUserDefaults = @"File";

static AZBackground *sharedInstance;

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
  NSLog(@"path %@", path);

  return AUTORELEASE([[NSImage alloc] initWithContentsOfFile: path]);
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

