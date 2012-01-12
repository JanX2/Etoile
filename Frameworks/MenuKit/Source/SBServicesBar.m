/* 
    SBServicesBar.m

    Core class for the services bar
   
    Copyright (C) 2004 Quentin Mathe

    Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  November 2004
   
    This file is part of the Etoile desktop environment.

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSToolbar.h>
#import "SBServicesBarItem.h"
#import "SBServicesBar.h"

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif

static NSString *SBSystemServicesBarNamespace = nil;

static SBServicesBar *serverInstance = nil;
static id proxyInstance = nil;

@interface SBServicesBarItem (ServicesBarKitPackage)
- (id) owner;
@end

@protocol SBServicesBar
- (void) addServicesBarItem: (SBServicesBarItem *)item;
- (void) insertServicesBarItem: (SBServicesBarItem *)item atIndex: (int)index;
- (void) removeServicesBarItem: (SBServicesBarItem *)item;
- (BOOL) isVertical;
- (float) thickness;
@end

@interface SBServicesBar (ServicesBarKitPackage)
+ (SBServicesBar *) serverInstance;
+ (BOOL) setUpServerInstance: (SBServicesBar *)bar;
- (GSToolbar *) toolbar;
@end


@implementation SBServicesBar

+ (void) initialize
{
	if (self == [SBServicesBar class])
	{
		SBSystemServicesBarNamespace = @"systemservicesbar";
	}
}

+ (SBServicesBar *) serverInstance
{
	return serverInstance;
}

+ (BOOL) setUpServerInstance: (SBServicesBar *)bar
{
	ASSIGN(serverInstance, bar);

	/* Finish set up by exporting server instance through DO */
	NSConnection *theConnection = [NSConnection defaultConnection];

	[theConnection setRootObject: bar];

	if ([theConnection registerName: SBSystemServicesBarNamespace] == NO) 
	{
		// FIXME: Take in account errors here.
		NSLog(@"Unable to register the services bar namespace %@ with DO", 
			SBSystemServicesBarNamespace);

		return NO;
	}

	return YES;
}

/** Reserved for client side. It's mandatory to have call -setUpServerInstance: 
    before usually in the server process itself. */
+ (id) systemServicesBar
{
	/* The test set up */

#ifdef HAVE_UKTEST
// Remove this code I think
	if (serverInstance == nil)
		serverInstance = [[SBServicesBar alloc] initForTest];
	
	return serverInstance;

#endif

	/* Now the normal set up */

	proxyInstance = [NSConnection 
		rootProxyForConnectionWithRegisteredName: SBSystemServicesBarNamespace
		host: nil];

	[proxyInstance setProtocolForProxy: @protocol(SBServicesBar)];

	/* We probably don't need to release it, it's just a singleton. */
	return RETAIN(proxyInstance); 
}

#ifdef HAVE_UKTEST
- (void) testInit
{
	UKNotNil(_items);
	UKNotNil(_itemToolbar);
	UKNotNil(_toolbarView);
	UKNotNil(_window);
	UKNotNil([_itemToolbar delegate]);

	NSLog(@"Window: %@", _window);
	NSLog(@"Window content view: %@", [_window contentView]);
	UKTrue([_toolbarView isDescendantOf: [_window contentView]]);
}
#endif

- (id) init
{
	self = [super init];

	if (self != nil)
	{
		_itemToolbar = [[GSToolbar alloc] initWithIdentifier: @"SBServicesBar"
			displayMode: NSToolbarDisplayModeLabelOnly 
			   sizeMode: NSToolbarSizeModeDefault];
		[_itemToolbar setDelegate: self];
		_items = [[NSMutableArray alloc] init];
	}
	
	return self;
}

#ifdef HAVE_UKTEST
- (id) initForTest
{
	self = [self init];

	NSLog(@"Set up with -initForTest and services bar %@", self);

	// NOTE: it's mandatory to have serverInstance non nil, otherwise item 
	// insertion method exits by complaining about incorrect services bar owner 
	// with each services bar item.
	ASSIGN(serverInstance, self);

	/* _window is released within -releaseForTest */
	_window = [[NSWindow alloc] initWithContentRect: NSMakeRect(100, 100, 500, 70) 
	                                      styleMask: NSBorderlessWindowMask 
	                                        backing: NSBackingStoreBuffered defer: NO];
	_toolbarView = [[GSToolbarView alloc] initWithFrame: NSMakeRect(0, 0, 500, 70)];	
	[[_window contentView] addSubview: _toolbarView];
	RELEASE(_toolbarView);

	[_toolbarView setToolbar: _itemToolbar];

	[_window makeKeyAndOrderFront: nil];

	return self;
}
#endif

- (void) dealloc
{
	RELEASE(_itemToolbar);
	RELEASE(_items);
	
	[super dealloc];
}

#ifdef HAVE_UKTEST
- (void) releaseForTest
{
	NSLog(@"Set down with -releaseForTest and services bar %@", self);

	// FIXME: This next line is needed, otherwise a segmentation fault happens
	// on _window release (the validation center has currently no sure
	// manner to know when a window is released... this results in a pointer on
	// garbage memory in similar border cases). Any windows should probably
	// receive the close message before being released, that's probably not true
	// currently. Perhaps we aren't observing window close notifications 
	// correctly. This must be checked.
	// The right fix is probably to replace RELEASE(toolbar) by -setToolbar: nil
	// in GSToolbarView, that would tear down related validation object as a side
	// effect. Then bypassing the need to monitor window release/close.
	[_toolbarView setToolbar: nil];
	TEST_RELEASE(_window);
	
	[super release];
}
#endif

- (void) addServicesBarItem: (SBServicesBarItem *)item
{
	[self insertServicesBarItem: item atIndex: [[_itemToolbar items] count]];
}

#ifdef HAVE_UKTEST
- (void) testInsertServicesBarItemAtIndexA
{
	SBServicesBarItem *item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	NSToolbarItem *toolbarItem;

	//UKRaisesExceptions([self insertServicesBarItem: item atIndex: -1]);
	//UKRaisesException([bar insertServicesBarItem: item atIndex: [_items count] + 1]);

	/* Part 1 */

	[self addServicesBarItem: item];

	UKTrue([_items containsObject: item]);

	/* Part 2 */

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
	
	/* Part 1 */

	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[_itemToolbar insertItemWithItemIdentifier: [item title] atIndex: [_items count]];

	UKTrue([[_itemToolbar visibleItems] containsObject: item->_toolbarItem]);

	/* Part 2 */
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[self insertServicesBarItem: item atIndex: [_items count] - 1];

	UKFalse([[[_itemToolbar items] valueForKey: @"identifier"] containsObject: item]);

	/* Part 3 (no tests currently) */
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[_itemToolbar insertItemWithItemIdentifier: [item title] atIndex: [_items count]];
	[self insertServicesBarItem: item atIndex: [_items count]];
}

- (void) testInsertServicesItemAtIndexC
{
	SBServicesBarItem *item;
	
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[self insertServicesBarItem: item atIndex: [_items count]];
	item = [[SBServicesBarItem alloc] initWithTitle: @"Whatever"];
	[self insertServicesBarItem: item atIndex: [_items count]];
		
	UKFalse([[[_itemToolbar items] objectsWithValue: @"Whatever" forKey: @"identifier"] count] == 1);
	UKTrue([[[_itemToolbar items] objectsWithValue: @"Whatever" forKey: @"label"] count] == 2);
}
#endif

// FIXME: Rename this method -setXXX rather than -insertXXX (unless we decide
// to prefer an insertion to a replacement).
- (void) insertServicesBarItem: (SBServicesBarItem *)item atIndex: (int)index
{
	NSArray *itemIdentifiers;
	int prevIndex;

	NSLog(@"Entering insert services bar item");

	if ([[item owner] isEqual: self] == NO)
	{
		// FIXME: It would be probably better to raise an exception here.
		NSLog(@"This services bar item %@ doesn't belong to services bar %@ \
			but to services bar %@", item, self, [item owner]);
	}

	if ([_items containsObject: item] == NO)
		[_items addObject: item];
	
	itemIdentifiers = [[_itemToolbar items] valueForKey: @"itemIdentifier"];
	prevIndex = [itemIdentifiers indexOfObject: [item title]];

	if (prevIndex != NSNotFound)
		[_itemToolbar removeItemAtIndex: prevIndex];

	NSLog(@"Just inserting services bar item %@ in toolbar %@", item, _itemToolbar);
	[_itemToolbar insertItemWithItemIdentifier: [item title] atIndex: index];
}

#ifdef HAVE_UKTEST
- (void) testRemoveServicesBarItem
{

}
#endif

- (void) removeServicesBarItem: (SBServicesBarItem *)item
{

}

- (BOOL) isVertical
{
	return YES;
}

/** The value is the one defined in Services/Private/MenuServer/MenuBarHeight.h. */
- (float) thickness
{
	return 22;
}

/*
 * Serialization methods (mandatory to talk with DO to Services Bar located in MenuServer)
 */

- (void) encodeWithCoder: (NSCoder *)coder
{

}

- (void) initWithCoder: (NSCoder *)coder
{

}

/*
 * Toolbar delegate methods
 */

- (NSToolbarItem *) toolbar:(GSToolbar *)toolbar 
      itemForItemIdentifier: (NSString *)identifier 
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

/*
 * Rest of package methods
 */

- (GSToolbar *) toolbar
{
	return _itemToolbar;
}

@end
