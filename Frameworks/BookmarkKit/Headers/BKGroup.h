/*
	BKGroup.h
	BKGroup is the BookmarkKit class which is used to represent a group of bookmark
	Copyright (C) 2006 Yen-Ju Chen <yjchen @ gmail>>	                   
	Author:  Yen-Ju Chen <yjchen @ gmail>
	Date:  October 2006

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

#import <CollectionKit/CollectionKit.h>
#import <AppKit/AppKit.h>
#import <BookmarkKit/BKGlobals.h>

@interface BKGroup: CKGroup <BKTopLevel>
{
  BKTopLevelType topLevel;
}

- (void) setName: (NSString *) name;
- (NSString *) name;

@end

