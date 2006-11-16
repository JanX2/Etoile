/*
    CKRecord.h
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
#import <CollectionKit/CKTypedefs.h>

@class CKCollection;

@interface CKRecord: NSObject <NSCopying>
{
  BOOL _readOnly;
  CKCollection *_book;
  NSDictionary *_dict;
}

/** Add properties to all item records

    Takes a dictionary of the form {propName = propType; [...]}.
    Property names must be unique; if a property is already in, it will
    not be added, nor will its type be changed. Returns the number of
    properties successfully added.
 */
+ (int) addPropertiesAndTypes: (NSDictionary*) properties;
+ (NSDictionary *) propertiesAndTypes;

/** Remove properties from all people records
    Returns the number of properties successfully removed
 */
+ (int) removeProperties: (NSArray*) properties;

+ (NSArray*) properties;
+ (CKPropertyType) typeOfProperty: (NSString*) property;

- (id) valueForProperty: (NSString *) property;
- (BOOL) setValue: (id) value forProperty: (NSString *) property;
- (BOOL) removeValueForProperty: (NSString *) property;

- (BOOL) isReadOnly; // return whether this is a read-only record
- (void) setReadOnly; // set this record to be read-only. cannot be reset.

/** Return the collection this record is part of.

    Can return nil, if this is a new record which has not been added to
    any address book yet.
  
    This is a non-Apple extension; Apple's API doesn't need it as
    it knows nothing about multiple address books.
 */
- (CKCollection *) collection;

/** Set the address book this record is part of.

  Can only be set once (since a record cannot be *moved* between
  address books); raises if it has been called before, or if book is
  nil.

  This is a non-Apple extension; Apple's API doesn't need it as
  it knows nothing about multiple address books.
 */
- (void) setCollection: (CKCollection *) book;

/** uniqueID is automatically generated when object initialized.
    There is no way to change it so far unless subclass.
 */
- (NSString *) uniqueID;

/** for save */
- (id) initWithContentDictionary: (NSDictionary *) dict;
- (NSDictionary*) contentDictionary;
@end
