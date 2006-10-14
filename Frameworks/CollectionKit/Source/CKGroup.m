/*
    CKGroup.m
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

#import <CollectionKit/CKGroup.h>
#import <CollectionKit/CKTypedefs.h>
#import <CollectionKit/CKGlobals.h>
#import <CollectionKit/CKMultiValue.h>
#import <CollectionKit/CKCollection.h>
#import "GNUstep.h"

@interface CKGroup (CKPrivate)
- (NSArray *) _readOnlyArray: (NSArray *) arr;
@end

@implementation CKGroup
+ (void) initialize
{
  NSDictionary *_propTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
	 [NSNumber numberWithInt: CKStringProperty], kCKUIDProperty,
	 [NSNumber numberWithInt: CKStringProperty], kCKGroupNameProperty,
	 [NSNumber numberWithInt: CKArrayProperty], kCKItemsProperty,
	 [NSNumber numberWithInt: CKDateProperty], kCKCreationDateProperty,
	 [NSNumber numberWithInt: CKDateProperty], kCKModificationDateProperty,
		 nil];
  [CKGroup addPropertiesAndTypes: _propTypes];
}

- (NSArray*) items
{
  NSAssert([self collection], @"Collection must be set!");
  NSArray *arr = [[self collection] itemsForGroup: self];
  
  if ([self isReadOnly]) 
    return [self _readOnlyArray: arr];

  return arr;
}

- (BOOL) addItem: (CKItem *) person
{
  NSAssert([self collection], @"Collection must be set!");

  if ([self isReadOnly]) 
    return NO;
  return [[self collection] addItem: person forGroup: self];
}

- (BOOL) removeItem: (CKItem *) person
{
  NSAssert([self collection], @"Address book must be set!");

  if ([self isReadOnly]) 
    return NO;
  return [[self collection] removeItem: person forGroup: self];
}

- (NSArray*) subgroups
{
  NSAssert([self collection], @"Collection must be set!");
  NSArray *arr = [[self collection] subgroupsForGroup: self];

  if ([self isReadOnly]) 
    return [self _readOnlyArray: arr];

  return arr;
}

- (BOOL) addSubgroup: (CKGroup*) group
{
  NSAssert([self collection], @"Collection must be set!");

  if ([self isReadOnly]) 
    return NO;

  return [[self collection] addSubgroup: group forGroup: self];
}

- (BOOL) removeSubgroup: (CKGroup*) group
{
  NSAssert([self collection], @"Collection must be set!");

  if ([self isReadOnly]) 
    return NO;

  return [[self collection] removeSubgroup: group forGroup: self];
}

- (NSArray*) parentGroups
{
  NSAssert([self collection], @"Collection must be set!");
  return [[self collection] parentGroupsForGroup: self];
}

- (BOOL) setDistributionIdentifier: (NSString *) identifier
		       forProperty: (NSString *) property
			      item: (CKItem *) person
{
  [NSException raise: CKUnimplementedError
	       format: @"Distribution identifiers not yet implemented"];
  return NO;
}

- (NSString*) distributionIdentifierForProperty: (NSString *) property
					   item: (CKItem *) person
{
  [NSException raise: CKUnimplementedError
	       format: @"Distribution identifiers not yet implemented"];
  return nil;
}

#if 0
+ (CKSearchElement*) searchElementForProperty: (NSString*) property 
					label: (NSString*) label 
					  key: (NSString*) key 
					value: (id) value 
				   comparison: (CKSearchComparison) comparison
{
  return [[[CKRecordSearchElement alloc]
	    initWithProperty: property
	    label: label
	    key: key
	    value: value
	    comparison: comparison]
	   autorelease];
}
#endif

- (BOOL) setValue: (id) value
      forProperty: (NSString *) property
{
  if([self isReadOnly])
    return NO;

  if(([[self class] typeOfProperty: property] & CKMultiValueMask) &&
     ([property isKindOfClass: [CKMutableMultiValue class]]))
    {
      // make sure no mutable multivalues are inserted
      CKMultiValue *mv;

      mv = [[[CKMultiValue alloc] initWithMultiValue: value]
	     autorelease];
      return [self setValue: mv forProperty: property];
    }
  return [super setValue: value forProperty: property];
}

@end

@implementation CKGroup (CKExtensions)
- (id) initWithContentDictionary: (NSDictionary *) dict
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary: dict];
  self = [super initWithContentDictionary: d];

  NSArray *members = [dict objectForKey: kCKItemsProperty];
#if 0
  if (members)
  {
    [self setValue: members forProperty: kCKItemsProperty];
    [d removeObjectForKey: kCKItemsProperty];
  }
  else
  {
    [self setValue: [NSArray array] forProperty: kCKItemsProperty];
  }
#else
  if (members == nil)
  {
    [self setValue: [NSArray array] forProperty: kCKItemsProperty];
  }
#endif
  return self;
}
@end

@implementation CKGroup (CKPrivate)
- (NSArray *) _readOnlyArray: (NSArray *) arr
{
  NSMutableArray *retval; 
  NSEnumerator *e; 
  CKRecord *r;

  retval = [NSMutableArray arrayWithCapacity: [arr count]];
  e = [arr objectEnumerator];

  while((r = [e nextObject]))
    {
      r = [[r copy] autorelease];
      [r setReadOnly];
      [retval addObject: r];
    }

  return [NSArray arrayWithArray: retval];
}
@end
