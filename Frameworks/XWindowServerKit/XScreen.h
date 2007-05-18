/*
   XScreen.h for XWindowServerKit
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

/* When current desktop changed, Azalea will send this notification 
 * through distributed notification center */
extern NSString *XCurrentWorkspaceDidChangeNotification;

#define ALL_DESKTOP (0xFFFFFFFF)

typedef enum _XScreenSide {
  XScreenLeftSide,
  XScreenRightSide,
  XScreenTopSide,
  XScreenBottomSide
} XScreenSide;

/* allow accessing xwindow system */
@interface NSScreen (XScreen)

/* Return current number of workspaces.
 * see NET_NUMBER_OF_DESKTOPS. */
- (int) numberOfWorkspaces;

/* Return available names of workspaces.
 * The number of names may not match the -numberOfWorkspaces.
 * See NET_DESKTOP_NAMES. */
- (NSArray *) namesOfWorkspaces;

/* NET_CURRENT_WORKSPACE */
- (void) setCurrentWorkspace: (int) workspace;
- (int) currentWorkspace;

/* _NET_SHOWING_DESKTOP */
- (BOOL) isShowingDesktop;
- (void) setShowingDesktop:(BOOL) flag;

@end
