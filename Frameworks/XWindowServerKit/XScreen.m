/*
   XScreen.m for XWindowServerKit
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

#import "XScreen.h"
#import <X11/Xatom.h>

NSString *XCurrentWorkspaceDidChangeNotification = @"XCurrentWorkspaceDidChangeNotification";

@implementation NSScreen (XScreen)

/** Private **/
/* return -1 if failed. */
- (int) intValueOfProperty: (char *) property
{
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  Window root_win = RootWindow(dpy, [self screenNumber]);

  Atom prop = XInternAtom(dpy, property, False);
  Atom type_ret;
  int format_ret;
  unsigned long items_ret;
  unsigned long after_ret;
  unsigned long *prop_data = NULL;
  int result = XGetWindowProperty(dpy, root_win, prop, 
		  0, 0x7FFFFFFF, False, XA_CARDINAL, 
		  &type_ret, &format_ret, &items_ret,
		  &after_ret, (unsigned char **)&prop_data);
  if ((result == Success) && (items_ret > 0)) {
    int number = (int)*prop_data;
    XFree(prop_data);
    return number;
  } else {
    return -1;
  }
}

/** End of Private **/

- (void) setCurrentWorkspace: (int) workspace
{
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  Window root_win = RootWindow(dpy, [self screenNumber]);
  Atom X_NET_CURRENT_DESKTOP = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", False);

  XClientMessageEvent *xev = calloc(1, sizeof(XClientMessageEvent));
  xev->type = ClientMessage;
  xev->window = root_win;
  xev->message_type = X_NET_CURRENT_DESKTOP;
  xev->format = 32;
  xev->data.l[0] = workspace;
  xev->data.l[1] = 0; // should put timestamp here for newer EWMH
  xev->data.l[2] = 0;
  xev->data.l[3] = 0;
  XSendEvent(dpy, root_win, False,
             (SubstructureNotifyMask|SubstructureRedirectMask), (XEvent *)xev);
  XFree(xev);
}

- (int) currentWorkspace
{
  return [self intValueOfProperty: "_NET_CURRENT_DESKTOP"];
}

- (int) numberOfWorkspaces
{
  int num = [self intValueOfProperty: "_NET_NUMBER_OF_DESKTOPS"];
  if (num < 0) {
    /* Failed to get number of desktop.
     * Return 0 instead of -1 so that it is less confusing. */
    num = 0;
  }
  return num;
}

- (NSArray *) namesOfWorkspaces;
{
  GSDisplayServer *server = GSCurrentServer();
  Display *dpy = (Display*)[GSCurrentServer() serverDevice];
  Window root_win = RootWindow(dpy, [self screenNumber]);

  Atom X_NET_DESKTOP_NAMES = XInternAtom(dpy, "_NET_DESKTOP_NAMES", False);
  Atom X_UTF8_STRING = XInternAtom(dpy, "UTF8_STRING", False);
  Atom type_ret;
  int format_ret;
  unsigned long items_ret;
  unsigned long after_ret;
  char *prop_data = NULL;
  int result = XGetWindowProperty(dpy, root_win, X_NET_DESKTOP_NAMES, 
		  0, 0x7FFFFFFF, False, X_UTF8_STRING, 
		  &type_ret, &format_ret, &items_ret,
		  &after_ret, (unsigned char**)&prop_data);
  if ((result == Success) && (items_ret > 0)) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    char *p = prop_data;
    while (p < prop_data + items_ret - 1) {
      NSString *s = [NSString stringWithUTF8String: p];
      if (s) {
        [array addObject: s];
      } else {
	[array addObject: [NSString string]];
      }
      p += strlen(p) + 1; // next
    }
    XFree(prop_data);
    return AUTORELEASE(array);
  } else {
    return nil;
  }
}

@end
