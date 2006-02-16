/* winspector.h - window attribute inspector header file
 *
 *  Window Maker window manager
 *
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

#ifndef WINSPECTOR_H_
#define WINSPECTOR_H_

#include "window.h"

void wShowInspectorForWindow(WWindow *wwin); /* winmenu.m */

void wHideInspectorForWindow(WWindow *wwin); /* actions.m */

void wUnhideInspectorForWindow(WWindow *wwin); /* actions.m */

void wDestroyInspectorPanels(); /* shutdown.m */

WWindow *wGetWindowOfInspectorForWindow(WWindow *wwin); /* actions.m */

void wCloseInspectorForWindow(WWindow *wwin); /* window.m, winspector.m */

#endif
