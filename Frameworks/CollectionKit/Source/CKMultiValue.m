/*
    CKMultiValue.m
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

#import <CollectionKit/CKMultiValue.h>
#import "GNUstep.h"

static NSString *CKMultiValue_ValueKey = @"Value";
static NSString *CKMultiValue_LabelKey = @"Label";
static NSString *CKMultiValue_IDKey = @"ID";

#define IS_A(obj,cls) [obj isKindOfClass: [cls class]]

static CKPropertyType _propTypeFromDict(NSDictionary *dict)
{
  id obj = [dict objectForKey: CKMultiValue_ValueKey];
  
  if(IS_A(obj, NSString))
    return CKStringProperty;
  if(IS_A(obj, NSDate))
    return CKDateProperty;
  if(IS_A(obj, NSArray))
    return CKArrayProperty;
  if(IS_A(obj, NSDictionary))
    return CKDictionaryProperty;
  if(IS_A(obj, NSData))
    return CKDataProperty;
  if(IS_A(obj, NSValue))
    return CKIntegerProperty;
  if(IS_A(obj, NSNumber))
    return CKRealProperty;

  return CKErrorInProperty;
}

@interface CKMultiValue (CKPrivate)
- (NSArray*) array;
- (CKPropertyType) type;
@end

@implementation CKMultiValue
- (id)initWithMultiValue: (CKMultiValue*) mv
{
  self = [self init];
  ASSIGN(_arr, AUTORELEASE([[mv array] mutableCopy])); 
  ASSIGNCOPY(_primaryId, [mv primaryIdentifier]);
  _type = [mv type];
  return self;
}

- (id) initWithType: (CKPropertyType) type
{
  self = [self init];
  ASSIGN(_arr, AUTORELEASE([[NSMutableArray alloc] initWithCapacity: 5]));
  _primaryId = nil;
  _type = type;
  return self;
}

- (id) initWithType: (CKPropertyType) type contentArray: (NSArray *) array
{
  self = [self initWithType: type];
  ASSIGN(_arr, AUTORELEASE([array mutableCopy]));
  return self;
}


- (void) dealloc
{
  DESTROY(_arr);
  DESTROY(_primaryId);
  [super dealloc];
}

- (NSArray*) contentArray
{
  return _arr;
}

- (unsigned int) count
{
  return [_arr count];
}

- (id) valueAtIndex: (int) index
{
  if (index >= [_arr count]) return nil;
  return [(NSDictionary *)[_arr objectAtIndex: index] objectForKey: CKMultiValue_ValueKey];
}

- (NSString*) labelAtIndex: (int) index
{
  if (index >= [_arr count]) return nil;
  return [(NSDictionary *)[_arr objectAtIndex: index] objectForKey: CKMultiValue_LabelKey];
}

- (NSString*) identifierAtIndex: (int) index
{
  if (index >= [_arr count]) return nil;
  return [(NSDictionary *)[_arr objectAtIndex: index] objectForKey: CKMultiValue_IDKey];
}

- (int) indexForIdentifier: (NSString*) identifier
{
  int i;

  for(i=0; i<[_arr count]; i++)
    if([[(NSDictionary *)[_arr objectAtIndex: i] objectForKey: CKMultiValue_IDKey]
	 isEqualToString: identifier])
      return i;
  return NSNotFound;
}

- (NSString*) primaryIdentifier
{
  return _primaryId;
}

- (CKPropertyType) propertyType
{
  NSEnumerator *e;
  id obj;
  CKPropertyType assumedType;

  if(![_arr count])
    return CKErrorInProperty;

  e = [_arr objectEnumerator];
  obj = [e nextObject];
  assumedType = _propTypeFromDict(obj);
  while((obj = [e nextObject]))
    if(assumedType != _propTypeFromDict(obj))
      return CKErrorInProperty;

  return assumedType;
}

- (NSString*) description
{
  return [_arr description];
}

- (id) copyWithZone: (NSZone*) zone
{
  return [[CKMultiValue alloc] initWithMultiValue: self];
}

- (id) mutableCopyWithZone: (NSZone*) zone
{
  return [[CKMutableMultiValue alloc] initWithMultiValue: self];
}
@end

@implementation CKMultiValue (Private)
- (NSArray*) array
{
  return _arr;
}

- (CKPropertyType) type
{
  return _type;
}
@end

@implementation CKMutableMultiValue
- (id) initWithType: (CKPropertyType) type
{
  self = [super initWithType: type];
  _nextId = 0;
  return self;
}

- (NSString*) _nextValidID
{
  NSEnumerator *e;
  NSDictionary *dict;
  int max;

  e = [_arr objectEnumerator];
  max = 0;
  while((dict = [e nextObject]))
    max = MAX(max, [[dict objectForKey: CKMultiValue_IDKey] intValue]);
  
  return [NSString stringWithFormat: @"%d", max+1];
}

- (NSString*) addValue: (id) value
	     withLabel: (NSString*) label
{
  NSString *identifier;
  NSMutableDictionary *dict;

  identifier = [self _nextValidID];
  dict = [NSMutableDictionary dictionary];
  
  // make sure nothing mutable gets added
  if(_type == CKMultiArrayProperty &&
     [value isKindOfClass: [NSMutableArray class]])
    value = [NSArray arrayWithArray: value];
  else if(_type == CKMultiDictionaryProperty &&
	  [value isKindOfClass: [NSMutableDictionary class]])
    value = [NSDictionary dictionaryWithDictionary: value];
  else if(_type == CKMultiDataProperty &&
	  [value isKindOfClass: [NSMutableData class]])
    value = [NSData dataWithData: value];
  
  if(value) [dict setObject: value forKey: CKMultiValue_ValueKey];
  if(label) [dict setObject: label forKey: CKMultiValue_LabelKey];
  [dict setObject: identifier forKey: CKMultiValue_IDKey];

  [_arr addObject: [NSDictionary dictionaryWithDictionary: dict]];

  return identifier;
}

- (NSString *) insertValue: (id) value
		 withLabel: (NSString*) label
		   atIndex: (int) index
{
  NSString* identifier;
  NSMutableDictionary *dict;

  identifier = [self _nextValidID];

  // make sure nothing mutable gets added
  if(_type == CKMultiArrayProperty &&
     [value isKindOfClass: [NSMutableArray class]])
    value = [NSArray arrayWithArray: value];
  else if(_type == CKMultiDictionaryProperty &&
	  [value isKindOfClass: [NSMutableDictionary class]])
    value = [NSDictionary dictionaryWithDictionary: value];
  else if(_type == CKMultiDataProperty &&
	  [value isKindOfClass: [NSMutableData class]])
    value = [NSData dataWithData: value];
  
  dict = [NSDictionary dictionaryWithObjectsAndKeys:
			 value, CKMultiValue_ValueKey,
		       label, CKMultiValue_LabelKey,
		       identifier, CKMultiValue_IDKey,
		       nil];

  [_arr insertObject: dict atIndex: index];

  return identifier;
}

- (BOOL) removeValueAndLabelAtIndex: (int) index
{
  if(index < 0 || index >= [_arr count]) return NO;
  [_arr removeObjectAtIndex: index];

  return YES;
}

- (BOOL) replaceValueAtIndex: (int) index
		   withValue: (id) value
{
  NSMutableDictionary *dict;

  if(index < 0 || index >= [_arr count]) return NO;

  // make sure nothing mutable gets added
  if(_type == CKMultiArrayProperty &&
     [value isKindOfClass: [NSMutableArray class]])
    value = [NSArray arrayWithArray: value];
  else if(_type == CKMultiDictionaryProperty &&
	  [value isKindOfClass: [NSMutableDictionary class]])
    value = [NSDictionary dictionaryWithDictionary: value];
  else if(_type == CKMultiDataProperty &&
	  [value isKindOfClass: [NSMutableData class]])
    value = [NSData dataWithData: value];
  
  dict = [NSMutableDictionary
	   dictionaryWithDictionary: [_arr objectAtIndex: index]];
  [dict setObject: value forKey: CKMultiValue_ValueKey];
  [_arr replaceObjectAtIndex: index withObject: dict];
  
  return YES;
}

- (BOOL) replaceLabelAtIndex: (int) index
		   withLabel: (NSString*) label
{
  NSMutableDictionary *dict;

  if(index < 0 || index >= [_arr count]) return NO;
  dict = [NSMutableDictionary
	   dictionaryWithDictionary: [_arr objectAtIndex: index]];
  [dict setObject: label forKey: CKMultiValue_LabelKey];
  [_arr replaceObjectAtIndex: index withObject: dict];

  return YES;
}

- (BOOL)setPrimaryIdentifier:(NSString *)identifier
{
  ASSIGNCOPY(_primaryId, identifier);
  return YES;
}
@end

