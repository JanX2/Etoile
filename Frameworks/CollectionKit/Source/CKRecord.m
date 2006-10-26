/*
    CKRecord.m
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
#import <CollectionKit/CKGlobals.h>
#import <CollectionKit/CKMultiValue.h>
#import "GNUstep.h"

static BOOL random_seeded = NO;
static NSMutableDictionary *pDict;

@implementation CKRecord

+ (int) addPropertiesAndTypes: (NSDictionary*) properties
{
  NSMutableDictionary *_propTypes;

  if (pDict == nil) {
    pDict = [[NSMutableDictionary alloc] init];
  }

  _propTypes = [pDict objectForKey: NSStringFromClass([self class])];
  if (_propTypes == nil) {
    _propTypes = [[NSMutableDictionary alloc] init];
    [pDict setObject: _propTypes forKey: NSStringFromClass([self class])];
  }

  int retval = 0;
  NSEnumerator *e;
  NSString *key;

  e = [properties keyEnumerator];
  while((key = [e nextObject]))
    if(![_propTypes objectForKey: key])
      {
        [_propTypes setObject: [properties objectForKey: key]
                    forKey: key];
        retval++;
      }
  return retval;
}

+ (int) removeProperties: (NSArray*) properties
{
  NSMutableDictionary *_propTypes;

  if (pDict == nil) {
    // Nothing to remove 
    return 0;
  }

  _propTypes = [pDict objectForKey: NSStringFromClass([self class])];
  if (_propTypes == nil) {
    // Nothing to remove
    return 0;
  }

  int retval = 0;
  NSEnumerator *e;
  NSString* key;

  e = [properties objectEnumerator];
  while((key = [e nextObject]))
    if([_propTypes objectForKey: key])
      {
        [_propTypes removeObjectForKey: key];
        retval++;
      }
  return retval;
}

+ (NSArray*) properties
{
  NSMutableDictionary *_propTypes;

  if (pDict == nil) {
    // Nothing 
    return nil;
  }

  _propTypes = [pDict objectForKey: NSStringFromClass([self class])];
  if (_propTypes == nil) {
    // Nothing 
    return nil;
  }

  return [_propTypes allKeys];
}

+ (CKPropertyType) typeOfProperty: (NSString*) property
{
  NSMutableDictionary *_propTypes;

  if (pDict == nil) {
    // Nothing 
    return CKErrorInProperty;
  }

  _propTypes = [pDict objectForKey: NSStringFromClass([self class])];
  if (_propTypes == nil) {
    // Nothing to remove
    return CKErrorInProperty;
  }
  id val;

  val = [_propTypes objectForKey: property];
  if(val) return (CKPropertyType)[val intValue];
  return CKErrorInProperty;
}

- (id) init
{
  self = [super init];

  _book = nil;
  _readOnly = NO;

  /* Generate uid */
  NSTimeInterval interval = [NSDate timeIntervalSinceReferenceDate];
  if (random_seeded == NO) {
    srandom((unsigned long)[[NSProcessInfo processInfo] processIdentifier]);
    random_seeded = YES;
  }
  NSString *uid = [NSString stringWithFormat: @"%10.6f.%010ld", interval, random()];

  ASSIGN(_dict, ([NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], kCKCreationDateProperty, [NSDate date], kCKModificationDateProperty, uid, kCKUIDProperty, nil]));

  return self;
}

- (void) dealloc
{
  DESTROY(_dict);
  DESTROY(_book);
  [super dealloc];
}

- (id) valueForProperty: (NSString *) property
{
  return [_dict objectForKey: property];
}

- (BOOL) setValue: (id) value forProperty: (NSString *) property
{
  NSMutableDictionary *newDict;
  
  if(_readOnly)
    {
      NSLog(@"Trying to set value %@ for property %@ in read-only record %@\n",
	    value, property, [self uniqueID]);
      return NO;
    }

  /* Not sure we should prevent people from modifying these properties.
   * If we allow kCKUIDProperty to be changed,
   * -copyWithZone: need to be changed to ignore copying UID.
   */
  if([property isEqualToString: kCKUIDProperty])
    return NO;
  if([property isEqualToString: kCKCreationDateProperty])
    return NO;
  if([property isEqualToString: kCKModificationDateProperty])
    return NO;

  newDict = [NSMutableDictionary dictionaryWithDictionary: _dict];
  
  if(!value/*|| [value isEqualToString: @""]*/)
    [newDict removeObjectForKey: property];
  else
    [newDict setObject: value forKey: property];

  [newDict setObject: [NSDate date] forKey: kCKModificationDateProperty];

  ASSIGN(_dict, AUTORELEASE([[NSDictionary alloc] initWithDictionary: newDict]));

  if(![property isEqualToString: kCKUIDProperty])
  {
    [[NSNotificationCenter defaultCenter]
        postNotificationName: CKRecordChangedNotification
        object: self
        userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				value, CKValueNotificationKey,
			      property, CKPropertyNotificationKey,
			      nil]];
  }
  return YES;
}

- (BOOL) removeValueForProperty: (NSString*) property
{
  NSMutableDictionary *newDict;
  
  if(_readOnly)
    {
      NSLog(@"Trying to remove value for property %@ in read-only record %@\n",
	    property, [self uniqueID]);
      return NO;
    }

  newDict = [NSMutableDictionary dictionaryWithDictionary: _dict];
  [newDict removeObjectForKey: property];
  ASSIGN(_dict, AUTORELEASE([[NSDictionary alloc] initWithDictionary: newDict]));

  if(![property isEqualToString: kCKUIDProperty])
  {
    [[NSNotificationCenter defaultCenter]
      postNotificationName: CKRecordChangedNotification
      object: self
      userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				property, CKPropertyNotificationKey,
			      nil]];
  }
  return YES;
}

- (BOOL) isReadOnly
{
  return _readOnly;
}

- (void) setReadOnly
{
  _readOnly = YES;
}

- (CKCollection *) collection
{
  return _book;
}

- (void) setCollection: (CKCollection *) book
{
  if(_book)
    [NSException raise: CKConsistencyError
		 format: @"Cannot set collection on record '%@'"
		 @" (already has one)", [self uniqueID]];
  if(!book)
    [NSException raise: CKConsistencyError
		 format: @"Cannot set nil collection on record '%@'",
		 [self uniqueID]];
  ASSIGN(_book, book);
}

- (id) copyWithZone: (NSZone*) z
{
  CKRecord *obj = [[CKRecord allocWithZone: z] init];
  if (_readOnly)
    [obj setReadOnly];

  NSArray *keys = [_dict allKeys];
  NSEnumerator *e = [keys objectEnumerator];
  NSString *key;
  while ((key = [e nextObject])) {
    [obj setValue: [self valueForProperty: key] forProperty: key];
  }

  obj->_book = nil;
  
  return obj;
}

- (NSString*) uniqueID
{
  return [self valueForProperty: kCKUIDProperty];
}

- (id) initWithContentDictionary: (NSDictionary *) dict
{
  self = [self init];

  NSMutableArray *keys;
  NSString *key;
  NSEnumerator *e;
  NSMutableDictionary *md = [[NSMutableDictionary alloc] init];

  keys = [NSMutableArray arrayWithArray: [dict allKeys]];
  e = [keys objectEnumerator];
  while((key = [e nextObject]))
    {
      id val;
      CKPropertyType t;

      val = [dict objectForKey: key];
      t = [[self class] typeOfProperty: key];
      if(t & CKMultiValueMask)
        {
          CKMutableMultiValue *mv;

          if([val isKindOfClass: [NSString class]])
            {
              NSLog(@"Warning: Converting value for %@ from broken "
                    @"string representation\n", key);
              val = [val propertyList];
            }
          mv = AUTORELEASE([[CKMutableMultiValue alloc] initWithType: t
                                             contentArray: val]);

          [md setObject: [[[CKMultiValue alloc] initWithMultiValue: mv]
                         autorelease]
             forKey: key];
        }
      else
        {
          switch(t)
            {
            case CKDateProperty:
              if([val isKindOfClass: [NSString class]])
                [md setObject: [NSCalendarDate dateWithString: val
                                             calendarFormat: @"%Y-%m-%d"]
                   forKey: key];
              else if([val isKindOfClass: [NSDate class]])
                [md setObject: [val copy] forKey: key];
              else
                NSLog(@"Unknown date class %@\n", [val className]);
              break;
            default:
              [md setObject: val forKey: key];
            }
        }
    }

  ASSIGN(_dict, [NSDictionary dictionaryWithDictionary: md]);

  return self;
}

- (NSDictionary*) contentDictionary
{
  NSMutableDictionary *dict;
  NSEnumerator *e;
  NSString *key;

  dict = [NSMutableDictionary dictionaryWithCapacity: [_dict count]];
  e = [[_dict allKeys] objectEnumerator];
  while((key = [e nextObject]))
    {
      NSObject *obj = [_dict objectForKey: key];
      if([obj isKindOfClass: [CKMultiValue class]])
        [dict setObject: [(CKMultiValue*)obj contentArray] forKey: key];
      else if([obj isKindOfClass: [NSString class]] ||
              [obj isKindOfClass: [NSData class]] ||
              [obj isKindOfClass: [NSDate class]] ||
              [obj isKindOfClass: [NSArray class]] ||
              [obj isKindOfClass: [NSNumber class]] ||
              [obj isKindOfClass: [NSDictionary class]])
        [dict setObject: obj forKey: key];
      else
        NSLog(@"Value for \"%@\" in record \"%@\" has invalid class %@\n",
              key, [self uniqueID], [obj className]);
    }

  return dict;
}
@end

