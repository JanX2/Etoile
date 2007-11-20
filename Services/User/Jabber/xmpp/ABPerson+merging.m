//
//  ABPerson+merging.m
//  Jabber
//
//  Created by David Chisnall on 19/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ABPerson+merging.h"
#import "Macros.h"

#define MATCH(x) [ABPerson searchElementForProperty:x\
											  label:nil\
												key:nil\
											  value:[self valueForProperty:x]\
										 comparison:kABEqual];
#define MATCH_IM_ADDRESS(type) if((addresses = [self valueForProperty:type]) != nil)\
{\
	for(unsigned int i=0 ; i<[addresses count] ; i++)\
	{\
		id address = [addresses valueAtIndex:i];\
		ABSearchElement * search = [ABPerson searchElementForProperty:type\
		                                                        label:nil\
		                                                          key:nil\
		                                                        value:address\
														   comparison:kABEqual];\
		NSArray * people = [ab recordsMatchingSearchElement:search];\
		if([people count] == 1)\
		{\
			return [people objectAtIndex:0];\
		}\
	}\
}



@implementation ABPerson (merging)
- (ABPerson*) findExistingPerson
{
	ABAddressBook * ab = [ABAddressBook sharedAddressBook];
	NSString * firstName = [self valueForProperty:kABFirstNameProperty];
	if([self valueForProperty:kABLastNameProperty] && firstName)
	{
		ABSearchElement * search = MATCH(kABLastNameProperty);
		NSArray * people = [ab recordsMatchingSearchElement:search];
		FOREACH(people, person, ABPerson*)
		{
			if([firstName isEqualToString:[person valueForProperty:kABFirstNameProperty]])
			{
				return person;
			}
		}
	}
	else
	{
		ABMultiValue * addresses;
		MATCH_IM_ADDRESS(kABJabberInstantProperty)
		MATCH_IM_ADDRESS(kABMSNInstantProperty)
		MATCH_IM_ADDRESS(kABAIMInstantProperty)
		MATCH_IM_ADDRESS(kABICQInstantProperty)
		MATCH_IM_ADDRESS(kABYahooInstantProperty)
	}
	return nil;
}
- (NSArray*) mergePerson:(ABPerson*)aPerson
{
	NSArray * properties = [ABPerson properties];
	NSMutableArray * failedProperties = [NSMutableArray array];
	FOREACH(properties, property, NSString*)
	{
		//Don't update implicit properties.
		if(!([property isEqualToString:kABUIDProperty]
			 ||
			 [property isEqualToString:kABCreationDateProperty]
			 ||
			 [property isEqualToString:kABModificationDateProperty]))
		{
			id otherValue = [aPerson valueForProperty:property];
			if(otherValue != nil)
			{
				id value = [self valueForProperty:property];
				//If we have no copy of this, just add it
				if(value == nil)
				{
					[self setValue:otherValue forProperty:property];
				}
				else
				{
					//If it's a multivalue with compatible types, merge it:
					if([value isKindOfClass:[ABMultiValue class]] &&
					   ([value propertyType] == [otherValue propertyType]))
					{
						ABMutableMultiValue * old = [value mutableCopy];
						for(unsigned int i=0 ; i<[otherValue count] ; i++)
						{
							id v = [(ABMultiValue*)otherValue valueAtIndex:i];
							BOOL duplicate = NO;
							for(unsigned int j=0 ; i<[old count] ; i++)
							{
								if([v isEqual:[old valueAtIndex:j]])
								{
									duplicate = YES;
									break;
								}
							}
							if(!duplicate)
							{
								[old addValue:v withLabel:[otherValue labelAtIndex:i]];
							}
						}
						[self setValue:old forProperty:property];
					}
					else
					{
						if(![otherValue isEqual:value])
						{
							NSLog(@"Not merging %@.  %@ => %@", property, value, otherValue);
							[failedProperties addObject:property];
						}
					}
				}
			}
		}
	}
	if([self imageData] == nil)
	{
		[self setImageData:[aPerson imageData]];
	}
	return failedProperties;
}
@end
