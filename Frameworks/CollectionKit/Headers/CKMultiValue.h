/*
    CKMultiValue.h
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

#import <Foundation/Foundation.h>
#import "CKTypedefs.h"

@interface CKMultiValue : NSObject <NSCopying, NSMutableCopying>
{
  NSString *_primaryId;
  CKPropertyType _type;
  NSMutableArray *_arr;
}
- (id) initWithMultiValue: (CKMultiValue*) mv;
- (id) initWithType: (CKPropertyType) type;

/** for save **/
- (id) initWithType: (CKPropertyType) type contentArray: (NSArray *) array;
- (NSArray*) contentArray;

- (NSUInteger) count;

- (id) valueAtIndex: (int) index;
- (NSString*) labelAtIndex: (int) index;
- (NSString*) identifierAtIndex: (int) index;
    
- (int) indexForIdentifier: (NSString*) identifier;

- (NSString*) primaryIdentifier;
    
- (CKPropertyType) propertyType;

@end

@interface CKMutableMultiValue: CKMultiValue
{
  int _nextId;
}

- (NSString*) addValue: (id) value withLabel: (NSString*) label;
- (NSString *) insertValue: (id) value withLabel: (NSString*) label
		   atIndex: (int) index;
- (BOOL) removeValueAndLabelAtIndex: (int) index;
- (BOOL) replaceValueAtIndex: (int) index withValue: (id) value;    
- (BOOL) replaceLabelAtIndex: (int) index withLabel: (NSString*) label;

- (BOOL)setPrimaryIdentifier:(NSString *)identifier;

@end

