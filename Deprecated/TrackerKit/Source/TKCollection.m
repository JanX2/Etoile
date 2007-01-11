/*
	TKCollection.m

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

#import "TKCollectioh.h"


@implementation TKCollection

/* Methods to add elements in collection */

- (void) addValue: (id)value forKey: (NSString *)keyPath
{

}

- (void) addValues: (NSArray *)values forKey: (NSString *)keyPath
{

}

/* Methods to remove elements in collection */

- (void) removeValue: (id)value forKey: (NSString *)keyPath
{

}

- (void) removeValues: (NSArray *)values forKey: (NSString *)keyPath
{

}

/* Methods to retrieve elements in collection */

- (NSArray *) valuesForKey: (NSString *)keyPath
{
    return nil;
}

- (TKCollection *) valuesCollectionForKey: (NSString *)keyPath
{
    return nil;
}

/* Methods overriden (inherited from TKObject category through NSObject) */

- (TKCollection *) collectAll
{
    return nil;
}

- (TKCollection *) collectWithValue: (id)value forKey: (NSString *)keyPath
{
    return nil;
}

- (TKCollection *) collectWithPredicate: (TKKeyValuePredicate *)predicate
{
    return nil;
}

- (TKCollection *) collectWithKeyValuePath: (NSString *)keyValuePath
{
    return nil;
}

- (TKCollection *) orderWithPredicate: (TKKeyValuePredicate *)predicate
{
    return nil;
}


- (TKCollection *) orderWithKeyValuePath: (NSString *)keyValuePath
{
    return nil;
}

@end
