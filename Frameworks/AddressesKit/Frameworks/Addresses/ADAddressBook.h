// ADAddressBook.h (this is -*- ObjC -*-)
// 
// \author: BjÅˆrn Giesler <bjoern@giesler.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:01 $

#ifndef ADADDRESSBOOK_H
#define ADADDRESSBOOK_H

/* system includes */
#include <Foundation/Foundation.h>

/* my includes */
#include <Addresses/ADTypedefs.h>
#include <Addresses/ADGlobals.h>

@class ADRecord;
@class ADPerson;
@class ADGroup;
@class ADSearchElement;
@class ADConverter;

@interface ADAddressBook: NSObject
+ (ADAddressBook*) sharedAddressBook;

- (NSArray*) recordsMatchingSearchElement: (ADSearchElement*) search;

- (BOOL) save;
- (BOOL) hasUnsavedChanges;

- (ADPerson*) me;
- (void) setMe: (ADPerson*) me;

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId;

- (BOOL) addRecord: (ADRecord*) record;
- (BOOL) removeRecord: (ADRecord*) record;

- (NSArray*) people;
- (NSArray*) groups;
@end

@interface ADAddressBook(GroupAccess)
- (NSArray*) membersForGroup: (ADGroup*) group;
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group;
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group;

- (NSArray*) subgroupsForGroup: (ADGroup*) group;
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
@end

@interface ADAddressBook(AddressesExtensions)
- (NSArray*) groupsContainingRecord: (ADRecord*) record;
- (NSDictionary*) addressBookDescription;
@end
#endif /* ADADDRESSBOOK_H */
