//
//  ETXMLString.m
//  Jabber
//
//  Created by David Chisnall on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETXMLString.h"
#import "../Macros.h"

@implementation ETXMLString
- (id) init
{
	SUPERINIT;
	value = nil;
	return self;
}
- (void) notifyParent
{
	if(value != nil)
	{
		id oldValue = value;
		value = [unescapeXMLCData(value) retain];
		[oldValue release];		
	}
	[super notifyParent];
}
- (void)characters:(NSString *)aString
{
	if(value == nil)
	{
		value = [aString retain];
	}
	else
	{
		value = [value stringByAppendingString:aString];
	}
}
@end
