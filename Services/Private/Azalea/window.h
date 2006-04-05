/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

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

#ifndef __window__
#define __window__

#import <X11/Xlib.h>
#import <glib.h>

typedef enum {
    Window_Menu,
    Window_Dock,
    Window_DockApp, /* used for events but not stacking */
    Window_Client,
    Window_Internal /* used for stacking but not events */
} Window_InternalType;

typedef struct _ObWindow ObWindow;
typedef struct _ObInternalWindow ObInternalWindow;

struct _ObWindow
{
    Window_InternalType type;
};

/* Wrapper for internal stuff. If its struct matches this then it can be used
   as an ObWindow */
typedef struct InternalWindow {
    ObWindow obwin;
    Window win;
} InternalWindow;

#define WINDOW_IS_MENU(win) (((ObWindow*)win)->type == Window_Menu)
#define WINDOW_IS_DOCK(win) (((ObWindow*)win)->type == Window_Dock)
#define WINDOW_IS_DOCKAPP(win) (((ObWindow*)win)->type == Window_DockApp)
#define WINDOW_IS_CLIENT(win) (((ObWindow*)win)->type == Window_Client)
#define WINDOW_IS_INTERNAL(win) (((ObWindow*)win)->type == Window_Internal)

struct _ObMenu;
struct _ObDockApp;
struct _ObClient;
struct _AZDockStruct;
struct _AZDockAppStruct;

#define WINDOW_AS_MENU(win) ((struct _ObMenuFrame*)win)
#define WINDOW_AS_DOCK(win) (((struct _AZDockStruct*)win)->dock)
#define WINDOW_AS_DOCKAPP(win) (((struct _AZDockAppStruct*)win)->dock_app)
#define WINDOW_AS_CLIENT(win) ((struct _ObClient*)win)
#define WINDOW_AS_INTERNAL(win) ((struct InternalWindow*)win)

#define MENU_AS_WINDOW(menu) ((ObWindow*)menu)
#define DOCK_AS_WINDOW(dock) ((ObWindow*)dock)
#define DOCKAPP_AS_WINDOW(dockapp) ((ObWindow*)dockapp)
#define CLIENT_AS_WINDOW(client) ((ObWindow*)client)
#define INTERNAL_AS_WINDOW(intern) ((ObWindow*)intern)

extern GHashTable *window_map;

void window_startup(gboolean reconfig);
void window_shutdown(gboolean reconfig);

Window window_top(ObWindow *self);
Window window_layer(ObWindow *self);

#endif
