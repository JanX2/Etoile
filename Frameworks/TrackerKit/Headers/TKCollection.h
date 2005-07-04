/*
	TKVCollection.h

	TKCollection is TrackerKit metacollection class used to wrap any kind 
        of collections like NSArray, NSDictionary, NSSet etc. with HOM support
        in mind
	
	Copyright (C) 2005 Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Foundation/Foundation.h>


@interface TKCollection : NSObject

/* Methods to add elements in collection */

- (void) addValue: (id)value forKey: (NSString *)keyPath;
- (void) addValues: (NSArray *)values forKey: (NSString *)keyPath;

/* Methods to remove elements in collection */

- (void) removeValue: (id)value forKey: (NSString *)keyPath;
- (void) removeValues: (NSArray *)values forKey: (NSString *)keyPath;

/* Methods to retrieve elements in collection */

- (NSArray *) valuesForKey: (NSString *)keyPath;
- (TKCollection *) valuesCollectionForKey: (NSString *)keyPath;

/* Methods overriden (inherited from TKObject category through NSObject) */

- (TKCollection *) collectAll; /* Equivalent to -collect in other HOM implementations */

- (TKCollection *) collectWithValue: (id)value forKey: (NSString *)keyPath;
- (TKCollection *) collectWithPredicate: (TKKeyValuePredicate *)predicate;
- (TKCollection *) collectWithKeyValuePath: (NSString *)keyValuePath;

- (TKCollection *) orderWithPredicate: (TKKeyValuePredicate *)predicate;
- (TKCollection *) orderWithKeyValuePath: (NSString *)keyValuePath;

@end
