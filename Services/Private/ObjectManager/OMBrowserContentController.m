/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */

#import "OMBrowserContentController.h"
#import "OMConstants.h"
#import "OMLayoutItemFactory.h"
#import "OMAppController.h"

@implementation OMBrowserContentController

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithObjectGraphContext: aContext];
	if (self == nil)
		return nil;

	OMLayoutItemFactory *itemFactory =
		[OMLayoutItemFactory factoryWithObjectGraphContext: aContext];

	/* baseTemplate is used for unknown COObject subclasses and 
	   baseGroupTemplate is used for unknown COCollection subclasses */
	ETItemTemplate *noteTemplate =
		[ETItemTemplate templateWithItem: [itemFactory itemGroup]
	                         objectClass: [COContainer class]
	                  objectGraphContext: aContext];
	ETItemTemplate *bookmarkTemplate = 
		[ETItemTemplate templateWithItem: [itemFactory item]
	                         objectClass: [COBookmark class]
		              objectGraphContext: aContext];
	ETItemTemplate *tagTemplate =
		[ETItemTemplate templateWithItem: [itemFactory itemGroup]
	                         objectClass: [COTag class]
		              objectGraphContext: aContext];
	ETItemTemplate *libraryTemplate =
		[ETItemTemplate templateWithItem: [itemFactory itemGroup]
	                         objectClass: [COLibrary class]
		              objectGraphContext: aContext];
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
	// TODO: Support returning nil -currentObjectType. Not sure it is a good
	// idea, because it involves changing various COController methods.
	ETUTI *contentType = [[[[self content] representedObject] ifResponds] objectType];
	return (contentType !=  nil ? contentType : [super currentObjectType]);
}

#pragma mark -
#pragma mark Object Insertion and Deletion Actions

- (void) add: (id)sender
{
	BOOL isMutableCollection = ([[self currentObjectType] isEqual: kETTemplateObjectType] == NO);

	// TODO: Implement toolbar item validation to assert rather than return
	if (isMutableCollection == NO)
		return;

	ETLog(@" === Add %@ === ", [self currentObjectType]);

	[super add: sender];
	
	NSString *type = [[[[self content] lastItem] subject] typeDescription];

	[[self editingContext] commitWithType: @"Object Creation"
						 shortDescription: [NSString stringWithFormat: @"Created New %@", type]];
}

- (void) addTag: (COGroup *)aTag
{
	ETItemTemplate *template = [self templateForType: [self currentGroupType]];
	[self insertItem: [template newItemWithRepresentedObject: aTag options: nil] 
	         atIndex: ETUndeterminedIndex];
	[[self editingContext] commitWithType: @"Object Creation"
						 shortDescription: @"Created New Tag"];
}

- (IBAction) remove: (id)sender
{
	NSArray *selectedObjects = [self selectedObjects];

	if ([selectedObjects isEmpty])
		return;

	/* Delete persistent roots or particular inner objects  */
	[[self editingContext] deleteObjects: [NSSet setWithArray: selectedObjects]];
	[[self editingContext] commitWithType: @"Object Deletion"
	                     shortDescription: @"Deleted one or several objects"];
}

- (void)subjectDidBeginEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{
	ETLog(@"Did begin editing for %@ - %@", anItem, aKey);
}

- (void)subjectDidEndEditingForItem: (ETLayoutItem *)anItem property: (NSString *)aKey
{ 	
	ETLog(@"Did end editing for %@ - %@", anItem, aKey);

	NSDictionary *metadata = D(A([[anItem representedObject] name]), kCOCommitMetadataShortDescriptionArguments);

	//ETAssert([[[anItem representedObject] objectGraphContext] hasChanges]);
	[[[anItem representedObject] persistentRoot] commitWithIdentifier: kOMCommitRename
															 metadata: metadata
														   undoTracks: nil
																error: NULL];
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
			[[object persistentRoot] setDeleted: YES];
		}
		else
		{
			// TODO: Implement something to remove children in parent/children
			// relationships (e.g. removing a subnode in a note tree structure)
			ETAssertUnreachable();
		}
	}
}

@end
