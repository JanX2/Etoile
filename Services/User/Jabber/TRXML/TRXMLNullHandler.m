//
//  TRXMLNullHandler.m
//  Jabber
//
//  Created by David Chisnall on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TRXMLNullHandler.h"
#import "../Macros.h"

@implementation TRXMLNullHandler
- (id) initWithXMLParser:(id)aParser parent:(id<NSObject,TRXMLParserDelegate>)aParent key:(id)aKey
{
	SELFINIT
	[aParser setContentHandler:self];
	[self setParser:aParser];
	[self setParent:aParent];
	key = [aKey retain];
	return self;
}

- (id) init
{
	SUPERINIT;
	value = [self retain];
	return self;
}

- (void) setParser:(id) XMLParser
{
	[self retain];
	parser = XMLParser;
}

- (void) setParent:(id) newParent
{
	parent = newParent;
}

- (void)characters:(NSString *)_chars
{
	//Ignore cdata
}

- (void)startElement:(NSString *)_Name
		  attributes:(NSDictionary*)_attributes
{
	depth++;
}

- (void)endElement:(NSString *)_Name
{
	depth--;
	if(depth == 0)
	{
		[parser setContentHandler:parent];
		[self notifyParent];
		[self release];
	}
}
- (void) addChild:(id)aChild forKey:aKey
{
	NSString * childSelectorName = [NSString stringWithFormat:@"add%@:", aKey];
	SEL childSelector = NSSelectorFromString(childSelectorName);
	if([self respondsToSelector:childSelector])
	{
		[self performSelector:childSelector withObject:aChild];
	}
	else
	{
		//NSLog(@"Unrecognised XML child type: %@", aKey);
	}
}

- (void) notifyParent
{
	if(key != nil && [parent respondsToSelector:@selector(addChild:forKey:)])
	{
		[(id)parent addChild:value forKey:key];
		//NSLog(@"Setting value: %@ for key: %@ in %@", value, key, parent);
	}
	[value release];
}


- (void) dealloc
{
	[key release];
	[super dealloc];
}
@end
