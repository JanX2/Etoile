// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   frame.h for the Openbox window manager
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
#import "geom.h"
#import "render/render.h"

typedef struct _ObFrame ObFrame;

typedef enum {
    OB_FRAME_CONTEXT_NONE,
    OB_FRAME_CONTEXT_DESKTOP,
    OB_FRAME_CONTEXT_CLIENT,
    OB_FRAME_CONTEXT_TITLEBAR,
    OB_FRAME_CONTEXT_HANDLE,
    OB_FRAME_CONTEXT_FRAME,
    OB_FRAME_CONTEXT_BLCORNER,
    OB_FRAME_CONTEXT_BRCORNER,
    OB_FRAME_CONTEXT_TLCORNER,
    OB_FRAME_CONTEXT_TRCORNER,
    OB_FRAME_CONTEXT_MAXIMIZE,
    OB_FRAME_CONTEXT_ALLDESKTOPS,
    OB_FRAME_CONTEXT_SHADE,
    OB_FRAME_CONTEXT_ICONIFY,
    OB_FRAME_CONTEXT_ICON,
    OB_FRAME_CONTEXT_CLOSE,
    /*! This is a special context, which occurs while dragging a window in
      a move/resize */
    OB_FRAME_CONTEXT_MOVE_RESIZE,
    OB_FRAME_NUM_CONTEXTS
} ObFrameContext;

/*! The decorations the client window wants to be displayed on it */
typedef enum {
    OB_FRAME_DECOR_TITLEBAR    = 1 << 0, /*!< Display a titlebar */
    OB_FRAME_DECOR_HANDLE      = 1 << 1, /*!< Display a handle (bottom) */
    OB_FRAME_DECOR_GRIPS       = 1 << 2, /*!< Display grips in the handle */
    OB_FRAME_DECOR_BORDER      = 1 << 3, /*!< Display a border */
    OB_FRAME_DECOR_ICON        = 1 << 4, /*!< Display the window's icon */
    OB_FRAME_DECOR_ICONIFY     = 1 << 5, /*!< Display an iconify button */
    OB_FRAME_DECOR_MAXIMIZE    = 1 << 6, /*!< Display a maximize button */
    /*! Display a button to toggle the window's placement on
      all desktops */
    OB_FRAME_DECOR_ALLDESKTOPS = 1 << 7,
    OB_FRAME_DECOR_SHADE       = 1 << 8, /*!< Displays a shade button */
    OB_FRAME_DECOR_CLOSE       = 1 << 9  /*!< Display a close button */
} ObFrameDecorations;

@class AZClient;

@interface AZFrame: NSObject
{
  AZClient *_client;

  Strut     size;
  Rect      area;
  Strut     innersize;

  BOOL visible;

  /*! Whether the window is obscured at all or fully visible. */
  BOOL obscured;

  unsigned int decorations;
  BOOL max_horz;

  Window    window;
  Window    plate;

  Window    title;
  Window    label;
  Window    max;
  Window    close;
  Window    desk;
  Window    shade;
  Window    icon;
  Window    iconify;
  Window    handle;
  Window    lgrip;
  Window    rgrip;

  Window    tlresize;
  Window    trresize;

  AZAppearance *a_unfocused_title;
  AZAppearance *a_focused_title;
  AZAppearance *a_unfocused_label;
  AZAppearance *a_focused_label;
  AZAppearance *a_icon;
  AZAppearance *a_unfocused_handle;
  AZAppearance *a_focused_handle;

  int      width;         /* title and handle */
  int      label_width;
  int      icon_x;        /* x-position of the window icon button */
  int      label_x;       /* x-position of the window title */
  int      iconify_x;     /* x-position of the window iconify button */
  int      desk_x;        /* x-position of the window all-desktops button */
  int      shade_x;       /* x-position of the window shade button */
  int      max_x;         /* x-position of the window maximize button */
  int      close_x;       /* x-position of the window close button */
  int      bwidth;        /* border width */
  int      rbwidth;       /* title border width */
  int      cbwidth_x;     /* client border width */
  int      cbwidth_y;     /* client border width */
  
  BOOL max_press;
  BOOL close_press;
  BOOL desk_press;
  BOOL shade_press;
  BOOL iconify_press;
  BOOL max_hover;
  BOOL close_hover;
  BOOL desk_hover;
  BOOL shade_hover;
  BOOL iconify_hover;

  BOOL focused;

  BOOL flashing;
  BOOL flash_on;
  GTimeVal flash_end;
}

- (void) grabClient: (AZClient *) client;
- (void) releaseClient: (AZClient *) client;

- (void) show;
- (void) hide;

- (void) adjustTheme;
- (void) adjustShape;
- (void) adjustState;
- (void) adjustFocusWithHilite: (BOOL) hilite;
- (void) adjustTitle;
- (void) adjustIcon;
- (void) adjustAreaWithMoved: (BOOL) moved resized: (BOOL) resized fake: (BOOL) fake;

/*! Applies gravity to the client's position to find where the frame should
 *  be positioned.
 *  @return The proper coordinates for the frame, based on the client.
 */
- (void) clientGravityAtX: (int *) x y: (int *) y;

/*! Reversly applies gravity to the frame's position to find where the client
 *  should be positioned.
 *  @return The proper coordinates for the client, based on the frame.
 */
- (void) frameGravityAtX: (int *) x y: (int *) y;

- (void) flashStart;
- (void) flashStop;

/* accessories */
- (AZClient *) client;
- (void) setClient: (AZClient *) client;

- (Window) window;
- (Window) plate;
- (Window) title;
- (Window) label;
- (Window) max;
- (Window) close;
- (Window) desk;
- (Window) shade;
- (Window) icon;
- (Window) iconify;
- (Window) handle;
- (Window) lgrip;
- (Window) rgrip;
- (Window) tlresize;
- (Window) trresize;

- (BOOL) max_press;
- (BOOL) close_press;
- (BOOL) desk_press;
- (BOOL) shade_press;
- (BOOL) iconify_press;
- (BOOL) max_hover;
- (BOOL) close_hover;
- (BOOL) desk_hover;
- (BOOL) shade_hover;
- (BOOL) iconify_hover;
- (BOOL) focused;
- (void) set_max_press: (BOOL) b;
- (void) set_close_press: (BOOL) b;
- (void) set_desk_press: (BOOL) b;
- (void) set_shade_press: (BOOL) b;
- (void) set_iconify_press: (BOOL) b;
- (void) set_max_hover: (BOOL) b;
- (void) set_close_hover: (BOOL) b;
- (void) set_desk_hover: (BOOL) b;
- (void) set_shade_hover: (BOOL) b;
- (void) set_iconify_hover: (BOOL) b;
- (void) set_focused: (BOOL) b;

- (BOOL) obscured;
- (BOOL) visible;
- (unsigned int) decorations;
- (BOOL) max_horz;
- (void) set_obscured: (BOOL) b;

- (Strut) size;
- (Rect) area;
- (Strut) innersize;
- (void) setArea: (Rect) area;

@end

ObFrameContext frame_context_from_string(const gchar *name);
ObFrameContext frame_context(AZClient *self, Window win);

