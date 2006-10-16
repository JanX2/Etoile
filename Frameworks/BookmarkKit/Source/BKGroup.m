/*
	BKGroup.m

	BKGroup is the BookmarkKit class which is used to represent a group of bookmark 

	Copyright (C) 2006 Yen-Ju Chen <yjchenx @ gmail>

	Author:  Yen-Ju Chen <yjchenx @ gmail>
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

#import <AppKit/AppKit.h>
#import <BookmarkKit/BKGroup.h>

NSString *const kBKGroupNameProperty = @"kBKGroupNameProperty";

@implementation BKGroup

+ (void) initialize
{
  /* subclass of CKRecord must implement this one.
   * Otherwise, it will not work properly. */
  NSDictionary *_propTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
         [NSNumber numberWithInt: CKStringProperty], kCKUIDProperty,
         [NSNumber numberWithInt: CKStringProperty], kBKGroupNameProperty,
         [NSNumber numberWithInt: CKArrayProperty], kCKItemsProperty,
         [NSNumber numberWithInt: CKDateProperty], kCKCreationDateProperty,
         [NSNumber numberWithInt: CKDateProperty], kCKModificationDateProperty,
                nil];
  [BKGroup addPropertiesAndTypes: _propTypes];
}

- (id) init
{
  self = [super init];
  topLevel = BKUndecidedTopLevel; // Can be grouped or not while saving
  return self;
}

// BKTopLevel protocol
- (void) setTopLevel: (BKTopLevelType) type
{
  topLevel = type;
}

- (BKTopLevelType) isTopLevel
{
  if (topLevel == BKUndecidedTopLevel)
  {
    if ([[self parentGroups] count])
      topLevel = BKNotTopLevel;
    else
      topLevel = BKTopLevel;
  }
  return topLevel;
}

@end
