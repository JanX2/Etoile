// ADAddressBook.m (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Implementation of Apple's AddressBook API
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.2 $
// $Date: 2004/06/14 05:48:08 $

/* system includes */
/* (none) */

/* my includes */
#include "ADAddressBook.h"
#include "ADEnvelopeAddressBook.h"
#include "ADRecord.h"
#include "ADPerson.h"
#include "ADGroup.h"

@implementation ADAddressBook
+ (ADAddressBook*) sharedAddressBook
{
  return [ADEnvelopeAddressBook sharedAddressBook];
}

- (NSArray*) subgroupsOfGroup: (ADGroup*) group
	matchingSearchElement: (ADSearchElement*) search
{
  NSMutableArray *arr;
  NSEnumerator *e; ADGroup *g;

  arr = [NSMutableArray array];
  e = [[group subgroups] objectEnumerator];
  while((g = [e nextObject]))
    {
      if([search matchesRecord: g])
	[arr addObject: g];
      [arr addObjectsFromArray: [self subgroupsOfGroup: g
				      matchingSearchElement: search]];
    }
  return [NSArray arrayWithArray: arr];
}

- (NSArray*) recordsMatchingSearchElement: (ADSearchElement*) search
{
  NSMutableArray *arr;
  NSEnumerator *e; ADPerson *p; ADGroup *g;

  arr = [NSMutableArray array];
  e = [[self people] objectEnumerator];
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

- (BOOL) save
{ [self subclassResponsibility: _cmd]; return NO; }
- (BOOL) hasUnsavedChanges
{ [self subclassResponsibility: _cmd]; return NO; }

- (ADPerson*) me
{ [self subclassResponsibility: _cmd]; return nil; }
- (void) setMe: (ADPerson*) me
{ [self subclassResponsibility: _cmd]; }

- (ADRecord*) recordForUniqueId: (NSString*) uniqueId
{ [self subclassResponsibility: _cmd]; return nil; }

- (BOOL) addRecord: (ADRecord*) record
{ [self subclassResponsibility: _cmd]; return NO; }
- (BOOL) removeRecord: (ADRecord*) record
{ [self subclassResponsibility: _cmd]; return NO; }

- (NSArray*) people
{ [self subclassResponsibility: _cmd]; return nil; }
- (NSArray*) groups
{ [self subclassResponsibility: _cmd]; return nil; }

@end

@implementation ADAddressBook(GroupAccess)
- (NSArray*) membersForGroup: (ADGroup*) group
{ [self subclassResponsibility: _cmd]; return nil; }
- (BOOL) addMember: (ADPerson*) person forGroup: (ADGroup*) group
{ [self subclassResponsibility: _cmd]; return NO; }
- (BOOL) removeMember: (ADPerson*) person forGroup: (ADGroup*) group
{ [self subclassResponsibility: _cmd]; return NO; }

- (NSArray*) subgroupsForGroup: (ADGroup*) group
{ [self subclassResponsibility: _cmd]; return nil; }
- (BOOL) addSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{ [self subclassResponsibility: _cmd]; return NO; }
- (BOOL) removeSubgroup: (ADGroup*) g1 forGroup: (ADGroup*) g2
{ [self subclassResponsibility: _cmd]; return NO; }
- (NSArray*) parentGroupsForGroup: (ADGroup*) group;
{ [self subclassResponsibility: _cmd]; return nil; }
@end

@implementation ADAddressBook(AddressesExtensions)
- (NSArray*) _groupOrSubgroups: (ADGroup*) g
	      containingRecord: (ADRecord*) record
{
  NSMutableArray *retval;
  NSArray *s;
  int i;

  retval = [NSMutableArray array];
  s = [g subgroups];

  // is it a group?
  if([record isKindOfClass: [ADGroup class]])
    {
      for(i=0; i<[s count]; i++)
	if([[[s objectAtIndex: i] uniqueId]
	     isEqualToString: [record uniqueId]])
	  {
	    [retval addObject: self];
	    break;
	  }
    }
  else
    {
      // no? then it's a person 
      NSArray *m;

      m = [g members];
      for(i=0; i<[m count]; i++)
	if([[[m objectAtIndex: i] uniqueId]
	     isEqualToString: [record uniqueId]])
	  {
	    [retval addObject: self];
	    break;
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
  
- (NSArray*) groupsContainingRecord: (ADRecord*) record
{
  NSEnumerator *e;
  ADGroup *g;
  NSMutableArray *m;

  e = [[self groups] objectEnumerator];
  m = [NSMutableArray array];
  while((g = [e nextObject]))
    {
      NSArray *a;

      a = [self _groupOrSubgroups: g
		containingRecord: record];
      if([a count])
	[m addObjectsFromArray: a];
    }

  return [NSArray arrayWithArray: m];
}

- (NSDictionary*) addressBookDescription
{
  return [NSDictionary dictionaryWithObjectsAndKeys: [self className],
		       @"Class", nil];
}
@end
@implementation ADAddressBook(ImageDataFile)
- (BOOL) setImageDataForPerson: (ADPerson*) person
		      withFile: (NSString*) filename
{
	return NO;
}
- (NSString*) imageDataFileForPerson: (ADPerson*) person
{
	return nil;
}
@end
