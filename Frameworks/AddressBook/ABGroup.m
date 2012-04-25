/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import "ABGroup.h"
#import "ABAddressBook.h"
#import "ABPerson.h"

@implementation ABGroup

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
	return [self contentArray];
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
	return [NSArray arrayWithArray: [self valueForProperty: @"subgroups"]];
}

- (BOOL)addSubgroup: (ABGroup *)aGroup
{
	[self addObject: aGroup forProperty: @"subgroups"];
	return YES;
}

- (BOOL)removeSubgroup: (ABGroup *)aGroup
{
	[self removeObject: aGroup forProperty: @"subgroups"];
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

