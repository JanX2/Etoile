/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/COGroup.h>
#import <AddressBook/ABRecord.h>

@class ABAddressBook, ABPerson;

/** 
@group Contacts
@abstract A contact in an address book. */
@interface ABGroup : COGroup <ABRecord>
{
	@private
	NSMutableDictionary *distributionIdentifiers;
}

/** @taskunit Initialization */

- (id)initWithAddressBook: (ABAddressBook *)aBook;
- (id)init;

/** @taskunit Accessing and Managing Members  */

- (NSArray *)members;
- (BOOL)addMember: (ABPerson *)aPerson;
- (BOOL)removeMember: (ABPerson *)aPerson;

/** @taskunit Accessing and Managing Subgroups  */

- (NSArray *)subgroups;
- (BOOL)addSubgroup: (ABGroup *)aGroup;
- (BOOL)removeSubgroup: (ABGroup *)aGroup;

/** @taskunit Mailing Support */

- (NSString *)distributionIdentifierForProperty: (NSString *)property 
                                         person: (ABPerson *)person;
- (BOOL)setDistributionIdentifier: (NSString *)identifier 
                      forProperty: (NSString *)property 
                           person: (ABPerson *)person;

@end
