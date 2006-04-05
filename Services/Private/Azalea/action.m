/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   action.c for the Openbox window manager
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

#import "AZDock.h"
#import "AZStacking.h"
#import "AZClient.h"
#import "AZMoveResizeHandler.h"
#import "menu.h"
#import "prop.h"
#import "action.h"
#import "openbox.h"
#import "grab.h"
#import "keyboard.h"
#import "config.h"
#import "AZMainLoop.h"
#import "AZScreen.h"
#import "AZEventHandler.h"
#import "AZFocusManager.h"

#include <glib.h>

inline void client_action_start(union ActionData *data)
{
    if (config_focus_follow)
        if (data->any.context != OB_FRAME_CONTEXT_CLIENT && !data->any.button)
            grab_pointer(TRUE, OB_CURSOR_NONE);
}

inline void client_action_end(union ActionData *data)
{
    if (config_focus_follow)
        if (data->any.context != OB_FRAME_CONTEXT_CLIENT) {
            if (!data->any.button) {
                grab_pointer(FALSE, OB_CURSOR_NONE);
            } else {
                AZClient *c;

                /* usually this is sorta redundant, but with a press action
                   the enter event will come as a GrabNotify which is
                   ignored, so this will handle that case */
                if ((c = AZUnderPointer()))
		{
		  [[AZEventHandler defaultHandler] enterClient: c];
		}
            }
        }
}

typedef struct
{
    const gchar *name;
    void (*func)(union ActionData *);
    void (*setup)(ObAction **, ObUserAction uact);
} ActionString;

static ObAction *action_new(void (*func)(union ActionData *data))
{
    ObAction *a = g_new0(ObAction, 1);
    a->ref = 1;
    a->func = func;

    return a;
}

void action_ref(ObAction *a)
{
    ++a->ref;
}

void action_unref(ObAction *a)
{
    if (a == NULL) return;

    if (--a->ref > 0) return;

    /* deal with pointers */
    if (a->func == action_execute || a->func == action_restart)
        g_free(a->data.execute.path);
    else if (a->func == action_showmenu)
        g_free(a->data.showmenu.name);

    g_free(a);
}

ObAction* action_copy(const ObAction *src)
{
    ObAction *a = action_new(src->func);

    a->data = src->data;

    /* deal with pointers */
    if (a->func == action_execute || a->func == action_restart)
        a->data.execute.path = g_strdup(a->data.execute.path);
    else if (a->func == action_showmenu)
        a->data.showmenu.name = g_strdup(a->data.showmenu.name);

    return a;
}

void setup_action_directional_focus_north(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_NORTH;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_east(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_EAST;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_south(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_SOUTH;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_west(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_WEST;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_northeast(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_NORTHEAST;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_southeast(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_SOUTHEAST;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_southwest(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_SOUTHWEST;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_directional_focus_northwest(ObAction **a, ObUserAction uact)
{
    (*a)->data.interdiraction.inter.any.interactive = TRUE;
    (*a)->data.interdiraction.direction = OB_DIRECTION_NORTHWEST;
    (*a)->data.interdiraction.dialog = TRUE;
}

void setup_action_send_to_desktop(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendto.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendto.follow = TRUE;
}

void setup_action_send_to_desktop_prev(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendtodir.inter.any.interactive = TRUE;
    (*a)->data.sendtodir.dir = OB_DIRECTION_WEST;
    (*a)->data.sendtodir.linear = TRUE;
    (*a)->data.sendtodir.wrap = TRUE;
    (*a)->data.sendtodir.follow = TRUE;
}

void setup_action_send_to_desktop_next(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendtodir.inter.any.interactive = TRUE;
    (*a)->data.sendtodir.dir = OB_DIRECTION_EAST;
    (*a)->data.sendtodir.linear = TRUE;
    (*a)->data.sendtodir.wrap = TRUE;
    (*a)->data.sendtodir.follow = TRUE;
}

void setup_action_send_to_desktop_left(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendtodir.inter.any.interactive = TRUE;
    (*a)->data.sendtodir.dir = OB_DIRECTION_WEST;
    (*a)->data.sendtodir.linear = FALSE;
    (*a)->data.sendtodir.wrap = TRUE;
    (*a)->data.sendtodir.follow = TRUE;
}

void setup_action_send_to_desktop_right(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendtodir.inter.any.interactive = TRUE;
    (*a)->data.sendtodir.dir = OB_DIRECTION_EAST;
    (*a)->data.sendtodir.linear = FALSE;
    (*a)->data.sendtodir.wrap = TRUE;
    (*a)->data.sendtodir.follow = TRUE;
}

void setup_action_send_to_desktop_up(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendtodir.inter.any.interactive = TRUE;
    (*a)->data.sendtodir.dir = OB_DIRECTION_NORTH;
    (*a)->data.sendtodir.linear = FALSE;
    (*a)->data.sendtodir.wrap = TRUE;
    (*a)->data.sendtodir.follow = TRUE;
}

void setup_action_send_to_desktop_down(ObAction **a, ObUserAction uact)
{
    (*a)->data.sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.sendtodir.inter.any.interactive = TRUE;
    (*a)->data.sendtodir.dir = OB_DIRECTION_SOUTH;
    (*a)->data.sendtodir.linear = FALSE;
    (*a)->data.sendtodir.wrap = TRUE;
    (*a)->data.sendtodir.follow = TRUE;
}

void setup_action_desktop(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktop.inter.any.interactive = FALSE;
}

void setup_action_desktop_prev(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktopdir.inter.any.interactive = TRUE;
    (*a)->data.desktopdir.dir = OB_DIRECTION_WEST;
    (*a)->data.desktopdir.linear = TRUE;
    (*a)->data.desktopdir.wrap = TRUE;
}

void setup_action_desktop_next(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktopdir.inter.any.interactive = TRUE;
    (*a)->data.desktopdir.dir = OB_DIRECTION_EAST;
    (*a)->data.desktopdir.linear = TRUE;
    (*a)->data.desktopdir.wrap = TRUE;
}

void setup_action_desktop_left(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktopdir.inter.any.interactive = TRUE;
    (*a)->data.desktopdir.dir = OB_DIRECTION_WEST;
    (*a)->data.desktopdir.linear = FALSE;
    (*a)->data.desktopdir.wrap = TRUE;
}

void setup_action_desktop_right(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktopdir.inter.any.interactive = TRUE;
    (*a)->data.desktopdir.dir = OB_DIRECTION_EAST;
    (*a)->data.desktopdir.linear = FALSE;
    (*a)->data.desktopdir.wrap = TRUE;
}

void setup_action_desktop_up(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktopdir.inter.any.interactive = TRUE;
    (*a)->data.desktopdir.dir = OB_DIRECTION_NORTH;
    (*a)->data.desktopdir.linear = FALSE;
    (*a)->data.desktopdir.wrap = TRUE;
}

void setup_action_desktop_down(ObAction **a, ObUserAction uact)
{
    (*a)->data.desktopdir.inter.any.interactive = TRUE;
    (*a)->data.desktopdir.dir = OB_DIRECTION_SOUTH;
    (*a)->data.desktopdir.linear = FALSE;
    (*a)->data.desktopdir.wrap = TRUE;
}

void setup_action_cycle_windows_next(ObAction **a, ObUserAction uact)
{
    (*a)->data.cycle.inter.any.interactive = TRUE;
    (*a)->data.cycle.linear = FALSE;
    (*a)->data.cycle.forward = TRUE;
    (*a)->data.cycle.dialog = TRUE;
}

void setup_action_cycle_windows_previous(ObAction **a, ObUserAction uact)
{
    (*a)->data.cycle.inter.any.interactive = TRUE;
    (*a)->data.cycle.linear = FALSE;
    (*a)->data.cycle.forward = FALSE;
    (*a)->data.cycle.dialog = TRUE;
}

void setup_action_movetoedge_north(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_NORTH;
}

void setup_action_movetoedge_south(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_SOUTH;
}

void setup_action_movetoedge_east(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_EAST;
}

void setup_action_movetoedge_west(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_WEST;
}

void setup_action_growtoedge_north(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_NORTH;
}

void setup_action_growtoedge_south(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_SOUTH;
}

void setup_action_growtoedge_east(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_EAST;
}

void setup_action_growtoedge_west(ObAction **a, ObUserAction uact)
{
    (*a)->data.diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.diraction.direction = OB_DIRECTION_WEST;
}

void setup_action_top_layer(ObAction **a, ObUserAction uact)
{
    (*a)->data.layer.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.layer.layer = 1;
}

void setup_action_normal_layer(ObAction **a, ObUserAction uact)
{
    (*a)->data.layer.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.layer.layer = 0;
}

void setup_action_bottom_layer(ObAction **a, ObUserAction uact)
{
    (*a)->data.layer.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.layer.layer = -1;
}

void setup_action_move(ObAction **a, ObUserAction uact)
{
    (*a)->data.moveresize.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.moveresize.move = TRUE;
    (*a)->data.moveresize.keyboard =
        (uact == OB_USER_ACTION_NONE ||
         uact == OB_USER_ACTION_KEYBOARD_KEY ||
         uact == OB_USER_ACTION_MENU_SELECTION);
}

void setup_action_resize(ObAction **a, ObUserAction uact)
{
    (*a)->data.moveresize.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    (*a)->data.moveresize.move = FALSE;
    (*a)->data.moveresize.keyboard =
        (uact == OB_USER_ACTION_NONE ||
         uact == OB_USER_ACTION_KEYBOARD_KEY ||
         uact == OB_USER_ACTION_MENU_SELECTION);
}

void setup_action_showmenu(ObAction **a, ObUserAction uact)
{
    (*a)->data.showmenu.any.client_action = OB_CLIENT_ACTION_OPTIONAL;
    /* you cannot call ShowMenu from inside a menu, cuz the menu code makes
       assumptions that there is only one menu (and submenus) open at
       a time! */
    if (uact == OB_USER_ACTION_MENU_SELECTION) {
        action_unref(*a);
        *a = NULL;
    }
}

void setup_client_action(ObAction **a, ObUserAction uact)
{
    (*a)->data.any.client_action = OB_CLIENT_ACTION_ALWAYS;
}

ActionString actionstrings[] =
{
    {
        "execute", 
        action_execute, 
        NULL
    },
    {
        "directionalfocusnorth", 
        action_directional_focus, 
        setup_action_directional_focus_north
    },
    {
        "directionalfocuseast", 
        action_directional_focus, 
        setup_action_directional_focus_east
    },
    {
        "directionalfocussouth", 
        action_directional_focus, 
        setup_action_directional_focus_south
    },
    {
        "directionalfocuswest",
        action_directional_focus,
        setup_action_directional_focus_west
    },
    {
        "directionalfocusnortheast",
        action_directional_focus,
        setup_action_directional_focus_northeast
    },
    {
        "directionalfocussoutheast",
        action_directional_focus,
        setup_action_directional_focus_southeast
    },
    {
        "directionalfocussouthwest",
        action_directional_focus,
        setup_action_directional_focus_southwest
    },
    {
        "directionalfocusnorthwest",
        action_directional_focus,
        setup_action_directional_focus_northwest
    },
    {
        "activate",
        action_activate,
        setup_client_action
    },
    {
        "focus",
        action_focus,
        setup_client_action
    },
    {
        "unfocus",
        action_unfocus,
        setup_client_action
    },
    {
        "iconify",
        action_iconify,
        setup_client_action
    },
    {
        "focustobottom",
        action_focus_order_to_bottom,
        setup_client_action
    },
    {
        "raiselower",
        action_raiselower,
        setup_client_action
    },
    {
        "raise",
        action_raise,
        setup_client_action
    },
    {
        "lower",
        action_lower,
        setup_client_action
    },
    {
        "close",
        action_close,
        setup_client_action
    },
    {
        "kill",
        action_kill,
        setup_client_action
    },
    {
        "shadelower",
        action_shadelower,
        setup_client_action
    },
    {
        "unshaderaise",
        action_unshaderaise,
        setup_client_action
    },
    {
        "shade",
        action_shade,
        setup_client_action
    },
    {
        "unshade",
        action_unshade,
        setup_client_action
    },
    {
        "toggleshade",
        action_toggle_shade,
        setup_client_action
    },
    {
        "toggleomnipresent",
        action_toggle_omnipresent,
        setup_client_action
    },
    {
        "moverelativehorz",
        action_move_relative_horz,
        setup_client_action
    },
    {
        "moverelativevert",
        action_move_relative_vert,
        setup_client_action
    },
    {
        "movetocenter",
        action_move_to_center,
        setup_client_action
    },
    {
        "resizerelativehorz",
        action_resize_relative_horz,
        setup_client_action
    },
    {
        "resizerelativevert",
        action_resize_relative_vert,
        setup_client_action
    },
    {
        "maximizefull",
        action_maximize_full,
        setup_client_action
    },
    {
        "unmaximizefull",
        action_unmaximize_full,
        setup_client_action
    },
    {
        "togglemaximizefull",
        action_toggle_maximize_full,
        setup_client_action
    },
    {
        "maximizehorz",
        action_maximize_horz,
        setup_client_action
    },
    {
        "unmaximizehorz",
        action_unmaximize_horz,
        setup_client_action
    },
    {
        "togglemaximizehorz",
        action_toggle_maximize_horz,
        setup_client_action
    },
    {
        "maximizevert",
        action_maximize_vert,
        setup_client_action
    },
    {
        "unmaximizevert",
        action_unmaximize_vert,
        setup_client_action
    },
    {
        "togglemaximizevert",
        action_toggle_maximize_vert,
        setup_client_action
    },
    {
        "togglefullscreen",
        action_toggle_fullscreen,
        setup_client_action
    },
    {
        "sendtodesktop",
        action_send_to_desktop,
        setup_action_send_to_desktop
    },
    {
        "sendtodesktopnext",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_next
    },
    {
        "sendtodesktopprevious",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_prev
    },
    {
        "sendtodesktopright",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_right
    },
    {
        "sendtodesktopleft",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_left
    },
    {
        "sendtodesktopup",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_up
    },
    {
        "sendtodesktopdown",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_down
    },
    {
        "desktop",
        action_desktop,
        setup_action_desktop
    },
    {
        "desktopnext",
        action_desktop_dir,
        setup_action_desktop_next
    },
    {
        "desktopprevious",
        action_desktop_dir,
        setup_action_desktop_prev
    },
    {
        "desktopright",
        action_desktop_dir,
        setup_action_desktop_right
    },
    {
        "desktopleft",
        action_desktop_dir,
        setup_action_desktop_left
    },
    {
        "desktopup",
        action_desktop_dir,
        setup_action_desktop_up
    },
    {
        "desktopdown",
        action_desktop_dir,
        setup_action_desktop_down
    },
    {
        "toggledecorations",
        action_toggle_decorations,
        setup_client_action
    },
    {
        "move",
        action_moveresize,
        setup_action_move
    },
    {
        "resize",
        action_moveresize,
        setup_action_resize
    },
    {
        "toggledockautohide",
        action_toggle_dockautohide,
        NULL
    },
    {
        "toggleshowdesktop",
        action_toggle_show_desktop,
        NULL
    },
    {
        "showdesktop",
        action_show_desktop,
        NULL
    },
    {
        "unshowdesktop",
        action_unshow_desktop,
        NULL
    },
    {
        "desktoplast",
        action_desktop_last,
        NULL
    },
    {
        "reconfigure",
        action_reconfigure,
        NULL
    },
    {
        "restart",
        action_restart,
        NULL
    },
    {
        "exit",
        action_exit,
        NULL
    },
    {
        "showmenu",
        action_showmenu,
        setup_action_showmenu
    },
    {
        "sendtotoplayer",
        action_send_to_layer,
        setup_action_top_layer
    },
    {
        "togglealwaysontop",
        action_toggle_layer,
        setup_action_top_layer
    },
    {
        "sendtonormallayer",
        action_send_to_layer,
        setup_action_normal_layer
    },
    {
        "sendtobottomlayer",
        action_send_to_layer,
        setup_action_bottom_layer
    },
    {
        "togglealwaysonbottom",
        action_toggle_layer,
        setup_action_bottom_layer
    },
    {
        "nextwindow",
        action_cycle_windows,
        setup_action_cycle_windows_next
    },
    {
        "previouswindow",
        action_cycle_windows,
        setup_action_cycle_windows_previous
    },
    {
        "movetoedgenorth",
        action_movetoedge,
        setup_action_movetoedge_north
    },
    {
        "movetoedgesouth",
        action_movetoedge,
        setup_action_movetoedge_south
    },
    {
        "movetoedgewest",
        action_movetoedge,
        setup_action_movetoedge_west
    },
    {
        "movetoedgeeast",
        action_movetoedge,
        setup_action_movetoedge_east
    },
    {
        "growtoedgenorth",
        action_growtoedge,
        setup_action_growtoedge_north
    },
    {
        "growtoedgesouth",
        action_growtoedge,
        setup_action_growtoedge_south
    },
    {
        "growtoedgewest",
        action_growtoedge,
        setup_action_growtoedge_west
    },
    {
        "growtoedgeeast",
        action_growtoedge,
        setup_action_growtoedge_east
    },
    {
        NULL,
        NULL,
        NULL
    }
};

/* only key bindings can be interactive. thus saith the xor.
   because of how the mouse is grabbed, mouse events dont even get
   read during interactive events, so no dice! >:) */
#define INTERACTIVE_LIMIT(a, uact) \
    if (uact != OB_USER_ACTION_KEYBOARD_KEY) \
        a->data.any.interactive = FALSE;

ObAction *action_from_string(const gchar *name, ObUserAction uact)
{
    ObAction *a = NULL;
    gboolean exist = FALSE;
    gint i;

    for (i = 0; actionstrings[i].name; i++)
        if (!g_ascii_strcasecmp(name, actionstrings[i].name)) {
            exist = TRUE;
            a = action_new(actionstrings[i].func);
            if (actionstrings[i].setup)
                actionstrings[i].setup(&a, uact);
            if (a)
                INTERACTIVE_LIMIT(a, uact);
            break;
        }
    if (!exist)
        g_warning("Invalid action '%s' requested. No such action exists.",
                  name);
    if (!a)
        g_warning("Invalid use of action '%s'. Action will be ignored.", name);
    return a;
}

ObAction *action_parse(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                       ObUserAction uact)
{
    gchar *actname;
    ObAction *act = NULL;
    xmlNodePtr n;

    if (parse_attr_string("name", node, &actname)) {
        if ((act = action_from_string(actname, uact))) {
            if (act->func == action_execute || act->func == action_restart) {
                if ((n = parse_find_node("execute", node->xmlChildrenNode))) {
                    gchar *s = parse_string(doc, n);
                    act->data.execute.path = parse_expand_tilde(s);
                    g_free(s);
                }
            } else if (act->func == action_showmenu) {
                if ((n = parse_find_node("menu", node->xmlChildrenNode)))
                    act->data.showmenu.name = parse_string(doc, n);
            } else if (act->func == action_move_relative_horz ||
                       act->func == action_move_relative_vert ||
                       act->func == action_resize_relative_horz ||
                       act->func == action_resize_relative_vert) {
                if ((n = parse_find_node("delta", node->xmlChildrenNode)))
                    act->data.relative.delta = parse_int(doc, n);
            } else if (act->func == action_desktop) {
                if ((n = parse_find_node("desktop", node->xmlChildrenNode)))
                    act->data.desktop.desk = parse_int(doc, n);
                if (act->data.desktop.desk > 0) act->data.desktop.desk--;
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    act->data.desktop.inter.any.interactive =
                        parse_bool(doc, n);
           } else if (act->func == action_send_to_desktop) {
                if ((n = parse_find_node("desktop", node->xmlChildrenNode)))
                    act->data.sendto.desk = parse_int(doc, n);
                if (act->data.sendto.desk > 0) act->data.sendto.desk--;
                if ((n = parse_find_node("follow", node->xmlChildrenNode)))
                    act->data.sendto.follow = parse_bool(doc, n);
            } else if (act->func == action_desktop_dir) {
                if ((n = parse_find_node("wrap", node->xmlChildrenNode)))
                    act->data.desktopdir.wrap = parse_bool(doc, n); 
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    act->data.desktopdir.inter.any.interactive =
                        parse_bool(doc, n);
            } else if (act->func == action_send_to_desktop_dir) {
                if ((n = parse_find_node("wrap", node->xmlChildrenNode)))
                    act->data.sendtodir.wrap = parse_bool(doc, n);
                if ((n = parse_find_node("follow", node->xmlChildrenNode)))
                    act->data.sendtodir.follow = parse_bool(doc, n);
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    act->data.sendtodir.inter.any.interactive =
                        parse_bool(doc, n);
            } else if (act->func == action_activate) {
                if ((n = parse_find_node("here", node->xmlChildrenNode)))
                    act->data.activate.here = parse_bool(doc, n);
            } else if (act->func == action_cycle_windows) {
                if ((n = parse_find_node("linear", node->xmlChildrenNode)))
                    act->data.cycle.linear = parse_bool(doc, n);
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    act->data.cycle.dialog = parse_bool(doc, n);
            } else if (act->func == action_directional_focus) {
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    act->data.cycle.dialog = parse_bool(doc, n);
            } else if (act->func == action_raise ||
                       act->func == action_lower ||
                       act->func == action_raiselower ||
                       act->func == action_shadelower ||
                       act->func == action_unshaderaise) {
                if ((n = parse_find_node("group", node->xmlChildrenNode)))
                    act->data.stacking.group = parse_bool(doc, n);
            }
            INTERACTIVE_LIMIT(act, uact);
        }
        g_free(actname);
    }
    return act;
}

void action_run_list(GSList *acts, ObClient *c, ObFrameContext context,
                     guint state, guint button, gint x, gint y,
                     gboolean cancel, gboolean done)
{
    GSList *it;
    ObAction *a;
    gboolean inter = FALSE;

    if (!acts)
        return;

    if (x < 0 && y < 0)
    {
	[[AZScreen defaultScreen] pointerPosAtX: &x y: &y];
    }

    if (grab_on_keyboard())
        inter = TRUE;
    else
        for (it = acts; it; it = g_slist_next(it)) {
            a = it->data;
            if (a->data.any.interactive) {
                inter = TRUE;
                break;
            }
        }

    if (!inter) {
        /* sometimes when we execute another app as an action,
           it won't work right unless we XUngrabKeyboard first,
           even though we grabbed the key/button Asychronously.
           e.g. "gnome-panel-control --main-menu" */
        XUngrabKeyboard(ob_display, [[AZEventHandler defaultHandler] eventLastTime]/*event_lasttime*/);
    }

    for (it = acts; it; it = g_slist_next(it)) {
        a = it->data;

        if (!(a->data.any.client_action == OB_CLIENT_ACTION_ALWAYS && !c)) {
            a->data.any.c = a->data.any.client_action ? c : NULL;
            a->data.any.context = context;
            a->data.any.x = x;
            a->data.any.y = y;

            a->data.any.button = button;

            if (a->data.any.interactive) {
                a->data.inter.cancel = cancel;
                a->data.inter.final = done;
                if (!(cancel || done))
                    if (!keyboard_interactive_grab(state, a->data.any.c, a))
                        continue;
            }

            /* XXX UGLY HACK race with motion event starting a move and the
               button release gettnig processed first. answer: don't queue
               moveresize starts. UGLY HACK XXX */
            if (a->data.any.interactive || a->func == action_moveresize) {
                /* interactive actions are not queued */
                a->func(&a->data);
            } else {
                [[AZMainLoop mainLoop] queueAction: a];
	    }
        }
    }
}

void action_run_string(const gchar *name, struct _ObClient *c)
{
    ObAction *a;
    GSList *l;

    a = action_from_string(name, OB_USER_ACTION_NONE);
    g_assert(a);

    l = g_slist_append(NULL, a);

    action_run(l, c, 0);
}

void action_execute(union ActionData *data)
{
    GError *e = NULL;
    gchar *cmd, **argv = 0;
    if (data->execute.path) {
        cmd = g_filename_from_utf8(data->execute.path, -1, NULL, NULL, NULL);
        if (cmd) {
            if (!g_shell_parse_argv (cmd, NULL, &argv, &e)) {
                g_warning("failed to execute '%s': %s",
                          cmd, e->message);
                g_error_free(e);
            } else {
                if (!g_spawn_async(NULL, argv, NULL, G_SPAWN_SEARCH_PATH |
                                   G_SPAWN_DO_NOT_REAP_CHILD,
                                   NULL, NULL, NULL, &e)) {
                    g_warning("failed to execute '%s': %s",
                              cmd, e->message);
                    g_error_free(e);
                }
                g_strfreev(argv);
            }
            g_free(cmd);
        } else {
            g_warning("failed to convert '%s' from utf8", data->execute.path);
        }
    }
}

void action_activate(union ActionData *data)
{
    [(data->activate.any.c)->_self activateHere: data->activate.here];
}

void action_focus(union ActionData *data)
{
    /* if using focus_delay, stop the timer now so that focus doesn't go moving
       on us */
    //event_halt_focus_delay();
    [[AZEventHandler defaultHandler] haltFocusDelay];

    [((ObClient *)(data->client.any.c))->_self focus];
}

void action_unfocus (union ActionData *data)
{
    [((ObClient *)(data->client.any.c))->_self unfocus];
}

void action_iconify(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self iconify: YES currentDesktop: YES];
    client_action_end(data);
}

void action_focus_order_to_bottom(union ActionData *data)
{
  [[AZFocusManager defaultManager] focusOrderToBottom: ((ObClient *)(data->client.any.c))->_self];
}

void action_raiselower(union ActionData *data)
{
    ObClient *c = data->client.any.c;
    gboolean raise = FALSE;
    int i, count = [[AZStacking stacking] count];

    for (i = 0; i < count; i++) {
	ObClient *cit = (ObClient *)[[AZStacking stacking] windowAtIndex: i];

        if (cit == c) break;
        if ([cit->_self normal] == [c->_self normal] &&
            [cit->_self layer] == [c->_self layer] &&
            [[cit->_self frame] visible] &&
            ![c->_self searchTransient: cit->_self]/*client_search_transient(c, cit)*/)
        {
            if (RECT_INTERSECTS_RECT([[cit->_self frame] area], [[c->_self frame] area])) {
                raise = TRUE;
                break;
            }
        }
    }

    if (raise)
        action_raise(data);
    else
        action_lower(data);
}

void action_raise(union ActionData *data)
{
    client_action_start(data);
    [[AZStacking stacking] raiseWindow: CLIENT_AS_WINDOW(data->client.any.c)
	                   group: data->stacking.group];
    client_action_end(data);
}

void action_unshaderaise(union ActionData *data)
{
    if ([data->client.any.c->_self shaded])
        action_unshade(data);
    else
        action_raise(data);
}

void action_shadelower(union ActionData *data)
{
    if ([data->client.any.c->_self shaded])
        action_lower(data);
    else
        action_shade(data);
}

void action_lower(union ActionData *data)
{
    client_action_start(data);
    [[AZStacking stacking] lowerWindow: CLIENT_AS_WINDOW(data->client.any.c)
	                   group: data->stacking.group];
    client_action_end(data);
}

void action_close(union ActionData *data)
{
    [data->client.any.c->_self close];
}

void action_kill(union ActionData *data)
{
    [data->client.any.c->_self kill];
}

void action_shade(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self shade: YES];
    client_action_end(data);
}

void action_unshade(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self shade: NO];
    client_action_end(data);
}

void action_toggle_shade(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self shade: ![data->client.any.c->_self shaded]];
    client_action_end(data);
}

void action_toggle_omnipresent(union ActionData *data)
{ 
  int num = ([data->client.any.c->_self desktop] == DESKTOP_ALL) ?
            [[AZScreen defaultScreen] desktop] : DESKTOP_ALL;
    [data->client.any.c->_self setDesktop: num hide: NO];
}

void action_move_relative_horz(union ActionData *data)
{
    ObClient *c = data->relative.any.c;
    client_action_start(data);
    [c->_self moveToX: [c->_self area].x + data->relative.delta
	            y: [c->_self area].y];
    client_action_end(data);
}

void action_move_relative_vert(union ActionData *data)
{
    ObClient *c = data->relative.any.c;
    client_action_start(data);
    [c->_self moveToX: [c->_self area].x
	            y: [c->_self area].y + data->relative.delta];
    client_action_end(data);
}

void action_move_to_center(union ActionData *data)
{
    ObClient *c = data->client.any.c;
    Rect *area;
    area = [[AZScreen defaultScreen] areaOfDesktop: [c->_self desktop]
	                                   monitor: 0];
    client_action_start(data);
    [c->_self moveToX: area->width / 2 - [c->_self area].width / 2
	            y: area->height / 2 - [c->_self area].height / 2];
    client_action_end(data);
}

void action_resize_relative_horz(union ActionData *data)
{
    ObClient *c = data->relative.any.c;
    client_action_start(data);
    [c->_self resizeToWidth: [c->_self area].width + data->relative.delta * [c->_self size_inc].width
                     height:  [c->_self area].height];
    client_action_end(data);
}

void action_resize_relative_vert(union ActionData *data)
{
    ObClient *c = data->relative.any.c;
    if (![c->_self shaded]) {
        client_action_start(data);
	[c->_self resizeToWidth: [c->_self area].width
		height: [c->_self area].height +
                     data->relative.delta * [c->_self size_inc].height];
        client_action_end(data);
    }
}

void action_maximize_full(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: YES direction: 0 saveArea: YES];
    client_action_end(data);
}

void action_unmaximize_full(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: NO direction: 0 saveArea: YES];
    client_action_end(data);
}

void action_toggle_maximize_full(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize:  
	       !([data->client.any.c->_self max_horz] || 
		 [data->client.any.c->_self max_vert])
	    direction: 0 saveArea: YES];
    client_action_end(data);
}

void action_maximize_horz(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: YES direction: 1 saveArea: YES];
    client_action_end(data);
}

void action_unmaximize_horz(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: NO direction: 1 saveArea: YES];
    client_action_end(data);
}

void action_toggle_maximize_horz(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: ![data->client.any.c->_self max_horz]
	    direction: 1 saveArea: YES];
    client_action_end(data);
}

void action_maximize_vert(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: YES direction: 2 saveArea: YES];
    client_action_end(data);
}

void action_unmaximize_vert(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: NO direction: 2 saveArea: YES];
    client_action_end(data);
}

void action_toggle_maximize_vert(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self maximize: ![data->client.any.c->_self max_vert]
	    direction: 2 saveArea: YES];
    client_action_end(data);
}

void action_toggle_fullscreen(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c->_self fullscreen: !([data->client.any.c->_self fullscreen])
	                       saveArea: YES];
    client_action_end(data);
}

void action_send_to_desktop(union ActionData *data)
{
    ObClient *c = data->sendto.any.c;

    if (![c->_self normal]) return;

    AZScreen *defaultScreen = [AZScreen defaultScreen];

    if (data->sendto.desk < [defaultScreen numberOfDesktops] ||
        data->sendto.desk == DESKTOP_ALL) {
	[c->_self setDesktop: data->sendto.desk hide: data->sendto.follow];
        if (data->sendto.follow)
	{
	  [defaultScreen setDesktop: data->sendto.desk];
	}
    }
}

void action_desktop(union ActionData *data)
{
    static guint first = (unsigned) -1;
    AZScreen *defaultScreen = [AZScreen defaultScreen];

    if (data->inter.any.interactive && first == (unsigned) -1)
    {
      first = [defaultScreen desktop];
    }

    if (!data->inter.any.interactive ||
        (!data->inter.cancel && !data->inter.final))
    {
        if (data->desktop.desk < [defaultScreen numberOfDesktops] ||
            data->desktop.desk == DESKTOP_ALL)
        {
	    [defaultScreen setDesktop: data->desktop.desk];
            if (data->inter.any.interactive)
	    {
		[defaultScreen desktopPopup: data->desktop.desk
			       show: YES];
	    }
        }
    } else if (data->inter.cancel) {
        [defaultScreen setDesktop: first];
    }

    if (!data->inter.any.interactive || data->inter.final) {
	[defaultScreen desktopPopup: 0 show: NO];
        first = (unsigned) -1;
    }
}

void action_desktop_dir(union ActionData *data)
{
    guint d;
    AZScreen *screen = [AZScreen defaultScreen];

    d = [screen cycleDesktop: data->desktopdir.dir
	                wrap: data->desktopdir.wrap
			linear: data->desktopdir.linear
			dialog: data->desktopdir.inter.any.interactive
			done: data->desktopdir.inter.final
			cancel: data->desktopdir.inter.cancel];

    if (!data->sendtodir.inter.any.interactive ||
        !data->sendtodir.inter.final ||
        data->sendtodir.inter.cancel)
    {
	[screen setDesktop: d];
    }
}

void action_send_to_desktop_dir(union ActionData *data)
{
    ObClient *c = data->sendtodir.inter.any.c;
    guint d;

    if (![c->_self normal]) return;
    AZScreen *screen = [AZScreen defaultScreen];
    d = [screen cycleDesktop: data->sendtodir.dir
	                wrap: data->sendtodir.wrap
			linear: data->sendtodir.linear
			dialog: data->sendtodir.inter.any.interactive
			done: data->sendtodir.inter.final
			cancel: data->sendtodir.inter.cancel];
    if (!data->sendtodir.inter.any.interactive ||
        !data->sendtodir.inter.final ||
        data->sendtodir.inter.cancel)
    {
	[c->_self setDesktop: d hide: data->sendtodir.follow];
        if (data->sendtodir.follow)
	{
            [screen setDesktop: d];
	}
    }
}

void action_desktop_last(union ActionData *data)
{
  AZScreen *screen = [AZScreen defaultScreen];
  [screen setDesktop: [screen lastDesktop]];
}

void action_toggle_decorations(union ActionData *data)
{
    ObClient *c = data->client.any.c;

    client_action_start(data);
    [c->_self setUndecorated: ![c->_self undecorated]];
    client_action_end(data);
}

static guint32 pick_corner(gint x, gint y, gint cx, gint cy, gint cw, gint ch)
{
    if (config_resize_four_corners) {
        if (x - cx > cw / 2) {
            if (y - cy > ch / 2)
                return prop_atoms.net_wm_moveresize_size_bottomright;
            else
                return prop_atoms.net_wm_moveresize_size_topright;
        } else {
            if (y - cy > ch / 2)
                return prop_atoms.net_wm_moveresize_size_bottomleft;
            else
                return prop_atoms.net_wm_moveresize_size_topleft;
        }
    } else {
        if (x - cx > cw * 2 / 3) {
            if (y - cy > ch * 2 / 3)
                return prop_atoms.net_wm_moveresize_size_bottomright;
            else if (y - cy < ch / 3)
                return prop_atoms.net_wm_moveresize_size_topright;
            else
                return prop_atoms.net_wm_moveresize_size_right;
        } else if (x - cx < cw / 3) {
            if (y - cy > ch * 2 / 3)
                return prop_atoms.net_wm_moveresize_size_bottomleft;
            else if (y - cy < ch / 3)
                return prop_atoms.net_wm_moveresize_size_topleft;
            else
                return prop_atoms.net_wm_moveresize_size_left;
        } else
            if (y - cy > ch * 2 / 3)
                return prop_atoms.net_wm_moveresize_size_bottom;
            else if (y - cy < ch / 3)
                return prop_atoms.net_wm_moveresize_size_top;
            else
                return prop_atoms.net_wm_moveresize_move;
    }
}

void action_moveresize(union ActionData *data)
{
    ObClient *c = data->moveresize.any.c;
    guint32 corner;

    if (![c->_self normal]) return;

    if (data->moveresize.keyboard) {
        corner = (data->moveresize.move ?
                  prop_atoms.net_wm_moveresize_move_keyboard :
                  prop_atoms.net_wm_moveresize_size_keyboard);
    } else {
        corner = (data->moveresize.move ?
                  prop_atoms.net_wm_moveresize_move :
                  pick_corner(data->any.x, data->any.y,
                              [[c->_self frame] area].x, [[c->_self frame] area].y,
                              /* use the client size because the frame
                                 can be differently sized (shaded
                                 windows) and we want this based on the
                                 clients size */
                              [c->_self area].width + [[c->_self frame] size].left +
                              [[c->_self frame] size].right,
                              [c->_self area].height + [[c->_self frame] size].top +
                              [[c->_self frame] size].bottom));
    }

    [[AZMoveResizeHandler defaultHandler]
	    startWithClient: c->_self x: data->any.x y: data->any.y
	    button: data->any.button corner: corner];
}

void action_reconfigure(union ActionData *data)
{
    ob_reconfigure();
}

void action_restart(union ActionData *data)
{
    ob_restart_other(data->execute.path);
}

void action_exit(union ActionData *data)
{
    ob_exit(0);
}

void action_showmenu(union ActionData *data)
{
    if (data->showmenu.name) {
        menu_show(data->showmenu.name, data->any.x, data->any.y,
                  data->showmenu.any.c);
    }
}

void action_cycle_windows(union ActionData *data)
{
    /* if using focus_delay, stop the timer now so that focus doesn't go moving
       on us */
    [[AZEventHandler defaultHandler] haltFocusDelay];

    [[AZFocusManager defaultManager] cycleForward: data->cycle.forward
	    linear: data->cycle.linear
	    interactive:  data->any.interactive
            dialog: data->cycle.dialog
            done: data->cycle.inter.final
	    cancel: data->cycle.inter.cancel];
}

void action_directional_focus(union ActionData *data)
{
    /* if using focus_delay, stop the timer now so that focus doesn't go moving
       on us */
    [[AZEventHandler defaultHandler] haltFocusDelay];

    [[AZFocusManager defaultManager] 
            directionalCycle: data->interdiraction.direction
            interactive: data->any.interactive
            dialog: data->interdiraction.dialog
            done: data->interdiraction.inter.final
            cancel: data->interdiraction.inter.cancel];
}

void action_movetoedge(union ActionData *data)
{
    gint x, y;
    ObClient *c = data->diraction.any.c;

    x = [[c->_self frame] area].x;
    y = [[c->_self frame] area].y;
    
    switch(data->diraction.direction) {
    case OB_DIRECTION_NORTH:
	y = [c->_self directionalEdgeSearch: OB_DIRECTION_NORTH];
        //y = client_directional_edge_search(c, OB_DIRECTION_NORTH);
        break;
    case OB_DIRECTION_WEST:
	x = [c->_self directionalEdgeSearch: OB_DIRECTION_WEST];
        //x = client_directional_edge_search(c, OB_DIRECTION_WEST);
        break;
    case OB_DIRECTION_SOUTH:
	y = [c->_self directionalEdgeSearch: OB_DIRECTION_SOUTH] -
        /*y = client_directional_edge_search(c, OB_DIRECTION_SOUTH) -*/
            [[c->_self frame] area].height;
        break;
    case OB_DIRECTION_EAST:
	x = [c->_self directionalEdgeSearch: OB_DIRECTION_EAST] -
        /*x = client_directional_edge_search(c, OB_DIRECTION_EAST) - */
            [[c->_self frame] area].width;
        break;
    default:
        g_assert_not_reached();
    }
    [[c->_self frame] frameGravityAtX: &x y: &y];
    client_action_start(data);
    [c->_self moveToX: x y: y];
    client_action_end(data);
}

void action_growtoedge(union ActionData *data)
{
    gint x, y, width, height, dest;
    ObClient *c = data->diraction.any.c;
    Rect *a;

    //FIXME growtoedge resizes shaded windows to 0 height
    if ([c->_self shaded])
        return;

    a = [[AZScreen defaultScreen] areaOfDesktop: [c->_self desktop]];
    x = [[c->_self frame] area].x;
    y = [[c->_self frame] area].y;
    width = [[c->_self frame] area].width;
    height = [[c->_self frame] area].height;

    switch(data->diraction.direction) {
    case OB_DIRECTION_NORTH:
	dest = [c->_self directionalEdgeSearch: OB_DIRECTION_NORTH];
        //dest = client_directional_edge_search(c, OB_DIRECTION_NORTH);
        if (a->y == y)
            height = [[c->_self frame] area].height / 2;
        else {
            height = [[c->_self frame] area].y + [[c->_self frame] area].height - dest;
            y = dest;
        }
        break;
    case OB_DIRECTION_WEST:
	dest = [c->_self directionalEdgeSearch: OB_DIRECTION_WEST];
        //dest = client_directional_edge_search(c, OB_DIRECTION_WEST);
        if (a->x == x)
            width = [[c->_self frame] area].width / 2;
        else {
            width = [[c->_self frame] area].x + [[c->_self frame] area].width - dest;
            x = dest;
        }
        break;
    case OB_DIRECTION_SOUTH:
	dest = [c->_self directionalEdgeSearch: OB_DIRECTION_SOUTH];
        //dest = client_directional_edge_search(c, OB_DIRECTION_SOUTH);
        if (a->y + a->height == y + [[c->_self frame] area].height) {
            height = [[c->_self frame] area].height / 2;
            y = a->y + a->height - height;
        } else
            height = dest - [[c->_self frame] area].y;
        y += (height - [[c->_self frame] area].height) % [c->_self size_inc].height;
        height -= (height - [[c->_self frame] area].height) % [c->_self size_inc].height;
        break;
    case OB_DIRECTION_EAST:
	dest = [c->_self directionalEdgeSearch: OB_DIRECTION_EAST];
        //dest = client_directional_edge_search(c, OB_DIRECTION_EAST);
        if (a->x + a->width == x + [[c->_self frame] area].width) {
            width = [[c->_self frame] area].width / 2;
            x = a->x + a->width - width;
        } else
            width = dest - [[c->_self frame] area].x;
        x += (width - [[c->_self frame] area].width) % [c->_self size_inc].width;
        width -= (width - [[c->_self frame] area].width) % [c->_self size_inc].width;
        break;
    default:
        g_assert_not_reached();
    }
    [[c->_self frame] frameGravityAtX: &x y: &y];
    width -= [[c->_self frame] size].left + [[c->_self frame] size].right;
    height -= [[c->_self frame] size].top + [[c->_self frame] size].bottom;
    client_action_start(data);
    [c->_self moveAndResizeToX: x y: y width: width height: height];
    client_action_end(data);
}

void action_send_to_layer(union ActionData *data)
{
  [(data->layer.any.c)->_self setLayer: data->layer.layer];
}

void action_toggle_layer(union ActionData *data)
{
    ObClient *c = data->layer.any.c;

    client_action_start(data);
    if (data->layer.layer < 0)
    {
        [c->_self setLayer: [c->_self below] ? 0 : -1];
        //client_set_layer(c, [c->_self below] ? 0 : -1);
    }
    else if (data->layer.layer > 0)
    {
        [c->_self setLayer: [c->_self above] ? 0 : 1];
        //client_set_layer(c, [c->_self above] ? 0 : 1);
    }
    client_action_end(data);
}

void action_toggle_dockautohide(union ActionData *data)
{
    config_dock_hide = !config_dock_hide;
    [[AZDock defaultDock] configure];
}

void action_toggle_show_desktop(union ActionData *data)
{
    AZScreen *screen = [AZScreen defaultScreen];
    [screen showDesktop: ![screen showingDesktop]];
}

void action_show_desktop(union ActionData *data)
{
    [[AZScreen defaultScreen] showDesktop: YES];
}

void action_unshow_desktop(union ActionData *data)
{
    [[AZScreen defaultScreen] showDesktop: NO];
}

