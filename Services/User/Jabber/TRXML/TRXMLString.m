//
//  TRXMLString.m
//  Jabber
//
//  Created by David Chisnall on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TRXMLString.h"
#import "Macros.h"
static inline NSString* escapeXMLCData(NSString* _XMLString)
{
	NSMutableString * XMLString = [NSMutableString stringWithString:_XMLString];
	[XMLString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"'" withString:@"&apos;" options:0 range:NSMakeRange(0,[XMLString length])];
	[XMLString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0,[XMLString length])];
	return XMLString;
}

@implementation TRXMLString
- (id) init
{
	SUPERINIT;
	value = nil;
	return self;
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
