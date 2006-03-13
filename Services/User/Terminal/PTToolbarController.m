/*
 **  PTToolbarController.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: manages an the toolbar.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import "PTToolbarController.h"
#import "iTermController.h"
#import "PseudoTerminal.h"

NSString *NewToolbarItem = @"New";
NSString *BookmarksToolbarItem = @"Bookmarks";
NSString *CloseToolbarItem = @"Close";
NSString *ConfigToolbarItem = @"Config";

@interface PTToolbarController (Private)
- (void)setupToolbar;
- (void)buildToolbarItemPopUpMenu:(NSToolbarItem *)toolbarItem forToolbar:(NSToolbar *)toolbar;
- (NSToolbarItem*)toolbarItemWithIdentifier:(NSString*)identifier;
@end

@implementation PTToolbarController

- (id)initWithPseudoTerminal:(PseudoTerminal*)terminal;
{
    self = [super init];
    
    _pseudoTerminal = terminal; // don't retain;
    
    // Add ourselves as an observer for notifications to reload the addressbook.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadAddressBookMenu:)
                                                 name: @"iTermReloadAddressBook"
                                               object: nil];
    
    [self setupToolbar];
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_toolbar release];
    [super dealloc];
}

- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray* itemIdentifiers= [[[NSMutableArray alloc]init] autorelease];
    
    [itemIdentifiers addObject: NewToolbarItem];
	[itemIdentifiers addObject: BookmarksToolbarItem];
    [itemIdentifiers addObject: ConfigToolbarItem];
    [itemIdentifiers addObject: NSToolbarSeparatorItemIdentifier];
    [itemIdentifiers addObject: NSToolbarCustomizeToolbarItemIdentifier];
    [itemIdentifiers addObject: CloseToolbarItem];
    [itemIdentifiers addObject: NSToolbarFlexibleSpaceItemIdentifier];
    
    return itemIdentifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray* itemIdentifiers = [[[NSMutableArray alloc]init] autorelease];
    
    [itemIdentifiers addObject: NewToolbarItem];
	[itemIdentifiers addObject: BookmarksToolbarItem];
    [itemIdentifiers addObject: ConfigToolbarItem];
    [itemIdentifiers addObject: NSToolbarCustomizeToolbarItemIdentifier];
    [itemIdentifiers addObject: CloseToolbarItem];
    [itemIdentifiers addObject: NSToolbarFlexibleSpaceItemIdentifier];
    [itemIdentifiers addObject: NSToolbarSpaceItemIdentifier];
    [itemIdentifiers addObject: NSToolbarSeparatorItemIdentifier];
    
    return itemIdentifiers;
}

- (NSToolbarItem *)toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSBundle *thisBundle = [NSBundle bundleForClass: [self class]];
    NSString *imagePath;
    NSImage *anImage;
    
    if ([itemIdent isEqual: CloseToolbarItem]) 
    {
        [toolbarItem setLabel: NSLocalizedStringFromTableInBundle(@"Close",@"iTerm", thisBundle, @"Toolbar Item: Close Session")];
        [toolbarItem setPaletteLabel: NSLocalizedStringFromTableInBundle(@"Close",@"iTerm", thisBundle, @"Toolbar Item: Close Session")];
        [toolbarItem setToolTip: NSLocalizedStringFromTableInBundle(@"Close the current session",@"iTerm", thisBundle, @"Toolbar Item Tip: Close")];
        imagePath = [thisBundle pathForResource:@"close"
                                         ofType:@"png"];
        anImage = [[NSImage alloc] initByReferencingFile: imagePath];
        [toolbarItem setImage: anImage];
        [anImage release];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(closeCurrentSession:)];
    }
    else if ([itemIdent isEqual: ConfigToolbarItem]) 
    {
        [toolbarItem setLabel: NSLocalizedStringFromTableInBundle(@"Configure",@"iTerm", thisBundle, @"Toolbar Item:Configure") ];
        [toolbarItem setPaletteLabel: NSLocalizedStringFromTableInBundle(@"Configure",@"iTerm", thisBundle, @"Toolbar Item:Configure") ];
        [toolbarItem setToolTip: NSLocalizedStringFromTableInBundle(@"Configure current window",@"iTerm", thisBundle, @"Toolbar Item Tip:Configure")];
        imagePath = [thisBundle pathForResource:@"config"
                                         ofType:@"png"];
        anImage = [[NSImage alloc] initByReferencingFile: imagePath];
        [toolbarItem setImage: anImage];
        [anImage release];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(showConfigWindow:)];
    } 
	else if ([itemIdent isEqual: BookmarksToolbarItem]) 
    {
        [toolbarItem setLabel: NSLocalizedStringFromTableInBundle(@"Bookmarks",@"iTerm", thisBundle, @"Toolbar Item: Bookmarks") ];
        [toolbarItem setPaletteLabel: NSLocalizedStringFromTableInBundle(@"Bookmarks",@"iTerm", thisBundle, @"Toolbar Item: Bookmarks") ];
        [toolbarItem setToolTip: NSLocalizedStringFromTableInBundle(@"Bookmarks",@"iTerm", thisBundle, @"Toolbar Item Tip: Bookmarks")];
        imagePath = [thisBundle pathForResource:@"addressbook"
                                         ofType:@"png"];
        anImage = [[NSImage alloc] initByReferencingFile: imagePath];
        [toolbarItem setImage: anImage];
        [anImage release];
        [toolbarItem setTarget: nil];
        [toolbarItem setAction: @selector(toggleBookmarksView:)];
    } 	
    else if ([itemIdent isEqual: NewToolbarItem])
    {
        NSPopUpButton *aPopUpButton;
        
        if([toolbar sizeMode] == NSToolbarSizeModeSmall)
            aPopUpButton = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(0.0, 0.0, 40.0, 24.0) pullsDown: YES];
        else
            aPopUpButton = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(0.0, 0.0, 48.0, 32.0) pullsDown: YES];
        
        [aPopUpButton setTarget: nil];
        [aPopUpButton setBordered: NO];
        [[aPopUpButton cell] setArrowPosition:NSPopUpArrowAtBottom];
        [toolbarItem setView: aPopUpButton];
        // Release the popup button since it is retained by the toolbar item.
        [aPopUpButton release];
        
        // build the menu
        [self buildToolbarItemPopUpMenu: toolbarItem forToolbar: toolbar];
        
        [toolbarItem setMinSize:[aPopUpButton bounds].size];
        [toolbarItem setMaxSize:[aPopUpButton bounds].size];
        [toolbarItem setLabel: NSLocalizedStringFromTableInBundle(@"New",@"iTerm", thisBundle, @"Toolbar Item:New")];
        [toolbarItem setPaletteLabel: NSLocalizedStringFromTableInBundle(@"New",@"iTerm", thisBundle, @"Toolbar Item:New")];
        [toolbarItem setToolTip: NSLocalizedStringFromTableInBundle(@"Open a new session",@"iTerm", thisBundle, @"Toolbar Item:New")];
    }
    else
        toolbarItem=nil;
    
    return toolbarItem;
}

@end

@implementation PTToolbarController (Private)

- (void)setupToolbar;
{        
    _toolbar = [[NSToolbar alloc] initWithIdentifier: @"Terminal Toolbar"];
    [_toolbar setVisible:true];
    [_toolbar setDelegate:self];
    [_toolbar setAllowsUserCustomization:YES];
    [_toolbar setAutosavesConfiguration:YES];
    [_toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    [_toolbar insertItemWithItemIdentifier: NewToolbarItem atIndex:0];
    [_toolbar insertItemWithItemIdentifier: ConfigToolbarItem atIndex:1];
    [_toolbar insertItemWithItemIdentifier: NSToolbarFlexibleSpaceItemIdentifier atIndex:2];
    [_toolbar insertItemWithItemIdentifier: NSToolbarCustomizeToolbarItemIdentifier atIndex:3];
    [_toolbar insertItemWithItemIdentifier: NSToolbarSeparatorItemIdentifier atIndex:4];
    [_toolbar insertItemWithItemIdentifier: CloseToolbarItem atIndex:5];
    
    [[_pseudoTerminal window] setToolbar:_toolbar];
    
}

- (void)buildToolbarItemPopUpMenu:(NSToolbarItem *)toolbarItem forToolbar:(NSToolbar *)toolbar
{
    NSPopUpButton *aPopUpButton;
    NSMenuItem *item;
    NSMenu *aMenu;
    id newwinItem;
    NSString *imagePath;
    NSImage *anImage;
    NSBundle *thisBundle = [NSBundle bundleForClass: [self class]];
    BOOL newwin = [[NSUserDefaults standardUserDefaults] boolForKey:@"SESSION_IN_NEW_WINDOW"];
    
    if (toolbarItem == nil)
        return;
    
    aPopUpButton = (NSPopUpButton *)[toolbarItem view];
    //[aPopUpButton setAction: @selector(_addressbookPopupSelectionDidChange:)];
    [aPopUpButton setAction: nil];
    [aPopUpButton removeAllItems];
    [aPopUpButton addItemWithTitle: @""];

    aMenu = [[iTermController sharedInstance] buildAddressBookMenuWithTarget: (newwin?nil:_pseudoTerminal) withShortcuts: NO];
	[aPopUpButton setMenu: aMenu];
    
    [[aPopUpButton menu] addItem: [NSMenuItem separatorItem]];
    [[aPopUpButton menu] addItemWithTitle: NSLocalizedStringFromTableInBundle(@"Open in a new window",@"iTerm", [NSBundle bundleForClass: [self class]], @"Toolbar Item: New") action: @selector(toggleNewWindowState:) keyEquivalent: @""];
    newwinItem=[aPopUpButton lastItem];
    [newwinItem setTarget:self];    
    [newwinItem setState:(newwin ? NSOnState : NSOffState)];    
    
    // Now set the icon
    item = [[aPopUpButton cell] menuItem];
    imagePath = [thisBundle pathForResource:@"newwin"
                                     ofType:@"png"];
    anImage = [[NSImage alloc] initByReferencingFile: imagePath];
    [toolbarItem setImage: anImage];
    [anImage release];
    [anImage setScalesWhenResized:YES];
    if([toolbar sizeMode] == NSToolbarSizeModeSmall)
        [anImage setSize:NSMakeSize(24.0, 24.0)];
    else
        [anImage setSize:NSMakeSize(30.0, 30.0)];
    
    [item setImage:anImage];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [aPopUpButton setPreferredEdge:NSMinXEdge];
    [[[aPopUpButton menu] menuRepresentation] setHorizontalEdgePadding:0.0];
    
    // build a menu representation for text only.
    item = [[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTableInBundle(@"New",@"iTerm", [NSBundle bundleForClass: [self class]], @"Toolbar Item:New") action: nil keyEquivalent: @""];
    aMenu = [[iTermController sharedInstance] buildAddressBookMenuWithTarget: (newwin?nil:_pseudoTerminal) withShortcuts: NO];
    [aMenu addItem: [NSMenuItem separatorItem]];
    [aMenu addItemWithTitle: NSLocalizedStringFromTableInBundle(@"Open in a new window",@"iTerm", [NSBundle bundleForClass: [self class]], @"Toolbar Item: New") action: @selector(toggleNewWindowState:) keyEquivalent: @""];
    newwinItem=[aMenu itemAtIndex: ([aMenu numberOfItems] - 1)];
    [newwinItem setState:(newwin ? NSOnState : NSOffState)];
    [newwinItem setTarget:self];
    
    [item setSubmenu: aMenu];
    [toolbarItem setMenuFormRepresentation: item];
    [item release];
}

// Reloads the addressbook entries into the popup toolbar item
- (void)reloadAddressBookMenu:(NSNotification *)aNotification
{
    NSToolbarItem *aToolbarItem = [self toolbarItemWithIdentifier:NewToolbarItem];
    
    if (aToolbarItem )
        [self buildToolbarItemPopUpMenu: aToolbarItem forToolbar:_toolbar];
}

- (void)toggleNewWindowState: (id) sender
{
    BOOL set = [[NSUserDefaults standardUserDefaults] boolForKey:@"SESSION_IN_NEW_WINDOW"];
    [[NSUserDefaults standardUserDefaults] setBool:!set forKey:@"SESSION_IN_NEW_WINDOW"];    
    
    [self reloadAddressBookMenu: nil];
}

- (NSToolbarItem*)toolbarItemWithIdentifier:(NSString*)identifier
{
    NSArray *toolbarItemArray;
    NSToolbarItem *aToolbarItem;
    int i;
    
    toolbarItemArray = [_toolbar items];
    
    // Find the addressbook popup item and reset it
    for (i = 0; i < [toolbarItemArray count]; i++)
    {
        aToolbarItem = [toolbarItemArray objectAtIndex: i];
        
        if ([[aToolbarItem itemIdentifier] isEqual: identifier])
            return aToolbarItem;
    }

return nil;
}


@end
