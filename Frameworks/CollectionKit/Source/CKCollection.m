/*
    CKCollection.m
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

#import <CollectionKit/CKCollection.h>
#import <CollectionKit/CKRecord.h>
#import <CollectionKit/CKItem.h>
#import <CollectionKit/CKGroup.h>
#import <CollectionKit/CKSearchElement.h>
#import "GNUstep.h"

@interface CKCollection (CKPrivate)
/* Load format with version 0.1 */
- (void) _loadFormat_0_1: (NSDictionary *) dict;
- (BOOL) _makeDirectory: (NSString*) path;
- (void) _handleRecordChanged: (NSNotification*) note;
- (void) _handleDBChangedExternally: (NSNotification*) note;
- (NSArray*) _allSubgroupsBelowGroup: (CKGroup*) group;
- (BOOL) removeRecord: (CKRecord*) record
	     forGroup: (CKGroup*) group
	    recursive: (BOOL) recursive;
/* Put all subgroup into set. */
- (void) collectSubgroup: (CKGroup *) group
                 withSet: (NSMutableSet *) set;
@end

@implementation CKCollection (CKPrivate)
- (void) _loadFormat_0_1: (NSDictionary *) dict 
{
  id object;
  NSDictionary *temp;
  NSEnumerator *e;
  NSString *uid;
  CKItem *item;
  CKGroup *group;

  /* Load group */
  temp = [dict objectForKey: CKGroupsKey];
  e = [[temp allKeys] objectEnumerator];;
  while ((uid = [e nextObject]))
  {
    group = [[groupClass alloc] initWithContentDictionary: [temp objectForKey: uid]];
    [group setCollection: self];
    [_groups setObject: group forKey: uid];
    DESTROY(group);
  }

  /* Load item */
  temp = [dict objectForKey: CKItemsKey];
  e = [[temp allKeys] objectEnumerator];
  while ((uid = [e nextObject]))
  { 
    item = [[itemClass alloc] initWithContentDictionary: [temp objectForKey: uid]];
    [item setCollection: self];
    [_items setObject: item forKey: uid];
    DESTROY(item);
  }

  /* Load config */
  object = [dict objectForKey: CKConfigKey];
  if (object) {
    ASSIGN(config, object);
  }
}

- (BOOL) _makeDirectory: (NSString*) location
{
  int i;
  NSString *currentPath;
  NSFileManager *fm;
  NSArray *arr;

  fm = [NSFileManager defaultManager];
  location = [location stringByExpandingTildeInPath];
  arr = [location pathComponents];
  currentPath = [arr objectAtIndex: 0];

  for(i=1; i<[arr count]; i++)
    {
      BOOL dir, result;
      
      currentPath = [currentPath
		      stringByAppendingPathComponent: [arr objectAtIndex: i]];

      result = [fm fileExistsAtPath: currentPath isDirectory: &dir];
      if((result == YES) && (dir == NO))
	return NO;

      if(result == NO)
	result = [fm createDirectoryAtPath: currentPath attributes: nil];

      if(result == NO)
	return NO;
    }

  return YES;
}

- (void) _handleRecordChanged: (NSNotification *) note
{
  CKRecord *record;

  record = [note object];
  if([record collection] != self) return;
  
  if(![record uniqueID])
    return;

  hasUnsavedChanges = YES;

  [[NSNotificationCenter defaultCenter]
    postNotificationName: CKCollectionChangedNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
		      [record uniqueID], CKUIDNotificationKey,
		       self, CKCollectionNotificationKey,
			    nil]];
}

- (void) _handleDBChangedExternally: (NSNotification*) note
{
#if 0
  NSString *obj;
  NSDictionary *info;
  NSString *location, *pid;

  obj = [note object];
  info = [note userInfo];
  
  if(![obj isEqualToString: [self className]])
    return;
  location = [info objectForKey: @"Location"];
  pid = [info objectForKey: @"IDOfChangingProcess"];

  if(!location || !pid)
    return;
  if([location isEqualToString: _loc] &&
     ([pid intValue] != [[NSProcessInfo processInfo] processIdentifier]))
    {
      NSLog(@"Posting\n");
      
      [self _invalidateCache];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: CKCollectionChangedExternallyNotification 
	object: self
	userInfo: [note userInfo]];
    }
#endif
}

- (NSArray*) _allSubgroupsBelowGroup: (CKGroup*) group
{
  NSMutableArray *arr;
  NSEnumerator *e;
  CKGroup *otherGroup;

  arr = [NSMutableArray array];
  e = [[group subgroups] objectEnumerator];  
  while((otherGroup = [e nextObject]))
    {
      NSArray *subgroups = [self _allSubgroupsBelowGroup: otherGroup];
      [arr addObject: otherGroup];
      [arr addObjectsFromArray: subgroups];
    }
  return arr;
}

- (BOOL) removeRecord: (CKRecord*) record
	     forGroup: (CKGroup*) group
	    recursive: (BOOL) recursive
{
  NSString *guid;
  NSString *muid;
  NSMutableArray *memberIds;
  int i; 
  BOOL doneAnything;

  guid = [group uniqueID];
  if(!guid || [group collection] != self)
    {
      NSLog(@"Group being removed from is not part of this collection\n");
      return NO;
    }
  muid = [record uniqueID];
  if(!muid || [record collection] != self)
    {
      NSLog(@"item being removed is not part of this collection\n");
      return NO;
    }

  memberIds = [NSMutableArray
		arrayWithArray: [group valueForProperty: kCKItemsProperty]];
  
  for(i=0; i<[memberIds count]; i++)
    {
      NSString *ruid = [memberIds objectAtIndex: i];
      if([ruid isEqualToString: muid])
	{
	  [memberIds removeObjectAtIndex: i--];
	  doneAnything = YES;
	}
    }

  // was this group changed? put it back
  if(doneAnything)
    [group setValue: memberIds forProperty: kCKItemsProperty];

  if(recursive)
    {
      NSEnumerator *e = nil;
      CKGroup *subgroup = nil;

      e = [[group subgroups] objectEnumerator];
      while((subgroup = [e nextObject]))
	[self removeRecord: record forGroup: subgroup recursive: YES];
    }
      
  return YES;
}

/* Put all subgroup into set. */
- (void) collectSubgroup: (CKGroup *) group
                 withSet: (NSMutableSet *) set
{
  NSArray *groups = [group subgroups];
  int i, count = [groups count];
  for (i = 0; i < count; i++) {
    CKGroup *g = [groups objectAtIndex: i];
    if ([set containsObject: g] == YES) {
      continue;
    } else {
      [set addObject: g];
      [self collectSubgroup: g withSet: set];
    }
  }
}

@end
  
@implementation CKCollection
- (NSArray*) subgroupsOfGroup: (CKGroup*) group
	matchingSearchElement: (CKSearchElement*) search
{
  NSMutableArray *arr;
  NSEnumerator *e; 
  CKGroup *g;

  arr = [NSMutableArray array];
  e = [[group subgroups] objectEnumerator];
  while((g = [e nextObject]))
    {
      if ([search matchesRecord: g])
	[arr addObject: g];
      [arr addObjectsFromArray: [self subgroupsOfGroup: g
				      matchingSearchElement: search]];
    }
  return [NSArray arrayWithArray: arr];
}

- (NSArray*) recordsMatchingSearchElement: (CKSearchElement*) search
{
  NSMutableArray *arr;
  NSEnumerator *e;
  CKItem *p;
  CKGroup *g;

  arr = [NSMutableArray array];
  e = [[self items] objectEnumerator];
  while((p = [e nextObject]))
    if([search matchesRecord: p])
      [arr addObject: p];

  e = [[self groups] objectEnumerator];
  while((g = [e nextObject]))
    {
      if([search matchesRecord: g])
	[arr addObject: g];
      [arr addObjectsFromArray: [self subgroupsOfGroup: g
				      matchingSearchElement: search]];
    }
  return [NSArray arrayWithArray: arr];
}

- (id) initWithLocation: (NSString*) location 
{
  return [self initWithLocation: location 
	              itemClass: [CKItem class]
	             groupClass: [CKGroup class]];
}

- (id) initWithLocation: (NSString*) location 
              itemClass: (Class) ic
	     groupClass: (Class) gc
{
  NSAssert(location, @"Location cannot be nil");

  self = [super init];

  itemClass = ic;
  groupClass = gc;

  ASSIGN(_loc, [location stringByExpandingTildeInPath]);
  if ([self reload] == NO) {
      [NSException raise: CKInternalError
		   format: @"Couldn't open local collection at %@",
		   _loc];
  }

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_handleRecordChanged:)
    name: CKRecordChangedNotification
    object: nil];
  [[NSDistributedNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_handleDBChangedExternally:)
    name: CKCollectionChangedExternallyNotification 
    object: nil];
  
  return self;
}

- (void) dealloc
{
  DESTROY(_loc);
  DESTROY(_items);
  DESTROY(_groups);
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
  [super dealloc];
}

- (NSString*) location
{
  return _loc;
}

- (void) setConfig: (id) c
{
  ASSIGN(config, c);
}

- (id) config
{
  return config;
}

- (BOOL) reload
{
  BOOL dir;
  ASSIGN(_items, AUTORELEASE([[NSMutableDictionary alloc] init]));
  ASSIGN(_groups, AUTORELEASE([[NSMutableDictionary alloc] init]));
  if([[NSFileManager defaultManager] fileExistsAtPath: _loc 
                                          isDirectory: &dir] == NO) 
  {
    /* No collection */
  }
  else
  {
    /* Open existing collection */
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: _loc];
    
    if (dict == nil) {
      return NO;
    }
    /* Check version */
    NSString *version = [dict objectForKey: CKFormatKey];
    if ([version isEqualToString: CKCollectionFormat_0_1]) {
      [self _loadFormat_0_1: dict];
    }
  }
  return YES;
}

- (BOOL) save
{
  /* Save everything on disk */
  NSArray *itemKeys = [_items allKeys];
  NSArray *groupKeys = [_groups allKeys];
  NSMutableDictionary *item_store = [NSMutableDictionary dictionaryWithCapacity: [itemKeys count]];
  NSMutableDictionary *group_store = [NSMutableDictionary dictionaryWithCapacity: [groupKeys count]];

  /* Save items */
  NSEnumerator *e = [itemKeys objectEnumerator];
  NSString *key;
  CKRecord *r;
  while ((key = [e nextObject])) {
    r = [_items objectForKey: key];
    [item_store setObject: [r contentDictionary] forKey: [r uniqueID]];
  }

  /* Save groups */
  e = [groupKeys objectEnumerator];
  while ((key = [e nextObject])) {
    r = [_groups objectForKey: key];
    [group_store setObject: [r contentDictionary] forKey: [r uniqueID]];
  }
  
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          item_store, CKItemsKey, 
                         group_store, CKGroupsKey, 
      [itemClass propertiesAndTypes], CKItemPropertiesKey,
     [groupClass propertiesAndTypes], CKGroupPropertiesKey,
              CKCollectionFormat_0_1, CKFormatKey, 
                      nil];
  if (config) {
    [dict setObject: config forKey: CKConfigKey];
  }

  if ([self _makeDirectory: [_loc stringByDeletingLastPathComponent]]) {
    [dict writeToFile: _loc atomically: YES];
  } else {
    // Should we raise an alert or exception
  }
#if 0
  NSString *pidStr = [NSString stringWithFormat: @"%d",
		     [[NSProcessInfo processInfo] processIdentifier]];
#endif
  [[NSDistributedNotificationCenter defaultCenter]
    postNotificationName: CKCollectionChangedExternallyNotification
    object: [self className]
    userInfo: nil /*[NSDictionary dictionaryWithObjectsAndKeys:
			      _loc, @"Location",
			    pidStr, @"IDOfChangingProcess", nil]*/];
  hasUnsavedChanges = NO;
  return YES;
}

- (BOOL) hasUnsavedChanges
{
  return hasUnsavedChanges;
}

- (CKRecord*) recordForUniqueID: (NSString*) uniqueId
{
  /* Should we check the file again ?
   * It is not that expensive if we load the property list
   * and check for the uniqueID, then extract the specific records.
   */
  CKRecord *temp = nil;
  temp = [_items objectForKey: uniqueId];
  if (temp == nil) {
    temp = [_groups objectForKey: uniqueId];
  }
  return temp;
}

- (BOOL) addRecord: (CKRecord*) r
{
  CKRecord *record;
  NSString *uid;

  uid = [r uniqueID];

  if([r collection])
    {
      NSLog(@"Record is already part of an address book\n");
      record = AUTORELEASE([r copy]);
    }
  else 
    {
      record = r;
    }
      
  [record setCollection: self];
  if ([record isKindOfClass: [CKItem class]]) {
    [_items setObject: record forKey: [record uniqueID]];
  } else if ([record isKindOfClass: [CKGroup class]]) {
    [_groups setObject: record forKey: [record uniqueID]];
  } else {
    [NSException raise: CKConsistencyError
		   format: @"Record %@ is not CKItem nor CKGroup",
		   record];
    return NO;
  }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: CKCollectionChangedNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			    uid, CKUIDNotificationKey,
			    self, CKCollectionNotificationKey,
			    nil]];
  hasUnsavedChanges = YES;
  return YES;
}

- (BOOL) removeRecord: (CKRecord*) record
{
  RETAIN(record); // Must retain. Otherwise, memory leak.

  NSString *uid = [record uniqueID];
  NSEnumerator *e = nil; 
  CKGroup *g = nil;

  if(uid == nil)
    {
      NSLog(@"Record does not contain an UID\n");
      return NO;
    }

  if([record collection] != self)
    {
      NSLog(@"Record is not part of this address book\n");
      return NO;
    }

  /* We need to remove all references to this record from groups first,
   * then remove it from collection.
   * Otherwise, if we remove it from collection first,
   * group will complain that the record is missing before they can remove it.
   */
  e = [[self groups] objectEnumerator];
  while((g = [e nextObject])) {
    [self removeRecord: record forGroup: g recursive: YES];
  }

  if ([record isKindOfClass: [CKItem class]])
    {
      [_items removeObjectForKey: uid];
    }
  else if ([record isKindOfClass: [CKGroup class]])
    {
      g = (CKGroup*)record;
      while([[g subgroups] count])
	[g removeSubgroup: [[g subgroups] objectAtIndex: 0]];
      [_groups removeObjectForKey: uid];
    }
  else 
    {
      [NSException raise: CKConsistencyError
 		  format: @"Record %@ is not CKItem nor CKGroup", record];
      return NO;
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: CKCollectionChangedNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      uid, CKUIDNotificationKey,
			    self, CKCollectionNotificationKey,
			    nil]];
  hasUnsavedChanges = YES;
  RELEASE(record);
  return YES;
}

- (NSArray*) items 
{
  return [_items allValues];
}

- (NSArray*) groups
{
  return [_groups allValues];
}

@end 

@implementation CKCollection (CKGroupAccess)
- (NSArray*) recordsInGroup: (CKGroup*) group withClass: (Class) class
{
  NSMutableArray *members;
  NSMutableArray *memberIds;
  NSString *guid;
  int i;

  guid = [group uniqueID];
  if(!guid || [group collection] != self)
    {
      NSLog(@"Group being examined is not part of this collection\n");
      return nil;
    }

  members = [NSMutableArray array];
  memberIds = [group valueForProperty: kCKItemsProperty];
  for(i=0; i<[memberIds count]; i++)
    {
      CKRecord *r = [self recordForUniqueID: [memberIds objectAtIndex: i]];
      if(r == nil)
	{
	  NSLog(@"Error: Member %@ still in group, but doesn't exist\n",
		[memberIds objectAtIndex: i]);
	  [memberIds removeObjectAtIndex: i--]; continue;
	}
      if([r isKindOfClass: class])
	[members addObject: r];
    }
  return [NSArray arrayWithArray: members];
}

- (NSArray*) itemsForGroup: (CKGroup*) group
{
  return [self recordsInGroup: group withClass: [CKItem class]];
}

- (NSArray *) itemsUnderGroup: (CKGroup *) group
{
  if (group == nil) {
    return [self items];
  }

  NSMutableSet *set = AUTORELEASE([[NSMutableSet alloc] init]);
  [self collectSubgroup: group withSet: set];

  NSArray *groups = [set allObjects];
  NSMutableSet *items = AUTORELEASE([[NSMutableSet alloc] init]);
  int i, count = [groups count];
  CKGroup *g = nil;
  for (i = 0; i < count; i++) {
    g = [groups objectAtIndex: i];
    [items addObjectsFromArray: [g items]];
  } 
  [items addObjectsFromArray: [group items]];
  return [items allObjects];
}


- (BOOL) addRecord: (CKRecord*) record forGroup: (CKGroup*) group
{
  NSString *guid;
  NSString *muid;
  NSMutableArray *memberIds;

  guid = [group uniqueID];
  if(!guid || [group collection] != self)
    {
      NSLog(@"Group being added to is not part of this collection\n");
      return NO;
    }

  muid = [record uniqueID];
  if([record collection] != self)
    {
      if([record isKindOfClass: [CKGroup class]] &&
	 ![record collection])
	{
	  [record setCollection: self];
	}
      else
	{
	  NSLog(@"Member being added to group has no UID\n");
	  return NO;
	}
    }

  memberIds = [NSMutableArray
		arrayWithArray: [group valueForProperty: kCKItemsProperty]];
  if(!memberIds)
    {
      memberIds = [[[NSMutableArray alloc] init] autorelease];
      [group setValue: memberIds forProperty: kCKItemsProperty];
    }
  if([memberIds containsObject: muid])
    {
      NSLog(@"Record %@ already is a member of group\n", muid);
      return NO;
    }

  [memberIds addObject: muid];
  [group setValue: memberIds forProperty: kCKItemsProperty];

  return YES;
}

- (BOOL) addItem: (CKItem *) person forGroup: (CKGroup*) group
{
  return [self addRecord: person forGroup: group];
}

- (BOOL) removeRecord: (CKRecord*) record forGroup: (CKGroup*) group
{
  return [self removeRecord: record forGroup: group recursive: NO];
}

- (BOOL) removeItem: (CKItem *) person forGroup: (CKGroup*) group
{
  return [self removeRecord: person forGroup: group];
}

- (NSArray*) subgroupsForGroup: (CKGroup*) group
{
  return [self recordsInGroup: group withClass: [CKGroup class]];
}

- (BOOL) addSubgroup: (CKGroup*) g1 forGroup: (CKGroup*) g2
{
  return [self addRecord: g1 forGroup: g2];
}

- (BOOL) removeSubgroup: (CKGroup*) g1 forGroup: (CKGroup*) g2
{
  NSArray *arr;
  int i;

  arr = [self subgroupsForGroup: g1];
  for(i=0; i<[arr count]; i++)
    [self removeSubgroup: [arr objectAtIndex: i] forGroup: g1];

  [self removeRecord: g1 forGroup: g2];

#if 0
  // when a subgroup gets removed from the last parent group, it is
  // deleted, as opposed to when a person is removed.
  arr = [self parentGroupsForGroup: g1];
  if(![arr count])
    [_deleted setObject: g1 forKey: [g1 uniqueID]];
#endif

  hasUnsavedChanges = YES;

  return YES;
}

- (NSArray*) parentGroupsForGroup: (CKGroup*) group
{
  NSMutableArray *arr;
  NSEnumerator *e;
  CKGroup *g;
  NSString *guid;

  guid = [group uniqueID];
  if(!guid || [group collection] != self)
    {
      NSLog(@"Group being removed from is not part of this address book\n");
      return NO;
    }

  arr = [NSMutableArray array];
  e = [[_groups allValues] objectEnumerator];
  while((g = [e nextObject]))
    if([[g valueForProperty: kCKItemsProperty] containsObject: guid])
      [arr addObject: g];
  return [NSArray arrayWithArray: arr];
}
@end 

@implementation CKCollection (CKExtensions)
- (NSArray*) _groupOrSubgroups: (CKGroup*) g
	      containingRecord: (CKRecord*) record
{
  NSMutableArray *retval;
  int i;

  retval = [NSMutableArray array];

  // is it a group?
  NSArray *s = [g subgroups];
  if([record isKindOfClass: [CKGroup class]])
    {
      for(i=0; i<[s count]; i++)
	if([[[s objectAtIndex: i] uniqueID]
	     isEqualToString: [record uniqueID]])
	  {
	    [retval addObject: self];
	    break;
	  }
    }
  else
    {
      // no? then it's a person 
      NSArray *m = [g items];
      for(i=0; i<[m count]; i++) {
	if([[[m objectAtIndex: i] uniqueID]
	     isEqualToString: [record uniqueID]])
	  {
	    [retval addObject: g];
	    break;
	  }
      }
    }
  
  for(i=0; i<[s count]; i++)
    {
      NSArray *a;

      a = [self _groupOrSubgroups: [s objectAtIndex: i]
		containingRecord: record];
      if([a count])
	[retval addObjectsFromArray: a];
    }
  
  return retval;
}
  
- (NSArray*) groupsContainingRecord: (CKRecord *) record
{
  NSEnumerator *e;
  CKGroup *g;
  NSMutableArray *m;

  e = [[self groups] objectEnumerator];
  m = [NSMutableArray array];
  while((g = [e nextObject]))
    {
      NSArray *a = [self _groupOrSubgroups: g containingRecord: record];
      if([a count])
	[m addObjectsFromArray: a];
    }

  return [NSArray arrayWithArray: m];
}

- (NSDictionary*) collectionDescription
{
  return [NSDictionary dictionaryWithObjectsAndKeys: [self className],
		       @"Class", _loc, @"Location", nil];
}
@end
