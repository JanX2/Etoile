// ADPerson.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADPERSON_H
#define ADPERSON_H

/* system includes */
/* (none) */

/* my includes */
/* (none) */

#include <Addresses/ADRecord.h>
#include <Addresses/ADSearchElement.h>
#include <Addresses/ADTypedefs.h>

@class ADSearchElement;

@interface ADPerson: ADRecord
/*!
  \brief Add properties to all people records

  Takes a dictionary of the form {propName = propType; [...]}.
  Property names must be unique; if a property is already in, it will
  not be added, nor will its type be changed. Returns the number of
  properties successfully added.
*/
+ (int) addPropertiesAndTypes: (NSDictionary*) properties;

/*!
  \brief Remove properties from all people records

  Returns the number of properties successfully removed
*/
+ (int) removeProperties: (NSArray*) properties;

+ (NSArray*) properties;
+ (ADPropertyType) typeOfProperty: (NSString*) property;
+ (ADSearchElement*) searchElementForProperty: (NSString*) property 
				       label: (NSString*) label 
					 key: (NSString*) key 
				       value: (id) value 
				  comparison: (ADSearchComparison) comparison;
- (ADPropertyType) typeOfProperty: (NSString*) property;

- (NSArray*) parentGroups;

- (id) initWithVCardRepresentation: (NSData*) vCardData;
- (NSData *) vCardRepresentation;
@end

@interface ADPerson(AddressesExtensions)
+ (ADScreenNameFormat) screenNameFormat;
+ (void) setScreenNameFormat: (ADScreenNameFormat) aFormat;
- (NSString*) screenName;
- (NSString*) screenNameWithFormat: (ADScreenNameFormat) aFormat;
- (NSComparisonResult) compareByScreenName: (ADPerson*) theOtherGuy;

- (BOOL) shared;
- (void) setShared: (BOOL) yesno;
@end

#endif /* ADPERSON_H */
