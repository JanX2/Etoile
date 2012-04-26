/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

/** @taskunit Record Properties */

/** <em>creationDate</em> property of type NSDate. Same as -[COObject creationDate]. */
extern NSString * const kABCreationDateProperty;
/** <em>modificationDate</em> property of type NSDate. Same as -[COObject modificationDate]. */
extern NSString * const kABModificationDateProperty;
/** <em>uniqueId</em> property of type NSString. Same as -[COObject UUID] string value. */
extern NSString * const kABUIDProperty;

/** @taskunit Person Properties */

extern NSString * const kABFirstNameProperty;
extern NSString * const kABLastNameProperty;
extern NSString * const kABFirstNamePhoneticProperty;
extern NSString * const kABLastNamePhoneticProperty;
extern NSString * const kABNicknameProperty;
extern NSString * const kABMaidenNameProperty;
extern NSString * const kABBirthdayProperty;
extern NSString * const kABOrganizationProperty;
extern NSString * const kABJobTitleProperty;
extern NSString * const kABHomePageProperty;
extern NSString * const kABURLsProperty;
extern NSString * const kABCalendarURIsProperty;
extern NSString * const kABEmailProperty;
extern NSString * const kABAddressProperty;
extern NSString * const kABOtherDatesProperty;
extern NSString * const kABRelatedNamesProperty;
extern NSString * const kABDepartmentProperty;
extern NSString * const kABPersonFlags;
extern NSString * const kABPhoneProperty;
extern NSString * const kABAIMInstantProperty;
extern NSString * const kABJabberInstantProperty;
extern NSString * const kABMSNInstantProperty;
extern NSString * const kABYahooInstantProperty;
extern NSString * const kABICQInstantProperty;
extern NSString * const kABNoteProperty;
extern NSString * const kABMiddleNameProperty;
extern NSString * const kABMiddleNamePhoneticProperty;
extern NSString * const kABTitleProperty;
extern NSString * const kABSuffixProperty;

/** @taskunit Group Properties */

/** <em>name</em> property of type NSString. Same as -[COObject name]. */
extern NSString * const kABGroupNameProperty;
