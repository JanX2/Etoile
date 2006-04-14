/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   config.c for the Openbox window manager
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

#import "AZDock.h"
#import "config.h"
#import "AZKeyboardHandler.h"
#import "mouse.h"
#import "prop.h"
#import "translate.h"
#import "parse.h"
#import "openbox.h"

BOOL config_focus_new;
BOOL config_focus_follow;
unsigned int    config_focus_delay;
BOOL config_focus_raise;
BOOL config_focus_last;

ObPlacePolicy config_place_policy;

gchar   *config_theme;
BOOL config_theme_keepborder;
BOOL config_theme_hidedisabled;

gchar *config_title_layout;

int    config_desktops_num;
GSList *config_desktops_names;
int    config_screen_firstdesk;

BOOL config_resize_redraw;
BOOL config_resize_four_corners;
int     config_resize_popup_show;
int     config_resize_popup_pos;

ObStackingLayer config_dock_layer;
BOOL        config_dock_floating;
BOOL        config_dock_nostrut;
ObDirection     config_dock_pos;
int            config_dock_x;
int            config_dock_y;
ObOrientation   config_dock_orient;
BOOL        config_dock_hide;
unsigned int           config_dock_hide_delay;
unsigned int           config_dock_show_delay;
unsigned int           config_dock_app_move_button;
unsigned int           config_dock_app_move_modifiers;

unsigned int config_keyboard_reset_keycode;
unsigned int config_keyboard_reset_state;

int config_mouse_threshold;
int config_mouse_dclicktime;

BOOL config_menu_warppointer;
BOOL config_menu_xorstyle;
unsigned int    config_menu_hide_delay;
BOOL config_menu_client_list_icons;

GSList *config_menu_files;

int config_resist_win;
int config_resist_edge;

BOOL config_resist_layers_below;

/*

<keybind key="C-x">
  <action name="ChangeDesktop">
    <desktop>3</desktop>
  </action>
</keybind>

*/

static void parse_key(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                      GList *keylist)
{
    gchar *key;
    AZAction *action;
    xmlNodePtr n, nact;
    GList *it;

    if ((n = parse_find_node("chainQuitKey", node))) {
        key = parse_string(doc, n);
        translate_key(key, &config_keyboard_reset_state,
                      &config_keyboard_reset_keycode);
        g_free(key);
    }

    n = parse_find_node("keybind", node);
    while (n) {
        if (parse_attr_string("key", n, &key)) {
            keylist = g_list_append(keylist, key);

            parse_key(i, doc, n->children, keylist);

            it = g_list_last(keylist);
            g_free(it->data);
            keylist = g_list_delete_link(keylist, it);
        }
        n = parse_find_node("keybind", n->next);
    }
    if (keylist) {
        nact = parse_find_node("action", node);
        while (nact) {
            if ((action = action_parse(i, doc, nact,
                                       OB_USER_ACTION_KEYBOARD_KEY))) {
		AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];
		[kHandler bind: keylist action: action];
	    }
            nact = parse_find_node("action", nact->next);
        }
    }
}

static void parse_keyboard(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                           gpointer d)
{
    [[AZKeyboardHandler defaultHandler] unbindAll];

    parse_key(i, doc, node->children, NULL);
}

/*

<context name="Titlebar"> 
  <mousebind button="Left" action="Press">
    <action name="Raise"></action>
  </mousebind>
</context>

*/

static void parse_mouse(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                        gpointer d)
{
    xmlNodePtr n, nbut, nact;
    gchar *buttonstr;
    gchar *contextstr;
    ObUserAction uact;
    ObMouseAction mact;
    AZAction *action;

    mouse_unbind_all();

    node = node->children;
    
    if ((n = parse_find_node("dragThreshold", node)))
        config_mouse_threshold = parse_int(doc, n);
    if ((n = parse_find_node("doubleClickTime", node)))
        config_mouse_dclicktime = parse_int(doc, n);

    n = parse_find_node("context", node);
    while (n) {
        if (!parse_attr_string("name", n, &contextstr))
            goto next_n;
        nbut = parse_find_node("mousebind", n->children);
        while (nbut) {
            if (!parse_attr_string("button", nbut, &buttonstr))
                goto next_nbut;
            if (parse_attr_contains("press", nbut, "action")) {
                uact = OB_USER_ACTION_MOUSE_PRESS;
                mact = OB_MOUSE_ACTION_PRESS;
            } else if (parse_attr_contains("release", nbut, "action")) {
                uact = OB_USER_ACTION_MOUSE_RELEASE;
                mact = OB_MOUSE_ACTION_RELEASE;
            } else if (parse_attr_contains("click", nbut, "action")) {
                uact = OB_USER_ACTION_MOUSE_CLICK;
                mact = OB_MOUSE_ACTION_CLICK;
            } else if (parse_attr_contains("doubleclick", nbut,"action")) {
                uact = OB_USER_ACTION_MOUSE_DOUBLE_CLICK;
                mact = OB_MOUSE_ACTION_DOUBLE_CLICK;
            } else if (parse_attr_contains("drag", nbut, "action")) {
                uact = OB_USER_ACTION_MOUSE_MOTION;
                mact = OB_MOUSE_ACTION_MOTION;
            } else
                goto next_nbut;
            nact = parse_find_node("action", nbut->children);
            while (nact) {
                if ((action = action_parse(i, doc, nact, uact)))
                    mouse_bind(buttonstr, contextstr, mact, action);
                nact = parse_find_node("action", nact->next);
            }
            g_free(buttonstr);
        next_nbut:
            nbut = parse_find_node("mousebind", nbut->next);
        }
        g_free(contextstr);
    next_n:
        n = parse_find_node("context", n->next);
    }
}

static void parse_focus(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                        gpointer d)
{
    xmlNodePtr n;

    node = node->children;
    
    if ((n = parse_find_node("focusNew", node)))
        config_focus_new = parse_bool(doc, n);
    if ((n = parse_find_node("followMouse", node)))
        config_focus_follow = parse_bool(doc, n);
    if ((n = parse_find_node("focusDelay", node)))
        config_focus_delay = parse_int(doc, n) * 1000;
    if ((n = parse_find_node("raiseOnFocus", node)))
        config_focus_raise = parse_bool(doc, n);
    if ((n = parse_find_node("focusLast", node)))
        config_focus_last = parse_bool(doc, n);
}

static void parse_placement(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                            gpointer d)
{
    xmlNodePtr n;

    node = node->children;
    
    if ((n = parse_find_node("policy", node)))
        if (parse_contains("UnderMouse", doc, n))
            config_place_policy = OB_PLACE_POLICY_MOUSE;
}

static void parse_theme(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                        gpointer d)
{
    xmlNodePtr n;

    node = node->children;

    if ((n = parse_find_node("name", node))) {
        gchar *c;

        g_free(config_theme);
        c = parse_string(doc, n);
        config_theme = parse_expand_tilde(c);
        g_free(c);
    }
    if ((n = parse_find_node("titleLayout", node))) {
        g_free(config_title_layout);
        config_title_layout = parse_string(doc, n);
    }
    if ((n = parse_find_node("keepBorder", node)))
        config_theme_keepborder = parse_bool(doc, n);
    if ((n = parse_find_node("hideDisabled", node)))
        config_theme_hidedisabled = parse_bool(doc, n);
}

static void parse_desktops(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                           gpointer d)
{
    xmlNodePtr n;

    node = node->children;
    
    if ((n = parse_find_node("number", node))) {
        int d = parse_int(doc, n);
        if (d > 0)
            config_desktops_num = d;
    }
    if ((n = parse_find_node("firstdesk", node))) {
        int d = parse_int(doc, n);
        if (d > 0)
            config_screen_firstdesk = d;
    }
    if ((n = parse_find_node("names", node))) {
        GSList *it;
        xmlNodePtr nname;

        for (it = config_desktops_names; it; it = it->next)
            g_free(it->data);
        g_slist_free(config_desktops_names);
        config_desktops_names = NULL;

        nname = parse_find_node("name", n->children);
        while (nname) {
            config_desktops_names = g_slist_append(config_desktops_names,
                                                   parse_string(doc, nname));
            nname = parse_find_node("name", nname->next);
        }
    }
}

static void parse_resize(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                         gpointer d)
{
    xmlNodePtr n;

    node = node->children;
    
    if ((n = parse_find_node("drawContents", node)))
        config_resize_redraw = parse_bool(doc, n);
    if ((n = parse_find_node("fourCorner", node)))
        config_resize_four_corners = parse_bool(doc, n);
    if ((n = parse_find_node("popupShow", node))) {
        config_resize_popup_show = parse_int(doc, n);
        if (parse_contains("Always", doc, n))
            config_resize_popup_show = 2;
        else if (parse_contains("Never", doc, n))
            config_resize_popup_show = 0;
        else if (parse_contains("Nonpixel", doc, n))
            config_resize_popup_show = 1;
    }
    if ((n = parse_find_node("popupPosition", node))) {
        config_resize_popup_pos = parse_int(doc, n);
        if (parse_contains("Top", doc, n))
            config_resize_popup_pos = 1;
        else if (parse_contains("Center", doc, n))
            config_resize_popup_pos = 0;
    }
}

static void parse_dock(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                       gpointer d)
{
    xmlNodePtr n;

    node = node->children;

    if ((n = parse_find_node("position", node))) {
        if (parse_contains("TopLeft", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_NORTHWEST;
        else if (parse_contains("Top", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_NORTH;
        else if (parse_contains("TopRight", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_NORTHEAST;
        else if (parse_contains("Right", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_EAST;
        else if (parse_contains("BottomRight", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_SOUTHEAST;
        else if (parse_contains("Bottom", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_SOUTH;
        else if (parse_contains("BottomLeft", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_SOUTHWEST;
        else if (parse_contains("Left", doc, n))
            config_dock_floating = NO,
            config_dock_pos = OB_DIRECTION_WEST;
        else if (parse_contains("Floating", doc, n))
            config_dock_floating = YES;
    }
    if (config_dock_floating) {
        if ((n = parse_find_node("floatingX", node)))
            config_dock_x = parse_int(doc, n);
        if ((n = parse_find_node("floatingY", node)))
            config_dock_y = parse_int(doc, n);
    } else {
        if ((n = parse_find_node("noStrut", node)))
            config_dock_nostrut = parse_bool(doc, n);
    }
    if ((n = parse_find_node("stacking", node))) {
        if (parse_contains("top", doc, n))
            config_dock_layer = OB_STACKING_LAYER_ABOVE;
        else if (parse_contains("normal", doc, n))
            config_dock_layer = OB_STACKING_LAYER_NORMAL;
        else if (parse_contains("bottom", doc, n))
            config_dock_layer = OB_STACKING_LAYER_BELOW;
    }
    if ((n = parse_find_node("direction", node))) {
        if (parse_contains("horizontal", doc, n))
            config_dock_orient = OB_ORIENTATION_HORZ;
        else if (parse_contains("vertical", doc, n))
            config_dock_orient = OB_ORIENTATION_VERT;
    }
    if ((n = parse_find_node("autoHide", node)))
        config_dock_hide = parse_bool(doc, n);
    if ((n = parse_find_node("hideDelay", node)))
        config_dock_hide_delay = parse_int(doc, n) * 1000;
    if ((n = parse_find_node("showDelay", node)))
        config_dock_show_delay = parse_int(doc, n) * 1000;
    if ((n = parse_find_node("moveButton", node))) {
        gchar *str = parse_string(doc, n);
        unsigned int b, s;
        if (translate_button(str, &s, &b)) {
            config_dock_app_move_button = b;
            config_dock_app_move_modifiers = s;
        } else {
            g_warning("invalid button '%s'", str);
        }
        g_free(str);
    }
}

static void parse_menu(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node,
                       gpointer d)
{
    xmlNodePtr n;
    for (node = node->children; node; node = node->next) {
        if (!xmlStrcasecmp(node->name, (const xmlChar*) "file")) {
            gchar *c;

            c = parse_string(doc, node);
            config_menu_files = g_slist_append(config_menu_files,
                                               parse_expand_tilde(c));
            g_free(c);
        }
        if ((n = parse_find_node("warpPointer", node)))
            config_menu_warppointer = parse_bool(doc, n);
        if ((n = parse_find_node("xorStyle", node)))
            config_menu_xorstyle = parse_bool(doc, n);
        if ((n = parse_find_node("hideDelay", node)))
            config_menu_hide_delay = parse_int(doc, n);
        if ((n = parse_find_node("desktopMenuIcons", node)))
            config_menu_client_list_icons = parse_bool(doc, n);
    }
}
   
static void parse_resistance(ObParseInst *i, xmlDocPtr doc, xmlNodePtr node, 
                             gpointer d)
{
    xmlNodePtr n;

    node = node->children;
    if ((n = parse_find_node("strength", node)))
        config_resist_win = parse_int(doc, n);
    if ((n = parse_find_node("screen_edge_strength", node)))
        config_resist_edge = parse_int(doc, n);
    if ((n = parse_find_node("edges_hit_layers_below", node)))
        config_resist_layers_below = parse_bool(doc, n);
}

typedef struct
{
    const gchar *key;
    const gchar *actname;
} ObDefKeyBind;

static void bind_default_keyboard()
{
    ObDefKeyBind *it;
    ObDefKeyBind binds[] = {
        { "A-Tab", "NextWindow" },
        { "S-A-Tab", "PreviousWindow" },
        { "A-F4", "Close" },
        { NULL, NULL }
    };

    for (it = binds; it->key; ++it) {
        GList *l = g_list_append(NULL, g_strdup(it->key));
	[[AZKeyboardHandler defaultHandler] bind: l
		action: action_from_string(it->actname, OB_USER_ACTION_KEYBOARD_KEY)];
    }
}

typedef struct
{
    const gchar *button;
    const gchar *context;
    const ObMouseAction mact;
    const gchar *actname;
} ObDefMouseBind;

static void bind_default_mouse()
{
    ObDefMouseBind *it;
    ObDefMouseBind binds[] = {
        { "Left", "Client", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Middle", "Client", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Right", "Client", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Desktop", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Middle", "Desktop", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Right", "Desktop", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Titlebar", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Handle", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "BLCorner", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "BRCorner", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "TLCorner", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "TRCorner", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Close", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Maximize", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Iconify", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Icon", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "AllDesktops", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Shade", OB_MOUSE_ACTION_PRESS, "Focus" },
        { "Left", "Client", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Titlebar", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Middle", "Titlebar", OB_MOUSE_ACTION_CLICK, "Lower" },
        { "Left", "Handle", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "BLCorner", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "BRCorner", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "TLCorner", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "TRCorner", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Close", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Maximize", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Iconify", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Icon", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "AllDesktops", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Shade", OB_MOUSE_ACTION_CLICK, "Raise" },
        { "Left", "Close", OB_MOUSE_ACTION_CLICK, "Close" },
        { "Left", "Maximize", OB_MOUSE_ACTION_CLICK, "ToggleMaximizeFull" },
        { "Left", "Iconify", OB_MOUSE_ACTION_CLICK, "Iconify" },
        { "Left", "AllDesktops", OB_MOUSE_ACTION_CLICK, "ToggleOmnipresent" },
        { "Left", "Shade", OB_MOUSE_ACTION_CLICK, "ToggleShade" },
        { "Left", "TLCorner", OB_MOUSE_ACTION_MOTION, "Resize" },
        { "Left", "TRCorner", OB_MOUSE_ACTION_MOTION, "Resize" },
        { "Left", "BLCorner", OB_MOUSE_ACTION_MOTION, "Resize" },
        { "Left", "BRCorner", OB_MOUSE_ACTION_MOTION, "Resize" },
        { "Left", "Titlebar", OB_MOUSE_ACTION_MOTION, "Move" },
        { "A-Left", "Frame", OB_MOUSE_ACTION_MOTION, "Move" },
        { "A-Middle", "Frame", OB_MOUSE_ACTION_MOTION, "Resize" },
        { NULL, NULL, 0, NULL }
    };

    for (it = binds; it->button; ++it) {
        ObUserAction uact;
        switch (it->mact) {
        case OB_MOUSE_ACTION_PRESS:
            uact = OB_USER_ACTION_MOUSE_PRESS; break;
        case OB_MOUSE_ACTION_RELEASE:
            uact = OB_USER_ACTION_MOUSE_RELEASE; break;
        case OB_MOUSE_ACTION_CLICK:
            uact = OB_USER_ACTION_MOUSE_CLICK; break;
        case OB_MOUSE_ACTION_DOUBLE_CLICK:
            uact = OB_USER_ACTION_MOUSE_DOUBLE_CLICK; break;
        case OB_MOUSE_ACTION_MOTION:
            uact = OB_USER_ACTION_MOUSE_MOTION; break;
        case OB_NUM_MOUSE_ACTIONS:
            g_assert_not_reached();
        }
        mouse_bind(it->button, it->context, it->mact,
                   action_from_string(it->actname, uact));
    }
}

void config_startup(ObParseInst *i)
{
    config_focus_new = YES;
    config_focus_follow = NO;
    config_focus_delay = 0;
    config_focus_raise = NO;
    config_focus_last = NO;

    parse_register(i, "focus", parse_focus, NULL);

    config_place_policy = OB_PLACE_POLICY_SMART;

    parse_register(i, "placement", parse_placement, NULL);

    config_theme = NULL;

    config_title_layout = g_strdup("NLIMC");
    config_theme_keepborder = YES;
    config_theme_hidedisabled = NO;

    parse_register(i, "theme", parse_theme, NULL);

    config_desktops_num = 4;
    config_screen_firstdesk = 1;
    config_desktops_names = NULL;

    parse_register(i, "desktops", parse_desktops, NULL);

    config_resize_redraw = YES;
    config_resize_four_corners = NO;
    config_resize_popup_show = 1; /* nonpixel increments */
    config_resize_popup_pos = 0;  /* center of client */

    parse_register(i, "resize", parse_resize, NULL);

    config_dock_layer = OB_STACKING_LAYER_ABOVE;
    config_dock_pos = OB_DIRECTION_NORTHEAST;
    config_dock_floating = NO;
    config_dock_nostrut = NO;
    config_dock_x = 0;
    config_dock_y = 0;
    config_dock_orient = OB_ORIENTATION_VERT;
    config_dock_hide = NO;
    config_dock_hide_delay = 300;
    config_dock_show_delay = 300;
    config_dock_app_move_button = 2; /* middle */
    config_dock_app_move_modifiers = 0;

    parse_register(i, "dock", parse_dock, NULL);

    translate_key("C-g", &config_keyboard_reset_state,
                  &config_keyboard_reset_keycode);

    bind_default_keyboard();

    parse_register(i, "keyboard", parse_keyboard, NULL);

    config_mouse_threshold = 3;
    config_mouse_dclicktime = 200;

    bind_default_mouse();

    parse_register(i, "mouse", parse_mouse, NULL);

    config_resist_win = 10;
    config_resist_edge = 20;
    config_resist_layers_below = NO;

    parse_register(i, "resistance", parse_resistance, NULL);

    config_menu_warppointer = YES;
    config_menu_xorstyle = YES;
    config_menu_hide_delay = 250;
    config_menu_client_list_icons = YES;
    config_menu_files = NULL;

    parse_register(i, "menu", parse_menu, NULL);
}

void config_shutdown()
{
    GSList *it;

    g_free(config_theme);

    g_free(config_title_layout);

    for (it = config_desktops_names; it; it = g_slist_next(it))
        g_free(it->data);
    g_slist_free(config_desktops_names);

    for (it = config_menu_files; it; it = g_slist_next(it))
        g_free(it->data);
    g_slist_free(config_menu_files);
}
