/*
    TestMultiValue.m
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
#import <CollectionKit/CKMultiValue.h>
#import "GNUstep.h"

@interface TestMultiValue: NSObject <UKTest>
@end

@implementation TestMultiValue
- (void) testBasic
{
  CKMutableMultiValue *mv = [[CKMutableMultiValue alloc] initWithType: CKMultiStringProperty];
  UKNotNil([mv addValue: @"First" withLabel: @"Label1"]);
  UKNotNil([mv addValue: @"Second" withLabel: @"Label1"]);
  UKNotNil([mv addValue: @"Third" withLabel: @"Label1"]);
  UKNil([mv identifierAtIndex: 3]);
  UKNil([mv primaryIdentifier]);
  NSString *iden = [mv identifierAtIndex: 0];
  UKNotNil(iden);
  [mv setPrimaryIdentifier: iden];
  UKStringsEqual(iden, [mv primaryIdentifier]); 
  UKIntsEqual([mv count], 3);
  UKStringsEqual([mv valueAtIndex: 2], @"Third");
}

- (void) testSave
{
  CKMutableMultiValue *mv = [[CKMutableMultiValue alloc] initWithType: CKMultiStringProperty];
  [mv addValue: @"First" withLabel: @"Label1"];
  [mv addValue: @"Second" withLabel: @"Label1"];
  [mv addValue: @"Third" withLabel: @"Label1"];
  NSArray *array = [mv contentArray];
  UKNotNil(array);
  CKMultiValue *v = [[CKMultiValue alloc] initWithType: CKMultiStringProperty contentArray: array];
  UKIntsEqual([mv count], [v count]);
  int i;
  for (i = 0; i < [mv count]; i++) {
    UKStringsEqual([mv valueAtIndex: i], [v valueAtIndex: i]);
  }
  [mv replaceValueAtIndex: 0 withValue: @"Not First"];
  UKIntsEqual([mv count], [v count]);
  UKStringsNotEqual([mv valueAtIndex: 0], [v valueAtIndex: 0]);
  
}

@end
