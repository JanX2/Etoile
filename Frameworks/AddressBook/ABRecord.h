/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

@class ABAddressBook;

/** 
@group Contacts
@abstract AddressBook model object protocol.
 */
@protocol ABRecord
#if 0
/** @taskunit Initialization */

- (id)initWithAddressBook: (ABAddressBook *)aBook;
- (id)init;

/** @taskunit Basic Properties */

- (BOOL)isReadOnly
#endif
@end

