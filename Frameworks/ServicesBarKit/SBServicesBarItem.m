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


@implementation SBServicesBarItem

#ifdef HAVE_UKTEST
- (void) testInitWithTitle
{	
	//UKRaisesException([[SBServicesBarItem alloc] initWithTitle: @""]);
	//UKRaisesException([[SBServicesBarItem alloc] initWithTitle: nil]);
	
	UKNotNil([self title]);
	UKStringsNotEqual([self title], @"");
	UKNotNil([_toolbarItem itemIdentifier]);
	UKStringsNotEqual([_toolbarItem itemIdentifier], @"");
	
	if ([self length] < 0)
		UKFail();
}
#endif

- (id) initWithTitle: (NSString *)title
{
	if ((self = [super init]) != nil)
	{
		[self setTitle: title];
		_toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: _title];
		
		return self;
	}
	
	return nil;
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
	return [SBServicesBar sharedServicesBar];
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
	[SBServicesBar sharedServicesBar];
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

