/*
	PKTableViewPresentation.m
 
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
#import "CocoaCompatibility.h"
#import "PKPreferencesController.h"
#import "PKPrefPanesRegistry.h"
#import "PKTableViewPreferencesController.h"

extern const NSString *PKTablePresentationMode;


@implementation PKTableViewPresentation

/*
 * Overriden methods
 */

- (void) loadUI
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    NSView *mainViewContainer = [pc preferencesView];
    
    /* We use a completely prebuilt table view we retrieve in a dedicated gorm file
       to avoid the nightmare to set up it manually in code with every elements it
       includes like corner view, scroll view etc. */

    [prebuiltTableView removeFromSuperview];
    
    [prebuiltTableView setFrameSize: NSMakeSize(100, [mainViewContainer frame].size.height)];
    [prebuiltTableView setFrameOrigin: NSMakePoint(0, 0)];
    [mainViewContainer addSubview: prebuiltTableView];
    
    /* Finish table view specific set up. */
    [preferencesTableView setDataSource: self];
    [preferencesTableView setDelegate: self];
    [preferencesTableView reloadData];
    
    [super loadUI];
}

- (void) unloadUI
{
    [prebuiltTableView removeFromSuperview];
}

- (NSString *) presentationMode
{
    return (NSString *)PKTablePresentationMode;
}

- (NSView *) presentationView
{
    return prebuiltTableView;
}

- (void) resizePreferencesViewForView: (NSView *)paneView
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    NSView *mainViewContainer = [pc preferencesView];
    
    /* Resize window so content area is large enough for prefs. */
    
	/* NSRect box = [mainViewContainer frame];
	NSRect wBox = [[mainViewContainer window] frame];
	NSSize lowerRightDist;
    
	lowerRightDist.width = wBox.size.width -(box.origin.x +box.size.width);
	lowerRightDist.height = wBox.size.height -(box.origin.y +box.size.height);
	
	box.size.width = lowerRightDist.width +box.origin.x +[theView frame].size.width;
	box.size.height = lowerRightDist.height +box.origin.y +[theView frame].size.height;
	box.origin.x = wBox.origin.x;
	box.origin.y = wBox.origin.y -(box.size.height -wBox.size.height); */
    
    NSRect tableFrame = [prebuiltTableView frame];
    NSRect paneFrame = [paneView frame];
    NSRect windowFrame;
    
    tableFrame.size.height = paneFrame.size.height;
    paneFrame.origin.x = tableFrame.origin.x + tableFrame.size.width;
    paneFrame.origin.y = 0;
    windowFrame.size.width = tableFrame.size.width + paneFrame.size.width;
    windowFrame.size.height = paneFrame.size.height;
    
	[[mainViewContainer window] setFrame: windowFrame display: YES animate: YES];
}

- (IBAction) switchPreferencePaneView: (id)sender
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    int row = [preferencesTableView selectedRow];
	NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    NSString *path = [[plugins objectAtIndex: row] identifier];
    
    [pc selectPreferencePaneWithIdentifier: path];
}

/*
 * Preferences controller delegate methods
 */

- (void) didSelectPreferencePaneWithIdentifier: (NSString *)identifier
{    
	NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    NSDictionary *info = [plugins objectWithValue: identifier forKey: @"path"];
    int row = [plugins indexOfObject: info];
    
    [preferencesTableView selectRow: row byExtendingSelection: NO];
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
	PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    int row = [preferencesTableView selectedRow];
	NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    NSString *path = (NSString *)[[plugins objectAtIndex: row] objectForKey: @"path"];
	
	[pc updateUIForPreferencePane: [[PKPrefPanesRegistry sharedRegistry] preferencePaneAtPath: path]];
}

@end
