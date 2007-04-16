/*
    MenuBarView.h

    Interface declaration of the MenuBarView class for the
    EtoileMenuServer application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import <AppKit/NSView.h>

/**
 * The view which fills the menubar window.
 */
@interface MenuBarView : NSView
{
  /**
   * The menu for the system bar.
   */
  NSMenu * systemMenu;

  BOOL systemLogoPushedIn;
}

/* Return the minimal size to display menu bar. It is etoile log only */
- (NSSize) minimalSize;

@end
