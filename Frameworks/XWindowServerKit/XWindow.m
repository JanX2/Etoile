/*
   XWindow.m for XWindowServerKit
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

#import "XWindow.h"
#import <X11/Xatom.h>

@implementation XWindow
- (id) initWithContentRect: (NSRect)contentRect
                 styleMask: (unsigned int)aStyle
                   backing: (NSBackingStoreType)bufferingType
                     defer: (BOOL)flag
                    screen: (NSScreen*)aScreen
{
  self = [super initWithContentRect: contentRect
                 styleMask: aStyle
                   backing: bufferingType
                     defer: flag
                    screen: aScreen];

  server = GSCurrentServer();
  dpy = (Display*)[GSCurrentServer() serverDevice];
  screen = [[NSScreen mainScreen] screenNumber];
  root_win = RootWindow(dpy, screen);

  X_NET_WM_DESKTOP = XInternAtom(dpy, "_NET_WM_DESKTOP", False);
  X_NET_WM_STATE = XInternAtom(dpy, "_NET_WM_STATE", False);
  X_NET_WM_STATE_SKIP_PAGER = XInternAtom(dpy, "_NET_WM_STATE_SKIP_PAGER", False);
  X_NET_WM_STATE_SKIP_TASKBAR = XInternAtom(dpy, "_NET_WM_STATE_SKIP_TASKBAR", False);
  X_NET_WM_STRUT_PARTIAL = XInternAtom(dpy, "_NET_WM_STRUT_PARTIAL", False);
  X_NET_WM_WINDOW_TYPE = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", False);
  X_NET_WM_WINDOW_TYPE_DOCK = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DOCK", False);

  return self;
}

- (Window) xwindow
{
  if (!win)
  {
    win = (Window)[server windowDevice: [self windowNumber]];
  }
  return win;
}

- (void) setDesktop: (int) desktop
{
  /* stay in all desktops */
  XClientMessageEvent *xev = calloc(1, sizeof(XClientMessageEvent));
  xev->type = ClientMessage;
  xev->window = [self xwindow];
  xev->message_type = X_NET_WM_DESKTOP;
  xev->format = 32;
  xev->data.l[0] = desktop;
  xev->data.l[1] = 0; // just in case
  xev->data.l[2] = 0;
  xev->data.l[3] = 0;
  XSendEvent(dpy, root_win, False, 
	     (SubstructureNotifyMask|SubstructureRedirectMask), (XEvent *)xev);
  XFree(xev);

  /* and in case window manager is not running */
  XChangeProperty(dpy, [self xwindow], X_NET_WM_DESKTOP, XA_CARDINAL, 32,
		  PropModeReplace, (unsigned char*)&desktop, 1);

}

- (void) skipTaskbarAndPager
{
  Atom *state = calloc(2, sizeof(Atom));
  state[0] = X_NET_WM_STATE_SKIP_PAGER;
  state[1] = X_NET_WM_STATE_SKIP_TASKBAR;
  XChangeProperty(dpy, [self xwindow], X_NET_WM_STATE, XA_ATOM, 32,
		  PropModeReplace, (unsigned char *) state, 2);
  XFree(state);
}

- (void) reserveScreenAreaOn: (XScreenSide) side          
                       width: (int) width start: (int) start end: (int) end
{
  Atom *strut = calloc(12, sizeof(Atom));
  strut[0] = 0;
  strut[1] = 0;
  strut[2] = 0;
  strut[3] = 0;
  strut[4] = 0;
  strut[5] = 0;
  strut[6] = 0;
  strut[7] = 0;
  strut[8] = 0;
  strut[9] = 0;
  strut[10] = 0;
  strut[11] = 0;
  switch(side) {
    case XScreenLeftSide:
      strut[0] = width;
      strut[4] = start;
      strut[5] = end;
      break;
    case XScreenRightSide:
      strut[1] = width;
      strut[6] = start;
      strut[7] = end;
      break;
    case XScreenTopSide:
      strut[2] = width;
      strut[8] = start;
      strut[9] = end;
      break;
    case XScreenBottomSide:
      strut[3] = width;
      strut[10] = start;
      strut[11] = end;
      break;
  }
  XChangeProperty(dpy, [self xwindow], X_NET_WM_STRUT_PARTIAL, XA_CARDINAL, 32,
		  PropModeReplace, (unsigned char *)strut, 12);
  XFree(strut);
}

- (void) setAsSystemDock
{
  Atom *state = calloc(1, sizeof(Atom));
  state[0] = X_NET_WM_WINDOW_TYPE_DOCK;
  XChangeProperty(dpy, [self xwindow], X_NET_WM_WINDOW_TYPE, XA_ATOM, 32,
		  PropModeReplace, (unsigned char *) state, 1);
  XFree(state);
}

@end
