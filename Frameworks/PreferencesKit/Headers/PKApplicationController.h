/*
	PKApplicationController.h

	Application controller class

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

#ifndef __PreferencesKit_ApplicationController__
#define __PreferencesKit_ApplicationController__

#include <PrefsModule/PrefsModule.h>

@class NSNotification, NSString, NSApplication;
@class PKPreferencesController;


@interface Controller: NSObject <PKPreferencesApplication>
{
	PKPreferencesController  *prefsController;
}

/*
 * Application delegate methods
 */

- (BOOL) application: (NSApplication *)app openFile: (NSString *)filename;
- (BOOL) applicationShouldTerminate: (NSApplication *)app;
- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)app;

/*
 * Notifications
 */

- (void) applicationDidFinishLaunching: (NSNotification *)notification;
- (void) applicationWillFinishLaunching: (NSNotification *)notification;
- (void) applicationWillTerminate: (NSNotification *)notification;

/*
 * Action methods
 */

- (IBAction) open: (id)sender;

/*
 * Accessors
 */

- (void) setPreferencesController: (PKPreferencesController *)aPrefsController;
- (PKPreferencesController *) preferencesController;

@end

#endif /* __PreferencesKit_ApplicationController__ */
