/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "DatabaseOperations.h"

#import "Feed.h"
#import "Database.h"
#import "NSBundle+Extensions.h"


#define DELETE_IDENTIFIER @"DB.Ops.Delete"
#define SUBSCRIBE_IDENTIFIER @"Feed.Ops.Subscribe"
#define ADD_CATEGORY_IDENTIFIER @"DB.Ops.AddCategory"
#define FETCH_IDENTIFIER @"Feed.Ops.Fetch"
#define FETCH_ALL_IDENTIFIER @"Feed.Ops.FetchAll"

@implementation DatabaseOperationsComponent

- (id) init
{
    if ((self = [super init]) != nil) {
        // ------------------------------
        // Toolbar items
        // ------------------------------
        
        // Feed fetching items
        fetchItem = [[NSToolbarItem alloc] initWithItemIdentifier: FETCH_IDENTIFIER];
        [fetchItem setLabel: _(@"Fetch feed")];
        [fetchItem setImage: [NSImage imageNamed: @"FetchFeed"]];
        [fetchItem setAction: @selector(fetchSelectedFeeds)];
        [fetchItem setTarget: self];
        
        fetchAllItem = [[NSToolbarItem alloc] initWithItemIdentifier: FETCH_ALL_IDENTIFIER];
        [fetchAllItem setLabel: _(@"Fetch all")];
        [fetchAllItem setImage: [NSImage imageNamed: @"FetchFeeds"]];
        [fetchAllItem setAction: @selector(fetchAllFeeds)];
        [fetchAllItem setTarget: self];
        
        // "Add feed" item
        subscribeItem = [[NSToolbarItem alloc] initWithItemIdentifier: DELETE_IDENTIFIER];
        [subscribeItem setLabel: _(@"Subscribe")];
        [subscribeItem setImage: [NSImage imageNamed: @"AddFeed"]];
        [subscribeItem setAction: @selector(subscribeFeed)];
        [subscribeItem setTarget: self];
        
        // "Add category" item
        addCategoryItem = [[NSToolbarItem alloc] initWithItemIdentifier: ADD_CATEGORY_IDENTIFIER];
        [addCategoryItem setLabel: _(@"New category")];
        [addCategoryItem setImage: [NSImage imageNamed: @"AddCategory"]];
        [addCategoryItem setAction: @selector(addCategory)];
        [addCategoryItem setTarget: self];
        
        // Feed deletion item
        deleteItem = [[NSToolbarItem alloc] initWithItemIdentifier: DELETE_IDENTIFIER];
        [deleteItem setLabel: _(@"Delete")];
        [deleteItem setImage: [NSImage imageNamed: @"DeleteFeed"]];
        [deleteItem setAction: @selector(deleteSelectedElements)];
        [deleteItem setTarget: self];
        
        
        // ----------------------------
        // Menu items
        // ----------------------------
        
        // Feed fetching menu items
        fetchMenuItem = [[NSMenuItem alloc] initWithTitle: _(@"Fetch feed")
                                                   action: @selector(fetchSelectedFeeds)
                                            keyEquivalent: @""];
        [fetchMenuItem setTarget: self];
        
        fetchAllMenuItem = [[NSMenuItem alloc] initWithTitle: _(@"Fetch all")
                                                      action: @selector(fetchAllFeeds)
                                               keyEquivalent: @""];
        [fetchAllMenuItem setTarget: self];
        
        // "Subscribe to feed" menu item
        subscribeMenuItem = [[NSMenuItem alloc] initWithTitle: _(@"Subscribe to URL...")
                                                 action: @selector(subscribeFeed)
                                          keyEquivalent: @""];
        [subscribeMenuItem setTarget: self];
        
        // "Delete feed" menu item
        deleteMenuItem = [[NSMenuItem alloc] initWithTitle: _(@"Delete feed")
                                                    action: @selector(deleteSelectedFeeds)
                                             keyEquivalent: @"r"];
        [deleteMenuItem setTarget: self];
        
        // FIXME: Add category item
        
        // Link with main menu
        NSMenu* feedMenu = [[[NSMenu alloc] init] autorelease];
        [feedMenu addItem: fetchAllMenuItem];
        [feedMenu addItem: fetchMenuItem];
        [feedMenu addItem: subscribeMenuItem];
        [feedMenu addItem: deleteMenuItem];
        
        [[NSApp mainMenu] setSubmenu: feedMenu forItem:
            [[NSApp mainMenu] itemWithTitle: NSLocalizedString(
                @"Feed",
                @"The name of the Feed menu entry. It's important that this is the same "
                @"name as in the Gorm file, otherwise the menu will not be filled."
                )]];
        
        // -------------------------------------
        // Prepare toolbar delegation
        // -------------------------------------
        NSArray* identifiers = [NSArray arrayWithObjects:
            FETCH_ALL_IDENTIFIER,
            FETCH_IDENTIFIER,
            SUBSCRIBE_IDENTIFIER,
            ADD_CATEGORY_IDENTIFIER,
            DELETE_IDENTIFIER,
            nil
        ];
        ASSIGN(allowedIdentifiers, identifiers);
        ASSIGN(defaultIdentifiers, allowedIdentifiers);
        
        // Init selected feeds with empty set
        ASSIGN(selectedFeeds, [NSSet new]);
    }
    
    return self;
}

// input accepting component protocol

-(void)componentDidUpdateSet: (NSNotification*) aNotification
{
    id<OutputProvidingComponent> component = [aNotification object];
    
    ASSIGN(selectedFeeds, [component objectsForPipeType: [PipeType feedType]]);
    ASSIGN(selectedElements, [component objectsForPipeType: [PipeType databaseElementType]]);
    
    // Using anyObject is appropriate, as there can only be one selected element.
    ASSIGN(
        subscriptionReferenceElement,
        [selectedElements anyObject]
    );
    
    // set the new insertion reference element for the subscription panel
    if (subscriptionPanel != nil) {
        [subscriptionPanel setReferenceElement: subscriptionReferenceElement];
    }
    
    // update the image for the delete item
    if ([selectedFeeds count] > 0) {
        [deleteItem setImage: [NSImage imageNamed: @"DeleteFeed"]];
    } else {
        [deleteItem setImage: [NSImage imageNamed: @"DeleteCategory"]];
    }
    
    // change the enabled state for the feed operation items
    BOOL isEnabled = ([selectedFeeds count] > 0) ? YES : NO;
    [fetchItem setEnabled: isEnabled];
    [deleteMenuItem setEnabled: isEnabled];
    [fetchMenuItem setEnabled: isEnabled];
    
    isEnabled = ([selectedElements count] > 0) ? YES : NO;
    [deleteItem setEnabled: isEnabled];
}

// toolbar delegate protocol

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
    if ([itemIdentifier isEqualToString: DELETE_IDENTIFIER]) {
        return deleteItem;
    } else if ([itemIdentifier isEqualToString: FETCH_IDENTIFIER]) {
        return fetchItem;
    } else if ([itemIdentifier isEqualToString: SUBSCRIBE_IDENTIFIER]) {
        return subscribeItem;
    } else if ([itemIdentifier isEqualToString: ADD_CATEGORY_IDENTIFIER]) {
        return addCategoryItem;
    } else if ([itemIdentifier isEqualToString: FETCH_ALL_IDENTIFIER]) {
        return fetchAllItem;
    }
    
    return nil; // identifier not found, possibly fall back on other toolbar delegates
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
    return allowedIdentifiers;
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
    return defaultIdentifiers;
}

// own methods

- (void) deleteSelectedElements
{
    NSEnumerator* enumerator = [selectedElements objectEnumerator];
    id <DatabaseElement> elem;
    
    while ((elem = [enumerator nextObject]) != nil) {
        [[Database shared] removeElement: elem];
    }
}

- (void) fetchSelectedFeeds
{
    NSEnumerator* enumerator = [selectedFeeds objectEnumerator];
    id <Feed> feed;
    
    while ((feed = [enumerator nextObject]) != nil) {
        [feed fetchInBackground];
    }
}

- (void) fetchAllFeeds
{
    [[Database shared] fetchAllFeeds];
}

- (void) subscribeFeed
{
    if (subscriptionPanel == nil) {
        ASSIGN(
            subscriptionPanel,
            [NSBundle instanceForBundleWithName: @"SubscriptionPanel"]
        );
    }
    
    [subscriptionPanel setReferenceElement: subscriptionReferenceElement];
    [subscriptionPanel show];
}

-(void) addCategory
{
    NSString* name = @"New category";
    BOOL result;
    id<Database> db = [Database shared];
    
    if (subscriptionReferenceElement == nil) {
        result = [db addCategoryNamed: name
                           inCategory: nil];
    } else {
        if ([subscriptionReferenceElement conformsToProtocol: @protocol(Category)]) {
            id<Category> cat = subscriptionReferenceElement;
            result = [db addCategoryNamed: name
                               inCategory: cat
                                 position: [[cat elements] count]];
        } else {
            NSAssert(
                [subscriptionReferenceElement conformsToProtocol: @protocol(DatabaseElement)],
                @"Bad subscription reference element"
            );
            
            id<Category> cat = [subscriptionReferenceElement superElement];
            int index;
            
            if (cat == nil) {
                index = [[db topLevelElements] indexOfObject: subscriptionReferenceElement];
            } else {
                index = [[cat elements] indexOfObject: subscriptionReferenceElement];
            }
            
            NSAssert1(
                index != NSNotFound,
                @"%@ db element is badly linked (bad super element)",
                subscriptionReferenceElement
            );
            
            result = [db addCategoryNamed: name
                               inCategory: cat
                                 position: index];
        }
    }
    
    NSAssert(result == YES, @"Category creation failed!");
}

@end

