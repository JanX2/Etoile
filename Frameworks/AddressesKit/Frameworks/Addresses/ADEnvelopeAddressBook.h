// ADEnvelopeAddressBook.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.2 $
// $Date: 2004/06/14 05:48:08 $

#ifndef ADENVELOPEADDRESSBOOK_H
#define ADENVELOPEADDRESSBOOK_H

/* system includes */
#include <Addresses/ADAddressBook.h>

/* my includes */
/* (none) */

@interface ADEnvelopeAddressBook: ADAddressBook
{
  NSMutableArray *_books;
  ADAddressBook *_primary;
  BOOL _merge;
}
  
+ (ADAddressBook*) sharedAddressBook;

- initWithPrimaryAddressBook: (ADAddressBook*) book;

- (BOOL) addAddressBook: (ADAddressBook*) book;
- (BOOL) removeAddressBook: (ADAddressBook*) book;

- (void) setPrimaryAddressBook: (ADAddressBook*) book;
- (ADAddressBook*) primaryAddressBook;
- (NSEnumerator*) addressBooksEnumerator;

- (void) setMergesAddressBooks: (BOOL) merge;
- (BOOL) mergesAddressBooks;
@end

#endif /* ADENVELOPEADDRESSBOOK_H */
