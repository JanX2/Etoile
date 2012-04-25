/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <CoreObject/COContainer.h>

@class ABPerson;
@protocol ABRecord;

/**
@group Contacts
@abstract A contact library. */
@interface ABAddressBook : COLibrary
{

}

/** @taskunit Initialization */

+ (ABAddressBook *)sharedAddressBook;

/** @taskunit Who am I */

- (ABPerson *)me;
- (void)setMe: (ABPerson *)aPerson;

/** @taskunit Accessing Records */

- (id <ABRecord>)recordForUniqueId: (NSString *)aUUIDString;
- (NSArray *)people;
- (NSArray *)groups;

/** @task Managing Records */

- (BOOL)addRecord: (id <ABRecord>)aRecord;
- (BOOL)removeRecord: (id <ABRecord>)aRecord;

/** @taskunit Formatting */

- (NSString *)formattedAddressFromDictionary: (NSDictionary *)anAddress;
- (NSInteger)defaultNameOrdering;
- (NSInteger)defaultCountryCode;

@end
