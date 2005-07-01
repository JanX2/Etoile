/*
	PKTableViewPreferencesController.m
 
	Preferences controller subclass with preference panes listed in a table bview
 
	Copyright (C) 2005 Quentin Mathe    
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2005
 
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
#import "PKTableViewPreferencesController.h"

/* We need to redeclare this PKPreferencesController variable because static 
variables are not inherited unlike class variables in other languages. */
//static PKPreferencesController *sharedInstance = nil;


@implementation PKTableViewPreferencesController

/*
 * Overriden methods
 */

- (void) initUI
{
    [super initUI];
    
	//inited = YES;
	
	//NSDebugLog(@"UI inited");
}

- (NSView *) preferencesListView
{
    return preferencesTableView;
}

/*
 * Table view delegate methods
 */

- (int) numberOfRowsInTableView: (NSTableView *)tableView
{
	int count = [[[PKPrefPanesRegistry sharedRegistry] loadedPlugins] count];
    
    return count;
}


- (id) tableView: (NSTableView*)tableView objectValueForTableColumn: (NSTableColumn *)tableColumn row: (int)row
{
	NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins]; 
    NSDictionary *info = [plugins objectAtIndex: row];
	
	return [info objectForKey: @"Name"];
}


- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
	int row = [preferencesTableView selectedRow];
	NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    NSString *path = (NSString *)[[plugins objectAtIndex: row] objectForKey: @"path"];
	
	[self updateUIForPreferencePane: [[PKPrefPanesRegistry sharedRegistry] preferencePaneAtPath: path]];
}

@end
