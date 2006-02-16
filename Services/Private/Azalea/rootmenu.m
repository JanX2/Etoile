// Modified by Yen-Ju Chen <yjchenx at gmail>
/* rootmenu.c- user defined menu
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

#include "screen.h"
#include <AppKit/AppKit.h>

void
OpenRootMenu(WScreen *scr, int x, int y, int keyboard)
{
    // FIXME: 1. should prevent menu outside the screen.
    //        2. it does not behave well in every condition.
    NSMenu *menu = [NSApp mainMenu];
    NSView <NSMenuView> *view = [menu menuRepresentation];
    NSWindow * window = [view window];
    if ([window isVisible]) // should use better way to tell
    {
      /* Close all submenus */
      id <NSMenuItem> item;
      int index;
      while(1)
      {
	index = [view highlightedItemIndex]; // get highlighted item
	[view setHighlightedItemIndex: -1];
	[window orderOut: nil];
	if (index < 0)
	{
	  // Not highlighted item;
	  break;
	}
        item = [menu itemAtIndex: index];
	menu = [item submenu];
	if (menu == nil)
	{
	  // No submenu
	  break;
	}
	else
	{
	  view = [menu menuRepresentation];
	  window = [view window];
	  continue;
	}
      }
    }
    else
    {
      /* This fix the problem when open menu on one workspace
       * and open again on another workspace
       */
      [view setHighlightedItemIndex: -1]; 

      /* Shift one pixel so a second click can close menu */
      NSPoint point = NSMakePoint(x+1, scr->scr_height-y+1);
      [window setFrameTopLeftPoint: point];
      [window makeKeyAndOrderFront: nil];
    }
}


