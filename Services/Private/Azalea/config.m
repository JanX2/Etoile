/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   config.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

#import "config.h"
#import "AZKeyboardHandler.h"
#import "AZMouseHandler.h"
#import "prop.h"
#import "translate.h"
#import "parse.h"
#import "openbox.h"

BOOL config_focus_new;
BOOL config_focus_last;

ObPlacePolicy config_place_policy;

NSString *config_theme;
BOOL config_theme_keepborder;
BOOL config_theme_hidedisabled;

NSString *config_title_layout;

int    config_desktops_num;
NSArray *config_desktops_names;
unsigned int    config_screen_firstdesk;

BOOL config_resize_redraw;
BOOL config_resize_four_corners;
int     config_resize_popup_show;
int     config_resize_popup_pos;

unsigned int config_keyboard_reset_keycode;
unsigned int config_keyboard_reset_state;

int config_mouse_threshold;
int config_mouse_dclicktime;

BOOL config_menu_warppointer;
unsigned int    config_menu_hide_delay;
BOOL config_menu_client_list_icons;

NSArray *config_menu_files;

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

static void parse_key(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                      NSMutableArray *keylist)
{
    NSString *key;
    AZAction *action;
    xmlNodePtr n, nact;

    if ((n = parse_find_node("chainQuitKey", node))) {
        key = parse_string(doc, n);
        translate_key(key, &config_keyboard_reset_state,
                      &config_keyboard_reset_keycode);
    }

    key = nil; /* reset, just in case */
    n = parse_find_node("keybind", node);
    while (n) {
        if (parse_attr_string("key", n, &key)) {
	    if (keylist == nil) {
	      keylist = AUTORELEASE([[NSMutableArray alloc] init]);
	    }
	    [keylist addObject: key];

            parse_key(parser, doc, n->children, keylist);

	    [keylist removeLastObject];
        }
        n = parse_find_node("keybind", n->next);
    }
    if ([keylist count]) {
        nact = parse_find_node("action", node);
        while (nact) {
            if ((action = action_parse(doc, nact,
                                       OB_USER_ACTION_KEYBOARD_KEY))) {
		AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];
		[kHandler bind: keylist action: action];
	    }
            nact = parse_find_node("action", nact->next);
        }
    }
}

static void parse_keyboard(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                           void * d)
{
    [[AZKeyboardHandler defaultHandler] unbindAll];

    parse_key(parser, doc, node->children, NULL);
}

/*

<context name="Titlebar"> 
  <mousebind button="Left" action="Press">
    <action name="Raise"></action>
  </mousebind>
</context>

*/

static void parse_mouse(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                        void * d)
{
    xmlNodePtr n, nbut, nact;
    NSString *buttonstr;
    NSString *contextstr;
    ObUserAction uact;
    ObMouseAction mact;
    AZAction *action;
    AZMouseHandler *mouseHandler = [AZMouseHandler defaultHandler];

    [mouseHandler unbindAll];

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
                if ((action = action_parse(doc, nact, uact)))
                    [mouseHandler bind: buttonstr context: contextstr
			    mouseAction: mact action: action];
                nact = parse_find_node("action", nact->next);
            }
        next_nbut:
            nbut = parse_find_node("mousebind", nbut->next);
        }
    next_n:
        n = parse_find_node("context", n->next);
    }
}

static void parse_focus(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                        void * d)
{
    xmlNodePtr n;

    node = node->children;
    
    if ((n = parse_find_node("focusNew", node)))
        config_focus_new = parse_bool(doc, n);
    if ((n = parse_find_node("focusLast", node)))
        config_focus_last = parse_bool(doc, n);
}

static void parse_placement(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                            void * d)
{
    xmlNodePtr n;

    node = node->children;
    
    if ((n = parse_find_node("policy", node)))
        if (parse_contains("UnderMouse", doc, n))
            config_place_policy = OB_PLACE_POLICY_MOUSE;
}

static void parse_theme(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                        void * d)
{
    xmlNodePtr n;

    node = node->children;

    if ((n = parse_find_node("name", node))) {
        NSString *c;

        c = parse_string(doc, n);
	ASSIGN(config_theme, [c stringByExpandingTildeInPath]);
    }
    if ((n = parse_find_node("titleLayout", node))) {
	ASSIGN(config_title_layout, parse_string(doc, n));
    }
    if ((n = parse_find_node("keepBorder", node)))
        config_theme_keepborder = parse_bool(doc, n);
    if ((n = parse_find_node("hideDisabled", node)))
        config_theme_hidedisabled = parse_bool(doc, n);
}

static void parse_desktops(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                           void * d)
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
            config_screen_firstdesk = (unsigned int)d;
    }
    if ((n = parse_find_node("names", node))) {
        xmlNodePtr nname;

	NSMutableArray *a = [[NSMutableArray alloc] init];

        nname = parse_find_node("name", n->children);
        while (nname) {
	    [a addObject: parse_string(doc, nname)];
            nname = parse_find_node("name", nname->next);
        }
	ASSIGNCOPY(config_desktops_names, a);
	DESTROY(a);
    }
}

static void parse_resize(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                         void * d)
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

static void parse_menu(AZParser *parser, xmlDocPtr doc, xmlNodePtr node,
                       void * d)
{
    xmlNodePtr n;
    NSMutableArray *a;
    if (config_menu_files)
      a = [NSMutableArray arrayWithArray: config_menu_files];
    else
      a = AUTORELEASE([[NSMutableArray alloc] init]);

    for (node = node->children; node; node = node->next) {
        if (!xmlStrcasecmp(node->name, (const xmlChar*) "file")) {
            [a addObject: parse_string(doc, node)];
        }
        if ((n = parse_find_node("warpPointer", node)))
            config_menu_warppointer = parse_bool(doc, n);
        if ((n = parse_find_node("hideDelay", node)))
            config_menu_hide_delay = parse_int(doc, n);
        if ((n = parse_find_node("desktopMenuIcons", node)))
            config_menu_client_list_icons = parse_bool(doc, n);
    }
    ASSIGNCOPY(config_menu_files, a);
}
   
static void parse_resistance(AZParser *parser, xmlDocPtr doc, xmlNodePtr node, 
                             void * d)
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
    NSString *key;
    NSString *actname;
} ObDefKeyBind;

static void bind_default_keyboard()
{
    ObDefKeyBind *it;
    ObDefKeyBind binds[] = {
        { @"A-Tab", @"NextWindow" },
        { @"S-A-Tab", @"PreviousWindow" },
        { @"A-F4", @"Close" },
        { NULL, nil}
    };

    for (it = binds; it->key; ++it) {
	[[AZKeyboardHandler defaultHandler] 
		bind: [NSArray arrayWithObjects: it->key, nil]
		action: [AZAction actionWithName: it->actname userAction: OB_USER_ACTION_KEYBOARD_KEY]];
    }
}

typedef struct
{
    NSString *button;
    NSString *context;
    const ObMouseAction mact;
    NSString *actname;
} ObDefMouseBind;

static void bind_default_mouse()
{
    ObDefMouseBind *it;
    ObDefMouseBind binds[] = {
        { @"Left", @"Client", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Middle", @"Client", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Right", @"Client", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Desktop", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Middle", @"Desktop", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Right", @"Desktop", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Titlebar", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Handle", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"BLCorner", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"BRCorner", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"TLCorner", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"TRCorner", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Close", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Maximize", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Iconify", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Icon", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"AllDesktops", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Shade", OB_MOUSE_ACTION_PRESS, @"Focus" },
        { @"Left", @"Client", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Titlebar", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Middle", @"Titlebar", OB_MOUSE_ACTION_CLICK, @"Lower" },
        { @"Left", @"Handle", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"BLCorner", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"BRCorner", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"TLCorner", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"TRCorner", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Close", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Maximize", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Iconify", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Icon", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"AllDesktops", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Shade", OB_MOUSE_ACTION_CLICK, @"Raise" },
        { @"Left", @"Close", OB_MOUSE_ACTION_CLICK, @"Close" },
        { @"Left", @"Maximize", OB_MOUSE_ACTION_CLICK, @"ToggleMaximizeFull" },
        { @"Left", @"Iconify", OB_MOUSE_ACTION_CLICK, @"Iconify" },
        { @"Left", @"AllDesktops", OB_MOUSE_ACTION_CLICK, @"ToggleOmnipresent" },
        { @"Left", @"Shade", OB_MOUSE_ACTION_CLICK, @"ToggleShade" },
        { @"Left", @"TLCorner", OB_MOUSE_ACTION_MOTION, @"Resize" },
        { @"Left", @"TRCorner", OB_MOUSE_ACTION_MOTION, @"Resize" },
        { @"Left", @"BLCorner", OB_MOUSE_ACTION_MOTION, @"Resize" },
        { @"Left", @"BRCorner", OB_MOUSE_ACTION_MOTION, @"Resize" },
        { @"Left", @"Titlebar", OB_MOUSE_ACTION_MOTION, @"Move" },
        { @"A-Left", @"Frame", OB_MOUSE_ACTION_MOTION, @"Move" },
        { @"A-Middle", @"Frame", OB_MOUSE_ACTION_MOTION, @"Resize" },
        { nil, nil, 0, nil}
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
        default:
            NSLog(@"Internal Error: should reach here");
        }
	[[AZMouseHandler defaultHandler] bind: it->button
		context: it->context mouseAction: it->mact
                   action: [AZAction actionWithName: it->actname userAction: uact]];
    }
}

void config_startup(AZParser *parser)
{
    config_focus_new = YES;
    config_focus_last = NO;

    [parser registerTag: @"focus" callback: parse_focus data: NULL];

    config_place_policy = OB_PLACE_POLICY_SMART;

    [parser registerTag: @"placement" callback: parse_placement data: NULL];

    config_theme = nil;

    ASSIGN(config_title_layout, ([NSString stringWithCString: "NLIMC"]));
    config_theme_keepborder = YES;
    config_theme_hidedisabled = NO;

    [parser registerTag: @"theme" callback: parse_theme data: NULL];

    config_desktops_num = 4;
    config_screen_firstdesk = 1;
    config_desktops_names = nil;

    [parser registerTag: @"desktops" callback: parse_desktops data: NULL];

    config_resize_redraw = YES;
    config_resize_four_corners = NO;
    config_resize_popup_show = 1; /* nonpixel increments */
    config_resize_popup_pos = 0;  /* center of client */

    [parser registerTag: @"resize" callback: parse_resize data: NULL];

    translate_key(@"C-g", &config_keyboard_reset_state,
                  &config_keyboard_reset_keycode);

    bind_default_keyboard();

    [parser registerTag: @"keyboard" callback: parse_keyboard data: NULL];

    config_mouse_threshold = 3;
    config_mouse_dclicktime = 200;

    bind_default_mouse();

    [parser registerTag: @"mouse" callback: parse_mouse data: NULL];

    config_resist_win = 10;
    config_resist_edge = 20;
    config_resist_layers_below = NO;

    [parser registerTag: @"resistance" callback: parse_resistance data: NULL];

    config_menu_warppointer = YES;
    config_menu_hide_delay = 250;
    config_menu_client_list_icons = YES;
    config_menu_files = nil;

    [parser registerTag: @"menu" callback: parse_menu data: NULL];
}

void config_shutdown()
{
    DESTROY(config_theme);
    DESTROY(config_title_layout);
    DESTROY(config_desktops_names);
    DESTROY(config_menu_files);
}
