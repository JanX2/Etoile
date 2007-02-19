//
//  MyDataSource.h
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@class	UKDistributedView;

@interface MyDataSource : NSObject
{
	NSMutableArray*				subCells;		// List of cells in this view, plus their positions etc.
	IBOutlet UKDistributedView*	distView;		// The UKDistributedView we display our data in.
	IBOutlet NSScrollView* scrollView;
}

-(void)	addCellWithTitle: (NSString*)title andImage: (NSImage*)img;	// Utility method for adding a new cell.

@end
