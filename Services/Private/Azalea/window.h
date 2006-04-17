/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   window.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   window.h for the Openbox window manager
   Copyright (c) 2003        Ben Jansens

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   See the COPYING file for a copy of the GNU General Public License.
*/

#import <Foundation/Foundation.h>
#import <X11/Xlib.h>

typedef enum {
    Window_Menu,
    Window_Dock,
    Window_DockApp, /* used for events but not stacking */
    Window_Client,
    Window_Internal /* used for stacking but not events */
} Window_InternalType;

@protocol AZWindow <NSObject>
- (Window_InternalType) windowType;
- (Window) windowTop;
- (int) windowLayer; /* ObStackingLayer */
@end

@interface AZInternalWindow: NSObject <AZWindow>
{
  Window window;
}
- (Window) window;
- (void) set_window: (Window) window;
@end

#define WINDOW_IS_MENU(win) ([((id <AZWindow>)(win)) windowType] == Window_Menu)
#define WINDOW_IS_DOCK(win) ([((id <AZWindow>)(win)) windowType] == Window_Dock)
#define WINDOW_IS_DOCKAPP(win) ([((id <AZWindow>)(win)) windowType] == Window_DockApp)
#define WINDOW_IS_CLIENT(win) ([((id <AZWindow>)(win)) windowType] == Window_Client)
#define WINDOW_IS_INTERNAL(win) ([((id <AZWindow>)(win)) windowType] == Window_Internal)

extern NSMutableDictionary *window_map;

void window_startup(BOOL reconfig);
void window_shutdown(BOOL reconfig);

