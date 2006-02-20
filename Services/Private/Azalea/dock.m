/* dock.c- built-in Dock module for WindowMaker
 *
 *  Window Maker window manager
 *
 *  Copyright (c) 1997-2003 Alfredo K. Kojima
 *  Copyright (c) 1998-2003 Dan Pascu
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
 *  USA.
 */


#include "wconfig.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <limits.h>

#ifndef PATH_MAX
#define PATH_MAX DEFAULT_PATH_MAX
#endif

#include "WindowMaker.h"
#include "wcore.h"
#include "window.h"
#include "icon.h"
#include "appicon.h"
#include "actions.h"
#include "stacking.h"
#include "dock.h"
#include "dialog.h"
#include "funcs.h"
#include "properties.h"
#include "menu.h"
#include "client.h"
#include "defaults.h"
#include "workspace.h"
#include "framewin.h"
#include "superfluous.h"
#include "wsound.h"
#include "xinerama.h"

#include "WMDialogController.h"
#include "WMDefaults.h"
#include "WMDockedAppPanel.h"

/**** Local variables ****/
#define CLIP_REWIND       1
#define CLIP_IDLE         0
#define CLIP_FORWARD      2


/**** Global variables ****/

extern XContext wWinContext;

extern Cursor wCursor[WCUR_LAST];

extern WPreferences wPreferences;

extern XContext wWinContext;


#define MOD_MASK wPreferences.modifier_mask

extern void appIconMouseDown(WObjDescriptor *desc, XEvent *event);

#define ICON_SIZE wPreferences.icon_size


/***** Local variables ****/

static NSString *dCommand = @"Command";
static NSString *dPasteCommand = @"PasteCommand";
#ifdef XDND /* XXX was OFFIX */
static NSString *dDropCommand = @"DropCommand";
#endif
static NSString *dAutoLaunch = @"AutoLaunch";
static NSString *dLock = @"Lock";
static NSString *dName = @"Name";
static NSString *dForced = @"Forced";
static NSString *dBuggyApplication = @"BuggyApplication";
static NSString *dYes = @"YES";
static NSString *dNo = @"NO";
static NSString *dHost = @"Host";
static NSString *dAutoAttractIcons = @"AutoAttractIcons";
static NSString *dPosition = @"Position";
static NSString *dApplications = @"Applications";
static NSString *dLowered = @"Lowered";
static NSString *dCollapsed = @"Collapsed";
static NSString *dAutoCollapse = @"AutoCollapse";
static NSString *dAutoRaiseLower = @"AutoRaiseLower";
static NSString *dOmnipresent = @"Omnipresent";

static void dockIconPaint(WAppIcon *btn);

static void iconMouseDown(WObjDescriptor *desc, XEvent *event);

static pid_t execCommand(WAppIcon *btn, char *command, WSavedState *state);

static void trackDeadProcess(pid_t pid, unsigned char status, WDock *dock);

static int getClipButton(int px, int py);

static void toggleLowered(WDock *dock);

static void toggleCollapsed(WDock *dock);

static void clipIconExpose(WObjDescriptor *desc, XEvent *event);

static void clipLeave(WDock *dock);

static void handleClipChangeWorkspace(WScreen *scr, XEvent *event);

Bool moveIconBetweenDocks(WDock *src, WDock *dest, WAppIcon *icon, int x, int y);

static void clipEnterNotify(WObjDescriptor *desc, XEvent *event);
static void clipLeaveNotify(WObjDescriptor *desc, XEvent *event);
static void clipAutoCollapse(void *cdata);
static void clipAutoExpand(void *cdata);
static void launchDockedApplication(WAppIcon *btn, Bool withSelection);

static void clipAutoLower(void *cdata);
static void clipAutoRaise(void *cdata);

static void showClipBalloon(WDock *dock, int workspace);

static void
renameCallback(WMenu *menu, WMenuEntry *entry)
{
    WDock *dock = entry->clientdata;
    int wspace;

    assert(entry->clientdata!=NULL);

    wspace = dock->screen_ptr->current_workspace;


    NSString *result = [[WMDialogController sharedController] inputDialogWithTitle: @"Rename Workspace"
	    message: [NSString stringWithFormat: @"Type the name for workspace %i:", wspace]
	    text: [NSString stringWithCString: dock->screen_ptr->workspaces[wspace]->name]];
    if (result)
    {
	wWorkspaceRename(dock->screen_ptr, wspace, (char*)[result cString]);
    }
}


static void
toggleLoweredCallback(WMenu *menu, WMenuEntry *entry)
{
    assert(entry->clientdata!=NULL);

    toggleLowered(entry->clientdata);

    entry->flags.indicator_on = !(((WDock*)entry->clientdata)->lowered);

    wMenuPaint(menu);
}


static int
matchWindow(void *item, void *cdata)
{
    return (((WFakeGroupLeader*)item)->leader == (Window)cdata);
}


static void
killCallback(WMenu *menu, WMenuEntry *entry)
{
    WScreen *scr = menu->menu->screen_ptr;
    WAppIcon *icon;
    WFakeGroupLeader *fPtr;
    char *buffer;

    if (!WCHECK_STATE(WSTATE_NORMAL))
        return;

    assert(entry->clientdata!=NULL);

    icon = (WAppIcon*)entry->clientdata;

    icon->editing = 1;

    WCHANGE_STATE(WSTATE_MODAL);

    buffer = wstrconcat(icon->wm_class,
                        (" will be forcibly closed.\n"
                          "Any unsaved changes will be lost.\n"
                          "Please confirm."));

    if (icon->icon && icon->icon->owner) {
        fPtr = icon->icon->owner->fake_group;
    } else {
        /* is this really necessary? can we kill a non-running dock icon? */
        Window win = icon->main_window;
        int index;

        index = WMFindInArray(scr->fakeGroupLeaders, matchWindow, (void*)win);
        if (index != WANotFound)
            fPtr = WMGetFromArray(scr->fakeGroupLeaders, index);
        else
            fPtr = NULL;
    }

    if (wPreferences.dont_confirm_kill
        || NSRunAlertPanel(@"Kill Application", [NSString stringWithCString: buffer], @"Yes", @"No", nil) == NSAlertDefaultReturn)
    {
        if (fPtr!=NULL) {
            WWindow *wwin, *twin;

            wwin = scr->focused_window;
            while (wwin) {
                twin = wwin->prev;
                if (wwin->fake_group == fPtr) {
                    wClientKill(wwin);
                }
                wwin = twin;
            }
        } else if (icon->icon && icon->icon->owner) {
            wClientKill(icon->icon->owner);
        }
    }

    wfree(buffer);

    icon->editing = 0;

    WCHANGE_STATE(WSTATE_NORMAL);
}


/* TODO: replace this function with a member of the dock struct */
static int
numberOfSelectedIcons(WDock *dock)
{
    WAppIcon *aicon;
    int i, n;

    n = 0;
    for (i=1; i<dock->max_icons; i++) {
        aicon = dock->icon_array[i];
        if (aicon && aicon->icon->selected) {
            n++;
        }
    }

    return n;
}


static WMArray*
getSelected(WDock *dock)
{
    WMArray *ret = WMCreateArray(8);
    WAppIcon *btn;
    int i;

    for (i=1; i<dock->max_icons; i++) {
        btn = dock->icon_array[i];
        if (btn && btn->icon->selected) {
            WMAddToArray(ret, btn);
        }
    }

    return ret;
}


static void
paintClipButtons(WAppIcon *clipIcon, Bool lpushed, Bool rpushed)
{
    Window win = clipIcon->icon->core->window;
    WScreen *scr = clipIcon->icon->core->screen_ptr;
    XPoint p[4];
    int pt = CLIP_BUTTON_SIZE*ICON_SIZE/64;
    int tp = ICON_SIZE - pt;
    int as = pt - 15; /* 15 = 5+5+5 */
    GC gc = scr->draw_gc; /* maybe use WMColorGC() instead here? */
    WMColor *color;
#ifdef GRADIENT_CLIP_ARROW
    Bool collapsed = clipIcon->dock->collapsed;
#endif

    /*if (!clipIcon->dock->collapsed)
        color = scr->clip_title_color[CLIP_NORMAL];
    else
        color = scr->clip_title_color[CLIP_COLLAPSED];*/
    color = scr->clip_title_color[CLIP_NORMAL];

    XSetForeground(dpy, gc, WMColorPixel(color));

    if (rpushed) {
        p[0].x = tp+1;
        p[0].y = 1;
        p[1].x = ICON_SIZE-2;
        p[1].y = 1;
        p[2].x = ICON_SIZE-2;
        p[2].y = pt-1;
    } else if (lpushed) {
        p[0].x = 1;
        p[0].y = tp;
        p[1].x = pt;
        p[1].y = ICON_SIZE-2;
        p[2].x = 1;
        p[2].y = ICON_SIZE-2;
    }
    if (lpushed || rpushed) {
        XSetForeground(dpy, scr->draw_gc, scr->white_pixel);
        XFillPolygon(dpy, win, scr->draw_gc, p, 3, Convex, CoordModeOrigin);
        XSetForeground(dpy, scr->draw_gc, scr->black_pixel);
    }
#ifdef GRADIENT_CLIP_ARROW
    if (!collapsed) {
        XSetFillStyle(dpy, scr->copy_gc, FillTiled);
        XSetTile(dpy, scr->copy_gc, scr->clip_arrow_gradient);
        XSetClipMask(dpy, scr->copy_gc, None);
        gc = scr->copy_gc;
    }
#endif /* GRADIENT_CLIP_ARROW */

    /* top right arrow */
    p[0].x = p[3].x = ICON_SIZE-5-as;
    p[0].y = p[3].y = 5;
    p[1].x = ICON_SIZE-6;
    p[1].y = 5;
    p[2].x = ICON_SIZE-6;
    p[2].y = 4+as;
    if (rpushed) {
        XFillPolygon(dpy, win, scr->draw_gc, p, 3, Convex, CoordModeOrigin);
        XDrawLines(dpy, win, scr->draw_gc, p, 4, CoordModeOrigin);
    } else {
#ifdef GRADIENT_CLIP_ARROW
        if (!collapsed)
            XSetTSOrigin(dpy, gc, ICON_SIZE-6-as, 5);
#endif
        XFillPolygon(dpy, win, gc, p,3,Convex,CoordModeOrigin);
        XDrawLines(dpy, win, gc, p,4,CoordModeOrigin);
    }

    /* bottom left arrow */
    p[0].x = p[3].x = 5;
    p[0].y = p[3].y = ICON_SIZE-5-as;
    p[1].x = 5;
    p[1].y = ICON_SIZE-6;
    p[2].x = 4+as;
    p[2].y = ICON_SIZE-6;
    if (lpushed) {
        XFillPolygon(dpy, win, scr->draw_gc, p, 3, Convex, CoordModeOrigin);
        XDrawLines(dpy, win, scr->draw_gc, p, 4, CoordModeOrigin);
    } else {
#ifdef GRADIENT_CLIP_ARROW
        if (!collapsed)
            XSetTSOrigin(dpy, gc, 5, ICON_SIZE-6-as);
#endif
        XFillPolygon(dpy, win, gc, p,3,Convex,CoordModeOrigin);
        XDrawLines(dpy, win, gc, p,4,CoordModeOrigin);
    }
#ifdef GRADIENT_CLIP_ARROW
    if (!collapsed)
        XSetFillStyle(dpy, scr->copy_gc, FillSolid);
#endif
}


RImage*
wClipMakeTile(WScreen *scr, RImage *normalTile)
{
    RImage *tile = RCloneImage(normalTile);
    RColor black;
    RColor dark;
    RColor light;
    int pt, tp;
    int as;

    pt = CLIP_BUTTON_SIZE*wPreferences.icon_size/64;
    tp = wPreferences.icon_size-1 - pt;
    as = pt - 15;

    black.alpha = 255;
    black.red = black.green = black.blue = 0;

    dark.alpha = 0;
    dark.red = dark.green = dark.blue = 60;

    light.alpha = 0;
    light.red = light.green = light.blue = 80;


    /* top right */
    ROperateLine(tile, RSubtractOperation, tp, 0, wPreferences.icon_size-2,
                 pt-1, &dark);
    RDrawLine(tile, tp-1, 0, wPreferences.icon_size-1, pt+1, &black);
    ROperateLine(tile, RAddOperation, tp, 2, wPreferences.icon_size-3,
                 pt, &light);

    /* arrow bevel */
    ROperateLine(tile, RSubtractOperation, ICON_SIZE - 7 - as, 4,
                 ICON_SIZE - 5, 4, &dark);
    ROperateLine(tile, RSubtractOperation, ICON_SIZE - 6 - as, 5,
                 ICON_SIZE - 5, 6 + as, &dark);
    ROperateLine(tile, RAddOperation, ICON_SIZE - 5, 4, ICON_SIZE - 5, 6 + as,
                 &light);

    /* bottom left */
    ROperateLine(tile, RAddOperation, 2, tp+2, pt-2,
                 wPreferences.icon_size-3, &dark);
    RDrawLine(tile, 0, tp-1, pt+1, wPreferences.icon_size-1, &black);
    ROperateLine(tile, RSubtractOperation, 0, tp-2, pt+1,
                 wPreferences.icon_size-2, &light);

    /* arrow bevel */
    ROperateLine(tile, RSubtractOperation, 4, ICON_SIZE - 7 - as, 4,
                 ICON_SIZE - 5, &dark);
    ROperateLine(tile, RSubtractOperation, 5, ICON_SIZE - 6 - as,
                 6 + as, ICON_SIZE - 5, &dark);
    ROperateLine(tile, RAddOperation, 4, ICON_SIZE - 5, 6 + as, ICON_SIZE - 5,
                 &light);

    return tile;
}


static void
omnipresentCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *clickedIcon = entry->clientdata;
    WAppIcon *aicon;
    WDock *dock;
    WMArray *selectedIcons;
    WMArrayIterator iter;
    int failed;

    assert(entry->clientdata!=NULL);

    dock = clickedIcon->dock;

    selectedIcons = getSelected(dock);

    if (!WMGetArrayItemCount(selectedIcons))
        WMAddToArray(selectedIcons, clickedIcon);

    failed = 0;
    WM_ITERATE_ARRAY(selectedIcons, aicon, iter) {
        if (wClipMakeIconOmnipresent(aicon, !aicon->omnipresent) == WO_FAILED)
            failed++;
        else if (aicon->icon->selected)
            wIconSelect(aicon->icon);
    }
    WMFreeArray(selectedIcons);

    if (failed > 1) {
        NSRunAlertPanel(@"Warning", @"Some icons cannot be made omnipresent.\nPlease make sure that no other icon is\ndocked in the same positions on the other\nworkspaces and the Clip is not full in\nsome workspace",
			@"OK", nil, nil);
    } else if (failed == 1) {
        NSRunAlertPanel(@"Warning", @"Icon cannot be made omnipresent.\nPlease make sure that no other icon is\ndocked in the same positions on the other\nworkspaces and the Clip is not full in\nsome workspace",
			@"OK", nil, nil);
    }
}


static void
removeIconsCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *clickedIcon = (WAppIcon*)entry->clientdata;
    WDock *dock;
    WAppIcon *aicon;
    WMArray *selectedIcons;
    int keepit;
    WMArrayIterator it;

    assert(clickedIcon!=NULL);

    dock = clickedIcon->dock;

    selectedIcons = getSelected(dock);

    if (WMGetArrayItemCount(selectedIcons)) {
        if (NSRunAlertPanel(@"Workspace Clip", @"All selected icons will be removed!", @"OK", @"Cancel", nil) != NSAlertDefaultReturn)

	{
            WMFreeArray(selectedIcons);
            return;
        }
    } else {
        if (clickedIcon->xindex==0 && clickedIcon->yindex==0) {
            WMFreeArray(selectedIcons);
            return;
        }
        WMAddToArray(selectedIcons, clickedIcon);
    }

    WM_ITERATE_ARRAY(selectedIcons, aicon, it) {
        keepit = aicon->running && wApplicationOf(aicon->main_window);
        wDockDetach(dock, aicon);
        if (keepit) {
            /* XXX: can: aicon->icon == NULL ? */
            PlaceIcon(dock->screen_ptr, &aicon->x_pos, &aicon->y_pos, wGetHeadForWindow(aicon->icon->owner));
            XMoveWindow(dpy, aicon->icon->core->window,
                        aicon->x_pos, aicon->y_pos);
            if (!dock->mapped || dock->collapsed)
                XMapWindow(dpy, aicon->icon->core->window);
        }
    }
    WMFreeArray(selectedIcons);

    if (wPreferences.auto_arrange_icons)
        wArrangeIcons(dock->screen_ptr, True);
}


static void
keepIconsCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *clickedIcon = (WAppIcon*)entry->clientdata;
    WDock *dock;
    WAppIcon *aicon;
    WMArray *selectedIcons;
    WMArrayIterator it;

    assert(clickedIcon!=NULL);
    dock = clickedIcon->dock;

    selectedIcons = getSelected(dock);

    if (!WMGetArrayItemCount(selectedIcons)
        && clickedIcon!=dock->screen_ptr->clip_icon) {
        char *command = NULL;

        if (!clickedIcon->command && !clickedIcon->editing) {
            clickedIcon->editing = 1;
	    NSString *result = [[WMDialogController sharedController] inputDialogWithTitle: @"Keep Icon"
		    message: @"Type the command used to launch the application"
		    text: nil]; // command is not set yet
	    if (result)
	    {
		command = wstrdup((char*)[result cString]);
                if (command && (command[0]==0 ||
                                (command[0]=='-' && command[1]==0))) {
                    wfree(command);
                    command = NULL;
                }
                clickedIcon->command = command;
                clickedIcon->editing = 0;
            } else {
                clickedIcon->editing = 0;
                if (command)
                    wfree(command);
                WMFreeArray(selectedIcons);
                return;
            }
        }

        WMAddToArray(selectedIcons, clickedIcon);
    }

    WM_ITERATE_ARRAY(selectedIcons, aicon, it) {
        if (aicon->icon->selected)
            wIconSelect(aicon->icon);
        if (aicon && aicon->attracted && aicon->command) {
            aicon->attracted = 0;
            if (aicon->icon->shadowed) {
                aicon->icon->shadowed = 0;
                aicon->icon->force_paint = 1;
                wAppIconPaint(aicon);
            }
        }
    }
    WMFreeArray(selectedIcons);
}




static void
toggleAutoAttractCallback(WMenu *menu, WMenuEntry *entry)
{
    WDock *dock = (WDock*)entry->clientdata;

    assert(entry->clientdata!=NULL);

    dock->attract_icons = !dock->attract_icons;
    /*if (!dock->attract_icons)
     dock->keep_attracted = 0;*/

    entry->flags.indicator_on = dock->attract_icons;

    wMenuPaint(menu);
}


static void
selectCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *icon = (WAppIcon*)entry->clientdata;

    assert(icon!=NULL);

    wIconSelect(icon->icon);

    wMenuPaint(menu);
}


static void
colectIconsCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *clickedIcon = (WAppIcon*)entry->clientdata;
    WDock *clip;
    WAppIcon *aicon;
    int x, y, x_pos, y_pos;

    assert(entry->clientdata!=NULL);
    clip = clickedIcon->dock;

    aicon = clip->screen_ptr->app_icon_list;

    while (aicon) {
        if (!aicon->docked && wDockFindFreeSlot(clip, &x, &y)) {
            x_pos = clip->x_pos + x*ICON_SIZE;
            y_pos = clip->y_pos + y*ICON_SIZE;
            if (aicon->x_pos != x_pos || aicon->y_pos != y_pos) {
#ifdef ANIMATIONS
                if (wPreferences.no_animations) {
                    XMoveWindow(dpy, aicon->icon->core->window, x_pos, y_pos);
                } else {
                    SlideWindow(aicon->icon->core->window,
                                aicon->x_pos, aicon->y_pos, x_pos, y_pos);
                }
#else
                XMoveWindow(dpy, aicon->icon->core->window, x_pos, y_pos);
#endif /* ANIMATIONS */
            }
            aicon->attracted = 1;
            if (!aicon->icon->shadowed) {
                aicon->icon->shadowed = 1;
                aicon->icon->force_paint = 1;
                /* We don't do an wAppIconPaint() here because it's in
                 * wDockAttachIcon(). -Dan
                 */
            }
            wDockAttachIcon(clip, aicon, x, y);
            if (clip->collapsed || !clip->mapped)
                XUnmapWindow(dpy, aicon->icon->core->window);
        }
        aicon = aicon->next;
    }
}


static void
selectIconsCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *clickedIcon = (WAppIcon*)entry->clientdata;
    WDock *dock;
    WMArray *selectedIcons;
    WMArrayIterator iter;
    WAppIcon *btn;
    int i;

    assert(clickedIcon!=NULL);
    dock = clickedIcon->dock;

    selectedIcons = getSelected(dock);

    if (!WMGetArrayItemCount(selectedIcons)) {
        for (i=1; i<dock->max_icons; i++) {
            btn = dock->icon_array[i];
            if (btn && !btn->icon->selected) {
                wIconSelect(btn->icon);
            }
        }
    } else {
        WM_ITERATE_ARRAY(selectedIcons, btn, iter) {
            wIconSelect(btn->icon);
        }
    }
    WMFreeArray(selectedIcons);

    wMenuPaint(menu);
}


static void
toggleCollapsedCallback(WMenu *menu, WMenuEntry *entry)
{
    assert(entry->clientdata!=NULL);

    toggleCollapsed(entry->clientdata);

    entry->flags.indicator_on = ((WDock*)entry->clientdata)->collapsed;

    wMenuPaint(menu);
}


static void
toggleAutoCollapseCallback(WMenu *menu, WMenuEntry *entry)
{
    WDock *dock;
    assert(entry->clientdata!=NULL);

    dock = (WDock*) entry->clientdata;

    dock->auto_collapse = !dock->auto_collapse;

    entry->flags.indicator_on = ((WDock*)entry->clientdata)->auto_collapse;

    wMenuPaint(menu);
}


static void
toggleAutoRaiseLowerCallback(WMenu *menu, WMenuEntry *entry)
{
    WDock *dock;
    assert(entry->clientdata!=NULL);

    dock = (WDock*) entry->clientdata;

    dock->auto_raise_lower = !dock->auto_raise_lower;

    entry->flags.indicator_on = ((WDock*)entry->clientdata)->auto_raise_lower;

    wMenuPaint(menu);
}


static void
launchCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *btn = (WAppIcon*)entry->clientdata;

    launchDockedApplication(btn, False);
}


static void
settingsCallback(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *btn = (WAppIcon*)entry->clientdata;

    if (btn->editing)
        return;
//    ShowDockAppSettingsPanel(btn);
    WMDockedAppPanel *panel = [WMDockedAppPanel sharedPanel];
    [panel setAppIcon: btn];
    [panel makeKeyAndOrderFront: nil];
}


static void
hideCallback(WMenu *menu, WMenuEntry *entry)
{
    WApplication *wapp;
    WAppIcon *btn = (WAppIcon*)entry->clientdata;

    wapp = wApplicationOf(btn->icon->owner->main_window);

    if (wapp->flags.hidden) {
        wWorkspaceChange(btn->icon->core->screen_ptr, wapp->last_workspace);
        wUnhideApplication(wapp, False, False);
    } else {
        wHideApplication(wapp);
    }
}


static void
unhideHereCallback(WMenu *menu, WMenuEntry *entry)
{
    WApplication *wapp;
    WAppIcon *btn = (WAppIcon*)entry->clientdata;

    wapp = wApplicationOf(btn->icon->owner->main_window);

    wUnhideApplication(wapp, False, True);
}


WAppIcon*
mainIconCreate(WScreen *scr, int type)
{
    WAppIcon *btn;
    int x_pos;

    if (type == WM_CLIP) {
        if (scr->clip_icon)
            return scr->clip_icon;
        btn = wAppIconCreateForDock(scr, NULL, "Logo", "WMClip", TILE_CLIP);
        btn->icon->core->descriptor.handle_expose = clipIconExpose;
        btn->icon->core->descriptor.handle_enternotify = clipEnterNotify;
        btn->icon->core->descriptor.handle_leavenotify = clipLeaveNotify;
        /*x_pos = scr->scr_width - ICON_SIZE*2 - DOCK_EXTRA_SPACE;*/
        x_pos = 0;
    } else {
        btn = wAppIconCreateForDock(scr, NULL, "Logo", "WMDock", TILE_NORMAL);
        x_pos = scr->scr_width - ICON_SIZE - DOCK_EXTRA_SPACE;
    }

    btn->xindex = 0;
    btn->yindex = 0;

    btn->icon->core->descriptor.handle_mousedown = iconMouseDown;
    btn->icon->core->descriptor.parent_type = WCLASS_DOCK_ICON;
    btn->icon->core->descriptor.parent = btn;
    /*ChangeStackingLevel(btn->icon->core, WMDockLevel);*/
    XMapWindow(dpy, btn->icon->core->window);
    btn->x_pos = x_pos;
    btn->y_pos = 0;
    btn->docked = 1;
    if (type == WM_CLIP)
        scr->clip_icon = btn;

    return btn;
}


static void
switchWSCommand(WMenu *menu, WMenuEntry *entry)
{
    WAppIcon *btn, *icon = (WAppIcon*) entry->clientdata;
    WScreen *scr = icon->icon->core->screen_ptr;
    WDock *src, *dest;
    WMArray *selectedIcons;
    int x, y;

    if (entry->order == scr->current_workspace)
        return;
    src = icon->dock;
    dest = scr->workspaces[entry->order]->clip;

    selectedIcons = getSelected(src);

    if (WMGetArrayItemCount(selectedIcons)) {
        WMArrayIterator iter;

        WM_ITERATE_ARRAY(selectedIcons, btn, iter) {
            if (wDockFindFreeSlot(dest, &x, &y)) {
                moveIconBetweenDocks(src, dest, btn, x, y);
                XUnmapWindow(dpy, btn->icon->core->window);
            }
        }
    } else if (icon != scr->clip_icon) {
        if (wDockFindFreeSlot(dest, &x, &y)) {
            moveIconBetweenDocks(src, dest, icon, x, y);
            XUnmapWindow(dpy, icon->icon->core->window);
        }
    }
    WMFreeArray(selectedIcons);
}



static void
launchDockedApplication(WAppIcon *btn, Bool withSelection)
{
    WScreen *scr = btn->icon->core->screen_ptr;

    if (!btn->launching &&
        ((!withSelection && btn->command!=NULL) ||
         (withSelection && btn->paste_command!=NULL))) {
        if (!btn->forced_dock) {
            btn->relaunching = btn->running;
            btn->running = 1;
        }
        if (btn->wm_instance || btn->wm_class) {
            WWindowAttributes attr;
            memset(&attr, 0, sizeof(WWindowAttributes));
            wDefaultFillAttributes(scr, btn->wm_instance, btn->wm_class,
                                   &attr, NULL, True);

            if (!attr.no_appicon && !btn->buggy_app)
                btn->launching = 1;
            else
                btn->running = 0;
        }
        btn->drop_launch = 0;
        btn->paste_launch = withSelection;
        scr->last_dock = btn->dock;
        btn->pid = execCommand(btn, (withSelection ? btn->paste_command :
                                     btn->command), NULL);
        if (btn->pid>0) {
            if (btn->buggy_app) {
                /* give feedback that the app was launched */
                btn->launching = 1;
                dockIconPaint(btn);
                btn->launching = 0;
                WMAddTimerHandler(200, (WMCallback*)dockIconPaint, btn);
            } else {
                dockIconPaint(btn);
            }
        } else {
            wwarning(("could not launch application %s\n"), btn->command);
            btn->launching = 0;
            if (!btn->relaunching) {
                btn->running = 0;
            }
        }
    }
}



static void
updateWorkspaceMenu(WMenu *menu, WAppIcon *icon)
{
    WScreen *scr = menu->frame->screen_ptr;
    char title[MAX_WORKSPACENAME_WIDTH+1];
    int i;

    if (!menu || !icon)
        return;

    for (i=0; i<scr->workspace_count; i++) {
        if (i < menu->entry_no) {
            if (strcmp(menu->entries[i]->text,scr->workspaces[i]->name)!=0) {
                wfree(menu->entries[i]->text);
                strcpy(title, scr->workspaces[i]->name);
                menu->entries[i]->text = wstrdup(title);
                menu->flags.realized = 0;
            }
            menu->entries[i]->clientdata = (void*)icon;
        } else {
            strcpy(title, scr->workspaces[i]->name);

            wMenuAddCallback(menu, title, switchWSCommand, (void*)icon);

            menu->flags.realized = 0;
        }
        if (i == scr->current_workspace) {
            wMenuSetEnabled(menu, i, False);
        } else {
            wMenuSetEnabled(menu, i, True);
        }
    }

    if (!menu->flags.realized)
        wMenuRealize(menu);
}


static WMenu*
makeWorkspaceMenu(WScreen *scr)
{
    WMenu *menu;

    menu = wMenuCreate(scr, NULL, False);
    if (!menu)
        wwarning(("could not create workspace submenu for Clip menu"));

    wMenuAddCallback(menu, "", switchWSCommand, (void*)scr->clip_icon);

    menu->flags.realized = 0;
    wMenuRealize(menu);

    return menu;
}


static void
updateClipOptionsMenu(WMenu *menu, WDock *dock)
{
    WMenuEntry *entry;
    int index = 0;

    if (!menu || !dock)
        return;

    /* keep on top */
    entry = menu->entries[index];
    entry->flags.indicator_on = !dock->lowered;
    entry->clientdata = dock;

    /* collapsed */
    entry = menu->entries[++index];
    entry->flags.indicator_on = dock->collapsed;
    entry->clientdata = dock;

    /* auto-collapse */
    entry = menu->entries[++index];
    entry->flags.indicator_on = dock->auto_collapse;
    entry->clientdata = dock;

    /* auto-raise/lower */
    entry = menu->entries[++index];
    entry->flags.indicator_on = dock->auto_raise_lower;
    entry->clientdata = dock;
    wMenuSetEnabled(menu, index, dock->lowered);

    /* attract icons */
    entry = menu->entries[++index];
    entry->flags.indicator_on = dock->attract_icons;
    entry->clientdata = dock;

    menu->flags.realized = 0;
    wMenuRealize(menu);
}


static WMenu*
makeClipOptionsMenu(WScreen *scr)
{
    WMenu *menu;
    WMenuEntry *entry;

    menu = wMenuCreate(scr, NULL, False);
    if (!menu) {
        wwarning(("could not create options submenu for Clip menu"));
        return NULL;
    }

    entry = wMenuAddCallback(menu, ("Keep on Top"),
                             toggleLoweredCallback, NULL);
    entry->flags.indicator = 1;
    entry->flags.indicator_on = 1;
    entry->flags.indicator_type = MI_CHECK;

    entry = wMenuAddCallback(menu, ("Collapsed"),
                             toggleCollapsedCallback, NULL);
    entry->flags.indicator = 1;
    entry->flags.indicator_on = 1;
    entry->flags.indicator_type = MI_CHECK;

    entry = wMenuAddCallback(menu, ("Autocollapse"),
                             toggleAutoCollapseCallback, NULL);
    entry->flags.indicator = 1;
    entry->flags.indicator_on = 1;
    entry->flags.indicator_type = MI_CHECK;

    entry = wMenuAddCallback(menu, ("Autoraise"),
                             toggleAutoRaiseLowerCallback, NULL);
    entry->flags.indicator = 1;
    entry->flags.indicator_on = 1;
    entry->flags.indicator_type = MI_CHECK;

    entry = wMenuAddCallback(menu, ("Autoattract Icons"),
                             toggleAutoAttractCallback, NULL);
    entry->flags.indicator = 1;
    entry->flags.indicator_on = 1;
    entry->flags.indicator_type = MI_CHECK;

    menu->flags.realized = 0;
    wMenuRealize(menu);

    return menu;
}


static WMenu*
dockMenuCreate(WScreen *scr, int type)
{
    WMenu *menu;
    WMenuEntry *entry;

    if (type == WM_CLIP && scr->clip_menu)
        return scr->clip_menu;

    menu = wMenuCreate(scr, NULL, False);
    if (type != WM_CLIP) {
        entry = wMenuAddCallback(menu, ("Keep on Top"),
                                 toggleLoweredCallback, NULL);
        entry->flags.indicator = 1;
        entry->flags.indicator_on = 1;
        entry->flags.indicator_type = MI_CHECK;
    } else {
        entry = wMenuAddCallback(menu, ("Clip Options"), NULL, NULL);
        scr->clip_options = makeClipOptionsMenu(scr);
        if (scr->clip_options)
            wMenuEntrySetCascade(menu, entry, scr->clip_options);

        entry = wMenuAddCallback(menu, ("Rename Workspace"), renameCallback,
                                 NULL);
        wfree(entry->text);
        entry->text = ("Rename Workspace");

        entry = wMenuAddCallback(menu, ("Selected"), selectCallback, NULL);
        entry->flags.indicator = 1;
        entry->flags.indicator_on = 1;
        entry->flags.indicator_type = MI_CHECK;

        entry = wMenuAddCallback(menu, ("Select All Icons"),
                                 selectIconsCallback, NULL);
        wfree(entry->text);
        entry->text = ("Select All Icons");

        entry = wMenuAddCallback(menu, ("Keep Icon"), keepIconsCallback, NULL);
        wfree(entry->text);
        entry->text = ("Keep Icon");

        entry = wMenuAddCallback(menu, ("Move Icon To"), NULL, NULL);
        wfree(entry->text);
        entry->text = ("Move Icon To");
        scr->clip_submenu = makeWorkspaceMenu(scr);
        if (scr->clip_submenu)
            wMenuEntrySetCascade(menu, entry, scr->clip_submenu);

        entry = wMenuAddCallback(menu, ("Remove Icon"), removeIconsCallback,
                                 NULL);
        wfree(entry->text);
        entry->text = ("Remove Icon");

        wMenuAddCallback(menu, ("Attract Icons"), colectIconsCallback, NULL);
    }

    wMenuAddCallback(menu, ("Launch"), launchCallback, NULL);

    wMenuAddCallback(menu, ("Unhide Here"), unhideHereCallback, NULL);

    entry = wMenuAddCallback(menu, ("Hide"), hideCallback, NULL);
    wfree(entry->text);
    entry->text = ("Hide");

    wMenuAddCallback(menu, ("Settings..."), settingsCallback, NULL);

    wMenuAddCallback(menu, ("Kill"), killCallback, NULL);

    if (type == WM_CLIP)
        scr->clip_menu = menu;

    return menu;
}


WDock*
wDockCreate(WScreen *scr, int type)
{
    WDock *dock;
    WAppIcon *btn;
    int icon_count;

    dock = wmalloc(sizeof(WDock));
    memset(dock, 0, sizeof(WDock));

    if (type == WM_CLIP)
        icon_count = CLIP_MAX_ICONS;
    else
        icon_count = scr->scr_height/wPreferences.icon_size;

    dock->icon_array = wmalloc(sizeof(WAppIcon*)*icon_count);
    memset(dock->icon_array, 0, sizeof(WAppIcon*)*icon_count);

    dock->max_icons = icon_count;

    btn = mainIconCreate(scr, type);

    btn->dock = dock;

    dock->x_pos = btn->x_pos;
    dock->y_pos = btn->y_pos;
    dock->screen_ptr = scr;
    dock->type = type;
    dock->icon_count = 1;
    dock->on_right_side = 1;
    dock->collapsed = 0;
    dock->auto_collapse = 0;
    dock->auto_collapse_magic = NULL;
    dock->auto_raise_lower = 0;
    dock->auto_lower_magic = NULL;
    dock->auto_raise_magic = NULL;
    dock->attract_icons = 0;
    dock->lowered = 1;
    dock->icon_array[0] = btn;
    wRaiseFrame(btn->icon->core);
    XMoveWindow(dpy, btn->icon->core->window, btn->x_pos, btn->y_pos);

    /* create dock menu */
    dock->menu = dockMenuCreate(scr, type);

    return dock;
}


void
wDockDestroy(WDock *dock)
{
    int i;
    WAppIcon *aicon;

    for (i=(dock->type == WM_CLIP) ? 1 : 0; i<dock->max_icons; i++) {
        aicon = dock->icon_array[i];
        if (aicon) {
            int keepit = aicon->running && wApplicationOf(aicon->main_window);
            wDockDetach(dock, aicon);
            if (keepit) {
                /* XXX: can: aicon->icon == NULL ? */
                PlaceIcon(dock->screen_ptr, &aicon->x_pos, &aicon->y_pos, wGetHeadForWindow(aicon->icon->owner));
                XMoveWindow(dpy, aicon->icon->core->window,
                            aicon->x_pos, aicon->y_pos);
                if (!dock->mapped || dock->collapsed)
                    XMapWindow(dpy, aicon->icon->core->window);
            }
        }
    }
    if (wPreferences.auto_arrange_icons)
        wArrangeIcons(dock->screen_ptr, True);
    wfree(dock->icon_array);
    if (dock->menu && dock->type!=WM_CLIP)
        wMenuDestroy(dock->menu, True);
    if (dock->screen_ptr->last_dock == dock)
        dock->screen_ptr->last_dock = NULL;
    wfree(dock);
}


void
wClipIconPaint(WAppIcon *aicon)
{
    WScreen *scr = aicon->icon->core->screen_ptr;
    WWorkspace *workspace = scr->workspaces[scr->current_workspace];
    WMColor *color;
    Window win = aicon->icon->core->window;
    int length, nlength;
    char *ws_name, ws_number[10];
    int ty, tx;

    wIconPaint(aicon->icon);

    length = strlen(workspace->name);
    ws_name = wmalloc(length + 1);
    snprintf(ws_name, length+1, "%s", workspace->name);
    snprintf(ws_number, sizeof(ws_number), "%i", scr->current_workspace + 1);
    nlength = strlen(ws_number);

    if (!workspace->clip->collapsed)
        color = scr->clip_title_color[CLIP_NORMAL];
    else
        color = scr->clip_title_color[CLIP_COLLAPSED];

    ty = ICON_SIZE - WMFontHeight(scr->clip_title_font) - 3;

    tx = CLIP_BUTTON_SIZE*ICON_SIZE/64;

    WMDrawString(scr->wmscreen, win, color, scr->clip_title_font, tx,
                 ty, ws_name, length);
    /*WMDrawString(scr->wmscreen, win, color, scr->clip_title_font, 4,
     2, ws_name, length);*/

    tx = (ICON_SIZE/2 - WMWidthOfString(scr->clip_title_font, ws_number,
                                        nlength))/2;

    WMDrawString(scr->wmscreen, win, color, scr->clip_title_font, tx,
                 2, ws_number, nlength);

    wfree(ws_name);

    if (aicon->launching) {
        XFillRectangle(dpy, aicon->icon->core->window, scr->stipple_gc,
                       0, 0, wPreferences.icon_size, wPreferences.icon_size);
    }
    paintClipButtons(aicon, aicon->dock->lclip_button_pushed,
                     aicon->dock->rclip_button_pushed);
}


static void
clipIconExpose(WObjDescriptor *desc, XEvent *event)
{
    wClipIconPaint(desc->parent);
}


static void
dockIconPaint(WAppIcon *btn)
{
    if (btn == btn->icon->core->screen_ptr->clip_icon)
        wClipIconPaint(btn);
    else
        wAppIconPaint(btn);
}


static NSDictionary *
make_icon_state(WAppIcon *btn)
{
    NSString *command, *autolaunch, *lock;
    NSString *name, *forced, *buggy;
    NSString *omnipresent = nil, *host = nil;
    NSString *position;
    NSMutableDictionary *node = AUTORELEASE([[NSMutableDictionary alloc] init]);

    char *tmp;

    if (btn) {
        if (!btn->command)
	    command = [NSString stringWithCString: "-"];
        else
	    command = [NSString stringWithCString: btn->command];

        autolaunch = btn->auto_launch ? dYes : dNo;

        lock = btn->lock ? dYes: dNo;

	/* FIXME: not sure here */
        tmp = EscapeWM_CLASS(btn->wm_instance, btn->wm_class);

	name = [NSString stringWithCString: tmp];

	/* FIXME: Not sure 
        wfree(tmp);
	*/

        forced = btn->forced_dock ? dYes: dNo;

        buggy = btn->buggy_app ? dYes: dNo;

        if (btn == btn->icon->core->screen_ptr->clip_icon)
	    position = [NSString stringWithFormat: @"%i,%i", btn->x_pos, btn->y_pos];
        else
	    position = [NSString stringWithFormat: @"%hi,%hi", btn->xindex, btn->yindex];

	[node setObject: command forKey: dCommand];
	[node setObject: name forKey: dName];
	[node setObject: autolaunch forKey: dAutoLaunch];
	[node setObject: lock forKey: dLock];
	[node setObject: forced forKey: dForced];
	[node setObject: buggy forKey: dBuggyApplication];
	[node setObject: position forKey: dPosition];

        omnipresent = btn->omnipresent ? dYes : dNo;
        if (btn->dock != btn->icon->core->screen_ptr->dock &&
            (btn->xindex != 0 || btn->yindex != 0))
	    [node setObject: omnipresent forKey: dOmnipresent];

#ifdef XDND /* was OFFIX */
        if (btn->dnd_command) {
	    command = [NSString stringWithCString: btn->dnd_command];
	    [node setObject: command forKey: dDropCommand];
        }
#endif /* XDND */

        if (btn->paste_command) {
	    command = [NSString stringWithCString: btn->paste_command];
	    [node setObject: command forKey: dPasteCommand];
        }

        if (btn->client_machine && btn->remote_start) {
	    host = [NSString stringWithCString: btn->client_machine];
	    [node setObject: host forKey: dHost];
        }
    }

    return node;
}


static NSDictionary *
dockSaveState(WDock *dock)
{
    int i;
    NSMutableArray *list = AUTORELEASE([[NSMutableArray alloc] init]);
    NSDictionary *icon_info = nil;
    NSMutableDictionary *dock_state = nil;
    NSString *key = nil;
    id value = nil;

    for (i=(dock->type==WM_DOCK ? 0 : 1); i<dock->max_icons; i++) {
        WAppIcon *btn = dock->icon_array[i];

        if (!btn || btn->attracted)
            continue;

        if ((icon_info = make_icon_state(dock->icon_array[i]))) {
	  [list addObject: icon_info];
        }
    }

    dock_state = [NSMutableDictionary dictionaryWithObject: list forKey: dApplications];

    if (dock->type == WM_DOCK) {
	key = [NSString stringWithFormat: @"Applications%i", dock->screen_ptr->scr_height];
	[dock_state setObject: list forKey: key];

	value = [NSString stringWithFormat: @"%i,%i", (dock->on_right_side ? -ICON_SIZE : 0), dock->y_pos];
	[dock_state setObject: value forKey: dPosition];
    }

    value = (dock->lowered ? dYes : dNo);
    [dock_state setObject: value forKey: dLowered];

    if (dock->type == WM_CLIP) {
        value = (dock->collapsed ? dYes : dNo);
	[dock_state setObject: value forKey: dCollapsed];

        value = (dock->auto_collapse ? dYes : dNo);
	[dock_state setObject: value forKey: dAutoCollapse];

        value = (dock->auto_raise_lower ? dYes : dNo);
	[dock_state setObject: value forKey: dAutoRaiseLower];

        value = (dock->attract_icons ? dYes : dNo);
	[dock_state setObject: value forKey: dAutoAttractIcons];
    }

    return dock_state;
}


void
wDockSaveState(WScreen *scr, NSDictionary *old_state)
{
    WMDefaults *defaults = [WMDefaults sharedDefaults];
    NSMutableDictionary *dock_state = nil;
    NSArray *keys = nil;

    dock_state = [NSMutableDictionary dictionaryWithDictionary: dockSaveState(scr->dock)];

    /*
     * Copy saved states of docks with different sizes.
     */
    if (old_state) {
        int i;
	id tmp;

	keys = [old_state allKeys];
        for (i = 0; i < [keys count]; i++) {
	    tmp = [keys objectAtIndex: i];

	    if ([tmp hasPrefix: @"Applications"] &&
			    [old_state objectForKey: tmp]) {
	        [dock_state setObject: [old_state objectForKey: tmp]
			       forKey: tmp];
	    }
	}
    }

    [defaults setDock: dock_state forScreen: scr->screen];
}


void
wClipSaveState(WScreen *scr)
{
    NSDictionary *clip_state;
    WMDefaults *defaults = [WMDefaults sharedDefaults];

    clip_state = make_icon_state(scr->clip_icon);

    [defaults setClip: clip_state forScreen: scr->screen];
}

NSDictionary *
wClipSaveWorkspaceState(WScreen *scr, int workspace)
{
    return dockSaveState(scr->workspaces[workspace]->clip);
}

static WAppIcon*
restore_icon_state(WScreen *scr, NSDictionary *info, int type, int index)
{
    WAppIcon *aicon;
    NSString *cmd;
    id value;
    BOOL boolValue;
    char *tmp;

    cmd = [info objectForKey: dCommand];
    if (cmd == nil)
      return NULL;

    /* parse window name */
    value = [info objectForKey: dName];
    if (value == nil)
        return NULL;

    {
        char *wclass, *winstance;
        char *command;

        ParseWindowName(value, &winstance, &wclass, "dock");

        if (!winstance && !wclass) {
            return NULL;
        }

        /* get commands */

	command = wstrdup((char*)[cmd cString]);

        if (!command || strcmp(command, "-")==0) {
            if (command)
                wfree(command);
            if (wclass)
                wfree(wclass);
            if (winstance)
                wfree(winstance);

            return NULL;
        }

        aicon = wAppIconCreateForDock(scr, command, winstance, wclass,
                                      TILE_NORMAL);
        if (wclass)
            wfree(wclass);
        if (winstance)
            wfree(winstance);
        if (command)
            wfree(command);
    }

    aicon->icon->core->descriptor.handle_mousedown = iconMouseDown;
    if (type == WM_CLIP) {
        aicon->icon->core->descriptor.handle_enternotify = clipEnterNotify;
        aicon->icon->core->descriptor.handle_leavenotify = clipLeaveNotify;
    }
    aicon->icon->core->descriptor.parent_type = WCLASS_DOCK_ICON;
    aicon->icon->core->descriptor.parent = aicon;


#ifdef XDND /* was OFFIX */
    cmd = [info objectForKey: dDropCommand];
    if (cmd)
        aicon->dnd_command = wstrdup((char*)[cmd cString]);
#endif

    cmd = [info objectForKey: dPasteCommand];
    if (cmd)
        aicon->paste_command = wstrdup((char*)[cmd cString]);

    /* check auto launch */
    value = [info objectForKey: dAutoLaunch];
    if (value) {
      boolValue = [value isEqualToString: dYes] ? YES : NO;
      aicon->auto_launch = boolValue;
    }

    /* check lock */
    value = [info objectForKey: dLock];
    if (value) {
      boolValue = [value isEqualToString: dYes] ? YES : NO;
      aicon->lock = boolValue;
    }

    /* check if it wasn't normally docked */
    value = [info objectForKey: dForced];
    if (value) {
      boolValue = [value isEqualToString: dYes] ? YES : NO;
      aicon->forced_dock = boolValue;
    }

    /* check if we can rely on the stuff in the app */
    value = [info objectForKey: dBuggyApplication];
    if (value) {
      boolValue = [value isEqualToString: dYes] ? YES : NO;
      aicon->buggy_app = boolValue;
    }

    /* get position in the dock */
    value = [info objectForKey: dPosition];
    if (value) {
      tmp = (char*)[value cString];
      if (sscanf(tmp, "%hi,%hi", &aicon->xindex, &aicon->yindex) != 2)
	NSLog(@"Warning: bad value in docked iconstate info %@", value);

      /* check position sanity */
      /* incomplete section! */
      if (type ==WM_DOCK) {
	aicon->xindex = 0;
	if (aicon->yindex < 0) {
	  NSLog(@"Warning: bad value in docked icon position %i,%i",
			  aicon->xindex, aicon->yindex);
	}
      }
    }
    else
    {
      aicon->yindex = index;
      aicon->xindex = 0;
    }

    /* check if icon is omnipresent */
    value = [info objectForKey: dOmnipresent];
    if (value) {
      boolValue = [value isEqualToString: dYes] ? YES : NO;
      aicon->omnipresent = boolValue;
    }

    aicon->running = 0;
    aicon->docked = 1;

    return aicon;
}


#define COMPLAIN(key) wwarning(("bad value in dock state info:%s"), key)


WAppIcon*
wClipRestoreState(WScreen *scr, NSDictionary *clip_state)
{
    WAppIcon *icon;
    id value;
    char *tmp;

    icon = mainIconCreate(scr, WM_CLIP);

    if (!clip_state)
        return icon;
    else
	RETAIN(clip_state);

    /* restore position */

    value = [clip_state objectForKey: dPosition];

    if (value) {
	WMRect rect;
	int flags;

	tmp = (char*)[value cString];
	if (sscanf(tmp, "%i,%i", &icon->x_pos, &icon->y_pos) != 2)
	  NSLog(@"Warning: bad value in dock state info: %@", value);
	rect.pos.x = icon->x_pos;
	rect.pos.y = icon->y_pos;
	rect.size.width = rect.size.height = ICON_SIZE;

        wGetRectPlacementInfo(scr, rect, &flags);
        if (flags & (XFLAG_DEAD | XFLAG_PARTIAL)) {
          wScreenKeepInside(scr, &icon->x_pos, &icon->y_pos,
                                  ICON_SIZE, ICON_SIZE);
        }
    }

#ifdef XDND /* was OFFIX */
    value = [clip_state objectForKey: dDropCommand];
    if (value)
        icon->dnd_command = wstrdup((char*)[value cString]);
#endif

    value = [clip_state objectForKey: dPasteCommand];
    if (value)
        icon->paste_command = wstrdup((char*)[value cString]);

    RELEASE(clip_state);

    return icon;
}


WDock*
wDockRestoreState(WScreen *scr, NSDictionary *dock_state, int type)
{
    WDock *dock;
    int count, i;
    id value;
    NSArray *apps;
    WAppIcon *aicon, *old_top;

    dock = wDockCreate(scr, type);

    if (!dock_state)
        return dock;

    RETAIN(dock_state);

    /* restore position */

    value = [dock_state objectForKey: dPosition];

    if (value) {
      WMRect rect;
      int flags;
      char *tmp;

      tmp = (char*)[value cString];
      if (sscanf(tmp, "%i,%i", &dock->x_pos, &dock->y_pos) != 2)
	NSLog(@"Warning: bad value for dock info %@", value);

      /* check position sanity */
      rect.pos.x = dock->x_pos;
      rect.pos.y = dock->y_pos;
      rect.size.width = rect.size.height = ICON_SIZE;

      wGetRectPlacementInfo(scr, rect, &flags);
      if (flags & (XFLAG_DEAD | XFLAG_PARTIAL)) {
	int x = dock->x_pos;
	wScreenKeepInside(scr, &x, &dock->y_pos, ICON_SIZE, ICON_SIZE);
      }

      /* Is this neede any more ? */
      if (type == WM_CLIP) {
	if (dock->x_pos < 0) {
          dock->x_pos = 0;
	} else if (dock->x_pos > scr->scr_width-ICON_SIZE) {
	  dock->x_pos = scr->scr_width-ICON_SIZE;
	}
      } else {
	if (dock->x_pos >= 0) {
	  dock->x_pos = DOCK_EXTRA_SPACE;
	  dock->on_right_side = 0;
	} else {
	  dock->x_pos = scr->scr_width - DOCK_EXTRA_SPACE - ICON_SIZE;
	  dock->on_right_side = 1;
	}
      }
    }

    /* restore lowered/raised state */

    dock->lowered = 0;

    value = [dock_state objectForKey: dLowered];

    if (value) {
      if ([value isEqualToString: dYes] == YES) {
	dock->lowered = 1;
      }
    }

    /* restore collapsed state */

    dock->collapsed = 0;

    value = [dock_state objectForKey: dCollapsed];

    if (value) {
      if ([value isEqualToString: dYes] == YES) {
	dock->collapsed = 1;
      }
    }

    /* restore auto-collapsed state */

    value = [dock_state objectForKey: dAutoCollapse];

    if (value) {
      if ([value isEqualToString: dYes] == YES) {
	dock->auto_collapse = 1;
	dock->collapsed = 1;
      }
    }

    /* restore auto-raise/lower state */

    value = [dock_state objectForKey: dAutoRaiseLower];

    if (value) {
      if ([value isEqualToString: dYes] == YES) {
	dock->auto_raise_lower= 1;
      }
    }

    /* restore attract icons state */

    dock->attract_icons = 0;

    value = [dock_state objectForKey: dAutoAttractIcons];

    if (value) {
      if ([value isEqualToString: dYes] == YES) {
	dock->attract_icons = 1;
      }
    }

    /* application list */

    {
	NSString *tmp;

        /*
         * When saving, it saves the dock state in
         * Applications and Applicationsnnn
         *
         * When loading, it will first try Applicationsnnn.
         * If it does not exist, use Applications as default.
         */

	tmp = [NSString stringWithFormat: @"Applications%i", scr->scr_height];
	apps = [dock_state objectForKey: tmp];

        if (!apps) {
	    apps = [dock_state objectForKey: dApplications];
        }
    }

    if ((apps == nil) || ([apps count] == 0)) {
	RELEASE(dock_state);
	return dock;
    }

    count = [apps count];

    old_top = dock->icon_array[0];

    /* dock->icon_count is set to 1 when dock is created.
     * Since Clip is already restored, we want to keep it so for clip,
     * but for dock we may change the default top tile, so we set it to 0.
     */
    if (type == WM_DOCK)
        dock->icon_count = 0;

    for (i=0; i<count; i++) {
        if (dock->icon_count >= dock->max_icons) {
            NSLog(@"Warning: there are too many icons stored in dock. Ignoring what doesn't fit");
            break;
        }

	value = [apps objectAtIndex: i];
        aicon = restore_icon_state(scr, value, type, dock->icon_count);

        dock->icon_array[dock->icon_count] = aicon;

        if (aicon) {
            aicon->dock = dock;
            aicon->x_pos = dock->x_pos + (aicon->xindex*ICON_SIZE);
            aicon->y_pos = dock->y_pos + (aicon->yindex*ICON_SIZE);

            if (dock->lowered)
                ChangeStackingLevel(aicon->icon->core, WMNormalLevel);
            else
                ChangeStackingLevel(aicon->icon->core, WMDockLevel);

            wCoreConfigure(aicon->icon->core, aicon->x_pos, aicon->y_pos,
                           0, 0);

            if (!dock->collapsed)
                XMapWindow(dpy, aicon->icon->core->window);
            wRaiseFrame(aicon->icon->core);

            dock->icon_count++;
        } else if (dock->icon_count==0 && type==WM_DOCK)
            dock->icon_count++;
    }

    /* if the first icon is not defined, use the default */
    if (dock->icon_array[0]==NULL) {
        /* update default icon */
        old_top->x_pos = dock->x_pos;
        old_top->y_pos = dock->y_pos;
        if (dock->lowered)
            ChangeStackingLevel(old_top->icon->core, WMNormalLevel);
        else
            ChangeStackingLevel(old_top->icon->core, WMDockLevel);
        dock->icon_array[0] = old_top;
        XMoveWindow(dpy, old_top->icon->core->window, dock->x_pos, dock->y_pos);
        /* we don't need to increment dock->icon_count here because it was
         * incremented in the loop above.
         */
    } else if (old_top!=dock->icon_array[0]) {
        if (old_top == scr->clip_icon)
            scr->clip_icon = dock->icon_array[0];
        wAppIconDestroy(old_top);
    }

    if (dock_state)
        RELEASE(dock_state); // it is retained above

    return dock;
}



void
wDockLaunchWithState(WDock *dock, WAppIcon *btn, WSavedState *state)
{
    if (btn && btn->command && !btn->running && !btn->launching) {

        btn->drop_launch = 0;
        btn->paste_launch = 0;

        btn->pid = execCommand(btn, btn->command, state);

        if (btn->pid>0) {
            if (!btn->forced_dock && !btn->buggy_app) {
                btn->launching = 1;
                dockIconPaint(btn);
            }
        }
    } else {
        wfree(state);
    }
}


void
wDockDoAutoLaunch(WDock *dock, int workspace)
{
    WAppIcon *btn;
    WSavedState *state;
    int i;

    for (i = 0; i < dock->max_icons; i++) {
        btn = dock->icon_array[i];
        if (!btn || !btn->auto_launch)
            continue;

        state = wmalloc(sizeof(WSavedState));
        memset(state, 0, sizeof(WSavedState));
        state->workspace = workspace;
        /* TODO: this is klugy and is very difficult to understand
         * what's going on. Try to clean up */
        wDockLaunchWithState(dock, btn, state);
    }
}


#ifdef XDND /* was OFFIX */
static WDock*
findDock(WScreen *scr, XEvent *event, int *icon_pos)
{
    WDock *dock;
    int i;

    *icon_pos = -1;
    if ((dock = scr->dock)!=NULL) {
        for (i=0; i<dock->max_icons; i++) {
            if (dock->icon_array[i]
                && dock->icon_array[i]->icon->core->window==event->xclient.window) {
                *icon_pos = i;
                break;
            }
        }
    }
    if (*icon_pos<0 && (dock = scr->workspaces[scr->current_workspace]->clip)!=NULL) {
        for (i=0; i<dock->max_icons; i++) {
            if (dock->icon_array[i]
                && dock->icon_array[i]->icon->core->window==event->xclient.window) {
                *icon_pos = i;
                break;
            }
        }
    }
    if(*icon_pos>=0)
        return dock;
    return NULL;
}


int
wDockReceiveDNDDrop(WScreen *scr, XEvent *event)
{
    WDock *dock;
    WAppIcon *btn;
    int icon_pos;

    dock = findDock(scr, event, &icon_pos);
    if (!dock)
        return False;

    /*
     * Return True if the drop was on an application icon window.
     * In this case, let the ClientMessage handler redirect the
     * message to the app.
     */
    if (dock->icon_array[icon_pos]->icon->icon_win!=None)
        return True;

    if (dock->icon_array[icon_pos]->dnd_command!=NULL) {
        scr->flags.dnd_data_convertion_status = 0;

        btn = dock->icon_array[icon_pos];

        if (!btn->forced_dock) {
            btn->relaunching = btn->running;
            btn->running = 1;
        }
        if (btn->wm_instance || btn->wm_class) {
            WWindowAttributes attr;
            memset(&attr, 0, sizeof(WWindowAttributes));
            wDefaultFillAttributes(btn->icon->core->screen_ptr,
                                   btn->wm_instance,
                                   btn->wm_class, &attr, NULL, True);

            if (!attr.no_appicon)
                btn->launching = 1;
            else
                btn->running = 0;
        }

        btn->paste_launch = 0;
        btn->drop_launch = 1;
        scr->last_dock = dock;
        btn->pid = execCommand(btn, btn->dnd_command, NULL);
        if (btn->pid>0) {
            dockIconPaint(btn);
        } else {
            btn->launching = 0;
            if (!btn->relaunching) {
                btn->running = 0;
            }
        }
    }
    return False;
}
#endif /* XDND */



Bool
wDockAttachIcon(WDock *dock, WAppIcon *icon, int x, int y)
{
    WWindow *wwin;
    int index;

    wwin = icon->icon->owner;
    if (icon->command==NULL) {
        char *command = NULL;

        icon->editing = 0;

        command = GetCommandForWindow(wwin->client_win);
        if (command) {
            icon->command = command;
        } else {
            /* icon->forced_dock = 1;*/
            if (dock->type!=WM_CLIP || !icon->attracted) {
                icon->editing = 1;
		NSString *result = [[WMDialogController sharedController] inputDialogWithTitle: @"Dock Icon"
			message: @"Type the command used to launch the application"
			text: nil]; // command is NULL here.
		if (result)
		{
		    command = wstrdup((char*)[result cString]);
                    if (command && (command[0]==0 ||
                                    (command[0]=='-' && command[1]==0))) {
                        wfree(command);
                        command = NULL;
                    }
                    icon->command = command;
                    icon->editing = 0;
                } else {
                    icon->editing = 0;
                    if (command)
                        wfree(command);
                    /* If the target is the dock, reject the icon. If
                     * the target is the clip, make it an attracted icon
                     */
                    if (dock->type==WM_CLIP) {
                        icon->attracted = 1;
                        if (!icon->icon->shadowed) {
                            icon->icon->shadowed = 1;
                            icon->icon->force_paint = 1;
                        }
                    } else {
                        return False;
                    }
                }
            }
        }
    } else {
        icon->editing = 0;
    }

    for (index=1; index<dock->max_icons; index++)
        if (dock->icon_array[index] == NULL)
            break;
    /* if (index == dock->max_icons)
     return; */

    assert(index < dock->max_icons);

    dock->icon_array[index] = icon;
    icon->yindex = y;
    icon->xindex = x;

    icon->omnipresent = 0;

    icon->x_pos = dock->x_pos + x*ICON_SIZE;
    icon->y_pos = dock->y_pos + y*ICON_SIZE;

    dock->icon_count++;

    icon->running = 1;
    icon->launching = 0;
    icon->docked = 1;
    icon->dock = dock;
    icon->icon->core->descriptor.handle_mousedown = iconMouseDown;
    if (dock->type == WM_CLIP) {
        icon->icon->core->descriptor.handle_enternotify = clipEnterNotify;
        icon->icon->core->descriptor.handle_leavenotify = clipLeaveNotify;
    }
    icon->icon->core->descriptor.parent_type = WCLASS_DOCK_ICON;
    icon->icon->core->descriptor.parent = icon;

    MoveInStackListUnder(dock->icon_array[index-1]->icon->core,
                         icon->icon->core);
    wAppIconMove(icon, icon->x_pos, icon->y_pos);
    wAppIconPaint(icon);

    if (wPreferences.auto_arrange_icons)
        wArrangeIcons(dock->screen_ptr, True);

#ifdef XDND /* was OFFIX */
    if (icon->command && !icon->dnd_command) {
        int len = strlen(icon->command)+8;
        icon->dnd_command = wmalloc(len);
        snprintf(icon->dnd_command, len, "%s %%d", icon->command);
    }
#endif

    if (icon->command && !icon->paste_command) {
        int len = strlen(icon->command)+8;
        icon->paste_command = wmalloc(len);
        snprintf(icon->paste_command, len, "%s %%s", icon->command);
    }

    return True;
}


void
reattachIcon(WDock *dock, WAppIcon *icon, int x, int y)
{
    int index;

    for(index=1; index<dock->max_icons; index++) {
        if(dock->icon_array[index] == icon)
            break;
    }
    assert(index < dock->max_icons);

    icon->yindex = y;
    icon->xindex = x;

    icon->x_pos = dock->x_pos + x*ICON_SIZE;
    icon->y_pos = dock->y_pos + y*ICON_SIZE;
}


Bool
moveIconBetweenDocks(WDock *src, WDock *dest, WAppIcon *icon, int x, int y)
{
    WWindow *wwin;
    char *command;
    int index;

    if (src == dest)
        return True;     /* No move needed, we're already there */

    if (dest == NULL)
        return False;

    wwin = icon->icon->owner;

    /*
     * For the moment we can't do this if we move icons in Clip from one
     * workspace to other, because if we move two or more icons without
     * command, the dialog box will not be able to tell us to which of the
     * moved icons it applies. -Dan
     */
    if ((dest->type==WM_DOCK /*|| dest->keep_attracted*/) && icon->command==NULL) {
        command = GetCommandForWindow(wwin->client_win);
        if (command) {
            icon->command = command;
        } else {
            icon->editing = 1;
            /* icon->forced_dock = 1;*/
	    NSString *result = [[WMDialogController sharedController] inputDialogWithTitle: @"Dock Icon"
		    message: @"Type the command used to launch the application"
		    text: nil]; // command is NULL here.
	    if (result)
	    {
		command = wstrdup((char*)[result cString]);
                if (command && (command[0]==0 ||
                                (command[0]=='-' && command[1]==0))) {
                    wfree(command);
                    command = NULL;
                }
                icon->command = command;
            } else {
                icon->editing = 0;
                if (command)
                    wfree(command);
                return False;
            }
            icon->editing = 0;
        }
    }

    if (dest->type == WM_DOCK)
        wClipMakeIconOmnipresent(icon, False);

    for(index=1; index<src->max_icons; index++) {
        if(src->icon_array[index] == icon)
            break;
    }
    assert(index < src->max_icons);

    src->icon_array[index] = NULL;
    src->icon_count--;

    for(index=1; index<dest->max_icons; index++) {
        if(dest->icon_array[index] == NULL)
            break;
    }
    /* if (index == dest->max_icons)
     return; */

    assert(index < dest->max_icons);

    dest->icon_array[index] = icon;
    icon->dock = dest;

    /* deselect the icon */
    if (icon->icon->selected)
        wIconSelect(icon->icon);

    if (dest->type == WM_DOCK) {
        icon->icon->core->descriptor.handle_enternotify = NULL;
        icon->icon->core->descriptor.handle_leavenotify = NULL;
    } else {
        icon->icon->core->descriptor.handle_enternotify = clipEnterNotify;
        icon->icon->core->descriptor.handle_leavenotify = clipLeaveNotify;
    }

    /* set it to be kept when moving to dock.
     * Unless the icon does not have a command set
     */
    if (icon->command && dest->type==WM_DOCK) {
        icon->attracted = 0;
        if (icon->icon->shadowed) {
            icon->icon->shadowed = 0;
            icon->icon->force_paint = 1;
        }
    }

    if (src->auto_collapse || src->auto_raise_lower)
        clipLeave(src);

    icon->yindex = y;
    icon->xindex = x;

    icon->x_pos = dest->x_pos + x*ICON_SIZE;
    icon->y_pos = dest->y_pos + y*ICON_SIZE;

    dest->icon_count++;

    MoveInStackListUnder(dest->icon_array[index-1]->icon->core,
                         icon->icon->core);
    wAppIconPaint(icon);

    return True;
}


void
wDockDetach(WDock *dock, WAppIcon *icon)
{
    int index;

    /* make the settings panel be closed */
#if 0
    if (icon->panel) {
        DestroyDockAppSettingsPanel(icon->panel);
    }
#endif
    WMDockedAppPanel *panel = [WMDockedAppPanel sharedPanel];
    if (icon == [panel appIcon])
    {
      [panel setAppIcon: NULL];
      [panel close];
    }

    /* This must be called before icon->dock is set to NULL.
     * Don't move it. -Dan
     */
    wClipMakeIconOmnipresent(icon, False);

    icon->docked = 0;
    icon->dock = NULL;
    icon->attracted = 0;
    icon->auto_launch = 0;
    if (icon->icon->shadowed) {
        icon->icon->shadowed = 0;
        icon->icon->force_paint = 1;
    }

    /* deselect the icon */
    if (icon->icon->selected)
        wIconSelect(icon->icon);

    if (icon->command) {
        wfree(icon->command);
        icon->command = NULL;
    }
#ifdef XDND /* was OFFIX */
    if (icon->dnd_command) {
        wfree(icon->dnd_command);
        icon->dnd_command = NULL;
    }
#endif
    if (icon->paste_command) {
        wfree(icon->paste_command);
        icon->paste_command = NULL;
    }

    for (index=1; index<dock->max_icons; index++)
        if (dock->icon_array[index] == icon)
            break;
    assert(index < dock->max_icons);
    dock->icon_array[index] = NULL;
    icon->yindex = -1;
    icon->xindex = -1;

    dock->icon_count--;

    /* if the dock is not attached to an application or
     * the the application did not set the approriate hints yet,
     * destroy the icon */
    if (!icon->running || !wApplicationOf(icon->main_window))
        wAppIconDestroy(icon);
    else {
        icon->icon->core->descriptor.handle_mousedown = appIconMouseDown;
        icon->icon->core->descriptor.handle_enternotify = NULL;
        icon->icon->core->descriptor.handle_leavenotify = NULL;
        icon->icon->core->descriptor.parent_type = WCLASS_APPICON;
        icon->icon->core->descriptor.parent = icon;

        ChangeStackingLevel(icon->icon->core, NORMAL_ICON_LEVEL);

        wAppIconPaint(icon);
        if (wPreferences.auto_arrange_icons) {
            wArrangeIcons(dock->screen_ptr, True);
        }
    }
    if (dock->auto_collapse || dock->auto_raise_lower)
        clipLeave(dock);
}


/*
 * returns the closest Dock slot index for the passed
 * coordinates.
 *
 * Returns False if icon can't be docked.
 *
 * Note: this function should NEVER alter ret_x or ret_y, unless it will
 * return True. -Dan
 */
Bool
wDockSnapIcon(WDock *dock, WAppIcon *icon, int req_x, int req_y,
              int *ret_x, int *ret_y, int redocking)
{
    WScreen *scr = dock->screen_ptr;
    int dx, dy;
    int ex_x, ex_y;
    int i, offset = ICON_SIZE/2;
    WAppIcon *aicon = NULL;
    WAppIcon *nicon = NULL;
    int max_y_icons, max_x_icons;

    /* TODO: XINERAMA, for these */
    max_x_icons = scr->scr_width/ICON_SIZE;
    max_y_icons = scr->scr_height/ICON_SIZE-1;

    if (wPreferences.flags.noupdates)
        return False;

    dx = dock->x_pos;
    dy = dock->y_pos;

    /* if the dock is full */
    if (!redocking &&
        (dock->icon_count >= dock->max_icons)) {
        return False;
    }

    /* exact position */
    if (req_y < dy)
        ex_y = (req_y - offset - dy)/ICON_SIZE;
    else
        ex_y = (req_y + offset - dy)/ICON_SIZE;

    if (req_x < dx)
        ex_x = (req_x - offset - dx)/ICON_SIZE;
    else
        ex_x = (req_x + offset - dx)/ICON_SIZE;

    /* check if the icon is outside the screen boundaries */
    {
        WMRect rect;
        int flags;

        rect.pos.x = dx + ex_x*ICON_SIZE;
        rect.pos.y = dy + ex_y*ICON_SIZE;
        rect.size.width = rect.size.height = ICON_SIZE;

        wGetRectPlacementInfo(scr, rect, &flags);
        if (flags & (XFLAG_DEAD | XFLAG_PARTIAL))
            return False;
    }

    if (dock->type == WM_DOCK) {
        if (icon->dock != dock && ex_x != 0)
            return False;

        aicon = NULL;
        for (i=0; i<dock->max_icons; i++) {
            nicon = dock->icon_array[i];
            if (nicon && nicon->yindex == ex_y) {
                aicon = nicon;
                break;
            }
        }

        if (redocking) {
            int sig, done, closest;

            /* Possible cases when redocking:
             *
             * icon dragged out of range of any slot -> false
             * icon dragged to range of free slot
             * icon dragged to range of same slot
             * icon dragged to range of different icon
             */
            if (abs(ex_x) > DOCK_DETTACH_THRESHOLD)
                return False;

            if (ex_y>=0 && ex_y<=max_y_icons && (aicon==icon || !aicon)) {
                *ret_x = 0;
                *ret_y = ex_y;
                return True;
            }

            /* start looking at the upper slot or lower? */
            if (ex_y*ICON_SIZE < (req_y + offset - dy))
                sig = 1;
            else
                sig = -1;

            closest = -1;
            done = 0;
            /* look for closest free slot */
            for (i=0; i<(DOCK_DETTACH_THRESHOLD+1)*2 && !done; i++) {
                int j;

                done = 1;
                closest = sig*(i/2) + ex_y;
                /* check if this slot is used */
                if (closest >= 0) {
                    for (j = 0; j<dock->max_icons; j++) {
                        if (dock->icon_array[j]
                            && dock->icon_array[j]->yindex==closest) {
                            /* slot is used by someone else */
                            if (dock->icon_array[j]!=icon)
                                done = 0;
                            break;
                        }
                    }
                }
                sig = -sig;
            }
            if (done && closest >= 0 && closest <= max_y_icons &&
                ((ex_y >= closest && ex_y - closest < DOCK_DETTACH_THRESHOLD+1)
                 ||
                 (ex_y < closest && closest - ex_y <= DOCK_DETTACH_THRESHOLD+1))) {
                *ret_x = 0;
                *ret_y = closest;
                return True;
            }
        } else { /* !redocking */

            /* if slot is free and the icon is close enough, return it */
            if (!aicon && ex_x == 0 && ex_y >= 0 && ex_y <= max_y_icons) {
                *ret_x = 0;
                *ret_y = ex_y;
                return True;
            }
        }
    } else { /* CLIP */
        int neighbours = 0;
        int start, stop, k;

        start = icon->omnipresent ? 0 : scr->current_workspace;
        stop  = icon->omnipresent ? scr->workspace_count : start+1;

        aicon = NULL;
        for (k=start; k<stop; k++) {
            WDock *tmp = scr->workspaces[k]->clip;
            if (!tmp)
                continue;
            for (i=0; i<tmp->max_icons; i++) {
                nicon = tmp->icon_array[i];
                if (nicon && nicon->xindex == ex_x && nicon->yindex == ex_y) {
                    aicon = nicon;
                    break;
                }
            }
            if (aicon)
                break;
        }
        for (k=start; k<stop; k++) {
            WDock *tmp = scr->workspaces[k]->clip;
            if (!tmp)
                continue;
            for (i=0; i<tmp->max_icons; i++) {
                nicon = tmp->icon_array[i];
                if (nicon && nicon != icon && /* Icon can't be it's own neighbour */
                    (abs(nicon->xindex - ex_x) <= CLIP_ATTACH_VICINITY &&
                     abs(nicon->yindex - ex_y) <= CLIP_ATTACH_VICINITY)) {
                    neighbours = 1;
                    break;
                }
            }
            if (neighbours)
                break;
        }

        if (neighbours && (aicon==NULL || (redocking && aicon == icon))) {
            *ret_x = ex_x;
            *ret_y = ex_y;
            return True;
        }
    }
    return False;
}


static int
onScreen(WScreen *scr, int x, int y, int sx, int ex, int sy, int ey)
{
    WMRect rect = wmkrect(x, y, ICON_SIZE, ICON_SIZE);
    int flags;

    wGetRectPlacementInfo(scr, rect, &flags);

    return !(flags & (XFLAG_DEAD | XFLAG_PARTIAL));
}


/*
 * returns true if it can find a free slot in the dock,
 * in which case it changes x_pos and y_pos accordingly.
 * Else returns false.
 */
Bool
wDockFindFreeSlot(WDock *dock, int *x_pos, int *y_pos)
{
    WScreen *scr = dock->screen_ptr;
    WAppIcon *btn;
    WAppIconChain *chain;
    unsigned char *slot_map;
    int mwidth;
    int r;
    int x, y;
    int i, done = False;
    int corner;
    int sx=0, sy=0, ex=scr->scr_width, ey=scr->scr_height;
    int extra_count=0;

    if (dock->type == WM_CLIP &&
        dock != scr->workspaces[scr->current_workspace]->clip)
        extra_count = scr->global_icon_count;

    /* if the dock is full */
    if (dock->icon_count+extra_count >= dock->max_icons) {
        return False;
    }

    if (!wPreferences.flags.nodock && scr->dock) {
        if (scr->dock->on_right_side)
            ex -= ICON_SIZE + DOCK_EXTRA_SPACE;
        else
            sx += ICON_SIZE + DOCK_EXTRA_SPACE;
    }

    if (ex < dock->x_pos)
        ex = dock->x_pos;
    if (sx > dock->x_pos+ICON_SIZE)
        sx = dock->x_pos+ICON_SIZE;
#define C_NONE 0
#define C_NW 1
#define C_NE 2
#define C_SW 3
#define C_SE 4

    /* check if clip is in a corner */
    if (dock->type==WM_CLIP) {
        if (dock->x_pos < 1 && dock->y_pos < 1)
            corner = C_NE;
        else if (dock->x_pos < 1 && dock->y_pos >= (ey-ICON_SIZE))
            corner = C_SE;
        else if (dock->x_pos >= (ex-ICON_SIZE)&& dock->y_pos >= (ey-ICON_SIZE))
            corner = C_SW;
        else if (dock->x_pos >= (ex-ICON_SIZE) && dock->y_pos < 1)
            corner = C_NW;
        else
            corner = C_NONE;
    } else
        corner = C_NONE;

    /* If the clip is in the corner, use only slots that are in the border
     * of the screen */
    if (corner!=C_NONE) {
        char *hmap, *vmap;
        int hcount, vcount;

        hcount = WMIN(dock->max_icons, scr->scr_width/ICON_SIZE);
        vcount = WMIN(dock->max_icons, scr->scr_height/ICON_SIZE);
        hmap = wmalloc(hcount+1);
        memset(hmap, 0, hcount+1);
        vmap = wmalloc(vcount+1);
        memset(vmap, 0, vcount+1);

        /* mark used positions */
        switch (corner) {
        case C_NE:
            for (i=0; i<dock->max_icons; i++) {
                btn = dock->icon_array[i];
                if (!btn)
                    continue;

                if (btn->xindex==0 && btn->yindex > 0 && btn->yindex < vcount)
                    vmap[btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex>0 && btn->xindex<hcount)
                    hmap[btn->xindex] = 1;
            }
            for (chain=scr->global_icons; chain!=NULL; chain=chain->next) {
                btn = chain->aicon;
                if (btn->xindex==0 && btn->yindex > 0 && btn->yindex < vcount)
                    vmap[btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex>0 && btn->xindex<hcount)
                    hmap[btn->xindex] = 1;
            }
            break;
        case C_NW:
            for (i=0; i<dock->max_icons; i++) {
                btn = dock->icon_array[i];
                if (!btn)
                    continue;

                if (btn->xindex==0 && btn->yindex > 0 && btn->yindex < vcount)
                    vmap[btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex<0 &&btn->xindex>-hcount)
                    hmap[-btn->xindex] = 1;
            }
            for (chain=scr->global_icons; chain!=NULL; chain=chain->next) {
                btn = chain->aicon;
                if (btn->xindex==0 && btn->yindex > 0 && btn->yindex < vcount)
                    vmap[btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex<0 &&btn->xindex>-hcount)
                    hmap[-btn->xindex] = 1;
            }
            break;
        case C_SE:
            for (i=0; i<dock->max_icons; i++) {
                btn = dock->icon_array[i];
                if (!btn)
                    continue;

                if (btn->xindex==0 && btn->yindex < 0 && btn->yindex > -vcount)
                    vmap[-btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex>0 && btn->xindex<hcount)
                    hmap[btn->xindex] = 1;
            }
            for (chain=scr->global_icons; chain!=NULL; chain=chain->next) {
                btn = chain->aicon;
                if (btn->xindex==0 && btn->yindex < 0 && btn->yindex > -vcount)
                    vmap[-btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex>0 && btn->xindex<hcount)
                    hmap[btn->xindex] = 1;
            }
            break;
        case C_SW:
        default:
            for (i=0; i<dock->max_icons; i++) {
                btn = dock->icon_array[i];
                if (!btn)
                    continue;

                if (btn->xindex==0 && btn->yindex < 0 && btn->yindex > -vcount)
                    vmap[-btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex<0 &&btn->xindex>-hcount)
                    hmap[-btn->xindex] = 1;
            }
            for (chain=scr->global_icons; chain!=NULL; chain=chain->next) {
                btn = chain->aicon;
                if (btn->xindex==0 && btn->yindex < 0 && btn->yindex > -vcount)
                    vmap[-btn->yindex] = 1;
                else if (btn->yindex==0 && btn->xindex<0 &&btn->xindex>-hcount)
                    hmap[-btn->xindex] = 1;
            }
        }
        x=0; y=0;
        done = 0;
        /* search a vacant slot */
        for (i=1; i<WMAX(vcount, hcount); i++) {
            if (i < vcount && vmap[i]==0) {
                /* found a slot */
                x = 0;
                y = i;
                done = 1;
                break;
            } else if (i < hcount && hmap[i]==0) {
                /* found a slot */
                x = i;
                y = 0;
                done = 1;
                break;
            }
        }
        wfree(vmap);
        wfree(hmap);
        /* If found a slot, translate and return */
        if (done) {
            if (corner==C_NW || corner==C_NE) {
                *y_pos = y;
            } else {
                *y_pos = -y;
            }
            if (corner==C_NE || corner==C_SE) {
                *x_pos = x;
            } else {
                *x_pos = -x;
            }
            return True;
        }
        /* else, try to find a slot somewhere else */
    }

    /* a map of mwidth x mwidth would be enough if we allowed icons to be
     * placed outside of screen */
    mwidth = (int)ceil(sqrt(dock->max_icons));

    /* In the worst case (the clip is in the corner of the screen),
     * the amount of icons that fit in the clip is smaller.
     * Double the map to get a safe value.
     */
    mwidth += mwidth;

    r = (mwidth-1)/2;

    slot_map = wmalloc(mwidth*mwidth);
    memset(slot_map, 0, mwidth*mwidth);

#define XY2OFS(x,y) (WMAX(abs(x),abs(y)) > r) ? 0 : (((y)+r)*(mwidth)+(x)+r)

    /* mark used slots in the map. If the slot falls outside the map
     * (for example, when all icons are placed in line), ignore them. */
    for (i=0; i<dock->max_icons; i++) {
        btn = dock->icon_array[i];
        if (btn)
            slot_map[XY2OFS(btn->xindex, btn->yindex)] = 1;
    }
    for (chain=scr->global_icons; chain!=NULL; chain=chain->next) {
        slot_map[XY2OFS(chain->aicon->xindex, chain->aicon->yindex)] = 1;
    }
    /* Find closest slot from the center that is free by scanning the
     * map from the center to outward in circular passes.
     * This will not result in a neat layout, but will be optimal
     * in the sense that there will not be holes left.
     */
    done = 0;
    for (i = 1; i <= r && !done; i++) {
        int tx, ty;

        /* top and bottom parts of the ring */
        for (x = -i; x <= i && !done; x++) {
            tx = dock->x_pos + x*ICON_SIZE;
            y = -i;
            ty = dock->y_pos + y*ICON_SIZE;
            if (slot_map[XY2OFS(x,y)]==0
                && onScreen(scr, tx, ty, sx, ex, sy, ey)) {
                *x_pos = x;
                *y_pos = y;
                done = 1;
                break;
            }
            y = i;
            ty = dock->y_pos + y*ICON_SIZE;
            if (slot_map[XY2OFS(x,y)]==0
                && onScreen(scr, tx, ty, sx, ex, sy, ey)) {
                *x_pos = x;
                *y_pos = y;
                done = 1;
                break;
            }
        }
        /* left and right parts of the ring */
        for (y = -i+1; y <= i-1; y++) {
            ty = dock->y_pos + y*ICON_SIZE;
            x = -i;
            tx = dock->x_pos + x*ICON_SIZE;
            if (slot_map[XY2OFS(x,y)]==0
                && onScreen(scr, tx, ty, sx, ex, sy, ey)) {
                *x_pos = x;
                *y_pos = y;
                done = 1;
                break;
            }
            x = i;
            tx = dock->x_pos + x*ICON_SIZE;
            if (slot_map[XY2OFS(x,y)]==0
                && onScreen(scr, tx, ty, sx, ex, sy, ey)) {
                *x_pos = x;
                *y_pos = y;
                done = 1;
                break;
            }
        }
    }
    wfree(slot_map);
#undef XY2OFS
    return done;
}


static void
moveDock(WDock *dock, int new_x, int new_y)
{
    WAppIcon *btn;
    int i;

    dock->x_pos = new_x;
    dock->y_pos = new_y;
    for (i=0; i<dock->max_icons; i++) {
        btn = dock->icon_array[i];
        if (btn) {
            btn->x_pos = new_x + btn->xindex*ICON_SIZE;
            btn->y_pos = new_y + btn->yindex*ICON_SIZE;
            XMoveWindow(dpy, btn->icon->core->window, btn->x_pos, btn->y_pos);
        }
    }
}


static void
swapDock(WDock *dock)
{
    WScreen *scr = dock->screen_ptr;
    WAppIcon *btn;
    int x, i;


    if (dock->on_right_side) {
        x = dock->x_pos = scr->scr_width - ICON_SIZE - DOCK_EXTRA_SPACE;
    } else {
        x = dock->x_pos = DOCK_EXTRA_SPACE;
    }

    for (i=0; i<dock->max_icons; i++) {
        btn = dock->icon_array[i];
        if (btn) {
            btn->x_pos = x;
            XMoveWindow(dpy, btn->icon->core->window, btn->x_pos, btn->y_pos);
        }
    }

    wScreenUpdateUsableArea(scr);
}


static pid_t
execCommand(WAppIcon *btn, char *command, WSavedState *state)
{
    WScreen *scr = btn->icon->core->screen_ptr;
    pid_t pid;
    char **argv;
    int argc;
    char *cmdline;

    cmdline = ExpandOptions(scr, command);

    if (scr->flags.dnd_data_convertion_status || !cmdline) {
        if (cmdline)
            wfree(cmdline);
        if (state)
            wfree(state);
        return 0;
    }

    wtokensplit(cmdline, &argv, &argc);

    if (argv==NULL) {
        if (cmdline)
            wfree(cmdline);
        if (state)
            wfree(state);
        return 0;
    }

    if ((pid=fork())==0) {
        char **args;
        int i;

        SetupEnvironment(scr);

#ifdef HAVE_SETSID
        setsid();
#endif

        args = malloc(sizeof(char*)*(argc+1));
        if (!args)
            exit(111);
        for (i=0; i<argc; i++) {
            args[i] = argv[i];
        }
        args[argc] = NULL;
        execvp(argv[0], args);
        exit(111);
    }
    wtokenfree(argv, argc);

    if (pid > 0) {
        if (!state) {
            state = wmalloc(sizeof(WSavedState));
            memset(state, 0, sizeof(WSavedState));
            state->hidden = -1;
            state->miniaturized = -1;
            state->shaded = -1;
            if (btn->dock==scr->dock || btn->omnipresent)
                state->workspace = -1;
            else
                state->workspace = scr->current_workspace;
        }
        wWindowAddSavedState(btn->wm_instance, btn->wm_class, cmdline, pid,
                             state);
        wAddDeathHandler(pid, (WDeathHandler*)trackDeadProcess,
                         btn->dock);
    } else if (state) {
        wfree(state);
    }
    wfree(cmdline);
    return pid;
}


void
wDockHideIcons(WDock *dock)
{
    int i;

    if (dock==NULL)
        return;

    for (i=1; i<dock->max_icons; i++) {
        if (dock->icon_array[i])
            XUnmapWindow(dpy, dock->icon_array[i]->icon->core->window);
    }
    dock->mapped = 0;

    dockIconPaint(dock->icon_array[0]);
}


void
wDockShowIcons(WDock *dock)
{
    int i, newlevel;
    WAppIcon *btn;

    if (dock==NULL)
        return;

    btn = dock->icon_array[0];
    moveDock(dock, btn->x_pos, btn->y_pos);

    newlevel = dock->lowered ? WMNormalLevel : WMDockLevel;
    ChangeStackingLevel(btn->icon->core, newlevel);

    for (i=1; i<dock->max_icons; i++) {
        if (dock->icon_array[i]) {
            MoveInStackListAbove(dock->icon_array[i]->icon->core,
                                 btn->icon->core);
            break;
        }
    }

    if (!dock->collapsed) {
        for (i=1; i<dock->max_icons; i++) {
            if (dock->icon_array[i]) {
                XMapWindow(dpy, dock->icon_array[i]->icon->core->window);
            }
        }
    }
    dock->mapped = 1;

    dockIconPaint(btn);
}


void
wDockLower(WDock *dock)
{
    int i;

    for (i=0; i<dock->max_icons; i++) {
        if (dock->icon_array[i])
            wLowerFrame(dock->icon_array[i]->icon->core);
    }
}


void
wDockRaise(WDock *dock)
{
    int i;

    for (i=dock->max_icons-1; i>=0; i--) {
        if (dock->icon_array[i])
            wRaiseFrame(dock->icon_array[i]->icon->core);
    }
}


void
wDockRaiseLower(WDock *dock)
{
    if (!dock->icon_array[0]->icon->core->stacking->above
        ||(dock->icon_array[0]->icon->core->stacking->window_level
           !=dock->icon_array[0]->icon->core->stacking->above->stacking->window_level))
        wDockLower(dock);
    else
        wDockRaise(dock);
}


void
wDockFinishLaunch(WDock *dock, WAppIcon *icon)
{
    icon->launching = 0;
    icon->relaunching = 0;
    dockIconPaint(icon);
}


WAppIcon*
wDockFindIconForWindow(WDock *dock, Window window)
{
    WAppIcon *icon;
    int i;

    for (i=0; i<dock->max_icons; i++) {
        icon = dock->icon_array[i];
        if (icon && icon->main_window == window)
            return icon;
    }
    return NULL;
}


void
wDockTrackWindowLaunch(WDock *dock, Window window)
{
    WAppIcon *icon;
    char *wm_class, *wm_instance;
    int i;
    Bool firstPass = True;
    Bool found = False;
    char *command = NULL;

    command = GetCommandForWindow(window);

    if (!PropGetWMClass(window, &wm_class, &wm_instance) ||
        (!wm_class && !wm_instance)) {

        if (command)
            wfree(command);
        return;
    }

retry:
    for (i=0; i<dock->max_icons; i++) {
        icon = dock->icon_array[i];
        if (!icon)
            continue;

        /* app is already attached to icon */
        if (icon->main_window == window) {
            found = True;
            break;
        }

        if ((icon->wm_instance || icon->wm_class)
            && (icon->launching || !icon->running)) {

            if (icon->wm_instance && wm_instance &&
                strcmp(icon->wm_instance, wm_instance)!=0) {
                continue;
            }
            if (icon->wm_class && wm_class &&
                strcmp(icon->wm_class, wm_class)!=0) {
                continue;
            }
            if (firstPass && command && strcmp(icon->command, command)!=0) {
                continue;
            }

            if (!icon->relaunching) {
                WApplication *wapp;

                /* Possibly an application that was docked with dockit,
                 * but the user did not update WMState to indicate that
                 * it was docked by force */
                wapp = wApplicationOf(window);
                if (!wapp) {
                    icon->forced_dock = 1;
                    icon->running = 0;
                }
                if (!icon->forced_dock) {
                    icon->main_window = window;
                }
            }
            found = True;
            if (!wPreferences.no_animations && !icon->launching &&
                !dock->screen_ptr->flags.startup && !dock->collapsed) {
                WAppIcon *aicon;
                int x0, y0;

                icon->launching = 1;
                dockIconPaint(icon);

                aicon = wAppIconCreateForDock(dock->screen_ptr, NULL,
                                              wm_instance, wm_class,
                                              TILE_NORMAL);
                /* XXX: can: aicon->icon == NULL ? */
                PlaceIcon(dock->screen_ptr, &x0, &y0, wGetHeadForWindow(aicon->icon->owner));
                wAppIconMove(aicon, x0, y0);
                /* Should this always be lowered? -Dan */
                if (dock->lowered)
                    wLowerFrame(aicon->icon->core);
                XMapWindow(dpy, aicon->icon->core->window);
                aicon->launching = 1;
                wAppIconPaint(aicon);
                SlideWindow(aicon->icon->core->window, x0, y0,
                            icon->x_pos, icon->y_pos);
                XUnmapWindow(dpy, aicon->icon->core->window);
                wAppIconDestroy(aicon);
            }
            wDockFinishLaunch(dock, icon);
            break;
        }
    }

    if (firstPass && !found) {
        firstPass = False;
        goto retry;
    }

    if (command)
        wfree(command);

    if (wm_class)
        XFree(wm_class);
    if (wm_instance)
        XFree(wm_instance);
}



void
wClipUpdateForWorkspaceChange(WScreen *scr, int workspace)
{
    if (!wPreferences.flags.noclip) {
        scr->clip_icon->dock = scr->workspaces[workspace]->clip;
        if (scr->current_workspace != workspace) {
            WDock *old_clip = scr->workspaces[scr->current_workspace]->clip;
            WAppIconChain *chain = scr->global_icons;

            while (chain) {
                moveIconBetweenDocks(chain->aicon->dock,
                                     scr->workspaces[workspace]->clip,
                                     chain->aicon, chain->aicon->xindex,
                                     chain->aicon->yindex);
                if (scr->workspaces[workspace]->clip->collapsed)
                    XUnmapWindow(dpy, chain->aicon->icon->core->window);
                chain = chain->next;
            }

            wDockHideIcons(old_clip);
            if (old_clip->auto_raise_lower) {
                if (old_clip->auto_raise_magic) {
                    WMDeleteTimerHandler(old_clip->auto_raise_magic);
                    old_clip->auto_raise_magic = NULL;
                }
                wDockLower(old_clip);
            }
            if (old_clip->auto_collapse) {
                if (old_clip->auto_expand_magic) {
                    WMDeleteTimerHandler(old_clip->auto_expand_magic);
                    old_clip->auto_expand_magic = NULL;
                }
                old_clip->collapsed = 1;
            }
            wDockShowIcons(scr->workspaces[workspace]->clip);
        }
        if (scr->flags.clip_balloon_mapped)
            showClipBalloon(scr->clip_icon->dock, workspace);
    }
}



static void
trackDeadProcess(pid_t pid, unsigned char status, WDock *dock)
{
    WAppIcon *icon;
    int i;

    for (i=0; i<dock->max_icons; i++) {
        icon = dock->icon_array[i];
        if (!icon)
            continue;

        if (icon->launching && icon->pid == pid) {
            if (!icon->relaunching) {
                icon->running = 0;
                icon->main_window = None;
            }
            wDockFinishLaunch(dock, icon);
            icon->pid = 0;
            if (status==111) {
                char *cmd;

#ifdef XDND
                if (icon->drop_launch)
                    cmd = icon->dnd_command;
                else
#endif
                if (icon->paste_launch)
                    cmd = icon->paste_command;
                else
                    cmd = icon->command;

		NSRunAlertPanel(@"Error", [NSString stringWithFormat: @"Could not execute command \"%s\"", cmd],
				@"OK", nil, nil);
            }
            break;
        }
    }
}


static void
toggleLowered(WDock *dock)
{
    WAppIcon *tmp;
    int newlevel, i;

    /* lower/raise Dock */
    if (!dock->lowered) {
        newlevel = WMNormalLevel;
        dock->lowered = 1;
    } else {
        newlevel = WMDockLevel;
        dock->lowered = 0;
    }

    for (i=0; i<dock->max_icons; i++) {
        tmp = dock->icon_array[i];
        if (!tmp)
            continue;

        ChangeStackingLevel(tmp->icon->core, newlevel);
        if (dock->lowered)
            wLowerFrame(tmp->icon->core);
    }

    if (dock->type == WM_DOCK)
        wScreenUpdateUsableArea(dock->screen_ptr);
}


static void
toggleCollapsed(WDock *dock)
{
    if (dock->collapsed) {
        dock->collapsed = 0;
        wDockShowIcons(dock);
    }
    else {
        dock->collapsed = 1;
        wDockHideIcons(dock);
    }
}


static void
openDockMenu(WDock *dock, WAppIcon *aicon, XEvent *event)
{
    WScreen *scr = dock->screen_ptr;
    WObjDescriptor *desc;
    WMenuEntry *entry;
    WApplication *wapp = NULL;
    int index = 0;
    int x_pos;
    int n_selected;
    int appIsRunning = aicon->running && aicon->icon && aicon->icon->owner;

    if (dock->type == WM_DOCK) {
        /* keep on top */
        entry = dock->menu->entries[index];
        entry->flags.indicator_on = !dock->lowered;
        entry->clientdata = dock;
        dock->menu->flags.realized = 0;
    } else {
        /* clip options */
        if (scr->clip_options)
            updateClipOptionsMenu(scr->clip_options, dock);

        n_selected = numberOfSelectedIcons(dock);

        /* Rename Workspace */
        entry = dock->menu->entries[++index];
        if (aicon == scr->clip_icon) {
            entry->callback = renameCallback;
            entry->clientdata = dock;
            entry->flags.indicator = 0;
            entry->text = ("Rename Workspace");
        } else {
            entry->callback = omnipresentCallback;
            entry->clientdata = aicon;
            if (n_selected > 0) {
                entry->flags.indicator = 0;
                entry->text = ("Toggle Omnipresent");
            } else {
                entry->flags.indicator = 1;
                entry->flags.indicator_on = aicon->omnipresent;
                entry->flags.indicator_type = MI_CHECK;
                entry->text = ("Omnipresent");
            }
        }

        /* select/unselect icon */
        entry = dock->menu->entries[++index];
        entry->clientdata = aicon;
        entry->flags.indicator_on = aicon->icon->selected;
        wMenuSetEnabled(dock->menu, index, aicon!=scr->clip_icon);

        /* select/unselect all icons */
        entry = dock->menu->entries[++index];
        entry->clientdata = aicon;
        if (n_selected > 0)
            entry->text = ("Unselect All Icons");
        else
            entry->text = ("Select All Icons");
        wMenuSetEnabled(dock->menu, index, dock->icon_count > 1);

        /* keep icon(s) */
        entry = dock->menu->entries[++index];
        entry->clientdata = aicon;
        if (n_selected > 1)
            entry->text = ("Keep Icons");
        else
            entry->text = ("Keep Icon");
        wMenuSetEnabled(dock->menu, index, dock->icon_count > 1);

        /* this is the workspace submenu part */
        entry = dock->menu->entries[++index];
        if (n_selected > 1)
            entry->text = ("Move Icons To");
        else
            entry->text = ("Move Icon To");
        if (scr->clip_submenu)
            updateWorkspaceMenu(scr->clip_submenu, aicon);
        wMenuSetEnabled(dock->menu, index, !aicon->omnipresent);

        /* remove icon(s) */
        entry = dock->menu->entries[++index];
        entry->clientdata = aicon;
        if (n_selected > 1)
            entry->text = ("Remove Icons");
        else
            entry->text = ("Remove Icon");
        wMenuSetEnabled(dock->menu, index, dock->icon_count > 1);

        /* attract icon(s) */
        entry = dock->menu->entries[++index];
        entry->clientdata = aicon;

        dock->menu->flags.realized = 0;
        wMenuRealize(dock->menu);
    }


    if (aicon->icon->owner) {
        wapp = wApplicationOf(aicon->icon->owner->main_window);
    } else {
        wapp = NULL;
    }

    /* launch */
    entry = dock->menu->entries[++index];
    entry->clientdata = aicon;
    wMenuSetEnabled(dock->menu, index, aicon->command!=NULL);

    /* unhide here */
    entry = dock->menu->entries[++index];
    entry->clientdata = aicon;
    if (wapp && wapp->flags.hidden) {
        entry->text = ("Unhide Here");
    } else {
        entry->text = ("Bring Here");
    }
    wMenuSetEnabled(dock->menu, index, appIsRunning);

    /* hide */
    entry = dock->menu->entries[++index];
    entry->clientdata = aicon;
    if (wapp && wapp->flags.hidden) {
        entry->text = ("Unhide");
    } else {
        entry->text = ("Hide");
    }
    wMenuSetEnabled(dock->menu, index, appIsRunning);

    /* settings */
    entry = dock->menu->entries[++index];
    entry->clientdata = aicon;
    wMenuSetEnabled(dock->menu, index, !aicon->editing
                    && !wPreferences.flags.noupdates);

    /* kill */
    entry = dock->menu->entries[++index];
    entry->clientdata = aicon;
    wMenuSetEnabled(dock->menu, index, appIsRunning);

    if (!dock->menu->flags.realized)
        wMenuRealize(dock->menu);

    if (dock->type == WM_CLIP) {
        /*x_pos = event->xbutton.x_root+2;*/
        x_pos = event->xbutton.x_root - dock->menu->frame->core->width/2 - 1;
        if (x_pos < 0) {
            x_pos = 0;
        } else if (x_pos + dock->menu->frame->core->width > scr->scr_width-2) {
            x_pos = scr->scr_width - dock->menu->frame->core->width - 4;
        }
    } else {
        x_pos = dock->on_right_side ?
            scr->scr_width - dock->menu->frame->core->width - 3 : 0;
    }

    wMenuMapAt(dock->menu, x_pos, event->xbutton.y_root+2, False);

    /* allow drag select */
    event->xany.send_event = True;
    desc = &dock->menu->menu->descriptor;
    (*desc->handle_mousedown)(desc, event);
}


/******************************************************************/
static void
iconDblClick(WObjDescriptor *desc, XEvent *event)
{
    WAppIcon *btn = desc->parent;
    WDock *dock = btn->dock;
    WApplication *wapp = NULL;
    int unhideHere = 0;

    if (btn->icon->owner && !(event->xbutton.state & ControlMask)) {
        wapp = wApplicationOf(btn->icon->owner->main_window);

        assert(wapp!=NULL);

        unhideHere = (event->xbutton.state & ShiftMask);

        /* go to the last workspace that the user worked on the app */
        if (wapp->last_workspace != dock->screen_ptr->current_workspace
            && !unhideHere) {
            wWorkspaceChange(dock->screen_ptr, wapp->last_workspace);
        }

        wUnhideApplication(wapp, event->xbutton.button==Button2, unhideHere);

        if (event->xbutton.state & MOD_MASK) {
            wHideOtherApplications(btn->icon->owner);
        }
    } else {
        if (event->xbutton.button==Button1) {

            if (event->xbutton.state & MOD_MASK) {
                /* raise/lower dock */
                toggleLowered(dock);
            } else if (btn == dock->screen_ptr->clip_icon) {
                if (getClipButton(event->xbutton.x, event->xbutton.y)==CLIP_IDLE)
                    toggleCollapsed(dock);
                else
                    handleClipChangeWorkspace(dock->screen_ptr, event);
            } else if (btn->command) {
                if (!btn->launching &&
                    (!btn->running || (event->xbutton.state & ControlMask))) {
                    launchDockedApplication(btn, False);
                }
            } else if (btn->xindex==0 && btn->yindex==0 &&
                       btn->dock->type==WM_DOCK) {
		[[WMDialogController sharedController] showGNUstepPanel: nil];
            }
        }
    }
}



static void
handleDockMove(WDock *dock, WAppIcon *aicon, XEvent *event)
{
    WScreen *scr = dock->screen_ptr;
    int ofs_x=event->xbutton.x, ofs_y=event->xbutton.y;
    int x, y;
    XEvent ev;
    int grabbed = 0, swapped = 0, done;
    Pixmap ghost = None;
    int superfluous = wPreferences.superfluous; /* we catch it to avoid problems */

#ifdef DEBUG
    puts("moving dock");
#endif
    if (XGrabPointer(dpy, aicon->icon->core->window, True, ButtonMotionMask
                     |ButtonReleaseMask|ButtonPressMask, GrabModeAsync,
                     GrabModeAsync, None, None, CurrentTime) !=GrabSuccess) {
        wwarning("pointer grab failed for dock move");
    }
    y = 0;
    for (x=0; x<dock->max_icons; x++) {
        if (dock->icon_array[x]!=NULL &&
            dock->icon_array[x]->yindex > y)
            y = dock->icon_array[x]->yindex;
    }
    y++;
    XResizeWindow(dpy, scr->dock_shadow, ICON_SIZE, ICON_SIZE*y);

    done = 0;
    while (!done) {
        WMMaskEvent(dpy, PointerMotionMask|ButtonReleaseMask|ButtonPressMask
                    |ButtonMotionMask|ExposureMask, &ev);
        switch (ev.type) {
        case Expose:
            WMHandleEvent(&ev);
            break;

        case MotionNotify:
            if (!grabbed) {
                if (abs(ofs_x-ev.xmotion.x)>=MOVE_THRESHOLD
                    || abs(ofs_y-ev.xmotion.y)>=MOVE_THRESHOLD) {
                    XChangeActivePointerGrab(dpy, ButtonMotionMask
                                             |ButtonReleaseMask|ButtonPressMask,
                                             wCursor[WCUR_MOVE], CurrentTime);
                    grabbed=1;
                }
                break;
            }
            if (dock->type == WM_CLIP) {
                x = ev.xmotion.x_root - ofs_x;
                y = ev.xmotion.y_root - ofs_y;
                wScreenKeepInside(scr, &x, &y, ICON_SIZE, ICON_SIZE);

                moveDock(dock, x, y);
            } else {
                /* move vertically if pointer is inside the dock*/
                if ((dock->on_right_side &&
                     ev.xmotion.x_root >= dock->x_pos - ICON_SIZE)
                    || (!dock->on_right_side &&
                        ev.xmotion.x_root <= dock->x_pos + ICON_SIZE*2)) {

                    x = ev.xmotion.x_root - ofs_x;
                    y = ev.xmotion.y_root - ofs_y;
                    wScreenKeepInside(scr, &x, &y, ICON_SIZE, ICON_SIZE);
                    moveDock(dock, dock->x_pos, y);
                }
                /* move horizontally to change sides */
                x = ev.xmotion.x_root - ofs_x;
                if (!dock->on_right_side) {

                    /* is on left */

                    if (ev.xmotion.x_root > dock->x_pos + ICON_SIZE*2) {
                        XMoveWindow(dpy, scr->dock_shadow, scr->scr_width-ICON_SIZE
                                    -DOCK_EXTRA_SPACE-1, dock->y_pos);
                        if (superfluous && ghost==None) {
                            ghost = MakeGhostDock(dock, dock->x_pos,
                                                  scr->scr_width-ICON_SIZE
                                                  -DOCK_EXTRA_SPACE-1,
                                                  dock->y_pos);
                            XSetWindowBackgroundPixmap(dpy, scr->dock_shadow,
                                                       ghost);
                            XClearWindow(dpy, scr->dock_shadow);
                        }
                        XMapRaised(dpy, scr->dock_shadow);
                        swapped = 1;
                    } else {
                        if (superfluous && ghost!=None) {
                            XFreePixmap(dpy, ghost);
                            ghost = None;
                        }
                        XUnmapWindow(dpy, scr->dock_shadow);
                        swapped = 0;
                    }
                } else {
                    /* is on right */
                    if (ev.xmotion.x_root < dock->x_pos - ICON_SIZE) {
                        XMoveWindow(dpy, scr->dock_shadow,
                                    DOCK_EXTRA_SPACE, dock->y_pos);
                        if (superfluous && ghost==None) {
                            ghost = MakeGhostDock(dock, dock->x_pos,
                                                  DOCK_EXTRA_SPACE, dock->y_pos);
                            XSetWindowBackgroundPixmap(dpy, scr->dock_shadow,
                                                       ghost);
                            XClearWindow(dpy, scr->dock_shadow);
                        }
                        XMapRaised(dpy, scr->dock_shadow);
                        swapped = -1;
                    } else {
                        XUnmapWindow(dpy, scr->dock_shadow);
                        swapped = 0;
                        if (superfluous && ghost!=None) {
                            XFreePixmap(dpy, ghost);
                            ghost = None;
                        }
                    }
                }
            }
            break;

        case ButtonPress:
            break;

        case ButtonRelease:
            if (ev.xbutton.button != event->xbutton.button)
                break;
            XUngrabPointer(dpy, CurrentTime);
            XUnmapWindow(dpy, scr->dock_shadow);
            XResizeWindow(dpy, scr->dock_shadow, ICON_SIZE, ICON_SIZE);
            if (dock->type == WM_DOCK) {
                if (swapped!=0) {
                    if (swapped>0)
                        dock->on_right_side = 1;
                    else
                        dock->on_right_side = 0;
                    swapDock(dock);
                    wArrangeIcons(scr, False);
                }
            }
            done = 1;
            break;
        }
    }
    if (superfluous) {
        if (ghost!=None)
            XFreePixmap(dpy, ghost);
        XSetWindowBackground(dpy, scr->dock_shadow, scr->white_pixel);
    }
#ifdef DEBUG
    puts("End dock move");
#endif
}



static void
handleIconMove(WDock *dock, WAppIcon *aicon, XEvent *event)
{
    WScreen *scr = dock->screen_ptr;
    Window wins[2];
    WIcon *icon = aicon->icon;
    WDock *dock2 = NULL, *last_dock = dock, *clip = NULL;
    int ondock, grabbed = 0, change_dock = 0, collapsed = 0;
    XEvent ev;
    int x = aicon->x_pos, y = aicon->y_pos;
    int ofs_x = event->xbutton.x, ofs_y = event->xbutton.y;
    int shad_x = x, shad_y = y;
    int ix = aicon->xindex, iy = aicon->yindex;
    int tmp;
    Pixmap ghost = None;
    Bool docked;
    int superfluous = wPreferences.superfluous; /* we catch it to avoid problems */
    int omnipresent = aicon->omnipresent; /* this must be cached!!! */


    if (wPreferences.flags.noupdates)
        return;

    if (XGrabPointer(dpy, icon->core->window, True, ButtonMotionMask
                     |ButtonReleaseMask|ButtonPressMask, GrabModeAsync,
                     GrabModeAsync, None, None, CurrentTime) !=GrabSuccess) {
#ifdef DEBUG0
        wwarning("pointer grab failed for icon move");
#endif
    }

    if (!(event->xbutton.state & MOD_MASK))
        wRaiseFrame(icon->core);

    if (!wPreferences.flags.noclip)
        clip = scr->workspaces[scr->current_workspace]->clip;

    if (dock == scr->dock && !wPreferences.flags.noclip)
        dock2 = clip;
    else if (dock != scr->dock && !wPreferences.flags.nodock)
        dock2 = scr->dock;

    wins[0] = icon->core->window;
    wins[1] = scr->dock_shadow;
    XRestackWindows(dpy, wins, 2);
    XMoveResizeWindow(dpy, scr->dock_shadow, aicon->x_pos, aicon->y_pos,
                      ICON_SIZE, ICON_SIZE);
    if (superfluous) {
        if (icon->pixmap!=None)
            ghost = MakeGhostIcon(scr, icon->pixmap);
        else
            ghost = MakeGhostIcon(scr, icon->core->window);

        XSetWindowBackgroundPixmap(dpy, scr->dock_shadow, ghost);
        XClearWindow(dpy, scr->dock_shadow);
    }
    XMapWindow(dpy, scr->dock_shadow);

    ondock = 1;


    while(1) {
        XMaskEvent(dpy, PointerMotionMask|ButtonReleaseMask|ButtonPressMask
                   |ButtonMotionMask|ExposureMask, &ev);
        switch (ev.type) {
        case Expose:
            WMHandleEvent(&ev);
            break;

        case MotionNotify:
            if (!grabbed) {
                if (abs(ofs_x-ev.xmotion.x)>=MOVE_THRESHOLD
                    || abs(ofs_y-ev.xmotion.y)>=MOVE_THRESHOLD) {
                    XChangeActivePointerGrab(dpy, ButtonMotionMask
                                             |ButtonReleaseMask|ButtonPressMask,
                                             wCursor[WCUR_MOVE], CurrentTime);
                    grabbed=1;
                } else {
                    break;
                }
            }

            if (omnipresent) {
                int i;
                for (i=0; i<scr->workspace_count; i++) {
                    if (i == scr->current_workspace)
                        continue;
                    wDockShowIcons(scr->workspaces[i]->clip);
                }
            }

            x = ev.xmotion.x_root - ofs_x;
            y = ev.xmotion.y_root - ofs_y;
            tmp = wDockSnapIcon(dock, aicon, x, y, &ix, &iy, True);
            if (tmp && dock2) {
                change_dock = 0;
                if (last_dock != dock && collapsed) {
                    last_dock->collapsed = 1;
                    wDockHideIcons(last_dock);
                    collapsed = 0;
                }
                if (!collapsed && (collapsed = dock->collapsed)) {
                    dock->collapsed = 0;
                    wDockShowIcons(dock);
                }
                if (dock->auto_raise_lower)
                    wDockRaise(dock);
                last_dock = dock;
            } else if (dock2) {
                tmp = wDockSnapIcon(dock2, aicon, x, y, &ix, &iy, False);
                if (tmp) {
                    change_dock = 1;
                    if (last_dock != dock2 && collapsed) {
                        last_dock->collapsed = 1;
                        wDockHideIcons(last_dock);
                        collapsed = 0;
                    }
                    if (!collapsed && (collapsed = dock2->collapsed)) {
                        dock2->collapsed = 0;
                        wDockShowIcons(dock2);
                    }
                    if (dock2->auto_raise_lower)
                        wDockRaise(dock2);
                    last_dock = dock2;
                }
            }
            if (aicon->launching
                || aicon->lock
                || (aicon->running && !(ev.xmotion.state & MOD_MASK))
                || (!aicon->running && tmp)) {
                shad_x = last_dock->x_pos + ix*wPreferences.icon_size;
                shad_y = last_dock->y_pos + iy*wPreferences.icon_size;

                XMoveWindow(dpy, scr->dock_shadow, shad_x, shad_y);

                if (!ondock) {
                    XMapWindow(dpy, scr->dock_shadow);
                }
                ondock = 1;
            } else {
                if (ondock) {
                    XUnmapWindow(dpy, scr->dock_shadow);
                }
                ondock = 0;
            }
            XMoveWindow(dpy, icon->core->window, x, y);
            break;

        case ButtonPress:
            break;

        case ButtonRelease:
            if (ev.xbutton.button != event->xbutton.button)
                break;
            XUngrabPointer(dpy, CurrentTime);
            if (ondock) {
                SlideWindow(icon->core->window, x, y, shad_x, shad_y);
                XUnmapWindow(dpy, scr->dock_shadow);
                if (!change_dock) {
                    reattachIcon(dock, aicon, ix, iy);
                    if (clip && dock!=clip && clip->auto_raise_lower)
                        wDockLower(clip);
                } else {
                    docked = moveIconBetweenDocks(dock, dock2, aicon, ix, iy);
                    if (!docked) {
                        /* Slide it back if dock rejected it */
                        SlideWindow(icon->core->window, x, y, aicon->x_pos,
                                    aicon->y_pos);
                        reattachIcon(dock, aicon, aicon->xindex,aicon->yindex);
                    }
                    if (last_dock->type==WM_CLIP && last_dock->auto_collapse) {
                        collapsed = 0;
                    }
                }
            } else {
                aicon->x_pos = x;
                aicon->y_pos = y;
                if (superfluous) {
                    if (!aicon->running && !wPreferences.no_animations) {
                        /* We need to deselect it, even if is deselected in
                         * wDockDetach(), because else DoKaboom() will fail.
                         */
                        if (aicon->icon->selected)
                            wIconSelect(aicon->icon);

                        wSoundPlay(WSOUND_KABOOM);
                        DoKaboom(scr,aicon->icon->core->window, x, y);
                    } else {
                        wSoundPlay(WSOUND_UNDOCK);
                    }
                } else {
                    wSoundPlay(WSOUND_UNDOCK);
                }
                if (clip && clip->auto_raise_lower)
                    wDockLower(clip);
                wDockDetach(dock, aicon);
            }
            if (collapsed) {
                last_dock->collapsed = 1;
                wDockHideIcons(last_dock);
                collapsed = 0;
            }
            if (superfluous) {
                if (ghost!=None)
                    XFreePixmap(dpy, ghost);
                XSetWindowBackground(dpy, scr->dock_shadow, scr->white_pixel);
            }
            if (omnipresent) {
                int i;
                for (i=0; i<scr->workspace_count; i++) {
                    if (i == scr->current_workspace)
                        continue;
                    wDockHideIcons(scr->workspaces[i]->clip);
                }
            }

#ifdef DEBUG
            puts("End icon move");
#endif
            return;
        }
    }
}


static int
getClipButton(int px, int py)
{
    int pt = (CLIP_BUTTON_SIZE+2)*ICON_SIZE/64;

    if (px < 0 || py < 0 || px >= ICON_SIZE || py >= ICON_SIZE)
        return CLIP_IDLE;

    if (py <= pt-((int)ICON_SIZE-1-px))
        return CLIP_FORWARD;
    else if (px <= pt-((int)ICON_SIZE-1-py))
        return CLIP_REWIND;

    return CLIP_IDLE;
}


static void
handleClipChangeWorkspace(WScreen *scr, XEvent *event)
{
    XEvent ev;
    int done, direction, new_ws;
    int new_dir;
    WDock *clip = scr->clip_icon->dock;

    direction = getClipButton(event->xbutton.x, event->xbutton.y);

    clip->lclip_button_pushed = direction==CLIP_REWIND;
    clip->rclip_button_pushed = direction==CLIP_FORWARD;

    wClipIconPaint(scr->clip_icon);
    done = 0;
    while(!done) {
        WMMaskEvent(dpy, ExposureMask|ButtonMotionMask|ButtonReleaseMask
                    |ButtonPressMask, &ev);
        switch (ev.type) {
        case Expose:
            WMHandleEvent(&ev);
            break;

        case MotionNotify:
            new_dir = getClipButton(ev.xmotion.x, ev.xmotion.y);
            if (new_dir != direction) {
                direction = new_dir;
                clip->lclip_button_pushed = direction==CLIP_REWIND;
                clip->rclip_button_pushed = direction==CLIP_FORWARD;
                wClipIconPaint(scr->clip_icon);
            }
            break;

        case ButtonPress:
            break;

        case ButtonRelease:
            if (ev.xbutton.button == event->xbutton.button)
                done = 1;
        }
    }

    clip->lclip_button_pushed = 0;
    clip->rclip_button_pushed = 0;

    new_ws = wPreferences.ws_advance || (event->xbutton.state & ControlMask);

    if (direction == CLIP_FORWARD) {
        if (scr->current_workspace < scr->workspace_count-1)
            wWorkspaceChange(scr, scr->current_workspace+1);
        else if (new_ws && scr->current_workspace < MAX_WORKSPACES-1)
            wWorkspaceChange(scr, scr->current_workspace+1);
        else if (wPreferences.ws_cycle)
            wWorkspaceChange(scr, 0);
    }
    else if (direction == CLIP_REWIND) {
        if (scr->current_workspace > 0)
            wWorkspaceChange(scr, scr->current_workspace-1);
        else if (scr->current_workspace==0 && wPreferences.ws_cycle)
            wWorkspaceChange(scr, scr->workspace_count-1);
    }

    wClipIconPaint(scr->clip_icon);
}


static void
iconMouseDown(WObjDescriptor *desc, XEvent *event)
{
    WAppIcon *aicon = desc->parent;
    WDock *dock = aicon->dock;
    WScreen *scr = aicon->icon->core->screen_ptr;

    if (aicon->editing || WCHECK_STATE(WSTATE_MODAL))
        return;

    scr->last_dock = dock;

    if (dock->menu->flags.mapped)
        wMenuUnmap(dock->menu);

    if (IsDoubleClick(scr, event)) {
        /* double-click was not in the main clip icon */
        if (dock->type != WM_CLIP || aicon->xindex!=0 || aicon->yindex!=0
            || getClipButton(event->xbutton.x, event->xbutton.y)==CLIP_IDLE) {
            iconDblClick(desc, event);
            return;
        }
    }

    if (dock->type == WM_CLIP && scr->flags.clip_balloon_mapped) {
        XUnmapWindow(dpy, scr->clip_balloon);
        scr->flags.clip_balloon_mapped = 0;
    }

#ifdef DEBUG
    puts("handling dock");
#endif
    if (event->xbutton.button == Button1) {
        if (event->xbutton.state & MOD_MASK)
            wDockLower(dock);
        else
            wDockRaise(dock);

        if ((event->xbutton.state & ShiftMask) && aicon!=scr->clip_icon &&
            dock->type!=WM_DOCK) {
            wIconSelect(aicon->icon);
            return;
        }

        if (aicon->yindex==0 && aicon->xindex==0) {
            if (getClipButton(event->xbutton.x, event->xbutton.y)!=CLIP_IDLE
                && dock->type==WM_CLIP)
                handleClipChangeWorkspace(scr, event);
            else
                handleDockMove(dock, aicon, event);
        } else
            handleIconMove(dock, aicon, event);

    } else if (event->xbutton.button==Button2 && dock->type==WM_CLIP &&
               aicon==scr->clip_icon) {
	    printf("display workspace menu\n");
    } else if (event->xbutton.button==Button2 && dock->type==WM_CLIP &&
               (event->xbutton.state & ShiftMask) && aicon!=scr->clip_icon) {
        wClipMakeIconOmnipresent(aicon, !aicon->omnipresent);
    } else if (event->xbutton.button == Button3) {
        if (event->xbutton.send_event &&
            XGrabPointer(dpy, aicon->icon->core->window, True, ButtonMotionMask
                         |ButtonReleaseMask|ButtonPressMask, GrabModeAsync,
                         GrabModeAsync, None, None, CurrentTime) !=GrabSuccess) {
            wwarning("pointer grab failed for dockicon menu");
            return;
        }

        openDockMenu(dock, aicon, event);
    } else if (event->xbutton.button == Button2) {
        WAppIcon *btn = desc->parent;

        if (!btn->launching &&
            (!btn->running || (event->xbutton.state & ControlMask))) {
            launchDockedApplication(btn, True);
        }
    }
}


static void
showClipBalloon(WDock *dock, int workspace)
{
    int w, h;
    int x, y;
    WScreen *scr = dock->screen_ptr;
    char *text;
    Window stack[2];

    scr->flags.clip_balloon_mapped = 1;
    XMapWindow(dpy, scr->clip_balloon);

    text = scr->workspaces[workspace]->name;

    w = WMWidthOfString(scr->clip_title_font, text, strlen(text));

    h = WMFontHeight(scr->clip_title_font);
    XResizeWindow(dpy, scr->clip_balloon, w, h);

    x = dock->x_pos + CLIP_BUTTON_SIZE*ICON_SIZE/64;
    y = dock->y_pos + ICON_SIZE - WMFontHeight(scr->clip_title_font) - 3;

    if (x+w > scr->scr_width) {
        x = scr->scr_width - w;
        if (dock->y_pos + ICON_SIZE + h > scr->scr_height)
            y = dock->y_pos - h - 1;
        else
            y = dock->y_pos + ICON_SIZE;
        XRaiseWindow(dpy, scr->clip_balloon);
    } else {
        stack[0] = scr->clip_icon->icon->core->window;
        stack[1] = scr->clip_balloon;
        XRestackWindows(dpy, stack, 2);
    }
    XMoveWindow(dpy, scr->clip_balloon, x, y);
    XClearWindow(dpy, scr->clip_balloon);
    WMDrawString(scr->wmscreen, scr->clip_balloon,
                 scr->clip_title_color[CLIP_NORMAL],
                 scr->clip_title_font,
                 0, 0, text, strlen(text));
}


static void
clipEnterNotify(WObjDescriptor *desc, XEvent *event)
{
    WAppIcon *btn = (WAppIcon*)desc->parent;
    WDock *dock;
    WScreen *scr;

    assert(event->type==EnterNotify);

    if(desc->parent_type!=WCLASS_DOCK_ICON)
        return;

    scr = btn->icon->core->screen_ptr;
    if (!btn->omnipresent)
        dock = btn->dock;
    else
        dock = scr->workspaces[scr->current_workspace]->clip;

    if (!dock || dock->type!=WM_CLIP)
        return;

    /* The auto raise/lower code */
    if (dock->auto_lower_magic) {
        WMDeleteTimerHandler(dock->auto_lower_magic);
        dock->auto_lower_magic = NULL;
    }
    if (dock->auto_raise_lower && !dock->auto_raise_magic) {
        dock->auto_raise_magic = WMAddTimerHandler(AUTO_RAISE_DELAY,
                                                   clipAutoRaise,
                                                   (void *)dock);
    }

    /* The auto expand/collapse code */
    if (dock->auto_collapse_magic) {
        WMDeleteTimerHandler(dock->auto_collapse_magic);
        dock->auto_collapse_magic = NULL;
    }
    if (dock->auto_collapse && !dock->auto_expand_magic) {
        dock->auto_expand_magic = WMAddTimerHandler(AUTO_EXPAND_DELAY,
                                                    clipAutoExpand,
                                                    (void *)dock);
    }

    if (btn->xindex == 0 && btn->yindex == 0)
        showClipBalloon(dock, dock->screen_ptr->current_workspace);
    else {
        if (dock->screen_ptr->flags.clip_balloon_mapped) {
            XUnmapWindow(dpy, dock->screen_ptr->clip_balloon);
            dock->screen_ptr->flags.clip_balloon_mapped = 0;
        }
    }
}


static void
clipLeave(WDock *dock)
{
    XEvent event;
    WObjDescriptor *desc = NULL;

    if (!dock || dock->type!=WM_CLIP)
        return;

    if (XCheckTypedEvent(dpy, EnterNotify, &event)!=False) {
        if (XFindContext(dpy, event.xcrossing.window, wWinContext,
                         (XPointer *)&desc)!=XCNOENT
            && desc && desc->parent_type==WCLASS_DOCK_ICON
            && ((WAppIcon*)desc->parent)->dock
            && ((WAppIcon*)desc->parent)->dock->type==WM_CLIP) {
            /* We didn't left the Clip yet */
            XPutBackEvent(dpy, &event);
            return;
        }

        XPutBackEvent(dpy, &event);
    } else {
        /* We entered a withdrawn window, so we're still in Clip */
        return;
    }

    if (dock->auto_raise_magic) {
        WMDeleteTimerHandler(dock->auto_raise_magic);
        dock->auto_raise_magic = NULL;
    }
    if (dock->auto_raise_lower && !dock->auto_lower_magic) {
        dock->auto_lower_magic = WMAddTimerHandler(AUTO_LOWER_DELAY,
                                                   clipAutoLower,
                                                   (void *)dock);
    }

    if (dock->auto_expand_magic) {
        WMDeleteTimerHandler(dock->auto_expand_magic);
        dock->auto_expand_magic = NULL;
    }
    if (dock->auto_collapse && !dock->auto_collapse_magic) {
        dock->auto_collapse_magic = WMAddTimerHandler(AUTO_COLLAPSE_DELAY,
                                                      clipAutoCollapse,
                                                      (void *)dock);
    }
}


static void
clipLeaveNotify(WObjDescriptor *desc, XEvent *event)
{
    WAppIcon *btn = (WAppIcon*)desc->parent;

    assert(event->type==LeaveNotify);

    if(desc->parent_type!=WCLASS_DOCK_ICON)
        return;

    clipLeave(btn->dock);
}


static void
clipAutoCollapse(void *cdata)
{
    WDock *dock = (WDock *)cdata;

    if (dock->type!=WM_CLIP)
        return;

    if (dock->auto_collapse) {
        dock->collapsed = 1;
        wDockHideIcons(dock);
    }
    dock->auto_collapse_magic = NULL;
}


static void
clipAutoExpand(void *cdata)
{
    WDock *dock = (WDock *)cdata;

    if (dock->type!=WM_CLIP)
        return;

    if (dock->auto_collapse) {
        dock->collapsed = 0;
        wDockShowIcons(dock);
    }
    dock->auto_expand_magic = NULL;
}


static void
clipAutoLower(void *cdata)
{
    WDock *dock = (WDock *)cdata;

    if (dock->type!=WM_CLIP)
        return;

    if (dock->auto_raise_lower)
        wDockLower(dock);

    dock->auto_lower_magic = NULL;
}


static void
clipAutoRaise(void *cdata)
{
    WDock *dock = (WDock *)cdata;

    if (dock->type!=WM_CLIP)
        return;

    if (dock->auto_raise_lower)
        wDockRaise(dock);

    if (dock->screen_ptr->flags.clip_balloon_mapped) {
        showClipBalloon(dock, dock->screen_ptr->current_workspace);
    }

    dock->auto_raise_magic = NULL;
}


static Bool
iconCanBeOmnipresent(WAppIcon *aicon)
{
    WScreen *scr = aicon->icon->core->screen_ptr;
    WDock *clip;
    WAppIcon *btn;
    int i, j;

    for (i=0; i<scr->workspace_count; i++) {
        clip = scr->workspaces[i]->clip;

        if (clip == aicon->dock)
            continue;

        if (clip->icon_count + scr->global_icon_count >= clip->max_icons)
            return False; /* Clip is full in some workspace */

        for (j=0; j<clip->max_icons; j++) {
            btn = clip->icon_array[j];
            if(btn && btn->xindex==aicon->xindex && btn->yindex==aicon->yindex)
                return False;
        }
    }

    return True;
}


int
wClipMakeIconOmnipresent(WAppIcon *aicon, int omnipresent)
{
    WScreen *scr = aicon->icon->core->screen_ptr;
    WAppIconChain *new_entry, *tmp, *tmp1;
    int status = WO_SUCCESS;

    if ((scr->dock && aicon->dock==scr->dock) || aicon==scr->clip_icon) {
        return WO_NOT_APPLICABLE;
    }

    if (aicon->omnipresent == omnipresent)
        return WO_SUCCESS;

    if (omnipresent) {
        if (iconCanBeOmnipresent(aicon)) {
            aicon->omnipresent = 1;
            new_entry = wmalloc(sizeof(WAppIconChain));
            new_entry->aicon = aicon;
            new_entry->next = scr->global_icons;
            scr->global_icons = new_entry;
            scr->global_icon_count++;
        } else {
            aicon->omnipresent = 0;
            status = WO_FAILED;
        }
    } else {
        aicon->omnipresent = 0;
        if (aicon == scr->global_icons->aicon) {
            tmp = scr->global_icons->next;
            wfree(scr->global_icons);
            scr->global_icons = tmp;
            scr->global_icon_count--;
        } else {
            tmp = scr->global_icons;
            while (tmp->next) {
                if (tmp->next->aicon == aicon) {
                    tmp1 = tmp->next->next;
                    wfree(tmp->next);
                    tmp->next = tmp1;
                    scr->global_icon_count--;
                    break;
                }
                tmp = tmp->next;
            }
        }
    }

    wAppIconPaint(aicon);

    return status;
}

