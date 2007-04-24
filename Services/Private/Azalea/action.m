/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
 
   action.c for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

#import "AZStacking.h"
#import "AZClient.h"
#import "AZMoveResizeHandler.h"
#import "prop.h"
#import "action.h"
#import "openbox.h"
#import "grab.h"
#import "AZKeyboardHandler.h"
#import "config.h"
#import "AZMainLoop.h"
#import "AZScreen.h"
#import "AZEventHandler.h"
#import "AZFocusManager.h"
#import "AZMenuFrame.h"
#import "AZMenuManager.h"
#import "AZStartupHandler.h"
#import <AppKit/AppKit.h>

inline void client_action_start(union ActionData *data)
{
}

inline void client_action_end(union ActionData *data)
{
}

typedef struct
{
    NSString *name;
    void (*func)(union ActionData *);
    void (*setup)(AZAction **, ObUserAction uact);
} ActionString;

void setup_action_directional_focus_north(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_NORTH;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_east(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_EAST;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_south(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_SOUTH;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_west(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_WEST;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_northeast(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_NORTHEAST;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_southeast(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_SOUTHEAST;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_southwest(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_SOUTHWEST;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_directional_focus_northwest(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->interdiraction.inter.any.interactive = YES;
    [(*a) data_pointer]->interdiraction.direction = OB_DIRECTION_NORTHWEST;
    [(*a) data_pointer]->interdiraction.dialog = YES;
}

void setup_action_send_to_desktop(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendto.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendto.follow = YES;
}

void setup_action_send_to_desktop_prev(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendtodir.inter.any.interactive = YES;
    [(*a) data_pointer]->sendtodir.dir = OB_DIRECTION_WEST;
    [(*a) data_pointer]->sendtodir.linear = YES;
    [(*a) data_pointer]->sendtodir.wrap = YES;
    [(*a) data_pointer]->sendtodir.follow = YES;
}

void setup_action_send_to_desktop_next(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendtodir.inter.any.interactive = YES;
    [(*a) data_pointer]->sendtodir.dir = OB_DIRECTION_EAST;
    [(*a) data_pointer]->sendtodir.linear = YES;
    [(*a) data_pointer]->sendtodir.wrap = YES;
    [(*a) data_pointer]->sendtodir.follow = YES;
}

void setup_action_send_to_desktop_left(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendtodir.inter.any.interactive = YES;
    [(*a) data_pointer]->sendtodir.dir = OB_DIRECTION_WEST;
    [(*a) data_pointer]->sendtodir.linear = NO;
    [(*a) data_pointer]->sendtodir.wrap = YES;
    [(*a) data_pointer]->sendtodir.follow = YES;
}

void setup_action_send_to_desktop_right(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendtodir.inter.any.interactive = YES;
    [(*a) data_pointer]->sendtodir.dir = OB_DIRECTION_EAST;
    [(*a) data_pointer]->sendtodir.linear = NO;
    [(*a) data_pointer]->sendtodir.wrap = YES;
    [(*a) data_pointer]->sendtodir.follow = YES;
}

void setup_action_send_to_desktop_up(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendtodir.inter.any.interactive = YES;
    [(*a) data_pointer]->sendtodir.dir = OB_DIRECTION_NORTH;
    [(*a) data_pointer]->sendtodir.linear = NO;
    [(*a) data_pointer]->sendtodir.wrap = YES;
    [(*a) data_pointer]->sendtodir.follow = YES;
}

void setup_action_send_to_desktop_down(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->sendtodir.inter.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->sendtodir.inter.any.interactive = YES;
    [(*a) data_pointer]->sendtodir.dir = OB_DIRECTION_SOUTH;
    [(*a) data_pointer]->sendtodir.linear = NO;
    [(*a) data_pointer]->sendtodir.wrap = YES;
    [(*a) data_pointer]->sendtodir.follow = YES;
}

void setup_action_desktop(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktop.inter.any.interactive = NO;
}

void setup_action_desktop_prev(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktopdir.inter.any.interactive = YES;
    [(*a) data_pointer]->desktopdir.dir = OB_DIRECTION_WEST;
    [(*a) data_pointer]->desktopdir.linear = YES;
    [(*a) data_pointer]->desktopdir.wrap = YES;
}

void setup_action_desktop_next(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktopdir.inter.any.interactive = YES;
    [(*a) data_pointer]->desktopdir.dir = OB_DIRECTION_EAST;
    [(*a) data_pointer]->desktopdir.linear = YES;
    [(*a) data_pointer]->desktopdir.wrap = YES;
}

void setup_action_desktop_left(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktopdir.inter.any.interactive = YES;
    [(*a) data_pointer]->desktopdir.dir = OB_DIRECTION_WEST;
    [(*a) data_pointer]->desktopdir.linear = NO;
    [(*a) data_pointer]->desktopdir.wrap = YES;
}

void setup_action_desktop_right(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktopdir.inter.any.interactive = YES;
    [(*a) data_pointer]->desktopdir.dir = OB_DIRECTION_EAST;
    [(*a) data_pointer]->desktopdir.linear = NO;
    [(*a) data_pointer]->desktopdir.wrap = YES;
}

void setup_action_desktop_up(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktopdir.inter.any.interactive = YES;
    [(*a) data_pointer]->desktopdir.dir = OB_DIRECTION_NORTH;
    [(*a) data_pointer]->desktopdir.linear = NO;
    [(*a) data_pointer]->desktopdir.wrap = YES;
}

void setup_action_desktop_down(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->desktopdir.inter.any.interactive = YES;
    [(*a) data_pointer]->desktopdir.dir = OB_DIRECTION_SOUTH;
    [(*a) data_pointer]->desktopdir.linear = NO;
    [(*a) data_pointer]->desktopdir.wrap = YES;
}

void setup_action_cycle_windows_next(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->cycle.inter.any.interactive = YES;
    [(*a) data_pointer]->cycle.linear = NO;
    [(*a) data_pointer]->cycle.forward = YES;
    [(*a) data_pointer]->cycle.dialog = YES;
    [(*a) data_pointer]->cycle.opaque = NO;
}

void setup_action_cycle_windows_previous(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->cycle.inter.any.interactive = YES;
    [(*a) data_pointer]->cycle.linear = NO;
    [(*a) data_pointer]->cycle.forward = NO;
    [(*a) data_pointer]->cycle.dialog = YES;
    [(*a) data_pointer]->cycle.opaque = NO;
}

void setup_action_movetoedge_north(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_NORTH;
}

void setup_action_movetoedge_south(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_SOUTH;
}

void setup_action_movetoedge_east(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_EAST;
}

void setup_action_movetoedge_west(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_WEST;
}

void setup_action_growtoedge_north(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_NORTH;
}

void setup_action_growtoedge_south(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_SOUTH;
}

void setup_action_growtoedge_east(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_EAST;
}

void setup_action_growtoedge_west(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->diraction.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->diraction.direction = OB_DIRECTION_WEST;
}

void setup_action_top_layer(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->layer.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->layer.layer = 1;
}

void setup_action_normal_layer(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->layer.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->layer.layer = 0;
}

void setup_action_bottom_layer(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->layer.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->layer.layer = -1;
}

void setup_action_move(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->moveresize.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->moveresize.move = YES;
    [(*a) data_pointer]->moveresize.keyboard =
        (uact == OB_USER_ACTION_NONE ||
         uact == OB_USER_ACTION_KEYBOARD_KEY ||
         uact == OB_USER_ACTION_MENU_SELECTION);
}

void setup_action_resize(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->moveresize.any.client_action = OB_CLIENT_ACTION_ALWAYS;
    [(*a) data_pointer]->moveresize.move = NO;
    [(*a) data_pointer]->moveresize.keyboard =
        (uact == OB_USER_ACTION_NONE ||
         uact == OB_USER_ACTION_KEYBOARD_KEY ||
         uact == OB_USER_ACTION_MENU_SELECTION);
}

void setup_action_showmenu(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->showmenu.any.client_action = OB_CLIENT_ACTION_OPTIONAL;
    /* you cannot call ShowMenu from inside a menu, cuz the menu code makes
       assumptions that there is only one menu (and submenus) open at
       a time! */
    if (uact == OB_USER_ACTION_MENU_SELECTION) {
        *a = NULL;
    }
}

void setup_client_action(AZAction **a, ObUserAction uact)
{
    [(*a) data_pointer]->any.client_action = OB_CLIENT_ACTION_ALWAYS;
}

ActionString actionstrings[] =
{
    {
        @"execute", 
        action_execute, 
        NULL
    },
    {
        @"directionalfocusnorth", 
        action_directional_focus, 
        setup_action_directional_focus_north
    },
    {
        @"directionalfocuseast", 
        action_directional_focus, 
        setup_action_directional_focus_east
    },
    {
        @"directionalfocussouth", 
        action_directional_focus, 
        setup_action_directional_focus_south
    },
    {
        @"directionalfocuswest",
        action_directional_focus,
        setup_action_directional_focus_west
    },
    {
        @"directionalfocusnortheast",
        action_directional_focus,
        setup_action_directional_focus_northeast
    },
    {
        @"directionalfocussoutheast",
        action_directional_focus,
        setup_action_directional_focus_southeast
    },
    {
        @"directionalfocussouthwest",
        action_directional_focus,
        setup_action_directional_focus_southwest
    },
    {
        @"directionalfocusnorthwest",
        action_directional_focus,
        setup_action_directional_focus_northwest
    },
    {
        @"activate",
        action_activate,
        setup_client_action
    },
    {
        @"focus",
        action_focus,
        setup_client_action
    },
    {
        @"unfocus",
        action_unfocus,
        setup_client_action
    },
    {
        @"iconify",
        action_iconify,
        setup_client_action
    },
    {
        @"focustobottom",
        action_focus_order_to_bottom,
        setup_client_action
    },
    {
        @"raiselower",
        action_raiselower,
        setup_client_action
    },
    {
        @"raise",
        action_raise,
        setup_client_action
    },
    {
        @"lower",
        action_lower,
        setup_client_action
    },
    {
        @"close",
        action_close,
        setup_client_action
    },
    {
        @"kill",
        action_kill,
        setup_client_action
    },
    {
        @"shadelower",
        action_shadelower,
        setup_client_action
    },
    {
        @"unshaderaise",
        action_unshaderaise,
        setup_client_action
    },
    {
        @"shade",
        action_shade,
        setup_client_action
    },
    {
        @"unshade",
        action_unshade,
        setup_client_action
    },
    {
        @"toggleshade",
        action_toggle_shade,
        setup_client_action
    },
    {
        @"toggleomnipresent",
        action_toggle_omnipresent,
        setup_client_action
    },
    {
        @"moverelativehorz",
        action_move_relative_horz,
        setup_client_action
    },
    {
        @"moverelativevert",
        action_move_relative_vert,
        setup_client_action
    },
    {
        @"movetocenter",
        action_move_to_center,
        setup_client_action
    },
    {
        @"resizerelativehorz",
        action_resize_relative_horz,
        setup_client_action
    },
    {
        @"resizerelativevert",
        action_resize_relative_vert,
        setup_client_action
    },
    {
	@"moverelative",
	action_move_relative,
	setup_client_action
    },
    {
	@"resizerelative",
	action_resize_relative,
	setup_client_action
    },
    {
        @"maximizefull",
        action_maximize_full,
        setup_client_action
    },
    {
        @"unmaximizefull",
        action_unmaximize_full,
        setup_client_action
    },
    {
        @"togglemaximizefull",
        action_toggle_maximize_full,
        setup_client_action
    },
    {
        @"maximizehorz",
        action_maximize_horz,
        setup_client_action
    },
    {
        @"unmaximizehorz",
        action_unmaximize_horz,
        setup_client_action
    },
    {
        @"togglemaximizehorz",
        action_toggle_maximize_horz,
        setup_client_action
    },
    {
        @"maximizevert",
        action_maximize_vert,
        setup_client_action
    },
    {
        @"unmaximizevert",
        action_unmaximize_vert,
        setup_client_action
    },
    {
        @"togglemaximizevert",
        action_toggle_maximize_vert,
        setup_client_action
    },
    {
        @"togglefullscreen",
        action_toggle_fullscreen,
        setup_client_action
    },
    {
        @"sendtodesktop",
        action_send_to_desktop,
        setup_action_send_to_desktop
    },
    {
        @"sendtodesktopnext",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_next
    },
    {
        @"sendtodesktopprevious",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_prev
    },
    {
        @"sendtodesktopright",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_right
    },
    {
        @"sendtodesktopleft",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_left
    },
    {
        @"sendtodesktopup",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_up
    },
    {
        @"sendtodesktopdown",
        action_send_to_desktop_dir,
        setup_action_send_to_desktop_down
    },
    {
        @"desktop",
        action_desktop,
        setup_action_desktop
    },
    {
        @"desktopnext",
        action_desktop_dir,
        setup_action_desktop_next
    },
    {
        @"desktopprevious",
        action_desktop_dir,
        setup_action_desktop_prev
    },
    {
        @"desktopright",
        action_desktop_dir,
        setup_action_desktop_right
    },
    {
        @"desktopleft",
        action_desktop_dir,
        setup_action_desktop_left
    },
    {
        @"desktopup",
        action_desktop_dir,
        setup_action_desktop_up
    },
    {
        @"desktopdown",
        action_desktop_dir,
        setup_action_desktop_down
    },
    {
        @"toggledecorations",
        action_toggle_decorations,
        setup_client_action
    },
    {
        @"move",
        action_moveresize,
        setup_action_move
    },
    {
        @"resize",
        action_moveresize,
        setup_action_resize
    },
    {
        @"toggleshowdesktop",
        action_toggle_show_desktop,
        NULL
    },
    {
        @"showdesktop",
        action_show_desktop,
        NULL
    },
    {
        @"unshowdesktop",
        action_unshow_desktop,
        NULL
    },
    {
        @"desktoplast",
        action_desktop_last,
        NULL
    },
    {
        @"reconfigure",
        action_reconfigure,
        NULL
    },
    {
        @"restart",
        action_restart,
        NULL
    },
    {
        @"exit",
        action_exit,
        NULL
    },
    {
        @"showmenu",
        action_showmenu,
        setup_action_showmenu
    },
    {
        @"sendtotoplayer",
        action_send_to_layer,
        setup_action_top_layer
    },
    {
        @"togglealwaysontop",
        action_toggle_layer,
        setup_action_top_layer
    },
    {
        @"sendtonormallayer",
        action_send_to_layer,
        setup_action_normal_layer
    },
    {
        @"sendtobottomlayer",
        action_send_to_layer,
        setup_action_bottom_layer
    },
    {
        @"togglealwaysonbottom",
        action_toggle_layer,
        setup_action_bottom_layer
    },
    {
        @"nextwindow",
        action_cycle_windows,
        setup_action_cycle_windows_next
    },
    {
        @"previouswindow",
        action_cycle_windows,
        setup_action_cycle_windows_previous
    },
    {
        @"movetoedgenorth",
        action_movetoedge,
        setup_action_movetoedge_north
    },
    {
        @"movetoedgesouth",
        action_movetoedge,
        setup_action_movetoedge_south
    },
    {
        @"movetoedgewest",
        action_movetoedge,
        setup_action_movetoedge_west
    },
    {
        @"movetoedgeeast",
        action_movetoedge,
        setup_action_movetoedge_east
    },
    {
        @"growtoedgenorth",
        action_growtoedge,
        setup_action_growtoedge_north
    },
    {
        @"growtoedgesouth",
        action_growtoedge,
        setup_action_growtoedge_south
    },
    {
        @"growtoedgewest",
        action_growtoedge,
        setup_action_growtoedge_west
    },
    {
        @"growtoedgeeast",
        action_growtoedge,
        setup_action_growtoedge_east
    },
    {
        nil,
        NULL,
        NULL
    }
};

/* only key bindings can be interactive. thus saith the xor.
   because of how the mouse is grabbed, mouse events dont even get
   read during interactive events, so no dice! >:) */
#define INTERACTIVE_LIMIT(a, uact) \
    if (uact != OB_USER_ACTION_KEYBOARD_KEY) \
        [a data_pointer]->any.interactive = NO;

@implementation AZAction
+ (AZAction *) actionWithName: (NSString *) name userAction: (ObUserAction) uact
{
  AZAction *a = nil;
  BOOL exist = NO;
  int i;

  for (i = 0; actionstrings[i].name; i++)
    if ([name compare: actionstrings[i].name options: NSCaseInsensitiveSearch] == NSOrderedSame) {
      exist = YES;
      a = [[AZAction alloc] initWithFunc: actionstrings[i].func];
      if (actionstrings[i].setup)
        actionstrings[i].setup(&a, uact);
      if (a)
        INTERACTIVE_LIMIT(a, uact);
      break;
    }
  if (!exist)
    NSLog(@"Invalid action '%@' requested. No such action exists.", name);
  if (!a)
    NSLog(@"Invalid use of action '%@'. Action will be ignored.", name);
  return AUTORELEASE(a);
}

- (AZActionFunc) func { return func; }
- (union ActionData) data { return data; }
- (union ActionData *) data_pointer { return &data; }
- (void) set_func: (AZActionFunc) f { func = f; }
- (void) set_data: (union ActionData) d { data = d; }
- (id) initWithFunc: (AZActionFunc) f
{
  self = [super init];
  func = f;
  return self;
}

- (void) dealloc
{
    /* deal with pointers */
    if (func == action_execute || func == action_restart)
        DESTROY(data.execute.path);
    else if (func == action_showmenu)
        DESTROY(data.showmenu.name);
    [super dealloc];
}

- (id) copyWithZone: (NSZone *) zone
{
    AZAction *a = [[AZAction allocWithZone: zone] initWithFunc: func];

    [a set_data: data];

    /* deal with pointers */
    if ([a func] == action_execute || [a func] == action_restart)
        [a data_pointer]->execute.path = [data.execute.path copy];
    else if ([a func] == action_showmenu)
        [a data_pointer]->showmenu.name = [data.showmenu.name copy];

    return a;
}
@end

AZAction *action_parse(xmlDocPtr doc, xmlNodePtr node, ObUserAction uact)
{
    NSString *actname;
    AZAction *act = nil;
    xmlNodePtr n;

    if (parse_attr_string("name", node, &actname)) {
        if ((act = [AZAction actionWithName: actname userAction: uact])) {
            if ([act func] == action_execute || [act func] == action_restart) {
                if ((n = parse_find_node("execute", node->xmlChildrenNode))) {
                    ASSIGN([act data_pointer]->execute.path, ([parse_string(doc, n) stringByExpandingTildeInPath]));
                }
            } else if ([act func] == action_showmenu) {
                if ((n = parse_find_node("menu", node->xmlChildrenNode)))
                    ASSIGN([act data_pointer]->showmenu.name, parse_string(doc, n));
            } else if ([act func] == action_move_relative_horz ||
                       [act func] == action_move_relative_vert ||
                       [act func] == action_resize_relative_horz ||
                       [act func] == action_resize_relative_vert) {
                if ((n = parse_find_node("delta", node->xmlChildrenNode)))
                     [act data_pointer]->relative.deltax = parse_int(doc, n);
            } else if ([act func] == action_move_relative) {
    	        if ((n = parse_find_node("x", node->xmlChildrenNode)))
                     [act data_pointer]->relative.deltax = parse_int(doc, n);
	        if ((n = parse_find_node("y", node->xmlChildrenNode)))
	             [act data_pointer]->relative.deltay = parse_int(doc, n);
	    } else if ([act func] == action_resize_relative) {
	        if ((n = parse_find_node("left", node->xmlChildrenNode)))
	             [act data_pointer]->relative.deltaxl = parse_int(doc, n);
	        if ((n = parse_find_node("up", node->xmlChildrenNode)))
	             [act data_pointer]->relative.deltayu = parse_int(doc, n);
	        if ((n = parse_find_node("right", node->xmlChildrenNode)))
	             [act data_pointer]->relative.deltax = parse_int(doc, n);
	        if ((n = parse_find_node("down", node->xmlChildrenNode)))
	             [act data_pointer]->relative.deltay = parse_int(doc, n);
            } else if ([act func] == action_desktop) {
                if ((n = parse_find_node("desktop", node->xmlChildrenNode)))
                    [act data_pointer]->desktop.desk = parse_int(doc, n);
                if ([act data].desktop.desk > 0) [act data_pointer]->desktop.desk--;
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    [act data_pointer]->desktop.inter.any.interactive =
                        parse_bool(doc, n);
           } else if ([act func] == action_send_to_desktop) {
                if ((n = parse_find_node("desktop", node->xmlChildrenNode)))
                    [act data_pointer]->sendto.desk = parse_int(doc, n);
                if ([act data].sendto.desk > 0) [act data_pointer]->sendto.desk--;
                if ((n = parse_find_node("follow", node->xmlChildrenNode)))
                    [act data_pointer]->sendto.follow = parse_bool(doc, n);
            } else if ([act func] == action_desktop_dir) {
                if ((n = parse_find_node("wrap", node->xmlChildrenNode)))
                    [act data_pointer]->desktopdir.wrap = parse_bool(doc, n); 
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    [act data_pointer]->desktopdir.inter.any.interactive =
                        parse_bool(doc, n);
            } else if ([act func] == action_send_to_desktop_dir) {
                if ((n = parse_find_node("wrap", node->xmlChildrenNode)))
                    [act data_pointer]->sendtodir.wrap = parse_bool(doc, n);
                if ((n = parse_find_node("follow", node->xmlChildrenNode)))
                    [act data_pointer]->sendtodir.follow = parse_bool(doc, n);
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    [act data_pointer]->sendtodir.inter.any.interactive =
                        parse_bool(doc, n);
            } else if ([act func] == action_activate) {
                if ((n = parse_find_node("here", node->xmlChildrenNode)))
                    [act data_pointer]->activate.here = parse_bool(doc, n);
            } else if ([act func] == action_cycle_windows) {
                if ((n = parse_find_node("linear", node->xmlChildrenNode)))
                    [act data_pointer]->cycle.linear = parse_bool(doc, n);
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    [act data_pointer]->cycle.dialog = parse_bool(doc, n);
                if ((n = parse_find_node("opaque", node->xmlChildrenNode)))
                    [act data_pointer]->cycle.opaque = parse_bool(doc, n);
            } else if ([act func] == action_directional_focus) {
                if ((n = parse_find_node("dialog", node->xmlChildrenNode)))
                    [act data_pointer]->cycle.dialog = parse_bool(doc, n);
            } else if ([act func] == action_raise ||
                       [act func] == action_lower ||
                       [act func] == action_raiselower ||
                       [act func] == action_shadelower ||
                       [act func] == action_unshaderaise) {
            }
            INTERACTIVE_LIMIT(act, uact);
        }
    }
    return act;
}

void action_run_mouse(NSArray *acts, AZClient *c, ObFrameContext n, unsigned int s, unsigned int b, int x, int y, Time time)
{
    action_run_list(acts, c, n, s, b, x, y, NO, NO, time);
}

void action_run_interactive(NSArray *acts, AZClient *c, unsigned int s, Time t, BOOL n, BOOL d)
{
    action_run_list(acts, c, OB_FRAME_CONTEXT_NONE, s, 0, -1, -1, t, n, d);
}

void action_run_key(NSArray *acts, AZClient *c, unsigned int state, int x, int y, Time t)
{
    action_run_list(acts, c, OB_FRAME_CONTEXT_NONE, state, 0, x, y, t, NO, NO);
}

void action_run(NSArray *acts, AZClient *c, unsigned int state, Time t)
{
    action_run_list(acts, c, OB_FRAME_CONTEXT_NONE, state, 0, -1, -1, t, NO, NO);
}

void action_run_list(NSArray *acts, AZClient *c, ObFrameContext context,
                     unsigned int state, unsigned int button, int x, int y,
                     Time time, BOOL cancel, BOOL done)
{
    AZAction *a;
    BOOL inter = NO;
    int i, count;

    if ((acts == nil) || ([acts count] == 0))
        return;

    if (x < 0 && y < 0)
    {
	[[AZScreen defaultScreen] pointerPosAtX: &x y: &y];
    }

    if (grab_on_keyboard()) {
        inter = YES;
    } else {
	count = [acts count];
	for (i = 0; i < count; i++) {
            a = [acts objectAtIndex: i];
            if ([a data].any.interactive) {
                inter = YES;
                break;
            }
        }
    }

    if (!inter) {
        /* sometimes when we execute another app as an action,
           it won't work right unless we XUngrabKeyboard first,
           even though we grabbed the key/button Asychronously.
           e.g. "gnome-panel-control --main-menu" */
        XUngrabKeyboard(ob_display, event_curtime);
    }

    count = [acts count];
    for (i = 0; i < count; i++) {
        a = [acts objectAtIndex: i];

        if (!([a data].any.client_action == OB_CLIENT_ACTION_ALWAYS && !c)) {
            [a data_pointer]->any.c = [a data].any.client_action ? c : NULL;
            [a data_pointer]->any.context = context;
            [a data_pointer]->any.x = x;
            [a data_pointer]->any.y = y;

            [a data_pointer]->any.button = button;

	    [a data_pointer]->any.time = time;

            if ([a data].any.interactive) {
                [a data_pointer]->inter.cancel = cancel;
                [a data_pointer]->inter.final = done;
                if (!(cancel || done)) {
		    AZKeyboardHandler *kHandler = [AZKeyboardHandler defaultHandler];

		    if (![kHandler interactiveGrab: state
				    client: [a data].any.c
				    action: a])
                        continue;
		}
            }

            /* XXX UGLY HACK race with motion event starting a move and the
               button release gettnig processed first. answer: don't queue
               moveresize starts. UGLY HACK XXX */
            if ([a data].any.interactive || [a func] == action_moveresize) {
                /* interactive actions are not queued */
                [a func]([a data_pointer]);
            } else {
                [[AZMainLoop mainLoop] queueAction: a];
	    }
        }
    }
}

void action_run_string(NSString *name, AZClient *c, Time time)
{
    AZAction *a = [AZAction actionWithName: name userAction: OB_USER_ACTION_NONE];
    if (a == nil) {
      NSLog(@"Internal Error: Cannot get action from string: %@", name);
      return;
    }

    action_run([NSArray arrayWithObjects: a, nil], c, 0, time);
}

void action_execute(union ActionData *data)
{
    if (data->execute.path) {
      NSString *p = nil;
      if ([data->execute.path isAbsolutePath])
	p = data->execute.path;
      else {
        // FIXME: we need to port this part again 
	/* Look through paths */
	NSProcessInfo *pi = [NSProcessInfo processInfo];
	NSArray *ps = [[[pi environment] objectForKey: @"PATH"] componentsSeparatedByString: @":"];
	NSFileManager *fm = [NSFileManager defaultManager];
	int i, count = [ps count];
	BOOL isDir;
	NSString *a;
	for (i = 0; i < count; i++) {
	  a = [[ps objectAtIndex: i] stringByAppendingPathComponent: data->execute.path];
	  if ([fm fileExistsAtPath: a isDirectory: &isDir] 
			  && (isDir == NO)) 
	  {
	    p = a;
	    break;
	  }
	}
      }
      if (p) {
        [NSTask launchedTaskWithLaunchPath: p arguments: nil];
      } else {
	NSLog(@"Cannot find command %@", data->execute.path);
      }
    }
}

void action_activate(union ActionData *data)
{
    /* similar to the openbox dock for dockapps, don't let user actions give
       focus to 3rd-party docks (panels) either (unless they ask for it
       themselves). */
    if ([data->client.any.c type] != OB_CLIENT_TYPE_DOCK) {
        [data->activate.any.c activateHere: data->activate.here user: YES];
    }
}

void action_focus(union ActionData *data)
{
    /* similar to the openbox dock for dockapps, don't let user actions give
       focus to 3rd-party docks (panels) either (unless they ask for it
       themselves). */
    if ([data->client.any.c type] != OB_CLIENT_TYPE_DOCK) {
        [data->client.any.c focus];
    }
}

void action_unfocus (union ActionData *data)
{
  AZFocusManager *fmanager = [AZFocusManager defaultManager];
  if (data->client.any.c == [fmanager focus_client])
    [fmanager fallbackTarget: NO old: nil];
}

void action_iconify(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c iconify: YES currentDesktop: YES];
    client_action_end(data);
}

void action_focus_order_to_bottom(union ActionData *data)
{
  [[AZFocusManager defaultManager] focusOrderToBottom: data->client.any.c];
}

void action_raiselower(union ActionData *data)
{
    AZClient *c = data->client.any.c;
    BOOL raise = NO;
    int i, count = [[AZStacking stacking] count];

    for (i = 0; i < count; i++) {
	id <AZWindow> temp = [[AZStacking stacking] windowAtIndex: i];
	if (WINDOW_IS_CLIENT(temp)) {
	  AZClient *cit = (AZClient *)temp;

          if (cit == c) break;
          if ([cit normal] == [c normal] &&
            [cit layer] == [c layer] &&
            [[cit frame] visible] &&
            ![c searchTransient: cit])
          {
            if (RECT_INTERSECTS_RECT([[cit frame] area], [[c frame] area])) {
                raise = YES;
                break;
            }
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
    [[AZStacking stacking] raiseWindow: data->client.any.c];
    client_action_end(data);
}

void action_unshaderaise(union ActionData *data)
{
    if ([data->client.any.c shaded])
        action_unshade(data);
    else
        action_raise(data);
}

void action_shadelower(union ActionData *data)
{
    if ([data->client.any.c shaded])
        action_lower(data);
    else
        action_shade(data);
}

void action_lower(union ActionData *data)
{
    client_action_start(data);
    [[AZStacking stacking] lowerWindow: data->client.any.c];
    client_action_end(data);
}

void action_close(union ActionData *data)
{
    [data->client.any.c close];
}

void action_kill(union ActionData *data)
{
    [data->client.any.c kill];
}

void action_shade(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c shade: YES];
    client_action_end(data);
}

void action_unshade(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c shade: NO];
    client_action_end(data);
}

void action_toggle_shade(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c shade: ![data->client.any.c shaded]];
    client_action_end(data);
}

void action_toggle_omnipresent(union ActionData *data)
{ 
  int num = ([data->client.any.c desktop] == DESKTOP_ALL) ?
            [[AZScreen defaultScreen] desktop] : DESKTOP_ALL;
    [data->client.any.c setDesktop: num hide: NO];
}

void action_move_relative_horz(union ActionData *data)
{
    AZClient *c = data->relative.any.c;
    client_action_start(data);
    [c moveToX: [c area].x + data->relative.deltax
	            y: [c area].y];
    client_action_end(data);
}

void action_move_relative_vert(union ActionData *data)
{
    AZClient *c = data->relative.any.c;
    client_action_start(data);
    [c moveToX: [c area].x
	            y: [c area].y + data->relative.deltax];
    client_action_end(data);
}

void action_move_to_center(union ActionData *data)
{
    AZClient *c = data->client.any.c;
    Rect *area;
    area = [[AZScreen defaultScreen] areaOfDesktop: [c desktop]
	                                   monitor: 0];
    client_action_start(data);
    [c moveToX: area->width / 2 - [c area].width / 2
	            y: area->height / 2 - [c area].height / 2];
    client_action_end(data);
}

void action_resize_relative_horz(union ActionData *data)
{
    AZClient *c = data->relative.any.c;
    client_action_start(data);
    [c resizeToWidth: [c area].width + data->relative.deltax * [c size_inc].width
                     height:  [c area].height];
    client_action_end(data);
}

void action_resize_relative_vert(union ActionData *data)
{
    AZClient *c = data->relative.any.c;
    if (![c shaded]) {
        client_action_start(data);
	[c resizeToWidth: [c area].width
		height: [c area].height +
                     data->relative.deltax * [c size_inc].height];
        client_action_end(data);
    }
}

void action_move_relative(union ActionData *data)
{
  AZClient *c = data->relative.any.c;
  client_action_start(data);
  [c moveToX: [c area].x + data->relative.deltax
	   y: [c area].y + data->relative.deltay];
  client_action_end(data);
}
  	 
void action_resize_relative(union ActionData *data)
{
  AZClient *c = data->relative.any.c;
  int x, y, ow, w, oh, h, lw, lh;
  client_action_start(data);
  x = [c area].x;
  y = [c area].y;
  ow = [c area].width;
  w = ow + data->relative.deltax * [c size_inc].width
      + data->relative.deltaxl * [c size_inc].width;
  oh = [c area].height;
  h = oh + data->relative.deltay * [c size_inc].height
      + data->relative.deltayu * [c size_inc].height;

  [c tryConfigureToCorner: OB_CORNER_TOPLEFT x: &x y: &y width: &w height: &h
               logicalW: &lw logicalH: &lh user: YES];
  [c moveAndResizeToX: x + (ow - w) y: y + (oh - h) width: w height: h];

  client_action_end(data);
}

void action_maximize_full(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: YES direction: 0];
    client_action_end(data);
}

void action_unmaximize_full(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: NO direction: 0];
    client_action_end(data);
}

void action_toggle_maximize_full(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize:  
	       !([data->client.any.c max_horz] || 
		 [data->client.any.c max_vert])
	    direction: 0];
    client_action_end(data);
}

void action_maximize_horz(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: YES direction: 1];
    client_action_end(data);
}

void action_unmaximize_horz(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: NO direction: 1];
    client_action_end(data);
}

void action_toggle_maximize_horz(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: ![data->client.any.c max_horz]
	               direction: 1];
    client_action_end(data);
}

void action_maximize_vert(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: YES direction: 2];
    client_action_end(data);
}

void action_unmaximize_vert(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: NO direction: 2];
    client_action_end(data);
}

void action_toggle_maximize_vert(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c maximize: ![data->client.any.c max_vert]
	               direction: 2];
    client_action_end(data);
}

void action_toggle_fullscreen(union ActionData *data)
{
    client_action_start(data);
    [data->client.any.c fullscreen: !([data->client.any.c fullscreen])];
    client_action_end(data);
}

void action_send_to_desktop(union ActionData *data)
{
    AZClient *c = data->sendto.any.c;

    if (![c normal]) return;

    AZScreen *defaultScreen = [AZScreen defaultScreen];

    if (data->sendto.desk < [defaultScreen numberOfDesktops] ||
        data->sendto.desk == DESKTOP_ALL) {
	[c setDesktop: data->sendto.desk hide: data->sendto.follow];
        if (data->sendto.follow)
	{
	  [defaultScreen setDesktop: data->sendto.desk];
	}
    }
}

void action_desktop(union ActionData *data)
{
    static unsigned int first = (unsigned) -1;
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
    unsigned int d;
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
    AZClient *c = data->sendtodir.inter.any.c;
    unsigned int d;

    if (![c normal]) return;
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
	[c setDesktop: d hide: data->sendtodir.follow];
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
    AZClient *c = data->client.any.c;

    client_action_start(data);
    [c setUndecorated: ![c undecorated]];
    client_action_end(data);
}

static unsigned long pick_corner(int x, int y, int cx, int cy, int cw, int ch)
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
    AZClient *c = data->moveresize.any.c;
    unsigned long corner;

    if (![c normal]) return;

    if (data->moveresize.keyboard) {
        corner = (data->moveresize.move ?
                  prop_atoms.net_wm_moveresize_move_keyboard :
                  prop_atoms.net_wm_moveresize_size_keyboard);
    } else {
        corner = (data->moveresize.move ?
                  prop_atoms.net_wm_moveresize_move :
                  pick_corner(data->any.x, data->any.y,
                              [[c frame] area].x, [[c frame] area].y,
                              /* use the client size because the frame
                                 can be differently sized (shaded
                                 windows) and we want this based on the
                                 clients size */
                              [c area].width + [[c frame] size].left +
                              [[c frame] size].right,
                              [c area].height + [[c frame] size].top +
                              [[c frame] size].bottom));
    }

    [[AZMoveResizeHandler defaultHandler]
	    startWithClient: c x: data->any.x y: data->any.y
	    button: data->any.button corner: corner];
}

void action_reconfigure(union ActionData *data)
{
    ob_reconfigure();
}

void action_restart(union ActionData *data)
{
    ob_restart_other([data->execute.path cString]);
}

void action_exit(union ActionData *data)
{
    ob_exit(0);
}

void action_showmenu(union ActionData *data)
{
    if (data->showmenu.name) {
	[[AZMenuManager defaultManager] showMenu: data->showmenu.name
		x: data->any.x y: data->any.y
		client: data->showmenu.any.c];
    }
}

void action_cycle_windows(union ActionData *data)
{
    [[AZFocusManager defaultManager] cycleForward: data->cycle.forward
	    linear: data->cycle.linear
	    interactive:  data->any.interactive
            dialog: data->cycle.dialog
            done: data->cycle.inter.final
	    cancel: data->cycle.inter.cancel
            opaque: data->cycle.opaque];
}

void action_directional_focus(union ActionData *data)
{
    [[AZFocusManager defaultManager] 
            directionalCycle: data->interdiraction.direction
            interactive: data->any.interactive
            dialog: data->interdiraction.dialog
            done: data->interdiraction.inter.final
            cancel: data->interdiraction.inter.cancel];
}

void action_movetoedge(union ActionData *data)
{
    int x, y;
    AZClient *c = data->diraction.any.c;

    x = [[c frame] area].x;
    y = [[c frame] area].y;
    
    switch(data->diraction.direction) {
    case OB_DIRECTION_NORTH:
	y = [c directionalEdgeSearch: OB_DIRECTION_NORTH];
        break;
    case OB_DIRECTION_WEST:
	x = [c directionalEdgeSearch: OB_DIRECTION_WEST];
        break;
    case OB_DIRECTION_SOUTH:
	y = [c directionalEdgeSearch: OB_DIRECTION_SOUTH] -
            [[c frame] area].height;
        break;
    case OB_DIRECTION_EAST:
	x = [c directionalEdgeSearch: OB_DIRECTION_EAST] -
            [[c frame] area].width;
        break;
    default:
	NSLog(@"Internal Error: should not reach here");
    }
    [[c frame] frameGravityAtX: &x y: &y];
    client_action_start(data);
    [c moveToX: x y: y];
    client_action_end(data);
}

void action_growtoedge(union ActionData *data)
{
    int x, y, width, height, dest;
    AZClient *c = data->diraction.any.c;
    Rect *a;

    //FIXME growtoedge resizes shaded windows to 0 height
    if ([c shaded])
        return;

    a = [[AZScreen defaultScreen] areaOfDesktop: [c desktop]];
    x = [[c frame] area].x;
    y = [[c frame] area].y;
    width = [[c frame] area].width;
    height = [[c frame] area].height;

    switch(data->diraction.direction) {
    case OB_DIRECTION_NORTH:
	dest = [c directionalEdgeSearch: OB_DIRECTION_NORTH];
        if (a->y == y)
            height = [[c frame] area].height / 2;
        else {
            height = [[c frame] area].y + [[c frame] area].height - dest;
            y = dest;
        }
        break;
    case OB_DIRECTION_WEST:
	dest = [c directionalEdgeSearch: OB_DIRECTION_WEST];
        if (a->x == x)
            width = [[c frame] area].width / 2;
        else {
            width = [[c frame] area].x + [[c frame] area].width - dest;
            x = dest;
        }
        break;
    case OB_DIRECTION_SOUTH:
	dest = [c directionalEdgeSearch: OB_DIRECTION_SOUTH];
        if (a->y + a->height == y + [[c frame] area].height) {
            height = [[c frame] area].height / 2;
            y = a->y + a->height - height;
        } else
            height = dest - [[c frame] area].y;
        y += (height - [[c frame] area].height) % [c size_inc].height;
        height -= (height - [[c frame] area].height) % [c size_inc].height;
        break;
    case OB_DIRECTION_EAST:
	dest = [c directionalEdgeSearch: OB_DIRECTION_EAST];
        if (a->x + a->width == x + [[c frame] area].width) {
            width = [[c frame] area].width / 2;
            x = a->x + a->width - width;
        } else
            width = dest - [[c frame] area].x;
        x += (width - [[c frame] area].width) % [c size_inc].width;
        width -= (width - [[c frame] area].width) % [c size_inc].width;
        break;
    default:
	NSLog(@"Internal Error: should not reach here");
    }
    [[c frame] frameGravityAtX: &x y: &y];
    width -= [[c frame] size].left + [[c frame] size].right;
    height -= [[c frame] size].top + [[c frame] size].bottom;
    client_action_start(data);
    [c moveAndResizeToX: x y: y width: width height: height];
    client_action_end(data);
}

void action_send_to_layer(union ActionData *data)
{
  [(data->layer.any.c) setLayer: data->layer.layer];
}

void action_toggle_layer(union ActionData *data)
{
    AZClient *c = data->layer.any.c;

    client_action_start(data);
    if (data->layer.layer < 0)
    {
        [c setLayer: [c below] ? 0 : -1];
    }
    else if (data->layer.layer > 0)
    {
        [c setLayer: [c above] ? 0 : 1];
    }
    client_action_end(data);
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

