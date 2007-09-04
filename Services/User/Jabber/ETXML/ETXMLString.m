//
//  ETXMLString.m
//  Jabber
//
//  Created by David Chisnall on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETXMLString.h"
#import "../Macros.h"
static inline NSString* unescapeXMLCData(NSString* _XMLString)
{
	NSMutableString * XMLString = [NSMutableString stringWithString:_XMLString];
	[XMLString replaceOccurrencesOfString:@"&lt;" withString:@"<" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&gt;" withString:@">" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&amp;" withString:@"&" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&apos;" withString:@"'" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:0 range:NSMakeRange(0,[XMLString length])];
	return XMLString;
}

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
