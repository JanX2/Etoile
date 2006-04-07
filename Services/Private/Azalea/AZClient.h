// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   client.h for the Openbox window manager
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
#import "AZGroup.h"
#import "AZStacking.h"
#import "mwm.h"
#import "render/color.h"
#import "window.h"
#import "geom.h"
#import "misc.h"
#import "gnustep.h"

/*! Holds an icon in ARGB format */
@interface AZClientIcon: NSObject
{
    int width;
    int height;
    RrPixel32 *data;
}

- (int) width;
- (void) setWidth: (int) width;
- (int) height;
- (void) setHeight: (int) height;
- (RrPixel32 *) data;
- (void) setData: (RrPixel32 *) data;
@end

@class AZClient;

/* The value in client.transient_for indicating it is a transient for its
   group instead of for a single window */
#define OB_TRAN_GROUP ((void*)~0l)

/*! Possible window types */
typedef enum
{
    OB_CLIENT_TYPE_DESKTOP, /*!< A desktop (bottom-most window) */
    OB_CLIENT_TYPE_DOCK,    /*!< A dock bar/panel window */
    OB_CLIENT_TYPE_TOOLBAR, /*!< A toolbar window, pulled off an app */
    OB_CLIENT_TYPE_MENU,    /*!< An unpinned menu from an app */
    OB_CLIENT_TYPE_UTILITY, /*!< A small utility window such as a palette */
    OB_CLIENT_TYPE_SPLASH,  /*!< A splash screen window */
    OB_CLIENT_TYPE_DIALOG,  /*!< A dialog window */
    OB_CLIENT_TYPE_NORMAL   /*!< A normal application window */
} ObClientType;

/*! The things the user can do to the client window */
typedef enum
{
    OB_CLIENT_FUNC_RESIZE     = 1 << 0, /*!< Allow user resizing */
    OB_CLIENT_FUNC_MOVE       = 1 << 1, /*!< Allow user moving */
    OB_CLIENT_FUNC_ICONIFY    = 1 << 2, /*!< Allow to be iconified */
    OB_CLIENT_FUNC_MAXIMIZE   = 1 << 3, /*!< Allow to be maximized */
    OB_CLIENT_FUNC_SHADE      = 1 << 4, /*!< Allow to be shaded */
    OB_CLIENT_FUNC_FULLSCREEN = 1 << 5, /*!< Allow to be made fullscreen */
    OB_CLIENT_FUNC_CLOSE      = 1 << 6  /*!< Allow to be closed */
} ObFunctions;

@interface AZClient: NSObject <AZWindow>
{
    Window  window;

    /*! The window's decorations. NULL while the window is being managed! */
    AZFrame *frame;

    /*! The number of unmap events to ignore on the window */
    int ignore_unmaps;

    /*! The id of the group the window belongs to */
    AZGroup *group;

    /*! Saved session data to apply to this client */
    struct _ObSessionState *session;

    /*! Whether or not the client is a transient window. This is guaranteed to 
      be TRUE if transient_for != NULL, but not guaranteed to be FALSE if
      transient_for == NULL. */
    BOOL transient;

    /*! The client which this client is a transient (child) for.
      A value of TRAN_GROUP signifies that the window is a transient for all
      members of its ObGroup, and is not a valid pointer to be followed in this
      case.
     */
    AZClient *transient_for;

    /*! The clients which are transients (children) of this client */
    NSMutableArray *transients;

    /*! The desktop on which the window resides (0xffffffff for all
      desktops) */
    unsigned int desktop;

    /*! The startup id for the startup-notification protocol. This will be
      NULL if a startup id is not set. */
    NSString *startup_id;

    /*! Normal window title */
    NSString *title;
    /*! The count for the title. When another window with the same title
      exists, a count will be appended to it. */
    unsigned int title_count;
    /*! Window title when iconified */
    NSString *icon_title;

    /*! The application that created the window */
    NSString *name;
    /*! The class of the window, can used for grouping */
    NSString *class;
    /*! The specified role of the window, used for identification */
    NSString *role;
    /*! The session client id for the window. *This can be NULL!* */
    NSString  *sm_client_id;

    /*! The type of window (what its function is) */
    ObClientType type;

    /*! Position and size of the window
      This will not always be the actual position of the window on screen, it
      is, rather, the position requested by the client, to which the window's
      gravity is applied.
    */
    Rect area;

    /*! Position and size of the window prior to being maximized */
    Rect pre_max_area;
    /*! Position and size of the window prior to being fullscreened */
    Rect pre_fullscreen_area;

    /*! The window's strut
      The strut defines areas of the screen that are marked off-bounds for
      window placement. In theory, where this window exists.
    */
    StrutPartial strut;
     
    /*! The logical size of the window
      The "logical" size of the window is refers to the user's perception of
      the size of the window, and is the value that should be displayed to the
      user. For example, with xterms, this value it the number of characters
      being displayed in the terminal, instead of the number of pixels.
    */
    Size logical_size;

    /*! Width of the border on the window.
      The window manager will set this to 0 while the window is being managed,
      but needs to restore it afterwards, so it is saved here.
    */
    unsigned int border_width;

    /*! The minimum aspect ratio the client window can be sized to.
      A value of 0 means this is ignored.
    */
    float min_ratio;
    /*! The maximum aspect ratio the client window can be sized to.
      A value of 0 means this is ignored.
    */
    float max_ratio;

    /*! The minimum size of the client window
      If the min is > the max, then the window is not resizable
    */
    Size min_size;
    /*! The maximum size of the client window
      If the min is > the max, then the window is not resizable
    */
    Size max_size;
    /*! The size of increments to resize the client window by */
    Size size_inc;
    /*! The base size of the client window
      This value should be subtracted from the window's actual size when
      displaying its size to the user, or working with its min/max size
    */
    Size base_size;

    /*! Window decoration and functionality hints */
    ObMwmHints mwmhints;

    /*! GNUstep attributes */
    GNUstepWMAttributes gnustep_attr;

    /*! Where to place the decorated window in relation to the undecorated
      window */
    int gravity;

    /*! The state of the window, one of WithdrawnState, IconicState, or
      NormalState */
    long wmstate;

    /*! True if the client supports the delete_window protocol */
    BOOL delete_window;
  
    /*! Was the window's position requested by the application or the user?
      if by the application, we force it completely onscreen, if by the user
      we only force it if it tries to go completely offscreen, if neither, we
      should place the window ourselves when it first appears */
    unsigned int positioned;
  
    /*! The layer in which the window will be stacked, windows in lower layers
      are always below windows in higher layers. */
    ObStackingLayer layer;

    /*! Can the window receive input focus? */
    BOOL can_focus;
    /*! Urgency flag */
    BOOL urgent;
    /*! Notify the window when it receives focus? */
    BOOL focus_notify;

    /*! The window uses shape extension to be non-rectangular? */
    BOOL shaped;

    /*! The window is modal, so it must be processed before any windows it is
      related to can be focused */
    BOOL modal;
    /*! Only the window's titlebar is displayed */
    BOOL shaded;
    /*! The window is iconified */
    BOOL iconic;
    /*! The window is maximized to fill the screen vertically */
    BOOL max_vert;
    /*! The window is maximized to fill the screen horizontally */
    BOOL max_horz;
    /*! The window should not be displayed by pagers */
    BOOL skip_pager;
    /*! The window should not be displayed by taskbars */
    BOOL skip_taskbar;
    /*! The window is a 'fullscreen' window, and should be on top of all
      others */
    BOOL fullscreen;
    /*! The window should be on top of other windows of the same type.
      above takes priority over below. */
    BOOL above;
    /*! The window should be underneath other windows of the same type.
      above takes priority over below. */
    BOOL below;

    /*! A bitmask of values in the ObFrameDecorations enum
      The values in the variable are the decorations that the client wants to
      be displayed around it.
    */
    unsigned int decorations;

    /*! A user option. When this is set to TRUE the client will not ever
      be decorated.
    */
    BOOL undecorated;

    /*! A bitmask of values in the ObFunctions enum
      The values in the variable specify the ways in which the user is allowed
      to modify this window.
    */
    unsigned int functions;

    /*! Icons for the client as specified on the client window */
    NSMutableArray *icons;
}

/*! Determines if the client should be shown or hidden currently.
    @return TRUE if it should be visible; otherwise, FALSE.
 */
- (BOOL) shouldShow;

/*! Returns if the window should be treated as a normal window.
    Some windows (desktops, docks, splash screens) have special rules applied
    to them in a number of places regarding focus or user interaction. */
- (BOOL) normal;

- (void) moveToX: (int) x y: (int) y;
- (void) resizeToWidth: (int) w height: (int) h;
- (void) moveAndResizeToX: (int) x y: (int) y width: (int) w height: (int) h;
- (void) configureToCorner: (ObCorner) anchor x: (int) x y: (int) y 
                     width: (int) w height: (int) h
		     user: (BOOL) user final: (BOOL) final;

/*! Move and/or resize the window.
    This also maintains things like the client's minsize, and size increments.
    @param anchor The corner to keep in the same position when resizing.
    @param x The x coordiante of the new position for the client.
    @param y The y coordiante of the new position for the client.
    @param w The width component of the new size for the client.
    @param h The height component of the new size for the client.
    @param user Specifies whether this is a user-requested change or a
                program requested change. For program requested changes, the
                constraints are not checked.
    @param final If user is true, then this should specify if this is a final
                 configuration. e.g. Final should be FALSE if doing an
                 interactive move/resize, and then be TRUE for the last call
                 only.
    @param force_reply Send a ConfigureNotify to the client regardless of if
                       the position changed.
 */
- (void) configureToCorner: (ObCorner) anchor x: (int) x y: (int) y 
                     width: (int) w height: (int) h
		     user: (BOOL) user final: (BOOL) final
		     forceReply: (BOOL) force_reply;

- (void) reconfigure;

/*! Finds coordinates to keep a client on the screen.
    @param oself The client
    @param x The x coord of the client, may be changed.
    @param y The y coord of the client, may be changed.
    @param w The width of the client.
    @param w The height of the client.
    @param rude Be rude about it. If false, it is only moved if it is entirely
                not visible. If true, then make sure the window is inside the
                struts if possible.
    @return true if the client was moved to be on-screen; false if not.
 */
- (BOOL) findOnScreenAtX: (int *) x y: (int *) y 
                   width: (int) w height: (int) h rude: (BOOL) rude;

/*! Moves a client so that it is on screen if it is entirely out of the
    viewable screen.
    @param oself The client to move
    @param rude Be rude about it. If false, it is only moved if it is entirely
                not visible. If true, then make sure the window is inside the
                struts if possible.
 */
- (void) moveOnScreen: (BOOL) rude;

/*! Fullscreen's or unfullscreen's the client window
    @param fs true if the window should be made fullscreen; false if it should
    be returned to normal state.
    @param savearea true to have the client's current size and position saved;
    otherwise, they are not. You should not save when mapping a
    new window that is set to fullscreen. This has no effect
    when restoring a window from fullscreen.
 */
- (void) fullscreen: (BOOL) fs saveArea: (BOOL) savearea;

/*! Iconifies or uniconifies the client window
    @param iconic true if the window should be iconified; false if it should be
    restored.
    @param curdesk If iconic is FALSE, then this determines if the window will
    be uniconified to the current viewable desktop (true) or to
    its previous desktop (false)
 */
- (void) iconify: (BOOL) iconic currentDesktop: (BOOL) curdesk;

/*! Maximize or unmaximize the client window
    @param max true if the window should be maximized; false if it should be
    returned to normal size.
    @param dir 0 to set both horz and vert, 1 to set horz, 2 to set vert.
    @param savearea true to have the client's current size and position saved;
    otherwise, they are not. You should not save when mapping a
    new window that is set to fullscreen. This has no effect
    when unmaximizing a window.
 */
- (void) maximize: (BOOL) max direction: (int) dir saveArea: (BOOL) savearea;

/*! Shades or unshades the client window
    @param shade true if the window should be shaded; false if it should be
    unshaded.
 */
- (void) shade: (BOOL) shade;

/*! Request the client to close its window */
- (void) close;

/*! Kill the client off violently */
- (void) kill;

/* Returns if the window is focused */
- (BOOL) focused;

/*! Sends the window to the specified desktop
    @param donthide If TRUE, the window will not be shown/hidden after its
    desktop has been changed. Generally this should be FALSE. */
- (void) setDesktop: (unsigned int) target hide: (BOOL) donthide;

/*! Validate client, by making sure no Destroy or Unmap events exist in
    the event queue for the window.
    @return true if the client is valid; false if the client has already
    been unmapped/destroyed, and so is invalid.
 */
- (BOOL) validate;

/*! Sets the wm_state to the specified value */
- (void) setWmState: (long) state;

/*! Adjusts the window's net_state
    This should not be called as part of the window mapping process! It is for
    use when updating the state post-mapping.<br>
    client_apply_startup_state is used to do the same things during the mapping
    process.
 */
- (void) setState: (Atom) action data1: (long) data1 data2: (long) data2;

/* Given a ObClient, find the client that focus would actually be sent to if
   you wanted to give focus to the specified ObClient. Will return the same
   ObClient passed to it or another ObClient if appropriate. */
- (AZClient *) focusTarget;

/*! Returns what client_focus would return if passed the same client, but
 *   without focusing it or modifying the focus order lists. */
- (BOOL) canFocus;

/*! Attempt to focus the client window */
- (BOOL) focus;

/*! Remove focus from the client window */
- (void) unfocus;

/*! Activates the client for use, focusing, uniconifying it, etc. To be used
    when the user deliberately selects a window for use.
    @param here If true, then the client is brought to the current desktop;
    otherwise, the desktop is changed to where the client lives.
 */
- (void) activateHere: (BOOL) here;

/*! Calculates the stacking layer for the client window */
- (void) calcLayer;

/*! Raises the client to the top of its stacking layer
    Normally actions call to the client_* functions to make stuff go, but this
    one is an exception. It just fires off an action, which will be queued.
    This is because stacking order rules can be changed by focus state, and so
    any time focus changes you have to wait for it to complete before you can
    properly restart windows. As such, this only queues an action for later
    execution, once the focus change has gone through.
 */
- (void) raise;

/*! Lowers the client to the bottom of its stacking layer
    Normally actions call to the client_* functions to make stuff go, but this
    one is an exception. It just fires off an action, which will be queued.
    This is because stacking order rules can be changed by focus state, and so
    any time focus changes you have to wait for it to complete before you can
    properly restart windows. As such, this only queues an action for later
    execution, once the focus change has gone through.
 */
- (void) lower;

/*! Updates the window's transient status, and any parents of it */
- (void) updateTransientFor;

/*! Update the protocols that the window supports and adjusts things if they
    change */
- (void) updateProtocols;

/*! Updates the WMNormalHints and adjusts things if they change */
- (void) updateNormalHints;

/*! Updates the WMHints and adjusts things if they change
    @param initstate Whether to read the initial_state property from the
    WMHints. This should only be used during the mapping
    process.
 */
- (void) updateWmhints;

/*! Updates the window's title and icon title */
- (void) updateTitle;

/*! Updates the window's application name and class */
- (void) updateClass;

/*! Updates the strut for the client */
- (void) updateStrut;

/*! Updates the window's icons */
- (void) updateIcons;

/*! Set up what decor should be shown on the window and what functions should
    be allowed (ObClient::decorations and ObClient::functions).
    This also updates the NET_WM_ALLOWED_ACTIONS hint.
 */
- (void) setupDecorAndFunctions;

/*! Retrieves the window's type and sets ObClient->type */
- (void) getType;

- (AZClientIcon *) iconWithWidth: (int) w height: (int) h;

/*! Searches a client's direct parents for a focused window. The function does
    not check for the passed client, only for *ONE LEVEL* of its parents.
    If no focused parentt is found, NULL is returned.
 */
- (AZClient *) searchFocusParent;

/*! Searches a client's transients for a focused window. The function does not
    check for the passed client, only for its transients.
    If no focused transient is found, NULL is returned.
 */
- (AZClient *) searchFocusTree;

/*! Searches a client's transient tree for a focused window. The function
    searches up the tree and down other branches as well as the passed client's.
    If no focused client is found, NULL is returned.
 */
//- (AZClient *) searchFocusTreeFull; // Not used

/*! Return a modal child of the client window that can be focused.
    @return A modal child of the client window that can be focused, or 0 if
    none was found.
 */
- (AZClient *) searchModalChild;

- (AZClient *) searchTopTransient;

/*! Search for a transient of a client. The transient is returned if it is one,
     NULL is returned if the given search is not a transient of the client. */
- (AZClient *) searchTransient: (AZClient *) search;

/*! Return the "closest" client in the given direction */
- (AZClient *) findDirectional: (ObDirection) dir;

/*! Return the closest edge in the given direction */
- (int) directionalEdgeSearch: (ObDirection) dir;

/*! Set a client window to be above/below other clients.
    @layer < 0 indicates the client should be placed below other clients.<br>
    = 0 indicates the client should be placed with other clients.<br>
    > 0 indicates the client should be placed above other clients.
 */
- (void) setLayer: (int) layer;

/*! Set a client window to have decorations or not */
- (void) setUndecorated: (BOOL) undecorated;
- (unsigned int) monitor;
- (void) updateSmClientId;
- (BOOL) hasGroupSiblings;

/* For AZClientManager */
- (void) getAll;
- (void) restoreSessionState;
- (void) changeState;
- (void) toggleBorder: (BOOL) show;
- (void) applyStartupState;
- (void) restoreSessionStacking;
- (void) showhide;

/* Accessories */
- (AZFrame *) frame;
- (void) set_frame: (AZFrame *) frame;

- (Window) window;
//- (Window *) windowPointer;
- (int) ignore_unmaps;
- (void) set_window: (Window) window;
- (void) set_ignore_unmaps: (int) ignore_unmaps;

- (AZGroup *) group;
- (void) set_group: (AZGroup *) group;

- (struct _ObSessionState *) session;
- (void) set_session: (struct _ObSessionState *) session;

- (BOOL) transient;
- (void) set_transient: (BOOL) transient;

- (AZClient *) transient_for;
- (void) set_transient_for: (AZClient *) transient_for;

- (NSArray *) transients;
- (void) removeTransient: (AZClient *) client;
- (void) addTransient: (AZClient *) client;
- (void) removeAllTransients;

- (unsigned int) desktop;
- (NSString *) startup_id;
- (void) set_desktop: (unsigned int) desktop;
- (void) set_startup_id: (NSString *) startup_id;

- (NSString *) title;
- (unsigned int ) title_count;
- (NSString *) icon_title;
- (NSString *) name;
- (NSString *) class;
- (NSString *) role;
- (NSString *) sm_client_id;
- (ObClientType) type;
- (void) set_title: (NSString *) title;
- (void) set_title_count: (unsigned int ) title_count;
- (void) set_icon_title: (NSString *) icon_title;
- (void) set_name: (NSString *) name;
- (void) set_class: (NSString *) class;
- (void) set_role: (NSString *) role;
- (void) set_sm_client_id: (NSString *) sm_client_id;
- (void) set_type: (ObClientType) type;

- (Rect) area;
- (Rect) pre_max_area;
- (Rect) pre_fullscreen_area;
- (StrutPartial) strut;
- (Size) logical_size;
- (unsigned int) border_width;
- (float) min_ratio;
- (float) max_ratio;
- (Size) min_size;
- (Size) max_size;
- (Size) size_inc;
- (Size) base_size;
- (ObMwmHints) mwmhints;
- (void) set_area: (Rect) area;
- (void) set_pre_max_area: (Rect) pre_max_area;
- (void) set_pre_fullscreen_area: (Rect) pre_fullscreen_area;
- (void) set_strut: (StrutPartial) strut;
- (void) set_logical_size: (Size) logical_size;
- (void) set_border_width: (unsigned int) border_width;
- (void) set_min_ratio: (float) min_ratio;
- (void) set_max_ratio: (float) max_ratio;
- (void) set_min_size: (Size) min_size;
- (void) set_max_size: (Size) max_size;
- (void) set_size_inc: (Size) size_inc;
- (void) set_base_size: (Size) base_size;
- (void) set_mwmhints: (ObMwmHints) mwmhints;

- (int) gravity;
- (long) wmstate;
- (BOOL) delete_window;
- (unsigned int) positioned;
- (ObStackingLayer) layer;
- (void) set_gravity: (int) gravity;
- (void) set_wmstate: (long) wmstate;
- (void) set_delete_window: (BOOL) delete_window;
- (void) set_positioned: (unsigned int) positioned;
- (void) set_layer: (ObStackingLayer) layer;


- (BOOL) can_focus;
- (BOOL) urgent;
- (BOOL) focus_notify;
- (BOOL) shaped;
- (void) set_can_focus: (BOOL) can_focus;
- (void) set_urgent: (BOOL) urgent;
- (void) set_focus_notify: (BOOL) focus_notify;
- (void) set_shaped: (BOOL) shaped;

- (BOOL) modal;
- (BOOL) shaded;
- (BOOL) iconic;
- (BOOL) max_vert;
- (BOOL) max_horz;
- (BOOL) skip_pager;
- (BOOL) skip_taskbar;
- (BOOL) fullscreen;
- (BOOL) above;
- (BOOL) below;
- (void) set_modal: (BOOL) modal;
- (void) set_shaded: (BOOL) shaded;
- (void) set_iconic: (BOOL) iconic;
- (void) set_max_vert: (BOOL) max_vert;
- (void) set_max_horz: (BOOL) max_horz;
- (void) set_skip_pager: (BOOL) skip_pager;
- (void) set_skip_taskbar: (BOOL) skip_taskbar;
- (void) set_fullscreen: (BOOL) fullscreen;
- (void) set_above: (BOOL) above;
- (void) set_below: (BOOL) below;

- (unsigned int) decorations;
- (void) set_decorations: (unsigned int) decorations;
- (BOOL) undecorated;
- (void) set_undecorated: (BOOL) undecorated;
- (unsigned int) functions;
- (void) set_functions: (unsigned int) functions;

- (NSArray *) icons;
- (void) removeAllIcons;
- (void) addIcon: (AZClientIcon *) icon;

/* Only used for category */
- (void) changeAllowedActions;

@end

AZClient *AZUnderPointer();

