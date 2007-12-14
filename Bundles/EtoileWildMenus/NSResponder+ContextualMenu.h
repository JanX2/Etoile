/*
   Copyright (C) 2007 Quentin Mathe.

   Author: Andreas Schik
   Date: December 2007

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#import <AppKit/NSResponder.h>
#import <AppKit/NSView.h>
#import <AppKit/NSMenu.h>

/* Allows to display transient version of main menu as in NeXTstep when no 
   contextal menu is available. */

@interface NSResponder (EtoileWildMenus)
+ (NSMenu *) defaultMenu;
@end

@interface NSView (EtoileWildMenus)
+ (NSMenu *) defaultMenu;
@end

