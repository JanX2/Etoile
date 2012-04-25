/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import <CoreObject/COEditingContext.h>
#import "ABAddressBook.h"
#import "ABGroup.h"
#import "ABPerson.h"
#import "ABRecord.h"

@implementation ABAddressBook

+ (ABAddressBook *)sharedAddressBook
{
	ETAssert([COEditingContext currentContext] != nil);
	return [[COEditingContext currentContext] contactLibrary];
}

+ (ABAddressBook *)addressBook
{
	ETAssert([COEditingContext currentContext] != nil);
	return [[COEditingContext currentContext] insertObjectWithClass: self rootObject: nil];
}

- (ABPerson *)me
{
	return [self valueForProperty: @"me"];
}

- (void)setMe: (ABPerson *)aPerson
{
	[self setValue: aPerson forProperty: @"me"];
}

- (id <ABRecord>)recordForUniqueId: (NSString *)aUUIDString
{
	ETUUID *uuid = [ETUUID UUIDWithString: aUUIDString];

	if (uuid == nil)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"The unique Id is not a valid UUID string."];
	}

	id record = [[self editingContext] objectWithUUID: uuid];
	ETAssert([[self content] containsObject: record]);
	return record;
}

- (NSArray *)people
{
	NSMutableArray *people = [self content];
	[[people filter] isKindOfClass: [ABPerson class]];
	return people;
}

- (NSArray *)groups
{
	NSMutableArray *groups = [self content];
	[[groups filter] isKindOfClass: [ABGroup class]];
	return groups;
}

- (BOOL)addRecord: (id <ABRecord>)aRecord
{
	[self addObject: aRecord];
	return YES;
}

- (BOOL)removeRecord: (id <ABRecord>)aRecord
{
	[self removeObject: aRecord];
	return YES;
}

- (NSString *)formattedAddressFromDictionary: (NSDictionary *)anAddress
{
	return nil;
}

- (NSInteger)defaultNameOrdering
{
	return 0;
}

- (NSInteger)defaultCountryCode
{
	return 0;
}

@end

