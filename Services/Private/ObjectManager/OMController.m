/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import "OMController.h"

@implementation OMController

- (COPersistentRoot *)persistentRootFromSelection
{
	NSArray *selectedItems = [[self content] selectedItemsInLayout];
	
	if ([selectedItems count] == 1)
	{
		return [[[selectedItems lastObject] representedObject] persistentRoot];
	}
	return nil;
}

- (COEditingContext *)editingContext
{
	if ([[self persistentObjectContext] respondsToSelector: @selector(parentContext)])
	{
		return [(COPersistentRoot *)[self persistentObjectContext] parentContext];
	}
	return (COEditingContext *)[self persistentObjectContext];
}

- (NSArray *) selectedObjects
{
	return [[[[self content] selectedItemsInLayout] mappedCollection] representedObject];
}

@end
