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
#import "PKTableViewPresentation.h"

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
    
    BOOL nibLoaded = [NSBundle loadNibNamed: @"PrebuiltTableView" owner: self];
    
    if (nibLoaded == NO)
        [NSException raise: @"PKTableViewPresentationException"
            format: @"Impossible to load PrebuiltTableView nib"];
    
    if (prebuiltTableView == nil)
        [NSException raise: @"PKTableViewPresentationException"
            format: @"PrebuiltTableView is nil"];

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

// FIXME: Actual code in this method have to be improved to work when
// preferencesView is not equal to contentView and we should move some portions
// common with other presentation classes in PKPresentationBuilder superclass.
- (void) resizePreferencesViewForView: (NSView *)paneView
{
 	PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    NSView *mainView = [pc preferencesView];
    NSRect paneFrame = [paneView frame];
    NSRect tableFrame = [prebuiltTableView frame];
	NSRect windowFrame = [[mainView window] frame];
    NSRect contentFrame = NSZeroRect;
    int previousHeight = windowFrame.size.height;
    int heightDelta;
    
    [super resizePreferencesViewForView: paneView];
    
    /* Resize window so content area is large enough for prefs. */
    
    tableFrame.size.height = paneFrame.size.height;
    paneFrame.origin.x = tableFrame.size.width;
    paneFrame.origin.y = 0;
    [prebuiltTableView setFrame: tableFrame];
    [paneView setFrame: paneFrame];
    
    contentFrame.size.width = tableFrame.size.width + paneFrame.size.width;
    contentFrame.size.height = paneFrame.size.height;
    
    // FIXME: Implement -frameRectForContentRect: in GNUstep 
    windowFrame.size = [NSWindow frameRectForContentRect: contentFrame
        styleMask: [[mainView window] styleMask]].size;
    
    // NOTE: We have to check carefully the view is not undersized to avoid
    // limiting switch possibilities in listed panes.
    if (windowFrame.size.height < 150)
        windowFrame.size.height = 150;
    if (windowFrame.size.width < 400)
        windowFrame.size.width = 400;
    
    /* We take in account the fact the origin is located at bottom left corner. */
    heightDelta = previousHeight - windowFrame.size.height;
    windowFrame.origin.y += heightDelta;
    
	[[mainView window] setFrame: windowFrame display: YES animate: YES];
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
