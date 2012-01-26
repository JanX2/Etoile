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

// NOTE: Could be simpler to have a method -setEditingContext as Apple does it 
// with CoreData. But it's less clean and means we might end up in a situation 
// where the context set on the controller is not the same than the one used by 
// the represented object, if the controller context has not been reset.
- (COEditingContext *) editingContext
{
	id repObject = [[self content] representedObject];
	COEditingContext *ctxt = [[repObject ifResponds] editingContext];

	/* All Objects smart group is not persistent, in that case we use an object 
	   among the content to get the editing context */
	if (ctxt == nil && [repObject isCollection])
	{
		for (id object in repObject)
		{
			ctxt = [[object ifResponds] editingContext];
			if (ctxt != nil)
				break;
		}
	}
	ETAssert(ctxt != nil);

	return ctxt;
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

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif
{
	ETLog(@"Did change selection in %@", [aNotif object]);
	NSArray *selectedItems = [[aNotif object] selectedItemsInLayout];
	[self setBrowsedGroup: [[selectedItems firstObject] representedObject]];
}

- (ETLayoutItem *) tagLibraryItem
{
	COLibrary *tagLibrary = [[self editingContext] tagLibrary];
	return [[[sourceListItem items] filteredArrayUsingPredicate: 
		[NSPredicate predicateWithFormat: @"representedObject == %@", tagLibrary]] firstObject];
}

- (IBAction) addNewTag: (id)sender
{
	/* First select Tags in the Source list */

	[sourceListItem setSelectedItems: A([self tagLibraryItem])];

	/* Create the new Tag */

	COEditingContext *ctxt = [self editingContext];
	COGroup *tag = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[tag setName: _(@"Untitled")];

	/* Will invoke -addObject: on the Tag group */
	[(OMBrowserContentController *)[contentViewItem controller] addTag: tag];

	[ctxt commit];

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
