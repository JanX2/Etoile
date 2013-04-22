/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */

#import "TWEditorContentController.h"
#import "TWAppController.h"
#import "TWLayoutItemFactory.h"
#import "TWTextTreeDocumentTemplate.h"

@implementation TWEditorContentController

- (id) init
{
	SUPERINIT;
	ETItemTemplate *textFragmentTemplate =
		[ETItemTemplate templateWithItem: [[TWLayoutItemFactory factory] item]
	                         objectClass: [ETTextFragment class]];
	ETItemTemplate *textTreeTemplate =
		[ETItemTemplate templateWithItem: [[TWLayoutItemFactory factory] itemGroup]
	                         objectClass: [ETTextTree class]];

	[self setTemplate: textFragmentTemplate forType: [self currentObjectType]];
	[self setTemplate: textTreeTemplate forType: [self currentGroupType]];

	return self;
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

- (void) selectionDidChange: (NSNotification *)aNotif
{

}

#pragma mark -
#pragma mark Object Insertion and Deletion Actions

- (void) expandItem: (ETLayoutItem *)anItem
{
	[(NSOutlineView *)[[[[self content] layout] ifResponds] tableView]
		expandItem: anItem expandChildren: NO];
}

- (ETLayoutItemGroup *) turnSelectedTextFragmentIntoTree
{
	if ([[self content] isEmpty] == NO)
		return nil;
	
	NSIndexPath *indexPath = [[[self content] selectionIndexPaths] lastObject];
	ETLayoutItem *item = [[self content] itemAtIndexPath: indexPath];

	if ([[item representedObject] isTextGroup])
	{
		return item;
	}

	ETLayoutItemGroup *parentItem = [item parentItem];
	NSUInteger index = [parentItem indexOfItem: item];
	ETUTI *textTreeType = [ETUTI typeWithClass: [ETTextTree class]];
	ETLayoutItemGroup *textTreeItem =
		(id)[self newItemWithURL: nil ofType: textTreeType options: nil];

	
	ETAssert([[textTreeItem representedObject] isKindOfClass: [ETTextTree class]]);
	ETAssert([[item representedObject] isKindOfClass: [ETTextFragment class]]);

	[[textTreeItem representedObject] appendTextFragment: [item representedObject]];

	[parentItem removeItem: item];
	[parentItem insertItem: textTreeItem atIndex: index];

	return textTreeItem;
}

- (void) expandSelectedTextTreeItem: (ETLayoutItemGroup *)aTreeItem
{
	if (aTreeItem == nil)
		return;
	
	NSIndexPath *indexPath = [[[self content] selectionIndexPaths] lastObject];
	[self expandItem: [[self content] itemAtIndexPath: indexPath]];
}

- (IBAction) add: (id)sender
{
	[self expandSelectedTextTreeItem: [self turnSelectedTextFragmentIntoTree]];
	[super add: sender];
}

- (BOOL) layout: (ETTextEditorLayout *)aLayout prepareTextView: (NSTextView *)aTextView
{
	id <ETText> textNode = [(id)[aLayout layoutContext] representedObject];
	ETAssert([textNode conformsToProtocol: @protocol(ETText)]);
	ETTextStorage *textStorage = [[ETTextStorage new] autorelease];

	[textStorage setText: textNode];
	[[[aTextView textContainer] layoutManager] replaceTextStorage: textStorage];
	[aTextView setNeedsDisplay: YES];

	return YES;
}

#pragma mark -
#pragma mark Other Object Actions

- (IBAction) search: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

@end
