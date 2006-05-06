/*
    EtoileMenulet.h

    Interface declaration of the EtoileMenulet protocol for the
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

#import <Foundation/NSObject.h>

@class NSView;

/**
 * The protocol to which Etoile menulets must conform.
 *
 * A menulet, in Etoile speak, is a small object which is displayed in the
 * menubar's right-most area (around the clock, among other stuff).
 * EtoileMenuServer loads these at startup time from bundles, so you can
 * program your own menulets.
 *
 * This protocol declares the methods which a menulet must implement
 * in order to be usable for EtoileMenuServer.
 */
@protocol EtoileMenulet

/**
 * Must return the menulet's view. This view will be put into the menubar,
 * and the menulet is free to customize it's behavior in any way it wishes
 * to.
 *
 * @return A view which will be put into the menubar.
 */
- (NSView *) menuletView;

@end
