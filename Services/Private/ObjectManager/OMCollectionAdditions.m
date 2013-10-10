/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import "OMCollectionAdditions.h"

@implementation NSArray (OMCollectionAdditions)

- (BOOL) isSameKindAmongObjects
{
	Class kind = [[self firstObject] class];

	for (id obj in self)
	{
		if ([obj isKindOfClass: kind] == NO && [kind isSubclassOfClass: [obj class]] == NO)
		{
			return NO;
		}
	}
	return YES;
}

@end


@implementation COSmartGroup (OMCollectionAdditions)

+ (COSmartGroup *) unionGroupWithCollections: (id <ETCollection>)collections
{
	COSmartGroup *selectionGroup = AUTORELEASE([[COSmartGroup alloc] init]);
	COContentBlock block = ^() {
		NSMutableSet *objects = [NSMutableSet set];

		for (COCollection *collection in collections)
		{
			[objects addObjectsFromArray: [collection contentArray]];
		}

		return [objects contentArray];
	};

	[selectionGroup setContentBlock: block];
	return selectionGroup;
}

@end
