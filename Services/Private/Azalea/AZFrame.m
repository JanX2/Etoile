// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   frame.c for the Openbox window manager
   Copyright (c) 2004        Mikael Magnusson
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

#import "AZFrame.h"
#import "AZFrame+Render.h"
#import "AZMainLoop.h"
#import "openbox.h"
#import "AZClient.h"
#import "AZMoveResizeHandler.h"
#import "AZFocusManager.h"
#import "prop.h"
#import "config.h"
#import "extensions.h"

#define PLATE_EVENTMASK (SubstructureRedirectMask | ButtonPressMask)
#define FRAME_EVENTMASK (EnterWindowMask | LeaveWindowMask | \
                         ButtonPressMask | ButtonReleaseMask | \
                         VisibilityChangeMask)
#define ELEMENT_EVENTMASK (ButtonPressMask | ButtonReleaseMask | \
                           ButtonMotionMask | ExposureMask | \
                           EnterWindowMask | LeaveWindowMask)

#define FRAME_HANDLE_Y(f) (innersize.top + [_client area].height + cbwidth_y)

static Window createWindow(Window parent, Visual *visual,
                           unsigned long mask, XSetWindowAttributes *attrib)
{
    return XCreateWindow(ob_display, parent, 0, 0, 1, 1, 0,
                         (visual ? 32 : [ob_rr_inst depth]), InputOutput,
                         (visual ? visual : [ob_rr_inst visual]),
                         mask, attrib);
}

static Visual *check_32bit_client(AZClient *c)
{
    XWindowAttributes wattrib;
    Status ret;

    ret = XGetWindowAttributes(ob_display, [c window], &wattrib);
    if (ret == BadDrawable)
      NSLog(@"Error: Bad Drawable");
    if (ret == BadWindow)
      NSLog(@"Error: Bad Window");

    if (wattrib.depth == 32)
        return wattrib.visual;
    return NULL;
}


@interface AZFrame (AZPrivate)
- (void) layoutTitle;
- (void) setThemeStatics;
- (void) freeThemeStatics;
- (void) setFrameExtents; /* Set _NET_FRAME_EXTENTS */

/* callback */
- (BOOL) flashTimeout: (id) data;
- (void) flashDone: (id) data;
@end

@implementation AZFrame

- (void) grabClient: (AZClient *) client
{
    _client = client;

    /* reparent the client to the frame */
    XReparentWindow(ob_display, [client window], plate, 0, 0);
    /*
      When reparenting the client window, it is usually not mapped yet, since
      this occurs from a MapRequest. However, in the case where Openbox is
      starting up, the window is already mapped, so we'll see unmap events for
      it. There are 2 unmap events generated that we see, one with the 'event'
      member set the root window, and one set to the client, but both get
      handled and need to be ignored.
    */
    if (ob_state() == OB_STATE_STARTING)
        [client set_ignore_unmaps: [client ignore_unmaps]+2];

    /* select the event mask on the client's parent (to receive config/map
       req's) the ButtonPress is to catch clicks on the client border */
    XSelectInput(ob_display, plate, PLATE_EVENTMASK);

    /* map the client so it maps when the frame does */
    XMapWindow(ob_display, [client window]);

    [self adjustAreaWithMoved: YES resized: YES fake: NO];
    [self setFrameExtents];

    /* set all the windows for the frame in the window_map */
    [window_map setObject: client forKey: [NSNumber numberWithInt: window]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: plate]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: title]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: label]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: max]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: close]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: desk]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: shade]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: icon]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: iconify]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: handle]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: lgrip]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: rgrip]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: tlresize]];
    [window_map setObject: client forKey: [NSNumber numberWithInt: trresize]];
}

- (void) releaseClient: (AZClient *) client
{
    XEvent ev;
    BOOL reparent = YES;

    NSAssert(_client == client, @"Release wrong client");

    /* check if the app has already reparented its window away */
    while (XCheckTypedWindowEvent(ob_display, [client window],
                                  ReparentNotify, &ev))
    {
        /* This check makes sure we don't catch our own reparent action to
           our frame window. This doesn't count as the app reparenting itself
           away of course.

           Reparent events that are generated by us are just discarded here.
           They are of no consequence to us anyhow.
        */
        if (ev.xreparent.parent != plate) {
            reparent = NO;
            XPutBackEvent(ob_display, &ev);
            break;
        }
    }

    if (reparent) {
        /* according to the ICCCM - if the client doesn't reparent itself,
           then we will reparent the window to root for them */
        XReparentWindow(ob_display, [client window],
                        RootWindow(ob_display, ob_screen),
                        [client area].x,
                        [client area].y);
    }

    /* remove all the windows for the frame from the window_map */
    [window_map removeObjectForKey: [NSNumber numberWithInt: window]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: plate]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: title]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: label]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: max]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: close]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: desk]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: shade]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: icon]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: iconify]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: handle]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: lgrip]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: rgrip]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: tlresize]];
    [window_map removeObjectForKey: [NSNumber numberWithInt: trresize]];

    [[AZMainLoop mainLoop] removeTimeout: self 
	                         handler: @selector(flashTimeout:)
	                            data: self cancel: YES];

    /* These two lines are from frame_free(). 
     * And obFrame is released in dealloc;
     */
    [self freeThemeStatics];
    XDestroyWindow(ob_display, window);
    if (colormap)
      XFreeColormap(ob_display, colormap);
}

- (void) show
{
    if (!visible) {
        visible = YES;
        XMapWindow(ob_display, [_client window]);
        XMapWindow(ob_display, window);
    }
}

- (void) hide
{
    if (visible) {
        visible = NO;
        [_client set_ignore_unmaps: [_client ignore_unmaps]+2];
        /* we unmap the client itself so that we can get MapRequest
           events, and because the ICCCM tells us to! */
        XUnmapWindow(ob_display, window);
        XUnmapWindow(ob_display, [_client window]);
    }
}

- (void) adjustTheme
{
  [self freeThemeStatics];
  [self setThemeStatics];
}

- (void) adjustShape
{
#ifdef SHAPE
    int num;
    XRectangle xrect[2];

    if (![_client shaped]) {
        /* clear the shape on the frame window */
        XShapeCombineMask(ob_display, window, ShapeBounding,
                          innersize.left,
                          innersize.top,
                          None, ShapeSet);
    } else {
        /* make the frame's shape match the clients */
        XShapeCombineShape(ob_display, window, ShapeBounding,
                           innersize.left,
                           innersize.top,
                           [_client window],
                           ShapeBounding, ShapeSet);

        num = 0;
        if (decorations & OB_FRAME_DECOR_TITLEBAR) {
            xrect[0].x = -ob_rr_theme->bwidth;
            xrect[0].y = -ob_rr_theme->bwidth;
            xrect[0].width = width + rbwidth * 2;
            xrect[0].height = ob_rr_theme->title_height + bwidth * 2;
            ++num;
        }

        if (decorations & OB_FRAME_DECOR_HANDLE) {
            xrect[1].x = -ob_rr_theme->bwidth;
            xrect[1].y = FRAME_HANDLE_Y(self);
            xrect[1].width = width + rbwidth * 2;
            xrect[1].height = ob_rr_theme->handle_height + bwidth * 2;
            ++num;
        }

        XShapeCombineRectangles(ob_display, window,
                                ShapeBounding, 0, 0, xrect, num,
                                ShapeUnion, Unsorted);
    }
#endif
}

- (void) adjustState
{
  [self render];
}

- (void) adjustFocusWithHilite: (BOOL) hilite
{
  focused = hilite;
  [self render];
}

- (void) adjustTitle
{
  [self render];
}

- (void) adjustIcon
{
  [self render];
}

- (void) adjustAreaWithMoved: (BOOL) moved resized: (BOOL) resized 
                        fake: (BOOL) fake
{
    Strut oldsize;

    oldsize = size;

    if (resized) {
        decorations = [_client decorations];
        max_horz = [_client max_horz];

        if (decorations & OB_FRAME_DECOR_BORDER) {
            bwidth = ob_rr_theme->bwidth;
            cbwidth_x = cbwidth_y = ob_rr_theme->cbwidth;
        } else {
            bwidth = cbwidth_x = cbwidth_y = 0;
        }
        rbwidth = bwidth;

        if (max_horz)
            bwidth = cbwidth_x = 0;

        STRUT_SET(innersize,
                  cbwidth_x, cbwidth_y,
                  cbwidth_x, cbwidth_y);
        width = [_client area].width + cbwidth_x * 2 -
            (max_horz ? rbwidth * 2 : 0);
        width = MAX(width, 1); /* no lower than 1 */

        /* set border widths */
        if (!fake) {
            XSetWindowBorderWidth(ob_display, window, bwidth);
            XSetWindowBorderWidth(ob_display, title,  rbwidth);
            XSetWindowBorderWidth(ob_display, handle, rbwidth);
            XSetWindowBorderWidth(ob_display, lgrip,  rbwidth);
            XSetWindowBorderWidth(ob_display, rgrip,  rbwidth);
        }

        if (decorations & OB_FRAME_DECOR_TITLEBAR)
            innersize.top += ob_rr_theme->title_height + rbwidth +
                (rbwidth - bwidth);
        if (decorations & OB_FRAME_DECOR_HANDLE &&
            ob_rr_theme->show_handle)
            innersize.bottom += ob_rr_theme->handle_height +
                rbwidth + (rbwidth - bwidth);
  
        /* they all default off, they're turned on in layout_title */
        icon_x = -1;
        desk_x = -1;
        shade_x = -1;
        iconify_x = -1;
        label_x = -1;
        max_x = -1;
        close_x = -1;

        /* position/size and map/unmap all the windows */

        if (!fake) {
            if (decorations & OB_FRAME_DECOR_TITLEBAR) {
                XMoveResizeWindow(ob_display, title,
                                  -bwidth, -bwidth,
                                  width, ob_rr_theme->title_height);
                XMapWindow(ob_display, title);

                if (decorations & OB_FRAME_DECOR_GRIPS) {
                    XMoveWindow(ob_display, tlresize, 0, 0);
                    XMoveWindow(ob_display, trresize,
                                width - ob_rr_theme->grip_width, 0);
                    XMapWindow(ob_display, tlresize);
                    XMapWindow(ob_display, trresize);
                } else {
                    XUnmapWindow(ob_display, tlresize);
                    XUnmapWindow(ob_display, trresize);
                }
            } else
                XUnmapWindow(ob_display, title);
        }

        if (decorations & OB_FRAME_DECOR_TITLEBAR)
            /* layout the title bar elements */
	    [self layoutTitle];

        if (!fake) {
            if (decorations & OB_FRAME_DECOR_HANDLE &&
                ob_rr_theme->show_handle)
            {
                XMoveResizeWindow(ob_display, handle,
                                  -bwidth, FRAME_HANDLE_Y(self),
                                  width, ob_rr_theme->handle_height);
                XMapWindow(ob_display, handle);

                if (decorations & OB_FRAME_DECOR_GRIPS) {
                    XMoveWindow(ob_display, lgrip, -rbwidth, -rbwidth);
                    XMoveWindow(ob_display, rgrip, -rbwidth + width -
                                ob_rr_theme->grip_width, -rbwidth);
                    XMapWindow(ob_display, lgrip);
                    XMapWindow(ob_display, rgrip);
                } else {
                    XUnmapWindow(ob_display, lgrip);
                    XUnmapWindow(ob_display, rgrip);
                }
            } else
                XUnmapWindow(ob_display, handle);

            /* move and resize the plate */
            XMoveResizeWindow(ob_display, plate,
                              innersize.left - cbwidth_x,
                              innersize.top - cbwidth_y,
                              [_client area].width + cbwidth_x * 2,
                              [_client area].height + cbwidth_y * 2);
            /* when the client has StaticGravity, it likes to move around. */
            XMoveWindow(ob_display, [_client window], cbwidth_x, cbwidth_y);
        }

        STRUT_SET(size, innersize.left + bwidth, innersize.top + bwidth,
                  innersize.right + bwidth, innersize.bottom + bwidth);
    }

    /* shading can change without being moved or resized */
    RECT_SET_SIZE(area, [_client area].width +
                  size.left + size.right,
                  ([_client shaded] ?  ob_rr_theme->title_height + rbwidth * 2:
                   [_client area].height + size.top + size.bottom));

    if (moved) {
        /* find the new coordinates, done after setting the frame.size, for
           frame_client_gravity. */
        area.x = [_client area].x;
        area.y = [_client area].y;
	[self clientGravityAtX: &(area.x) y: &(area.y)];
    }

    if (!fake) {
        /* move and resize the top level frame.
           shading can change without being moved or resized */
        XMoveResizeWindow(ob_display, window, area.x, area.y,
                          area.width - bwidth * 2, area.height - bwidth * 2);

        if (resized) {
	    [self render];
	    [self adjustShape];
        }

        if (!STRUT_EQUAL(size, oldsize)) {
            unsigned long vals[4];
            vals[0] = size.left;
            vals[1] = size.right;
            vals[2] = size.top;
            vals[3] = size.bottom;
            PROP_SETA32([_client window], kde_net_wm_frame_strut,
                        cardinal, vals, 4);
        }

        /* if this occurs while we are focus cycling, the indicator needs to
           match the changes */
	AZFocusManager *fManager = [AZFocusManager defaultManager];
	if ([fManager focus_cycle_target] == _client)
	   [fManager cycleDrawIndicator];
    }
    if (resized && (decorations & OB_FRAME_DECOR_TITLEBAR))
        XResizeWindow(ob_display, label, label_width,
                      ob_rr_theme->label_height);
}

- (void) clientGravityAtX: (int *) x y: (int *) y
{
    /* horizontal */
    switch ([_client gravity]) {
    default:
    case NorthWestGravity:
    case SouthWestGravity:
    case WestGravity:
        break;

    case NorthGravity:
    case SouthGravity:
    case CenterGravity:
        *x -= (size.left + size.right) / 2;
        break;

    case NorthEastGravity:
    case SouthEastGravity:
    case EastGravity:
        *x -= size.left + size.right;
        break;

    case ForgetGravity:
    case StaticGravity:
        *x -= size.left;
        break;
    }

    /* vertical */
    switch ([_client gravity]) {
    default:
    case NorthWestGravity:
    case NorthEastGravity:
    case NorthGravity:
        break;

    case CenterGravity:
    case EastGravity:
    case WestGravity:
        *y -= (size.top + size.bottom) / 2;
        break;

    case SouthWestGravity:
    case SouthEastGravity:
    case SouthGravity:
        *y -= size.top + size.bottom;
        break;

    case ForgetGravity:
    case StaticGravity:
        *y -= size.top;
        break;
    }
}

- (void) frameGravityAtX: (int *) x y: (int *) y
{
    /* horizontal */
    switch ([_client gravity]) {
    default:
    case NorthWestGravity:
    case WestGravity:
    case SouthWestGravity:
        break;
    case NorthGravity:
    case CenterGravity:
    case SouthGravity:
        *x += (size.left + size.right) / 2;
        break;
    case NorthEastGravity:
    case EastGravity:
    case SouthEastGravity:
        *x += size.left + size.right;
        break;
    case StaticGravity:
    case ForgetGravity:
        *x += size.left;
        break;
    }

    /* vertical */
    switch ([_client gravity]) {
    default:
    case NorthWestGravity:
    case NorthGravity:
    case NorthEastGravity:
        break;
    case WestGravity:
    case CenterGravity:
    case EastGravity:
        *y += (size.top + size.bottom) / 2;
        break;
    case SouthWestGravity:
    case SouthGravity:
    case SouthEastGravity:
        *y += size.top + size.bottom;
        break;
    case StaticGravity:
    case ForgetGravity:
        *y += size.top;
        break;
    }
}

- (void) flashStart
{
    flash_on = focused;

    if (!flashing)
    {
      [[AZMainLoop mainLoop] addTimeout: self 
	                     handler: @selector(flashTimeout:)
	                     microseconds: USEC_PER_SEC * 0.6
			     data: self 
			     notify: @selector(flashDone:)];
    }
    gettimeofday(&flash_end, NULL);
    time_val_add(&flash_end, USEC_PER_SEC * 5);
    
    flashing = YES;
}

- (void) flashStop
{
    flashing = NO;
}

- (id) initWithClient: (AZClient *) client
{
  self = [super init];

  XSetWindowAttributes attrib;
  unsigned long mask;
  Visual *visual;

  obscured = YES;

  visual = check_32bit_client(client);

  /* create the non-visible decor windows */

  mask = CWEventMask;
  if (visual) {
    /* client has a 32-bit visual */
    mask |= CWColormap | CWBackPixel | CWBorderPixel;
    /* create a colormap with the visual */
    colormap = attrib.colormap =
        XCreateColormap(ob_display,
                        RootWindow(ob_display, ob_screen),
                        visual, AllocNone);
    attrib.background_pixel = BlackPixel(ob_display, 0);
    attrib.border_pixel = BlackPixel(ob_display, 0);
  }
  attrib.event_mask = FRAME_EVENTMASK;
  window = createWindow(RootWindow(ob_display, ob_screen), visual,
                                mask, &attrib);

  mask &= ~CWEventMask;
  plate = createWindow(window, visual, mask, &attrib);
  /* create the visible decor windows */

  mask = CWEventMask;
  if (visual) { 
    /* client has a 32-bit visual */
    mask |= CWColormap | CWBackPixel | CWBorderPixel;
    attrib.colormap = [ob_rr_inst colormap];
  }

  attrib.event_mask = ELEMENT_EVENTMASK;
  title = createWindow(window, NULL, mask, &attrib);


  mask |= CWCursor;
  attrib.cursor = ob_cursor(OB_CURSOR_NORTHWEST);
  tlresize = createWindow(title, NULL, mask, &attrib);
  attrib.cursor = ob_cursor(OB_CURSOR_NORTHEAST);
  trresize = createWindow(title, NULL, mask, &attrib);

  mask &= ~CWCursor;
  label = createWindow(title, NULL, mask, &attrib);
  max = createWindow(title, NULL, mask, &attrib);
  close = createWindow(title, NULL, mask, &attrib);
  desk = createWindow(title, NULL, mask, &attrib);
  shade = createWindow(title, NULL, mask, &attrib);
  icon = createWindow(title, NULL, mask, &attrib);
  iconify = createWindow(title, NULL, mask, &attrib);
  handle = createWindow(window, NULL, mask, &attrib);

  mask |= CWCursor;
  attrib.cursor = ob_cursor(OB_CURSOR_SOUTHWEST);
  lgrip = createWindow(handle, NULL, mask, &attrib);
  attrib.cursor = ob_cursor(OB_CURSOR_SOUTHEAST);
  rgrip = createWindow(handle, NULL, mask, &attrib); 

  focused = NO;

  /* the other stuff is shown based on decor settings */
  XMapWindow(ob_display, plate);
  XMapWindow(ob_display, lgrip);
  XMapWindow(ob_display, rgrip);
  XMapWindow(ob_display, label);

  max_press = close_press = desk_press = 
        iconify_press = shade_press = NO;
  max_hover = close_hover = desk_hover = 
        iconify_hover = shade_hover = NO;

  [self setThemeStatics];
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

/* accessories */
- (AZClient *) client { return _client; }
- (void) setClient: (AZClient *) client { _client = client; }

- (Window) window { return window; }
- (Window) plate { return plate; }
- (Window) title { return title; }
- (Window) label { return label; }
- (Window) max { return max; }
- (Window) close { return close; }
- (Window) desk { return desk; }
- (Window) shade { return shade; }
- (Window) icon { return icon; }
- (Window) iconify { return iconify; }
- (Window) handle { return handle; }
- (Window) lgrip { return lgrip; }
- (Window) rgrip { return rgrip; }
- (Window) tlresize { return tlresize; }
- (Window) trresize { return trresize; }

- (BOOL) max_press { return max_press; }
- (BOOL) close_press { return close_press; }
- (BOOL) desk_press { return desk_press; }
- (BOOL) shade_press { return shade_press; }
- (BOOL) iconify_press { return iconify_press; }
- (BOOL) max_hover { return max_hover; }
- (BOOL) close_hover { return close_hover; }
- (BOOL) desk_hover { return desk_hover; }
- (BOOL) shade_hover { return shade_hover; }
- (BOOL) iconify_hover { return iconify_hover; }
- (BOOL) focused { return focused; }
- (void) set_max_press: (BOOL) b { max_press = b; }
- (void) set_close_press: (BOOL) b { close_press = b; }
- (void) set_desk_press: (BOOL) b { desk_press = b; }
- (void) set_shade_press: (BOOL) b { shade_press = b; }
- (void) set_iconify_press: (BOOL) b { iconify_press = b; }
- (void) set_max_hover: (BOOL) b { max_hover = b; }
- (void) set_close_hover: (BOOL) b { close_hover = b; }
- (void) set_desk_hover: (BOOL) b { desk_hover = b; }
- (void) set_shade_hover: (BOOL) b { shade_hover = b; }
- (void) set_iconify_hover: (BOOL) b { iconify_hover = b; }
- (void) set_focused: (BOOL) b { focused = b; }

- (BOOL) obscured { return obscured; }
- (BOOL) visible { return visible; }
- (unsigned int) decorations { return decorations; }
- (BOOL) max_horz { return max_horz; }
- (void) set_obscured: (BOOL) b { obscured = b; }

- (Strut) size { return size; }
- (Rect) area { return area; }
- (Strut) innersize { return innersize; }
- (void) setArea: (Rect) a { area = a; }

@end

@implementation AZFrame (AZPrivate)
- (void) layoutTitle
{
    char *lc;
    int x;
    BOOL n, d, i, l, m, c, s;

    n = d = i = l = m = c = s = NO;

    /* figure out whats being shown, and the width of the label */
    label_width = width - (ob_rr_theme->padding + 1) * 2;
    for (lc = (char*)[config_title_layout cString]; *lc != '\0'; ++lc) {
        switch (*lc) {
        case 'N':
            if (n) { *lc = ' '; break; } /* rm duplicates */
            n = YES;
            label_width -= (ob_rr_theme->button_size + 2 +
                                  ob_rr_theme->padding + 1);
            break;
        case 'D':
            if (d) { *lc = ' '; break; }
            if (!(decorations & OB_FRAME_DECOR_ALLDESKTOPS) && config_theme_hidedisabled)
                break;
            d = YES;
            label_width -= (ob_rr_theme->button_size +
                                  ob_rr_theme->padding + 1);
            break;
        case 'S':
            if (s) { *lc = ' '; break; }
            if (!(decorations & OB_FRAME_DECOR_SHADE) && config_theme_hidedisabled)
                break;
            s = YES;
            label_width -= (ob_rr_theme->button_size +
                                  ob_rr_theme->padding + 1);
            break;
        case 'I':
            if (i) { *lc = ' '; break; }
            if (!(decorations & OB_FRAME_DECOR_ICONIFY) && config_theme_hidedisabled)
                break;
            i = YES;
            label_width -= (ob_rr_theme->button_size +
                                  ob_rr_theme->padding + 1);
            break;
        case 'L':
            if (l) { *lc = ' '; break; }
            l = YES;
            break;
        case 'M':
            if (m) { *lc = ' '; break; }
            if (!(decorations & OB_FRAME_DECOR_MAXIMIZE) && config_theme_hidedisabled)
                break;
            m = YES;
            label_width -= (ob_rr_theme->button_size +
                                  ob_rr_theme->padding + 1);
            break;
        case 'C':
            if (c) { *lc = ' '; break; }
            if (!(decorations & OB_FRAME_DECOR_CLOSE) && config_theme_hidedisabled)
                break;
            c = YES;
            label_width -= (ob_rr_theme->button_size +
                                  ob_rr_theme->padding + 1);
            break;
        }
    }
    if (label_width < 1) label_width = 1;

    if (!n) XUnmapWindow(ob_display, icon);
    if (!d) XUnmapWindow(ob_display, desk);
    if (!s) XUnmapWindow(ob_display, shade);
    if (!i) XUnmapWindow(ob_display, iconify);
    if (!l) XUnmapWindow(ob_display, label);
    if (!m) XUnmapWindow(ob_display, max);
    if (!c) XUnmapWindow(ob_display, close);

    x = ob_rr_theme->padding + 1;
    for (lc = (char*)[config_title_layout cString]; *lc != '\0'; ++lc) {
        switch (*lc) {
        case 'N':
            if (!n) break;
            icon_x = x;
            XMapWindow(ob_display, icon);
            XMoveWindow(ob_display, icon, x, ob_rr_theme->padding);
            x += ob_rr_theme->button_size + 2 + ob_rr_theme->padding + 1;
            break;
        case 'D':
            if (!d) break;
            desk_x = x;
            XMapWindow(ob_display, desk);
            XMoveWindow(ob_display, desk, x, ob_rr_theme->padding + 1);
            x += ob_rr_theme->button_size + ob_rr_theme->padding + 1;
            break;
        case 'S':
            if (!s) break;
            shade_x = x;
            XMapWindow(ob_display, shade);
            XMoveWindow(ob_display, shade, x, ob_rr_theme->padding + 1);
            x += ob_rr_theme->button_size + ob_rr_theme->padding + 1;
            break;
        case 'I':
            if (!i) break;
            iconify_x = x;
            XMapWindow(ob_display, iconify);
            XMoveWindow(ob_display, iconify, x, ob_rr_theme->padding + 1);
            x += ob_rr_theme->button_size + ob_rr_theme->padding + 1;
            break;
        case 'L':
            if (!l) break;
            label_x = x;
            XMapWindow(ob_display, label);
            XMoveWindow(ob_display, label, x, ob_rr_theme->padding);
            x += label_width + ob_rr_theme->padding + 1;
            break;
        case 'M':
            if (!m) break;
            max_x = x;
            XMapWindow(ob_display, max);
            XMoveWindow(ob_display, max, x, ob_rr_theme->padding + 1);
            x += ob_rr_theme->button_size + ob_rr_theme->padding + 1;
            break;
        case 'C':
            if (!c) break;
            close_x = x;
            XMapWindow(ob_display, close);
            XMoveWindow(ob_display, close, x, ob_rr_theme->padding + 1);
            x += ob_rr_theme->button_size + ob_rr_theme->padding + 1;
            break;
        }
    }
}

- (void) setThemeStatics
{
    /* set colors/appearance/sizes for stuff that doesn't change */
    XSetWindowBorder(ob_display, window,
                     RrColorPixel(ob_rr_theme->b_color));
    XSetWindowBorder(ob_display, title,
                     RrColorPixel(ob_rr_theme->b_color));
    XSetWindowBorder(ob_display, handle,
                     RrColorPixel(ob_rr_theme->b_color));
    XSetWindowBorder(ob_display, rgrip,
                     RrColorPixel(ob_rr_theme->b_color));
    XSetWindowBorder(ob_display, lgrip,
                     RrColorPixel(ob_rr_theme->b_color));

    XResizeWindow(ob_display, max,
                  ob_rr_theme->button_size, ob_rr_theme->button_size);
    XResizeWindow(ob_display, iconify,
                  ob_rr_theme->button_size, ob_rr_theme->button_size);
    XResizeWindow(ob_display, icon,
                  ob_rr_theme->button_size + 2, ob_rr_theme->button_size + 2);
    XResizeWindow(ob_display, close,
                  ob_rr_theme->button_size, ob_rr_theme->button_size);
    XResizeWindow(ob_display, desk,
                  ob_rr_theme->button_size, ob_rr_theme->button_size);
    XResizeWindow(ob_display, shade,
                  ob_rr_theme->button_size, ob_rr_theme->button_size);
    XResizeWindow(ob_display, lgrip,
                  ob_rr_theme->grip_width, ob_rr_theme->handle_height);
    XResizeWindow(ob_display, rgrip,
                  ob_rr_theme->grip_width, ob_rr_theme->handle_height);
    XResizeWindow(ob_display, tlresize,
                  ob_rr_theme->grip_width, ob_rr_theme->handle_height);
    XResizeWindow(ob_display, trresize,
                  ob_rr_theme->grip_width, ob_rr_theme->handle_height);

    /* set up the dynamic appearances */
    a_unfocused_title = [ob_rr_theme->a_unfocused_title copy];
    a_focused_title = [ob_rr_theme->a_focused_title copy];
    a_unfocused_label = [ob_rr_theme->a_unfocused_label copy];
    a_focused_label = [ob_rr_theme->a_focused_label copy];
    a_unfocused_handle = [ob_rr_theme->a_unfocused_handle copy];
    a_focused_handle = [ob_rr_theme->a_focused_handle copy];
    a_icon = [ob_rr_theme->a_icon copy];
}

- (void) setFrameExtents /* Set _NET_FRAME_EXTENTS */
{
  unsigned long *extents = calloc(sizeof(unsigned long), 4);
  extents[0] = innersize.left+bwidth;
  extents[1] = innersize.right+bwidth;
  extents[2] = innersize.top+bwidth;
  extents[3] = innersize.bottom+bwidth;
  PROP_SETA32([_client window], net_frame_extents, cardinal, extents, 4);
  free(extents);
}

- (void) freeThemeStatics
{
    DESTROY(a_unfocused_title); 
    DESTROY(a_focused_title);
    DESTROY(a_unfocused_label);

    DESTROY(a_focused_label);
    DESTROY(a_unfocused_handle);
    DESTROY(a_focused_handle);
    DESTROY(a_icon);
}

- (void) flashDone: (id) data
{
    if (focused != flash_on)
      [self adjustFocusWithHilite: focused];
}

- (BOOL) flashTimeout: (id) data
{
    struct timeval now;

    gettimeofday(&now, NULL);
    if (now.tv_sec > flash_end.tv_sec ||
        (now.tv_sec == flash_end.tv_sec &&
         now.tv_usec >= flash_end.tv_usec))
        flashing = NO;

    if (!flashing)
        return NO; /* we are done */

    flash_on = !flash_on;
    if (!focused) {
	[self adjustFocusWithHilite: flash_on];
        focused = NO;
    }

    return YES; /* go again */
}
@end

ObFrameContext frame_context_from_string(const char *name)
{
    if (!strcasecmp("Desktop", name))
        return OB_FRAME_CONTEXT_DESKTOP;
    else if (!strcasecmp("Client", name))
        return OB_FRAME_CONTEXT_CLIENT;
    else if (!strcasecmp("Titlebar", name))
        return OB_FRAME_CONTEXT_TITLEBAR;
    else if (!strcasecmp("Handle", name))
        return OB_FRAME_CONTEXT_HANDLE;
    else if (!strcasecmp("Frame", name))
        return OB_FRAME_CONTEXT_FRAME;
    else if (!strcasecmp("TLCorner", name))
        return OB_FRAME_CONTEXT_TLCORNER;
    else if (!strcasecmp("TRCorner", name))
        return OB_FRAME_CONTEXT_TRCORNER;
    else if (!strcasecmp("BLCorner", name))
        return OB_FRAME_CONTEXT_BLCORNER;
    else if (!strcasecmp("BRCorner", name))
        return OB_FRAME_CONTEXT_BRCORNER;
    else if (!strcasecmp("Maximize", name))
        return OB_FRAME_CONTEXT_MAXIMIZE;
    else if (!strcasecmp("AllDesktops", name))
        return OB_FRAME_CONTEXT_ALLDESKTOPS;
    else if (!strcasecmp("Shade", name))
        return OB_FRAME_CONTEXT_SHADE;
    else if (!strcasecmp("Iconify", name))
        return OB_FRAME_CONTEXT_ICONIFY;
    else if (!strcasecmp("Icon", name))
        return OB_FRAME_CONTEXT_ICON;
    else if (!strcasecmp("Close", name))
        return OB_FRAME_CONTEXT_CLOSE;
    else if (!strcasecmp("MoveResize", name))
        return OB_FRAME_CONTEXT_MOVE_RESIZE;
    return OB_FRAME_CONTEXT_NONE;
}

ObFrameContext frame_context(AZClient *client, Window win)
{

    if([[AZMoveResizeHandler defaultHandler] moveresize_in_progress])
        return OB_FRAME_CONTEXT_MOVE_RESIZE;

    if (win == RootWindow(ob_display, ob_screen))
        return OB_FRAME_CONTEXT_DESKTOP;
    if (client == NULL) return OB_FRAME_CONTEXT_NONE;
    if (win == [client window]) {
        /* conceptually, this is the desktop, as far as users are
           concerned */
        if ([client type] == OB_CLIENT_TYPE_DESKTOP)
            return OB_FRAME_CONTEXT_DESKTOP;
        return OB_FRAME_CONTEXT_CLIENT;
    }

    if (win == [[client frame] plate]) {
        /* conceptually, this is the desktop, as far as users are
           concerned */
        if ([client type] == OB_CLIENT_TYPE_DESKTOP)
            return OB_FRAME_CONTEXT_DESKTOP;
        return OB_FRAME_CONTEXT_CLIENT;
    }

    if (win == [[client frame] window])   return OB_FRAME_CONTEXT_FRAME;
    if (win == [[client frame] title])    return OB_FRAME_CONTEXT_TITLEBAR;
    if (win == [[client frame] label])    return OB_FRAME_CONTEXT_TITLEBAR;
    if (win == [[client frame] handle])   return OB_FRAME_CONTEXT_HANDLE;
    if (win == [[client frame] lgrip])    return OB_FRAME_CONTEXT_BLCORNER;
    if (win == [[client frame] rgrip])    return OB_FRAME_CONTEXT_BRCORNER;
    if (win == [[client frame] tlresize]) return OB_FRAME_CONTEXT_TLCORNER;
    if (win == [[client frame] trresize]) return OB_FRAME_CONTEXT_TRCORNER;
    if (win == [[client frame] max])      return OB_FRAME_CONTEXT_MAXIMIZE;
    if (win == [[client frame] iconify])  return OB_FRAME_CONTEXT_ICONIFY;
    if (win == [[client frame] close])    return OB_FRAME_CONTEXT_CLOSE;
    if (win == [[client frame] icon])     return OB_FRAME_CONTEXT_ICON;
    if (win == [[client frame] desk])     return OB_FRAME_CONTEXT_ALLDESKTOPS;
    if (win == [[client frame] shade])    return OB_FRAME_CONTEXT_SHADE;

    return OB_FRAME_CONTEXT_NONE;
}

