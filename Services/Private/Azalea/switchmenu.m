// Modified by Yen-Ju Chen yjchenx gmail
/*
 *  Window Maker window manager
 *
 *  Copyright (c) 1997      Shige Abe
 *  Copyright (c) 1997-2003 Alfredo K. Kojima
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include "WindowMaker.h"
#include "window.h"
#include "client.h"
#include "workspace.h"
#include "framewin.h"
#include "WMApplication.h"

/********* Global Variables *******/

static int initialized = 0;

static void observer(void *self, WMNotification *notif);
static void wsobserver(void *self, WMNotification *notif);


void
InitializeSwitchMenu()
{
    if (!initialized) {
        initialized = 1;

        WMAddNotificationObserver(observer, NULL, WMNManaged, NULL);
        WMAddNotificationObserver(observer, NULL, WMNUnmanaged, NULL);
        WMAddNotificationObserver(observer, NULL, WMNChangedWorkspace, NULL);
        WMAddNotificationObserver(observer, NULL, WMNChangedState, NULL);
        WMAddNotificationObserver(observer, NULL, WMNChangedFocus, NULL);
        WMAddNotificationObserver(observer, NULL, WMNChangedStacking, NULL);
        WMAddNotificationObserver(observer, NULL, WMNChangedName, NULL);

        WMAddNotificationObserver(wsobserver, NULL, WMNWorkspaceChanged, NULL);
        WMAddNotificationObserver(wsobserver, NULL, WMNWorkspaceNameChanged, NULL);
    }
}


/*
 *
 * Open switch menu
 *
 */
void
OpenSwitchMenu(WScreen *scr, int x, int y, int keyboard)
{
  printf("Open switch menu\n");
}

NSString *titleForWindow (WScreen *scr, WWindow *wwin)
{
  NSString *title, *workspace, *icon = @"";
  if (wwin->frame->title)
  {
    title = [NSString stringWithCString: wwin->frame->title];
  }
  else
  {
    title = [NSString stringWithCString: DEF_WINDOW_TITLE];
  }

  if ([title length]>40)
  {
    title = [title substringToIndex: 40];
  }

  if (IS_OMNIPRESENT(wwin))
  {
    workspace = [NSString stringWithCString: "[*]"];
  }
  else
  {
    char *ws = wstrdup(scr->workspaces[wwin->frame->workspace]->name);
    workspace = [NSString stringWithFormat: @"[%s]", ws];

#if 0 // FIXME: not sure to remove ws
	    wfree(ws);
#endif
  }

  if (wwin->flags.hidden) {
    icon = @".";
  } else if (wwin->flags.miniaturized) {
    icon = @"v";
  } else if (wwin->flags.focused) {
    icon = @"x";
  } else if (wwin->flags.shaded) {
    icon = @"-";
  }

  return [NSString stringWithFormat: @"%@ %@ %@", icon, title, workspace];
}

/*
 * Update switch menu
 */
void
UpdateSwitchMenu(WScreen *scr, WWindow *wwin, int action)
{
    int i;
    int checkVisibility = 0;
    WMApplication *wmapp = [WMApplication wmApplication];
    NSMenu *switches = [wmapp switchMenu];
    NSString *title;

    /*
     *  This menu is updated under the following conditions:
     *
     *    1.  When a window is created.
     *    2.  When a window is destroyed.
     *
     *    3.  When a window changes it's title.
     * 	  4.  When a window changes its workspace.
     */
    if (action == ACTION_ADD) {

        if (wwin->flags.internal_window ||
            WFLAGP(wwin, skip_window_list) ||
            IS_GNUSTEP_MENU(wwin)) {
            return;
        }

	title = titleForWindow(scr, wwin);
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: title
	       	action: @selector(switchWindow:) keyEquivalent: @""];	
	[item setTag: wwin->client_win];
	[switches addItem: item];
	DESTROY(item);
        checkVisibility = 1;

    } else {
	for (i=0; i<[switches numberOfItems]; i++)
	{
          NSMenuItem *item = [switches itemAtIndex: i];
	  if ([item tag] == wwin->client_win)
	  {
                switch (action) {
                case ACTION_REMOVE:
                    checkVisibility = 1;

		    [switches removeItemAtIndex: i];

                    break;

                case ACTION_CHANGE:
                case ACTION_CHANGE_WORKSPACE:
                case ACTION_CHANGE_STATE:

		    title = titleForWindow(scr, wwin);

		    NSMenuItem *item = [switches itemAtIndex: i];
		    [item setTitle: title];
		    [switches itemChanged: item];

                    checkVisibility = 1;
                    break;
                }
                break;
            }
        }
    }
    if (checkVisibility) {
#if 0 // Do nothing now
        int tmp;

        tmp = switchmenu->frame->top_width + 5;
        /* if menu got unreachable, bring it to a visible place */
        if (switchmenu->frame_x < tmp - (int)switchmenu->frame->core->width) {
            wMenuMove(switchmenu, tmp - (int)switchmenu->frame->core->width,
                      switchmenu->frame_y, False);
        }
#endif
    }

    /* FIXME: WMaker freeze if switches is detached.
     * [switches update];
     */
}


/* When name of workspace changed, update switch menu accordingly */
void
UpdateSwitchMenuWorkspace(WScreen *scr, int workspace)
{
    NSMenu *switches = [[WMApplication wmApplication] switchMenu];

    if ((switches == nil) || ([switches numberOfItems] == 0))
      return;

    /* Go through every window */
    WWindow *wwin = scr->focused_window;
    NSString *title;
    id <NSMenuItem> item;
    while (wwin) {
      if (wwin->frame->workspace == workspace)
      {
	item = [switches itemWithTag: (int)(wwin->client_win)];
        title = titleForWindow(scr, wwin);
	[item setTitle: title];
	[switches itemChanged: item];
      }
      wwin = wwin->prev;
    }
}


static void
observer(void *self, WMNotification *notif)
{
    WWindow *wwin = (WWindow*)WMGetNotificationObject(notif);
    const char *name = WMGetNotificationName(notif);
    void *data = WMGetNotificationClientData(notif);

    if (!wwin)
        return;

    if (strcmp(name, WMNManaged) == 0)
        UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_ADD);
    else if (strcmp(name, WMNUnmanaged) == 0)
        UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_REMOVE);
    else if (strcmp(name, WMNChangedWorkspace) == 0)
        UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_CHANGE_WORKSPACE);
    else if (strcmp(name, WMNChangedFocus) == 0)
        UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_CHANGE_STATE);
    else if (strcmp(name, WMNChangedName) == 0)
        UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_CHANGE);
    else if (strcmp(name, WMNChangedState) == 0) {
        if (strcmp((char*)data, "omnipresent") == 0) {
            UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_CHANGE_WORKSPACE);
        } else {
            UpdateSwitchMenu(wwin->screen_ptr, wwin, ACTION_CHANGE_STATE);
        }
    }
}


static void
wsobserver(void *self, WMNotification *notif)
{
    WScreen *scr = (WScreen*)WMGetNotificationObject(notif);
    const char *name = WMGetNotificationName(notif);
    void *data = WMGetNotificationClientData(notif);

    if (strcmp(name, WMNWorkspaceNameChanged) == 0) {
        UpdateSwitchMenuWorkspace(scr, (int)data);
    } else if (strcmp(name, WMNWorkspaceChanged) == 0) {

    }
}

