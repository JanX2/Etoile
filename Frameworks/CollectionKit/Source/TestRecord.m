/*
    TestRecord.m
    Copyright (C) <2006> Yen-Ju Chen <gmail>

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

#import <UnitKit/UnitKit.h>
#import <Foundation/Foundation.h>
#import <CollectionKit/CKRecord.h>
#import <CollectionKit/CKItem.h>
#import <CollectionKit/CKMultiValue.h>
#import <CollectionKit/CKGlobals.h>
#import <CollectionKit/CKTypedefs.h>
#import "GNUstep.h"

@interface TestRecord: NSObject <UKTest>
@end

@implementation TestRecord
- (void) testSave
{
  [CKItem addPropertiesAndTypes: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: CKStringProperty], @"Name", [NSNumber numberWithInt: CKMultiStringProperty], @"Email", nil]];

  CKMutableMultiValue *mv = [[CKMutableMultiValue alloc] initWithType: CKMultiStringProperty];
  NSString *iden = [mv addValue: @"boss@office" withLabel: @"Work"];
  [mv addValue: @"boss@factory" withLabel: @"Work"];
  [mv addValue: @"sleep@bed" withLabel: @"Home"];
  [mv setPrimaryIdentifier: iden];
  CKItem *item = [[CKItem alloc] init];
  [item setValue: @"Boss" forProperty: @"Name"];
  [item setValue: AUTORELEASE(mv) forProperty: @"Email"];

  NSDictionary *dict = [item contentDictionary];
  UKNotNil(dict);
  CKItem *n = [[CKItem alloc] initWithContentDictionary: dict];
  UKStringsEqual([item valueForProperty: @"Name"], [n valueForProperty: @"Name"]);
  CKMultiValue *vv = [n valueForProperty: @"Email"];
  UKIntsEqual([mv count], [vv count]);
  UKStringsEqual([mv valueAtIndex: 2], [vv valueAtIndex: 2]);
}

- (void) testPropertiesAndTypes
{
  UKNil([CKRecord properties]);
  int count = [CKRecord addPropertiesAndTypes: [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt: CKStringProperty], kCKUIDProperty, [NSNumber numberWithInt: CKDateProperty], kCKCreationDateProperty, [NSNumber numberWithInt: CKDateProperty], kCKModificationDateProperty, nil]];
  UKIntsEqual(count, 3);
  UKNotNil([CKRecord properties]);
  UKIntsEqual([CKRecord typeOfProperty: kCKUIDProperty], CKStringProperty);
  count = [CKRecord removeProperties: [NSArray arrayWithObjects: kCKCreationDateProperty, kCKModificationDateProperty, nil]];
  UKIntsEqual(count, 2);
  UKIntsEqual([[CKRecord properties] count], 1);
  UKStringsEqual([[CKRecord properties] objectAtIndex: 0], kCKUIDProperty);
}

- (void) testCopy
{
  CKRecord *record = [[CKRecord alloc] init];
  NSString *property1 = @"Property1";
  NSString *property2 = @"ABC_Property";
  NSString *property3 = @"!@#_Property";
  NSString *value1= @"Value1";
  NSString *value2= @"%^&_Value";
  NSString *value3= @"BSE_Value";

  [record setValue: value1 forProperty: property1];
  [record setValue: value2 forProperty: property2];
  [record setValue: value3 forProperty: property3];

  CKRecord *clone = [record copy];
  UKStringsEqual([record valueForProperty: property1], [clone valueForProperty: property1]);
  UKStringsEqual([record valueForProperty: property2], [clone valueForProperty: property2]);
  UKStringsEqual([record valueForProperty: property3], [clone valueForProperty: property3]);
  UKStringsNotEqual([record valueForProperty: kCKUIDProperty], [clone valueForProperty: kCKUIDProperty]);
  [record setValue: @"New Value" forProperty: property1];
  UKStringsNotEqual([record valueForProperty: property1], [clone valueForProperty: property1]);
}

#if 0
- (void) testUniquieID
{
  int i, count = 100;
  for (i = 0; i < count; i++) {
    CKRecord *record = [[CKRecord alloc] init];
    NSLog(@"%@", [record uniqueID]);
  }
}
#endif
@end
