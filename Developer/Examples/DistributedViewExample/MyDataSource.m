//
//  MyDataSource.m
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#ifdef GNUSTEP
#import <EtoileExtensions/EtoileCompatibility.h>
#endif

#ifndef __ETOILE__
#import "UKDistributedView.h"
#import "UKFinderIconCell.h"
#else
#import <EtoileExtensions/UKDistributedView.h>
#import <EtoileExtensions/UKFinderIconCell.h>
#endif
#import "MyDataSource.h"
#import "MyDistViewItem.h"




@implementation MyDataSource

-(id)	init
{
    self = [super init];
    if( self )
	{
        subCells = [[NSMutableArray alloc] init];	// This example keeps its items in an array.
    }
    return self;
}


-(void)	dealloc
{
	[subCells release];
}


// When we've finished building, set up our custom cell type and a few sample items to play with:
-(void)	awakeFromNib
{
	/* Set up a finder icon cell to use: */
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] autorelease] init];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: YES];

	[distView setPrototype: bCell];
	[distView setCellSize: NSMakeSize(100.0,80.0)];

	// Add a few items:
	[self addCellWithTitle: @"Lady Jaye" andImage:[NSImage imageNamed: @"LadyJayeIcon"]];
	[self addCellWithTitle: @"Mimi Rogers" andImage:[NSImage imageNamed: @"MimiRogersIcon"]];
	[self addCellWithTitle: @"Mediator File" andImage:[NSImage imageNamed: @"MediDoc"]];
	
	// Make items draggable and initially position them neatly:
	[distView positionAllItems:self];	// Instead of this you'd probably load the positions from wherever you get your items from.
	[distView setDragMovesItems:YES];	// Allow dragging around items in the view.
}

-(void)	addCellWithTitle: (NSString*)title andImage: (NSImage*)img
{
	MyDistViewItem*		item = [[[MyDistViewItem alloc] autorelease] initWithTitle:title andImage:img];
	[subCells addObject: item];
}

// DistributedView delegate methods:
-(int)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return [subCells count];	// Tell our list view how many items to expect:
}

-(NSPoint)	distributedView: (UKDistributedView*)distributedView positionForCell:(NSCell*)cell atItemIndex: (int)row
{
	MyDistViewItem*		item = [subCells objectAtIndex: row];
	
	// Display item data in cell:
	[cell setImage: [item image]];
	[cell setTitle: [item title]];
	
	/* Tell list view where to display this item:
		You *must* keep track of your items' positions, and if you
		want to be able to move them, you must also implement setPosition:forItemIndex: */
	return [item position];
}


// User has repositioned this item. Pick up the change:
-(void)	distributedView: (UKDistributedView*)distributedView setPosition: (NSPoint)pos forItemIndex: (int)row
{
	MyDistViewItem*		item = [subCells objectAtIndex: row];
	
	[item setPosition: pos];
}


@end
