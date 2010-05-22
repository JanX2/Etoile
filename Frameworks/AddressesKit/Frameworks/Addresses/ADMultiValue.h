// ADMultiValue.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.2 $
// $Date: 2004/07/29 03:40:13 $

#ifndef ADMULTIVALUE_H
#define ADMULTIVALUE_H

/* system includes */
#include <Foundation/Foundation.h>

/* my includes */
#include <Addresses/ADTypedefs.h>

@interface ADMultiValue : NSObject <NSCopying, NSMutableCopying>
{
  NSString *_primaryId;
  ADPropertyType _type;
  NSMutableArray *_arr;
}

- (NSUInteger) count;

- (id) valueAtIndex: (int) index;
- (NSString*) labelAtIndex: (int) index;
- (NSString*) identifierAtIndex: (int) index;
    
- (int) indexForIdentifier: (NSString*) identifier;

- (NSString*) primaryIdentifier;
    
- (ADPropertyType) propertyType;
@end

@interface ADMultiValue(AddressesExtensions)
- (id) initWithMultiValue: (ADMultiValue*) mv;
- (id) initWithType: (ADPropertyType) type;
- (NSArray*) contentArray;
@end

@interface ADMutableMultiValue: ADMultiValue
{
  int _nextId;
}

- (NSString*) addValue: (id) value
	     withLabel: (NSString*) label;
- (NSString *) insertValue: (id) value
		 withLabel: (NSString*) label
		   atIndex: (int) index;
- (BOOL) removeValueAndLabelAtIndex: (int) index;
- (BOOL) replaceValueAtIndex: (int) index
		   withValue: (id) value;    
- (BOOL) replaceLabelAtIndex: (int) index
		   withLabel: (NSString*) label;

- (BOOL)setPrimaryIdentifier:(NSString *)identifier;
@end

@interface ADMutableMultiValue(AddressesExtensions)
- (BOOL) addValue: (id) value
	withLabel: (NSString*) label
       identifier: (NSString*) identifier;
@end
#endif /* ADMULTIVALUE_H */
