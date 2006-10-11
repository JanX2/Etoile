/*
    TestCollection.m
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

#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <CollectionKit/CollectionKit.h>
#import "GNUstep.h"

static NSString *kName = @"Name";
static NSString *kEMails = @"E-Mails";
static NSString *path = @"/tmp/testCollection";

@interface TestCollection: NSObject <UKTest>
{
  CKCollection *collection;
}
@end

@implementation TestCollection
- (id) init 
{
  self = [super init];
  collection = [[CKCollection alloc] initWithLocation: path];
  [CKItem addPropertiesAndTypes: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: CKStringProperty], kName, [NSNumber numberWithInt: CKMultiStringProperty], kEMails, nil]];

  CKMutableMultiValue *mv = [[CKMutableMultiValue alloc] initWithType: CKMultiStringProperty];
  NSString *iden = [mv addValue: @"boss@office" withLabel: @"Work"];
  [mv addValue: @"boss@factory" withLabel: @"Work"];
  [mv addValue: @"sleep@bed" withLabel: @"Home"];
  [mv setPrimaryIdentifier: iden];
  CKItem *item = [[CKItem alloc] init];
  [item setValue: @"Boss" forProperty: kName];
  [item setValue: AUTORELEASE(mv) forProperty: kEMails];
  [collection addRecord: item];

  mv = [[CKMutableMultiValue alloc] initWithType: CKMultiStringProperty];
  [mv addValue: @"friend@office" withLabel: @"Work"];
  [mv addValue: @"funny@bar" withLabel: @"Home"];
  [mv addValue: @"lazy@home" withLabel: @"Home"];
  item = [[CKItem alloc] init];
  [item setValue: @"Friend" forProperty: kName];
  [item setValue: AUTORELEASE(mv) forProperty: kEMails];
  [collection addRecord: item];
 
  return self;
}

- (void) testBasic
{
  NSArray *items = [collection items];
  UKIntsEqual([items count], 2);
  UKTrue([collection hasUnsavedChanges]);
  CKRecord *record = [items objectAtIndex: 0];
  CKMultiValue *mv = [record valueForProperty: kEMails];
  UKIntsEqual([mv count], 3);
  int index = [mv indexForIdentifier: [mv primaryIdentifier]];
  if ([[record valueForProperty: kName] isEqualToString: @"Boss"]) {
    UKStringsEqual([mv valueAtIndex: index], @"boss@office");
  }
  if ([[record valueForProperty: kName] isEqualToString: @"Friend"]) {
    UKIntsEqual(index, NSNotFound);
  }
}

- (void) testSave
{
  [collection save];
  CKCollection *ck = [[CKCollection alloc] initWithLocation: path];
  UKIntsEqual([[collection items] count], [[ck items] count]);
  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
}

#define ADD_RECORD(v1, v2, u) \
  mv = [[CKMutableMultiValue alloc] initWithType: CKMultiStringProperty]; \
  [mv addValue: v1 withLabel: @"ISP"]; \
  [mv addValue: v2 withLabel: @"ISP"]; \
  item = [[CKItem alloc] init]; \
  [item setValue: u forProperty: kName]; \
  [item setValue: mv forProperty: kEMails]; \
  [collection addRecord: item]; \
  [item release]; \
  [mv release]; 
 

- (void) testGroup
{
  CKMutableMultiValue *mv;
  CKItem *item;

  ADD_RECORD(@"email@isp1", @"email@isp2", @"NetUser");
  ADD_RECORD(@"box@isp1", @"box2@isp2", @"BoxUser");

  CKGroup *group = [[CKGroup alloc] init];
  [collection addRecord: group];
  CKItem *record = [[collection items] objectAtIndex: 0];
  [group addItem: record];
  UKIntsEqual([[collection groups] count], 1);
  group = [[collection groups] objectAtIndex: 0]; 
  UKIntsEqual([[group items] count], 1);
  UKNotNil([group uniqueID]);
  NSArray *pGroups = [record parentGroups];
  UKNotNil(pGroups);
  UKTrue([pGroups count] > 0);
  UKStringsEqual([group uniqueID], [[[record parentGroups] objectAtIndex: 0] uniqueID]);
}

@end
