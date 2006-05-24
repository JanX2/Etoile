/*
    ClockMenulet.m

    Implementation of the ClockMenulet class for the EtoileMenuServer
    application.

    Copyright (C) 2005, 2006  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "ServicesBarMenulet.h"

@interface SBServicesBar (ServicesBarKitPackage)
- (GSToolbar *) toolbar;
@end

@interface ServicesBarMenulet (ServicesBarKitPrivate)
-(BOOL) publishServicesBarInstance;
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
		servicesBar = [[SBServicesBar alloc] init];
		toolbarView = [[GSToolbarView alloc] initWithFrame: NSMakeRect(0, 0, 100, 20)];
		[toolbarView setToolbar: [servicesBar toolbar]];

		if ([self publishServicesBarInstance] == NO)
			self = nil;
	}

	return self;
}

-(BOOL) publishServicesBarInstance
{
	NSConnection *theConnection = [NSConnection defaultConnection];

	[theConnection setRootObject: servicesBar];

	if ([theConnection registerName: @"servicesbarkit/servicesbar"] == NO) 
	{
		// FIXME: Take in account errors here.
		return NO;
	}

	return YES;
}

- (NSView *) menuletView
{
  return toolbarView;
}

@end
