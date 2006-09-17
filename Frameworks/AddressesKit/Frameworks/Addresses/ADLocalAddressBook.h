// ADLocalAddressBook.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
//
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADLOCALADDRESSBOOK_H
#define ADLOCALADDRESSBOOK_H

/* system includes */
#include <Addresses/ADAddressBook.h>
#include <Addresses/ADGroup.h>

/* my includes */
/* (none) */

@interface ADLocalAddressBook: ADAddressBook
{
  NSString *_loc;
  NSMutableDictionary *_unsaved;
  NSMutableDictionary *_deleted;
  NSMutableDictionary *_cache;
}

+ (NSString*) defaultLocation;
+ (void) setDefaultLocation: (NSString*) location;

+ (ADAddressBook*) sharedAddressBook;

+ (BOOL) makeLocalAddressBookAtLocation: (NSString*) location;

- initWithLocation: (NSString*) location;
- (NSString*) location;
@end

@interface ADLocalAddressBook(GroupAccess)
- (NSArray*) membersForGroup: (ADGroup*) group;
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group;
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group;

- (NSArray*) subgroupsForGroup: (ADGroup*) group;
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2;
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
@end

@interface ADLocalAddressBook(ImageDataFile)
- (BOOL) setImageDataForPerson: (ADPerson*) person
		      withFile: (NSString*) filename;
- (NSString*) imageDataFileForPerson: (ADPerson*) person;
@end
#endif /* ADLOCALADDRESSBOOK_H */
