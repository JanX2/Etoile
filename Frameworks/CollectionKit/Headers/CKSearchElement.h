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
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
    USA
 */

#import <Foundation/Foundation.h>
#import <CollectionKit/CKRecord.h>
#import <CollectionKit/CKTypedefs.h>
#import <CollectionKit/CKGlobals.h>

@interface CKSearchElement: NSObject
+ (CKSearchElement*) searchElementForConjunction: (CKSearchConjunction) conj
					children: (NSArray*) children;
- (BOOL) matchesRecord: (CKRecord*) record;
@end

@interface CKRecordSearchElement: CKSearchElement // EXTENSION
{
  NSString *_property, *_label, *_key;
  id _val;
  CKSearchComparison _comp;
}

- initWithProperty: (NSString*) property
	     label: (NSString*) label
	       key: (NSString*) key
	     value: (id) value
	comparison: (CKSearchComparison) comparison;
- (void) dealloc;
- (BOOL) matchesValue: (id) value;
- (BOOL) matchesRecord: (CKRecord*) record;
@end

