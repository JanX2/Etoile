/*
	PKTableViewPreferencesController.h
 
	Preferences window with table view controller class
 
	Copyright (C) 2005 Quentin Mathe
 
	Author: Quentin Mathe <qmathe@club-internet.fr>
	Date:	2005

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA
*/

@class NSNotification, NSWindow, NSView;
@protocol PrefsController;


@interface PKTableViewPreferencesController: NSObject <PrefsController>
{
	IBOutlet id	window;
	IBOutlet id	owner;
}

+ (PrefsController *) sharedPreferencesController;

/*
 * Accessors
 */

- (NSWindow *) window;

/* 
 * Notifications
 */

- (void) windowWillClose: (NSNotification *) aNotification;

/*
 * Preferences UI related stuff
 */

- (void) initUI;
- (void) updateUIForPreferencesModule: (id <PrefsModule>)module;
- (NSView *) preferencesMainView;

@end
