/*
	PKApplicationController.m

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PKApplicationController.h"
#import "PKBundleController.h"
#import "PKPreferencesController.h"

static NSUserDefaults *defaults = nil;
static BOOL doneLaunching = NO;


@implementation PKApplicationController

+ (void) initialize
{
	defaults = [NSUserDefaults standardUserDefaults];
}

- (id) init
{
	if ((self = [super init]) != nil)
	{
		return self;
	}
	
	return nil;
}

/*
 * Action methods
 */
 
- (void) open: (id)sender;
{
	PKBundleController	*bundler = [PKBundleController sharedBundleController];
	int					result;
	NSArray				*fileTypes = [NSArray arrayWithObjects: @"prefPane", @"prefs", nil];
	NSOpenPanel			*oPanel = [NSOpenPanel openPanel];

	[oPanel setAllowsMultipleSelection: NO];
	[oPanel setCanChooseFiles: YES];
	[oPanel setCanChooseDirectories: NO];

	result = [oPanel runModalForDirectory: NSHomeDirectory() file: nil types: fileTypes];
	if (result == NSOKButton) /* Got a new dir */
	{
		NSArray	*pathArray = [oPanel filenames];

		[bundler loadBundleWithPath: [pathArray objectAtIndex: 0]];
	}
}

/*
 * Delegate methods
 */

- (BOOL) application: (NSApplication *)app openFile: (NSString *)filename
{
	PKBundleController *bundleManager = [PKBundleController sharedBundleController];

	return [bundleManager loadBundleWithPath: filename];
}

- (BOOL) applicationShouldTerminate: (NSApplication *)app;
{
	return YES;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)app;
{
	return YES;
}

/*
 * Notifications methods
 */

/* Sent when the app has finished starting up */
- (void) applicationDidFinishLaunching: (NSNotification *)notif;
{
	if ([defaults boolForKey: @"autolaunch"]) 
	{
		[NSApp hide: self];
	} 
	else 
	{
		[[prefsController window] makeKeyAndOrderFront: self];
	}
}

// Sent when the app is just about to complete its startup
- (void) applicationWillFinishLaunching: (NSNotification *)notif;
{
	NSMenu *menu = [NSApp mainMenu];

	// [menu setTitle: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"ApplicationName"]];

	NSDebugLog (@"Windows");
	[NSApp setWindowsMenu: [[menu itemWithTitle: _(@"Windows")] submenu]];

	NSDebugLog (@"Services");
	[NSApp setServicesMenu: [[menu itemWithTitle: _(@"Services")] submenu]];

	/*
	 * This should work, but doesn't because GNUstep starts apps hidden and
	 * unhides them between -applicationWillFinishLaunching: and
	 * -applicationDidFinishLaunching:
	 */
	if ([defaults boolForKey: @"autolaunch"])
		[NSApp hide: self];
}

/* 
 * Check whether the prefs controller window is visible, and if not, order it
 * front.
 */
- (void) applicationDidUnhide: (NSNotification *) not;
{
	if (doneLaunching && [[prefsController window] isVisible] == NO)
		[[prefsController window] makeKeyAndOrderFront: self];
}

- (void) applicationWillTerminate: (NSNotification *) notification;
{

}

/*
 * Accessors
 */

- (void) setPreferencesController: (PKPreferencesController *)controller
{
	ASSIGN(prefsController, controller);
}

- (PKPreferencesController *) preferencesController
{
	return prefsController;
}

@end
