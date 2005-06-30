/*
	PKToolbarPreferencesController.m

	Preferences controller subclass with preference panes listed in a toolbar

	Copyright (C) 2005 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-interent.fr>
	Date:  February 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>
#import "PKPrefPanesRegistry.h"
#import "PKToolbarPreferencesController.h";
/* We need to redeclare this PKPreferencesController variable because static 
   variables are not inherited unlike class variables in other languages. */
//static PKPreferencesController *sharedInstance = nil;


@implementation PKToolbarPreferencesController

/*
 * Overriden methods
 */

- (void) initUI
{
	preferencesToolbar = [[NSToolbar alloc] initWithIdentifier: @"PrefsWindowToolbar"];
    
    [super initUI];
    
	[preferencesToolbar setDelegate: self];
	[preferencesToolbar setAllowsUserCustomization: NO];
    if ([owner isKindOfClass: [NSWindow class]])
    {
        [(NSWindow *)owner setToolbar: preferencesToolbar];
    }
    else
    {
        NSLog(@"Preferences panes cannot be listed in a toolbar when owner is \
            not an NSWindow instance.");
        [preferencesToolbar release];
    }
	
    //inited = YES;
	
	//NSDebugLog(@"UI inited");
}

- (NSView *) preferencesListView
{
    return nil;
}

/*
 * Toolbar delegate methods
 */

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
      itemForItemIdentifier:(NSString*)identifier
  willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
    NSToolbarItem *toolbarItem = 
        [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    NSArray *plugins = [[PKPrefPaneRegistry sharedRegistry] loadedPlugins];
    NSArray *bundles = [plugins valueForKey: @"bundle"];
	NSDictionary *info = [bundles objectWithValue: identifier forKey: @"bundleIdentifier"];

	[toolbarItem setLabel: [info objectForKey: @"name"]];
	[toolbarItem setImage: [info objectForKey: @"image"]];
	
    [toolbarItem setTarget: self];
    [toolbarItem setAction: @selector(switchView:)];
    
	return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar 
{
    return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar 
{    
    NSArray *plugins = [[PKPrefPaneRegistry sharedRegistry] loadedPlugins];
	NSArray *identifiers = [[plugins valueForKey: @"bundle"] valueForKey: @"bundleIdentifier"];
    
    return identifiers;
}

- (NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar 
{    
	return [self toolbarAllowedItemIdentifiers: toolbar];
}

@end
