/* 
   SBServicesBar.m

   Core class for the services bar
   
   Copyright (C) 2004 Quentin Mathe

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: November 2004
   
   This file is part of the Etoile desktop environment.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSToolbar.h>
#import "SBServicesBarItem.h"
#import "SBServicesBar.h"


@implementation SBServicesBar

+ (SBServicesBar *) sharedServicesBar
{
	return [[SBServicesBar alloc] init];
}

- (void) testInit
{
	UKNotNil(_items);
	UKNotNil(_itemsToolbar);
	UKNotNil(_toolbarView);
	UKNotNil(_window);
	UKNotNil([_itemsToolbar delegate]);
	
	UKTrue([_toolbarView isDescendantOf: [_window contentView]]);
}

- (id) init
{
	if ((self = [super init]) != nil)
	{
		_itemsToolbar = [[GSToolbar alloc] initWithIdentifier: @"SBServicesBar"];
		[_itemsToolbar setDelegate: self];
		_items = [[NSMutableArray alloc] init];
		
		return self;
	}
	
	return nil;
}

- (id) initForTest
{
	self = [SBServicesBar sharedServicesBar];
	
	_window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 400, 22) styleMask: NSBorderlessWindowMask 
		backing: NSBackingStoreBuffered defer: NO];
	_toolbarView = [[GSToolbarView alloc] initWithFrame: NSMakeRect(0, 0, 400, 22)];
	//AUTORELEASE(_window);
	//AUTORELEASE(_toolbarView);
	
	[[_window contentView] addSubview: _toolbarView];
	RELEASE(_toolbarView);
	[_toolbarView setToolbar: _itemsToolbar];
	
	return self;
}

- (void) dealloc
{
	RELEASE(_itemsToolbar);
	RELEASE(_items);
	
	[super dealloc];
}

- (void) releaseForTest
{
	if ([self retainCount] == 1)
	{
		NSLog(@"retainCount will be 0");
		//RELEASE(_window);
	}
	[super release];
}

- (void) addServicesBarItem: (SBServicesBarItem *)item
{
	[self insertServicesBarItem: item atIndex: [[_itemsToolbar items] count]];
}

- (void) testInsertServicesBarItemAtIndexA
{
	SBServicesBarItem *item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	NSToolbarItem *toolbarItem;
	
	//UKRaisesExceptions([self insertServicesBarItem: item atIndex: -1]);
	//UKRaisesException([bar insertServicesBarItem: item atIndex: [_items count] + 1]);
	
	[self addServicesBarItem: item];
	UKTrue([_items containsObject: item]);
	
	[item setView: [[NSView alloc] initWithFrame: NSMakeRect(1, 1, 1, 1)]];
	toolbarItem = [item valueForKey: @"_toolbarItem"];
	NSLog(@"toolbarItem %@", toolbarItem);
	NSLog(@"toolbarItem view %@", [toolbarItem view]);
	NSLog(@"toolbarItem view superview %@", [[toolbarItem view] superview]);
	UKTrue([[toolbarItem view] isDescendantOf: _toolbarView]);
}

- (void) testInsertServicesItemAtIndexB
{
	SBServicesBarItem *item;
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[_itemsToolbar insertItemWithItemIdentifier: [item title] atIndex: [_items count]];	
	UKTrue([[_itemsToolbar visibleItems] containsObject: item->_toolbarItem]);
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[self insertServicesBarItem: item atIndex: [_items count] - 1];
	UKFalse([[[_itemsToolbar items] valueForKey: @"identifier"] containsObject: item]);
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[_itemsToolbar insertItemWithItemIdentifier: [item title] atIndex: [_items count]];
	[self insertServicesBarItem: item atIndex: [_items count]];
}

- (void) testInsertServicesItemAtIndexC
{
	SBServicesBarItem *item;
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[self insertServicesBarItem: item atIndex: [_items count]];
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[self insertServicesBarItem: item atIndex: [_items count]];
		
	UKFalse([[[_itemsToolbar items] objectsWithValue: @"Whatever" forKey: @"identifier"] count] == 1);
	UKTrue([[[_itemsToolbar items] objectsWithValue: @"Whatever" forKey: @"label"] count] == 2);
}

- (void) insertServicesBarItem: (SBServicesBarItem *)item atIndex: (int)index
{
	[_items addObject: item];
	[_itemsToolbar insertItemWithItemIdentifier: [item title] atIndex: index];
}

- (void) testRemoveServicesBarItem
{

}

- (void) removeServicesBarItem: (SBServicesBarItem *)item
{

}

- (BOOL) isVertical
{
	return YES;
}

- (float) thickness
{
	return 22;
}

/*
 * Toolbar delegate methods
 */

- (NSToolbarItem *) toolbar:(GSToolbar *)toolbar itemForItemIdentifier: (NSString *)identifier
	willBeInsertedIntoToolbar: (BOOL)insert
{
	SBServicesBarItem *item = [[_items objectsWithValue: identifier forKey: @"title"] objectAtIndex: 0];
	NSToolbarItem *toolbarItem = [item valueForKey: @"_toolbarItem"];
	
	NSLog(@"toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar has been called");
	NSLog(@"Toolbar item : %@", toolbarItem);
	
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (GSToolbar *)toolbar 
{
	NSArray *identifiers = [_items valueForKey: @"title"];
	
	NSLog(@"toolbarDefaultItemIdentifiers: has been called");
	NSLog(@"Identifiers : %@", identifiers);
	
	return identifiers;
}

- (NSArray *) toolbarAllowedItemIdentifiers: (GSToolbar *)toolbar 
{
  	NSArray *identifiers = [_items valueForKey: @"title"];
	
	NSLog(@"toolbarAllowedItemIdentifiers: has been called"); 
    NSLog(@"Identifiers : %@", identifiers);
	
	return identifiers;
}

@end
