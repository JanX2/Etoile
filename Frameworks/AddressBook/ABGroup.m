/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import "ABGroup.h"
#import "ABAddressBook.h"
#import "ABPerson.h"
#import "ABConstants.h"

@implementation ABGroup

+ (ETEntityDescription *)newEntityDescription
{
	ETEntityDescription *group = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add the 
	// property descriptions that we will inherit through the parent
	if ([[group name] isEqual: [ABGroup className]] == NO) 
		return group;

	ETPropertyDescription *uniqueId = [ETPropertyDescription descriptionWithName: kABUIDProperty type: (id)@"NSString"];
	/* uniqueId is derived from COObject.UUID */
	[uniqueId setDerived: YES];

	ETPropertyDescription *parentGroups = [ETPropertyDescription descriptionWithName: @"parentGroups" type: (id)@"NSArray"];
	/* parentGroups is an alias on COObject.parentCollections */
	[parentGroups setDerived: YES]; 
	[parentGroups setMultivalued: YES];
	[parentGroups setOrdered: YES];

	/* Both members and subgroups are not considered ordered, but using NSArray 
       allows the content presentation order to remain stable at the UI level.
	   Both are slices derived from COObject.contents */
	ETPropertyDescription *members = [ETPropertyDescription descriptionWithName: @"members" type: (id)@"NSArray"];
	[members setDerived: YES];
	[members setMultivalued: YES];
	[members setOrdered: NO];
	ETPropertyDescription *subgroups = [ETPropertyDescription descriptionWithName: @"subgroups" type: (id)@"NSArray"];
	[subgroups setDerived: YES];
	[subgroups setMultivalued: YES];
	[subgroups setOrdered: NO];

	/*ETPropertyDescription *distributionIds = [ETPropertyDescription descriptionWithName: @"distributionIdentifiers" type: (id)@"NSDictionary"];
	[distributionIds setMultivalued: YES];*/

	[group setPropertyDescriptions: A(uniqueId, parentGroups, members, subgroups)];
	return group;
}

- (id)initWithAddressBook: (ABAddressBook *)aBook
{
	return self;
}

- (id)initWithVCardRepresentation: (NSData *)vCardData
{
	return self;
}

- (id)init
{
	return self;
}

- (NSArray *)members
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"className == %@", @"ABPerson"];
	return [[self valueForProperty: @"contents"] filteredArrayUsingPredicate: predicate];
}

- (BOOL)addMember: (ABPerson *)aPerson
{
	[self addObject: aPerson];
	return YES;
}

- (BOOL)removeMember: (ABPerson *)aPerson
{
	[self removeObject: aPerson];
	return YES;
}

- (NSArray *)subgroups
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"className == %@", @"ABGroup"];
	return [[self valueForProperty: @"contents"] filteredArrayUsingPredicate: predicate];
}

- (BOOL)addSubgroup: (ABGroup *)aGroup
{
	[self addObject: aGroup];
	return YES;
}

- (BOOL)removeSubgroup: (ABGroup *)aGroup
{
	[self removeObject: aGroup];
	return YES;
}

- (NSString *)distributionIdentifierForProperty: (NSString *)aProperty 
                                         person: (ABPerson *)aPerson
{
	if (aProperty == nil || aPerson == nil)
		return nil;

	NSString *aggregateKey = 
		[NSString stringWithFormat: @"%@-%@", aProperty, [[aPerson UUID] stringValue]];

	NSString *identifier = [distributionIdentifiers objectForKey: aggregateKey];

	if (identifier == nil)
	{
		[[aPerson valueForProperty: aProperty] primaryIdentifier];
	}
	return identifier;
}

- (BOOL)setDistributionIdentifier: (NSString *)anIdentifier
                      forProperty: (NSString *)aProperty 
                           person: (ABPerson *)aPerson
{
	NILARG_EXCEPTION_TEST(aPerson);

	if (aProperty == nil)
		return NO;

	NSString *aggregateKey = 
		[NSString stringWithFormat: @"%@-%@", aProperty, [[aPerson UUID] stringValue]];

	if (anIdentifier == nil)
	{
		[distributionIdentifiers removeObjectForKey: aggregateKey]; 
	}
	else
	{
		[distributionIdentifiers setObject: anIdentifier forKey: aggregateKey]; 
	}
	return YES;
}

@end

