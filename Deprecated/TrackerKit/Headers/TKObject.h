/*
	TKObject.h

	TKObject is a category on NSObject to have it supporting HOM-like
	semantic.
	
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

@interface NSObject (TrackerKit)

- (TKCollection *) collectAll; /* Equivalent to -collect in other HOM implementations */

- (TKCollection *) collectWithValue: (id)value forKey: (NSString *)keyPath;
- (TKCollection *) collectWithPredicate: (TKKeyValuePredicate *)predicate;
- (TKCollection *) collectWithKeyValuePath: (NSString *)keyValuePath;

- (TKCollection *) orderWithPredicate: (TKKeyValuePredicate *)predicate;
- (TKCollection *) orderWithKeyValuePath: (NSString *)keyValuePath;

@end
