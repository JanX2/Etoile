/*
    CKGroup.h
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

#import <CollectionKit/CKRecord.h>
#import <CollectionKit/CKItem.h>
#import <CollectionKit/CKTypedefs.h>

@interface CKGroup: CKRecord

- (NSArray *) items;
- (BOOL) addItem: (CKItem *) item;
- (BOOL) removeItem: (CKItem *) item;

- (NSArray*) subgroups;
- (BOOL) addSubgroup: (CKGroup*) group;
- (BOOL) removeSubgroup: (CKGroup*) group;
- (NSArray*) parentGroups;

- (BOOL) setDistributionIdentifier: (NSString *) identifier
		       forProperty: (NSString *) property
			      item: (CKItem *) item;
- (NSString*) distributionIdentifierForProperty: (NSString *) property
					   item: (CKItem *) item;

#if 0
+ (CKSearchElement*) searchElementForProperty: (NSString*) property
				       label: (NSString*) label
					 key: (NSString*) key
				       value: (id) value
				  comparison: (CKSearchComparison) comparison;
#endif
@end

