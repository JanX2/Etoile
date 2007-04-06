/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-
 
   action.h for Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   action.h for the Openbox window manager
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

#ifndef __action_h
#define __action_h

#import "AZFrame.h"
#include "misc.h"
#include "parse.h"

/* These have to all have a Client* at the top even if they don't use it, so
   that I can set it blindly later on. So every function will have a Client*
   available (possibly NULL though) if it wants it.
*/

typedef enum
{
    OB_CLIENT_ACTION_NO,
    OB_CLIENT_ACTION_OPTIONAL,
    OB_CLIENT_ACTION_ALWAYS
} ObClientActionReq;

struct AnyAction {
    ObClientActionReq client_action;
    AZClient *c;
    ObFrameContext context;
    BOOL interactive;
    int x;
    int y;
    int button;
    Time time;
};

struct InteractiveAction {
    struct AnyAction any;
    BOOL final;
    BOOL cancel;
};

struct InterDirectionalAction{
    struct InteractiveAction inter;
    ObDirection direction;
    BOOL dialog;
};

struct DirectionalAction{
    struct AnyAction any;
    ObDirection direction;
};

struct Execute {
    struct AnyAction any;
    NSString *path;
};

struct ClientAction {
    struct AnyAction any;
};

struct Activate {
    struct AnyAction any;
    BOOL here; /* bring it to the current desktop */
};

struct MoveResizeRelative {
    struct AnyAction any;
    int deltax;
    int deltay;
    int deltaxl;
    int deltayu;
};

struct SendToDesktop {
    struct AnyAction any;
    unsigned int desk;
    BOOL follow;
};

struct SendToDesktopDirection {
    struct InteractiveAction inter;
    ObDirection dir;
    BOOL wrap;
    BOOL linear;
    BOOL follow;
};

struct Desktop {
    struct InteractiveAction inter;
    unsigned int desk;
};

struct Layer {
    struct AnyAction any;
    int layer; /* < 0 = below, 0 = normal, > 0 = above */
};

struct DesktopDirection {
    struct InteractiveAction inter;
    ObDirection dir;
    BOOL wrap;
    BOOL linear;
};

struct MoveResize {
    struct AnyAction any;
    BOOL move;
    BOOL keyboard;
};

struct ShowMenu {
    struct AnyAction any;
    NSString *name;
};

struct CycleWindows {
    struct InteractiveAction inter;
    BOOL linear;
    BOOL forward;
    BOOL dialog;
    BOOL opaque;
};

struct Stacking {
    struct AnyAction any;
};

union ActionData {
    struct AnyAction any;
    struct InteractiveAction inter;
    struct InterDirectionalAction interdiraction;
    struct DirectionalAction diraction;
    struct Execute execute;
    struct ClientAction client;
    struct Activate activate;
    struct MoveResizeRelative relative;
    struct SendToDesktop sendto;
    struct SendToDesktopDirection sendtodir;
    struct Desktop desktop;
    struct DesktopDirection desktopdir;
    struct MoveResize moveresize;
    struct ShowMenu showmenu;
    struct CycleWindows cycle;
    struct Layer layer;
    struct Stacking stacking;
};

typedef void (*AZActionFunc)(union ActionData *data);

@interface AZAction: NSObject <NSCopying>
{
    /* The func member acts like an enum to tell which one of the structs in
       the data union are valid.
    */
    AZActionFunc func;
    union ActionData data;
}
+ (AZAction *) actionWithName: (NSString *) name userAction: (ObUserAction) uact;
- (id) initWithFunc: (AZActionFunc) func;
- (AZActionFunc) func;
- (union ActionData) data;
- (union ActionData *) data_pointer;
- (void) set_func: (AZActionFunc) func;
- (void) set_data: (union ActionData) data;
@end

/* Creates a new Action from the name of the action
   A few action types need data set after making this call still. Check if
   the returned action's "func" is one of these.
   action_execute - the path needs to be set
   action_restart - the path can optionally be set
   action_desktop - the destination desktop needs to be set
   action_send_to_desktop - the destination desktop needs to be set
   action_move_relative_horz - the delta
   action_move_relative_vert - the delta
   action_resize_relative_horz - the delta
   action_resize_relative_vert - the delta
   action_move_relative - the deltas
   action_resize_relative - the deltas
*/

/* Autoreleased */
AZAction* action_parse(xmlDocPtr doc, xmlNodePtr node, ObUserAction uact);

/*! Executes a list of actions.
  @param c The client associated with the action. Can be NULL.
  @param state The keyboard modifiers state at the time the user action occured
  @param button The mouse button used to execute the action.
  @param x The x coord at which the user action occured.
  @param y The y coord at which the user action occured.
  @param cancel If the action is cancelling an interactive action. This only
         affects interactive actions, but should generally always be FALSE.
  @param done If the action is completing an interactive action. This only
         affects interactive actions, but should generally always be FALSE.
*/
void action_run_list(NSArray *acts, AZClient *c, ObFrameContext context,
                     unsigned int state, unsigned int button, int x, int y,
                     Time time, BOOL cancel, BOOL done);

void action_run_mouse(NSArray *acts, AZClient *c, ObFrameContext context, unsigned int state, unsigned int button, int x, int y, Time time);

void action_run_interactive(NSArray *acts, AZClient *c, unsigned int state, Time time, BOOL cancel, BOOL done);

void action_run_key(NSArray *acts, AZClient *c, unsigned int state, int x, int y, Time time);

void action_run(NSArray *acts, AZClient *c, unsigned int state, Time time);

void action_run_string(NSString *name, AZClient *c, Time time);

/* Execute */
void action_execute(union ActionData *data);
/* ActivateAction */
void action_activate(union ActionData *data);
/* ClientAction */
void action_focus(union ActionData *data);
/* ClientAction */
void action_unfocus(union ActionData *data);
/* ClientAction */
void action_iconify(union ActionData *data);
/* ClientAction */
void action_focus_order_to_bottom(union ActionData *data);
/* ClientAction */
void action_raiselower(union ActionData *data);
/* ClientAction */
void action_raise(union ActionData *data);
/* ClientAction */
void action_lower(union ActionData *data);
/* ClientAction */
void action_close(union ActionData *data);
/* ClientAction */
void action_kill(union ActionData *data);
/* ClientAction */
void action_shade(union ActionData *data);
/* ClientAction */
void action_shadelower(union ActionData *data);
/* ClientAction */
void action_unshaderaise(union ActionData *data);
/* ClientAction */
void action_unshade(union ActionData *data);
/* ClientAction */
void action_toggle_shade(union ActionData *data);
/* ClientAction */
void action_toggle_omnipresent(union ActionData *data);
/* MoveResizeRelative */
void action_move_relative_horz(union ActionData *data);
/* MoveResizeRelative */
void action_move_relative_vert(union ActionData *data);
/* MoveResizeRelative */
void action_move_relative(union ActionData *data);
/* MoveResizeRelative */
void action_resize_relative(union ActionData *data);
/* ClientAction */
void action_move_to_center(union ActionData *data);
/* MoveResizeRelative */
void action_resize_relative_horz(union ActionData *data);
/* MoveResizeRelative */
void action_resize_relative_vert(union ActionData *data);
/* ClientAction */
void action_maximize_full(union ActionData *data);
/* ClientAction */
void action_unmaximize_full(union ActionData *data);
/* ClientAction */
void action_toggle_maximize_full(union ActionData *data);
/* ClientAction */
void action_maximize_horz(union ActionData *data);
/* ClientAction */
void action_unmaximize_horz(union ActionData *data);
/* ClientAction */
void action_toggle_maximize_horz(union ActionData *data);
/* ClientAction */
void action_maximize_vert(union ActionData *data);
/* ClientAction */
void action_unmaximize_vert(union ActionData *data);
/* ClientAction */
void action_toggle_maximize_vert(union ActionData *data);
/* ClientAction */
void action_toggle_fullscreen(union ActionData *data);
/* SendToDesktop */
void action_send_to_desktop(union ActionData *data);
/* SendToDesktopDirection */
void action_send_to_desktop_dir(union ActionData *data);
/* Desktop */
void action_desktop(union ActionData *data);
/* DesktopDirection */
void action_desktop_dir(union ActionData *data);
/* Any */
void action_desktop_last(union ActionData *data);
/* ClientAction */
void action_toggle_decorations(union ActionData *data);
/* MoveResize */
void action_moveresize(union ActionData *data);
/* Any */
void action_reconfigure(union ActionData *data);
/* Execute */
void action_restart(union ActionData *data);
/* Any */
void action_exit(union ActionData *data);
/* ShowMenu */
void action_showmenu(union ActionData *data);
/* CycleWindows */
void action_cycle_windows(union ActionData *data);
/* InterDirectionalAction */
void action_directional_focus(union ActionData *data);
/* DirectionalAction */
void action_movetoedge(union ActionData *data);
/* DirectionalAction */
void action_growtoedge(union ActionData *data);
/* Layer */
void action_send_to_layer(union ActionData *data);
/* Layer */
void action_toggle_layer(union ActionData *data);
/* Any */
void action_toggle_dockautohide(union ActionData *data);
/* Any */
void action_toggle_show_desktop(union ActionData *data);
/* Any */
void action_show_desktop(union ActionData *data);
/* Any */
void action_unshow_desktop(union ActionData *data);

#endif
