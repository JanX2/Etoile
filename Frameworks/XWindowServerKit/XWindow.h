/*
   XWindow.h for XWindowServerKit
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

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>
#import <X11/Xlib.h>

#define ALL_DESKTOP (0xFFFFFFFF)

/* allow accessing xwindow system */
@interface XWindow: NSWindow
{
  GSDisplayServer *server;
  Display *dpy;
  int screen;
  Window root_win, win;

  /* Atom */
  Atom X_NET_WM_DESKTOP;
  Atom X_NET_WM_STATE;
  Atom X_NET_WM_STATE_SKIP_PAGER;
  Atom X_NET_WM_STATE_SKIP_TASKBAR;
}

/* If defer is NO when window is created. 
 * xwindow doesn't not exist until it is ordered front.
 * Better to set defer YES all the time. */
- (Window) xwindow;

/* Use ALL_DESTKTOP for all desktops */
- (void) setDesktop: (int) desktop;

/* Skip taskbar and pager */
- (void) skipTaskbarAndPager;

@end
