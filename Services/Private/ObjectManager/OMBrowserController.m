/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <ObjectMerging/COCommitTrack.h>
#import <ObjectMerging/COHistoryTrack.h>
#import <ObjectMerging/COObject.h>
#import "OMBrowserController.h"
#import "OMLayoutItemFactory.h"
#import "OMAppController.h"

@implementation OMController

- (COEditingContext *) editingContext
{
	return [COEditingContext currentContext];
}

@end

@implementation OMBrowserController

@synthesize contentViewItem, sourceListItem, viewPopUpItem, browsedGroup;

- (id) init
{
	SUPERINIT;
	[self setCurrentObjectType: nil];
	return self;
}

- (void) dealloc
{
	DESTROY(contentViewItem);
	DESTROY(sourceListItem);
	DESTROY(viewPopUpItem);
	DESTROY(browsedGroup);
	[super dealloc];
}

- (void) setBrowsedGroup: (id <ETCollection>)aGroup
{
	ETAssert(aGroup != nil);

	id oldRepresentedObject = AUTORELEASE(RETAIN([sourceListItem representedObject]));

	// NOTE: We don't use -isEqual: to handle nil cases transparently
	if ([contentViewItem representedObject] == oldRepresentedObject) 
		return;

	ETLog(@"Browse group %@", aGroup);
	ASSIGN(browsedGroup, aGroup);
	
	// NOTE: Will update the window title
	[contentViewItem setRepresentedObject: browsedGroup];
	[contentViewItem reload];
	[contentViewItem setSelectionIndex: NSNotFound];

	//statusLabelItem view setObjectValue: anObject.

	//history addObject: (mainViewItem representedObject).
}

- (id) selectedObject
{
	id selectedObject = [[[[self contentViewItem] selectedItemsInLayout] firstObject] representedObject];

	if (selectedObject == nil)
	{
		selectedObject = [self browsedGroup];
	}
	return selectedObject;
}

- (BOOL) isSameKindAmongObjects: (NSArray *)objects
{
	Class kind = [[objects firstObject] class];

	for (id obj in objects)
	{
		if ([obj isKindOfClass: kind] == NO && [kind isSubclassOfClass: [obj class]] == NO)
		{
			return NO;
		}
	}
	return YES;
}

- (COGroup *) whereGroup
{
	return [[sourceListItem firstItem] representedObject];
}

- (ETLayoutItemGroup *) whatGroupItem
{
	return [sourceListItem itemAtIndex: 1];
}

- (COGroup *) whenGroup
{
	return [[sourceListItem lastItem] representedObject];
}

- (NSSet *) selectedTags
{
	NSMutableSet *tags = [NSMutableSet set];
	ETLayoutItemGroup *whatGroupItem = [self whatGroupItem];

	for (NSIndexPath *indexPath in [whatGroupItem selectionIndexPaths])
	{
		COObject *selectedObject = [[whatGroupItem itemAtIndexPath: indexPath] representedObject];
	
		if ([selectedObject isTag])
		{
			[tags addObject: selectedObject];
		}
		else
		{
			ETAssert([selectedObject isKindOfClass: [COTagGroup class]]);
			[tags addObjectsFromArray: [selectedObject contentArray]];
		}
	}
	return tags;
}

- (COSmartGroup *) whereUnionGroup
{
	COSmartGroup *selectionGroup = AUTORELEASE([[COSmartGroup alloc] init]);
	COContentBlock block = ^() {
		NSMutableSet *objects = [NSMutableSet set];

		for (COCollection *collection in [self whereGroup])
		{
			[objects addObjectsFromArray: [collection contentArray]];
		}

		return [objects contentArray];
	};

	[selectionGroup setContentBlock: block];
	return selectionGroup;
}

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif
{
	ETLog(@"Did change selection in %@", [aNotif object]);
	NSArray *selectedItems = [[aNotif object] selectedItemsInLayout];
	NSArray *selectedObjects = [[selectedItems mappedCollection] representedObject];
	BOOL isSingleSelection = ([selectedObjects count] == 1);
	BOOL isMultipleSelectionInSingleCategory = ([selectedObjects count] > 1 
		&& [self isSameKindAmongObjects: selectedObjects]);

	if (isSingleSelection)
	{
		[self setBrowsedGroup: [selectedObjects firstObject]];
	}
	else if (isMultipleSelectionInSingleCategory)
	{
		COSmartGroup *selectionGroup = AUTORELEASE([[COSmartGroup alloc] init]);

		COContentBlock block = ^() {
			NSMutableSet *objects = [NSMutableSet set];

			for (COCollection *collection in selectedObjects)
			{
				[objects addObjectsFromArray: [collection contentArray]];
			}

			return [objects contentArray];
		};

		[selectionGroup setContentBlock: block];
		[self setBrowsedGroup: selectionGroup];
	}
	else
	{
		// TODO: Finish filtering on whenPredicate & whatPredicate & searchPredicate
		NSPredicate *predicate =
            [NSPredicate predicateWithFormat: @"ALL %@ IN tags", [self selectedTags]];
		COSmartGroup *tagFilteredGroup = AUTORELEASE([[COSmartGroup alloc] init]);

		[tagFilteredGroup setTargetCollection: [self whereUnionGroup]];

		[tagFilteredGroup setQuery: [COQuery queryWithPredicate: predicate]];

		[self setBrowsedGroup: tagFilteredGroup];
	}
}

- (ETLayoutItem *) tagLibraryItem
{
	COLibrary *tagLibrary = [[self editingContext] tagLibrary];
	return [[[sourceListItem items] filteredArrayUsingPredicate: 
		[NSPredicate predicateWithFormat: @"representedObject == %@", tagLibrary]] firstObject];
}

- (IBAction) addNewTag: (id)sender
{
	/* Ensure the What item group is expanded */
	
	[(NSOutlineView *)[[[self sourceListItem] layout] tableView] 
		expandItem: [self whatGroupItem] expandChildren: NO];

	/* First select the right Tag Group in the Source list */

	NSArray *selectedTagGroupItems = [[self whatGroupItem] selectedItems];

	/* Deselect everything in the source list */
	[[self sourceListItem] setSelectionIndexPaths: [NSArray array]];

	if ([selectedTagGroupItems isEmpty])
	{
		ETLayoutItem *unclassifiedTagGroupItem = [[self whatGroupItem] lastItem];
		[[self whatGroupItem] setSelectedItems: A(unclassifiedTagGroupItem)];
	}
	else
	{
		[[self whatGroupItem] setSelectedItems: A([selectedTagGroupItems firstObject])];
	}

	/* Create the new Tag */

	COEditingContext *ctxt = [self editingContext];
	COGroup *tag = [ctxt insertObjectWithEntityName: @"Anonymous.COTag"];

	[tag setName: _(@"Untitled")];

	/* Will invoke -addObject: on the Tag group */
	[(OMBrowserContentController *)[contentViewItem controller] addTag: tag];

	[ctxt commitWithType: @"Tag Creation" shortDescription: @"Created Tag"];

	/* Finally let the user edit the tag name */

	// TODO: [[contentViewItem lastItem] beginEditingForProperty: @"name"];
}

- (IBAction) remove: (id)sender
{
	[[contentViewItem controller] remove: sender];
}

- (IBAction) search: (id)sender
{
	NSString *searchString = [sender stringValue];

	ETLog(@"Search %@ with %@", [searchString description], [[contentViewItem controller] description]);

	if ([searchString isEqual: @""])
	{
		[[contentViewItem controller] setFilterPredicate: nil];
	}
	else
	{
		// TODO: Improve (Full-text, SQL, more properties, Object Matching integration)
		NSString *queryString = 
			@"(name CONTAINS %@) OR (typeDescription CONTAINS %@) OR (tagDescription CONTAINS %@)";
		NSPredicate *predicate = [NSPredicate predicateWithFormat: queryString
			                                        argumentArray: A(searchString, searchString, searchString)]; 

		[[contentViewItem controller] setFilterPredicate: predicate];
	}
}

- (IBAction) doubleClick: (id)sender
{
	id clickedObject = [[sender doubleClickedItem] representedObject];

	ETLog(@"Double click %@", [clickedObject description]);

	if ([clickedObject isGroup])
	{
		// TODO: Should use -openDocument: on OMAppController
		OMLayoutItemFactory *itemFactory = [OMLayoutItemFactory factory];
		ETLayoutItemGroup *browser = 
			[itemFactory browserWithGroup: [(OMAppController *)[[itemFactory windowGroup] controller] sourceListGroups]];
	
		[(OMBrowserController *)[browser controller] setBrowsedGroup: clickedObject];
		[[itemFactory windowGroup] addObject: browser];
	}
	else
	{
		ETLog(@"Open is not yet implemented!");
	}
}

- (IBAction) changePresentationViewFromPopUp: (id)sender
{
	ETAssert(viewPopUpItem != nil);
	ETLayout *templateLayout = [[(NSPopUpButton *)[viewPopUpItem view] selectedItem] representedObject];
	[contentViewItem setLayout: AUTORELEASE([templateLayout copy])];
}

- (IBAction) open: (id)sender
{

}

- (IBAction) openSelection: (id)sender
{

}

- (IBAction) markVersion: (id)sender
{

}

- (IBAction) revertTo: (id)sender
{

}

- (IBAction) browseHistory: (id)sender
{
	if ([[self selectedObject] isPersistent] == NO)
		return;

	//COTrack *track = [COCommitTrack trackWithObject: [self selectedObject]];
	COTrack *track = [[self selectedObject] commitTrack];
	ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] historyBrowserWithRepresentedObject: track];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

- (IBAction) export: (id)sender
{

}

- (IBAction) showInfos: (id)sender
{

}

- (IBAction)undoInSelection: (id)sender
{
	// TODO: Support multiple selected objects by looking for the last edited 
	// object among them.
	// TODO: If we want to prevent undoing changes not committed by the Object Manager...
	// Check wether the revision to be undone was written in the main custom 
	// undo track. When it is not the case, disable Undo in Selection or skip 
	// the checked object (then test the next selected object).
	[[[self selectedObject] commitTrack] undo];
}

@end


@implementation OMBrowserContentController

- (void) addTag: (COGroup *)aTag
{
	ETItemTemplate *template = [self templateForType: [self currentGroupType]];
	[self insertItem: [template newItemWithRepresentedObject: aTag options: nil] 
	         atIndex: ETUndeterminedIndex];
}

- (IBAction) remove: (id)sender
{
	NSArray *selectedItems = [[self content] selectedItemsInLayout];

	if ([selectedItems isEmpty])
		return;

	NSArray *coreObjects =  [[selectedItems mappedCollection] representedObject];

	for (COObject *object in coreObjects)
	{
		[[self editingContext] deleteObject: object];
	}
	[[self editingContext] commit];
}

- (void) objectDidBeginEditing: (ETLayoutItem *)anItem
{
	ETLog(@"Did begin editing in %@", anItem);
}

- (void) objectDidEndEditing: (ETLayoutItem *)anItem
{ 	
	ETLog(@"Did end editing in %@", anItem);

	NSString *shortDesc = [NSString stringWithFormat: @"Renamed to %@", [[anItem representedObject] name]];

	[[self editingContext] commitWithType: @"Object Renaming" 
	                     shortDescription: shortDesc
	                      longDescription: nil];
}

@end
