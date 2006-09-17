// ADPublicAddressBook.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADPUBLICADDRESSBOOK_H
#define ADPUBLICADDRESSBOOK_H

/* system includes */
/* (none) */

/* my includes */
#include "ADAddressBook.h"

@interface ADPublicAddressBook: ADAddressBook
{
  BOOL _readOnly;
  ADAddressBook *_book;
}

- initWithAddressBook: (ADAddressBook*) book
	     readOnly: (BOOL) ro;
@end

@protocol ADSimpleAddressBookServing
- (ADAddressBook*) addressBookForReadOnlyAccessWithAuth: (id) auth;
- (ADAddressBook*) addressBookForReadWriteAccessWithAuth: (id) auth;
@end

#endif /* ADPUBLICADDRESSBOOK_H */
