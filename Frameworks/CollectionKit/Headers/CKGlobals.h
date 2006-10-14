/*  
    CKGlobals.h
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

#ifndef _CollectionKit_Globals_
#define _CollectionKit_Globals_

#import <Foundation/NSString.h>

/* Used to store items and groups in property list (NSDictionary) */
extern NSString *const CKItemsKey;
extern NSString *const CKGroupsKey;
extern NSString *const CKFormatKey; // version of property list
extern NSString *const CKCollectionFormat_0_1;

/* Properties common to all Records */
extern NSString *const kCKUIDProperty; 			// string
extern NSString *const kCKCreationDateProperty;		// date
extern NSString *const kCKModificationDateProperty;	// date

/* Group-specific */
extern NSString *const kCKGroupNameProperty;     // string
extern NSString *const kCKItemsProperty;         // array; NON-APPLE EXTENSION

/* Notificaiton: (kABDatabaseChangedNotification) */
/* When collection is changed 
 * Keys for user info:
 * CKUIDNotificationKey: UID of changed record
 * CKCollectionNotificationKey: changed collection
 */
extern NSString *const CKCollectionChangedNotification;
extern NSString *const CKUIDNotificationKey;
extern NSString *const CKCollectionNotificationKey;

/* Notificaiton: (kABDatabaseChangedExternallyNotification) */
extern NSString *const CKCollectionChangedExternallyNotification;

/* Notification 
 * When record is change by -setValue:forProerty and -removeValueForProperty:
 * Keys for user info:
 * CKChangedValueKey: changed value
 * CKChangedPropertyKey: changed property
 */
extern NSString *const CKRecordChangedNotification;
extern NSString *const CKValueNotificationKey;
extern NSString *const CKPropertyNotificationKey;

/* Error */
extern NSString *const CKUnimplementedError;
extern NSString *const CKInternalError;
extern NSString *const CKConsistencyError;

#endif /* _CollectionKit_Globals_ */
