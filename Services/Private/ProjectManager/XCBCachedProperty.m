/*
 * Étoilé ProjectManager - XCBProperty.m
 *
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import "XCBCachedProperty.h"
#import "XCBAtomCache.h"

const NSString *XCBInvalidTypeException = @"XCBInvalidTypeException";

@implementation XCBCachedProperty

- (id)initWithGetPropertyReply: (xcb_get_property_reply_t*)reply
                  propertyName: (NSString*)name
{
	SELFINIT;
	propertyName = [name retain];
	type = reply->type;
	format = reply->format;
	format_length = reply->value_len;
	bytes_after = reply->bytes_after;

	void *value = xcb_get_property_value(reply);
	int length = xcb_get_property_value_length(reply) * format / 8;
	if (length > 0 && value != NULL)
	{
		propertyData = [[NSData alloc]
			initWithBytes: value
			       length: length];
	}
	return self;
}

- (void)dealloc
{
	[propertyName release];
	[propertyData release];
	[super dealloc];
}
- (BOOL)isEmpty
{
	return propertyData == nil;
}
- (NSString*)propertyName
{
	return propertyName;
}
- (xcb_atom_t)type
{
	return type;
}
- (uint8_t)format
{
	return format;
}
- (uint32_t)lengthInFormatUnits
{
	return format_length;
}
- (NSData*)data
{
	return propertyData;
}
- (uint8_t*)asBytes
{
	return (uint8_t*)[propertyData bytes];
}
- (uint16_t*)asShorts
{
	return (uint16_t*)[propertyData bytes];
}
- (uint32_t*)asLongs
{
	return (uint32_t*)[propertyData bytes];
}
- (xcb_atom_t)asAtom
{
	[self checkAtomType: @"ATOM"];
	return (xcb_atom_t)([self asLongs][0]);
}
- (NSArray*)asAtomArray
{
	[self checkAtomType: @"ATOM"];
	uint32_t *longs = [self asLongs];
	NSMutableArray *atomArray = [NSMutableArray arrayWithCapacity: format_length];
	for (uint32_t i = 0; i < format_length; i++)
	{
		[atomArray addObject: [[XCBAtomCache sharedInstance] nameForAtom:(xcb_atom_t)longs[i]]];
	}
	return atomArray;
}

- (void)checkAtomType: (NSString*)expectedType
{
	if (type != [[XCBAtomCache sharedInstance] atomNamed: expectedType])
	{
		[NSException raise: (NSString*)XCBInvalidTypeException
		            format: @"Expected cached data for property %@ in the %@ type (stored as %@)",
		        propertyName,
		        expectedType,
		        [[XCBAtomCache sharedInstance] nameForAtom: type]]
		        ;
	}
}

- (NSString*)asString
{
	[self checkAtomType: @"STRING"];
	return [[[NSString alloc]
		initWithBytes: [[self data] bytes]
		       length: [[self data] length]
		     encoding: NSISOLatin1StringEncoding]
		     autorelease];
}
@end
