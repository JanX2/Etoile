/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <ObjectMerging/COHistoryTrack.h>
#import <ObjectMerging/COObject.h>
#import "OMBrowserController.h"
#import "OMLayoutItemFactory.h"
#import "OMAppController.h"

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

- (COEditingContext *) editingContext
{
	return [[self content] editingContext];
}

- (ETLayoutItem *) tagGroupItem
{
	COGroup *tagGroup = [[self editingContext] tagGroup];
	return [[[sourceListItem items] filteredArrayUsingPredicate: 
		[NSPredicate predicateWithFormat: @"representedObject == %@", tagGroup]] firstObject];
}

- (void) addNewTag: (id)sender
{
	/* First select Tags in the Source list */

	[sourceListItem setSelectedItems: A([self tagGroupItem])];

	/* Create the new Tag */

	COEditingContext *ctxt = [self editingContext];
	COGroup *tag = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[tag setName: _(@"Untitled")];

	/* Will invoke -addObject: on the Tag group */
	[[contentViewItem controller] insertObject: tag atIndex: ETUndeterminedIndex];

	[ctxt commit];

	/* Finally let the user edit the tag name */

	// TODO: [[contentViewItem lastItem] beginEditingForProperty: @"name"];
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
	COHistoryTrack *track = [[COHistoryTrack alloc] initTrackWithObject: [self selectedObject]  
	                                                   containedObjects: YES];
	//ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] itemGroupWithRepresentedObject: track];
	ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] itemGroupWithRepresentedObject: [[[track nodes] mappedCollection] underlyingRevision]];
	ETOutlineLayout *layout = [ETOutlineLayout layout];

	[layout setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];
	[layout setDisplayedProperties: A(@"revisionNumber", @"UUID", @"type", @"date", @"objectUUID", @"properties")];
	[layout setDisplayName: @"Revision Number" forProperty: @"revisionNumber"];
	[layout setDisplayName: @"Revision UUID" forProperty: @"UUID"];
	[layout setDisplayName: @"Date" forProperty: @"date"];
	[layout setDisplayName: @"Type" forProperty: @"type"];
	[layout setDisplayName: @"Object UUID" forProperty: @"objectUUID"];
	[layout setDisplayName: @"Properties" forProperty: @"properties"];
	[[layout columnForProperty: @"properties"] setWidth: 200];

	[browser setSource: browser];
	[browser setLayout: layout];
	[browser setSize: NSMakeSize(700, 400)];
	[browser reload];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

- (IBAction) export: (id)sender
{

}

- (IBAction) showInfos: (id)sender
{

}

@end


@implementation OMBrowserContentController

- (COEditingContext *) editingContext
{
	return [[self content] editingContext];
}

- (void) remove: (id)sender
{
	NSArray *selectedItems = [[self content] selectedItemsInLayout];
	NSArray *coreObjects =  [[selectedItems mappedCollection] representedObject];

	for (COObject *object in coreObjects)
	{
		[[self editingContext] deleteObject: object];
	}
	[[self editingContext] commit];
}

- (void) objectDidBeginEditing: (ETLayoutItem *)anItem
{
	ETLog(@"Did beging editing in %@", anItem);
}

- (void) objectDidEndEditing: (ETLayoutItem *)anItem
{ 	
	ETLog(@"Did end editing in %@", anItem);
	[[self editingContext] commit];
}

@end
