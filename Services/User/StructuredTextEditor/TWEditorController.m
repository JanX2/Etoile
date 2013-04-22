/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */

#import "TWEditorController.h"
#import "TWAppController.h"
#import "TWLayoutItemFactory.h"

@implementation TWEditorController

@synthesize contentViewItem, sourceListItem, viewPopUpItem;

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
	DESTROY(statusLabelItem);
	[super dealloc];
}

- (NSArray *) trackedItemPropertyNames
{
	return A(@"contentViewItem", @"viewPopUpItem");
	//return A(@"contentViewItem", @"sourceListItem", @"viewPopUpItem", @"statusLabelItem");
}

- (COEditingContext *)editingContext
{
	if ([[self persistentObjectContext] respondsToSelector: @selector(parentContext)])
	{
		return [(COPersistentRoot *)[self persistentObjectContext] parentContext];
	}
	return (COEditingContext *)[self persistentObjectContext];
}

- (ETLayoutItemGroup *) bodyItem
{
	return [[self sourceListItem] parentItem];
}

- (ETLayoutItemGroup *) inspectorItem
{
	return (ETLayoutItemGroup *)[[self bodyItem] itemForIdentifier: @"inspector"];
}

#pragma mark -
#pragma mark Selection

- (id) selectedObjectInContentView
{
	id selectedObject = [[[[self contentViewItem] selectedItemsInLayout] firstObject] representedObject];

	if (selectedObject == nil)
	{
		selectedObject = [[self contentViewItem] representedObject];
	}
	return selectedObject;
}

- (NSArray *) selectedObjectsInSourceList
{
	return [[[[self sourceListItem] selectedItemsInLayout] mappedCollection] representedObject];
}

#pragma mark -
#pragma mark Notifications

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif
{

}

#pragma mark -
#pragma mark Presentation

- (BOOL) isInspectorHidden
{
	return ([self inspectorItem] == nil);
}

- (void) showInspector
{
	NSSize size = NSMakeSize([[TWLayoutItemFactory factory] defaultInspectorWidth], [[self bodyItem] height]);
	ETLayoutItemGroup *inspectorItem =
		[[TWLayoutItemFactory factory] inspectorWithObject: [self selectedObjectInContentView]
	                                                  size: size
	                                            controller: self];

	[[self contentViewWrapperItem] setWidth: [[self contentViewWrapperItem] width] - [inspectorItem width]];
	[[self bodyItem] addItem: inspectorItem];
}

- (void) hideInspector
{
	ETAssert([[self bodyItem] containsItem: [self inspectorItem]]);
	[[self bodyItem] removeItem: [self inspectorItem]];
}

#pragma mark -
#pragma mark Object Insertion and Deletion Actions

- (IBAction) add: (id)sender
{
	[[contentViewItem controller] add: sender];
}

- (IBAction) insert: (id)sender
{
	[[contentViewItem controller] insert: sender];
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
	[[contentViewItem layout] setDelegate: [contentViewItem controller]];
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

- (IBAction) toggleInspector: (id)sender
{
	BOOL isInspectorHidden = ([self inspectorItem] == nil);

	if (isInspectorHidden)
	{
		[self showInspector];
	}
	else
	{
		[self hideInspector];
	}
}

#pragma mark -
#pragma mark Other Object Actions

- (IBAction) search: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) open: (id)sender
{
	// TODO: Implement
	[self doesNotRecognizeSelector: _cmd];
}

- (IBAction) browseHistory: (id)sender
{
	if ([[self selectedObjectInContentView] isPersistent] == NO)
		return;

	COTrack *track = [[self selectedObjectInContentView] commitTrack];
	ETLayoutItemGroup *browser =
		[[ETLayoutItemFactory factory] historyBrowserWithRepresentedObject: track
		                                                             title: nil];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

@end
