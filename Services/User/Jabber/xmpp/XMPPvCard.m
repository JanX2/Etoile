//
//  XMPPvCard.m
//  Jabber
//
//  Created by David Chisnall on 12/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XMPPvCard.h"
#import "ETXMLString.h"
#include "Macros.h"
#import "NSData+Base64.h"

@implementation XMPPvCard
- (id) init
{
	SUPERINIT;
	person = [[ABPerson alloc] init];
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
/*
- (void) notifyParent
{
		ABGroup * jabberGroup = nil;
		NSArray * groups = [ab groups];
		FOREACH(groups, group, ABRecord*)
		{
			if([[group valueForProperty:kABGroupNameProperty] isEqualToString:@"Jabber People"])
			{
				jabberGroup = (ABGroup*)group;
			}
		}
		if(jabberGroup == nil)
		{
			group = [[[ABGroup alloc] init] autorelease];
			[group setValue:@"Jabber People" forProperty:kABGroupNameProperty];
			[ab addRecord:group];
		}
		NSLog(@"Adding person: %@ %@", [person valueForProperty:kABFirstNameProperty], [person valueForProperty:kABLastNameProperty]);
		[ab addRecord:person];
		[jabberGroup addMember:person];
		[ab save];
	}
	[super notifyParent];
}
*/
#define PROPERTY_FROM_XML(property, xml)\
- (void) add ## xml:(NSString*)aString\
{\
	NSLog(@"Trying to add '%@' for property %s", aString, #property);\
	if(aString != nil && ![aString isEqualToString:@""])\
	{\
		[person setValue:aString forProperty:property];\
	}\
}
PROPERTY_FROM_XML(kABNicknameProperty, NICKNAME)
PROPERTY_FROM_XML(kABLastNameProperty, FAMILY)
PROPERTY_FROM_XML(kABFirstNameProperty, GIVEN)
#ifdef GNUSTEP
#define MULTI_INIT ABMutableMultiValue * multi = [[ABMutableMultiValue alloc] initWithType:kABMultiStringProperty]
#else
#define MULTI_INIT ABMutableMultiValue * multi = [[ABMutableMultiValue alloc] init]
#endif
#define MULTI_PROPERTY_FROM_XML(property, label, xml) \
- (void) add ## xml:(NSString*)aString\
{\
	NSLog(@"Trying to add '%@' for property %s", aString, #property);\
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
#ifdef GNUSTEP
	NSArray * names = [aString componentsSeparatedByString:@" "];
#else
	NSArray * names = [aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
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
