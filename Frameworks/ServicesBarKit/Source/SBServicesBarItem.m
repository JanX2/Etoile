/* 
    SBServicesBarItem.m

    Core class for the services bar framework
   
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
#import "SBServicesBar.h"
#import "SBServicesBarItem.h"

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif

static id proxyInstance = nil;

@interface SBServicesBar (ServicesBarKitPackage)
+ (SBServicesBar *) serverInstance;
+ (BOOL) setUpServerInstance: (SBServicesBar *)bar;
@end

@protocol SBServicesBarItem
+ (id) systemServicesBarItemWithTitle: (NSString *)title;

- (SBServicesBar *) servicesBar;

- (NSString *) title;
- (void) setTitle: (NSString *)title;
- (float) length;
- (void) setLength: (float)length;
- (NSView *) view;
- (void) setView: (NSView *)view;
@end

@interface SBServicesBarItem (ServicesBarKitPackage)
- (id) owner;
@end

/*
 * SBServicesBar proxy extension to handle services bar item creation on server 
 * side
 */

@interface SBServicesBar (SBServicesBarItem)
- (id) setUpServicesBarItemWithTitle: (NSString *)title;
@end

@implementation SBServicesBar (SBServicesBarItem)

- (id) setUpServicesBarItemWithTitle: (NSString *)title
{
	SBServicesBarItem *item = [[SBServicesBarItem alloc] initWithTitle: title];

	NSLog(@"Server side creation of services bar item %@", self);

	// FIXME: We should retain the item properly in an array instead of 
	// inserting it directly in the services bar.
	[self addServicesBarItem: item];
	RELEASE(item);

	return item;
}

@end

@implementation SBServicesBarItem

- (id) owner
{
	return _ownerBar;
}

#ifdef HAVE_UKTEST
- (void) testInitWithTitle
{	
	//UKRaisesException([[SBServicesBarItem alloc] initWithTitle: @""]);
	//UKRaisesException([[SBServicesBarItem alloc] initWithTitle: nil]);
	
	UKNotNil([self title]);
	UKStringsNotEqual([self title], @"");
	UKNotNil(_toolbarItem);
	UKNotNil([_toolbarItem itemIdentifier]);
	UKStringsNotEqual([_toolbarItem itemIdentifier], @"");
	UKStringsEqual([_toolbarItem label], [self title]);
	
	if ([self length] < 0)
		UKFail();
}
#endif

/** We use a factory method because the instance is created on the server side
    and we only return a proxy. Then to rely on -initWithTitle: would make the 
	instanciation. */
//+ (id) servicesBarItemWithTitle: (NSString *)title inServicesBar: (id)bar
+ (id) systemServicesBarItemWithTitle: (NSString *)title
{
	if ([SBServicesBar serverInstance] == nil) /* Client side */
	{
		id servicesBarProxy;
		id itemProxy;

		/* Now the normal remote set up */
	
		NSLog(@"Client side set up by retrieving the proxy of services bar item \
			%@", self);

		servicesBarProxy = [NSConnection 
			rootProxyForConnectionWithRegisteredName: @"servicesbarkit/servicesbar"
			host:nil];

		itemProxy = [servicesBarProxy setUpServicesBarItemWithTitle: title];
		[itemProxy setProtocolForProxy: @protocol(SBServicesBarItem)];

		return itemProxy; 
	}
	else /* Server side */
	{
		return [[SBServicesBar serverInstance] 
			setUpServicesBarItemWithTitle: title];
	}

	return nil;
}

- (id) initWithTitle: (NSString *)title
{
	self = [super init];

	if (self != nil)
	{	
		// FIXME: Use a real unique identifier and not just the title alone.
		_toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: _title];

		// NOTE: Accessors suppose the related toolbar item has already been created.
		[self setTitle: title];

		/* Useful to know when a services bar item is inserted in a services
			bar it doesn't belong to (in other words, in a process different
			from the one where the item instance is located. */
		ASSIGN(_ownerBar, [SBServicesBar serverInstance]);
	}

	return self;
}

#ifdef HAVE_UKTEST
- (id) initForTest
{
	self = [self initWithTitle: @"Whatever"];
	
	//AUTORELEASE(_toolbarItem);
	//AUTORELEASE(_title);
	
	return self;
}
#endif

- (void) dealloc
{
	RELEASE(_title);
	RELEASE(_toolbarItem);
	
	[super dealloc];
}

- (NSString *) description
{
	NSString *desc = [super description];
	
	return [NSString stringWithFormat: @"%@ with title %@\n", desc, [self title]];
}

#ifdef HAVE_UKTEST
- (void) testServicesBar
{
	SBServicesBar *bar = [SBServicesBar sharedServicesBar];
	
	[bar addServicesBarItem: self];
	UKNotNil([self servicesBar]);
}
#endif

- (SBServicesBar *) servicesBar
{
	return [SBServicesBar systemServicesBar];
}

- (float) length
{
	return _itemLength;
}

- (void) setLength:(float)length;
{
	_itemLength = length;
}

- (NSView *) view
{
	return _itemView;
}

#ifdef HAVE_UKTEST
- (void) testSetView
{
	SBServicesBar *bar = [SBServicesBar sharedServicesBar];
	
	[bar addServicesBarItem: self];
	[self setView: [[NSView alloc] initWithFrame: NSMakeRect(1, 1, 1, 1)]];
	UKObjectsSame([self view], [_toolbarItem view]);
	UKTrue([[[bar valueForKey: @"_window"] contentView] isDescendantOf: [self view]]);
}
#endif

- (void) setView: (NSView *)view;
{
	ASSIGN(_itemView, view);
	[_toolbarItem setView: _itemView];
}

- (NSString *) title
{
	return _title;
}

- (void) setTitle: (NSString *)title
{
	ASSIGN(_title, title);
	[_toolbarItem setLabel: _title];
}

@end

/*
 * Service bar item default implementation
 */

@implementation SBServicesBarItem (Default)

- (void) sendActionOn: (int)mask
{

}

- (void) popUpMenu: (NSMenu *)menu
{
	//[SBServicesBar sharedServicesBar];
}

/*
 * Accessors
 */

- (SEL) action
{
	return [_toolbarItem action];
}

- (void) setAction: (SEL)action
{
	[_toolbarItem setAction: action];
}

- (id) target
{
	return [_toolbarItem target];
}

- (void) setTarget: (id)target
{
	[_toolbarItem setTarget: target];
}

- (NSAttributedString *) attributedTitle
{
	return _attTitle;
}

- (void) setAttributedTitle: (NSAttributedString *)attributedTitle
{
	ASSIGN(_attTitle, attributedTitle);
}

- (NSImage *) image
{
	return _image;
}

- (void) setImage: (NSImage *)image
{
	ASSIGN(_image, image);
	[_toolbarItem setImage: image];
}

- (NSImage *) alternateImage
{
	return _altImage;
}

- (void) setAlternateImage:(NSImage *)image
{
	ASSIGN(_altImage, image);	
}

- (NSMenu *) menu
{
	return _menu;
}

- (void) setMenu: (NSMenu *)menu
{
	ASSIGN(_menu, menu);
}

- (BOOL) isEnabled
{
	return [_toolbarItem isEnabled]; 
}

- (void) setEnabled: (BOOL)enabled
{
	[_toolbarItem setEnabled: enabled];
}

- (NSString *) toolTip
{
	return _toolTip;
}

- (void) setToolTip: (NSString *)toolTip
{
	ASSIGN(_toolTip, toolTip);
}

- (BOOL) highlightMode
{
	return _highlightMode;
}

- (void) setHighlightMode: (BOOL)highlightMode
{
	_highlightMode = highlightMode;
}

@end

