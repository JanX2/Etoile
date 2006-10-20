/*
    CKCollection.h
    Copyright (C) <2006> Yen-Ju Chen <gmail>
    Copyright (C) <2005> Bjoern Giesler <bjoern@giesler.de>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301      USA
*/

#import <Foundation/Foundation.h>
#import <CollectionKit/CKTypedefs.h>
#import <CollectionKit/CKGlobals.h>

@class CKRecord;
@class CKItem;
@class CKGroup;
@class CKSearchElement;

/* Collection is saved as property list of NSDictionary.
 * Keys are UID of records, which can be item or group.
 */

@interface CKCollection: NSObject
{
  NSString *_loc;
  NSMutableDictionary *_items;
  NSMutableDictionary *_groups;
  BOOL hasUnsavedChanges;
  Class itemClass;
  Class groupClass;
}

/* Load collection from file */
- (id) initWithLocation: (NSString*) location;
/* Specify the classes for item and group.
 * This methid is for subclass of CKCollection */
- (id) initWithLocation: (NSString*) location
              itemClass: (Class) itemClass
             groupClass: (Class) groupClass;

- (NSString*) location;
- (NSArray*) recordsMatchingSearchElement: (CKSearchElement*) search;

/** Reload from saved database. Used when database is externally modified **/
- (BOOL) reload; 
- (BOOL) save;
- (BOOL) hasUnsavedChanges;

- (CKRecord *) recordForUniqueID: (NSString *) uniqueId;

- (BOOL) addRecord: (CKRecord *) record;
- (BOOL) removeRecord: (CKRecord *) record;

- (NSArray*) items;
- (NSArray*) groups;
@end

@interface CKCollection (CKGroupAccess)
- (NSArray*) itemsForGroup: (CKGroup *) group;
- (BOOL) addItem: (CKItem *) item forGroup: (CKGroup*) group;
- (BOOL) removeItem: (CKItem *) item forGroup: (CKGroup*) group;

- (NSArray*) subgroupsForGroup: (CKGroup*) group;
- (BOOL) addSubgroup: (CKGroup*) g1 forGroup: (CKGroup*) g2;
- (BOOL) removeSubgroup: (CKGroup*) g1 forGroup: (CKGroup*) g2;
- (NSArray*) parentGroupsForGroup: (CKGroup*) group;
@end

@interface CKCollection (CKExtensions)
- (NSArray*) groupsContainingRecord: (CKRecord*) record;
- (NSDictionary*) collectionDescription;
@end

