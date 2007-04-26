/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <IconKit/IconKit.h>
#import "Controller.h"
#import "SearchController.h"
#import "SearchView.h"
#import "DocumentTools.h"

/**
 * Non-Public methods.
 */

@interface NSToolbar (Vindaloo)
- (NSArray *) itemsForIdentifier: (NSString *)identifier;
- (NSToolbarItem *) itemForIdentifier: (NSString *)identifier;
- (NSToolbarItem *) visibleItemForIdentifier: (NSString *)identifier;
@end


@interface DocumentTools (Private)
//- (NSButton*) myCreateToggleButtonWithImage: (NSString*)anImageName;
@end


@implementation DocumentTools

- (id) initWithWindowController: (Controller *)aController target: (id)aTarget
{
	if (![super init])
		return nil;

	controller = aController;
	[self setTarget: aTarget];

	return self;
}

/* Toolbar delegate methods */

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar
	itemForItemIdentifier:(NSString*)identifier
	willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier: identifier];

   [item setTarget: target];

	if ([identifier isEqual: @"Back"]) 
	{
		[item setLabel: _(@"Previous Page")];
		//[item setImage: [NSImage imageNamed: @"Previous.png"]];
		[item setImage: [[IKIcon iconWithIdentifier: @"go-previous"] image]];
		[item setAction: @selector(previousPage:)];
	} 
	else if ([identifier isEqual: @"Forward"]) 
	{
		[item setLabel: _(@"Next Page")];
		//[item setImage: [NSImage imageNamed: @"Next.png"]];
		[item setImage: [[IKIcon iconWithIdentifier: @"go-next"] image]];
		[item setAction: @selector(nextPage:)];
	} 
	else if ([identifier isEqual: @"FirstPage"]) 
	{
		[item setLabel: _(@"First Page")];
		[item setImage: [NSImage imageNamed: @"First.png"]];
		[item setAction: @selector(firstPage:)];
	} 
	else if ([identifier isEqual: @"LastPage"]) 
	{
		[item setLabel: _(@"Last Page")];
		[item setImage: [NSImage imageNamed: @"Last.png"]];
		[item setAction: @selector(lastPage:)];
	}
	else if ([identifier isEqual: @"ZoomIn"]) 
	{
		[item setLabel: _(@"Zoom In")];
		//[item setImage: [NSImage imageNamed: @"ZoomIn.png"]];
		[item setImage: [[IKIcon iconWithIdentifier: @"zoom-in"] image]];
		[item setAction: @selector(zoomIn:)];
	}
	else if ([identifier isEqual: @"ZoomOut"]) 
	{
		[item setLabel: _(@"Zoom Out")];
		//[item setImage: [NSImage imageNamed: @"ZoomOut.png"]];
		[item setImage: [[IKIcon iconWithIdentifier: @"zoom-out"] image]];
		[item setAction: @selector(zoomOut:)];
	}
	else if ([identifier isEqual: @"FitPage"]) 
	{
		[item setLabel: _(@"Full Page")];
		[item setImage: [NSImage imageNamed: @"FitPage.png"]];
		[item setAction: @selector(toggleFitPage:)];
	}
	else if ([identifier isEqual: @"FitWidth"]) 
	{
		[item setLabel: _(@"Full Page Width")];
		[item setImage: [NSImage imageNamed: @"FitWidth.png"]];
		[item setAction: @selector(toggleFitWidth:)];
	}
	else if ([identifier isEqual: @"FitHeight"]) 
	{
		[item setLabel: _(@"Full Page Height")];
		[item setImage: [NSImage imageNamed: @"FitHeight.png"]];
		[item setAction: @selector(toggleFitHeight:)];
	}
	else if ([identifier isEqual: @"CurrentPage"]) 
	{
		NSTextField *fieldCurrentPage = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];

		[fieldCurrentPage setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[fieldCurrentPage setAlignment: NSCenterTextAlignment];
		[fieldCurrentPage sizeToFit];
		[fieldCurrentPage setFrameSize: NSMakeSize(40, NSHeight([fieldCurrentPage frame]))];

		[item setLabel: _(@"Page")];
		[item setView: fieldCurrentPage];
	}
	else if ([identifier isEqual: @"NumberOfPages"]) 
	{
		NSTextField *fieldPageNumber = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];

		[fieldPageNumber setEditable: NO];
		[fieldPageNumber setSelectable: NO];
		[fieldPageNumber setBordered: NO];
		[fieldPageNumber setBezeled: NO];
		[fieldPageNumber setDrawsBackground: NO];
		[fieldPageNumber setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
		[fieldPageNumber setAlignment: NSLeftTextAlignment];
		[fieldPageNumber setStringValue: @"of 9999"];
		[fieldPageNumber sizeToFit];
		[fieldPageNumber setAction: @selector(takePageFrom:)];
		[fieldPageNumber setTarget: target];

		[item setLabel: _(@"Number of Pages")];
		[item setView: fieldPageNumber];
	}
	else if ([identifier isEqual: @"ZoomFactor"]) 
	{
		NSTextField *fieldZoomFactor = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];

		[fieldZoomFactor setFont: [fieldZoomFactor font]];
		[fieldZoomFactor setAlignment: NSCenterTextAlignment];
		[fieldZoomFactor sizeToFit];
		[fieldZoomFactor setFrameSize: NSMakeSize(55, NSHeight([fieldZoomFactor frame]))];
		[fieldZoomFactor setAction: @selector(takeZoomFrom:)];
		[fieldZoomFactor setTarget: target];

		[item setLabel: _(@"Scale")];
		[item setView: fieldZoomFactor];
	}
	else if ([identifier isEqual: @"Search"]) 
	{
		SearchView *searchView = (SearchView *)[[controller searchController] searchView];

		[searchView setFrameSize: NSMakeSize(100, 22)];

		[item setLabel: _(@"Search")];
		[item setView: searchView];
	}
	else 
	{
		[item release];
		item = nil;

		/*NSAssert1(
		  [identifier isEqual: @"Search"],
		  @"Bad toolbar item requested: %@", identifier
		);*/
	}
	
	NSAssert1(
		item != nil,
		@"nil toolbar item returned for %@ identifier",
		identifier
	);

	return item;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar 
{
	NSArray *identifiers = [NSArray arrayWithObjects: @"Back", @"Forward", 
		@"CurrentPage", NSToolbarFlexibleSpaceItemIdentifier, @"ZoomFactor",
		@"ZoomIn", @"ZoomOut", @"FitWidth", NSToolbarSeparatorItemIdentifier, 
		@"Search", nil];

	return identifiers;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar 
{
	NSArray *identifiers = [NSArray arrayWithObjects: @"Back", @"Forward", 
		@"FirstPage", @"LastPage", @"CurrentPage", @"NumberOfPages", 
		@"ZoomFactor", @"ZoomIn", @"ZoomOut", @"FitWidth", @"FitHeight", 
		@"FitPage", @"Search", NSToolbarSeparatorItemIdentifier, 
		NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier, NSToolbarPrintItemIdentifier, 
		nil];

	return identifiers;
}

- (void) setTarget: (id)aTarget
{
	target = aTarget;
}

- (void) setPage: (int)aPage
{
	NSString *text = [NSString stringWithFormat: @"%d", aPage];
	NSToolbarItem *item = [[[controller window] toolbar] itemForIdentifier: @"CurrentPage"];
	
	[(NSTextField *)[item view] setStringValue: text];
}

- (void) setPageCount: (int)aPageCount
{
	NSString *text = [NSString stringWithFormat:@"of %d", aPageCount];
	NSToolbarItem *item = [[[controller window] toolbar] itemForIdentifier: @"NumberOfPages"];
	
	[(NSTextField *)[item view] setStringValue: text];
}

- (void) setZoom: (float)aFactor
{
	NSString* text = [NSString stringWithFormat: @"%.0f %%", aFactor];
	NSToolbarItem *item = [[[controller window] toolbar] itemForIdentifier: @"ZoomFactor"];
	
	[(NSTextField *)[item view] setStringValue: text];
}

- (void) setResizePolicy: (ResizePolicy)aPolicy
{
/* [fitWidthBT setState: (aPolicy == ResizePolicyFitWidth ? NSOnState : NSOffState)];
   [fitHeightBT setState: (aPolicy == ResizePolicyFitHeight ? NSOnState : NSOffState)];
   [fitPageBT setState: (aPolicy == ResizePolicyFitPage ? NSOnState : NSOffState)]; */
}

- (void) focusPageField
{
	NSToolbarItem *currentPageItem = [[[controller window] toolbar] 
		visibleItemForIdentifier: @"CurrentPage"];

	[[controller window] makeFirstResponder: [currentPageItem view]];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation DocumentTools (Private)

#if 0
 - (NSButton*) myCreateToggleButtonWithImage: (NSString*)anImageName
{
   NSButton* button = [self myCreateButtonWithImage: anImageName];
   [button setButtonType: NSToggleButton];
   
   NSString* extension = [anImageName pathExtension];
   NSString* base = [anImageName stringByDeletingPathExtension];
   NSString* alternateImage = [NSString stringWithFormat: @"%@On.%@", base, extension];
   [button setAlternateImage: [NSImage imageNamed: alternateImage]];

   return button;
}
#endif

@end

@implementation NSToolbar (Vindaloo)

- (NSArray *) itemsForIdentifier: (NSString *)identifier
{
	NSEnumerator *e = [[self items] objectEnumerator];
	NSToolbarItem *item = nil;
	NSMutableArray *matchingItems = [NSMutableArray array];

	while ((item = [e nextObject]) != nil)
	{
		if ([[item itemIdentifier] isEqual: identifier])
			[matchingItems addObject: item];
	}

	return matchingItems;
}

- (NSToolbarItem *) itemForIdentifier: (NSString *)identifier
{
	NSArray *matchingItems = [self itemsForIdentifier: identifier];

	if ([matchingItems count] > 0)
		return [matchingItems objectAtIndex: 0];

	return nil;
}

- (NSToolbarItem *) visibleItemForIdentifier: (NSString *)identifier
{
	NSToolbarItem *matchingItem = [self itemForIdentifier: identifier];

	if ([[self visibleItems] containsObject: matchingItem])
		return matchingItem;

	return nil;
}

@end
