/*
   XFunctions.m for XWindowServerKit
   Copyright (c) 2006        Yen-Ju Chen
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
   * Neither the name of the Etoile project nor the names of its contributors
     may be used to endorse or promote products derived from this software
     without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
   THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "XFunctions.h"
#import "gnustep.h"
#import <X11/Xatom.h>
#import <X11/Xutil.h>

static NSString *_XDGConfigHomePath;
static NSString *_XDGDataHomePath;
static NSArray *_XDGConfigDirectories;
static NSArray *_XDGDataDirectories;

BOOL XWindowClassHint(Window window, NSString **wm_class, NSString **wm_instance)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  XClassHint *class_hint;

  class_hint = XAllocClassHint();
  if (XGetClassHint(dpy,window,class_hint) == 0) {
    if (wm_class)
      *wm_class = nil;
    if (wm_instance)
      *wm_instance = nil;
    XFree(class_hint);
    return NO;
  }
  if (wm_instance)
    *wm_instance = [NSString stringWithCString: class_hint->res_name];
  if (wm_class)
    *wm_class = [NSString stringWithCString: class_hint->res_class];

  XFree(class_hint);
  return YES;
}

NSImage *XWindowIcon(Window window)
{
  NSImage *icon = nil;
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  unsigned long num;
  unsigned long *data = NULL;
  Atom prop = XInternAtom(dpy, "_NET_WM_ICON", False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, window, prop,
                                  0, 0x7FFFFFFF, False, XA_CARDINAL,
                                  &type_ret, &format_ret, &num,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Error: cannot get client icon");
    if (data != NULL) {
      XFree(data);
    }
    return nil;
  }

  if (num && data) {
    int width = data[0];
    int height = data[1];
    int size = width * height;
    if (2+size > num) {
      NSLog(@"Internal Error: icon size larger than return data.");
      if (data != NULL) {
        XFree(data);
      }
      return nil;
    }
    /* Try to make a bitmap representation */
    unsigned char *buf = calloc(sizeof(unsigned char), size * 4);
    int i = 0, j;
    for (j = 2; j < size; j++) {
#if 1 /* Although this is correct behavior, it can be platform-dependent */
      buf[i++] = (data[j] >> 16) & 0xff; // B
      buf[i++] = (data[j] >> 8) & 0xff; // G
      buf[i++] = (data[j] >> 0) & 0xff; // R
      buf[i++] = (data[j] >> 24) & 0xff; // A
#else
      buf[i++] = (data[j] >> 24) & 0xff; // A
      buf[i++] = (data[j] >> 16) & 0xff; // R
      buf[i++] = (data[j] >> 8) & 0xff; // G
      buf[i++] = (data[j]) & 0xff; // B
#endif
    }
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
	                        initWithBitmapDataPlanes: &buf
 	                        pixelsWide: width
	                        pixelsHigh: height
		                bitsPerSample: 8 /* depth */
		                samplesPerPixel: 4 /* channels */
		                hasAlpha: YES
		                isPlanar: NO
			        colorSpaceName: NSCalibratedRGBColorSpace
				bytesPerRow: 4 * width
				bitsPerPixel: 4 * 8];
    icon = [[NSImage alloc] initWithSize: NSMakeSize(width, height)];
    [icon addRepresentation: rep];
    DESTROY(rep);
    /* Should free buf */
  }
  if (data != NULL) {
    XFree(data);
  }
  return icon;
}

unsigned long XWindowState(Window win)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  unsigned long return_value = -1;
  unsigned long *data = NULL;
  unsigned long count;
  Atom prop = XInternAtom(dpy, "WM_STATE", False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, win, prop,
                                  0, 0x7FFFFFFF, False, prop,
                                  &type_ret, &format_ret, &count,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Error: cannot get client state");
  }
  else
  {
    return_value = data[0];
  }
  if (data != NULL) {
    XFree(data);
  }
  return return_value; 
}

Atom *XWindowNetStates(Window win, unsigned long *count)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  Atom *data = NULL;
  Atom prop = XInternAtom(dpy, "_NET_WM_STATE", False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, win, prop,
                                  0, 0x7FFFFFFF, False, XA_ATOM,
                                  &type_ret, &format_ret, count,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Error: cannot get net state of client");
    *count = 0;
    if (data != NULL) {
      XFree(data);
    }
    return NULL;
  }
  return data;
}

Window XWindowGroupWindow(Window win)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  XWMHints *wmHints = XGetWMHints(dpy, win);
  if (wmHints) {
    Window group_leader = wmHints->window_group;
    XFree(wmHints);
    return group_leader;
  }
  return 0;
}

NSString* XWindowCommandPath(Window win)
{
  /* WM_COMMAND is not used by many modern applications */
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  int argc_return;
  char **argv_return;
  
  int result = XGetCommand(dpy, win, &argv_return, &argc_return);
  if ((result == 0) || (argc_return == 0)) 
  {
    //NSLog(@"No command available");
    return nil;
  }

  // FIXME: should process string list to get all arguments
  return [NSString stringWithCString: argv_return[0]];
}

/* This one does not work because GNUstep 
 * only set IconWindowHint for WindowMaker */
BOOL XWindowIsIcon(Window win)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  XWMHints* hints = XGetWMHints (dpy, win);

  if (hints != NULL)
  {
	if (hints->flags & IconWindowHint)
	{
		//NSLog (@"ICON WINDOW");
		return YES;
	}
	XFree (hints);
  }
  return NO;
}

void XWindowCloseWindow(Window win, BOOL forcefully)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  if (forcefully) {
    XKillClient(dpy, win);
    return;
  } 

  Atom *data = NULL;
  Atom prop = XInternAtom(dpy, "WM_PROTOCOLS", False);
  Atom delete_window = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret, count;
  int result = XGetWindowProperty(dpy, win, prop,
                                  0, 0x7FFFFFFF, False, XA_ATOM,
                                  &type_ret, &format_ret, &count,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Cannot get wm_protocols of client. Quit forcefully.");
    // Do not support quit gracefully. Must be forcefully.
    if (data != NULL) {
      XFree(data);
    }
    XKillClient(dpy, win);
    return;
  } else {
    int i;
    for (i = 0; i < count; i++) {
      if (data[i] == delete_window) {
	//NSLog(@"Support WM_DELETE_WINDOW");
	/* Send message to quit */
	XClientMessageEvent *xev = calloc(1, sizeof(XClientMessageEvent));
	xev->type = ClientMessage;
	xev->display = dpy;
	xev->window = win;
	xev->message_type = prop;
	xev->format = 32;
	xev->data.l[0] = delete_window;
	xev->data.l[1] = 0; // just in case
	xev->data.l[2] = 0;
	xev->data.l[3] = 0;
	XSendEvent(dpy, win, False,
		                 NoEventMask, (XEvent *)xev);
	XFree(xev);
      }
    }
  }
  if (data != NULL) {
    XFree(data);
  }
}

BOOL XGNUstepWindowLevel(Window win, int *level)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  BOOL result_value = NO;
  unsigned long *data = NULL;
  Atom prop = XInternAtom(dpy, _GNUSTEP_WM_ATTR, False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret, count;
  int result = XGetWindowProperty(dpy, win, prop,
                                  0, 0x7FFFFFFF, False, prop,
                                  &type_ret, &format_ret, &count,
                                  &after_ret, (unsigned char **)&data);
  if ((result == Success)) 
  {
    if (data[0] & GSWindowLevelAttr) 
    {
      *level = data[2];
      result_value = YES;
    }
  }
  if (data != NULL) 
  {
    XFree(data);
  }
  return result_value;
}

void XWindowSetActiveWindow(Window win, Window old)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  Window root_win = RootWindow(dpy, [[NSScreen mainScreen] screenNumber]);
  Atom X_NET_ACTIVE_WINDOW = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);

  XClientMessageEvent *xev = calloc(1, sizeof(XClientMessageEvent));
  xev->type = ClientMessage;
  xev->display = dpy;
  xev->window = win;
  xev->message_type = X_NET_ACTIVE_WINDOW;
  xev->format = 32;
  xev->data.l[0] = 2;
  xev->data.l[1] = CurrentTime; /* Not sure about this */
  xev->data.l[2] = (old == None) ? 0 : old;
  xev->data.l[3] = 0;
  XSendEvent(dpy, root_win, False,
             SubstructureRedirectMask, (XEvent *)xev);
  XFree(xev);
}

unsigned int XWindowDesktopOfWindow(Window win)
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];

  unsigned long *data = NULL;
  Atom prop = XInternAtom(dpy, "_NET_WM_DESKTOP", False);
  Atom type_ret;
  int format_ret;
  unsigned long after_ret, count;
  int result = XGetWindowProperty(dpy, win, prop,
                                  0, 0x7FFFFFFF, False, XA_CARDINAL,
                                  &type_ret, &format_ret, &count,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) {
    NSLog(@"Error: cannot get _NET_WM_DESKTOP of client");
    return -1;
  }
  int desktop = (int)*data;
  XFree(data);
  return desktop;
}

Window XWindowActiveWindow()
{
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  Window root_win = RootWindow(dpy, [[NSScreen mainScreen] screenNumber]);
  Atom X_NET_ACTIVE_WINDOW = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);

  Window window = None;
  unsigned long num;
  unsigned long *data = NULL;
  Atom type_ret;
  int format_ret;
  unsigned long after_ret;
  int result = XGetWindowProperty(dpy, root_win, X_NET_ACTIVE_WINDOW,
                                  0, 0x7FFFFFFF, False, XA_WINDOW,
                                  &type_ret, &format_ret, &num,
                                  &after_ret, (unsigned char **)&data);
  if ((result != Success)) 
  {
    NSLog(@"Error: cannot get active window.");
  }
  else
  {
    window = data[0];
  }
  if (data != NULL)
  {
    XFree(data);
  }
  return window;
}


/* Freedesktop.org stuff */
NSString *XDGConfigHomePath()
{
  if (_XDGConfigHomePath == nil) {
    NSString *p = [[[NSProcessInfo processInfo] environment] objectForKey: @"XDG_CONFIG_HOME"];
    if (p && [p length] > 0) {
      ASSIGN(_XDGConfigHomePath, p);
    } else {
      ASSIGN(_XDGConfigHomePath, [NSHomeDirectory() stringByAppendingPathComponent: @".config"]);
    }
  }
  return _XDGConfigHomePath;
}

NSString *XDGDataHomePath()
{
  if (_XDGDataHomePath == nil) {
    NSString *p = [[[NSProcessInfo processInfo] environment] objectForKey: @"XDG_DATA_HOME"];
    if (p && [p length] > 0) {
      ASSIGN(_XDGDataHomePath, p);
    } else {
      ASSIGN(_XDGDataHomePath, [[NSHomeDirectory() stringByAppendingPathComponent: @".local"] stringByAppendingPathComponent: @"share"]);
    }
  }
  return _XDGDataHomePath;
}

NSArray *XDGConfigDirectories()
{
  if (_XDGConfigDirectories == nil) {
    NSString *p = [[[NSProcessInfo processInfo] environment] objectForKey: @"XDG_CONFIG_DIRS"];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject: XDGConfigHomePath()];
    if (p && [p length] > 0) { /* not unset or empty */
      [array addObjectsFromArray: [p componentsSeparatedByString: @":"]];
    } else {
      [array addObject: [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"etc", @"xdg", nil]]];
    }
    ASSIGNCOPY(_XDGConfigDirectories, array);
    DESTROY(array);
  }
  return _XDGConfigDirectories;
}

NSArray *XDGDataDirectories()
{
  if (_XDGDataDirectories == nil) {
    NSString *p = [[[NSProcessInfo processInfo] environment] objectForKey: @"XDG_DATA_DIRS"];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject: XDGDataHomePath()];
    if (p && [p length] > 0) {/* not unset or empty */
        [array addObjectsFromArray: [p componentsSeparatedByString: @":"]];
    } else {
        [array addObject: [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"usr", @"local", @"share", nil]]];
        [array addObject: [NSString pathWithComponents: [NSArray arrayWithObjects: @"/", @"usr", @"share", nil]]];
    }
    ASSIGNCOPY(_XDGDataDirectories, array);
    DESTROY(array);
  }
  return _XDGDataDirectories;
}

