/*
	PKPreferencesController.h

	Preferences window controller class

	Copyright (C) 2001 Dusk to Dawn Computing, Inc. 
	              2004 Quentin Mathe

	Author: Jeff Teunissen <deek@d2dc.net>
	        Quentin Mathe <qmathe@club-internet.fr>

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

@class NSNotification, NSView, NSWindow;
@protocol PrefsController, PrefsModule;


@interface PKPreferencesController: NSObject <PrefsController>
{
	IBOutlet id	window;
	IBOutlet id	owner;
}

+ (PKPreferencesController *) sharedPrefencesController;

/*
 * Accessors
 */

- (NSWindow *) window;

/*
 * Notifications
 */

- (void) windowWillClose: (NSNotification *)aNotification;

/*
 * Preferences UI related stuff
 */

- (void) initUI;
- (void) updateUIForPreferencesModule: (id <PrefsModule>)module;
- (NSView *) preferencesMainView;

@end
