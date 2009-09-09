//
//  XMPPvCard.m
//  Jabber
//
//  Created by David Chisnall on 12/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XMPPvCard.h"
#import <EtoileXML/ETXMLString.h>
#import <EtoileFoundation/EtoileFoundation.h>

@interface XMPPvCardUpdate : ETXMLNullHandler {
}
@end
@implementation XMPPvCardUpdate
- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>) aParent
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	[value autorelease];
	value = @"";
	return self;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"photo"])
	{
		[[[ETXMLString alloc] initWithXMLParser:parser
										 parent:self
											key:aName] startElement:aName
		 attributes:attributes];
	}
	else
	{
		depth++;
	}
}
- (void) addphoto:(NSString*)photoHash
{
	value = [photoHash retain];
}
@end

@implementation XMPPvCard
- (id) initWithXMLParser: (ETXMLParser*)aParser
                  parent: (id <ETXMLParserDelegate>) aParent
                     key: (id) aKey
{
	self = [super initWithXMLParser: aParser
	                         parent: aParent
	                            key: aKey];
	if (nil == self)
	{
		return nil;
	}
	person = [[ABPerson alloc] init];
	[value autorelease];
	value = person;
	return self;
}

- (void)startElement:(NSString *)aName
		  attributes:(NSDictionary*)attributes
{
	if([aName isEqualToString:@"N"] || [aName isEqualToString:@"vCard"])
	{
		depth++;
	}
	else
	{
		NSLog(@"Parsing vCard Element: %@", aName);
		[[[ETXMLString alloc] initWithXMLParser:parser
										 parent:self
											key:aName] startElement:aName
														attributes:attributes];
	}
}

#define PROPERTY_FROM_XML(property, xml)\
- (void) add ## xml:(NSString*)aString\
{\
	if(aString != nil && ![aString isEqualToString:@""])\
	{\
		[person setValue:aString forProperty:property];\
	}\
}
PROPERTY_FROM_XML(kABNicknameProperty, NICKNAME)
PROPERTY_FROM_XML(kABLastNameProperty, FAMILY)
PROPERTY_FROM_XML(kABFirstNameProperty, GIVEN)
#ifdef GNUSTEP
#define MULTI_INIT ABMutableMultiValue * multi = [(ABMutableMultiValue*)[ABMutableMultiValue alloc] initWithType:kABMultiStringProperty]
#else
#define MULTI_INIT ABMutableMultiValue * multi = [[ABMutableMultiValue alloc] init]
#endif
#define MULTI_PROPERTY_FROM_XML(property, label, xml) \
- (void) add ## xml:(NSString*)aString\
{\
	if(aString != nil && ![aString isEqualToString:@""])\
	{\
		MULTI_INIT;\
		[multi addValue:aString withLabel:label];\
		[person setValue:multi forProperty:property];\
		[multi release];\
	}\
}
MULTI_PROPERTY_FROM_XML(kABEmailProperty, kABEmailHomeLabel, EMAIL)
MULTI_PROPERTY_FROM_XML(kABURLsProperty, kABHomePageLabel, URL)
//FIXME: This should actually be getting <PHOTO><BINVAL>{CDATA}</BINVAL></PHOTO>, not <PHOTO>{CDATA}</PHOTO>
- (void) addPHOTO:(NSString*)aString
{
	NSMutableString * photo = [aString mutableCopy];
	[photo replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [photo length])];	


	if([photo length] > 9 && [[photo substringToIndex:9] isEqualToString:@"image/png"])
	{
		[photo deleteCharactersInRange:NSMakeRange(0,9)];
	}
	else if([photo length] > 10 && [[photo substringToIndex:10] isEqualToString:@"image/jpeg"])
	{
		[photo deleteCharactersInRange:NSMakeRange(0,10)];
	}
	[person setImageData:[photo base64DecodedData]];
}
- (void) addFN:(NSString*)aString
{
	NSArray * names;
#define GS_GNUSTEP_V GS_API_LATEST
// FIXME: Figure out a way to use GS_API_VERSION() without GNUstep base. 
// The issue is that GSVersionMacros.h is LGPL-licensed.
#ifndef GNUSTEP
#define GS_API_VERSION(x, y) 1
#endif
#if GS_API_VERSION(0, 011700)
	//Leopard method.
	names = [aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
#else
	names = [aString componentsSeparatedByString:@" "];
#endif
	switch([names count])
	{
		case 3:
		{
			[person setValue:[names objectAtIndex:0] forProperty:kABFirstNameProperty];
			[person setValue:[names objectAtIndex:1] forProperty:kABMiddleNameProperty];
			[person setValue:[names objectAtIndex:2] forProperty:kABLastNameProperty];
			break;
		}
		case 2:
		{
			[person setValue:[names objectAtIndex:0] forProperty:kABFirstNameProperty];
			[person setValue:[names objectAtIndex:1] forProperty:kABLastNameProperty];
			break;
		}
		case 1:
		{
			[person setValue:[names objectAtIndex:0] forProperty:kABFirstNameProperty];
			break;
		}
	}
}
@end
