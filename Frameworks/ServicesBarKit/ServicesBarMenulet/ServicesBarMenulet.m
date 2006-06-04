/* 
	ServicesBarMenulet.m

    Interface declaration of the Services Bar menulet class for the
    EtoileMenuServer application.
   
    Copyright (C) 2006 Quentin Mathe

    Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  May 2006
   
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

#import "ServicesBarMenulet.h"
#import "SBServicesBarItem.h"
#import "SBServicesBar.h"

@interface SBServicesBar (ServicesBarKitPackage)
+ (BOOL) setUpServerInstance: (id)instance;
- (GSToolbar *) toolbar;
@end

@interface ServicesBarMenulet (ServicesBarKitPrivate)
-(BOOL) publishServicesBarInstance;
@end

@interface GSToolbar (Private)
- (NSView *) _backView;
- (GSToolbarView *) _toolbarView;
@end


@implementation ServicesBarMenulet

- (void) dealloc
{
	TEST_RELEASE(toolbarView);
	DESTROY(servicesBar);

	[super dealloc];
}

- (id) init
{
	if ((self = [super init]) != nil)
	{
		NSLog(@"Init services bar menulet");

		servicesBar = [[SBServicesBar alloc] init];
		if ([SBServicesBar setUpServerInstance: servicesBar] == NO)
		{
			NSLog(@"ServicesBarMenulet - Unable to set up server instance");
			//self = nil;
		}
		AUTORELEASE(servicesBar); // Retained by -setUpServerInstance:

		// NOTE: 22 is the menu bar height defined in MenuServer/MenuBarHeight.h,
		// this value is returned by -[SBServicesBar thickness].
		// We substract 1 to adjust the border perfectly (visible on click), don't
		// know why it's necessary. As today we subtract 2 in fact.
		toolbarView = [[GSToolbarView alloc] initWithFrame: 
			NSMakeRect(0, 0, 500, [servicesBar thickness]  - 2)];
		[toolbarView setBorderMask: GSToolbarViewNoBorder];
		[toolbarView setToolbar: [servicesBar toolbar]];
		// NOTE: We really set the toolbar view frame now, because the toolbar 
		// set up reset it.
		[toolbarView setFrame: NSMakeRect(0, 0, 500, [servicesBar thickness] - 2)];
	}

	return self;
}

- (NSView *) menuletView
{
	return toolbarView;
}

- (void) test
{
	SBServicesBarItem *item = [SBServicesBarItem
		systemServicesBarItemWithTitle: @"ServicesBarMenulet test"];
	SBServicesBar *bar = servicesBar;

	NSLog(@"Services bar item %@ with title %@", item, [item title]);

	[bar insertServicesBarItem: item atIndex: 0];

	NSLog(@"Services bar %@ with items %@", bar, nil); //bar->_items);

	id toolbar = [bar toolbar];
	NSLog(@"Toolbar %@ with frame %@ and items %@ (visible only %@)", 
		toolbar, NSStringFromRect([[toolbar _toolbarView] frame]), 
		[toolbar items], [toolbar visibleItems]);
	
	id toolbarItem = [[[bar toolbar] items] objectAtIndex: 0];
	NSLog(@"Toolbar item with title %@ and frame %@ at index %d", 
		 [toolbarItem label], NSStringFromRect([[toolbarItem _backView] frame]), 0);

	item = [SBServicesBarItem
		systemServicesBarItemWithTitle: @"Click me"];
	[item setAction: @selector(displayClickMePanel:)];
	[item setTarget: self];

	[bar insertServicesBarItem: item atIndex: 0];
}

- (void) displayClickMePanel: (id)sender
{
	NSRunAlertPanel(@"Click me", 
		@"Displayed by the MenuServer on the behalf of a menulet", nil, nil, nil);
}


@end
