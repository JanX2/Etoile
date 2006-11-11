/*
    CKItem.m
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

#import <CollectionKit/CKItem.h>
#import <CollectionKit/CKGlobals.h>
#import <CollectionKit/CKTypedefs.h>
#import <CollectionKit/CKMultiValue.h>
#import <CollectionKit/CKCollection.h>
#import "GNUstep.h"

@implementation CKItem

+ (void) initialize
{
  NSDictionary *_propTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
	[NSNumber numberWithInt: CKStringProperty], kCKUIDProperty,
	[NSNumber numberWithInt: CKDateProperty], kCKCreationDateProperty,
	[NSNumber numberWithInt: CKDateProperty], kCKModificationDateProperty,
		 nil];
  [CKItem addPropertiesAndTypes: _propTypes];
  DESTROY(_propTypes);
}

+ (CKSearchElement*) searchElementForProperty: (NSString*) property 
				        label: (NSString*) label 
				 	  key: (NSString*) key 
				        value: (id) value 
				   comparison: (CKSearchComparison) comparison
{
  return AUTORELEASE([[CKRecordSearchElement alloc]
	                       initWithProperty: property
	                       label: label
	                       key: key
	                       value: value
	                       comparison: comparison]);
}

- (id) valueForProperty: (NSString*) property
{
  id val;
  CKPropertyType type;

  val = [super valueForProperty: property];
  type = [[self class] typeOfProperty: property];
  // multi-value? If so, create empty one and put it in
  if(!val && (type & CKMultiValueMask) && ![self isReadOnly])
    {
      NSMutableDictionary *newDict;
      
      val = [[[CKMultiValue alloc] initWithType: type] autorelease];
      newDict = [NSMutableDictionary dictionaryWithDictionary: _dict];
      [newDict setObject: val forKey: property];
      ASSIGN(_dict, AUTORELEASE([[NSDictionary alloc] initWithDictionary: newDict]));
    }

  return val;
}

- (BOOL) setValue: (id) value forProperty: (NSString *) property
{
  if([self isReadOnly])
    return NO;
  if(([[self class] typeOfProperty: property] & CKMultiValueMask) &&
     ([value isKindOfClass: [CKMutableMultiValue class]]))
    {
      // make sure no mutable multivalues are inserted
      CKMultiValue *mv = [[CKMultiValue alloc] initWithMultiValue: value];
      return [super setValue: AUTORELEASE(mv) forProperty: property];
    }
  return [super setValue: value forProperty: property];
}

- (NSArray*) parentGroups
{
  if(![self collection])
    return [NSArray array];

  return [[self collection] groupsContainingRecord: self];
}

@end

