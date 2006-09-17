// ADRecord.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADRECORD_H
#define ADRECORD_H

/* system includes */
#include <Foundation/Foundation.h>

/* my includes */
/* (none) */

@class ADAddressBook;

@interface ADRecord: NSObject <NSCopying>
{
  BOOL _readOnly;
  ADAddressBook *_book;
  NSDictionary *_dict;
}

- (id) valueForProperty: (NSString *) property;
- (BOOL) setValue: (id) value forProperty: (NSString *) property;
- (BOOL) removeValueForProperty: (NSString *) property;

/*!
  \brief Return the address book this record is part of.

  Can return nil, if this is a new record which has not been added to
  any address book yet.
  
  \note This is a non-Apple extension; Apple's API doesn't need it as
  it knows nothing about multiple address books.
*/
- (id) addressBook;

/*!
  \brief Set the address book this record is part of.

  Can only be set once (since a record cannot be *moved* between
  address books); raises if it has been called before, or if book is
  nil.

  \note This is a non-Apple extension; Apple's API doesn't need it as
  it knows nothing about multiple address books.
*/
- (void) setAddressBook: (id) book;
@end

@interface ADRecord(Convenience)
- (NSString*) uniqueId;
@end


// Addresses Extensions
@interface ADRecord(AddressesExtensions)
- (id) initWithRepresentation: (NSString*) str
			 type: (NSString*) type;
- (NSString*) representationWithType: (NSString*) type;

- (BOOL) readOnly;    // return whether this is a read-only record
- (void) setReadOnly; // set this record to be read-only. cannot be reset.

- (NSDictionary*) contentDictionary;
@end
#endif /* ADRECORD_H */
