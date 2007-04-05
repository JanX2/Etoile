/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   prop.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   prop.c for the Openbox window manager
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
#import "prop.h"
#import "openbox.h"
#import "gnustep.h"
#import <X11/Xatom.h>

Atoms prop_atoms;

/* Weird bug */
#define FALSE NO
#define CREATE(var, name) (prop_atoms.var = \
                           XInternAtom(ob_display, name, FALSE))

void prop_startup()
{
    CREATE(cardinal, "CARDINAL");
    CREATE(window, "WINDOW");
    CREATE(pixmap, "PIXMAP");
    CREATE(atom, "ATOM");
    CREATE(string, "STRING");
    CREATE(utf8, "UTF8_STRING");

    CREATE(manager, "MANAGER");
     
    CREATE(wm_colormap_windows, "WM_COLORMAP_WINDOWS");
    CREATE(wm_protocols, "WM_PROTOCOLS");
    CREATE(wm_state, "WM_STATE");
    CREATE(wm_change_state, "WM_CHANGE_STATE");
    CREATE(wm_delete_window, "WM_DELETE_WINDOW");
    CREATE(wm_take_focus, "WM_TAKE_FOCUS");
    CREATE(wm_name, "WM_NAME");
    CREATE(wm_icon_name, "WM_ICON_NAME");
    CREATE(wm_class, "WM_CLASS");
    CREATE(wm_window_role, "WM_WINDOW_ROLE");
    CREATE(motif_wm_hints, "_MOTIF_WM_HINTS");

    CREATE(sm_client_id, "SM_CLIENT_ID");

    CREATE(net_supported, "_NET_SUPPORTED");
    CREATE(net_client_list, "_NET_CLIENT_LIST");
    CREATE(net_client_list_stacking, "_NET_CLIENT_LIST_STACKING");
    CREATE(net_number_of_desktops, "_NET_NUMBER_OF_DESKTOPS");
    CREATE(net_desktop_geometry, "_NET_DESKTOP_GEOMETRY");
    CREATE(net_desktop_viewport, "_NET_DESKTOP_VIEWPORT");
    CREATE(net_current_desktop, "_NET_CURRENT_DESKTOP");
    CREATE(net_desktop_names, "_NET_DESKTOP_NAMES");
    CREATE(net_active_window, "_NET_ACTIVE_WINDOW");
    CREATE(net_workarea, "_NET_WORKAREA");
    CREATE(net_supporting_wm_check, "_NET_SUPPORTING_WM_CHECK");
    CREATE(net_desktop_layout, "_NET_DESKTOP_LAYOUT");
    CREATE(net_showing_desktop, "_NET_SHOWING_DESKTOP");

    CREATE(net_close_window, "_NET_CLOSE_WINDOW");
    CREATE(net_wm_moveresize, "_NET_WM_MOVERESIZE");
    CREATE(net_moveresize_window, "_NET_MOVERESIZE_WINDOW");

    CREATE(net_startup_id, "_NET_STARTUP_ID");

    CREATE(net_wm_name, "_NET_WM_NAME");
    CREATE(net_wm_visible_name, "_NET_WM_VISIBLE_NAME");
    CREATE(net_wm_icon_name, "_NET_WM_ICON_NAME");
    CREATE(net_wm_visible_icon_name, "_NET_WM_VISIBLE_ICON_NAME");
    CREATE(net_wm_desktop, "_NET_WM_DESKTOP");
    CREATE(net_wm_window_type, "_NET_WM_WINDOW_TYPE");
    CREATE(net_wm_state, "_NET_WM_STATE");
    CREATE(net_wm_strut, "_NET_WM_STRUT");
    CREATE(net_wm_strut_partial, "_NET_WM_STRUT_PARTIAL");
    CREATE(net_wm_icon, "_NET_WM_ICON");
/*   CREATE(net_wm_pid, "_NET_WM_PID"); */
    CREATE(net_wm_allowed_actions, "_NET_WM_ALLOWED_ACTIONS");
    CREATE(net_wm_user_time, "_NET_WM_USER_TIME");
    CREATE(net_frame_extents, "_NET_FRAME_EXTENTS");

/*   CREATE(net_wm_ping, "_NET_WM_PING"); */
  
    CREATE(net_wm_window_type_desktop, "_NET_WM_WINDOW_TYPE_DESKTOP");
    CREATE(net_wm_window_type_dock, "_NET_WM_WINDOW_TYPE_DOCK");
    CREATE(net_wm_window_type_toolbar, "_NET_WM_WINDOW_TYPE_TOOLBAR");
    CREATE(net_wm_window_type_menu, "_NET_WM_WINDOW_TYPE_MENU");
    CREATE(net_wm_window_type_utility, "_NET_WM_WINDOW_TYPE_UTILITY");
    CREATE(net_wm_window_type_splash, "_NET_WM_WINDOW_TYPE_SPLASH");
    CREATE(net_wm_window_type_dialog, "_NET_WM_WINDOW_TYPE_DIALOG");
    CREATE(net_wm_window_type_normal, "_NET_WM_WINDOW_TYPE_NORMAL");

    prop_atoms.net_wm_moveresize_size_topleft = 0;
    prop_atoms.net_wm_moveresize_size_top = 1;
    prop_atoms.net_wm_moveresize_size_topright = 2;
    prop_atoms.net_wm_moveresize_size_right = 3;
    prop_atoms.net_wm_moveresize_size_bottomright = 4;
    prop_atoms.net_wm_moveresize_size_bottom = 5;
    prop_atoms.net_wm_moveresize_size_bottomleft = 6;
    prop_atoms.net_wm_moveresize_size_left = 7;
    prop_atoms.net_wm_moveresize_move = 8;
    prop_atoms.net_wm_moveresize_size_keyboard = 9;
    prop_atoms.net_wm_moveresize_move_keyboard = 10;

    CREATE(net_wm_action_move, "_NET_WM_ACTION_MOVE");
    CREATE(net_wm_action_resize, "_NET_WM_ACTION_RESIZE");
    CREATE(net_wm_action_minimize, "_NET_WM_ACTION_MINIMIZE");
    CREATE(net_wm_action_shade, "_NET_WM_ACTION_SHADE");
    CREATE(net_wm_action_stick, "_NET_WM_ACTION_STICK");
    CREATE(net_wm_action_maximize_horz, "_NET_WM_ACTION_MAXIMIZE_HORZ");
    CREATE(net_wm_action_maximize_vert, "_NET_WM_ACTION_MAXIMIZE_VERT");
    CREATE(net_wm_action_fullscreen, "_NET_WM_ACTION_FULLSCREEN");
    CREATE(net_wm_action_change_desktop, "_NET_WM_ACTION_CHANGE_DESKTOP");
    CREATE(net_wm_action_close, "_NET_WM_ACTION_CLOSE");
    CREATE(net_wm_state_modal, "_NET_WM_STATE_MODAL");
    CREATE(net_wm_state_sticky, "_NET_WM_STATE_STICKY");
    CREATE(net_wm_state_maximized_vert, "_NET_WM_STATE_MAXIMIZED_VERT");
    CREATE(net_wm_state_maximized_horz, "_NET_WM_STATE_MAXIMIZED_HORZ");
    CREATE(net_wm_state_shaded, "_NET_WM_STATE_SHADED");
    CREATE(net_wm_state_skip_taskbar, "_NET_WM_STATE_SKIP_TASKBAR");
    CREATE(net_wm_state_skip_pager, "_NET_WM_STATE_SKIP_PAGER");
    CREATE(net_wm_state_hidden, "_NET_WM_STATE_HIDDEN");
    CREATE(net_wm_state_fullscreen, "_NET_WM_STATE_FULLSCREEN");
    CREATE(net_wm_state_above, "_NET_WM_STATE_ABOVE");
    CREATE(net_wm_state_below, "_NET_WM_STATE_BELOW");
    CREATE(net_wm_state_demands_attention, "_NET_WM_STATE_DEMANDS_ATTENTION");
  
    prop_atoms.net_wm_state_add = 1;
    prop_atoms.net_wm_state_remove = 0;
    prop_atoms.net_wm_state_toggle = 2;

    prop_atoms.net_wm_orientation_horz = 0;
    prop_atoms.net_wm_orientation_vert = 1;
    prop_atoms.net_wm_topleft = 0;
    prop_atoms.net_wm_topright = 1;
    prop_atoms.net_wm_bottomright = 2;
    prop_atoms.net_wm_bottomleft = 3;

    CREATE(kde_wm_change_state, "_KDE_WM_CHANGE_STATE");
    CREATE(kde_net_wm_window_type_override,"_KDE_NET_WM_WINDOW_TYPE_OVERRIDE");

    CREATE(rootpmapid, "_XROOTPMAP_ID");
    CREATE(esetrootid, "ESETROOT_PMAP_ID");

    CREATE(openbox_pid, "_OPENBOX_PID");
    CREATE(ob_wm_state_undecorated, "_OB_WM_STATE_UNDECORATED");
    CREATE(ob_control, "_OB_CONTROL");

    CREATE(gnustep_wm_attr, _GNUSTEP_WM_ATTR);
}

#include <X11/Xutil.h>
#include <string.h>

static BOOL get_prealloc(Window win, Atom prop, Atom type, int size,
                             unsigned char *data, unsigned long num)
{
    BOOL ret = NO;
    int res;
    unsigned char *xdata = NULL;
    Atom ret_type;
    int ret_size;
    unsigned long ret_items, bytes_left;
    long num32 = 32 / size * num; /* num in 32-bit elements */

    res = XGetWindowProperty(ob_display, win, prop, 0l, num32,
                             FALSE, type, &ret_type, &ret_size,
                             &ret_items, &bytes_left, &xdata);
    if (res == Success && ret_items && xdata) {
        if (ret_size == size && ret_items >= num) {
            unsigned int i;
            for (i = 0; i < num; ++i)
                switch (size) {
                case 8:
                    data[i] = xdata[i];
                    break;
                case 16:
                    ((gsu16 *)data)[i] = ((unsigned short *)xdata)[i];
                    break;
                case 32:
                    ((gsu32 *)data)[i] = ((unsigned long*)xdata)[i];
                    break;
                default:
		    NSLog( @"Should not reach here"); /* unhandled size */
                }
            ret = YES;
        }
        XFree(xdata);
    }
    return ret;
}

static BOOL get_all(Window win, Atom prop, Atom type, int size,
                        unsigned char **data, unsigned int *num)
{
    BOOL ret = NO;
    int res;
    unsigned char *xdata = NULL;
    Atom ret_type;
    int ret_size;
    unsigned long ret_items, bytes_left;

    res = XGetWindowProperty(ob_display, win, prop, 0l, LONG_MAX,
                             FALSE, type, &ret_type, &ret_size,
                             &ret_items, &bytes_left, &xdata);
    if (res == Success) {
        if (ret_size == size && ret_items > 0) {
            unsigned int i;

            *data = calloc(ret_items,  (size / 8));
            for (i = 0; i < ret_items; ++i)
                switch (size) {
                case 8:
                    (*data)[i] = xdata[i];
                    break;
                case 16:
                    ((gsu16 *)*data)[i] = ((unsigned short *)xdata)[i];
                    break;
                case 32:
                    ((gsu32 *)*data)[i] = ((unsigned long *)xdata)[i];
                    break;
                default:
		    NSLog( @"Should not reach here"); /* unhandled size */
                }
            *num = ret_items;
            ret = YES;
        }
        XFree(xdata);
    }
    return ret;
}

static BOOL get_stringlist(Window win, Atom prop, char ***list, int *nstr)
{
    XTextProperty tprop;
    BOOL ret = NO;

    if (XGetTextProperty(ob_display, win, &tprop, prop) && tprop.nitems) {
        if (XTextPropertyToStringList(&tprop, list, nstr))
            ret = YES;
        XFree(tprop.value);
    }
    return ret;
}

BOOL prop_get32(Window win, Atom prop, Atom type, unsigned long *ret)
{
    return get_prealloc(win, prop, type, 32, (unsigned char*)ret, 1);
}

BOOL prop_get_array32(Window win, Atom prop, Atom type, unsigned long **ret,
                          unsigned int *nret)
{
    return get_all(win, prop, type, 32, (unsigned char**)ret, nret);
}

/* Autoreleased */
BOOL prop_get_string_locale(Window win, Atom prop, NSString **ret)
{
    char **list;
    int nstr;
    NSString *s;

    if (get_stringlist(win, prop, &list, &nstr) && nstr) {
	s = [NSString stringWithCString: list[0]];
        XFreeStringList(list);
        if (s) {
            *ret = s;
            return YES;
        }
    }
    return NO;
}

BOOL prop_get_strings_locale(Window win, Atom prop, NSArray **ret)
{
    char *raw, *p;
    unsigned int num, count = 0;
    NSMutableArray *ma = AUTORELEASE([[NSMutableArray alloc] init]);

    if (get_all(win, prop, prop_atoms.string, 8, (unsigned char**)&raw, &num)) {

        p = raw;
        while (p < raw + num - 1) {
            ++count;
	    [ma addObject: [NSString stringWithCString: p]];
            p += strlen(p) + 1; /* next string */
        }

	*ret = AUTORELEASE([ma copy]);
	XFree(raw);
        return YES;
    }
    return NO;
}

BOOL prop_get_string_utf8(Window win, Atom prop, NSString **ret)
{
    char *raw;
    NSString *str = nil;
    unsigned int num;
     
    if (get_all(win, prop, prop_atoms.utf8, 8, (unsigned char**)&raw, &num)) {
	str = [NSString stringWithUTF8String: raw]; /* grab the first string from the list */
        XFree(raw);
	if (str) {
            *ret = str;
            return YES;
        }
    }
    return NO;
}

BOOL prop_get_strings_utf8(Window win, Atom prop, NSArray **ret)
{
    char *raw, *p;
    unsigned int num, count = 0;
    NSMutableArray *ma = AUTORELEASE([[NSMutableArray alloc] init]);
    NSString *s;

    if (get_all(win, prop, prop_atoms.utf8, 8, (unsigned char**)&raw, &num)) {

        p = raw;
        while (p < raw + num - 1) {
            ++count;
	    s = [NSString stringWithUTF8String: p];
	    if (s)
	      [ma addObject: s];
	    else /* invalid UTF8 */
              [ma addObject: [NSString string]];
            p += strlen(p) + 1; /* next string */
        }

	*ret = AUTORELEASE([ma copy]);
        XFree(raw);
        return YES;
    }
    return NO;
}

void prop_set32(Window win, Atom prop, Atom type, unsigned long val)
{
    XChangeProperty(ob_display, win, prop, type, 32, PropModeReplace,
                    (unsigned char*)&val, 1);
}

void prop_set_array32(Window win, Atom prop, Atom type, unsigned long *val,
                      unsigned int num)
{
    XChangeProperty(ob_display, win, prop, type, 32, PropModeReplace,
                    (unsigned char*)val, num);
}

void prop_set_string_utf8(Window win, Atom prop, const char *val)
{
    XChangeProperty(ob_display, win, prop, prop_atoms.utf8, 8,
                    PropModeReplace, (unsigned char*)val, strlen(val));
}

void prop_set_strings_utf8(Window win, Atom prop, NSArray *strs)
{
    NSMutableData *data = AUTORELEASE([[NSMutableData alloc] init]);
    int i, count = [strs count];
    char empty = '\0';

    for (i = 0; i < count; i++) {
	[data appendData: [[strs objectAtIndex: i] dataUsingEncoding: NSUTF8StringEncoding]];
	[data appendBytes: &empty length: 1];

    }
    XChangeProperty(ob_display, win, prop, prop_atoms.utf8, 8,
                    PropModeReplace, (unsigned char*)[data bytes], [data length]);
}

void prop_erase(Window win, Atom prop)
{
    XDeleteProperty(ob_display, win, prop);
}

void prop_message(Window about, Atom messagetype, long data0, long data1,
                  long data2, long data3, long mask)
{
    XEvent ce;
    ce.xclient.type = ClientMessage;
    ce.xclient.message_type = messagetype;
    ce.xclient.display = ob_display;
    ce.xclient.window = about;
    ce.xclient.format = 32;
    ce.xclient.data.l[0] = data0;
    ce.xclient.data.l[1] = data1;
    ce.xclient.data.l[2] = data2;
    ce.xclient.data.l[3] = data3;
    XSendEvent(ob_display, RootWindow(ob_display, ob_screen), FALSE,
               mask, &ce);
}
