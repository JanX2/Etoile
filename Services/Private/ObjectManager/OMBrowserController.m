/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import "OMBrowserController.h"
#import "OMLayoutItemFactory.h"
#import "OMAppController.h"

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
	[(id)[contentViewItem controller] prepareForNewRepresentedObject: aGroup];
	[[statusLabelItem view] setObjectValue: aGroup];

	[[self history] addObject: aGroup];
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

- (ETHistory *)history
{
	// TODO: Return 'Recently Visted' from WHEN group
	return nil;
}

- (COGroup *) whereGroup
{
	return [[sourceListItem firstItem] representedObject];
}

- (ETLayoutItemGroup *) whatGroupItem
{
	return (id)[sourceListItem itemAtIndex: 1];
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
			[tags addObjectsFromArray: [(COTagGroup *)selectedObject contentArray]];
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

#pragma mark -
#pragma mark Object Insertion and Deletion Actions

- (IBAction) add: (id)sender
{
	[[contentViewItem controller] add: sender];
}

- (IBAction) addNewObjectFromTemplate: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
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

- (IBAction) addNewGroup: (id)sender
{
	// TODO: Implement New Smart Group...
}

- (IBAction) remove: (id)sender
{
	[[contentViewItem controller] remove: sender];
}

#pragma mark -
#pragma mark Presentation Actions

- (void) changePresentationViewToMenuItem: (NSMenuItem *)aMenuItem
{
	ETLayout *templateLayout = [aMenuItem representedObject];
	[contentViewItem setLayout: AUTORELEASE([templateLayout copy])];
}

- (NSString *) currentPresentationTitle
{
	return [[[[ETApp layoutItem] controller] ifResponds] currentPresentationTitle];
}

- (void) setCurrentPresentationTitle: (NSString *)aTitle
{
	[[[[ETApp layoutItem] controller] ifResponds] setCurrentPresentationTitle: aTitle];
}

- (void) updateForNewSelectedItemTitle: (NSString *)newTitle
                              oldTitle: (NSString *)oldTitle
                                inMenu: (NSMenu *)aMenu
{
	BOOL hasExpectedAppController = ([self currentPresentationTitle] != nil);

	if (hasExpectedAppController == NO)
		return;

	[[aMenu itemWithTitle: oldTitle] setState: NSOffState];
	[[aMenu itemWithTitle: newTitle] setState: NSOnState];
}

- (IBAction) changePresentationViewFromPopUp: (id)sender
{
	ETAssert(viewPopUpItem != nil);

	[self changePresentationViewToMenuItem: [[viewPopUpItem view] selectedItem]];

	NSString *newSelectedTitle = [[[viewPopUpItem view] selectedItem] title];
	
	[self updateForNewSelectedItemTitle: newSelectedTitle
	                           oldTitle: [self currentPresentationTitle]
	                             inMenu: [[ETApp viewMenuItem] submenu]];
	[self setCurrentPresentationTitle: newSelectedTitle];
}

- (IBAction) changePresentationViewFromMenuItem: (id)sender
{
	[self updateForNewSelectedItemTitle: [sender title]
	                           oldTitle: [self currentPresentationTitle]
	                             inMenu: [sender menu]];
	[self changePresentationViewToMenuItem: sender];

	[self setCurrentPresentationTitle: [sender title]];
	[(NSPopUpButton *)[viewPopUpItem view] selectItemWithTitle: [self currentPresentationTitle]];
}

- (IBAction) changeInspectorViewFromMenuItem: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

#pragma mark -
#pragma Other Object Actions

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
		[itemFactory browserWithGroup: [[self sourceListItem] representedObject]
					   editingContext: [self editingContext]];
		
		[(OMBrowserController *)[browser controller] setBrowsedGroup: clickedObject];
		[[itemFactory windowGroup] addObject: browser];
	}
	else
	{
		ETLog(@"Open is not yet implemented!");
	}
}

- (IBAction) open: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) openSelection: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) markVersion: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) revertTo: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) browseHistory: (id)sender
{
	if ([[self selectedObject] isPersistent] == NO)
		return;

	COTrack *track = [[self selectedObject] commitTrack];
	ETLayoutItemGroup *browser =
		[[ETLayoutItemFactory factory] historyBrowserWithRepresentedObject: track
		                                                             title: nil];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

- (IBAction) export: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
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

- (id) init
{
	SUPERINIT;

	/* baseTemplate is used for unknown COObject subclasses and 
	   baseGroupTemplate is used for unknown COCollection subclasses */
	ETItemTemplate *noteTemplate =
		[ETItemTemplate templateWithItem: [[OMLayoutItemFactory factory] itemGroup]
	                         objectClass: [COContainer class]];
	ETItemTemplate *bookmarkTemplate = 
		[ETItemTemplate templateWithItem: [[OMLayoutItemFactory factory] item]
	                         objectClass: [COBookmark class]];
	ETItemTemplate *tagTemplate =
		[ETItemTemplate templateWithItem: [[OMLayoutItemFactory factory] itemGroup]
	                         objectClass: [COTag class]];
	ETItemTemplate *libraryTemplate =
		[ETItemTemplate templateWithItem: [[OMLayoutItemFactory factory] itemGroup]
	                         objectClass: [COLibrary class]];
	ETItemTemplate *baseTemplate = [self templateForType: [self currentObjectType]];
	ETItemTemplate *baseGroupTemplate = [self templateForType: [self currentGroupType]];

	[self setTemplate: baseTemplate forType: [ETUTI typeWithClass: [COObject class]]];
	[self setTemplate: baseGroupTemplate forType: [ETUTI typeWithClass: [COCollection class]]];
	[self setTemplate: noteTemplate forType: [ETUTI typeWithClass: [COContainer class]]];
	[self setTemplate: bookmarkTemplate forType: [ETUTI typeWithClass: [COBookmark class]]];
	[self setTemplate: tagTemplate forType: [ETUTI typeWithClass: [COTag class]]];
	[self setTemplate: libraryTemplate forType: [ETUTI typeWithClass: [COLibrary class]]];

	ETUTI *librarySubtype = [ETUTI typeWithClass: [COTagLibrary class]];
	ETAssert([[self templateForType: librarySubtype] isEqual: libraryTemplate]);

	return self;
}

- (void)prepareForNewRepresentedObject: (id)browsedGroup
{
	// NOTE: Will update the window title
	[[self content] setRepresentedObject: browsedGroup];
	[[self content] reload];
	[[self content] setSelectionIndex: NSNotFound];
}

- (void)setContent:(ETLayoutItemGroup *)anItem
{
	if ([self content] != nil)
	{
		[self stopObserveObject: [self content]
		    forNotificationName: ETItemGroupSelectionDidChangeNotification];
	}
	[super setContent: anItem];

	if (anItem != nil)
	{
		[self startObserveObject: anItem
		     forNotificationName: ETItemGroupSelectionDidChangeNotification
		                selector: @selector(contentSelectionDidChange:)];
	}
}

- (id <COPersistentObjectContext>)persistentObjectContext
{
	COPersistentRoot *persistentRoot = [self persistentRootFromSelection];
	return (persistentRoot != nil ? persistentRoot : [super persistentObjectContext]);
}

- (ETUTI *)currentObjectType
{
	// TODO: COSmartGroup doesn't respond to -objectType. COCollection and
	// COSmartGroup could implement a new COCollection protocol. Not sure it's needed.
	ETUTI *contentType = [[[[self content] representedObject] ifResponds] objectType];
	return (contentType !=  nil ? contentType : [super currentObjectType]);
}

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

	/* Delete persistent roots or particular inner objects  */
	[[self editingContext] deleteObjects: [[selectedItems mappedCollection] representedObject]];
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

	[[[anItem representedObject] persistentRoot] commitWithType: @"Object Renaming"
	                                           shortDescription: shortDesc];
}

- (NSArray *) selectedObjects
{
	return [[[[self content] selectedItemsInLayout] mappedCollection] representedObject];
}

- (NSInteger)menuInsertionIndex
{
	NSMenuItem *editMenuItem = [[ETApp mainMenu] itemWithTag: ETEditMenuTag];
	return [[ETApp mainMenu] indexOfItem: editMenuItem];
}

- (void)hideMenusForModelObject: (id)anObject
{
	if (menuProvider == nil)
		return;
	
	if ([[menuProvider class] isEqual: [anObject class]])
		return;

	NSInteger nbOfMenusToRemove = [[[menuProvider class] menuItems] count];

	for (NSInteger i = 0; i < nbOfMenusToRemove; i++)
	{
		[[ETApp mainMenu] removeItemAtIndex: [self menuInsertionIndex] + 1];
	}
	DESTROY(menuProvider);
}

- (void)showMenusForModelObject: (id)anObject
{
	if (anObject == nil)
		return;

	if ([[menuProvider class] isEqual: [anObject class]])
		return;

	NSArray *menuItems = [[anObject class] menuItems];

	if ([menuItems isEmpty])
		return;

	for (NSMenuItem *item in [menuItems reverseObjectEnumerator])
	{
		[[ETApp mainMenu] insertItem: item atIndex: [self menuInsertionIndex] + 1];
	}
	ASSIGN(menuProvider, anObject);
}

- (void) contentSelectionDidChange: (NSNotification *)aNotif
{
	NSArray *selectedObjects = [self selectedObjects];
	id selectedObject = ([selectedObjects count] == 1 ? [selectedObjects lastObject] : nil);

	[self hideMenusForModelObject: selectedObject];
	[self showMenusForModelObject: selectedObject];
}

@end

@implementation COEditingContext (OMAdditions)

- (void)deleteObjects: (NSSet *)objects
{
	for (COObject *object in objects)
	{
		if ([object isRoot])
		{
			[self deletePersistentRootForRootObject: object];
		}
		else
		{
			[[object persistentRoot] deleteObject: object];
		}
	}
}

@end
