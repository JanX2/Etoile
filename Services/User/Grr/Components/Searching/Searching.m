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

#import "Searching.h"
#import "NSSet+ArticleFiltering.h"

#define IDENTIFIER @"Search"


/* allowed and default item identifiers */
static NSArray* itemIdentifiers = nil;


@interface SearchingComponent (Private)
-(void)_setOutputSet: (NSSet*)newOutputSet;
@end


@implementation SearchingComponent

// ------------------------------------------------
//    initialization
// ------------------------------------------------

- (id) init
{
    if ((self = [super init]) != nil) {
	toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: IDENTIFIER];
	searchField = [[NSSearchField alloc] initWithFrame: NSMakeRect(0, 0, 200, 22)];
	[searchField setRecentsAutosaveName: @"recent article searches"];
	[toolbarItem setView: searchField];
	[searchField setTarget: self];
	[searchField setAction: @selector(searchAction:)];
	[toolbarItem setLabel: NSLocalizedString(@"Search", @"search toolbar item label")];

	if (itemIdentifiers == nil) {
	    itemIdentifiers = [[NSArray alloc] initWithObjects:
	        NSToolbarFlexibleSpaceItemIdentifier,
	        IDENTIFIER,
	        nil
	    ];
	}
    }

    return self;
}


// ------------------------------------------------
//    toolbar delegate methods
// ------------------------------------------------

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
    if ([itemIdentifier isEqualToString: IDENTIFIER]) {
	return toolbarItem;
    } else {
	return nil;
    }
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
    return itemIdentifiers;
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{
    return itemIdentifiers;
}

// ------------------------------------------------
//    actual searching
// ------------------------------------------------

-(void) searchAction: (id)sender
{
	NSLog(@"search action");
	ASSIGN(searchString, [searchField stringValue]);
	
	[self _setOutputSet: [inputSet subsetFilteredForString: searchString]];
}


// ------------------------------------------------
//    input accepting component protocol
// ------------------------------------------------

-(void)componentDidUpdateSet: (NSNotification*) aNotification
{
	id<OutputProvidingComponent> component = [aNotification object];
	NSSet* newInputSet = [component objectsForPipeType: [PipeType articleType]];
	
	if ([newInputSet isSubsetOfSet: inputSet]) {
	    NSMutableSet* mutSet = [NSMutableSet setWithSet: newInputSet];
	    [mutSet intersectSet: outputSet];
	    [self _setOutputSet: mutSet];
	} else {
	    [self _setOutputSet: [newInputSet subsetFilteredForString: searchString]];
	}
	
	ASSIGN(inputSet, newInputSet);
}

// ------------------------------------------------
//    output stuff
// ------------------------------------------------

/**
 * Call this to change the output set. This method also
 * checks if the output set maybe didn't change and only
 * sends the change notification if it did.
 */
-(void)_setOutputSet: (NSSet*)newOutputSet
{
	// Note: For outputSet == nil, this evaluates to TRUE.
	if ([outputSet isEqualToSet: newOutputSet] == NO) {
		ASSIGN(outputSet, newOutputSet);
		
		NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
		[center postNotificationName: ComponentDidUpdateNotification
		                      object: self];
	}
}

-(NSSet*) objectsForPipeType: (id<PipeType>)aPipeType;
{
    NSAssert2(
        aPipeType == [PipeType articleType],
        @"%@ component does not support pipe type %@",
        self, aPipeType
    );

    if (outputSet != nil) {
	return [NSSet setWithSet: outputSet];
    } else {
        return [NSSet set];
    }
}

@end

