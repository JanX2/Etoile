/*
    BundleExtensionLoader.h

    Declaration of the EtoileSystemBarEntry protocol for the
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

@protocol NSMenuItem;
@class NSString;

/**
 * The protocol to which Etoile system bar entries must conform.
 *
 * The system bar is the menu which pops up when the user clicks the
 * Etoile logo in the menubar. EtoileMenuServer loads these at startup
 * time so that the user can add his/her own entries.
 *
 * This protocol declares methods which system bar entries must implement
 * in order to be usable within EtoileMenuServer.
 */
@protocol EtoileSystemBarEntry

/**
 * Must return the system bar entry's menu item. This item will be inserted
 * into the system bar and may be customized to any looks and behavior that
 * the system bar entry sees fit.
 *
 * @return An object conforming to NSMenuItem, which will be inserted into
 * the system bar.
 */
- (id <NSMenuItem>) menuItem;

/**
 * Must return the entry's menu group. All entries in the menu are grouped
 * together based on their group, whereby groups are separated by menu item
 * separators. Thus, entries with the same menu group name appear visually
 * grouped together.
 *
 * In case the system bar entry doesn't want to declare a group of it's own
 * (e.g. it isn't such a big, important thing, which would justify to
 * separate it into it's own group), it can return `nil' here, so it will be
 * put into an implicit 'ungrouped' group at the end of the menu, just above
 * the 'Log Out' menu item.
 *
 * @return A string which specifies to which group of system bar entries
 * this entry belongs, or `nil' in case it doesn't belong in any particular
 * group.
 */
- (NSString *) menuGroup;

@end
