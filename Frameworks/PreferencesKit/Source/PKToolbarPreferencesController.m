/*
	PreferencesController.m

	Preferences window controller class

	Copyright (C) 2001 Dusk to Dawn Computing, Inc.

	Author: Jeff Teunissen <deek@d2dc.net>
	Date:	11 Nov 2001

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

@implementation PKToolbarPreferencesController

static PreferencesController	*sharedInstance = nil;
static NSMutableDictionary	*modules = nil;
static id		currentModule = nil;
static BOOL 		inited = NO;

/*
 * Preferences window UI stuff
 */

- (void) initUI
{
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"PrefsWindowToolbar"];
	
	[toolbar setDelegate: self];
	[toolbar setAllowsUserCustomization: NO];
	[window setToolbar: toolbar];
	inited = YES;
	
	NSDebugLog(@"UI inited");
}

- (NSView *) preferencesMainView
{
	return [window contentViewWithoutToolbar];
}

// Toolbar delegate methods

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString*)identifier
  willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc]
    initWithItemIdentifier:identifier];
	id module = [modules objectForKey: identifier];
	
	AUTORELEASE(toolbarItem);

	[toolbarItem setLabel: [module buttonCaption]];
	[toolbarItem setImage: [module buttonImage]];
	if (![module buttonAction])
	{
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(switchView:)];
	}
	else {
		[toolbarItem setTarget: module];
		[toolbarItem setAction: [module buttonAction]];
	}
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar {
	return [modules allKeys];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar {    
	return [modules allKeys];
}

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar {    
	return [modules allKeys];
}

@end
