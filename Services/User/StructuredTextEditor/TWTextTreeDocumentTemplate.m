/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */

#import "TWTextTreeDocumentTemplate.h"

@implementation TWTextTreeDocumentTemplate

- (BOOL) writeItem: (ETLayoutItem *)anItem
             toURL: (NSURL *)aURL
           options: (NSDictionary *)options
{
	ETAssert([[anItem representedObject] isKindOfClass: [COObject class]]);
	[[[anItem representedObject] persistentRoot] commit];
	return YES;
}

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	COEditingContext *editingContext = [COEditingContext currentContext];
	NSAssert(editingContext != nil, @"Current editing context must not be nil to create a new item");
	
	ETLayoutItem *item = [super newItemWithURL: aURL options: options];
	
	[editingContext insertNewPersistentRootWithRootObject: [item representedObject]];
	return item;
}

- (ETLayoutItem *) contentItem
{
	return [(ETLayoutItemGroup *)[super contentItem] itemForIdentifier: @"contentView"];
}

@end


@implementation NSObject (TWOutlinerTextTree)

- (BOOL) isTextGroup
{
	return [self conformsToProtocol: @protocol(ETTextGroup)];
}

@end
